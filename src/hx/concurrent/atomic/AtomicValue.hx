/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.atomic;

import hx.concurrent.lock.RLock;

/**
 * Value holder with thread-safe accessors.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class AtomicValue<T> {

   final _lock = new RLock();

   /**
    * <pre><code>
    * >>> new AtomicValue(null).value   == null
    * >>> new AtomicValue(true).value   == true
    * >>> new AtomicValue("cat").value  == "cat"
    * </code></pre>
    */
   public var value(get, never):T;
   var _value:T;
   function get_value():T {
      _lock.acquire();
      var result = _value;
      _lock.release();
      return result;
   }


   public function new(initialValue:T) {
      this._value = initialValue;
   }


   /**
    * <pre><code>
    * >>> new AtomicValue("cat").getAndSet("dog") == "cat"
    * </code></pre>
    */
   public function getAndSet(value:T):T {
      _lock.acquire();
      var old = _value;
      _value = value;
      _lock.release();
      return old;
   }


   public function set(value:T):Void {
      _lock.acquire();
      this._value = value;
      _lock.release();
   }


   /**
    * <pre><code>
    * >>> new AtomicValue(true).toString()  == "true"
    * >>> new AtomicValue(false).toString() == "false"
    * </code></pre>
    */
   inline
   public function toString()
      return Std.string(value);
}
