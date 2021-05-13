/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.lock;

import hx.concurrent.internal.Dates;
import hx.concurrent.ConcurrentException;
import hx.concurrent.lock.RLock;
import hx.concurrent.thread.Threads;

/**
 * See:
 * - https://en.wikipedia.org/wiki/Semaphore_(programming)
 * - https://docs.microsoft.com/en-us/dotnet/api/system.threading.semaphore
 * - http://devdocs.io/openjdk~8/java/util/concurrent/semaphore
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Semaphore implements Acquirable {

   public var availablePermits(get, never):Int;

#if java

   final _sem:java.util.concurrent.Semaphore;

   inline
   function get_availablePermits():Int return _sem.availablePermits();

   inline
   public function new(initialPermits:Int) {
      _sem = new java.util.concurrent.Semaphore(initialPermits);
   }


   inline public function acquire():Void _sem.acquire();
   inline public function tryAcquire(timeoutMS = 0):Bool return _sem.tryAcquire(timeoutMS, java.util.concurrent.TimeUnit.MILLISECONDS);
   /**
    * Increases availablePermits by one.
    */
   inline public function release():Void _sem.release();

#else
   var _availablePermits:Int;
   inline
   function get_availablePermits():Int return _availablePermits;

   final permitLock = new RLock();


   inline
   public function new(initialPermits:Int) {
      _availablePermits = initialPermits;
   }


   inline
   public function acquire():Void
      while (tryAcquire(500) == false) { };


   private function tryAcquireInternal():Bool
      return permitLock.execute(function() {
         if (_availablePermits > 0) {
            _availablePermits--;
            return true;
         }
         return false;
      });


   inline
   public function tryAcquire(timeoutMS = 0):Bool
      #if threads
         return Threads.await(tryAcquireInternal, timeoutMS);
      #else
         return tryAcquireInternal();
      #end


   /**
    * Increases availablePermits by one.
    */
   public function release():Void {
      permitLock.acquire();
      _availablePermits++;
      permitLock.release();
   }
#end
}

