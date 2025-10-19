/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.thread;

#if threads
import haxe.Rest;
import haxe.ds.ReadOnlyArray;
import haxe.io.BytesBuffer;
import haxe.io.Eof;
import hx.concurrent.collection.Queue;
import hx.concurrent.internal.*;
import hx.concurrent.internal.NullAnalysisHelper.lazyNonNull;
import hx.concurrent.lock.RLock;
import hx.concurrent.Future.CompletableFuture;
import sys.io.Process;


/**
 * Similar to sys.io.Process but with non-blocking stderr/stdout to handle interactive prompts.
 *
 * Per BackgroundProcess two threads are spawned to handle the underlying blocking haxe.io.Input stderr/stdout streams.
 */
@:allow(hx.concurrent.thread.BackgroundProcessBuilder)
class BackgroundProcess {

   @:access(hx.concurrent.thread.BackgroundProcessBuilder)
   public static function builder(executable:String) {
      if (executable == null || executable.length == 0)
         throw "[executable] must not be null or empty";
      return new BackgroundProcessBuilder(executable);
   }

   /**
    * @throws an exception in case the process cannot be created
    */
   public static function create(executable:String, ...args:Dynamic):BackgroundProcess {
      return builder(executable).withArgs(args).build();
   }

   private static final SYNC = new RLock();

   public final executable:String;

   final _args = new Array<String>();
   public final args:ReadOnlyArray<String>;
   public var workDir(default, null) = Sys.getCwd();

   /**
    * - the exit code if the process finished, or
    * - null if the process is still running, or
    * - an undefined int value if the process was killed
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

   var process:Process = lazyNonNull();

   private function new(executable:String) {
      this.executable = executable;
      args = this._args;
   }

   public function isRunning(): Bool {
      if (exitCode != null)
         return false;

      try {
         stdin.flush();
         return true;
      } catch (ex) {
         return false;
      }
   }

   #if neko
   var isKilled = false;
   #end

   #if java @:access(sys.io.Process.proc) #end
   function run() {
      process = SYNC.execute(() -> {
         final oldCWD = Sys.getCwd();
         if (workDir != oldCWD) Sys.setCwd(workDir);
         try {
             final process = new Process(executable, _args);
             if (workDir != oldCWD) Sys.setCwd(oldCWD);
             return process;
         } catch (ex) {
            if (workDir != oldCWD) Sys.setCwd(oldCWD);
            throw ex;
         }
      });
      #if java
         try {
            pid = process.getPid();
         } catch (ex) {
            /* sys.io.Process#getPid() results into an Exception on Java 11:
             *   Exception in thread "main" java.lang.ClassCastException: class haxe.lang.Closure cannot be cast to class java.lang.Number (haxe.lang.Closure is in unnamed module of loader 'app'; java.lang.Number is in module java.base of loader 'bootstrap')
             *     at haxe.lang.Runtime.toInt(Runtime.java:127)
             *     at sys.io.Process.getPid(Process.java:218)
             */
         }

         if (pid == -1) {
            try {
               // Java 9+ https://docs.oracle.com/javase/9/docs/api/java/lang/ProcessHandle.html#pid--
               final javaProcess:hx.concurrent.internal.externs.java.lang.Process = cast process.proc;
               pid = cast(javaProcess.pid(), Int);
            } catch (ex) {
               // ignore
            }
         }
      #else
         pid = process.getPid();
      #end

      #if (java || cs) @:volatile #end
      var stdErrDone = false;
      Threads.spawn(() -> {
         try {
            while (#if neko !isKilled #else true #end) {
               try {
                  stderr.bytes.push(process.stderr.readByte());
               } catch (ex:haxe.io.Eof) {
                  #if eval Sys.sleep(0.001); #end // adding a sleep here somehow prevents sporadic premature Eof exceptions on Eval target
                  break;
               }
            }
         } catch (ex) {
            trace(ex);
         }

         stdErrDone = true;
      });

      Threads.spawn(() -> {
         try {
            while (#if neko !isKilled #else true #end)
               try
                  stdout.bytes.push(process.stdout.readByte())
               catch (ex:haxe.io.Eof)
                  break;
         } catch (ex) {
            trace(ex);
         }

         Threads.await(() -> stdErrDone, 5000);
         #if neko
            exitCode = isKilled ? -1 : process.exitCode();
         #else
            exitCode = process.exitCode();
         #end
         process.close();
      });
   }

   /**
    * Blocks until the process exits or timeoutMS is reached.
    *
    * If <code>timeoutMS</code> is set 0, immediately returns with null or the exit code.
    * If <code>timeoutMS</code> is set to value > 0, waits up to the given time span for the process to exit and returns either null or the exit code.
    * If <code>timeoutMS</code> is set to `-1`, waits indefinitely until the process exits.
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
    * If <code>timeoutMS</code> is set 0, immediately returns with null or the exit code.
    * If <code>timeoutMS</code> is set to value > 0, waits up to the given time span for the process to exit and returns either null or the exit code.
    * If <code>timeoutMS</code> is set to `-1`, waits indefinitely until the process exits.
    * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
    *
    * @return the exit code or null if the process was killed because timeout was reached.
    */
   public function awaitExitOrKill(timeoutMS:Int):Null<Int> {
      final exitCode = awaitExit(timeoutMS);
      if (isRunning())
         kill();
      return exitCode;
   }

   /**
    * Blocks until the process exits or timeoutMS is reached.
    *
    * If <code>timeoutMS</code> is set 0, immediately returns.
    * If <code>timeoutMS</code> is set to value > 0, waits up to the given time span for the process to exit and returns.
    * If <code>timeoutMS</code> is set to `-1`, waits indefinitely until the process exits.
    * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
    *
    * @return `true` if process exited successfully, `false` if process is still running
    * @throws if exitCode != 0
    */
   public function awaitSuccess(timeoutMS:Int, includeStdErr = true):Bool {
      final exitCode = awaitExit(timeoutMS);
      if (exitCode == 0)
         return true;

      if (exitCode == null)
         return false;

      if (includeStdErr)
         throw 'Process [exe=$executable,pid=$pid] failed with exit code $exitCode and error message: ${stderr.readAll()}';

      throw 'Process [exe=$executable,pid=$pid] failed with exit code $exitCode';
   }

   /**
    * Blocks until the process exits or timeoutMS is reached.
    *
    * If <code>timeoutMS</code> is set 0, immediately returns.
    * If <code>timeoutMS</code> is set to value > 0, waits up to the given timespan for the process exits and returns.
    * If <code>timeoutMS</code> is set to `-1`, waits indefinitely until the process exists.
    * If <code>timeoutMS</code> is set to value lower than -1, results in an exception.
    *
    * @return `true` if process exited successfully, `false` if process did not finish in time and thus process termination was requested
    * @throws if exitCode != 0
    */
   public function awaitSuccessOrKill(timeoutMS:Int, includeStdErr = true):Bool {
      if (!awaitSuccess(timeoutMS, includeStdErr)) {
         kill();
         return false;
      }
      return true;
   }

   /**
    * Kills the process if it is still running.
    *
    * The process may not be immediately terminated once the command is issued.
    * So it may be followed by an awaitExit() call.
    *
    * @return this for method chaining
    */
   #if java @:access(sys.io.Process.proc) #end
   public function kill():Void {
      if (!isRunning())
         return;

      function exec(cmd:String, ...args:String):Void {
         final p = new Process(cmd, args);
         p.exitCode(true);
         p.close();
      }

      final pid = this.pid;
      if (pid > -1) switch (OS.current) {
         case Linux, MacOS:
            exec("kill", "-STOP", '$pid'); // freeze process to prevent it from spawning more children
            exec("pkill", "-9", "-P", '$pid'); // kill descendant processes
            #if neko isKilled = true; #end // must be set before the actual termination on Linux to avoid a race condition
            exec("kill", "-9", '$pid'); // kill process
            return;
         case Windows:
            // kill process with descendant processes
            exec("taskkill", "/f", "/t", "/pid", '$pid');
            #if neko isKilled = true; #end
            return;
         default:
      }
      #if java
         process.proc.destroyForcibly();
      #else
         process.kill();
      #end
      #if neko isKilled = true; #end
   }
}

@:allow(hx.concurrent.thread.BackgroundProcess)
class NonBlockingInput {

   final bytes = new Queue<Null<Int>>();
   var linePreview = "";


   inline //
   function new() {
   }


   private function readLineInternal(maxWaitMS:Int):BytesBuffer {
      final buffer = new BytesBuffer();
      final waitUntil = Dates.now() + maxWaitMS;
      while (true) {
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

      final buffer = readLineInternal(maxWaitMS);
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

      final buffer = readLineInternal(maxWaitMS);

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
    * @return all currently available output or an empty string if no data.
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


class BackgroundProcessBuilder {

   final process:BackgroundProcess;
   var isBuilt = false;

   inline function new(executable:String) {
      process = new BackgroundProcess(executable);
   }

   /**
    * @throws an exception in case the process cannot be created
    */
   public function build():BackgroundProcess {
      if (isBuilt)
         throw "Already built!";

      isBuilt = true;
      process.run();
      return process;
   }

   public function withArg(...arg:Any):BackgroundProcessBuilder {
      withArgs(arg);
      return this;
   }

   // instead of Array<Any> using Array<Dynamic> which allows arrays of mixed content
   public function withArgs(args:Array<Dynamic>):BackgroundProcessBuilder {
      for (arg in args) {
         if (arg is Array)
            withArgs(arg);
         else
            process._args.push(Std.string(arg));
      }
      return this;
   }

   public function withWorkDir(path:String):BackgroundProcessBuilder {
      process.workDir = path;
      return this;
   }
}
#end
