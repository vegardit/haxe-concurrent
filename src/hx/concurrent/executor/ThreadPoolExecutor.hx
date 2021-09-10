/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.executor;

import hx.concurrent.Future.FutureResult;
import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.collection.Queue;
import hx.concurrent.executor.Executor.TaskFuture;
import hx.concurrent.executor.Executor.TaskFutureBase;
import hx.concurrent.executor.Schedule.ScheduleTools;
import hx.concurrent.internal.Dates;
import hx.concurrent.internal.Either2;
import hx.concurrent.thread.ThreadPool;
import hx.concurrent.thread.Threads;

/**
 * hx.concurrent.thread.ThreadPool based executor.
 * Only available on platforms supporting threads.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
#if threads
class ThreadPoolExecutor extends Executor {

   public inline static final SCHEDULER_RESOLUTION_MS = 10;
   public inline static final SCHEDULER_RESOLUTION_SEC = SCHEDULER_RESOLUTION_MS / 1000;

   final _threadPool:ThreadPool;

   final _scheduledTasks = new Array<TaskFutureImpl<Dynamic>>();
   final _newScheduledTasks = new Queue<TaskFutureImpl<Dynamic>>();


   public function new(threadPoolSize:Int, autostart = true) {
      if (threadPoolSize < 1)
         throw "[threadPoolSize] must be > 0";

      super();

      _threadPool = new ThreadPool(threadPoolSize, autostart);

      if (autostart)
         start();
   }


   override
   function onStart() {

      state = RUNNING;

      /*
       * start scheduler thread
       */
      Threads.spawn(function() {

         final doneTasks = new Array<TaskFutureImpl<Dynamic>>();

         while (state == RUNNING) {
            /*
             * put scheduled tasks in execution queue if required
             */
            for (t in _scheduledTasks) {
               if (t.isDue())
                  _threadPool.submit((ctx) -> t.run());
               else if (t.isStopped)
                  doneTasks.push(t);
            }

            /*
             * purge done tasks from list
             */
            if (doneTasks.length > 0) {
               for (t in doneTasks)
                  _scheduledTasks.remove(t);

               #if python @:nullSafety(Off) #end // null-safety false positive
               doneTasks.resize(0);
            }

            /*
             * process newly scheduled tasks or sleep
             */
            final t = _newScheduledTasks.pop();
            if (t == null) {
               Sys.sleep(SCHEDULER_RESOLUTION_SEC);
               continue;
            }

            final startAt = Dates.now();
            _scheduledTasks.push(t);

            while (true) {
               // work on the _newScheduledTasks queue for max. 10ms
               if (Dates.now() - startAt > SCHEDULER_RESOLUTION_MS)
                  break;

               final t = _newScheduledTasks.pop();
               if (t == null)
                  break;
               _scheduledTasks.push(t);
            }
         }

         /*
          * cancel any remaining scheduled tasks
          */
         for (t in _scheduledTasks)
            t.cancel();
         while (true) {
            final t = _newScheduledTasks.pop();
            if (t == null) break;
            t.cancel();
         }

         Threads.await(() -> _threadPool.state == STOPPED, -1);
         state = STOPPED;
      });
   }


   override
   public function submit<T>(task:Either2<Void->T,Void->Void>, ?schedule:Schedule):TaskFuture<T>
      return _stateLock.execute(function() {
         if (state != RUNNING)
            throw 'Cannot accept new tasks. Executor is not in state [RUNNING] but [$state].';

         if (schedule == null)
            schedule = Executor.NOW_ONCE;

         final future = new TaskFutureImpl<T>(this, task, schedule);

         // skip round-trip via scheduler for one-shot tasks that should be executed immediately
         switch(schedule) {
            case ONCE(_):
               if (future.isDue()) {
                  _threadPool.submit((ctx) -> future.run());
                  return future;
               }
            default:
         }

         _newScheduledTasks.push(future);
         return future;
      });


   override
   public function stop()
      _stateLock.execute(function() {
         if (state == RUNNING) {
            state = STOPPING;

            _threadPool.stop();
         }
      });
}


private class TaskFutureImpl<T> extends TaskFutureBase<T> {

   var _nextRunAt:Float;


   public function new(executor:ThreadPoolExecutor, task:Either2<Void->T,Void->Void>, schedule:Schedule) {
      super(executor, task, schedule);
      this._nextRunAt = ScheduleTools.firstRunAt(this.schedule);
   }


   public function isDue():Bool {
      if (isStopped || _nextRunAt == -1)
         return false;

      if (Dates.now() >= _nextRunAt) {
         // calculate next run
         switch(schedule) {
            case ONCE(_):                   _nextRunAt = -1;
            case FIXED_DELAY(_):            _nextRunAt = -1;
            case FIXED_RATE(intervalMS, _): _nextRunAt += intervalMS;
            case HOURLY(_):                 _nextRunAt += ScheduleTools.HOUR_IN_MS;
            case DAILY(_):                  _nextRunAt += ScheduleTools.DAY_IN_MS;
            case WEEKLY(_):                 _nextRunAt += ScheduleTools.WEEK_IN_MS;
         };
         return true;
      }
      return false;
   }


   public function run():Void {
      if (isStopped)
         return;

      var result:FutureResult<T> = FutureResult.NONE(this);
      try {
         final resultValue:T = switch(_task.value) {
            case a(fn): fn();
            case b(fn): fn(); null;
         }
         result = FutureResult.SUCCESS(resultValue, Dates.now(), this);
      } catch (ex:Dynamic)
         result = FutureResult.FAILURE(ConcurrentException.capture(ex), Dates.now(), this);

      // calculate next run for FIXED_DELAY
      switch(schedule) {
         case ONCE(_):                    isStopped = true;
         case FIXED_DELAY(intervalMS, _): _nextRunAt = Dates.now() + intervalMS;
         default: /*nothing*/
      }

      this.result = result;

      final fn = this.onResult;
      if (fn != null) try fn(result) catch (ex:Dynamic) trace(ex);
      final fn = _executor.onResult;
      if (fn != null) try fn(result) catch (ex:Dynamic) trace(ex);
   }
}
#end
