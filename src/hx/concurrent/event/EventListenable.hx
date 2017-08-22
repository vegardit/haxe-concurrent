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

    var _eventListeners = new Array<EVENT->Void>();
    var _eventListenersLock = new RLock();

    public function subscribe(listener:EVENT->Void):Bool  {
        if (listener == null)
            throw "[listener] must not be null";

        return _eventListenersLock.execute(function() {
            if (_eventListeners.indexOf(listener) > -1)
                return false;

            var newList = _eventListeners.copy();
            newList.push(listener);
            _eventListeners = newList;
            return true;
        });
    }


    public function unsubscribe(listener:EVENT->Void):Bool {
        if (listener == null)
            throw "[listener] must not be null";

        return _eventListenersLock.execute(function() {
            if (_eventListeners.indexOf(listener) == -1)
                return false;

            var newList = _eventListeners.copy();
            newList.remove(listener);
            _eventListeners = newList;
            return true;
        });
    }
}
