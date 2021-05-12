# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Fixed
- compilation error on Haxe 4.2: `EventListenable.hx:36: characters 30-41 : { remove : (hx.concurrent.event.AbstractEventListenable.EVENT -> Void) -> Bool } has no field addIfAbsent`
- `int += AtomicInt` not working on Haxe 4.2
- `Threads.current` and `RLock` not working on Haxe 4.2 with HashLink
- potential race condition when executing BackgroundProcess


## [3.0.0] - 2020-04-21

### Changed
- minimum required Haxe version is now 4.x
- removed support for old PHP5 target
- renamed `DefaultEventListenable` to `AbstractEventListenable`


## [2.1.3] - 2019-08-02

### Changed
- Use sys.thread API for C# on Haxe4

### Fixed
- Haxe4.RC3 eval compilation errror: sys.thread.Thread has no field id


## [2.1.2] - 2019-06-25

### Fixed
- [Issue #4](https://github.com/vegardit/haxe-concurrent/issues/4) [haxe4+hl] "Lock was aquired by another thread!"
- [haxe4+hl] ScheduleTools.firstRunAt() returns wrong values


## [2.1.1] - 2019-05-19

### Fixed
- [haxe4+python] Compile error "Ints.hx:46: lines 46-68 : Float should be Int"


## [2.1.0] - 2019-05-09

### Added
- class hx.concurrent.thread.BackgroundProcess
- property Queue#length
- method ThreadPool#awaitTermination()
- method ThreadPool#cancelPendingTasks()
- method ThreadPool#getExecutingTasks()
- method ThreadPool#getPendingTasks()

### Changed
- [PR-3](https://github.com/vegardit/haxe-concurrent/pull/3) Use new `sys.thread `package when possible on Haxe 4


## [2.0.1] - 2018-10-23

### Fixed
- class hx.concurrent.lock.RWLock not working on JS target
- workaround for HL on Haxe 3.4 which is missing native thread support


## [2.0.0] - 2018-09-20

### Added
- interface hx.concurrent.lock.Acquirable
- class hx.concurrent.CountDownLatch
- class hx.concurrent.lock.RWLock (upgradeable Read Write Lock)

### Changed
- renamed methid hx.concurrent.thread.Threads#wait() to hx.concurrent.thread.Threads#await()
- changed hx.concurrent.lock.Semaphore from abstract to class

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
- field hx.concurrent.Service.ServiceState.STARTING
- method hx.concurrent.Service.Service#start()

### Changed
- replaced license header by "SPDX-License-Identifier: Apache-2.0"


## [1.0.0] - 2017-10-16

### Added
- Initial release
