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
package hx.concurrent.executor;

import hx.concurrent.Future.FutureResult;
import hx.concurrent.executor.Executor.ExecutorState;
import hx.concurrent.executor.Executor.TaskFuture;
import hx.concurrent.executor.Schedule.ScheduleTools;
import hx.concurrent.internal.Dates;
import hx.concurrent.internal.Either2;

/**
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class TimerBasedExecutor extends Executor {

    var _scheduledTasks = new Array<TimerBasedTaskFuture<Dynamic>>();

    inline
    public function new() {
    }


    override
    public function submit<T>(task:Either2<Void->T,Void->Void>, ?schedule:Schedule):TaskFuture<T> {

        return _stateLock.execute(function() {
            if (state != RUNNING)
                throw "Cannot accept new tasks. TaskExecutor is not in state [RUNNING].";

            // cleanup task list
            var i = _scheduledTasks.length;
            while (i-- > 0) if (_scheduledTasks[i].isStopped) _scheduledTasks.splice(i, 1);

            var future = new TimerBasedTaskFuture<T>(task, schedule == null ? Executor.NOW_ONCE : schedule);
            switch(schedule) {
                case ONCE(0):
                default: _scheduledTasks.push(future);
            }
            return future;
        });
    }


    override
    public function stop() {
        _stateLock.execute(function() {
            if (state == ExecutorState.RUNNING) {
                state = ExecutorState.STOPPING;

                for (t in _scheduledTasks)
                    t.cancel();

                state = ExecutorState.STOPPED;
            }
        });
    }
}


private class TimerBasedTaskFuture<T> implements TaskFuture<T> {

    public var result(default, null):FutureResult<T>;

    public var schedule(default, null):Schedule;
    public var isStopped(default, null) = false;

    public var onResult(default, set):FutureResult<T>->Void = null;
    inline function set_onResult(fn:FutureResult<T>->Void) {
        return _sync.execute(function() {
            // immediately invoke the callback function in case a result is already present
            if(fn != null) switch(this.result) {
                case NONE(_):
                default: fn(this.result);
            }
            return onResult = fn;
        });
    }

    var _sync:RLock = new RLock();
    var _task:Either2<Void->T,Void->Void>;
    var _timer:haxe.Timer;


    public function new(task:Either2<Void->T,Void->Void>, schedule:Schedule) {
        _task = task;
        result = FutureResult.NONE(this);

        this.schedule = ScheduleTools.assertValid(schedule);

        var initialDelay = Std.int(ScheduleTools.firstRunAt(this.schedule) - Dates.now());
        haxe.Timer.delay(this.run, initialDelay < 0 ? 0 : initialDelay);
    }


    public function run():Void {
        if (isStopped)
            return;

        _sync.execute(function() {
            if (_timer == null) {
                switch(schedule) {
                    case FIXED_RATE(intervalMS, _): _timer = new haxe.Timer(intervalMS); _timer.run = this.run;
                    case HOURLY(_): _timer = new haxe.Timer(ScheduleTools.HOUR_IN_MS);   _timer.run = this.run;
                    case DAILY(_):  _timer = new haxe.Timer(ScheduleTools.DAY_IN_MS);    _timer.run = this.run;
                    case WEEKLY(_): _timer = new haxe.Timer(ScheduleTools.WEEK_IN_MS);   _timer.run = this.run;
                    default:
                }
            }
        }, true);

        var result:FutureResult<T> = null;
        try {
            var resultValue:T = switch(_task.value) {
                case a(fn): fn();
                case b(fn): fn(); null;
            }
            result = FutureResult.SUCCESS(resultValue, Dates.now(), this);
        } catch (e:Dynamic)
            result = FutureResult.EXCEPTION(ConcurrentException.capture(e), Dates.now(), this);

        _sync.execute(function() {
            // calculate next run for FIXED_DELAY
            switch(schedule) {
                case ONCE(_): isStopped = true;
                case FIXED_DELAY(intervalMS, _): _timer = haxe.Timer.delay(this.run, intervalMS);
                default: /*nothing*/
            }

            this.result = result;
            if (onResult != null)
                onResult(result);
        }, true);
    }


    inline
    public function cancel():Void {
        if(_timer != null) _timer.stop();
        isStopped = true;
    }
}
