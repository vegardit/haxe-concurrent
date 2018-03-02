/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.collection;

import hx.concurrent.internal.Either3;
import hx.concurrent.lock.RLock;

/**
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:forward
abstract SynchronizedArray<T>(SynchronizedArrayImpl<T>) from SynchronizedArrayImpl<T> to SynchronizedArrayImpl<T> {

    /**
     * @param initialValues either a hx.concurrent.collection.Collection<T>, an Array<T> or a List<T>.
     */
    public function new(?initialValues:Either3<Collection<T>, Array<T>, List<T>>) {
        this = new SynchronizedArrayImpl();
        if(initialValues != null)
            this.addAll(initialValues);
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2])[0] == 1
     * </code></pre>
     */
    @:arrayAccess
    inline function _get(idx:Int):Null<T> {
      return this.get(idx);
    }

    /**
     * >>> function(){var arr=new SynchronizedArray([1,2]); arr[2]=3; return arr.toArray(); }() == [1, 2, 3]
     */
    @:arrayAccess
    inline function _set(idx:Int, x:T):T {
      this.set(idx, x);
      return x;
    }
}

private class SynchronizedArrayImpl<T> implements OrderedCollection<T> {
    var _items = new Array<T>();
    var _sync = new RLock();

    @:allow(hx.concurrent.collection.SynchronizedArray)
    function set(idx:Int, x:T):Void {
        _sync.execute(function() {
            _items[idx] = x;
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray().first      == null
     * >>> new SynchronizedArray([1,2]).first == 1
     * </code></pre>
     */
    public var first(get, never):Null<T>;
    inline function get_first():Null<T> {
        return _sync.execute(function() {
            return _items.length == 0 ? null : _items[0];
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray().last      == null
     * >>> new SynchronizedArray([1,2]).last == 2
     * </code></pre>
     */
    public var last(get, never):Null<T>;
    inline function get_last():Null<T> {
        return _sync.execute(function() {
            return _items.length == 0 ? null : _items[_items.length  - 1];
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray().length      == 0
     * >>> new SynchronizedArray([1,2]).length == 2
     * </code></pre>
     */
    public var length(get, never):Int;
    inline function get_length():Int {
        return _sync.execute(function() {
            return _items.length;
        });
    }

    inline
    public function new() {
    }

    public function add(item:T):Void {
        _sync.execute(function() {
            _items.push(item);
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1]).addIfAbsent(2)   == true
     * >>> new SynchronizedArray([1,2]).addIfAbsent(1) == false
     * </code></pre>
     */
    public function addIfAbsent(item:T):Bool {
        return _sync.execute(function() {
            if (_items.indexOf(item) >-1)
                return false;
            _items.push(item);
            return true;
        });
    }

    public function addAll(coll:Either3<Collection<T>, Array<T>, List<T>>):Void {
        _sync.execute(function() {
            switch(coll.value) {
                case a(coll): for (i in coll.iterator()) _items.push(i);
                case b(arr):  for (i in arr) _items.push(i);
                case c(list): for (i in list) _items.push(i);
            }
        });
    }

    public function clear():Void {
        _sync.execute(function() {
            _items = [];
        });
    }

    public function insertAt(idx:Int, x:T):Void {
        _sync.execute(function() {
            _items.insert(idx, x);
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2]).remove(1) == true
     * >>> new SynchronizedArray([2]).remove(1)   == false
     * >>> new SynchronizedArray().remove(1)      == false
     * </code></pre>
     */
    public function remove(x:T):Bool {
        return _sync.execute(function() {
            if (_items.indexOf(x) == -1)
                return false;

            return _items.remove(x);
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2]).removeAt(1)     == 2
     * >>> new SynchronizedArray([1]).removeAt(1)       == null
     * >>> new SynchronizedArray([1]).removeAt(1, true) throws ~/Index out of range/
     * </code></pre>
     */
    public function removeAt(idx:Int, throwIfOutOfRange:Bool=false):Null<T> {
        return _sync.execute(function() {
            if (idx < 0 || idx >= _items.length) {
                if (throwIfOutOfRange)
                    throw "Index out of range.";
                return null;
            }
            var removed = _items.splice(idx, 1);
            return removed.length == 0 ? null : removed[0];
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2]).removeFirst() == 1
     * >>> new SynchronizedArray().removeFirst()      == null
     * >>> new SynchronizedArray().removeFirst(true)  throws ~/This collection is empty/
     * </code></pre>
     */
    public function removeFirst(throwIfEmpty:Bool = false):Null<T> {
        return _sync.execute(function() {
            if(_items.length == 0) {
                if (throwIfEmpty)
                    throw "This collection is empty.";
                return null;
            }

            return _items.shift();
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2]).removeLast() == 2
     * >>> new SynchronizedArray().removeLast()      == null
     * >>> new SynchronizedArray().removeLast(true)  throws ~/This collection is empty/
     * </code></pre>
     */
    public function removeLast(throwIfEmpty:Bool = false):Null<T> {
        return _sync.execute(function() {
            if(_items.length == 0) {
                if (throwIfEmpty)
                    throw "This collection is empty.";
                return null;
            }

            return _items.pop();
        });
    }

    inline
    public function copy():SynchronizedArray<T> {
        return _sync.execute(function() {
            return new SynchronizedArray<T>(_items.copy());
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2]).contains(1) == true
     * >>> new SynchronizedArray([2]).contains(1)   == false
     * >>> new SynchronizedArray().contains(1)      == false
     * </code></pre>
     */
    inline
    public function contains(x:T):Bool {
        return indexOf(x) > -1;
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([2]).isEmpty() == false
     * >>> new SynchronizedArray().isEmpty()    == true
     * </code></pre>
     */
    public function isEmpty():Bool {
        return _sync.execute(function() {
            return _items.length == 0;
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2]).get(1)  == 2
     * >>> new SynchronizedArray([2]).get(1)    == null
     * >>> new SynchronizedArray().get(1, true) throws ~/Index out of range/
     * </code></pre>
     */
    public function get(idx:Int, throwIfOutOfRange:Bool = false):Null<T> {
        return _sync.execute(function() {
            if (idx < 0 || idx >= _items.length) {
                if (throwIfOutOfRange)
                    throw "Index out of range.";
                return null;
            }
            return _items[idx];
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2,1]).indexOf(1)    == 0
     * >>> new SynchronizedArray([1,2,1]).indexOf(1, 1) == 2
     * >>> new SynchronizedArray([2]).indexOf(1)        == -1
     * >>> new SynchronizedArray().indexOf(1)           == -1
     * </code></pre>
     */
    inline
    public function indexOf(x:T, startAt:Int = 0):Int {
        return _sync.execute(function() {
            return _items.indexOf(x, startAt);
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2,1]).lastIndexOf(1)    == 2
     * >>> new SynchronizedArray([1,2,1]).lastIndexOf(1, 1) == 0
     * >>> new SynchronizedArray([2]).lastIndexOf(1)        == -1
     * >>> new SynchronizedArray().lastIndexOf(1)           == -1
     * </code></pre>
     */
    inline
    public function lastIndexOf(x:T, ?startAt:Int):Int {
        return _sync.execute(function() {
            #if (flash||js)
            return _items.lastIndexOf(x, startAt == null ? _items.length - 1 : startAt);
            #else
            return _items.lastIndexOf(x, startAt);
            #end
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2,1]).filter(function(x) return x == 1).toArray() == [1, 1]
     * </code></pre>
     */
    inline
    public function filter(fn:T->Bool):SynchronizedArray<T> {
        return _sync.execute(function() {
            return new SynchronizedArray(_items.filter(fn));
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2,1]).map(function(x) return Std.string(x)).toArray() == ["1", "2", "1"]
     * </code></pre>
     */
    inline
    public function map<X>(fn:T->X):SynchronizedArray<X> {
        return _sync.execute(function() {
            return new SynchronizedArray(_items.map(fn));
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2]).join("_") == "1_2"
     * >>> new SynchronizedArray([1]).join("_")   == "1"
     * >>> new SynchronizedArray().join("_")      == ""
     * </code></pre>
     */
    inline
    public function join(sep:String):String {
        return _sync.execute(function() {
            return _items.join(sep);
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2]).iterator().hasNext() == true
     * >>> new SynchronizedArray([1,2]).iterator().next()    == 1
     * >>> new SynchronizedArray().iterator().hasNext()      == false
     * </code></pre>
     */
    inline
    public function iterator():Iterator<T> {
        return _sync.execute(function() {
            return _items.iterator();
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2]).toArray() == [1,2]
     * >>> new SynchronizedArray([1]).toArray()   == [1]
     * >>> new SynchronizedArray().toArray()      == []
     * </code></pre>
     */
    inline
    public function toArray():Array<T> {
        return _sync.execute(function() {
            return _items.copy();
        });
    }

    /**
     * <pre><code>
     * >>> new SynchronizedArray([1,2]).toString() == "[1,2]"
     * >>> new SynchronizedArray([1]).toString()   == "[1]"
     * >>> new SynchronizedArray().toString()      == "[]"
     * </code></pre>
     */
    inline
    public function toString():String {
        return _sync.execute(function() {
            #if (flash||js)
            return "[" + _items.toString() + "]";
            #else
            return _items.toString();
            #end
        });
    }

}
