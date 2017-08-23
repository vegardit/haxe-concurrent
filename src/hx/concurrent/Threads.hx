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

import hx.concurrent.internal.Dates;

/**
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
#if sys
class Threads {

    /**
     * Puts the current thread in sleep for the given amount of milli seconds.
     */
    inline
    public static function sleep(timeMS:Int) {
        Sys.sleep(timeMS/1000);
    }

    #if threads
    /**
     * Spawns a new deamon thread (i.e. terminates with the main thread) to execute the given function.
     */
    inline
    public static function spawn(func:Void->Void) {
        #if cpp
            cpp.vm.Thread.create(func);
        #elseif cs
            new cs.system.threading.Thread(cs.system.threading.ThreadStart.FromHaxeFunction(func)).Start();
        #elseif java
            java.vm.Thread.create(func);
        #elseif neko
            neko.vm.Thread.create(func);
        #elseif python
            var t = new python.lib.threading.Thread({target: func});
            t.daemon = true;
            t.start();
        #else
            throw "Unsupported operation.";
        #end
    }
    #end

    /**
     * Blocks the current thread until `condition` returns `true`.
     *
     * If <code>timeoutMS</code> is set 0, the function immediatly returns with the value returned by `condition`.
     * If <code>timeoutMS</code> is set to value > 0, the function waits up to the given timespan for a new message.
     * If <code>timeoutMS</code> is set to `-1`, the function waits indefinitely until a new message is available.
     * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
     */
    public static function wait(condition:Void->Bool, timeoutMS:Int, sleepSecs = 0.001):Bool {
        if (timeoutMS < -1)
            throw "[timeoutMS] must be >= -1";

        if (timeoutMS == 0)
            return condition();

        var startAt = Dates.now();
        while (!condition()) {
            if (timeoutMS > 0) {
                var elapsedMS = Dates.now() - startAt;
                if (elapsedMS >= timeoutMS)
                    return false;
            }
            // wait 1ms
            Sys.sleep(sleepSecs);
        }
        return true;
    }
}
#end

