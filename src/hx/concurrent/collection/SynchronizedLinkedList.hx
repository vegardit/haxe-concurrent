/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.collection;

import hx.concurrent.internal.Either3;
import hx.concurrent.lock.RLock;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:forward
abstract SynchronizedLinkedList<T>(SynchronizedLinkedListImpl<T>) from SynchronizedLinkedListImpl<T> to SynchronizedLinkedListImpl<T>{

   /**
    * @param initialValues either a hx.concurrent.collection.Collection<T>, an Array<T> or a List<T>.
    */
   public function new(?initialValues:Either3<Collection<T>, Array<T>, List<T>>) {
      this = new SynchronizedLinkedListImpl();
      if(initialValues != null)
         this.addAll(initialValues);
   }


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2])[0] == 1
    * </code></pre>
    */
   @:arrayAccess
   inline function _get(idx:Int):Null<T>
      return this.get(idx);
}


private class SynchronizedLinkedListImpl<T> implements OrderedCollection<T> {

   var _items = new List<T>();
   final _sync = new RLock();


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList().first      == null
    * >>> new SynchronizedLinkedList([1,2]).first == 1
    * </code></pre>
    */
   public var first(get, never):Null<T>;
   inline function get_first():Null<T>
      return _sync.execute(() -> _items.first());


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList().last      == null
    * >>> new SynchronizedLinkedList([1,2]).last == 2
    * </code></pre>
    */
   public var last(get, never):Null<T>;
   inline function get_last():Null<T>
      return _sync.execute(() -> _items.last());


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList().length      == 0
    * >>> new SynchronizedLinkedList([1,2]).length == 2
    * </code></pre>
    */
   public var length(get, never):Int;
   function get_length():Int
      return _sync.execute(function() {
          var len = 0;
          for (item in _items)
              len++;
          return len;
      });


   inline
   public function new() {
   }


   public function add(item:T):Void
      _sync.execute(() -> _items.add(item));


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1]).addIfAbsent(2)   == true
    * >>> new SynchronizedLinkedList([1,2]).addIfAbsent(1) == false
    * </code></pre>
    */
   public function addIfAbsent(item:T):Bool
      return _sync.execute(function() {
         if (contains(item))
            return false;
         _items.add(item);
         return true;
      });


   public function addAll(coll:Either3<Collection<T>, Array<T>, List<T>>):Void
      _sync.execute(function() {
         switch(coll.value) {
            case a(coll): for (i in coll.iterator()) _items.add(i);
            case b(arr):  for (i in arr) _items.add(i);
            case c(list): for (i in list) _items.add(i);
         }
      });


   public function clear():Void
      _sync.execute(() -> _items = new List<T>());


   public function insertAt(idx:Int, x:T):Void
      _sync.execute(function() {
         final items = new List<T>();

         if (idx < 0) {
            idx = length + idx;
            if (idx < 0)
               idx = 0;
         }
         if (idx == 0) {
            items.push(x);
            return;
         }

         var inserted = false;
         var i = -1;
         for (item in _items) {
            i++;

            if (i == idx)
               items.add(x);
            items.add(item);
         }
         if (!inserted)
            items.add(x);
         _items = items;
     });


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2]).remove(1) == true
    * >>> new SynchronizedLinkedList([2]).remove(1)   == false
    * >>> new SynchronizedLinkedList().remove(1)      == false
    * </code></pre>
    */
   public function remove(x:T):Bool
      return _sync.execute(function() {
         if (indexOf(x) == -1)
            return false;

         return _items.remove(x);
      });


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2]).removeAt(1)     == 2
    * >>> new SynchronizedLinkedList([1]).removeAt(1)       == null
    * >>> new SynchronizedLinkedList([1]).removeAt(1, true) throws ~/Index out of range/
    * </code></pre>
    */
   public function removeAt(idx:Int, throwIfOutOfRange:Bool=false):Null<T>
      return _sync.execute(function():Null<T> {
         if (idx < 0 || idx >= _items.length) {
            if (throwIfOutOfRange)
               throw "Index out of range.";
            return null;
         }

         final items = new List<T>();
         var i = 0;
         var removed:Null<T> = null;
         for (item in _items) {
            if(i == idx)
               removed = item;
            else
               _items.add(item);
            i++;
         }
         _items = items;
         return removed;
      });


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2]).removeFirst() == 1
    * >>> new SynchronizedLinkedList().removeFirst()      == null
    * >>> new SynchronizedLinkedList().removeFirst(true)  throws ~/This collection is empty/
    * </code></pre>
    */
   public function removeFirst(throwIfEmpty:Bool = false):Null<T>
      return _sync.execute(function() {
         if(_items.length == 0) {
            if (throwIfEmpty)
               throw "This collection is empty.";
            return null;
         }

         return _items.pop();
      });


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2]).removeLast() == 2
    * >>> new SynchronizedLinkedList().removeLast()      == null
    * >>> new SynchronizedLinkedList().removeLast(true)  throws ~/This collection is empty/
    * </code></pre>
    */
   public function removeLast(throwIfEmpty:Bool = false):Null<T>
      return _sync.execute(function():Null<T> {
         if(_items.length == 0) {
            if (throwIfEmpty)
               throw "This collection is empty.";
            return null;
         }

         final it = _items.iterator();
         _items = new List<T>();
         while(true) {
            final item = it.next();
            if (it.hasNext())
               _items.add(item);
             else
               return item;
         }
      });


   public function copy():SynchronizedLinkedList<T>
      return _sync.execute(function() {
         final copy = new List<T>();
         for (item in _items)
            copy.add(item);
         return new SynchronizedLinkedList<T>(copy);
      });


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2]).contains(1) == true
    * >>> new SynchronizedLinkedList([2]).contains(1)   == false
    * >>> new SynchronizedLinkedList().contains(1)      == false
    * </code></pre>
    */
   inline
   public function contains(x:T):Bool
      return indexOf(x) > -1;


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([2]).isEmpty() == false
    * >>> new SynchronizedLinkedList().isEmpty()    == true
    * </code></pre>
    */
   public function isEmpty():Bool
      return _sync.execute(() -> !_items.iterator().hasNext());


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2]).get(1)  == 2
    * >>> new SynchronizedLinkedList([2]).get(1)    == null
    * >>> new SynchronizedLinkedList().get(1, true) throws ~/Index out of range/
    * </code></pre>
    */
   public function get(idx:Int, throwIfOutOfRange:Bool = false):Null<T>
      return _sync.execute(function():Null<T> {
         if (idx < 0 || idx >= _items.length) {
            if (throwIfOutOfRange)
               throw "Index out of range.";
            return null;
         }

         var i = 0;
         for (item in _items) {
            if (i == idx)
               return item;
            i++;
         }
         return null;
      });


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2,1]).indexOf(1)    == 0
    * >>> new SynchronizedLinkedList([1,2,1]).indexOf(1, 1) == 2
    * >>> new SynchronizedLinkedList([2]).indexOf(1)        == -1
    * >>> new SynchronizedLinkedList().indexOf(1)           == -1
    * </code></pre>
    */
   public function indexOf(x:T, startAt:Int = 0):Int
      return _sync.execute(function() {
          var i = 0;
          for (item in _items) {
              if (i >= startAt && item == x)
                  return i;
              i++;
          }
          return -1;
      });


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2,1]).lastIndexOf(1)    == 2
    * >>> new SynchronizedLinkedList([1,2,1]).lastIndexOf(1, 1) == 0
    * >>> new SynchronizedLinkedList([2]).lastIndexOf(1)        == -1
    * >>> new SynchronizedLinkedList().lastIndexOf(1)           == -1
    * </code></pre>
    */
   inline
   public function lastIndexOf(x:T, ?startAt:Int):Int
      return _sync.execute(function() {
         var i = 0;
         var foundAt = -1;
         for (item in _items) {
            if (startAt != null && i > startAt)
               break;
            if (item == x)
               foundAt = i;
            i++;
         }
         return foundAt;
      });


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2,1]).filter((x) -> x == 1).toArray() == [1, 1]
    * </code></pre>
    */
   public function filter(fn:T->Bool):SynchronizedLinkedList<T>
      return _sync.execute(() -> new SynchronizedLinkedList(_items.filter(fn)));


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2,1]).map((x) -> Std.string(x)).toArray() == ["1", "2", "1"]
    * </code></pre>
    */
   public function map<X>(fn:T->X):SynchronizedLinkedList<X>
      return _sync.execute(() -> new SynchronizedLinkedList(_items.map(fn)));


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2]).join("_") == "1_2"
    * >>> new SynchronizedLinkedList([1]).join("_")   == "1"
    * >>> new SynchronizedLinkedList().join("_")      == ""
    * </code></pre>
    */
   public function join(sep:String):String
      return _sync.execute(() -> _items.join(sep));


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2]).iterator().hasNext() == true
    * >>> new SynchronizedLinkedList([1,2]).iterator().next()    == 1
    * >>> new SynchronizedLinkedList().iterator().hasNext()      == false
    * </code></pre>
    */
   public function iterator():Iterator<T>
      return _sync.execute(() -> _items.iterator());


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2]).toArray() == [1,2]
    * >>> new SynchronizedLinkedList([1]).toArray()   == [1]
    * >>> new SynchronizedLinkedList().toArray()      == []
    * </code></pre>
    */
   public function toArray():Array<T>
      return _sync.execute(function() {
         final arr = new Array<T>();
         for (item in _items)
            arr.push(item);
         return arr;
      });


   /**
    * <pre><code>
    * >>> new SynchronizedLinkedList([1,2]).toString() == "{1, 2}"
    * >>> new SynchronizedLinkedList([1]).toString()   == "{1}"
    * >>> new SynchronizedLinkedList().toString()      == "{}"
    * </code></pre>
    */
   public function toString():String
      return _sync.execute(() -> _items.toString());
}
