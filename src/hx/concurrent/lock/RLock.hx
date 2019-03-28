/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.lock;

import hx.concurrent.internal.Dates;
import hx.concurrent.ConcurrentException;
import hx.concurrent.thread.Threads;

/**
 * A re-entrant lock that can only be released by the same thread that acquired it.
 *
 * https://stackoverflow.com/questions/2332765/lock-mutex-semaphore-whats-the-difference
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class RLock implements Acquirable {

    /**
     * Indicates if this class will have any effect on the current target.
     * Currently: CPP, CS, Flash, HashLink, Java, Neko, Python.
     */
    public static inline var isSupported = #if (interp||cpp||cs||flash||hl||java||neko||python) true #else false #end;

    #if ((haxe_ver >= 4) && (interp || neko || cpp || hl || java))
        var _rlock = new sys.thread.Mutex();
    #elseif cpp
        var _rlock = new cpp.vm.Mutex();
    #elseif cs
        // nothing to do
    #elseif flash
        // flash.concurrent.Mutex requries swf-version >= 11.4
        // flash.concurrent.Condition requries swf-version >= 11.5
        var _cond = new flash.concurrent.Condition(new flash.concurrent.Mutex());
    #elseif java
        var _rlock = new java.util.concurrent.locks.ReentrantLock();
    #elseif neko
        var _rlock = new neko.vm.Mutex();
    #elseif python
        var _rlock = new python.lib.threading.RLock();
    #end

    var _holder:Dynamic = null;
    var _holderEntranceCount = 0;


    public var availablePermits(get, never):Int;
    function get_availablePermits():Int return isAcquiredByAnyThread ? 0 : 1;


    /**
     * Indicates if the lock is acquired by any thread
     */
    public var isAcquiredByAnyThread(get, null):Bool;
    inline function get_isAcquiredByAnyThread():Bool {
        #if (((haxe_ver >= 4) && java) || !java)
            return _holder != null;
        #else
            return _rlock.isLocked();
        #end
    }

    /**
     * Indicates if the lock is acquired by the current thread
     */
    public var isAcquiredByCurrentThread(get, null):Bool;
    inline function get_isAcquiredByCurrentThread():Bool {
        #if (((haxe_ver >= 4) && java) || !java)
            return _holder == Threads.current;
        #else
            return _rlock.isHeldByCurrentThread();
        #end
    }


    /**
     * Indicates if the lock is acquired by any other thread
     */
    public var isAcquiredByOtherThread(get, null):Bool;
    inline function get_isAcquiredByOtherThread():Bool return isAcquiredByAnyThread && !isAcquiredByCurrentThread;


    inline
    public function new() {
    }


    /**
     * Executes the given function while the lock is acquired.
     */
    public function execute<T>(func:Void->T, swallowExceptions = false):T {
        var ex:ConcurrentException = null;
        var result:T = null;

        acquire();
        try {
            result = func();
        } catch (e:Dynamic) {
            ex = ConcurrentException.capture(e);
        }
        release();

        if (!swallowExceptions && ex != null)
            ex.rethrow();
        return result;
    }


    /**
     * Blocks until lock can be acquired.
     */
    public function acquire():Void {
        #if ((haxe_ver >= 4) && (interp || neko || cpp || hl || java))
            _rlock.acquire();
        #elseif cs
            cs.system.threading.Monitor.Enter(this);
        #elseif (cpp||neko||python)
            _rlock.acquire();
        #elseif java
            _rlock.lock();
        #elseif flash
            _cond.mutex.lock();
        #else
            // single-threaded targets: js,lua,php
        #end

        _holder = Threads.current;
        _holderEntranceCount++;
    }


    /**
     * By default this call is non-blocking, meaning if the lock cannot be acquired `false` is returned immediately.
     *
     * If <code>timeoutMS</code> is set to value > 0, results in blocking for the given time to aqcuire the lock.
     * If <code>timeoutMS</code> is set to value lower than -0, results in an exception.
     *
     * @return `false` if lock could not be acquired
     */
    public function tryAcquire(timeoutMS = 0):Bool {
        if (timeoutMS < 0) throw "[timeoutMS] must be >= 0";

        if (tryAcquireInternal(timeoutMS)) {
            #if (((haxe_ver >= 4) && java) || !java)
            _holder = Threads.current;
            _holderEntranceCount++;
            #end
            return true;
        }

        return false;
    }


    #if !flash inline #end
    private function tryAcquireInternal(timeoutMS = 0):Bool {
        #if ((haxe_ver >= 4) && (interp || neko || cpp || hl || java))
            return Threads.await(function() return _rlock.tryAcquire(), timeoutMS);
        #elseif cs
            return cs.system.threading.Monitor.TryEnter(this, timeoutMS);
        #elseif (cpp||neko)
            return Threads.await(function() return _rlock.tryAcquire(), timeoutMS);
        #elseif java
            return _rlock.tryLock(timeoutMS, java.util.concurrent.TimeUnit.MILLISECONDS);
        #elseif python
            return Threads.await(function() return _rlock.acquire(false), timeoutMS);
        #elseif flash
            var startAt = Dates.now();
            while (true) {
                if (_cond.mutex.tryLock())
                    return true;

                var elapsedMS = Dates.now() - startAt;
                if (elapsedMS >= timeoutMS)
                    return false;

                // wait for mutex to be released by other thread
                _cond.wait(timeoutMS - elapsedMS);
            }
        #else
            // single-threaded targets: js,lua,php
            return _holder == null || _holder == Threads.current;
        #end
    }


    /**
     * Releases the lock.
     *
     * @throws an exception if the lock was not acquired by the current thread
     */
    public function release():Void {
        if (isAcquiredByCurrentThread) {
            #if (((haxe_ver >= 4) && java) || !java)
                _holderEntranceCount--;
                if (_holderEntranceCount == 0)
                    _holder = null;
            #end
        } else if (isAcquiredByOtherThread) {
            throw "Lock was aquired by another thread!";
        }
        else
            throw "Lock was not aquired by any thread!";

        #if ((haxe_ver >= 4) && (interp || neko || cpp || hl || java))
            _rlock.release();
        #elseif cs
            cs.system.threading.Monitor.Exit(this);
        #elseif (cpp||neko||python)
            _rlock.release();
        #elseif java
            _rlock.unlock();
        #elseif flash
            _cond.notify();
            _cond.mutex.unlock();
        #else
            // single-threaded targets: js,lua,php
        #end
    }
}
