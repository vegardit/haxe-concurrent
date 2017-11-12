/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.collection.CopyOnWriteArray;

/**
 * @author <a href="http://sebthom.de/">Sebastian Thomschke</a>
 */
interface EventListenable<EVENT> {

    /**
     * @return false if was subscribed already
     */
    function subscribe(listener:EVENT->Void):Bool;

    /**
     * @return false if was not subscribed
     */
    function unsubscribe(listener:EVENT->Void):Bool;
}


@:abstract
class DefaultEventListenable<EVENT> implements EventListenable<EVENT> {

    var _eventListeners = new CopyOnWriteArray<EVENT->Void>();

    public function subscribe(listener:EVENT->Void):Bool  {
        if (listener == null)
            throw "[listener] must not be null";

        return _eventListeners.addIfAbsent(listener);
    }


    public function unsubscribe(listener:EVENT->Void):Bool {
        if (listener == null)
            throw "[listener] must not be null";

        return _eventListeners.remove(listener);
    }
}
