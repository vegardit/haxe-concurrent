/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
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
abstract Either2<A, B>(_Either2<A, B>) {

   inline
   public function new(value:_Either2<A, B>)
       this = value;


   public var value(get,never):_Either2<A, B>;
   inline
   function get_value():_Either2<A, B>
       return this;


   @:from
   inline
   static function fromA<A,B>(value:A):Either2<A, B>
      return new Either2(a(value));


   @:from
   inline
   static function fromB<A,B>(value:B):Either2<A, B>
      return new Either2(b(value));
}

@:noDoc @:dox(hide)
private enum _Either2<A, B> {
   a(v:A);
   b(v:B);
}
