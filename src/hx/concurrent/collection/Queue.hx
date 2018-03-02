/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.collection;

import hx.concurrent.lock.RLock;
import hx.concurrent.thread.Threads;

/**
 * Unbound thread-safe first-in-first-out message queue.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Queue<T> {

    #if cpp
        var _queue = new cpp.vm.Deque<T>();
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


    public function new() {
        #if python
            python.Syntax.pythonCode('import collections');
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
            #if (cpp||neko)
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
            Threads.wait(function() {
                #if (cpp||neko)
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
        return msg;
    }
    #else
    public function pop():Null<T> {
        _queueLock.acquire();
        var msg = _queue.pop();
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

        #if (cpp||neko)
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
    }


    /**
     * Add a message at the end of the queue.
     *
     * @throws exception if given msg is null
     */
    public function push(msg:T):Void {
        if (msg == null)
            throw "[msg] must not be null";

        #if (cpp||neko)
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
    }
}
