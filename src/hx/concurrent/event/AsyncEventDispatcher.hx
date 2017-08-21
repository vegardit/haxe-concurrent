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
import hx.concurrent.executor.Executor;

/**
 *
 * @author <a href="http://sebthom.de/">Sebastian Thomschke</a>
 */
class AsyncEventDispatcher<EVENT> implements EventDispatcher<EVENT> {

    var _eventListeners = new Array<EVENT->Void>();
    var _eventListenersLock = new RLock();
    var _executor:Executor;


    public function new(executor:Executor) {
        if (executor == null)
            throw "[executor] must not be null";

        this._executor = executor;
    }


    /**
     * @return the number of listeners notified successfully
     */
    inline
    public function fire(event:EVENT):Future<Int> {
        var listeners:Array<EVENT->Void> = _eventListenersLock.execute(function() return _eventListeners.copy());
        return _executor.submit(function():Int {
            var count = 0;
            for (listener in listeners) {
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


    public function subscribe(listener:EVENT->Void):Bool  {
        if (listener == null)
            throw "[listener] must not be null";

        return _eventListenersLock.execute(function() {
            if (_eventListeners.indexOf(listener) > -1)
                return false;
            _eventListeners.push(listener);
            return true;
        });
    }


    public function unsubscribe(listener:EVENT->Void):Bool {
        if (listener == null)
            throw "[listener] must not be null";

        return _eventListenersLock.execute(function() return _eventListeners.remove(listener));
    }


    inline
    public function unsubscribeAll():Void {
        _eventListenersLock.execute(function() _eventListeners = []);
    }
}
