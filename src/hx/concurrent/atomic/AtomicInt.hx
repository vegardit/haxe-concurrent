/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.atomic;

import hx.concurrent.lock.RLock;

/**
 * Integer with thread-safe atomic operations.
 *
 * <pre><code>
 * >>> (new AtomicInt(3) < 4)      == true
 * >>> (new AtomicInt(3) < 4.0)    == true
 * >>> (new AtomicInt(3) > 2)      == true
 * >>> (new AtomicInt(3) > 2.0)    == true
 * >>> (new AtomicInt(3) == 3)     == true
 * >>> (new AtomicInt(3) == 3.0)   == true
 * >>> (new AtomicInt(3) != 4)     == true
 * >>> (new AtomicInt(3) != 4.0)   == true
 * >>> (-new AtomicInt(3) == -3)   == true
 * >>> (-new AtomicInt(3) == -3.0) == true
 * </code></pre>
 */
@:forward
abstract AtomicInt(AtomicIntImpl) from AtomicIntImpl to AtomicIntImpl {

   inline //
   public function new(val:Int = 0) 
      this = new AtomicIntImpl(val);

   @:to inline function toInt():Int return this.value;

   @:op(A+=B) inline function op_add_assign1(v:Int):AtomicInt       { increment(v);        return this; }
   @:op(A-=B) inline function op_sub_assign1(v:Int):AtomicInt       { increment(-v);       return this; }
   @:op(A+=B) inline function op_add_assign2(v:AtomicInt):AtomicInt { increment(v.value);  return this; }
   @:op(A-=B) inline function op_sub_assign2(v:AtomicInt):AtomicInt { increment(-v.value); return this; }

   @:op(A+B) inline function op_add1(v:Int):Int       return this.value + v;
   @:op(A+B) inline function op_add2(v:AtomicInt):Int return this.value + v.value;
   @:op(A-B) inline function op_sub1(v:Int):Int       return this.value - v;
   @:op(A-B) inline function op_sub2(v:AtomicInt):Int return this.value - v.value;

   @:op(A<B) inline function op_lt1(v:Int):Bool       return this.value < v;
   @:op(A<B) inline function op_lt2(v:AtomicInt):Bool return this.value < v.value;
   @:op(A<B) inline function op_lt3(v:Float):Bool     return this.value < v;
   @:op(A>B) inline function op_gt1(v:Int):Bool       return this.value > v;
   @:op(A>B) inline function op_gt2(v:AtomicInt):Bool return this.value > v.value;
   @:op(A>B) inline function op_gt3(v:Float):Bool     return this.value > v;

   @:op(A<=B) inline function op_le(v:Float):Bool     return this.value <= v;
   @:op(A>=B) inline function op_ge(v:Float):Bool     return this.value >= v;

   @:op(--A) inline function op_decrement_pre():Int   return decrementAndGet();
   @:op(A--) inline function op_decrement_post():Int  return getAndDecrement();
   @:op(++A) inline function op_increment_pre():Int   return this.incrementAndGet();
   @:op(A++) inline function op_increment_post():Int  return this.getAndIncrement();

   @:op(-A)  inline function op_negate():Int          return -this.value;

   @:op(A+B) static inline function op_add3(a:Int, b:AtomicInt):Int return a + b.value;
   @:op(A-B) static inline function op_sub3(a:Int, b:AtomicInt):Int return a - b.value;

   inline public function increment(amount:Int = 1):Void      this.incrementAndGet(amount);
   inline public function decrement(amount:Int = 1):Void      this.incrementAndGet(-amount);
   inline public function decrementAndGet(amount:Int = 1):Int return this.incrementAndGet(-amount);
   inline public function getAndDecrement(amount:Int = 1):Int return this.getAndIncrement(-amount);

   /**
    * <pre><code>
    * >>> new AtomicInt(3).toString() == "3"
    * </code></pre>
    */
   inline ///
   public function toString():String
      return Std.string(this.value);
}

private class AtomicIntImpl {

   /**
    * <pre><code>
    * >>> new AtomicInt(4).value == 4
    * </code></pre>
    */
   public var value(get, set):Int;


#if java
   var _value:java.util.concurrent.atomic.AtomicInteger;
   inline function get_value():Int return _value.get();
   inline function set_value(val:Int):Int { _value.set(val); return val; }

   inline public function new(initialValue:Int = 0) this._value = new java.util.concurrent.atomic.AtomicInteger(initialValue);

   inline public function getAndIncrement(amount:Int = 1):Int return _value.getAndAdd(amount);
   inline public function incrementAndGet(amount:Int = 1):Int return _value.addAndGet(amount);

#elseif cs
   var _value:Int;
   function get_value():Int return untyped __cs__("System.Threading.Volatile.Read(ref _value)");
   inline function set_value(val:Int):Int { cs.system.threading.Interlocked.Exchange(_value, val); return val; }

   inline public function new(initialValue:Int = 0) this._value = initialValue;

   inline public function getAndIncrement(amount:Int = 1):Int return cs.system.threading.Interlocked.Add(_value, amount) - amount;
   inline public function incrementAndGet(amount:Int = 1):Int return cs.system.threading.Interlocked.Add(_value, amount);

#else
   final lock = new RLock();
   var _value:Int;

   function get_value():Int {
      lock.acquire();
      final result = _value;
      lock.release();
      return result;
   }
   function set_value(val:Int):Int {
      lock.acquire();
      _value = val;
      lock.release();
      return val;
   }


   inline //
   public function new(initialValue:Int = 0) {
      _value = initialValue;
   }


   /**
    * <pre><code>
    * >>> new AtomicInt(1).getAndIncrement()  == 1
    * >>> new AtomicInt(1).getAndIncrement(2) == 1
    * </code></pre>
    */
   public function getAndIncrement(amount:Int = 1):Int {
      lock.acquire();
      final old = _value;
      _value += amount;
      lock.release();
      return old;
   }


   /**
    * <pre><code>
    * >>> new AtomicInt(1).incrementAndGet()  == 2
    * >>> new AtomicInt(1).incrementAndGet(2) == 3
    * </code></pre>
    */
   public function incrementAndGet(amount:Int = 1):Int {
      lock.acquire();
      final result = _value += amount;
      lock.release();
      return result;
   }
#end
}
