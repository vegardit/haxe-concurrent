/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent;

import hx.concurrent.Service.ServiceState;
import hx.concurrent.atomic.AtomicBool;
import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.collection.Queue;
import hx.concurrent.event.AsyncEventDispatcher;
import hx.concurrent.event.EventDispatcherWithHistory;
import hx.concurrent.event.SyncEventDispatcher;
import hx.concurrent.executor.Executor;
import hx.concurrent.executor.Schedule;
import hx.concurrent.internal.Dates;
import hx.concurrent.lock.RLock;
import hx.concurrent.lock.RWLock;
import hx.concurrent.lock.Semaphore;
import hx.concurrent.thread.BackgroundProcess;
import hx.concurrent.thread.ThreadPool;
import hx.concurrent.thread.Threads;
import hx.doctest.internal.Logger;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:build(hx.doctest.DocTestGenerator.generateDocTests())
@:keep // prevent DCEing of manually created testXYZ() methods
class TestRunner extends hx.doctest.DocTestRunner {

   #if threads
   static final logQueue = new Queue<{level:Level, msg:String, ?pos:haxe.PosInfos}>();
   @:keep
   static final __static_init = {
      /*
       * async logging
       */
      final log = Logger.log;
      Threads.spawn(function():Void {
         while (true) {
            final logEntry = logQueue.pop(500);
            if (logEntry != null) {
               log(logEntry.level, logEntry.msg, logEntry.pos);
            }
         }
      });

      Logger.log = function(level:Level, msg:String, ?pos:haxe.PosInfos):Void {
         logQueue.push({level: level, msg: msg, pos: pos});
      }
   }
   #end


   public static function main() {
      final runner = new TestRunner();
      runner.runAndExit(300);
   }


   function testAtomicInt() {
      var atomic = new AtomicInt(1);
      var val:Int = atomic;
      assertEquals(atomic.value, 1);
      assertEquals(val, 1);

      atomic = new AtomicInt(1);
      val = atomic++;
      assertEquals(atomic.value, 2);
      assertEquals(val, 1);

      atomic = new AtomicInt(1);
      val = ++atomic;
      assertEquals(atomic.value, 2);
      assertEquals(val, 2);

      atomic = new AtomicInt(1);
      val = atomic--;
      assertEquals(atomic.value, 0);
      assertEquals(val, 1);

      atomic = new AtomicInt(1);
      val = --atomic;
      assertEquals(atomic.value, 0);
      assertEquals(val, 0);

      atomic = new AtomicInt(1);
      val = -atomic;
      assertEquals(atomic.value, 1);
      assertEquals(val, -1);

      atomic = new AtomicInt(1);
      val = atomic + 1;
      assertEquals(atomic.value, 1);
      assertEquals(val, 2);

      atomic = new AtomicInt(1);
      val = atomic + atomic;
      assertEquals(atomic.value, 1);
      assertEquals(val, 2);

      atomic = new AtomicInt(1);
      val = 1 + atomic;
      assertEquals(atomic.value, 1);
      assertEquals(val, 2);

      atomic = new AtomicInt(1);
      val = 1;
      val += atomic;
      assertEquals(atomic.value, 1);
      assertEquals(val, 2);

      atomic = new AtomicInt(1);
      val = atomic - 1;
      assertEquals(atomic.value, 1);
      assertEquals(val, 0);

      atomic = new AtomicInt(1);
      val = atomic - atomic;
      assertEquals(atomic.value, 1);
      assertEquals(val, 0);

      atomic = new AtomicInt(1);
      val = 1 - atomic;
      assertEquals(atomic.value, 1);
      assertEquals(val, 0);

      atomic = new AtomicInt(1);
      val = 1;
      val -= atomic;
      assertEquals(atomic.value, 1);
      assertEquals(val, 0);

      atomic = new AtomicInt(0);
      assertEquals(atomic++, 0);
      assertEquals(++atomic, 2);
      atomic += 10;
      assertEquals(atomic.value, 12);
      atomic -= 10;
      assertEquals(atomic.value, 2);
      assertEquals(atomic--, 2);
      assertEquals(--atomic, 0);
   }


   function testConstantFuture() {
      final future = new Future.ConstantFuture(10);
      switch(future.result) {
         case SUCCESS(10, _):
         default: fail();
      }
      var flag = false;
      future.onResult = function(result:Future.FutureResult<Int>) flag = true;
      assertEquals(flag, true);
   }


   #if threads
   function testCountDownLatch() {
      var signal = new CountDownLatch(1);
      assertEquals(1, signal.count);
      assertFalse(signal.tryAwait(10));

      signal.countDown();
      assertEquals(0, signal.count);
      assertTrue(signal.tryAwait(10));

      signal.await();

      final signal = new CountDownLatch(1);
      Threads.spawn(function() {
         signal.countDown();
      });

      signal.await();
   }
   #end


   function testQueue() {
      final q = new Queue<Int>();
      assertEquals(0, q.length);
      assertEquals(null, q.pop());
      q.push(1);
      q.push(2);
      q.pushHead(3);
      assertEquals(3, q.length);
      assertEquals(3, q.pop());
      assertEquals(2, q.length);
      assertEquals(1, q.pop());
      assertEquals(1, q.length);
      assertEquals(2, q.pop());
      assertEquals(0, q.length);

      #if threads
      final q = new Queue<Int>();
      Threads.spawn(function() {
         Threads.sleep(1000);
         q.push(123);
         Threads.sleep(1000);
         q.push(456);
      });
      Threads.sleep(100);
      assertEquals(null, q.pop());
      assertEquals(null, q.pop(100));
      assertEquals(123,  q.pop(1500));
      assertEquals(null, q.pop());
      assertEquals(456,  q.pop(-1));
      assertEquals(null, q.pop());
      #end
   }


   function testScheduleTools() {
      final now = Dates.now();
      final in2sDate = Date.fromTime(now + 2000);

      final runInMS = Std.int(ScheduleTools.firstRunAt(HOURLY(in2sDate.getMinutes(), in2sDate.getSeconds())) - now);
      assertInRange(runInMS, 1000, 3000);

      final runInMS = Std.int(ScheduleTools.firstRunAt(DAILY(in2sDate.getHours(), in2sDate.getMinutes(), in2sDate.getSeconds())) - now);
      assertInRange(runInMS, 1000, 3000);

      final runInMS = Std.int(ScheduleTools.firstRunAt(WEEKLY(in2sDate.getDay(), in2sDate.getHours(), in2sDate.getMinutes(), in2sDate.getSeconds())) - now);
      assertInRange(runInMS, 1000, 3000);
   }


   function testRLock() {
      final lock = new RLock();
      assertFalse(lock.isAcquiredByCurrentThread);
      assertFalse(lock.isAcquiredByOtherThread);
      assertFalse(lock.isAcquiredByAnyThread);
      assertEquals(1, lock.availablePermits);

      #if threads
      Threads.spawn(function() {
         lock.acquire();
         Threads.sleep(2000);
         lock.release();
      });
      Threads.sleep(100);
      assertFalse(lock.tryAcquire(100));

      assertFalse(lock.isAcquiredByCurrentThread);
      assertTrue(lock.isAcquiredByOtherThread);
      assertTrue(lock.isAcquiredByAnyThread);
      assertEquals(0, lock.availablePermits);

      assertTrue(lock.tryAcquire(3000));

      assertTrue(lock.isAcquiredByCurrentThread);
      assertFalse(lock.isAcquiredByOtherThread);
      assertTrue(lock.isAcquiredByAnyThread);
      assertEquals(0, lock.availablePermits);
      #end

      final flag = new AtomicBool(false);
      lock.acquire();
      // test lock re-entrance
      assertTrue(lock.execute(function():Bool {
         flag.value = true;
         return true;
      }));
      assertTrue(flag.value);
      lock.release();
   }


   function testRWLock() {
      final lock = new RWLock();

      assertMin(lock.readLock.availablePermits, 1);
      assertEquals(lock.writeLock.availablePermits, 1);

      try {
         lock.readLock.release();
         fail("Exception expected!");
      } catch (ex:Dynamic) { } // expected

      try {
         lock.writeLock.release();
         fail("Exception expected!");
      } catch (ex:Dynamic) { } // expected

      assertMin(lock.readLock.availablePermits, 1);
      assertEquals(lock.writeLock.availablePermits, 1);
      assertFalse(lock.readLock.isAcquiredByAnyThread);
      assertFalse(lock.readLock.isAcquiredByCurrentThread);
      assertFalse(lock.readLock.isAcquiredByOtherThread);
      assertFalse(lock.writeLock.isAcquiredByAnyThread);
      assertFalse(lock.writeLock.isAcquiredByCurrentThread);
      assertFalse(lock.writeLock.isAcquiredByOtherThread);

      lock.readLock.acquire();

      assertMin(lock.readLock.availablePermits, 1);
      assertEquals(lock.writeLock.availablePermits, 1);
      assertTrue(lock.readLock.isAcquiredByAnyThread);
      assertTrue(lock.readLock.isAcquiredByCurrentThread);
      assertFalse(lock.readLock.isAcquiredByOtherThread);
      assertFalse(lock.writeLock.isAcquiredByAnyThread);
      assertFalse(lock.writeLock.isAcquiredByCurrentThread);
      assertFalse(lock.writeLock.isAcquiredByOtherThread);

      lock.writeLock.acquire(); // upgrading read to write lock

      assertMin(lock.readLock.availablePermits, 1);
      assertEquals(lock.writeLock.availablePermits, 0);
      assertTrue(lock.readLock.isAcquiredByAnyThread);
      assertTrue(lock.readLock.isAcquiredByCurrentThread);
      assertFalse(lock.readLock.isAcquiredByOtherThread);
      assertTrue(lock.writeLock.isAcquiredByAnyThread);
      assertTrue(lock.writeLock.isAcquiredByCurrentThread);
      assertFalse(lock.writeLock.isAcquiredByOtherThread);

      final oldPermits = lock.readLock.availablePermits;
      lock.readLock.acquire(); // read lock reentrance
      assertEquals(oldPermits -1, lock.readLock.availablePermits);

      lock.readLock.release();
      assertEquals(oldPermits, lock.readLock.availablePermits);

      assertTrue(lock.readLock.isAcquiredByAnyThread);
      assertTrue(lock.readLock.isAcquiredByCurrentThread);
      assertFalse(lock.readLock.isAcquiredByOtherThread);

      lock.readLock.release();
      assertFalse(lock.readLock.isAcquiredByAnyThread);
      assertFalse(lock.readLock.isAcquiredByCurrentThread);
      assertFalse(lock.readLock.isAcquiredByOtherThread);

      lock.writeLock.acquire(); // write lock reentrance
      lock.writeLock.release();
      assertEquals(lock.writeLock.availablePermits, 0);
      assertTrue(lock.writeLock.isAcquiredByAnyThread);
      assertTrue(lock.writeLock.isAcquiredByCurrentThread);
      assertFalse(lock.writeLock.isAcquiredByOtherThread);

      lock.writeLock.release();
      assertEquals(lock.writeLock.availablePermits, 1);
      assertFalse(lock.writeLock.isAcquiredByAnyThread);
      assertFalse(lock.writeLock.isAcquiredByCurrentThread);
      assertFalse(lock.writeLock.isAcquiredByOtherThread);

      #if threads
      lock.writeLock.acquire();

      final signal = new CountDownLatch(1);
      Threads.spawn(function() {
         assertFalse(lock.readLock.tryAcquire());
         assertFalse(lock.writeLock.tryAcquire());

         assertTrue(lock.writeLock.isAcquiredByAnyThread);
         assertFalse(lock.writeLock.isAcquiredByCurrentThread);
         assertTrue(lock.writeLock.isAcquiredByOtherThread);
         signal.countDown();
      });
      signal.await();

      lock.writeLock.release();
      lock.readLock.acquire();

      final signal = new CountDownLatch(1);
      Threads.spawn(function() {
         assertTrue(lock.readLock.isAcquiredByAnyThread);
         assertFalse(lock.readLock.isAcquiredByCurrentThread);
         assertTrue(lock.readLock.isAcquiredByOtherThread);

         assertTrue(lock.readLock.tryAcquire());

         assertTrue(lock.readLock.isAcquiredByAnyThread);
         assertTrue(lock.readLock.isAcquiredByCurrentThread);
         assertTrue(lock.readLock.isAcquiredByOtherThread);
         lock.readLock.release();

         assertFalse(lock.writeLock.tryAcquire());
         signal.countDown();
      });
      signal.await();
      lock.readLock.release();
      #end
   }


   function testSemaphore() {
      final sem = new Semaphore(2);

      assertEquals(2, sem.availablePermits);

      assertTrue(sem.tryAcquire());
      assertTrue(sem.tryAcquire());
      assertEquals(0, sem.availablePermits);
      assertFalse(sem.tryAcquire());
      sem.release();
      assertTrue(sem.tryAcquire());
      sem.release();
      sem.release();
      sem.release();
      assertEquals(3, sem.availablePermits);
   }


   function testThreads() {
      #if threads
         assertTrue(Threads.isSupported);
         final i = new AtomicInt(0);
         for (j in 0...10)
            Threads.spawn(() -> i.increment());
         assertTrue(Threads.await(function() return i.value == 10, 200));
      #else
         assertFalse(Threads.isSupported);
      #end
   }


   #if threads
   function testBackgroundProcess() {
      // cannot use timout command on Windows because of "ERROR: Input redirection is not supported, exiting the process immediately."
      final p = Sys.systemName() == "Windows" ?
         new BackgroundProcess("ping", ["127.0.0.1", "-n", 2, "-w", 1000]) :
         new BackgroundProcess("ping", ["127.0.0.1", "-c", 2, "-W", 1000]);

      assertEquals(p.exitCode, null);
      assertTrue(p.isRunning);
      #if !java
         assertMin(p.pid, 1);
      #end

      Logger.log(INFO, "Awaiting exit of ping process...");
      p.awaitExit(5000);

      if(p.exitCode != 0)
         trace(p.stderr.readAll());

      final linePreview = p.stdout.previewLine(0);
      assertEquals(linePreview, p.stdout.readLine(0));
      assertEndsWith(linePreview, "\n");
      assertNotEquals(linePreview, p.stdout.previewLine(0));

      assertContains(p.stdout.readAll(), "127.0.0.1");
      assertEquals(p.exitCode, 0);
      assertFalse(p.isRunning);
      #if !java
         assertMin(p.pid, 1);
      #end
   }


   function testThreadPool() {
      final pool = new ThreadPool(2);
      final ids = [-1, -1];
      for (j in 0...2)
         pool.submit(function(ctx:ThreadContext) {
            Threads.sleep(200);
            ids[j] = ctx.id;
         });
      Threads.sleep(50);
      assertEquals(pool.pendingTasks, 0);
      assertEquals(pool.executingTasks, 2);
      assertEquals(-1, ids[0]);
      assertEquals(-1, ids[1]);

      pool.awaitCompletion(500);
      assertEquals(pool.pendingTasks, 0);
      assertEquals(pool.executingTasks, 0);
      assertNotEquals(-1, ids[0]);
      assertNotEquals(-1, ids[1]);
      assertNotEquals(ids[0], ids[1]);

      pool.stop();
   }
   #end


   function testEventDispatcher_Async() {
      final executor = Executor.create(2);
      final disp = new AsyncEventDispatcher(executor);

      final listener1Count = new AtomicInt();
      final listener1 = function(event:String) {
         listener1Count.incrementAndGet();
      }

      assertTrue(disp.subscribe(listener1));
      #if !(hl)
      assertFalse(disp.subscribe(listener1));
      #end

      final fut1 = disp.fire("123");
      final fut2 = disp.fire("1234567890");

      _later(100, function() {
         executor.stop();
         assertEquals(2, listener1Count.value);
         switch(fut1.result) {
            case SUCCESS(v,_): assertEquals(1, v);
            default: fail();
         }
         switch(fut2.result) {
            case SUCCESS(v,_): assertEquals(1, v);
            default: fail();
         }
      });
   }


   function testEventDispatcher_WithHistory() {
      final disp = new EventDispatcherWithHistory<String>(new SyncEventDispatcher<String>());

      switch(disp.fire("123").result) {
         case SUCCESS(v,_): assertEquals(0, v);
         default: fail();
      }
      switch(disp.fire("1234567890").result) {
         case SUCCESS(v,_): assertEquals(0, v);
         default: fail();
      }

      final listener1Count = new AtomicInt();
      final listener1 = function(event:String) {
         listener1Count.incrementAndGet();
      }
      assertTrue(disp.subscribeAndReplayHistory(listener1));
      #if !(hl)
      assertFalse(disp.subscribeAndReplayHistory(listener1));
      assertEquals(2, listener1Count.value);
      #end
   }


   function testEventDispatcher_Sync() {
      final disp = new SyncEventDispatcher<String>();

      final listener1Count = new AtomicInt();
      final listener1 = function(event:String) {
         listener1Count.incrementAndGet();
      }

      assertTrue(disp.subscribe(listener1));
      #if !(hl)
      assertFalse(disp.subscribe(listener1));
      #end

      switch(disp.fire("123").result) {
         case SUCCESS(v,_): assertEquals(1, v);
         default: fail();
      }
      assertEquals(1, listener1Count.value);
   }


   function testTaskExecutor_shutdown() {
      final executor = Executor.create(2);
      assertEquals(executor.state, ServiceState.RUNNING);
      executor.stop();
      _later(500, function() {
         assertEquals(executor.state, ServiceState.STOPPED);
      });
   }


   function testTaskExecutor_shutdown_with_running_tasks() {
      final executor = Executor.create(3);
      final intervalMS = 20;
      var task_invocations = new AtomicInt(0);
      var task_first_execution:Float = 0;
      final task = executor.submit(function() {
         if (task_first_execution == 0)
            task_first_execution = Dates.now();
         task_invocations.increment();
      }, FIXED_RATE(intervalMS));

      _later(10 * intervalMS, function() {
         final v:Int = task_invocations;
         final task1_elapsed = Dates.now() - task_first_execution;
         final v_expected_value = task1_elapsed / intervalMS;
         assertMin(v, Math.round(v_expected_value * 0.5));
         assertMax(v, Math.round(v_expected_value * 1.5));
         assertFalse(task.isStopped);
      });
      _later(12 * intervalMS, function() {
         executor.stop();
      });
      _later(40 * intervalMS, function() {
         assertTrue(task.isStopped);
         assertEquals(executor.state, ServiceState.STOPPED);
      });
   }


   function testTaskExecutor_schedule_ONCE() {
      final executor = Executor.create(3);

      final flag1 = new AtomicBool(false);
      final flag2 = new AtomicBool(false);
      final flag3 = new AtomicBool(false);

      final task1 = executor.submit(() -> flag1.negate(), ONCE(0));
      final task2 = executor.submit(() -> flag2.negate(), ONCE(500));
      final task3 = executor.submit(() -> flag3.negate(), ONCE(500));

      assertFalse(flag2.value);
      assertFalse(flag3.value);

      _later(100, function() {
         assertTrue(flag1.value);
         assertTrue(task1.isStopped);

         assertFalse(flag2.value);
         assertFalse(task2.isStopped);

         assertFalse(flag3.value);
         assertFalse(task3.isStopped);
         task3.cancel();
         assertFalse(flag3.value);
         assertTrue(task3.isStopped);
      });
      _later(1000, function() {
         assertTrue(flag2.value);
         assertTrue(task2.isStopped);

         assertFalse(flag3.value);
         assertTrue(task3.isStopped);

         executor.stop();
      });
   }


   function testTaskExecutor_schedule_RATE_DELAY() {
      final executor = Executor.create(2);

      final intervalMS = 100;
      final threadMS = 200;

      final fixedRateCounter  = new AtomicInt(0);
      var future1_first_execution:Float = 0;
      final future1 = executor.submit(function() {
         if (future1_first_execution == 0)
            future1_first_execution = Dates.now();
         fixedRateCounter.increment();
         #if threads
         Threads.sleep(threadMS);
         #end
      }, FIXED_RATE(intervalMS));
      final v1 = new AtomicInt(0);

      #if threads
      final fixedDelayCounter = new AtomicInt(0);
      var future2_first_execution:Float = 0;
      final future2 = executor.submit(function() {
         if (future2_first_execution == 0)
            future2_first_execution = Dates.now();
         fixedDelayCounter.increment();
         Threads.sleep(threadMS);
      }, FIXED_DELAY(intervalMS));
      final v2 = new AtomicInt(0);
      #end

      _later(10 * intervalMS, function() {
         future1.cancel();
         #if threads
         Threads.await(() -> future1.isStopped, 1000);
         #end
         final future1_elapsed = Dates.now() - future1_first_execution;
         v1.value = fixedRateCounter.value;
         final v1_expected_value = future1_elapsed / intervalMS;
         assertMin(v1.value, Math.round(v1_expected_value * 0.5));
         assertMax(v1.value, Math.round(v1_expected_value * 1.5));

         #if threads
         future2.cancel();
         Threads.await(() -> future2.isStopped, 1000);
         final future2_elapsed = Dates.now() - future2_first_execution;
         v2.value = fixedDelayCounter.value;
         final v2_expected_value = future2_elapsed / (intervalMS + threadMS);
         assertMin(v2.value, Math.round(v2_expected_value * 0.5));
         assertMax(v2.value, Math.round(v2_expected_value * 1.5));

         assertTrue(v1 > v2);
         #end
      });
      _later(12 * intervalMS, function() {
         assertEquals(v1.value, fixedRateCounter.value);
         #if threads
         assertEquals(v2.value, fixedDelayCounter.value);
         #end

         executor.stop();
      });
   }


   function testTaskExecutor_schedule_HOURLY_DAILY_WEEKLY() {
      final executor = Executor.create(3);

      var hourlyCounter  = new AtomicInt(0);
      var dailyCounter  = new AtomicInt(0);
      var weeklyCounter  = new AtomicInt(0);
      final d = Date.fromTime(Dates.now() + 2000);
      final future1 = executor.submit(() -> hourlyCounter++, HOURLY(d.getMinutes(), d.getSeconds()));
      final future2 = executor.submit(() -> dailyCounter++,  DAILY(d.getHours(), d.getMinutes(), d.getSeconds()));
      final future3 = executor.submit(() -> weeklyCounter++, WEEKLY(d.getDay(), d.getHours(), d.getMinutes(), d.getSeconds()));
      assertEquals(hourlyCounter.value, 0);
      assertEquals(dailyCounter.value, 0);
      assertEquals(weeklyCounter.value, 0);
      _later(2500, function() {
         assertEquals(hourlyCounter.value, 1);
         assertEquals(dailyCounter.value, 1);
         assertEquals(weeklyCounter.value, 1);
         assertFalse(future1.isStopped);
         assertFalse(future2.isStopped);
         assertFalse(future3.isStopped);

         executor.stop();
      });

      _later(2600, function() {
         assertTrue(future1.isStopped);
         assertTrue(future2.isStopped);
         assertTrue(future3.isStopped);
      });
   }


   final _asyncExecutor = Executor.create(10);
   final _asyncTests = new AtomicInt(0);
   function _later(delayMS:Int, fn:Void->Void) {
      _asyncTests.increment();
      final future:TaskFuture<Dynamic> = _asyncExecutor.submit(function() {
         try {
            fn();
         } catch (ex:Dynamic){
            trace(ex);
         }
         _asyncTests.decrement();
      }, ONCE(delayMS));
   }


   override
   function runAndExit(expectedMinNumberOfTests = 0):Void {
      results = new ThreadSafeDocTestResults(this);
      final startTime = Dates.now();
      run(expectedMinNumberOfTests, true, false);

      final t = new haxe.Timer(100);
      t.run = function() {
         if(_asyncTests.value == 0) {
            t.stop();

            final timeSpent = Std.int((Dates.now() - startTime) / 1000);

            if (results.testsPassed + results.testsFailed == 0) {
               // no tests defined, DocTestRunner will display warning
            } else if (results.testsFailed == 0) {
               hx.doctest.internal.Logger.log(INFO, '**********************************************************');
               hx.doctest.internal.Logger.log(INFO, 'All ${results.testsPassed} test(s) PASSED within $timeSpent seconds.');
               hx.doctest.internal.Logger.log(INFO, '**********************************************************');
            } else {
               hx.doctest.internal.Logger.log(ERROR, '**********************************************************');
               hx.doctest.internal.Logger.log(ERROR, '${results.testsFailed} of ${results.testsPassed + results.testsFailed} test(s) FAILED:');
               results.logFailures();
            }

            final exitCode = results.testsFailed == 0 ? 0 : 1;
            #if threads
               Threads.await(() -> logQueue.length == 0, 10000);
            #end
            #if python
               // workaround for https://bugs.python.org/issue42717
               Threads.sleep(5000);
            #end
            hx.doctest.DocTestRunner.exit(exitCode);
         }
      };
   }


   @:nullSafety(Off)
   function assertEndsWith(txt:String, suffix:String, ?pos:haxe.PosInfos):Void
      results.add(txt != null && StringTools.endsWith(txt, suffix), 'assertEndsWith("$txt", "$suffix")', pos);

   @:nullSafety(Off)
   function assertContains(searchIn:String, searchFor:String, ?pos:haxe.PosInfos):Void
      results.add(searchIn != null && searchIn.indexOf(searchFor) > -1, 'assertContains("$searchIn", "$searchFor")', pos);
}


private class ThreadSafeDocTestResults extends hx.doctest.DocTestRunner.DefaultDocTestResults {

   final _sync = new RLock();

   function super_add(success:Bool, msg:String, pos:haxe.PosInfos):Void
      super.add(success, msg, pos);

   function super_logFailures():Void
      super.logFailures();

   override
   public function add(success:Bool, msg:String, pos:haxe.PosInfos):Void
      _sync.execute(() -> super_add(success, msg, pos));

   override
   public function logFailures():Void
      _sync.execute(() -> super_logFailures());
}
