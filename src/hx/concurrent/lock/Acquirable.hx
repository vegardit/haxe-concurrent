/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.lock;

interface Acquirable {

   var availablePermits(get, never):Int;

   /**
    * Blocks until a permit can be acquired.
    */
   function acquire():Void;

   /**
    * By default this call is non-blocking, meaning if the object cannot be aqcuired currently `false` is returned immediately.
    *
    * If <code>timeoutMS</code> is set to value > 0, results in blocking for the given time to aqcuire the object.
    * If <code>timeoutMS</code> is set to value lower than 0, results in an exception.
    *
    * @return `false` if lock could not be acquired
    */
   function tryAcquire(timeoutMS:Int = 0):Bool;

   /**
    * Releases one permit.
    *
    * Depending on the implementation this method may throw an exception if the current thread doesn't hold the permit.
    */
   function release():Void;

   /**
    * Executes the given function while the acquirable is acquired.
    */
   function execute<T>(func:Void->T, swallowExceptions:Bool = false):T;
}


abstract class AbstractAcquirable implements Acquirable {

   public var availablePermits(get, never):Int;
   abstract function get_availablePermits():Int;

   /**
    * Executes the given function while the lock is acquired.
    */
   public function execute<T>(func:Void->T, swallowExceptions:Bool = false):T {
      var ex:Null<ConcurrentException> = null;
      var result:Null<T> = null;

      acquire();
      try {
         result = func();
      } catch (e) {
         ex = ConcurrentException.capture(e);
      }
      release();

      if (!swallowExceptions && ex != null)
         ex.rethrow();
      @:nullSafety(Off)
      return result;
   }
}
