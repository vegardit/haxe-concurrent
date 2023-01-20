/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.thread;

#if threads

import haxe.ds.ReadOnlyArray;
import haxe.io.BytesBuffer;
import haxe.io.Eof;
import hx.concurrent.collection.Queue;
import hx.concurrent.internal.*;
import hx.concurrent.lock.RLock;
import sys.io.Process;

/**
 * Similar to sys.io.Process but with non-blocking stderr/stdout to
 * handle interactive prompts.
 *
 * Per BackgroundProcess two threads are spawned to handle the underlying
 * blocking haxe.io.Input stderr/stdout streams.
 */
class BackgroundProcess {

   public final cmd:String;
   public final args:Null<ReadOnlyArray<String>>;

   /**
    * the exit code or null if the process is still running or was killed
    */
   #if java @:volatile #end
   public var exitCode(default, null):Null<Int>;

   /**
    * the process ID or -1 on targets that have no support (e.g. Java < 9 on Windows)
    */
   public var pid(default, null):Int = -1;

   /**
    * the process's standard input
    */
   public var stdin(get, never):haxe.io.Output;
   inline function get_stdin() return process.stdin;

   public final stderr = new NonBlockingInput();
   public final stdout = new NonBlockingInput();

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
   public function new(cmd:String, ?args:Array<Any>) {
      if (cmd == null || cmd.length == 0)
         throw "[cmd] must not be null or empty";

      this.cmd = cmd;
      final argsAsString = args == null ? null : args.map((arg) -> Std.string(arg));
      this.args = argsAsString;
      process = new Process(cmd, argsAsString);
      #if java
         try {
            pid = process.getPid();
         } catch (ex:Dynamic) {
            /* sys.io.Process#getPid() results into an Exception on Java 11:
             *   Exception in thread "main" java.lang.ClassCastException: class haxe.lang.Closure cannot be cast to class java.lang.Number (haxe.lang.Closure is in unnamed module of loader 'app'; java.lang.Number is in module java.base of loader 'bootstrap')
             *     at haxe.lang.Runtime.toInt(Runtime.java:127)
             *     at sys.io.Process.getPid(Process.java:218)
             */
         }

         if (pid == -1) {
            try {
               // Java 9+ https://docs.oracle.com/javase/9/docs/api/java/lang/ProcessHandle.html#pid--
               final pidMethod = Reflect.field(process.proc, "pid");
               pid = Reflect.callMethod(process.proc, pidMethod, []);
            } catch (ex:Dynamic) {
               // ignore
            }
         }
      #else
         pid = process.getPid();
      #end

      @:volatile
      var stdErrDone = false;
      Threads.spawn(() -> {
         try {
            while (true) {
               try {
                  stderr.bytes.push(process.stderr.readByte());
               } catch (ex:haxe.io.Eof) {
                #if eval Sys.sleep(0.001); #end // adding a sleep here somehow prevents sporadic premature Eof exceptions on Eval target
                break;
               }
            }
         } catch (ex:Dynamic) {
            trace(ex);
         }

         stdErrDone = true;
      });

      Threads.spawn(() -> {
         try {
            while (true)
               try stdout.bytes.push(process.stdout.readByte()) catch (ex:haxe.io.Eof) break;
         } catch (ex:Dynamic) {
             trace(ex);
         }

         Threads.await(() -> stdErrDone, 5000);
         exitCode = process.exitCode();
         process.close();
      });
   }

   /**
    * Blocks until the process exits or timeoutMS is reached.
    *
    * If <code>timeoutMS</code> is set 0, immediatly returns with the null or the exit code.
    * If <code>timeoutMS</code> is set to value > 0, waits up to the given timespan for the process exists and returns either null or the exit code.
    * If <code>timeoutMS</code> is set to `-1`, waits indefinitely until the process exists.
    * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
    *
    * @return the exit code or null
    */
   public function awaitExit(timeoutMS:Int):Null<Int> {
      Threads.await(() -> exitCode != null, timeoutMS);
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
    * @return `true` if process exited successful, `false` if process is still running
    * @throws if exitCode != 0
    */
   public function awaitSuccess(timeoutMS:Int, includeStdErr = true):Bool {
      final exitCode = awaitExit(timeoutMS);
      if (exitCode == 0)
         return true;

      if (exitCode == null)
         return false;

      if (includeStdErr)
         throw 'Process [cmd=$cmd,pid=$pid] failed with exit code $exitCode and error message: ${stderr.readAll()}';

      throw 'Process [cmd=$cmd,pid=$pid] failed with exit code $exitCode';
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

   final bytes = new Queue<Null<Int>>();
   var linePreview = "";


   inline
   function new() { }


   private function readLineInteral(maxWaitMS:Int):BytesBuffer {
      final buffer = new BytesBuffer();
      final waitUntil = Dates.now() + maxWaitMS;
      while(true) {
         final byte = bytes.pop(0);
         if (byte == null) {
            if (Dates.now() > waitUntil)
               break;

            Threads.sleep(5);
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

      final buffer = readLineInteral(maxWaitMS);
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
         final line = linePreview;
         linePreview = "";
         return line;
      }

      final buffer = readLineInteral(maxWaitMS);

      if (linePreview.length == 0) {
         if (buffer.length == 0)
            return "";

         return buffer.getBytes().toString();
      }

      final line = buffer.length == 0 ? linePreview : linePreview + buffer.getBytes().toString();
      linePreview = "";
      return line;
   }


   /**
    * @return all currently available ouput or an empty string if no data.
    */
   public function readAll():String {
      final buffer = new BytesBuffer();
      while(true) {
         final byte = bytes.pop(5);
         if (byte == null)
            break;

         buffer.addByte(byte);
      }

      if (linePreview.length == 0) {
         if (buffer.length == 0)
            return "";

         return buffer.getBytes().toString();
      }

      final all = buffer.length == 0 ? linePreview : linePreview + buffer.getBytes().toString();
      linePreview = "";
      return all;
   }
}
#end
