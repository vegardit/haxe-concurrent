/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.executor;

import hx.concurrent.executor.Executor.AbstractTaskFuture;
import hx.concurrent.executor.Executor.Task;
import hx.concurrent.executor.Executor.TaskFuture;
import hx.concurrent.executor.Schedule.ScheduleTools;
import hx.concurrent.internal.Dates;
import hx.concurrent.internal.Either2;

/**
 * haxe.Timer based executor.
 */
class TimerExecutor extends Executor {

   var _scheduledTasks:Array<TaskFutureImpl<Dynamic>> = [];


   inline //
   public function new(autostart = true) {
      super();

      if (autostart)
         start();
   }


   public function submit<T>(task:Either2<Void->T, Void->Void>, ?schedule:Schedule):TaskFuture<T> {
      final schedule:Schedule = schedule == null ? Executor.NOW_ONCE : schedule;
      return _stateLock.execute(function() {
         if (state != RUNNING)
            throw 'Cannot accept new tasks. Executor is not in state [RUNNING] but [$state].';

         // cleanup task list
         var i = _scheduledTasks.length;
         while (i-- > 0)
            if (_scheduledTasks[i].isStopped) _scheduledTasks.splice(i, 1);

         final future = new TaskFutureImpl<T>(this, task, schedule);
         switch (schedule) {
            case ONCE(0):
            default: _scheduledTasks.push(future);
         }
         return future;
      });
   }

   override //
   function onStop() {
      for (t in _scheduledTasks)
         t.cancel();
      _scheduledTasks = [];
   }
}


@:access(hx.concurrent.executor.Executor)
private class TaskFutureImpl<T> extends AbstractTaskFuture<T> {

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

      var fnResult:Either2<T, ConcurrentException>;
      try {
         fnResult = switch(_task.value) {
            case a(functionWithReturnValue):    functionWithReturnValue();
            case b(functionWithoutReturnValue): functionWithoutReturnValue(); null;
         }
      } catch (ex)
         fnResult = ConcurrentException.capture(ex);

      // calculate next run for FIXED_DELAY
      switch (schedule) {
         case ONCE(_): isStopped = true;
         case FIXED_DELAY(intervalMS, _): _timer = haxe.Timer.delay(this.run, intervalMS);
         default: /*nothing*/
      }

      complete(fnResult, true);
      _executor.notifyResult(result);
   }


   override //
   public function cancel():Void {
      final t = _timer;
      if (t != null) t.stop();
      super.cancel();
   }
}
