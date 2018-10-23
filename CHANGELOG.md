# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## [Unreleased]


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
