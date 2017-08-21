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
package hx.concurrent.event;

import hx.concurrent.Future;
import hx.concurrent.RLock;

/**
 * @author <a href="http://sebthom.de/">Sebastian Thomschke</a>
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
