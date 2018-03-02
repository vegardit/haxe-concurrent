/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.collection;

import hx.concurrent.internal.Either3;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface OrderedCollection<T> extends Collection<T> {

    public var first(get, never):Null<T>;
    public var last(get, never):Null<T>;

    public function insertAt(idx:Int, x:T):Void;
    public function removeAt(idx:Int, throwIfOutOfRange:Bool=false):Null<T>;
    public function removeFirst(throwIfEmpty:Bool=false):Null<T>;
    public function removeLast(throwIfEmpty:Bool=false):Null<T>;

    public function get(idx:Int, throwIfOutOfRange:Bool=false):Null<T>;
    public function indexOf(x:T, startAt:Int=0):Int;
    public function lastIndexOf(x:T, ?startAt:Int):Int;
}
