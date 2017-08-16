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
package hx.concurrent;

import haxe.CallStack;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class ConcurrentException {

    static inline var INDENT:String = #if java "\t" #else "  " #end;


    inline
    public static function capture(ex:Dynamic) {
        return new ConcurrentException(ex);
    }


    public var cause(default, null):Dynamic;
    public var causeStackTrace(default, null):Array<StackItem>;


    function new(cause:Dynamic) {
        this.cause = cause;
        this.causeStackTrace = CallStack.exceptionStack();
    }


    #if (!python) inline #end
    public function rethrow() {
        #if neko
            neko.Lib.rethrow(cause);  // Neko has proper support
        #elseif python
            //python.Syntax.pythonCode("raise"); // rethrows the last but not necessarily the captured exception
            python.Syntax.pythonCode('raise Exception(self.toString()) from None');
        #else
            // cpp.Lib.rethrow(cause);  // swallows stacktrace
            // cs.Lib.rethrow(this);    // throw/rethrow swallows complete stacktrace
            // js.Lib.rethrow();        // rethrows the last but not necessarily the captured exception
            // php.Lib.rethrow(cause);  // swallows stacktrace
            throw this.toString();
        #end
    }


    public function toString():String {
        var sb = new StringBuf();
        sb.add("rethrown exception:\n");
        sb.add(INDENT); sb.add("--------------------\n");
        sb.add(INDENT); sb.add("| Exception : "); sb.add(cause); sb.add("\n");
        for (item in CallStack.toString(causeStackTrace).split("\n")) {
            if (item == "") continue;
            sb.add(INDENT);
            sb.add(StringTools.replace(item, "Called from", "| at"));
            sb.add("\n");
        }
        sb.add(INDENT); sb.add("--------------------");
        return sb.toString();
    }
}
