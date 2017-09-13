/*
 * Copyright (c) 2017 Vegard IT GmbH, http://vegardit.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package hx.concurrent.lock;

import hx.concurrent.internal.Dates;
import hx.concurrent.ConcurrentException;
import hx.concurrent.lock.RLock;
import hx.concurrent.thread.Threads;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
abstract Semaphore(SemaphoreImpl) from SemaphoreImpl to SemaphoreImpl {

    public var availablePermits(get, never):Int;
    inline function get_availablePermits():Int return this.availablePermits;

    inline
    public function new(initialPermits:Int) {
        this = new SemaphoreImpl(initialPermits);
    }

    #if threads
    /**
     * Blocks until a permit can be acquired.
     */
    inline
    public function acquire():Void this.acquire();
    #end

    /**
     * By default this call is non-blocking, meaning if no permit can be acquired `false` is returned immediately.
     *
     * If <code>timeoutMS</code> is set to value > 0, results in blocking for the given time to aqcuire a permit.
     * If <code>timeoutMS</code> is set to value lower than 0, results in an exception.
     *
     * @return `false` if lock could not be acquired
     */
    inline
    public function tryAcquire(timeoutMS:Int = 0):Bool return this.tryAcquire(timeoutMS);

    /**
     * Increases availablePermits by one.
     */
    inline
    public function release():Void this.release();

}

#if java
private abstract SemaphoreImpl(java.util.concurrent.Semaphore) from java.util.concurrent.Semaphore to java.util.concurrent.Semaphore {

    public var availablePermits(get, never):Int;
    inline function get_availablePermits():Int return this.availablePermits();


    inline
    public function new(initialPermits:Int) {
        this = new java.util.concurrent.Semaphore(initialPermits);
    }


    inline
    public function acquire():Void {
        this.acquire();
    }


    inline
    public function tryAcquire(timeoutMS:Int = 0):Bool {
        return this.tryAcquire(timeoutMS, java.util.concurrent.TimeUnit.MILLISECONDS);
    }


    inline
    public function release():Void this.release();
}
#else
private class SemaphoreImpl {

    public var availablePermits(default, null):Int;

    var permitLock = new RLock();

    inline
    public function new(initialPermits:Int) {
        this.availablePermits = initialPermits;
    }



    #if threads
    inline
    public function acquire():Void {
        while (tryAcquire(1000) == false) { };
    }
    #end


    inline
    private function tryAcquireInternal():Bool {
        return permitLock.execute(function() {
            if (availablePermits > 0) {
                availablePermits--;
                return true;
            }
            return false;
        });
    }


    public function tryAcquire(timeoutMS:Int = 0):Bool {
        #if threads
            return Threads.wait(tryAcquireInternal, timeoutMS);
        #else
            return tryAcquireInternal();
        #end
    }


    inline
    public function release():Void {
        permitLock.acquire();
        availablePermits++;
        permitLock.release();
    }
}
#end
