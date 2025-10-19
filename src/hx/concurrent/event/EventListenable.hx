/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.collection.CopyOnWriteArray;

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


abstract class AbstractEventListenable<EVENT> implements EventListenable<EVENT> {

   /* explicitly specifying type of variable to prevent on Haxe 4.2+:
    * EventListenable.hx:40: characters 30-41 : { remove : (hx.concurrent.event.AbstractEventListenable.EVENT -> Void) -> Bool } has no field addIfAbsent
    */
   final _eventListeners:CopyOnWriteArray<EVENT->Void> = new CopyOnWriteArray<EVENT->Void>();


   public function subscribe(listener:EVENT->Void):Bool {
      if (listener == null)
         throw "[listener] must not be null";

      return _eventListeners.addIfAbsent(listener);
   }


   public function unsubscribe(listener:EVENT->Void):Bool {
      if (listener == null)
         throw "[listener] must not be null";

      return _eventListeners.remove(listener);
   }


   function unsubscribeAll():Void
      _eventListeners.clear();
}
