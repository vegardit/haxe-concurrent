/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:forward(concat, copy, filter, indexOf, iterator, join, lastIndexOf, length, map, slice, toString)
abstract ReadOnlyArray<T>(Array<T>) from Array<T> {

    @:arrayAccess
    inline function get(i:Int):T return this[i];

}
