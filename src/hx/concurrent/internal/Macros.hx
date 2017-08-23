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

