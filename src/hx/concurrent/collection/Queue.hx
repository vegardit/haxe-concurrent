/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.collection;

import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.lock.RLock;
import hx.concurrent.thread.Threads;

/**
 * Unbound thread-safe first-in-first-out message queue.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Queue<T> {

   #if ((haxe_ver >= 4) && (eval || neko || cpp || hl || java || cs))
      var _queue = new sys.thread.Deque<T>();
   #elseif cpp
      var _queue = new cpp.vm.Deque<T>();
   #elseif (hl && (haxe_ver >= 4))
      var _queue = new hl.vm.Deque<T>();
   #elseif neko
      var _queue = new neko.vm.Deque<T>();
   #elseif java
      var _queue = new java.util.concurrent.ConcurrentLinkedDeque<T>();
   #elseif python
      var _queue:Dynamic;
   #else
      var _queue = new List<T>();
      var _queueLock = new RLock();
   #end

   public var length(get, never):Int;
   var _length = new AtomicInt(0);
   inline function get_length():Int return _length;

   public function new() {
      #if python
         #if (haxe_ver >= 4)
            python.Syntax.code("import collections");
         #else
            python.Syntax.pythonCode("import collections");
         #end
         _queue = untyped collections.deque();
      #end
   }


   #if threads
   /**
    * Pop a message from the queue head.
    *
    * By default (with timeoutMS=0) this function is non-blocking, meaning if no message is available in the queue
    * `null` is returned immediately.
    *
    * If <code>timeoutMS</code> is set to value > 0, the function waits up to the given timespan for a new message.
    * If <code>timeoutMS</code> is set to `-1`, the function waits indefinitely until a new message is available.
    * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
    */
   public function pop(timeoutMS:Int = 0):Null<T> {
      var msg:Null<T> = null;

      if (timeoutMS < -1)
         throw "[timeoutMS] must be >= -1";

      if (timeoutMS == 0) {
         #if ((haxe_ver >= 4) && (eval || neko || cpp || hl || java || cs))
            msg = _queue.pop(false);
         #elseif (cpp||neko)
            msg = _queue.pop(false);
         #elseif java
            msg = _queue.poll();
         #elseif python
            msg = try _queue.pop() catch(e:Dynamic) null;
         #else
            _queueLock.acquire();
            msg = _queue.pop();
            _queueLock.release();
         #end
      } else {
          Threads.await(function() {
            #if ((haxe_ver >= 4) && (eval || neko || cpp || hl || java || cs))
               msg = _queue.pop(false);
            #elseif (cpp||neko)
               msg = _queue.pop(false);
            #elseif java
               msg = _queue.poll();
            #elseif python
               msg = try _queue.pop() catch(e:Dynamic) null;
            #else
               _queueLock.acquire();
               msg = _queue.pop();
               _queueLock.release();
            #end
            return msg != null;
         }, timeoutMS);
      }
      if (msg != null) _length--;
      return msg;
   }
   #else
   public function pop():Null<T> {
      _queueLock.acquire();
      var msg = _queue.pop();
      if (msg != null) _length--;
      _queueLock.release();
      return msg;
   }
   #end


   /**
    * Skips the quue and adds the given message to the head of the queue.
    *
    * @throws exception if given msg is null
    */
   public function pushHead(msg:T):Void {
      if (msg == null)
         throw "[msg] must not be null";

      #if ((haxe_ver >= 4) && (eval || neko || cpp || hl || java || cs))
         _queue.push(msg);
      #elseif (cpp||neko)
         _queue.push(msg);
      #elseif java
         _queue.addFirst(msg);
      #elseif python
         _queue.append(msg);
      #else
         _queueLock.acquire();
         _queue.push(msg);
         _queueLock.release();
      #end
      _length++;
   }


   /**
    * Add a message at the end of the queue.
    *
    * @throws exception if given msg is null
    */
   public function push(msg:T):Void {
      if (msg == null)
         throw "[msg] must not be null";

      #if ((haxe_ver >= 4) && (eval || neko || cpp || hl || java || cs))
         _queue.add(msg);
      #elseif (cpp||neko)
         _queue.add(msg);
      #elseif java
         _queue.addLast(msg);
      #elseif python
         _queue.appendleft(msg);
      #else
         _queueLock.acquire();
         _queue.add(msg);
         _queueLock.release();
      #end
      _length++;
   }
}
