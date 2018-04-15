/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.Future;
import hx.concurrent.lock.RLock;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class EventDispatcherWithHistory<EVENT> implements EventDispatcher<EVENT> {
    var _eventHistory = new Array<EVENT>();
    var _eventHistoryLock = new RLock();
    var _wrapped:EventDispatcher<EVENT>;


    public function new(wrapped:EventDispatcher<EVENT>) {
        _wrapped = wrapped;
    }


    inline
    public function clearHistory():Void {
        _eventHistoryLock.execute(function() _eventHistory = []);
    }


    inline
    public function fire(event:EVENT):Future<Int> {
        _eventHistoryLock.execute(function() _eventHistory.push(event));
        return _wrapped.fire(event);
    }


    /**
     * If the listener was not subscribed already, all recorded events will be send to the given listeners.
     */
    public function subscribeAndReplayHistory(listener:EVENT->Void):Bool {
        if (listener == null)
            throw "[listener] must not be null";

        if (_wrapped.subscribe(listener)) {
            for (event in _eventHistory)
                listener(event);
            return true;
        }

        return false;
    }


    inline
    public function subscribe(listener:EVENT->Void):Bool {
        return _wrapped.subscribe(listener);
    }


    inline
    public function unsubscribe(listener:EVENT->Void):Bool {
        return _wrapped.unsubscribe(listener);
    }


    inline
    public function unsubscribeAll():Void {
        _wrapped.unsubscribeAll();
    }
}
