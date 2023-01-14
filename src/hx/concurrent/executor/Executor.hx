/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.executor;

import hx.concurrent.Future.FutureResult;
import hx.concurrent.Future.FutureBase;
import hx.concurrent.Service.ServiceBase;
import hx.concurrent.internal.Either2;
import hx.concurrent.thread.Threads;

/**
 * A scheduler/work manager that executes submitted tasks asynchronously or concurrently
 * based on a given schedule.
 */
class Executor extends ServiceBase {

   static final NOW_ONCE = Schedule.ONCE(0);

   /**
    * Creates a new target specific task executor instance.
    *
    * @param maxConcurrent maximum number of concurrently executed tasks. Has no effect on targets without thread support.
    */
   public static function create(maxConcurrent:Int = 1, autostart = true):Executor {
      #if threads
         if (Threads.isSupported)
            return new ThreadPoolExecutor(maxConcurrent, autostart);
      #end
      return new TimerExecutor(autostart);
   }


   /**
    * Global callback function `function(result:FutureResult<T>):Void` to be executed when a
    * new result comes available for any task.
    *
    * Replaces any previously registered onResult function.
    */
   public var onResult:FutureResult<Dynamic>->Void = function(result) {
      switch(result) {
         case FAILURE(ex, _): trace(ex);
         default:
      }
   };


   /**
    * Submits the given task for background execution.
    *
    * @param task the function to be executed either `function():T {}` or `function():Void {}`
    * @param schedule the task's execution schedule, if not specified Schedule.ONCE(0) is used
    *
    * @throws exception if in state ServiceState#STOPPING or ServiceState#STOPPED
    */
   public function submit<T>(task:Task<T>, ?schedule:Schedule):TaskFuture<T>
      throw "Not implemented";


   /**
    * Initiates a graceful shutdown of this executor canceling execution of all queued and scheduled tasks.
    */
   override
   public function stop()
      super.stop();
}

/**
 * A function with no parameters and return type Void or T
 */
typedef Task<T> = Either2<Void->T,Void->Void>;


interface TaskFuture<T> extends Future<T> {

   /**
    * The effective schedule of the task.
    */
   var schedule(default, null):Schedule;

   /**
    * @return true if no future executions are scheduled
    */
   var isStopped(default, null):Bool;

   /**
    * Prevents any further scheduled executions of this task.
    */
   function cancel():Void;

   #if threads
   /**
    * If <code>timeoutMS</code> is set 0, the function immediatly returns.
    * If <code>timeoutMS</code> is set to value > 0, this function waits for the given time until a result is available.
    * If <code>timeoutMS</code> is set to `-1`, this function waits indefinitely until a result is available.
    * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
    *
    * @return result of the last execution
    */
   function waitAndGet(timeoutMS:Int):FutureResult<T>;
   #end
}


class TaskFutureBase<T> extends FutureBase<T> implements TaskFuture<T> {

   public var schedule(default, null):Schedule;
   public var isStopped(default, null) = false;

   final _executor:Executor;
   final _task:Task<T>;


   function new(executor:Executor, task:Task<T>, schedule:Schedule) {
      super();
      _executor = executor;
      _task = task;

      this.schedule = Schedule.ScheduleTools.assertValid(schedule);
   }


   public function cancel():Void
      isStopped = true;


   #if threads
   public function waitAndGet(timeoutMS:Int):FutureResult<T> {
      Threads.await(() -> switch(this.result) {
         case NONE(_): false;
         default: true;
      }, timeoutMS, ThreadPoolExecutor.SCHEDULER_RESOLUTION_MS);

      return this.result;
   }
   #end
}
