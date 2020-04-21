/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
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
   final _eventHistoryLock = new RLock();
   final _wrapped:EventDispatcher<EVENT>;


   public function new(wrapped:EventDispatcher<EVENT>) {
      _wrapped = wrapped;
   }


   public function clearHistory():Void
      _eventHistoryLock.execute(function() _eventHistory = []);


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


   public function subscribe(listener:EVENT->Void):Bool
      return _wrapped.subscribe(listener);


   public function unsubscribe(listener:EVENT->Void):Bool
      return _wrapped.unsubscribe(listener);


   public function unsubscribeAll():Void
      _wrapped.unsubscribeAll();
}
