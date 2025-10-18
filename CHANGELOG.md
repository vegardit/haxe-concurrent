# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]


## [5.1.4] - 2024-12-19

### Added
- support threads on `jvm` target


## [5.1.3] - 2023-05-07

### Fixed
- null analysis issues with Haxe 4.3.x
- ClassCastException with Haxe 4.3.x on JVM target


## [5.1.2] - 2023-05-06

### Fixed
- `Null safety: Cannot pass nullable value to not-nullable argument` with Haxe 4.3.x


## [5.1.1] - 2023-04-02

### Fixed
- `Unknown identifier : _pollPeriod`


## [5.1.0] - 2023-04-02

### Added
- [PR#26](https://github.com/vegardit/haxe-concurrent/pull/26) add `ThreadPool.pollPeriod` (thanks to [onehundredfeet](https://github.com/onehundredfeet))


## [5.0.3] - 2023-02-17

### Changed
- use rest arguments with BackgroundProcess args


## [5.0.2] - 2023-02-16

### Changed
- make BackgroundProcess constructor private


## [5.0.0] - 2023-02-16

### Changed
- disabled locking/thread support for eval target because of too many platform issues
- refactored Future API
  - added class `CompletableFuture`
  - renamed class `ConstantFuture` to `CompletedFuture`
  - added function `Future.isComplete`
  - replace field `Future.onResult` with function `Future.onCompletion`
- refactored Executor API
  - replace field `Executor.onResult()` with function `Executor.onCompletion()`
  - renamed `TaskFuture.waitAndGet()` to `TaskFuture.awaitCompletion()`
  - renamed `TaskFutureBase` to `AbstractTaskFuture`
- `BackgroundProcess#kill()` now explicitly kills descendant processes if possible

### Fixed
- `BackgroundProcess.pid` is not with Java 9+

### Added
- method `BackgroundProcess#builder(exe)`
- method `BackgroundProcess#create(exe, args)`
- method `BackgroundProcess#awaitExitOrKill()`
- method `BackgroundProcess#awaitSuccessOrKill()`


## [4.1.0] - 2023-01-20

### Added
- `BackgroundProcess#awaitSuccess()` now returns a boolean indicating if the process finished or is still running

### Fixed
- Fix "Uncaught exception Lock was acquired by another thread!"
- Prevent random premature killing of external processes run via BackgroundProcess


## [4.0.1] - 2023-01-17

### Fixed
- `BackgroundProcess#readAll` always returns empty string


## [4.0.0] - 2022-04-26

### Changed
- minimum required Haxe version is now 4.2

### Added
- type `SynchronizedMap`


## [3.0.2] - 2021-09-10

### Fixed
- [Issue #12](https://github.com/vegardit/haxe-concurrent/issues/12) memory leak in ThreadPoolExecutor


## [3.0.1] - 2021-08-01

### Fixed
- Haxe 4.2 support
  - compilation error: `EventListenable.hx:36: characters 30-41 : { remove : (hx.concurrent.event.AbstractEventListenable.EVENT -> Void) -> Bool } has no field addIfAbsent`
  - `int += AtomicInt` not working
  - `Threads.current` and `RLock` not working on HashLink
- potential race condition when executing `BackgroundProcess`
- Warning `untyped __php__ is deprecated.`
- Warning `__js__ is deprecated, use js.Syntax.code instead`


## [3.0.0] - 2020-04-21

### Changed
- minimum required Haxe version is now 4.x
- removed support for old PHP5 target
- renamed `DefaultEventListenable` to `AbstractEventListenable`


## [2.1.3] - 2019-08-02

### Changed
- Use sys.thread API for C# on Haxe4

### Fixed
- Haxe4.RC3 eval compilation error: sys.thread.Thread has no field id


## [2.1.2] - 2019-06-25

### Fixed
- [Issue #4](https://github.com/vegardit/haxe-concurrent/issues/4) [haxe4+hl] "Lock was aquired by another thread!"
- [haxe4+hl] ScheduleTools.firstRunAt() returns wrong values


## [2.1.1] - 2019-05-19

### Fixed
- [haxe4+python] Compile error "Ints.hx:46: lines 46-68 : Float should be Int"


## [2.1.0] - 2019-05-09

### Added
- class `hx.concurrent.thread.BackgroundProcess`
- property `Queue#length`
- method `ThreadPool#awaitTermination()`
- method `ThreadPool#cancelPendingTasks()`
- method `ThreadPool#getExecutingTasks()`
- method `ThreadPool#getPendingTasks()`

### Changed
- [PR-3](https://github.com/vegardit/haxe-concurrent/pull/3) Use new `sys.thread `package when possible on Haxe 4


## [2.0.1] - 2018-10-23

### Fixed
- class `hx.concurrent.lock.RWLock` not working on JS target
- workaround for HL on Haxe 3.4 which is missing native thread support


## [2.0.0] - 2018-09-20

### Added
- interface `hx.concurrent.lock.Acquirable`
- class `hx.concurrent.CountDownLatch`
- class `hx.concurrent.lock.RWLock` (upgradeable Read Write Lock)

### Changed
- renamed method `hx.concurrent.thread.Threads#wait()` to `hx.concurrent.thread.Threads#await()`
- changed `hx.concurrent.lock.Semaphore` from abstract to class

### Fixed
- define "threads" is now set correctly for targets supporting real threading


## [1.2.0] - 2018-08-22

### Added
- better error logging in Executor
- use native threads on HL target


## [1.1.1] - 2018-04-19

### Fixed
- [java] "java.lang.IllegalArgumentException: Non-positive period" when using TimerExecutor.submit()


## [1.1.0] - 2018-04-15

### Added
- field `hx.concurrent.Service.ServiceState.STARTING`
- method `hx.concurrent.Service.Service#start()`

### Changed
- replaced license header by "SPDX-License-Identifier: Apache-2.0"


## [1.0.0] - 2017-10-16

### Added
- Initial release
