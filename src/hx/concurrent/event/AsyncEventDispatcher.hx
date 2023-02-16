/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.Future;
import hx.concurrent.executor.Executor;

class AsyncEventDispatcher<EVENT> extends EventListenable.AbstractEventListenable<EVENT> implements EventDispatcher<EVENT> {

   final _executor:Executor;


   public function new(executor:Executor) {
      if (executor == null)
         throw "[executor] must not be null";

      this._executor = executor;
   }


   /**
    * @return the number of listeners notified successfully
    */
   public function fire(event:EVENT):Future<Int>
      return _executor.submit(function():Int {
         var count = 0;
         for (listener in _eventListeners.iterator()) {
            try {
               listener(event);
               count++;
            } catch (ex) {
               trace(ex);
            }
         }
         return count;
      });


   override //
   public function unsubscribeAll():Void
      super.unsubscribeAll();
}
