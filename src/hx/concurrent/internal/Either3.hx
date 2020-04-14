/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:noCompletion
abstract Either3<A, B, C>(_Either3<A, B, C>) {

    inline
    public function new(value:_Either3<A, B, C>) {
        this = value;
    }

    public var value(get,never):_Either3<A, B, C>;
    inline
    function get_value():_Either3<A, B, C> {
        return this;
    }

    @:from
    inline
    static function fromA<A,B,C>(value:A):Either3<A, B, C> {
        return new Either3(a(value));
    }

    @:from
    inline
    static function fromB<A,B,C>(value:B):Either3<A, B, C> {
        return new Either3(b(value));
    }

    @:from
    inline
    static function fromC<A,B,C>(value:C):Either3<A, B, C> {
        return new Either3(c(value));
    }
}

@:noDoc @:dox(hide)
private enum _Either3<A, B, C> {
    a(v:A);
    b(v:B);
    c(v:C);
}
