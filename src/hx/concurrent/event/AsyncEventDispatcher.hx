/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.Future;
import hx.concurrent.executor.Executor;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class AsyncEventDispatcher<EVENT> extends EventListenable.DefaultEventListenable<EVENT> implements EventDispatcher<EVENT> {

    var _executor:Executor;


    public function new(executor:Executor) {
        if (executor == null)
            throw "[executor] must not be null";

        this._executor = executor;
    }


    /**
     * @return the number of listeners notified successfully
     */
    public function fire(event:EVENT):Future<Int> {
        return _executor.submit(function():Int {
            var count = 0;
            for (listener in _eventListeners.iterator()) {
                try {
                    listener(event);
                    count++;
                } catch (ex:Dynamic) {
                    trace(ex);
                }
            }
            return count;
        });
    }


    inline override
    public function unsubscribeAll():Void {
        super.unsubscribeAll();
    }
}
