# haxe-concurrent - cross platform concurrency support
[![Build Status](https://travis-ci.org/vegardit/haxe-concurrent.svg?branch=master)](https://travis-ci.org/vegardit/haxe-concurrent)

1. [What is it?](#what-is-it)
1. [`hx.concurrent.atomic` package](#atomic-package)
1. [`hx.concurrent.collection` package](#collection-package)
1. [`hx.concurrent.executor` package](#executor-package)
1. [`hx.concurrent.event` package](#event-package)
1. [`hx.concurrent.lock` package](#lock-package)
1. [`hx.concurrent.thread` package](#thread-package)
1. [Installation](#installation)
1. [Using the latest code](#latest)
1. [License](#license)
1. [Alternatives](#alternatives)


## <a name="what-is-it"></a>What is it?

A [haxelib](http://lib.haxe.org/documentation/using-haxelib/) that provides some basic platform agnostic concurrency support.

All classes are under the package `hx.concurrent` or below.

The library has been tested with Haxe 3.4.4 and 4.0 nightly on targets C++, C#, Flash, Java, JavaScript (node.js and phantom.js),
PHP 5, PHP 7, Python 3.

**Note:**
* When compiling for Flash the option `-swf-version 11.5` (or higher) must be specified, otherwise you will get `Class flash.concurrent::Condition could not be found.`
* When compiling for C# the option `-D net-ver=45` must be specified, otherwise you may get `error CS0234: The type or namespace name 'Volatile' does not exist in the namespace 'System.Threading'. Are you missing an assembly reference?`


## <a name="atomic-package"></a>The `hx.concurrent.atomic` package

The [hx.concurrent.atomic](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/atomic) package contains mutable value holder classes that allow for thread.safe manipulation:

* [AtomicBool](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/atomic/AtomicBool.hx)
* [AtomicInt](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/atomic/AtomicInt.hx)
* [AtomicValue](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/atomic/AtomicValue.hx)


## <a name="collection-package"></a>The `hx.concurrent.collection` package

The [hx.concurrent.collection](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/collection) package contains thread-safe implementations of differnt types of collections:

* [CopyOnWriteArray](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/collection/CopyOnWriteArray.hx)
* [Queue](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/collection/Queue.hx)
* [SynchronizedArray](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/collection/SynchronizedArray.hx)
* [SynchronizedLinkedList](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/collection/SynchronizedLinkedList.hx)


## <a name="executor-package"></a>The `hx.concurrent.executor` package

The [hx.concurrent.collection](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/collection) package contains
[Executor](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/executor/Executor.hx) implementations that allow
to execute functions concurrently and to schedule tasks for later/repeated execution.

On platform with the thread support (C++, C#, Neko, Python, Java) threads are used to realize true concurrent execution, on other
platforms `haxe.Timer` is used to at least realize async execution.

```haxe
import hx.concurrent.executor.*;

class Test {

    static function main() {
        var executor = Executor.create(3);  // <- 3 means to use a thread pool of 3 threads on platforms that support threads
        // depending on the platform either a thread-based or timer-based implementation is returned

        // define a function to be executed concurrently/async/scheduled (return type can also be Void)
        var myTask=function():Date {
            trace("Executing...");
            return Date.now();
        }

        // submit 10 tasks each to be executed once asynchronously/concurrently as soon as possible
        for(i in 0...10) {
            executor.submit(myTask);
        }

        executor.submit(myTask, ONCE(2000));            // async one-time execution with a delay of 2 seconds
        executor.submit(myTask, FIXED_RATE(200));       // repeated async execution every 200ms
        executor.submit(myTask, FIXED_DELAY(200));      // repeated async execution 200ms after the last execution
        executor.submit(myTask, HOURLY(30));            // async execution 30min after each full hour
        executor.submit(myTask, DAILY(3, 30));          // async execution daily at 3:30
        executor.submit(myTask, WEEKLY(SUNDAY, 3, 30)); // async execution sundays at 3:30

        // submit a task and keep a reference to it
        var future = executor.submit(myTask, FIXED_RATE(200));

        // check if a result is already available
        switch(future.result) {
            case SUCCESS(value, time, _): trace('Successfully execution at ${Date.fromTime(time)} with result: $value');
            case FAILURE(ex, time, _):    trace('Execution failed at ${Date.fromTime(time)} with exception: $ex');
            case NONE:                    trace("No result yet...");
        }

        // check if the task is scheduled to be executed (again) in the future
        if(!future.isStopped) {
            trace('The task is scheduled for further executions with schedule: ${future.schedule}');
        }

        // cancel any future execution of the task
        future.cancel();
    }
```


## <a name="event-package"></a>The `hx.concurrent.event` package

The [hx.current.event](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/event) package contains classes for type-safe event dispatching.

```haxe
import hx.concurrent.executor.*;
import hx.concurrent.event.*;

class Test {

    static function main() {
        /**
         * create a dispatcher that notifies listeners/callbacks synchronously in the current thread
         */
        var syncDispatcher = new SyncEventDispatcher<String>(); // events are of type string

        // create event listener
        var onEvent = function(event:String):Void {
            trace('Received event: $event');
        }

        syncDispatcher.subscribe(onEvent);

        // notify all registered listeners synchronously,
        // meaning this method call blocks until all listeners are finished executing
        syncDispatcher.fire("Hey there");

        /**
         * create a dispatcher that notifies listeners ansychronously using an execturo
         */
        var executor = Executor.create(5); // thread-pool with 5 threads
        var asyncDispatcher = new AsyncEventDispatcher<String>(executor);

        // notify all registered listeners asynchronously,
        // meaning this method call returns immediately
        asyncDispatcher.fire("Hey there");

        // fire another event and get notified when all listeners where notified
        var future = asyncDipatcher.fire("Boom");

        future.onResult = function(result:Future.FutureResult<Int>) {
            switch(result) {
                case SUCCESS(count, _): trace('$count listeners were successfully notified');
                case FAILURE(ex, _): trace('Event could not be delivered because of: $ex');
            }
        };

    }
}
```


## <a name="lock-package"></a>The `hx.concurrent.lock` package

The [hx.concurrent.lock](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/lock) package contains lock implementations for different purposes:

* [RLock](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/lock/RLock.hx) - a re-entrant lock
* [Semaphore](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/lock/Semaphore.hx)


## <a name="thread-package"></a>The `hx.concurrent.thread` package

The [hx.concurrent.thread](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/thread) package contains
classes for platforms supporting threads:

* [ThreadPool](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/thread/ThreadPool.hx) - very basic thread-pool implementation supporting C++, C#, Neko, Java and Python. For advanced concurrency or cross-platform requirements use [Executor](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/executor/Executor.hx) instead.
* [Threads](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/thread/Threads.hx)


## <a name="installation"></a>Installation

1. install the library via haxelib using the command:
    ```
    haxelib install haxe-concurrent
    ```

2. use in your Haxe project

   * for [OpenFL](http://www.openfl.org/)/[Lime](https://github.com/openfl/lime) projects add `<haxelib name="haxe-concurrent" />` to your [project.xml](http://www.openfl.org/documentation/projects/project-files/xml-format/)
   * for free-style projects add `-lib haxe-concurrent`  to `your *.hxml` file or as command line option when running the [Haxe compiler](http://haxe.org/manual/compiler-usage.html)


## <a name="latest"></a>Using the latest code

### Using `haxelib git`

```
haxelib git haxe-concurrent https://github.com/vegardit/haxe-concurrent master D:\haxe-projects\haxe-concurrent
```

###  Using Git

1. check-out the master branch
    ```
    git clone https://github.com/vegardit/haxe-concurrent --branch master --single-branch D:\haxe-projects\haxe-concurrent
    ```

2. register the development release with haxe
    ```
    haxelib dev haxe-concurrent D:\haxe-projects\haxe-concurrent
    ```

###  Using Subversion

1. check-out the trunk
    ```
    svn checkout https://github.com/vegardit/haxe-concurrent/trunk D:\haxe-projects\haxe-concurrent
    ```

2. register the development release with haxe
    ```
    haxelib dev haxe-concurrent D:\haxe-projects\haxe-concurrent
    ```


## <a name="license"></a>License

All files are released under the [Apache License 2.0](https://github.com/vegardit/haxe-concurrent/blob/master/LICENSE.txt).


## <a name="alternatives"></a>Alternatives

**Other libraries addressing concurrency/parallism:**

* https://github.com/thomasuster/haxe-threadpool - thread pool implementation for C++ and Neko
* https://github.com/Blank101/haxe-concurrency
* https://github.com/kevinresol/filelock
* http://hamaluik.com/posts/a-platform-agnostic-thread-pool-for-haxe-openfl/ - cross platform API but only uses real threads on C++ and Neko, otherwise single threaded blocking execution
* https://github.com/Rezmason/Golems
* https://github.com/zjnue/hxworker
