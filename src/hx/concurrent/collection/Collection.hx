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
package hx.concurrent.collection;
import hx.concurrent.internal.Either3;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface Collection<T> {

    public var length(get, never):Int;

    public function add(x:T):Void;
    public function addIfAbsent(x:T):Bool;
    public function addAll(coll:Either3<Collection<T>, Array<T>, List<T>>):Void;
    public function clear():Void;
    public function remove(x:T):Bool;

    public function contains(x:T):Bool;
    public function isEmpty():Bool;

    public function iterator():Iterator<T>;
    public function filter(fn:T->Bool):Collection<T>;
    public function map<X>(fn:T->X):Collection<X>;

    public function copy():Collection<T>;
    public function toArray():Array<T>;
    public function toString():String;
    public function join(sep:String):String;
}

