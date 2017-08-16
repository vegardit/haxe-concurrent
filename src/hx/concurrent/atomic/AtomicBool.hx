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
package hx.concurrent.atomic;

#if java
import java.util.concurrent.atomic.AtomicBoolean;
private typedef AB = AtomicBoolean;
#else
private typedef AB = AtomicBoolImpl;
#end

/**
 * Boolean with thread-safe atomic operations.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
abstract AtomicBool(AB) from AB to AB {

    /**
     * <pre><code>
     * >>> (new AtomicBool() == false)      == true
     * >>> (new AtomicBool(true) == true)   == true
     * >>> (new AtomicBool(true) != false)  == true
     * >>> (!new AtomicBool(true) == false) == true
     * </code></pre>
     */
    inline
    public function new(?val:Bool = false) {
        this = new AB(val);
    }

    @:to     inline function toBool():Bool    return value;
    @:op(!A) inline function op_negate():Bool return !value;

    /**
     * <pre><code>
     * >>> new AtomicBool(true).value  == true
     * >>> new AtomicBool(false).value == false
     * </code></pre>
     */
    public var value(get, set):Bool;
    inline function get_value():Bool {
        #if java
            return this.get();
        #else
            return this.value;
        #end
    }
    inline function set_value(value:Bool):Bool {
        this.set(value);
        return value;
    }


    /**
     * <pre><code>
     * >>> new AtomicBool(true).getAndSet(false) == true
     * >>> new AtomicBool(false).getAndSet(true) == false
     * </code></pre>
     */
    inline
    public function getAndSet(value:Bool):Bool {
        return this.getAndSet(value);
    }

    /**
     * <pre><code>
     * >>> new AtomicBool(true).negate()  == false
     * >>> new AtomicBool(false).negate() == true
     * </code></pre>
     */
    #if !java inline #end
    public function negate():Bool {
        #if java
            var newVal = !this.get();
            while (!this.compareAndSet(!newVal, newVal)) {
                newVal = !newVal;
            }
            return newVal;
        #else
            return this.negate();
        #end
    }

    /**
     * <pre><code>
     * >>> new AtomicBool(true).getAndNegate()  == true
     * >>> new AtomicBool(false).getAndNegate() == false
     * </code></pre>
     */
    #if !java inline #end
    public function getAndNegate():Bool {
        #if java
            var oldVal = this.get();
            while (!this.compareAndSet(oldVal, !oldVal)) {
                oldVal = !oldVal;
            }
            return oldVal;
        #else
            return this.getAndNegate();
        #end
    }

    /**
     * <pre><code>
     * >>> new AtomicBool(true).toString()  == "true"
     * >>> new AtomicBool(false).toString() == "false"
     * </code></pre>
     */
    inline public function toString():String {
        return this.toString();
    }
}

private class AtomicBoolImpl {

    var _lock:RLock;

    public var value(get, never):Bool;
    var _value:Bool;
    function get_value():Bool {
        _lock.acquire();
        var result = _value;
        _lock.release();
        return result;
    }

    public function new(initialValue:Bool=false) {
        _lock = new RLock();
        this._value = initialValue;
    }

    public function getAndSet(value:Bool):Bool {
        _lock.acquire();
        var old = _value;
        _value = value;
        _lock.release();
        return old;
    }

    public function getAndNegate():Bool {
        _lock.acquire();
        var oldValue = _value;
        _value = !oldValue;
        _lock.release();
        return oldValue;
    }

    public function negate():Bool {
        _lock.acquire();
        var newValue = !_value;
        _value = newValue;
        _lock.release();
        return newValue;
    }

    public function set(value:Bool):Void {
        _lock.acquire();
        this._value = value;
        _lock.release();
    }

    inline
    public function toString() {
        return Std.string(value);
    }
}
