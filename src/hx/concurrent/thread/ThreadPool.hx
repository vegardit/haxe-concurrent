/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.thread;

#if threads
import haxe.ds.StringMap;
import hx.concurrent.Service.ServiceBase;
import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.collection.Queue;
import hx.concurrent.thread.Threads;


class ThreadPool extends ServiceBase {
   /**
    * The default amount of time a worker sleeps waiting for work
    */
   public static final DEFAULT_POLL_PERIOD = 0.001;

   static final _threadIDs = new AtomicInt();

   var _spawnedThreadCount = new AtomicInt(0);
   var _workingThreadCount = new AtomicInt(0);
   final _workQueue = new Queue<Task>();

   public final threadCount:Int;

   /**
    * The amount of time a worker sleeps waiting for work
    */
   public var pollPeriod(default, set):Float = DEFAULT_POLL_PERIOD;
   inline function set_pollPeriod(value:Float) {
      if (value <= 0)
         throw "[value] must be >= 0";
      return pollPeriod = value;
   }

   /**
    * Number of tasks currently executed in parallel.
    */
   public var executingTasks(get, never):Int;
   inline function get_executingTasks():Int return _workingThreadCount;

   /**
    * Number of tasks waiting for execution.
    */
   public var pendingTasks(get, never):Int;
   inline function get_pendingTasks():Int return _workQueue.length;

   public function new(numThreads:Int, autostart = true) {
      if (numThreads < 1)
         throw "[numThreads] must be > 0";

      super();

      threadCount = numThreads;

      if (autostart)
         start();
   }


   /**
    * Waits for all submitted tasks being executed.
    *
    * If <code>timeoutMS</code> is set 0, the function immediately returns.
    * If <code>timeoutMS</code> is set to value > 0, this function waits for the given time until a result is available.
    * If <code>timeoutMS</code> is set to `-1`, this function waits indefinitely until a result is available.
    * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
    *
    * @return <code>true</code> if all submitted tasks are done otherwise <code>false</code>.
    */
   public function awaitCompletion(timeoutMS:Int):Bool
      return Threads.await(() -> _workQueue.length == 0 && _workingThreadCount == 0, timeoutMS);


   /**
    * @return the number of cancelled tasks
    */
   public function cancelPendingTasks():Int {
      var canceled = 0;
      while (true) {
          if (_workQueue.pop() == null)
              break;
          canceled++;
      }
      return canceled;
   }


   override //
   function onStart() {

      state = RUNNING;

      /*
       * start worker threads
       */
      for (i in 0...threadCount) {
         Threads.spawn(function() {
            _spawnedThreadCount++;

            final context = new ThreadContext(_threadIDs.incrementAndGet());

            trace('[$this] Spawned thread $_spawnedThreadCount/$threadCount with ID ${context.id}.');

            while (true) {
               final task = _workQueue.pop();
               if (task == null) {
                  if(state != RUNNING)
                     break;
                  Sys.sleep(pollPeriod);
               } else {
                  try {
                     _workingThreadCount++;
                     task(context);
                  } catch (ex) {
                     trace(ex);
                  }
                  _workingThreadCount--;
               }
            }

            trace('[$this] Stopped thread with ID ${context.id}.');

            _spawnedThreadCount--;

            if (_spawnedThreadCount == 0)
               _stateLock.execute(() -> state = STOPPED);
         });
      }
   }


   /**
    * Submits a task for immediate execution in a thread.
    */
   public function submit(task:Task):Void {
      if (task == null)
         throw "[task] must not be null";

      _stateLock.execute(function() {
         if (state != RUNNING)
            throw 'ThreadPool is not in required state [RUNNING] but [$state]';
         _workQueue.push(task);
      });
   }


   /**
    * Initiates a graceful shutdown of this executor canceling execution of all queued tasks.
    */
   override //
   public function stop():Void
      _stateLock.execute(function() {
         if (state == RUNNING) {
            state = STOPPING;
         }
      });
}


typedef Task=ThreadContext->Void;


class ThreadContext {
   /**
    * ID of the current thread
    */
   public final id:Int;
   public final vars = new StringMap<Dynamic>();

   inline //
   public function new(id:Int) {
      this.id = id;
   }
}
#end
