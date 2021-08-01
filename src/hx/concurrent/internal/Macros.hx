/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.internal;

import haxe.macro.*;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:noCompletion
class Macros {

   static final __static_init = {
      #if (haxe_ver < 4)
         throw 'ERROR: As of haxe-concurrent 3.0.0, Haxe 4.x or higher is required!';
      #end
   };

   macro
   public static function addDefines() {
      final def = Context.getDefines();
      if (def.exists("cpp") ||
          def.exists("cs") ||
          def.exists("hl") ||
          def.exists("eval") ||
          def.exists("java") ||
          def.exists("neko") ||
          def.exists("python")
      ) {
         trace("[INFO] Setting compiler define 'threads'.");
         Compiler.define("threads");
      } else {
         trace("[INFO] NOT setting compiler define 'threads'.");
      }

      if (def.exists("java") && !def.exists("jvm")) {
         trace("[INFO] Setting compiler define 'java_src'.");
         Compiler.define("java_src");
      }
      return macro {}
   }

   macro
   public static function configureNullSafety() {
      haxe.macro.Compiler.nullSafety("hx.concurrent",
         #if (haxe_ver < 4.1)
            Strict // Haxe 4.x does not have StrictThreaded
         #else
            StrictThreaded
         #end
      );
      return macro {}
   }
}
