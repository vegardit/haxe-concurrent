/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, http://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent;

import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.lock.RLock;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface Service<T> {

    public var id(default, null):T;

    public var state(default, null):ServiceState;

    public function stop():Void;

    public function toString():String;
}


enum ServiceState {
    RUNNING;
    STOPPING;
    STOPPED;
}


@:abstract
class ServiceBase implements Service<Int> {

    static var _ids = new AtomicInt();

    public var id(default, never):Int = _ids.incrementAndGet();

    public var state(default, set):ServiceState = RUNNING;
    var _stateLock:RLock = new RLock();

    function set_state(s:ServiceState) {
        switch(s) {
            case RUNNING: trace('[$this] is running.');
            case STOPPING: trace('[$this] is stopping.');
            case STOPPED: trace('[$this] is stopped.');
        }
        return state = s;
    }

    function new() {
        trace('[$this] instantiated.');
    }

    public function stop() {
        _stateLock.execute(function() {
            if (state == RUNNING) {
                state = STOPPING;
            }
        });
    }

    inline
    public function toString():String {
        return Type.getClassName(Type.getClass(this)) + "#" + id;
    }
}
