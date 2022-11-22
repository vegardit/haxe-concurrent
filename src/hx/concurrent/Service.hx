/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent;

import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.lock.RLock;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface Service<T> {

   var id(default, null):T;

   var state(default, null):ServiceState;

   function start():Void;

   function stop():Void;

   function toString():String;
}


enum ServiceState {
   STARTING;
   RUNNING;
   STOPPING;
   STOPPED;
}


abstract class ServiceBase implements Service<Int> {

   static final _ids = new AtomicInt();

   public final id = _ids.incrementAndGet();

   public var state(default, set):ServiceState = STOPPED;
   function set_state(s:ServiceState) {
      switch(s) {
         case STARTING: trace('[$this] is starting...');
         case RUNNING: trace('[$this] is running.');
         case STOPPING: trace('[$this] is stopping...');
         case STOPPED: trace('[$this] is stopped.');
      }
      return state = s;
   }
   final _stateLock:RLock = new RLock();


   function new() {
      trace('[$this] instantiated.');
   }


   public function start():Void {
      _stateLock.execute(function() {
         switch(state) {
            case STARTING:  {/*nothing to do*/};
            case RUNNING:  {/*nothing to do*/};
            case STOPPING: throw 'Service [$this] is currently stopping!';
            case STOPPED:  {
               state = STARTING;
               onStart();
               state = RUNNING;
            }
         }
      });
   }


   function onStart():Void {
       // override if required
   }


   public function stop():Void {
      _stateLock.execute(function() {
         if (state == RUNNING) {
            state = STOPPING;
            onStop();
            state = STOPPED;
          }
      });
   }


   function onStop():Void {
      // override if required
   }


   public function toString():String {
      #if js @:nullSafety(Off) #end
      return Type.getClassName(Type.getClass(this)) + "#" + id;
   }
}
