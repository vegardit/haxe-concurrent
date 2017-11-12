/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
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

