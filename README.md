# haxe-concurrent - cross platform concurrency support
[![Build Status](https://travis-ci.org/vegardit/haxe-concurrent.svg?branch=master)](https://travis-ci.org/vegardit/haxe-concurrent)

1. [What is it?](#what-is-it)
1. [The `Executor` class](#executor-class)
1. [`hx.concurrent.atomic` package](#atomic-package)
1. [Installation](#installation)
1. [Using the latest code](#latest)
1. [License](#license)


## <a name="what-is-it"></a>What is it?

A [haxelib](http://lib.haxe.org/documentation/using-haxelib/) that provides concurrency support on all targets.

All classes are under the package `hx.concurrent` or below.

The library has been tested with Haxe 3.4.2 and 4.0 nightly on targets C++, C#, Flash, Java, JavaScript (node.js and phantom.js),
PHP 5, PHP 7, Python 3.

**Note:** When compiling for Flash the option `-swf-version 11.5` (or higher) must be specified.


## <a name="executor-class"></a>The `Executor` class

The [hx.concurrent.executor.Executor](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/executor/Executor.hx) allows you execute code
concurrently and to schedule tasks for later execution.

On platform with the thread support (C++, C#, Neko, Python, Java) threads are used to realize true concurrent execution on
other platforms `haxe.Timer` is used to at least realize async execution.

```haxe
import hx.concurrent.executor.Executor;

class Test {

    static function main() {
        var executor = Executor.create(3);  // <- 3 means to use a thread pool of 3 threads on platforms that support threads
        // depending on the platform either a thread-based or timer-based implementation is returned

        // define a task to be executed concurrently/async/scheduled
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
        executor.submit(myTask, FIXED_DELAY(200));      // repeated async execution 200ms after the last execution
        executor.submit(myTask, HOURLY(30));            // async execution 30min after each full hour
        executor.submit(myTask, DAILY(3, 30));          // async execution daily at 3:30
        executor.submit(myTask, WEEKLY(SUNDAY, 3, 30)); // async execution sundays at 3:30

        // submit a task and keep a reference to it
        var future = executor.submit(myTask, FIXED_RATE(200));

        // check if a result is already available
        switch(future.result) {
            case SUCCESS(result, time, _): trace('Successfully execution at ${Date.fromTime(time)} with result: $result');
            case EXCEPTION(ex, time, _):   trace('Execution failed at ${Date.fromTime(time)} with exception: $ex');
            case NONE:                     trace("No result yet...");
        }

        // check if the task is scheduled to be executed (again) in the future
        if(!future.isStopped) {
            trace('The task is scheduled for further executions with schedule: ${future.schedule}');
        }

        // cancel any future execution of the task
        future.cancel();
    }
```


## <a name="atomic-package"></a>The `hx.concurrent.atomic` package

The [hx.concurrent.atomic](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/atomic) package contains
mutable value holder classes that allow for thread.safe manipulation:

* [AtomicBool](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/atomic/AtomicBool.hx)
* [AtomicInt](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/atomic/AtomicInt.hx)
* [AtomicValue](https://github.com/vegardit/haxe-concurrent/blob/master/src/hx/concurrent/atomic/AtomicValue.hx)


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
