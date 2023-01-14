/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.lock;

import hx.concurrent.internal.Dates;
import hx.concurrent.internal.Ints;
import hx.concurrent.lock.Acquirable.AbstractAcquirable;
import hx.concurrent.thread.Threads;

/**
 * A upgradeable re-entrant read-write lock where locks can only be released by the same thread that acquired them.
 *
 * A thread can acquire a write-lock (upgrade) while holding a read-lock if no other thread holds a read-lock at the same time.
 *
 * https://stackoverflow.com/questions/2332765/lock-mutex-semaphore-whats-the-difference
 */
@:allow(hx.concurrent.lock.ReadLock)
@:allow(hx.concurrent.lock.WriteLock)
@:nullSafety(Off)
class RWLock {

   public final readLock:ReadLock;
   public final writeLock:WriteLock;

   final sync = new RLock();

   inline
   public function new() {
      readLock = new ReadLock(this);
      writeLock = new WriteLock(this);
   }
}


@:allow(hx.concurrent.lock.RWLock)
@:allow(hx.concurrent.lock.WriteLock)
class ReadLock extends AbstractAcquirable {

   function get_availablePermits():Int {
      if (rwLock.writeLock.isAcquiredByOtherThread)
         return 0;

      return rwLock.sync.execute(() -> Ints.MAX_VALUE - holders.length);
   }


   /**
    * Indicates if the lock is acquired by any thread
    */
   public var isAcquiredByAnyThread(get, never):Bool;
   inline function get_isAcquiredByAnyThread():Bool
      return rwLock.sync.execute(() -> holders.length > 0);


   /**
    * Indicates if the lock is acquired by the current thread
    */
   public var isAcquiredByCurrentThread(get, never):Bool;
   inline function get_isAcquiredByCurrentThread():Bool
      return rwLock.sync.execute(() -> holders.indexOf(Threads.current) > -1);


   /**
    * Indicates if the lock is acquired by any other thread
    */
   public var isAcquiredByOtherThread(get, never):Bool;
   inline function get_isAcquiredByOtherThread():Bool {
      final requestor = Threads.current;
      return rwLock.sync.execute(function() {
         if (holders.length == 0)
            return false;

         for (holder in holders)
            if (holder != requestor)
               return true;
         return false;
      });
   }


   final rwLock:RWLock;
   final holders = new Array<Dynamic>();


   inline
   function new(rwLock:RWLock) {
       this.rwLock = rwLock;
   }


   public function acquire():Void {
      while (true) {
         if (tryAcquire(Ints.MAX_VALUE))
            return;
      }
   }


   public function tryAcquire(timeoutMS:Int = 0):Bool {
      final requestor = Threads.current;

      final startAt = Dates.now();
      while (true) {
         if (rwLock.sync.execute(function() {
            if(rwLock.writeLock.isAcquiredByOtherThread)
               return false;

            holders.push(requestor);
            return true;
         }))
            return true;

         final elapsedMS = Dates.now() - startAt;
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

   final rwLock:RWLock;

   inline function new(rwLock:RWLock) {
      super();
      this.rwLock = rwLock;
   }

   override
   function get_availablePermits():Int {
      if (isAcquiredByAnyThread)
         return 0;

      return rwLock.sync.execute(function() {
         final readLockHolders = rwLock.readLock.holders;

         // no read locks?
         if (readLockHolders.length == 0)
            return 1;

         // read locks held by other threads?
         final requestor = Threads.current;
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
      final requestor = Threads.current;
      final readLockHolders = rwLock.readLock.holders;

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
      rwLock.sync.execute(() -> super_release());


   function super_tryAcquire(timeoutMS = 0):Bool return super.tryAcquire(timeoutMS);
   function super_release():Void return super.release();
}
