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
package hx.concurrent;

import hx.concurrent.internal.Dates;

/**
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface Future<T> {

    /**
     * This function is non-blocking eaning if no result is available yet
     * <code>TaskResult.None</code> is returned.
     *
     * @return the future's computed result
     */
    public var result(default, null):FutureResult<T>;

    /**
     * Callback function `function(result:FutureResult<T>):Void` to be executed when a result comes
     * available or immediately in case a result is already present.
     *
     * Replaces any previously registered onResult function.
     */
    public var onResult(default, set):FutureResult<T>->Void;
}


enum FutureResult<T> {

    /**
     * Indicates last execution attempt successfully computed a result.
     * @param time when the result was computed
     */
    SUCCESS(result:T, time:Float, future:Future<T>);

    /**
     * Indicates an error during the last execution attempt.
     * @param time when the failure occured
     */
    FAILURE(ex:ConcurrentException, time:Float, future:Future<T>);

    /**
     * Indicates no result has been computed yet
     */
    NONE(future:Future<T>);
}


/**
 * Future with a pre-calculated result.
 */
class ConstantFuture<T> implements Future<T> {

    public var result(default, null):FutureResult<T>;

    public var onResult(default, set):FutureResult<T>->Void = null;
    inline function set_onResult(fn:FutureResult<T>->Void) {
        if(fn != null) fn(result);
        return onResult = fn;
    }

    inline
    public function new(result:T) {
        this.result = FutureResult.SUCCESS(result, Dates.now(), this);
    }
}
