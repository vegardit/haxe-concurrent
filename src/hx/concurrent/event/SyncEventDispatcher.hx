/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.Future.ConstantFuture;

class SyncEventDispatcher<EVENT> extends EventListenable.AbstractEventListenable<EVENT> implements EventDispatcher<EVENT> {

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
         } catch (ex) {
            trace(ex);
         }
      }
      return new ConstantFuture(count);
   }


   override
   public function unsubscribeAll():Void
      super.unsubscribeAll();
}
