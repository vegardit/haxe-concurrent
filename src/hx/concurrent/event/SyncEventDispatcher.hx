/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.Future.ConstantFuture;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
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
   public function unsubscribeAll():Void
      super.unsubscribeAll();
}
