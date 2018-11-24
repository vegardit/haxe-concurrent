/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
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
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class BackgroundProcess {

    public var cmd(default, null):String;
    public var args(default, null):ReadOnlyArray<String>;

    /**
     * the process's standard input
     */
    public var stdin(get, never):haxe.io.Output;
    inline function get_stdin() return process.stdin;

    public var stderr(default, never):NonBlockingInput = new NonBlockingInput();
    public var stdout(default, never):NonBlockingInput = new NonBlockingInput();

    /**
     * the process ID or -1 on targets that have no support (e.g. Java < 9 on Windows)
     */
    public var pid(default, null):Int;

    /**
     * the exit code or null if the process is still running or was killed
     */
    public var exitCode(default, null):Null<Int>;

    public var isRunning(get, never): Bool;
    inline function get_isRunning() {
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

            try {
                exitCode = process.exitCode();
                process.close();
            } catch (ex:Dynamic) {
                // ignore
            }
        });

        Threads.spawn(function() {
            try {
                while (true)
                    try stderr.bytes.push(process.stderr.readByte()) catch (ex:haxe.io.Eof) break;
            } catch (ex:Dynamic) {
                trace(ex);
            }

            try {
                exitCode = process.exitCode();
                process.close();
            } catch (ex:Dynamic) {
                // ignore
            }
        });
    }

    /**
     * Kills the process.
     */
    inline
    public function kill():Void {
        process.kill();
    }

    public function waitForExit():Int {
        while (true) {
            if (exitCode != null)
                return exitCode;
            Threads.sleep(10);
        }
    }
}

@:allow(hx.concurrent.thread.BackgroundProcess)
class NonBlockingInput {

    var bytes(default, never) = new Queue<Null<Int>>();

    inline
    function new() { }

    /**
     * @return a line incl. new line separator or an empty string if no data
     */
    public function readLine(maxWaitMS:Int):String {
        var result = new BytesBuffer();
        var waitUntil = Dates.now() + maxWaitMS;
        while(true) {
            var byte = bytes.pop(0);
            if (byte == null) {
                if (Dates.now() > waitUntil)
                    break;
                else {
                    Threads.sleep(1);
                    continue;
                }
            }

            result.addByte(byte);

            if (byte == 10)
                break;
        }
        if (result.length == 0)
            return "";

        return result.getBytes().toString();
    }

    /**
     * @return all currently available ouput or an empty string if no data.
     */
    public function readAll():String {
        var result = new BytesBuffer();
        while(true) {
            var byte = bytes.pop(0);
            if (byte == null)
                break;

            result.addByte(byte);

        }
        if (result.length == 0)
            return "";

        return result.getBytes().toString();
    }

}
#end