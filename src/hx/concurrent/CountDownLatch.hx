/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent;

import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.lock.RLock;
import hx.concurrent.thread.Threads;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
#if java
abstract CountDownLatch(java.util.concurrent.CountDownLatch) {

   public var count(get, never):Int;
   inline function get_count():Int
      return haxe.Int64.toInt(this.getCount());


   inline
   public function new(count:Int) {
      this = new java.util.concurrent.CountDownLatch(count);
   }


   inline
   public function countDown():Void
      this.countDown();


   inline
   public function await():Void
      this.await();


   inline
   public function tryAwait(timeoutMS:Int):Bool
      return this.await(timeoutMS, java.util.concurrent.TimeUnit.MILLISECONDS);
}
#elseif threads
class CountDownLatch {

   public var count(get, null):Int;
   inline function get_count():Int
      return _count;

   var _count:AtomicInt;


   inline
   public function new(count:Int) {
      _count = new AtomicInt(count);
   }


   inline
   public function countDown():Void
      _count--;


   public function await():Void
      while(_count > 0)
         Threads.sleep(10);


   public function tryAwait(timeoutMS:Int):Bool
      return Threads.await(() -> count < 1, timeoutMS);
}
#end
