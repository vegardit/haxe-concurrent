/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.lock;

import hx.concurrent.atomic.AtomicBool;
import hx.concurrent.internal.Dates;
import hx.concurrent.internal.Ints;
import hx.concurrent.ConcurrentException;
import hx.concurrent.thread.Threads;

/**
 * A upgradeable re-entrant read-write lock where locks can only be released by the same thread that acquired them.
 *
 * A thread can acquire a write-lock (upgrade) while holding a read-lock if no other thread holds a read-lock at the same time.
 *
 * https://stackoverflow.com/questions/2332765/lock-mutex-semaphore-whats-the-difference
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:allow(hx.concurrent.lock.ReadLock)
@:allow(hx.concurrent.lock.WriteLock)
class RWLock {

   public var readLock(default, null):ReadLock;
   public var writeLock(default, null):WriteLock;

   var sync(default, null) = new RLock();

   inline
   public function new() {
      readLock = new ReadLock(this);
      writeLock = new WriteLock(this);
   }
}


@:allow(hx.concurrent.lock.RWLock)
@:allow(hx.concurrent.lock.WriteLock)
class ReadLock implements Acquirable {

   public var availablePermits(get, never):Int;
   function get_availablePermits():Int {
      if (rwLock.writeLock.isAcquiredByOtherThread)
         return 0;

      return rwLock.sync.execute(function() {
         return Ints.MAX_VALUE - holders.length;
      });
   }


   /**
    * Indicates if the lock is acquired by any thread
    */
   public var isAcquiredByAnyThread(get, null):Bool;
   inline function get_isAcquiredByAnyThread():Bool
      return rwLock.sync.execute(function() {
         return holders.length > 0;
      });


   /**
    * Indicates if the lock is acquired by the current thread
    */
   public var isAcquiredByCurrentThread(get, null):Bool;
   inline function get_isAcquiredByCurrentThread():Bool
      return rwLock.sync.execute(function() {
         return holders.indexOf(Threads.current) > -1;
      });


   /**
    * Indicates if the lock is acquired by any other thread
    */
   public var isAcquiredByOtherThread(get, null):Bool;
   inline function get_isAcquiredByOtherThread():Bool {
      var requestor = Threads.current;
      return rwLock.sync.execute(function() {
         if (holders.length == 0)
            return false;

         for (holder in holders)
            if (holder != requestor)
               return true;
         return false;
      });
   }


   var rwLock:RWLock;
   var holders = new Array<Dynamic>();


   inline
   function new(rwLock:RWLock)
       this.rwLock = rwLock;


   public function acquire():Void {
      while (true) {
         if (tryAcquire(Ints.MAX_VALUE))
            return;
      }
   }


   public function tryAcquire(timeoutMS:Int = 0):Bool {
      var requestor = Threads.current;

      var startAt = Dates.now();
      while (true) {
         if (rwLock.sync.execute(function() {
            if(rwLock.writeLock.isAcquiredByOtherThread)
               return false;

            holders.push(requestor);
            return true;
         }))
            return true;

         var elapsedMS = Dates.now() - startAt;
         if (elapsedMS >= timeoutMS)
            return false;
      }
   }


   public function release():Void
      rwLock.sync.execute(function() {
         if (!holders.remove(Threads.current))
            throw "This lock was not acquired by the current thread!";
      });
}


@:allow(hx.concurrent.lock.RWLock)
@:allow(hx.concurrent.lock.ReadLock)
class WriteLock extends RLock {

   var rwLock:RWLock;

   inline function new(rwLock:RWLock) {
      super();
      this.rwLock = rwLock;
   }

   override
   function get_availablePermits():Int {
      if (isAcquiredByAnyThread)
         return 0;

      return rwLock.sync.execute(function() {
         var readLockHolders = rwLock.readLock.holders;

         // no read locks?
         if (readLockHolders.length == 0)
            return 1;

         // read locks held by other threads?
         var requestor = Threads.current;
         for (holder in readLockHolders)
            if (holder != requestor)
               return 0;
         return 1;
      });
   }


   override
   public function acquire():Void {
      while (true) {
         if (tryAcquire(Ints.MAX_VALUE))
            return;
      }
   }


   override
   public function tryAcquire(timeoutMS = 0):Bool {
      var requestor = Threads.current;
      var readLockHolders = rwLock.readLock.holders;

      #if (flash||sys)
      return Threads.await(function() {
         return rwLock.sync.execute(function() {
      #end
            if (readLockHolders.length > 0) {
               // read locks held by other threads?
               for (holder in readLockHolders) {
                  if (holder != requestor)
                     return false;
               }
            }
            return super_tryAcquire(50);
      #if (flash||sys)
         });
      }, timeoutMS);
      #end
   }


   override
   public function release():Void
      rwLock.sync.execute(function() {
         super_release();
      });


   function super_tryAcquire(timeoutMS = 0):Bool return super.tryAcquire(timeoutMS);
   function super_release():Void return super.release();
}
