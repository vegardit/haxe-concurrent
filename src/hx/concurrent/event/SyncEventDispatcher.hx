/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.Future.ConstantFuture;

/**
 *
 * @author <a href="http://sebthom.de/">Sebastian Thomschke</a>
 */
class SyncEventDispatcher<EVENT> extends EventListenable.DefaultEventListenable<EVENT> implements EventDispatcher<EVENT> {

    public function new() {
    }

    /**
     * @return the number of listeners notified successfully
     */
    public function fire(event:EVENT):ConstantFuture<Int> {
        var count = 0;
        for (listener in _eventListeners.iterator()) {
            try {
                listener(event);
                count++;
            } catch (ex:Dynamic) {
                trace(ex);
            }
        }
        return new ConstantFuture(count);
    }


    override
    public function unsubscribeAll():Void {
        super.unsubscribeAll();
    }
}
