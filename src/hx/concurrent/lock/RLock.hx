/*
 * Copyright (c) 2016-2022 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.lock;

import hx.concurrent.lock.Acquirable.AbstractAcquirable;
import hx.concurrent.internal.Dates;
import hx.concurrent.thread.Threads;

/**
 * A re-entrant lock that can only be released by the same thread that acquired it.
 *
 * https://stackoverflow.com/questions/2332765/lock-mutex-semaphore-whats-the-difference
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class RLock extends AbstractAcquirable {

   /**
    * Indicates if this class will have any effect on the current target.
    * Currently: CPP, CS, Flash, HashLink, Java, Neko, Python.
    */
   public static inline final isSupported = #if (threads || flash) true #else false #end;

   #if (cpp || cs || eval || java || neko || hl)
   final _rlock = new sys.thread.Mutex();
   #elseif flash
      // flash.concurrent.Mutex requries swf-version >= 11.4
      // flash.concurrent.Condition requries swf-version >= 11.5
      final _cond = new flash.concurrent.Condition(new flash.concurrent.Mutex());
   #elseif python
      final _rlock = new python.lib.threading.RLock();
   #end

   var _holder:Null<Dynamic> = null;
   var _holderEntranceCount = 0;


   function get_availablePermits():Int
      return isAcquiredByAnyThread ? 0 : 1;


   /**
    * Indicates if the lock is acquired by any thread
    */
   public var isAcquiredByAnyThread(get, never):Bool;
   inline function get_isAcquiredByAnyThread():Bool
      return _holder != null;


   /**
    * Indicates if the lock is acquired by the current thread
    */
   public var isAcquiredByCurrentThread(get, never):Bool;
   inline function get_isAcquiredByCurrentThread():Bool
      return _holder == Threads.current;


   /**
    * Indicates if the lock is acquired by any other thread
    */
   public var isAcquiredByOtherThread(get, never):Bool;
   inline function get_isAcquiredByOtherThread():Bool
      return isAcquiredByAnyThread && !isAcquiredByCurrentThread;


   inline
   public function new() {
   }


   /**
    * Blocks until lock can be acquired.
    */
   public function acquire():Void {
      #if (cpp || cs || eval || java || neko || hl || python)
         _rlock.acquire();
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
         _holder = Threads.current;
         _holderEntranceCount++;
         return true;
      }

      return false;
   }


   #if !flash inline #end
   private function tryAcquireInternal(timeoutMS = 0):Bool {
      #if (cpp || cs || eval || java || neko || hl)
         return Threads.await(() -> _rlock.tryAcquire(), timeoutMS);
      #elseif python
         return Threads.await(() -> _rlock.acquire(false), timeoutMS);
      #elseif flash
         final startAt = Dates.now();
         while (true) {
            if (_cond.mutex.tryLock())
               return true;

            final elapsedMS = Dates.now() - startAt;
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
         _holderEntranceCount--;
         if (_holderEntranceCount == 0)
            _holder = null;
      } else if (isAcquiredByOtherThread) {
         throw "Lock was aquired by another thread!";
      } else
         throw "Lock was not aquired by any thread!";

      #if (cpp || cs || eval || java || neko || hl || python)
         _rlock.release();
      #elseif flash
         _cond.notify();
         _cond.mutex.unlock();
      #else
         // single-threaded targets: js,lua,php
      #end
   }
}
