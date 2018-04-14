/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.thread;

import haxe.ds.StringMap;
import hx.concurrent.Service.ServiceBase;
import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.collection.Queue;
import hx.concurrent.thread.Threads;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
#if threads
class ThreadPool extends ServiceBase {

    static var _threadIDs(default, never) = new AtomicInt();

    var _threadCount = new AtomicInt(0);
    var _workQueue = new Queue<Task>();
    var _workQueueSize = new AtomicInt();


    public function new(numThreads:Int) {
        if (numThreads < 1)
            throw "[numThreads] must be > 0";

        super();

        /*
         * start worker threads
         */
        for (i in 0...numThreads) {
            Threads.spawn(function() {
                _threadCount++;

                var context = new ThreadContext(_threadIDs.incrementAndGet());

                trace('[$this] Spawned thread $_threadCount/$numThreads with ID ${context.id}.');

                while (true) {
                    var task = _workQueue.pop();
                    if (task == null) {
                        if(state != RUNNING)
                            break;
                        Sys.sleep(0.001);
                    } else {
                        try {
                            task(context);
                        } catch (ex:Dynamic) {
                            trace(ex);
                        }
                    }
                }

                trace('[$this] Stopped thread with ID ${context.id}.');

                _threadCount--;

                if (_threadCount == 0)
                    _stateLock.execute(function() {
                        state = STOPPED;
                    });
            });
        }
    }


    /**
     * Submits a task for immediate execution in a thread.
     */
    public function submit(task:Task):Void {
        if (task == null)
            throw "[task] must not be null";

        _workQueue.push(task);
    }


    /**
     * Initiates a graceful shutdown of this executor. Canceling execution of all scheduled tasks.
     */
    override
    public function stop() {
        super.stop();
    }
}


typedef Task=ThreadContext->Void;


class ThreadContext {
    /**
     * ID of the current thread
     */
    public var id(default, null):Int;
    public var vars(default, never) = new StringMap<Dynamic>();

    inline
    public function new(id:Int) {
        this.id = id;
    }
}
#end
