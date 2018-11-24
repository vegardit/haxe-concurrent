/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.internal;

import haxe.macro.Compiler;
import haxe.macro.Context;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
class Macros {

    macro
    public static function addDefines() {
        var def = Context.getDefines();
        if (def.exists("cpp") ||
            def.exists("cs") ||
           (def.exists("hl") && Std.parseFloat(def["haxe_ver"]) >= 4) ||
            def.exists("java") ||
            def.exists("neko") ||
            def.exists("python")
        ) {
            trace("[INFO] Setting compiler define 'threads'.");
            Compiler.define("threads");
        } else {
            trace("[INFO] NOT setting compiler define 'threads'.");
        }
        return macro {}
    }
}
