/*
 * Copyright (c) 2016-2017 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.internal;

import haxe.macro.Compiler;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Macros {

    macro
    public static function addDefines() {
        var def = haxe.macro.Context.getDefines();
        if(def.exists("cpp") || def.exists("cs") || def.exists("java") || def.exists("neko") || def.exists("python")) {
            Compiler.define("threads");
        }
        return macro {}
    }
}

