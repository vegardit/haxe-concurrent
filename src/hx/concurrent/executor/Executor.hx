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
package hx.concurrent.executor;

import hx.concurrent.Future.FutureResult;
import hx.concurrent.internal.Either2;

/**
 * A scheduler/work manager that executes submitted tasks asynchronously or concurrently
 * based on a given schedule.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Executor {

    static var NOW_ONCE = Schedule.ONCE(0);


    /**
     * Creates a new target specific task executor instance.
     *
     * @param maxConcurrent maximum number of concurrently executed tasks. Has no effect on targets without thread support.
     */
    public static function create(maxConcurrent:Int = 1):Executor {
        #if (cpp||cs||java||neko||python)
            return new ThreadBasedExecutor(maxConcurrent);
        #else
            return new TimerBasedExecutor();
        #end
    }


    public var state(default, null):ExecutorState = RUNNING;
    var _stateLock:RLock = new RLock();


    /**
     * Submits the given task for background execution.
     *
     * @param task the function to be executed either `function():T {}` or `function():Void {}`
     * @param schedule the task's execution schedule, if not specified Schedule.ONCE(0) is used
     *
     * @throws exception if in state TaskExecutorState#STOPPING or TaskExecutorState#STOPPED
     */
    public function submit<T>(task:Either2<Void->T,Void->Void>, ?schedule:Schedule):TaskFuture<T> {
        throw "Not implemented";
    }


    /**
     * Initiates a graceful shutdown of this executor. Canceling execution of all scheduled tasks.
     */
    public function stop() {
        _stateLock.execute(function() {
            if (state == ExecutorState.RUNNING)
                state = ExecutorState.STOPPING;
        });
    }
}


/**
 * Represents the runtime state of an executore instance
 */
enum ExecutorState {
    /**
     * Executor accepts new tasks and processes submitted tasks.
     */
    RUNNING;

    /**
     * Executor is shutting down and does not accept new tasks but is currently executing previously submitted tasks.
     */
    STOPPING;

    /**
     * Executor does not accept new tasks and does not process any previously submitted tasks.
     */
    STOPPED;
}


interface TaskFuture<T> extends Future<T> {

    /**
     * The effective schedule of the task.
     */
    public var schedule(default, null):Schedule;

    /**
     * @return true if no future executions are scheduled
     */
    public var isStopped(default, null):Bool;

    /**
     * Prevents any further scheduled executions of this task.
     */
    public function cancel():Void;

    #if (cpp||cs||java||neko||python)
    /**
     * If <code>timeoutMS</code> is set 0, the function immediatly returns.
     * If <code>timeoutMS</code> is set to value > 0, this function waits for the given time until a result is available.
     * If <code>timeoutMS</code> is set to `-1`, this function waits indefinitely until a result is available.
     * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
     *
     * @return result of the last execution
     */
    public function waitAndGet(timeoutMS:Int):FutureResult<T>;
    #end
}
