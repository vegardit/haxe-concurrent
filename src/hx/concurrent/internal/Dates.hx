/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
class Dates {

   #if cs
      static final epochTicks = new cs.system.DateTime(1970, 1, 1).Ticks;
      static final ticksPerMS = cast cs.system.TimeSpan.TicksPerMillisecond;
   #elseif flash
      static final inizializedTimeMS = Date.now().getTime();
      static final initializedStampMS = flash.Lib.getTimer();
   #elseif js
   #elseif sys
   #else
      static final inizializedTimeMS = Date.now().getTime();
      static final initializedStampSecs = haxe.Timer.stamp();
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
   public static function toDate(time:Float):Date
      return Date.fromTime(time);
}
