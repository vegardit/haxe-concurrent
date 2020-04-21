/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.thread;

#if threads

import haxe.io.BytesBuffer;
import haxe.io.Eof;
import hx.concurrent.collection.Queue;
import hx.concurrent.internal.*;
import sys.io.Process;

/**
 * Similar to sys.io.Process but with non-blocking stderr/stdout to
 * handle interactive prompts.
 *
 * Per BackgroundProcess two threads are spawned to handle the underlying
 * blocking haxe.io.Input stderr/stdout streams.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class BackgroundProcess {

   public var cmd(default, null):String;
   public var args(default, null):ReadOnlyArray<String>;

   /**
    * the exit code or null if the process is still running or was killed
    */
   public var exitCode(default, null):Null<Int>;

   /**
    * the process ID or -1 on targets that have no support (e.g. Java < 9 on Windows)
    */
   public var pid(default, null):Int;

   /**
    * the process's standard input
    */
   public var stdin(get, never):haxe.io.Output;
   inline function get_stdin() return process.stdin;

   public var stderr(default, never):NonBlockingInput = new NonBlockingInput();
   public var stdout(default, never):NonBlockingInput = new NonBlockingInput();

   public var isRunning(get, never): Bool;
   function get_isRunning() {
      if (exitCode != null)
         return false;
      try {
         stdin.flush();
         return true;
      } catch (ex:Dynamic) {
         return false;
      }
   }

   var process:Process;

   /**
    * @throws an exception in case the process cannot be created
    */
   @:access(sys.io.Process.proc)
   public function new(cmd:String, ?args:Array<AnyAsString>) {
      if (cmd == null || cmd.length == 0)
         throw "[cmd] must not be null or empty";

      this.cmd = cmd;
      this.args = args;
      process = new Process(cmd, args);
      #if java
         try {
            pid = process.getPid();
         } catch (ex:Dynamic) {
            /* process.getPid() results into an Exception on Java 11:
             *   Exception in thread "main" java.lang.ClassCastException: class haxe.lang.Closure cannot be cast to class java.lang.Number (haxe.lang.Closure is in unnamed module of loader 'app'; java.lang.Number is in module java.base of loader 'bootstrap')
             *     at haxe.lang.Runtime.toInt(Runtime.java:127)
             *     at sys.io.Process.getPid(Process.java:218)
             *     at hx.concurrent.thread.BackgroundProcess.__hx_ctor_hx_concurrent_thread_BackgroundProcess(BackgroundProcess.java:43)
             *     at hx.concurrent.thread.BackgroundProcess.<init>(BackgroundProcess.java:17)
             */
            pid = -1;
         }

         if (pid == -1) {
            try {
               // Java 9+
               var pidMethod = Reflect.field(process.proc, "pid");
               pid = Reflect.callMethod(process.proc, pidMethod, []);
            } catch (ex:Dynamic) {
               // ignore
            }
         }
      #else
         pid = process.getPid();
      #end

      Threads.spawn(function() {
         try {
            while (true)
               try stdout.bytes.push(process.stdout.readByte()) catch (ex:haxe.io.Eof) break;
          } catch (ex:Dynamic) {
            trace(ex);
         }

         try exitCode = process.exitCode() catch (ex:Dynamic) { /* ignore */ }
         try process.close()               catch (ex:Dynamic) { /* ignore */ }
      });

      Threads.spawn(function() {
         try {
            while (true)
               try stderr.bytes.push(process.stderr.readByte()) catch (ex:haxe.io.Eof) break;
         } catch (ex:Dynamic) {
            trace(ex);
         }

         try exitCode = process.exitCode() catch (ex:Dynamic) { /* ignore */ }
         try process.close()               catch (ex:Dynamic) { /* ignore */ }
      });
   }

   /**
    * Blocks until the process exits or timeoutMS is reached.
    *
    * If <code>timeoutMS</code> is set 0, immediatly returns with the null or the exit code.
    * If <code>timeoutMS</code> is set to value > 0, waits up to the given timespan for the process exists and returns either null or the exit code.
    * If <code>timeoutMS</code> is set to `-1`, waits indefinitely until the process exists.
    * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
    */
   public function awaitExit(timeoutMS:Int):Null<Int> {
      Threads.await(function() return exitCode != null, timeoutMS);
      return exitCode;
   }

   /**
    * Blocks until the process exits or timeoutMS is reached.
    *
    * If <code>timeoutMS</code> is set 0, immediatly returns.
    * If <code>timeoutMS</code> is set to value > 0, waits up to the given timespan for the process exists and returns.
    * If <code>timeoutMS</code> is set to `-1`, waits indefinitely until the process exists.
    * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
    *
    * @throws if exitCode != 0
    */
   public function awaitSuccess(timeoutMS:Int, includeStdErr = true):Void {
      var exitCode = awaitExit(timeoutMS);
      if (exitCode == 0)
         return;

      if (includeStdErr)
         throw 'Process failed with exit code $exitCode and error message: ${stderr.readAll()}';

      throw 'Process failed with exit code $exitCode';
   }

   /**
    * Kills the process.
    */
   inline
   public function kill():Void {
      process.kill();
   }
}

@:allow(hx.concurrent.thread.BackgroundProcess)
class NonBlockingInput {

   var bytes(default, never) = new Queue<Null<Int>>();
   var linePreview = "";


   inline
   function new() { }


   inline
   private function readLineInteral(maxWaitMS:Int):BytesBuffer {
      var buffer = new BytesBuffer();
      var waitUntil = Dates.now() + maxWaitMS;
      while(true) {
         var byte = bytes.pop(0);
         if (byte == null) {
            if (Dates.now() > waitUntil)
               break;

            Threads.sleep(1);
            continue;
         }

         buffer.addByte(byte);

         if (byte == 10)
            break;
      }
      return buffer;
   }


   /**
    * Characters read through previewLine() will still be returned by readLine()
    * when invoked.
    *
    * @return a line incl. new line separator or an empty string if no data
    */
   public function previewLine(maxWaitMS:Int):String {
      if (StringTools.endsWith(linePreview, "\n"))
         return linePreview;

      var buffer = readLineInteral(maxWaitMS);
      if (buffer.length == 0)
         return linePreview;

      linePreview = linePreview + buffer.getBytes().toString();
      return linePreview;
   }


   /**
    * @return a line incl. new line separator or an empty string if no data
    */
   public function readLine(maxWaitMS:Int):String {
      if (linePreview.length > 0 && StringTools.endsWith(linePreview, "\n")) {
         var line = linePreview;
         linePreview = "";
         return line;
      }

      var buffer = readLineInteral(maxWaitMS);

      if (linePreview.length == 0) {
         if (buffer.length == 0)
            return "";

         return buffer.getBytes().toString();
      }

      var line = buffer.length == 0 ? linePreview : linePreview + buffer.getBytes().toString();
      linePreview = "";
      return line;
   }


   /**
    * @return all currently available ouput or an empty string if no data.
    */
   public function readAll():String {
      var buffer = new BytesBuffer();
      while(true) {
         var byte = bytes.pop(5);
         if (byte == null)
            break;

         buffer.addByte(byte);
      }
      if (buffer.length == 0)
         return "";

      if (linePreview.length == 0) {
         if (buffer.length == 0)
            return "";

         return buffer.getBytes().toString();
      }

      var all = buffer.length == 0 ? linePreview : linePreview + buffer.getBytes().toString();
      linePreview = "";
      return all;
   }
}
#end