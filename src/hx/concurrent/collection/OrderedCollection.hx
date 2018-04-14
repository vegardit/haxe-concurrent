/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.collection;

import hx.concurrent.internal.Either3;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface OrderedCollection<T> extends Collection<T> {

    var first(get, never):Null<T>;
    var last(get, never):Null<T>;

    function insertAt(idx:Int, x:T):Void;
    function removeAt(idx:Int, throwIfOutOfRange:Bool=false):Null<T>;
    function removeFirst(throwIfEmpty:Bool=false):Null<T>;
    function removeLast(throwIfEmpty:Bool=false):Null<T>;

    function get(idx:Int, throwIfOutOfRange:Bool=false):Null<T>;
    function indexOf(x:T, startAt:Int=0):Int;
    function lastIndexOf(x:T, ?startAt:Int):Int;
}
