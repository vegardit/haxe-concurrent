/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
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


/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:build(hx.doctest.DocTestGenerator.generateDocTests("src", ".*\\.hx"))
class TestRunner extends hx.doctest.DocTestRunner {

    #if threads
    @:keep
    static var __static_init = {
        /*
         * synchronize trace calls
         */
        var sync = new RLock();
        var old = haxe.Log.trace;
        haxe.Log.trace = function(v:Dynamic, ?pos: haxe.PosInfos ):Void {
            sync.execute(function() old(v, pos));
        }
    }
    #end


    public static function main() {
        var runner = new TestRunner();
        runner.runAndExit();
    }


    function testAtomicInt() {
        var val:Int = -1;

        var atomic = new AtomicInt(1);
        val = atomic;
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
        var future = new Future.ConstantFuture(10);
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

        var signal = new CountDownLatch(1);
        Threads.spawn(function() {
            signal.countDown();
        });

        signal.await();
    }
    #end


    function testQueue() {
        var q = new Queue<Int>();
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
        var q = new Queue<Int>();
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
        var now = Dates.now();
        var in2sDate = Date.fromTime(now + 2000);
        var runInMS = ScheduleTools.firstRunAt(HOURLY(in2sDate.getMinutes(), in2sDate.getSeconds())) - now;
        assertTrue(runInMS > 1000);
        assertTrue(runInMS < 3000);
        var runInMS = ScheduleTools.firstRunAt(DAILY(in2sDate.getHours(), in2sDate.getMinutes(), in2sDate.getSeconds())) - now;
        assertTrue(runInMS > 1000);
        assertTrue(runInMS < 3000);
        var runInMS = ScheduleTools.firstRunAt(WEEKLY(in2sDate.getDay(), in2sDate.getHours(), in2sDate.getMinutes(), in2sDate.getSeconds())) - now;
        assertTrue(runInMS > 1000);
        assertTrue(runInMS < 3000);
    }


    function testRLock() {
        var lock = new RLock();
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

        var flag = new AtomicBool(false);
        lock.acquire();
        // test lock re-entrance
        assertTrue(lock.execute(function():Bool { flag.value = true; return true; } ));
        assertTrue(flag.value);
        lock.release();
    }


    function testRWLock() {
        var lock = new RWLock();

        try {
            lock.readLock.release();
            fail("Exception expected!");
        } catch (ex:Dynamic) { /* expected */ }

        try {
            lock.writeLock.release();
            fail("Exception expected!");
        } catch (ex:Dynamic) { /* expected */ }

        assertTrue(lock.readLock.availablePermits > 0);
        assertTrue(lock.writeLock.availablePermits == 1);
        assertFalse(lock.readLock.isAcquiredByAnyThread);
        assertFalse(lock.readLock.isAcquiredByCurrentThread);
        assertFalse(lock.readLock.isAcquiredByOtherThread);
        assertFalse(lock.writeLock.isAcquiredByAnyThread);
        assertFalse(lock.writeLock.isAcquiredByCurrentThread);
        assertFalse(lock.writeLock.isAcquiredByOtherThread);

        lock.readLock.acquire();

        assertTrue(lock.readLock.availablePermits > 0);
        assertTrue(lock.writeLock.availablePermits == 1);
        assertTrue(lock.readLock.isAcquiredByAnyThread);
        assertTrue(lock.readLock.isAcquiredByCurrentThread);
        assertFalse(lock.readLock.isAcquiredByOtherThread);
        assertFalse(lock.writeLock.isAcquiredByAnyThread);
        assertFalse(lock.writeLock.isAcquiredByCurrentThread);
        assertFalse(lock.writeLock.isAcquiredByOtherThread);

        lock.writeLock.acquire(); // upgrading read to write lock

        assertTrue(lock.readLock.availablePermits > 0);
        assertTrue(lock.writeLock.availablePermits == 0);
        assertTrue(lock.readLock.isAcquiredByAnyThread);
        assertTrue(lock.readLock.isAcquiredByCurrentThread);
        assertFalse(lock.readLock.isAcquiredByOtherThread);
        assertTrue(lock.writeLock.isAcquiredByAnyThread);
        assertTrue(lock.writeLock.isAcquiredByCurrentThread);
        assertFalse(lock.writeLock.isAcquiredByOtherThread);

        var oldPermits = lock.readLock.availablePermits;
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
        assertTrue(lock.writeLock.availablePermits == 0);
        assertTrue(lock.writeLock.isAcquiredByAnyThread);
        assertTrue(lock.writeLock.isAcquiredByCurrentThread);
        assertFalse(lock.writeLock.isAcquiredByOtherThread);

        lock.writeLock.release();
        assertTrue(lock.writeLock.availablePermits == 1);
        assertFalse(lock.writeLock.isAcquiredByAnyThread);
        assertFalse(lock.writeLock.isAcquiredByCurrentThread);
        assertFalse(lock.writeLock.isAcquiredByOtherThread);

        #if threads
        lock.writeLock.acquire();

        var signal = new CountDownLatch(1);
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

        var signal = new CountDownLatch(1);
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
        var sem = new Semaphore(2);

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
            var i = new AtomicInt(0);
            for (j in 0...10)
                Threads.spawn(function() i.increment());
            assertTrue(Threads.await(function() return i.value == 10, 200));
        #else
            assertFalse(Threads.isSupported);
        #end
    }


    #if threads
    function testBackgroundProcess() {
        // cannot use timout command on Windows because of "ERROR: Input redirection is not supported, exiting the process immediately."
        var p = Sys.systemName() == "Windows" ?
            new BackgroundProcess("ping", ["127.0.0.1", "-n", 2, "-w", 1000]) :
            new BackgroundProcess("ping", ["127.0.0.1", "-c", 2, "-W", 1000]);

        assertEquals(p.exitCode, null);
        assertTrue(p.isRunning);
        #if !java
            assertTrue(p.pid > 0);
        #end

        p.awaitExit();

        if(p.exitCode != 0)
            trace(p.stderr.readAll());

        var linePreview = p.stdout.previewLine(0);
        assertEquals(linePreview, p.stdout.readLine(0));
        assertTrue(StringTools.endsWith(linePreview, "\n"));
        assertNotEquals(linePreview, p.stdout.previewLine(0));

        assertTrue(p.stdout.readAll().indexOf("127.0.0.1") > -1);
        assertEquals(p.exitCode, 0);
        assertFalse(p.isRunning);
        #if !java
            assertTrue(p.pid > 0);
        #end
    }


    function testThreadPool() {
        var pool = new ThreadPool(2);
        var ids = [-1, -1];
        for (j in 0...2)
            pool.submit(function(ctx:ThreadContext) {
                Threads.sleep(50);
                ids[j] = ctx.id;
            });
        Threads.sleep(20);
        assertEquals(pool.pendingTasks, 0);
        assertEquals(pool.executingTasks, 2);
        assertEquals( -1, ids[0]);
        assertEquals( -1, ids[1]);

        pool.awaitCompletion(200);
        assertEquals(pool.pendingTasks, 0);
        assertEquals(pool.executingTasks, 0);
        assertNotEquals( -1, ids[0]);
        assertNotEquals( -1, ids[1]);
        assertNotEquals(ids[0], ids[1]);

        pool.stop();
    }
    #end


    function testEventDispatcher_Async() {
        var executor = Executor.create(2);
        var disp = new AsyncEventDispatcher(executor);

        var listener1Count = new AtomicInt();
        var listener1 = function(event:String) {
            listener1Count.incrementAndGet();
        }

        assertTrue(disp.subscribe(listener1));
        #if !(hl)
        assertFalse(disp.subscribe(listener1));
        #end

        var fut1 = disp.fire("123");
        var fut2 = disp.fire("1234567890");

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
        var disp = new EventDispatcherWithHistory<String>(new SyncEventDispatcher<String>());

        switch(disp.fire("123").result) {
            case SUCCESS(v,_): assertEquals(0, v);
            default: fail();
        }
        switch(disp.fire("1234567890").result) {
            case SUCCESS(v,_): assertEquals(0, v);
            default: fail();
        }

        var listener1Count = new AtomicInt();
        var listener1 = function(event:String) {
            listener1Count.incrementAndGet();
        }
        assertTrue(disp.subscribeAndReplayHistory(listener1));
        #if !(hl)
        assertFalse(disp.subscribeAndReplayHistory(listener1));
        assertEquals(2, listener1Count.value);
        #end
    }


    function testEventDispatcher_Sync() {
        var disp = new SyncEventDispatcher<String>();

        var listener1Count = new AtomicInt();
        var listener1 = function(event:String) {
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
        var executor = Executor.create(2);
        assertEquals(executor.state, ServiceState.RUNNING);
        executor.stop();
        _later(200, function() {
            assertEquals(executor.state, ServiceState.STOPPED);
        });
    }


    function testTaskExecutor_shutdown_with_running_tasks() {
        var executor = Executor.create(3);
        var counter = new AtomicInt(0);
        var future = executor.submit(function() counter++, FIXED_RATE(20));
        var startAt = Dates.now();
        _later(200, function() {
            var v = counter.value;
            assertFalse(future.isStopped);
            assertTrue(v >= 10 * 0.4);
            assertTrue(v <= 10 * 1.4);
        });
        _later(220, function() {
            executor.stop();
        });
        _later(400, function() {
            assertTrue(future.isStopped);
            assertEquals(executor.state, ServiceState.STOPPED);
        });
    }


    function testTaskExecutor_schedule_ONCE() {
        var executor = Executor.create(3);

        var flag1 = new AtomicBool(false);
        var flag2 = new AtomicBool(false);
        var flag3 = new AtomicBool(false);
        var startAt = Dates.now();
        var future1 = executor.submit(function():Void flag1.negate(), ONCE(0));
        var future2 = executor.submit(function():Void flag2.negate(), ONCE(140));
        var future3 = executor.submit(function():Void flag3.negate(), ONCE(140));
        _later(30, function() {
            assertTrue(flag1.value);
            assertTrue(future1.isStopped);

            assertFalse(flag2.value);
            assertFalse(future2.isStopped);

            assertFalse(flag3.value);
            assertFalse(future3.isStopped);
            future3.cancel();
            assertFalse(flag3.value);
            assertTrue(future3.isStopped);
        });
        _later(200, function() {
            assertTrue(flag2.value);
            assertTrue(future2.isStopped);

            assertFalse(flag3.value);
            assertTrue(future3.isStopped);

            executor.stop();
        });
    }


    function testTaskExecutor_schedule_RATE_DELAY() {
        var executor = Executor.create(2);

        var intervalMS = 40;
        var threadMS = 10;

        var fixedRateCounter  = new AtomicInt(0);
        var future1 = executor.submit(function() {
            fixedRateCounter.increment();
            #if threads
            Threads.sleep(threadMS);
            #end
        }, FIXED_RATE(intervalMS));
        var v1 = new AtomicInt(0);

        #if threads
        var fixedDelayCounter = new AtomicInt(0);
        var future2 = executor.submit(function() {
            fixedDelayCounter.increment();
            Threads.sleep(threadMS);
        }, FIXED_DELAY(intervalMS));
        var v2 = new AtomicInt(0);
        #end

        var waitMS = intervalMS * 10;
        _later(waitMS, function() {
            future1.cancel();
            v1.value = fixedRateCounter.value;
            assertTrue(v1.value <= (waitMS / intervalMS) * 1.6);
            assertTrue(v1.value >= (waitMS / intervalMS) * 0.4);

            #if threads
            future2.cancel();
            v2.value = fixedDelayCounter.value;
            assertTrue(v2.value <= (waitMS / (intervalMS + threadMS)) * 1.6);
            assertTrue(v2.value >= (waitMS / (intervalMS + threadMS)) * 0.4);
            assertTrue(v1 > v2);
            #end
        });
        _later(waitMS + 2 * intervalMS, function() {
            assertEquals(v1.value, fixedRateCounter.value);
            #if threads
            assertEquals(v2.value, fixedDelayCounter.value);
            #end

            executor.stop();
        });
    }


    function testTaskExecutor_schedule_HOURLY_DAILY_WEEKLY() {
        var executor = Executor.create(3);

        var hourlyCounter  = new AtomicInt(0);
        var dailyCounter  = new AtomicInt(0);
        var weeklyCounter  = new AtomicInt(0);
        var d = Date.fromTime(Dates.now() + 2000);
        var future1 = executor.submit(function() hourlyCounter.increment(), HOURLY(d.getMinutes(), d.getSeconds()));
        var future2 = executor.submit(function() dailyCounter.increment(),  DAILY(d.getHours(), d.getMinutes(), d.getSeconds()));
        var future3 = executor.submit(function() weeklyCounter.increment(), WEEKLY(d.getDay(), d.getHours(), d.getMinutes(), d.getSeconds()));
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


    var _asyncExecutor = Executor.create(10);
    var _asyncTests = new AtomicInt(0);
    function _later(delayMS:Int, fn:Void->Void) {
        _asyncTests++;
        var future:TaskFuture<Dynamic> = _asyncExecutor.submit(function() {
            try fn() catch (ex:Dynamic) trace(ex);
            _asyncTests--;
        }, ONCE(delayMS));
    }

    override
    function runAndExit(expectedMinNumberOfTests = 0):Void {
        results = new ThreadSafeDocTestResults();
        var startTime = Dates.now();
        run(expectedMinNumberOfTests, false);

        var t = new haxe.Timer(100);
        t.run = function() {
            if(_asyncTests.value == 0) {
                t.stop();

                var timeSpent = Std.int((Dates.now() - startTime) / 1000);

                if (results.getSuccessCount() + results.getFailureCount() == 0) {
                    // no tests defined, DocTestRunner will display warning
                } else if (results.getFailureCount() == 0) {
                    hx.doctest.internal.Logger.log(INFO, '**********************************************************');
                    hx.doctest.internal.Logger.log(INFO, 'All ${results.getSuccessCount()} test(s) were SUCCESSFUL within $timeSpent seconds.');
                    hx.doctest.internal.Logger.log(INFO, '**********************************************************');
                } else {
                    hx.doctest.internal.Logger.log(ERROR, '**********************************************************');
                    hx.doctest.internal.Logger.log(ERROR, '${results.getFailureCount()} of ${results.getSuccessCount() + results.getFailureCount()} test(s) FAILED:');
                    results.logFailures();
                }

                var exitCode = results.getFailureCount() == 0 ? 0 : 1;
                hx.doctest.DocTestRunner.exit(exitCode);
            }
        };
    }
}

private class ThreadSafeDocTestResults extends hx.doctest.DocTestRunner.DefaultDocTestResults {

    var _sync = new RLock();

    function super_add(success:Bool, msg:String, loc:hx.doctest.internal.Logger.SourceLocation, pos:haxe.PosInfos) {
        super.add(success, msg, loc, pos);
    }
    function super_logFailures() {
        super.logFailures();
    }

    override
    public function add(success:Bool, msg:String, loc:hx.doctest.internal.Logger.SourceLocation, pos:haxe.PosInfos) {
        _sync.execute(function() super_add(success, msg, loc, pos));
    }

    override
    public function getSuccessCount():Int {
        return _sync.execute(function() return _testsOK);
    }

    override
    public function getFailureCount():Int {
        return _sync.execute(function() return _testsFailed.length);
    }

    override
    public function logFailures():Void {
        return _sync.execute(function() super_logFailures());
    }
}
