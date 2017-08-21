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
import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.collection.FIFOQueue;
import hx.concurrent.executor.Executor.TaskFuture;
import hx.concurrent.executor.Schedule.ScheduleTools;
import hx.concurrent.internal.Dates;
import hx.concurrent.internal.Either2;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
#if (cpp||cs||java||neko||python)
class ThreadBasedExecutor extends Executor {

    public inline static var SCHEDULER_RESOLUTION_MS = 5;
    public inline static var SCHEDULER_RESOLUTION_SEC = SCHEDULER_RESOLUTION_MS / 1000;

    var _threadCount = new AtomicInt(0);
    var _runNow = new FIFOQueue<ThreadBasedTaskFuture<Dynamic>>();

    var _scheduledTasks = new Array<ThreadBasedTaskFuture<Dynamic>>();
    var _newScheduledTasks = new FIFOQueue<ThreadBasedTaskFuture<Dynamic>>();


    public function new(threadPoolSize:Int) {
        if (threadPoolSize < 1)
            throw "[threadPoolSize] must be > 0";

        /*
         * start scheduler thread
         */
        Threads.spawn(function() {

            var doneTasks = new Array<ThreadBasedTaskFuture<Dynamic>>();

            while (state == RUNNING) {
                /*
                 * put scheduled tasks in execution queue if required
                 */
                for (t in _scheduledTasks) {
                    if (t.isDue())
                        _runNow.push(t);
                    else if (t.isStopped)
                        doneTasks.push(t);
                }

                /*
                 * purge done tasks from list
                 */
                if (doneTasks.length > 0)
                    for (t in doneTasks)
                        _scheduledTasks.remove(t);

                /*
                 * process newly scheduled tasks or sleep
                 */
                var t = _newScheduledTasks.pop();
                if (t == null) {
                    Sys.sleep(SCHEDULER_RESOLUTION_SEC);
                    continue;
                }

                var startAt = Dates.now();
                _scheduledTasks.push(t);

                while (true) {
                    // work on the _newScheduledTasks queue for max. 5ms
                    if (Dates.now() - startAt > SCHEDULER_RESOLUTION_MS)
                        break;

                    var t = _newScheduledTasks.pop();
                    if (t == null)
                        break;
                    _scheduledTasks.push(t);
                }
            }

            /*
             * cancel any remaining scheduled tasks
             */
            for (t in _scheduledTasks)
                t.cancel();
            while (true) {
                var t = _newScheduledTasks.pop();
                if (t == null) break;
                t.cancel();
            }
        });

        /*
         * start worker threads
         */
        for (i in 0...threadPoolSize) {
            Threads.spawn(function() {
                _threadCount++;

                while (true) {
                    var task = _runNow.pop(SCHEDULER_RESOLUTION_MS);
                    if (task == null) {
                        if(state != RUNNING)
                            break;
                    } else
                        task.run();
                }

                _threadCount--;

                if (_threadCount == 0)
                    _stateLock.execute(function() {
                        state = STOPPED;
                    });
            });
        }
    }


    override
    public function submit<T>(task:Either2<Void->T,Void->Void>, ?schedule:Schedule):TaskFuture<T> {
        return _stateLock.execute(function() {
            if (state != RUNNING)
                throw "Cannot accept new tasks. TaskExecutor is not in state [RUNNING].";

            var future = new ThreadBasedTaskFuture<T>(task, schedule == null ? Executor.NOW_ONCE : schedule);

            // skip round-trip via scheduler for one-shot tasks that should be executed immediately
            switch(schedule) {
                case ONCE(_):
                    if (future.isDue()) {
                        _runNow.push(future);
                        return future;
                    }
                default:
            }

            _newScheduledTasks.push(future);
            return future;
        });
    }
}

private class ThreadBasedTaskFuture<T> implements TaskFuture<T> {

    public var result(default, null):FutureResult<T>;

    public var schedule(default, null):Schedule;
    public var isStopped(default, null) = false;

    public var onResult(default, set):FutureResult<T>->Void = null;
    var _onResultLock:RLock = new RLock();
    inline function set_onResult(fn:FutureResult<T>->Void) {
        return _onResultLock.execute(function() {
            if(fn != null) switch(this.result) {
                case NONE(_):
                default: fn(this.result);
            }
            return onResult = fn;
        });
    }

    var _nextRunAt:Float;
    var _task:Either2<Void->T,Void->Void>;

    public function new(task:Either2<Void->T,Void->Void>, schedule:Schedule) {
        _task = task;
        result = FutureResult.NONE(this);

        this.schedule = ScheduleTools.assertValid(schedule);
        this._nextRunAt = ScheduleTools.firstRunAt(this.schedule);
    }


    public function isDue():Bool {
        if (isStopped || _nextRunAt == -1)
            return false;

        if (Dates.now() >= _nextRunAt) {
            // calculate next run
            switch(schedule) {
                case ONCE(_):                   _nextRunAt = -1;
                case FIXED_DELAY(_):            _nextRunAt = -1;
                case FIXED_RATE(intervalMS, _): _nextRunAt += intervalMS;
                case HOURLY(_):                 _nextRunAt += ScheduleTools.HOUR_IN_MS;
                case DAILY(_):                  _nextRunAt += ScheduleTools.DAY_IN_MS;
                case WEEKLY(_):                 _nextRunAt += ScheduleTools.WEEK_IN_MS;
            };
            return true;
        }
        return false;
    }


    public function run():Void {
        if (isStopped)
            return;

        var result:FutureResult<T> = null;
        try {
            var resultValue:T = switch(_task.value) {
                case a(fn): fn();
                case b(fn): fn(); null;
            }
            result = FutureResult.SUCCESS(resultValue, Dates.now(), this);
        } catch (e:Dynamic)
            result = FutureResult.EXCEPTION(ConcurrentException.capture(e), Dates.now(), this);

        // calculate next run for FIXED_DELAY
        switch(schedule) {
            case ONCE(_):                    isStopped = true;
            case FIXED_DELAY(intervalMS, _): _nextRunAt = Dates.now() + intervalMS;
            default: /*nothing*/
        };

        _onResultLock.execute(function() {
            this.result = result;
            if (onResult != null)
                onResult(result);
        }, true);
    }


    inline
    public function cancel():Void {
        isStopped = true;
    }

    public function waitAndGet(timeoutMS:Int):FutureResult<T> {

        Threads.wait(function() {
            return switch(this.result) {
                case NONE(_): false;
                default: true;
            };
        }, timeoutMS, ThreadBasedExecutor.SCHEDULER_RESOLUTION_SEC);

        return this.result;
    }
}
#end
