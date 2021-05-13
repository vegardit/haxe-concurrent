/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.thread;

import hx.concurrent.internal.Dates;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Threads {

   /**
    * <pre><code>
    * >>> Threads.current == Threads.current
    * </code></pre>
    *
    * @return a target-specific object or ID representing the current thread.
    */
   public static var current(get, never):Dynamic;
   static function get_current():Dynamic {
      #if (haxe_ver < 4.2 && hl)
         return Std.string(sys.thread.Thread.current());
      #elseif (haxe_ver < 4.2 && python)
         python.Syntax.code("import threading");
         return python.Syntax.code("threading.current_thread()");
      #elseif eval
         return cast(sys.thread.Thread.current(), eval.vm.NativeThread).id();
      #elseif threads
         return sys.thread.Thread.current();
      #elseif flash
         var worker = flash.system.Worker.current;
         return worker == null ? "MainThread" : worker;
      #else // javascript, lua, php
         return "MainThread";
      #end
   }


   /**
    * @return true if spawning threads is supported by current target
    */
   public static var isSupported(get, never):Bool;
   #if !python inline #end
   static function get_isSupported():Bool {
      #if threads
         #if python
            try {
               python.Syntax.code("from threading import Thread");
               return true;
            } catch (ex:Dynamic) {
               return false;
            }
         #end
         return true;
      #else
         return false;
      #end
   }


   #if (flash||sys)
   /**
    * Blocks the current thread until `condition` returns `true`.
    *
    * If <code>timeoutMS</code> is set 0, the function immediatly returns with the value returned by `condition`.
    * If <code>timeoutMS</code> is set to value > 0, the function waits up to the given timespan for a new message.
    * If <code>timeoutMS</code> is set to `-1`, the function waits indefinitely until a new message is available.
    * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
    */
   public static function await(condition:()->Bool, timeoutMS:Int, waitLoopSleepMS = 10):Bool {
      if (timeoutMS < -1)
         throw "[timeoutMS] must be >= -1";

      if (timeoutMS == 0)
         return condition();

      #if flash
      final cond = new flash.concurrent.Condition(new flash.concurrent.Mutex());
      #else
      final waitLoopSleepSecs = waitLoopSleepMS / 1000.0;
      #end

      final startAt = Dates.now();
      while (!condition()) {
         if (timeoutMS > 0) {
            final elapsedMS = Dates.now() - startAt;
            if (elapsedMS >= timeoutMS)
               return false;
         }
         // wait 1ms
         #if flash
            cond.wait(waitLoopSleepMS);
         #else
            Sys.sleep(waitLoopSleepSecs);

         #end
      }
      return true;
   }


   /**
    * Puts the current thread to sleep for the given milliseconds.
    */
   inline
   public static function sleep(timeMS:Int):Void {
      #if flash
         final cond = new flash.concurrent.Condition(new flash.concurrent.Mutex());
         cond.wait(timeMS);
      #else
         Sys.sleep(timeMS / 1000);
      #end
   }
   #end


   #if threads
   /**
    * Spawns a new deamon thread (i.e. terminates with the main thread) to execute the given function.
    */
   inline
   public static function spawn(func:()->Void):Void {
      #if (cpp || cs || eval || java || neko || hl)
         sys.thread.Thread.create(func);
      #elseif python
         final t = new python.lib.threading.Thread({target: func});
         t.daemon = true;
         t.start();
      #else // flash, javascript, lua
         throw "Unsupported operation.";
      #end
   }
   #end
}


