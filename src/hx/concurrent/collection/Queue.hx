/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.collection;

import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.lock.RLock;
import hx.concurrent.thread.Threads;

/**
 * Unbound thread-safe first-in-first-out message queue.
 */
class Queue<T> {
   #if (cpp || cs || eval || java || neko || hl)
      final _queue = new sys.thread.Deque<T>();
   #elseif python
      final _queue:Dynamic;
   #else
      final _queue = new List<T>();
      final _queueLock = new RLock();
   #end

   public var length(get, never):Int;
   var _length = new AtomicInt(0);
   inline function get_length():Int return _length;

   public function new() {
      #if python
          python.Syntax.code("import collections");
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
         #if (cpp || cs || eval || java || neko || hl)
            msg = _queue.pop(false);
         #elseif python
            msg = try _queue.pop() catch(e:Dynamic) null;
         #else
            _queueLock.acquire();
            msg = _queue.pop();
            _queueLock.release();
         #end
      } else {
          Threads.await(function() {
            #if (cpp || cs || eval || java || neko || hl)
               msg = _queue.pop(false);
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
      final msg = _queue.pop();
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

      #if (cpp || cs || eval || java || neko || hl)
         _queue.push(msg);
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

      #if (cpp || cs || eval || java || neko || hl)
         _queue.add(msg);
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
