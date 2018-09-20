/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.internal;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Ints {

    /**
     * Maximum value Int type can hold depending on target platform
     */
    public static var MAX_VALUE(default, never):Int = {
        #if cs
            untyped __cs__("int.MaxValue");
        #elseif flash
            untyped __global__["int"].MAX_VALUE;
        #elseif java
            untyped __java__("Integer.MAX_VALUE");
        #elseif js
            untyped __js__("Number.MAX_SAFE_INTEGER");
        #elseif php
            untyped __php__("PHP_INT_MAX");
        #elseif python
            python.Syntax.pythonCode("import sys");
            python.Syntax.pythonCode("sys.maxsize");
        #else // neko, cpp, lua, etc.
            Std.int(Math.pow(2,31)-1);
        #end
    }


    /**
     * Maximum negative value Int type can hold depending on target platform
     */
    public static var MIN_VALUE(default, never):Int = {
        #if cs
            untyped __cs__("int.MinValue");
        #elseif flash
            untyped __global__["int"].MIN_VALUE;
        #elseif java
            untyped __java__("Integer.MIN_VALUE");
        #elseif js
            untyped __js__("Number.MIN_SAFE_INTEGER");
        #elseif php
            untyped __php__("PHP_INT_MIN");
        #elseif python
            python.Syntax.pythonCode("import sys");
            -python.Syntax.pythonCode("sys.maxsize") -1;
        #else // neko, cpp, lua, etc.
            -Std.int(Math.pow(2,31));
        #end
    }

}
