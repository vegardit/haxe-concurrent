/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent;

import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.event.EventListenable;
import hx.concurrent.lock.RLock;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface Service<T> {

    var id(default, null):T;

    var state(default, null):ServiceState;

    function stop():Void;

    function toString():String;
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
    function set_state(s:ServiceState) {
        switch(s) {
            case RUNNING: trace('[$this] is running.');
            case STOPPING: trace('[$this] is stopping.');
            case STOPPED: trace('[$this] is stopped.');
        }
        return state = s;
    }
    var _stateLock:RLock = new RLock();


    inline
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


    public function toString():String {
        return Type.getClassName(Type.getClass(this)) + "#" + id;
    }

}
