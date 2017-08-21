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
package hx.concurrent.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:noCompletion
abstract Either2<A, B>(_Either2<A, B>) {

    inline
    public function new(value:_Either2<A, B>) {
        this = value;
    }

    public var value(get,never):_Either2<A, B>;
    inline
    function get_value():_Either2<A, B> {
        return this;
    }

    @:from
    inline
    static function fromA<A,B>(value:A):Either2<A, B> {
        return new Either2(a(value));
    }

    @:from
    inline
    static function fromB<A,B>(value:B):Either2<A, B> {
        return new Either2(b(value));
    }
}

@:noDoc @:dox(hide)
private enum _Either2<A, B> {
    a(v:A);
    b(v:B);
}
