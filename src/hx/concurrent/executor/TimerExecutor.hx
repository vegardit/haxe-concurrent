/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.executor;

import hx.concurrent.Future.FutureResult;
import hx.concurrent.executor.Executor.Task;
import hx.concurrent.executor.Executor.TaskFuture;
import hx.concurrent.executor.Executor.TaskFutureBase;
import hx.concurrent.executor.Schedule.ScheduleTools;
import hx.concurrent.internal.Dates;
import hx.concurrent.internal.Either2;

/**
 * haxe.Timer based executor.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class TimerExecutor extends Executor {

   var _scheduledTasks:Array<TaskFutureImpl<Dynamic>> = [];


   inline
   public function new(autostart = true) {
      super();

      if (autostart)
         start();
   }


   override
   public function submit<T>(task:Either2<Void->T,Void->Void>, ?schedule:Schedule):TaskFuture<T>
      return _stateLock.execute(function() {
         if (state != RUNNING)
            throw 'Cannot accept new tasks. Executor is not in state [RUNNING] but [$state].';

         // cleanup task list
         var i = _scheduledTasks.length;
         while (i-- > 0) if (_scheduledTasks[i].isStopped) _scheduledTasks.splice(i, 1);

         final future = new TaskFutureImpl<T>(this, task, schedule == null ? Executor.NOW_ONCE : schedule);
         switch(schedule) {
            case ONCE(0):
            default: _scheduledTasks.push(future);
         }
         return future;
      });


   override
   function onStop() {
      for (t in _scheduledTasks)
         t.cancel();
      _scheduledTasks = [];
   }
}


private class TaskFutureImpl<T> extends TaskFutureBase<T> {

   var _timer:Null<haxe.Timer>;


   public function new(executor:TimerExecutor, task:Task<T>, schedule:Schedule) {
      super(executor, task, schedule);
      var initialDelay = Std.int(ScheduleTools.firstRunAt(this.schedule) - Dates.now());
      #if java
         if (initialDelay < 1) initialDelay = 1;
      #else
         if (initialDelay < 0) initialDelay = 0;
      #end
      haxe.Timer.delay(this.run, initialDelay);
   }

   public function run():Void {
      if (isStopped)
         return;

      if (_timer == null) {
         var t:Null<haxe.Timer> = null;
         switch(schedule) {
            case FIXED_RATE(intervalMS, _): t = new haxe.Timer(intervalMS); t.run = this.run;
            case HOURLY(_): t = new haxe.Timer(ScheduleTools.HOUR_IN_MS);   t.run = this.run;
            case DAILY(_):  t = new haxe.Timer(ScheduleTools.DAY_IN_MS);    t.run = this.run;
            case WEEKLY(_): t = new haxe.Timer(ScheduleTools.WEEK_IN_MS);   t.run = this.run;
            default:
         }
         _timer = t;
      }

      var result:FutureResult<T> = FutureResult.NONE(this);
      try {
         var resultValue:T = switch(_task.value) {
            case a(fn): fn();
            case b(fn): fn(); null;
         }
         result = FutureResult.SUCCESS(resultValue, Dates.now(), this);
      } catch (ex:Dynamic)
         result = FutureResult.FAILURE(ConcurrentException.capture(ex), Dates.now(), this);

      // calculate next run for FIXED_DELAY
      switch(schedule) {
         case ONCE(_): isStopped = true;
         case FIXED_DELAY(intervalMS, _): _timer = haxe.Timer.delay(this.run, intervalMS);
         default: /*nothing*/
      }

      this.result = result;

      final fn = this.onResult;
      if (fn != null) try fn(result) catch (ex:Dynamic) trace(ex);
      final fn = _executor.onResult;
      if (fn != null) try fn(result) catch (ex:Dynamic) trace(ex);
   }


   override
   public function cancel():Void {
      final t = _timer;
      if(t != null) t.stop();
      super.cancel();
   }
}
