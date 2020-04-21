/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.collection;

import hx.concurrent.internal.Either3;
import hx.concurrent.lock.RLock;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:forward
abstract CopyOnWriteArray<T>(CopyOnWriteArrayImpl<T>) from CopyOnWriteArrayImpl<T> to CopyOnWriteArrayImpl<T> {

   /**
    * @param initialValues either a hx.concurrent.collection.Collection<T>, an Array<T> or a List<T>.
    */
   public function new(?initialValues:Either3<Collection<T>, Array<T>, List<T>>) {
      this = new CopyOnWriteArrayImpl();
      if(initialValues != null)
         this.addAll(initialValues);
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2])[0] == 1
    * </code></pre>
    */
   @:arrayAccess
   inline function _get(idx:Int):Null<T>
      return this.get(idx);


   /**
    * >>> ({var arr=new CopyOnWriteArray([1,2]); arr[2]=3; arr; }).toArray() == [1, 2, 3]
    */
   @:arrayAccess
   inline function _set(idx:Int, x:T):T {
      this._set(idx, x);
      return x;
   }
}

private class CopyOnWriteArrayImpl<T> implements OrderedCollection<T> {

   var _items = new Array<T>();
   var _sync = new RLock();

   @:allow(hx.concurrent.collection.CopyOnWriteArray)
   function _set(idx:Int, x:T):Void {
      _sync.execute(function() {
         var items = _items.copy();
         items[idx] = x;
         _items = items;
      });
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray().first      == null
    * >>> new CopyOnWriteArray([1,2]).first == 1
    * </code></pre>
    */
   public var first(get, never):Null<T>;
   inline function get_first():Null<T> {
      var items = _items;
      return items.length == 0 ? null : items[0];
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray().last      == null
    * >>> new CopyOnWriteArray([1,2]).last == 2
    * </code></pre>
    */
   public var last(get, never):Null<T>;
   inline function get_last():Null<T> {
      var items = _items;
      return items.length == 0 ? null : items[items.length - 1];
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray().length      == 0
    * >>> new CopyOnWriteArray([1,2]).length == 2
    * </code></pre>
    */
   public var length(get, never):Int;
   inline function get_length():Int
       return _items.length;


    inline
    public function new() {
    }


   public function add(x:T):Void {
      _sync.execute(function() {
         var items = _items.copy();
         items.push(x);
         _items = items;
      });
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1]).addIfAbsent(2)   == true
    * >>> new CopyOnWriteArray([1,2]).addIfAbsent(1) == false
    * </code></pre>
    */
   public function addIfAbsent(x:T):Bool {
      return _sync.execute(function() {
         if (_items.indexOf(x) > -1)
            return false;

         var items = _items.copy();
         items.push(x);
         _items = items;
         return true;
      });
   }


   public function addAll(coll:Either3<Collection<T>, Array<T>, List<T>>):Void {
      _sync.execute(function() {
         var items:Array<T> = null;
         switch(coll.value) {
            case a(coll):
               items = _items.copy();
               for (i in coll.iterator())
                 items.push(i);
            case b(arr):
               items = _items.concat(arr);
            case c(list):
               items = _items.copy();
               for (i in list)
                  items.push(i);
         }
         _items = items;
      });
   }


   inline
   public function clear():Void
      _items = [];


   public function insertAt(idx:Int, x:T):Void {
      _items = _sync.execute(function() {
         var items = _items.copy();
         items.insert(idx, x);
         return items;
      });
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2]).remove(1) == true
    * >>> new CopyOnWriteArray([2]).remove(1)   == false
    * >>> new CopyOnWriteArray().remove(1)      == false
    * </code></pre>
    */
   public function remove(x:T):Bool {
      return _sync.execute(function() {
         if (_items.indexOf(x) == -1)
            return false;

         var items = _items.copy();
         var removed = items.remove(x);
         _items = items;
         return removed;
      });
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2]).removeAt(1)     == 2
    * >>> new CopyOnWriteArray([1]).removeAt(1)       == null
    * >>> new CopyOnWriteArray([1]).removeAt(1, true) throws ~/Index out of range/
    * </code></pre>
    */
   public function removeAt(idx:Int, throwIfOutOfRange:Bool=false):Null<T> {
      return _sync.execute(function() {
         if (idx < 0 || idx >= _items.length) {
            if (throwIfOutOfRange)
               throw "Index out of range.";
            return null;
         }
         var items = _items.copy();
         var removed = items.splice(idx, 1);
         _items = items;
         return removed.length == 0 ? null : removed[0];
      });
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2]).removeFirst() == 1
    * >>> new CopyOnWriteArray().removeFirst()      == null
    * >>> new CopyOnWriteArray().removeFirst(true)  throws ~/This collection is empty/
    * </code></pre>
    */
   public function removeFirst(throwIfEmpty:Bool = false):Null<T> {
      return _sync.execute(function() {
         if(_items.length == 0) {
            if (throwIfEmpty)
               throw "This collection is empty.";
            return null;
         }

         var items = _items.copy();
         var removed = items.shift();
         _items = items;
         return removed;
      });
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2]).removeLast() == 2
    * >>> new CopyOnWriteArray().removeLast()      == null
    * >>> new CopyOnWriteArray().removeLast(true)  throws ~/This collection is empty/
    * </code></pre>
    */
   public function removeLast(throwIfEmpty:Bool = false):Null<T> {
      return _sync.execute(function() {
         if(_items.length == 0) {
            if (throwIfEmpty)
               throw "This collection is empty.";
            return null;
         }

         var items = _items.copy();
         var removed = items.pop();
         _items = items;
         return removed;
      });
   }


   inline
   public function copy():CopyOnWriteArray<T>
      return new CopyOnWriteArray(_items.copy());


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2]).contains(1) == true
    * >>> new CopyOnWriteArray([2]).contains(1)   == false
    * >>> new CopyOnWriteArray().contains(1)      == false
    * </code></pre>
    */
   inline
   public function contains(x:T):Bool
      return indexOf(x) > -1;


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([2]).isEmpty() == false
    * >>> new CopyOnWriteArray().isEmpty()    == true
    * </code></pre>
    */
   inline
   public function isEmpty():Bool
      return _items.length == 0;


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2]).get(1)  == 2
    * >>> new CopyOnWriteArray([2]).get(1)    == null
    * >>> new CopyOnWriteArray().get(1, true) throws ~/Index out of range/
    * </code></pre>
    */
   public function get(idx:Int, throwIfOutOfRange:Bool = false):Null<T> {
      var items = _items;
      if (idx < 0 || idx >= items.length) {
         if (throwIfOutOfRange)
            throw "Index out of range.";
         return null;
      }
      return items[idx];
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2,1]).indexOf(1)    == 0
    * >>> new CopyOnWriteArray([1,2,1]).indexOf(1, 1) == 2
    * >>> new CopyOnWriteArray([2]).indexOf(1)        == -1
    * >>> new CopyOnWriteArray().indexOf(1)           == -1
    * </code></pre>
    */
   inline
   public function indexOf(x:T, startAt:Int=0):Int
       return _items.indexOf(x, startAt);


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2,1]).lastIndexOf(1)    == 2
    * >>> new CopyOnWriteArray([1,2,1]).lastIndexOf(1, 1) == 0
    * >>> new CopyOnWriteArray([2]).lastIndexOf(1)        == -1
    * >>> new CopyOnWriteArray().lastIndexOf(1)           == -1
    * </code></pre>
    */
   inline
   public function lastIndexOf(x:T, ?startAt:Int):Int {
      #if (flash||js)
         var items = _items;
         return items.lastIndexOf(x, startAt == null ? items.length - 1 : startAt);
      #else
         return _items.lastIndexOf(x, startAt);
      #end
   }


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2,1]).filter(function(x) return x == 1).toArray() == [1, 1]
    * </code></pre>
    */
   inline
   public function filter(fn:T->Bool):CopyOnWriteArray<T>
      return new CopyOnWriteArray(_items.filter(fn));


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2,1]).map(function(x) return Std.string(x)).toArray() == ["1", "2", "1"]
    * </code></pre>
    */
   inline
   public function map<X>(fn:T->X):CopyOnWriteArray<X>
      return new CopyOnWriteArray(_items.map(fn));


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2]).join("_") == "1_2"
    * >>> new CopyOnWriteArray([1]).join("_")   == "1"
    * >>> new CopyOnWriteArray().join("_")      == ""
    * </code></pre>
    */
   inline
   public function join(sep:String):String
      return _items.join(sep);


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2]).iterator().hasNext() == true
    * >>> new CopyOnWriteArray([1,2]).iterator().next()    == 1
    * >>> new CopyOnWriteArray().iterator().hasNext()      == false
    * </code></pre>
    */
   inline
   public function iterator():Iterator<T>
      return _items.iterator();


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2]).toArray() == [1,2]
    * >>> new CopyOnWriteArray([1]).toArray()   == [1]
    * >>> new CopyOnWriteArray().toArray()      == []
    * </code></pre>
    */
   inline
   public function toArray():Array<T>
       return _items.copy();


   /**
    * <pre><code>
    * >>> new CopyOnWriteArray([1,2]).toString() == "[1,2]"
    * >>> new CopyOnWriteArray([1]).toString()   == "[1]"
    * >>> new CopyOnWriteArray().toString()      == "[]"
    * </code></pre>
    */
   inline
   public function toString():String {
      #if (flash||js)
         return "[" + _items.toString() + "]";
      #else
         return _items.toString();
      #end
   }
}

