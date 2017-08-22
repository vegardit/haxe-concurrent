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
        var listeners = _eventListeners;

        return _eventListenersLock.execute(function() {
            var count = 0;
            for (listener in listeners) {
                try {
                    listener(event);
                    count++;
                } catch (ex:Dynamic) {
                    trace(ex);
                }
            }
            return new ConstantFuture(count);
        });
    }


    public function unsubscribeAll():Void {
        _eventListenersLock.execute(function() _eventListeners = []);
    }
}
