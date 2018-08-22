/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
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
        if(def.exists("cpp") || def.exists("cs") || def.exists("hl") || def.exists("java") || def.exists("neko") || def.exists("python")) {
            trace("[INFO] Setting compiler define 'threads'.");
            Compiler.define("threads");
        } else {
            trace("[INFO] NOT setting compiler define 'threads'.");
        }
        return macro {}
    }
}
