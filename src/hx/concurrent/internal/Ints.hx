/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.internal;

/**
 * <b>IMPORTANT:</b> This class is not part of the API. Direct usage is discouraged.
 */
@:noDoc @:dox(hide)
class Ints {

   /**
    * Maximum positive value `Int` type can hold depending on target platform
    * <pre><code>
    * >>> Ints.MAX_VALUE > 0
    * </code></pre>
    */
   public static var MAX_VALUE(default, never):Int = {
      #if cs
         untyped __cs__("int.MaxValue");
      #elseif flash
         untyped __global__["int"].MAX_VALUE;
      #elseif java
         java.lang.Integer.MAX_VALUE;
      #elseif nodejs
         untyped js.Syntax.code("Number.MAX_SAFE_INTEGER");
      #elseif php
         php.Syntax.code("PHP_INT_MAX");
      #elseif python
         python.Syntax.code("import sys");
         Std.int(python.Syntax.code("sys.maxsize"));
      #elseif eval
         2147483647;
      #else // neko, cpp, lua, js, etc.
         Std.int(Math.pow(2, 31) - 1);
      #end
   }
}
