/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.collection;

import haxe.Constraints.IMap;
import haxe.ds.HashMap;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import hx.concurrent.lock.RLock;

@:forward
abstract SynchronizedMap<K, V>(SynchronizedMapImpl<K, V>) from SynchronizedMapImpl<K, V> to SynchronizedMapImpl<K, V> {

   /**
    * <pre><code>
    * >>> SynchronizedMap.newHashMap().isEmpty == true
    * </code></pre>
    */
   inline public static function newHashMap<K:{function hashCode():Int;}, V>() {
      return new SynchronizedMap<K, V>(new HashMapDelegate<K, V>());
   }

   /**
    * <pre><code>
    * >>> SynchronizedMap.newIntMap().isEmpty == true
    * </code></pre>
    */
   inline public static function newIntMap<V>() {
      return new SynchronizedMap<Int, V>(new IntMap<V>());
   }

   /**
    * <pre><code>
    * >>> SynchronizedMap.newObjectMap().isEmpty == true
    * </code></pre>
    */
   inline public static function newObjectMap<K:{}, V>() {
      return new SynchronizedMap<K, V>(new ObjectMap<K, V>());
   }

   /**
    * <pre><code>
    * >>> SynchronizedMap.newStringMap().isEmpty == true
    * </code></pre>
    */
   inline public static function newStringMap<String, V>() {
      return new SynchronizedMap<String, V>(new StringMap<V>());
   }

   /**
    * <pre><code>
    * >>> SynchronizedMap.from([100 => 50])            .isEmpty == false
    * >>> SynchronizedMap.from(["foo" => "bar"])       .isEmpty == false
    * >>> SynchronizedMap.from(new haxe.ds.StringMap()).isEmpty == true
    * </code></pre>
    */
   inline public static function from<K, V>(initialValues:IMap<K, V>) {
      return new SynchronizedMap<K, V>(initialValues);
   }

   /**
    * <pre><code>
    * >>> SynchronizedMap.newHashMap().isEmpty == true
    * </code></pre>
    */
   inline public static function fromHashMap<K:{function hashCode():Int;}, V>(initialValues:HashMap<K, V>) {
      return new SynchronizedMap<K, V>(new HashMapDelegate<K, V>(initialValues));
   }

   private function new<K, V>(initialValues:IMap<K, V>) {
      this = new SynchronizedMapImpl<K, V>(initialValues.copy());
   }

   /**
    * <pre><code>
    * >>> SynchronizedMap.from([100 => 50])[100] == 50
    * >>> SynchronizedMap.from(["foo" => "bar"])["foo"] == "bar"
    * >>> SynchronizedMap.from(new haxe.ds.StringMap()) != null
    * </code></pre>
    */
   @:arrayAccess
   inline function _get(k:K):Null<V>
      return this.get(k);

   @:arrayAccess
   inline function _set(k:K, v:V):V {
      this.set(k, v);
      return v;
   }
}

private final class SynchronizedMapImpl<K, V> implements IMap<K, V> {

   final _items:IMap<K, V>;
   final _sync = new RLock();

   inline public function new(items:IMap<K, V>) {
      this._items = items;
   }

   /**
    * <pre><code>
    * >>> SynchronizedMap.from([1 => 1])               .length == 1
    * >>> SynchronizedMap.from([1 => 1, 2 => 2])       .length == 2
    * >>> SynchronizedMap.from(new haxe.ds.StringMap()).length == 0
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

   /**
    * <pre><code>
    * >>> SynchronizedMap.from([100 => 50])            .isEmpty == false
    * >>> SynchronizedMap.from(["foo" => "bar"])       .isEmpty == false
    * >>> SynchronizedMap.from(new haxe.ds.StringMap()).isEmpty == true
    * </code></pre>
    */
   public var isEmpty(get, never):Bool;

   function get_isEmpty():Bool
      return _sync.execute(() -> !_items.iterator().hasNext());

   /**
    * <pre><code>
    * >>> SynchronizedMap.from([100 => 50])            .get(100)   == 50
    * >>> SynchronizedMap.from(["foo" => "bar"])       .get("foo") == "bar"
    * >>> SynchronizedMap.from(new haxe.ds.StringMap()).get("foo") == null
    * </code></pre>
    */
   inline public function get(k:K):Null<V>
      return _sync.execute(() -> _items.get(k));

   inline public function set(k:K, v:V):Void
      _sync.execute(() -> return _items.set(k, v));

   /**
    * <pre><code>
    * >>> SynchronizedMap.from([100 => 50])     .exists(100)   == true
    * >>> SynchronizedMap.from(["foo" => "bar"]).exists("foo") == true
    * >>> SynchronizedMap.newStringMap()        .exists("foo") == false
    * </code></pre>
    */
   inline public function exists(k:K):Bool
      return _sync.execute(() -> _items.exists(k));

   /**
    * <pre><code>
    * >>> SynchronizedMap.from([100 => 50])     .remove(100)   == true
    * >>> SynchronizedMap.from(["foo" => "bar"]).remove("foo") == true
    * >>> SynchronizedMap.newStringMap()        .remove("foo") == false
    * </code></pre>
    */
   inline public function remove(k:K):Bool
      return _sync.execute(() -> _items.remove(k));

   /**
    * <pre><code>
    * >>> SynchronizedMap.from([100 => 50])     .keys().next() == 100
    #if !cs
    * >>> SynchronizedMap.from(["foo" => "bar"]).keys().next() == "foo"
    #end
    * >>> SynchronizedMap.newStringMap()        .keys().hasNext() == false
    * </code></pre>
    */
   inline public function keys():Iterator<K>
      return _sync.execute(() -> new SynchronizedMapIterator<K>(_sync, _items.keys()));

   /**
    * <pre><code>
    * >>> SynchronizedMap.from([100 => 50])     .iterator().next() == 50
    #if !cs
    * >>> SynchronizedMap.from(["foo" => "bar"]).iterator().next() == "bar"
    #end
    * >>> SynchronizedMap.newStringMap()        .iterator().hasNext() == false
    * </code></pre>
    */
   inline public function iterator():Iterator<V>
      return _sync.execute(() -> new SynchronizedMapIterator<V>(_sync, _items.iterator()));

   inline public function keyValueIterator():KeyValueIterator<K, V>
      return _sync.execute(() -> new SynchronizedMapIterator<{key:K, value:V}>(_sync, _items.keyValueIterator()));

   inline public function copy():SynchronizedMap<K, V>
      return _sync.execute(() -> SynchronizedMap.from(_items.copy()));

   inline public function toString():String
      return _sync.execute(() -> Std.string(_items));

   inline public function clear():Void
      _sync.execute(() -> _items.clear());
}


private final class SynchronizedMapIterator<T> {

   final _sync:RLock;
   final _it:Iterator<T>;

   inline public function new(sync:RLock, it:Iterator<T>) {
      _sync = sync;
      _it = it;
   }

   inline public function hasNext():Bool
      return _sync.execute(() -> _it.hasNext());

   inline public function next():T
      return _sync.execute(() -> _it.next());
}

/**
 * workaround for haxe.ds.HashMap not implementing IMap interface
 */
private final class HashMapDelegate<K:{function hashCode():Int;}, V> implements IMap<K, V> {

   final map = new HashMap<K, V>();

   inline public function new(?from:HashMap<K, V>) {
      if (from != null) {
         @:nullSafety(Off)
         for (k => v in from) {
            map.set(k, v);
         }
      }
   }

   #if (php || lua) @:nullSafety(Off) #end
   inline public function get(k:K):Null<V>
      return map.get(k);

   #if neko @:nullSafety(Off) #end
   inline public function set(k:K, v:V):Void
      map.set(k, v);

   #if neko @:nullSafety(Off) #end
   inline public function exists(k:K):Bool
      return map.exists(k);

   #if neko @:nullSafety(Off) #end
   inline public function remove(k:K):Bool
      return map.remove(k);

   inline public function keys():Iterator<K>
      return map.keys();

   inline public function iterator():Iterator<V>
      return map.iterator();

   inline public function keyValueIterator():KeyValueIterator<K, V>
      return map.keyValueIterator();

   inline public function copy():IMap<K, V>
      return new HashMapDelegate(map);

   inline public function toString():String
      return Std.string(map);

   inline public function clear():Void
      map.clear();
}
