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

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:noCompletion
class Dates {

    #if cs
        static var epochTicks = new cs.system.DateTime(1970, 1, 1).Ticks;
        static var ticksPerMS = cast cs.system.TimeSpan.TicksPerMillisecond;
    #elseif flash
        static var inizializedTimeMS = Date.now().getTime();
        static var initializedStampMS = flash.Lib.getTimer();
    #elseif js
    #elseif sys
    #else
        static var inizializedTimeMS = Date.now().getTime();
        static var initializedStampSecs = haxe.Timer.stamp();
    #end

    /**
     * @return the current time in milli-seconds
     */
    inline
    public static function now():Float {
        #if cs
            return cast(cs.system.DateTime.UtcNow.Ticks - epochTicks, Float) / ticksPerMS;
        #elseif flash
            return inizializedTimeMS + (flash.Lib.getTimer() - initializedStampMS);
        #elseif java
            return cast java.lang.System.currentTimeMillis();
        #elseif js
            return untyped __js__("Date.now()");
        #elseif sys // Cpp, Lua, Neko, HL, PHP, Python
            return Sys.time() * 1000;
        #else
            // fallback for new platforms
            return inizializedTimeMS + ((haxe.Timer.stamp() - initializedStampSecs) * 1000);
        #end
    }

    /**
     * Returns an Date object with the local time.
     *
     * @param time in milli-seconds
     */
    inline
    public static function toDate(time:Float):Date {
        return Date.fromTime(time);
    }
}
