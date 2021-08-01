/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.executor;

import hx.concurrent.internal.Dates;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
enum Schedule {

   /**
    * @param initialDelayMS time to wait until first execution, default is 0.
    */
   ONCE(?initialDelayMS:Int);

   /**
    * @param initialDelayMS time to wait until first executio, default is 0.
    */
   FIXED_DELAY(intervalMS:Int, ?initialDelayMS:Int);

   /**
    * @param initialDelayMS time to wait until first execution, default is 0.
    */
   FIXED_RATE(intervalMS:Int, ?initialDelayMS:Int);

   /**
    * @param minute 0-59, default is 0.
    * @param second 0-59, default is 0.
    */
   HOURLY(?minute:Int, ?second:Int);

   /**
    * @param hour 0-23, default is 0.
    * @param minute 0-59, default is 0.
    * @param second 0-59, default is 0.
    */
   DAILY(?hour:Int, ?minute:Int, ?second:Int);

   /**
    * @param day default is ScheduleWeekday#Sunday.
    * @param hour 0-23, default is 0.
    * @param minute 0-59, default is 0.
    * @param second 0-59, default is 0.
    */
   WEEKLY(?day:ScheduleWeekday, ?hour:Int, ?minute:Int, ?second:Int);
}


@:enum
abstract ScheduleWeekday(Int) from Int to Int {
   public var SUNDAY = 0;
   public var MONDAY = 1;
   public var TUESDAY = 2;
   public var WEDNESDAY = 3;
   public var THURSDAY = 4;
   public var FRIDAY = 5;
   public var SATURDAY = 6;
}


class ScheduleTools {

   public static inline final HOUR_IN_MS = 60 * 60 * 1000;
   public static inline final DAY_IN_MS = 24 * HOUR_IN_MS;
   public static inline final WEEK_IN_MS = 7 * DAY_IN_MS;


   public static function applyDefaults(schedule:Schedule):Schedule {
       switch(schedule) {
         case ONCE(initialDelayMS):
            if (initialDelayMS == null)
               return Schedule.ONCE(0);

         case FIXED_DELAY(intervalMS, initialDelayMS):
            if (initialDelayMS == null)
               return Schedule.FIXED_DELAY(intervalMS, 0);

         case FIXED_RATE(intervalMS, initialDelayMS):
            if (initialDelayMS == null)
               return Schedule.FIXED_RATE(intervalMS, 0);

         case HOURLY(minute, second):
            if (minute == null || second == null)
               return Schedule.HOURLY(
                  minute == null ? 0 : minute,
                  second == null ? 0 : second
               );

         case DAILY(hour, minute, second):
            if (hour == null || minute == null || second == null)
               return Schedule.DAILY(
                  hour == null ? 0 : hour,
                  minute == null ? 0 : minute,
                  second == null ? 0 : second
               );

         case WEEKLY(day, hour, minute, second):
            if (day == null || hour == null || minute == null || second == null)
               return Schedule.WEEKLY(
                  day == null ? ScheduleWeekday.SUNDAY : day,
                  hour == null ? 0 : hour,
                  minute == null ? 0 : minute,
                  second == null ? 0 : second
               );
      }
      return schedule;
   }


   /**
    * @return schedule with default values applied if required.
    * @throws exception if any argument is out-of range
    */
   public static function assertValid(schedule:Schedule):Schedule {
      schedule = applyDefaults(schedule);
      @:nullSafety(Off)
      switch(schedule) {
         case ONCE(initialDelayMS):
            if (initialDelayMS < 0)
               throw "[Schedule.ONCE.initialDelayMS] must be >= 0";

         case FIXED_DELAY(intervalMS, initialDelayMS):
            if (intervalMS <= 0)
               throw "[Schedule.FIXED_DELAY.intervalMS] must be > 0";
            if (initialDelayMS == null || initialDelayMS < 0)
               throw "[Schedule.FIXED_DELAY.initialDelayMS] must be >= 0";

         case FIXED_RATE(intervalMS, initialDelayMS):
            if (intervalMS <= 0)
               throw "[Schedule.FIXED_RATE.intervalMS] must be > 0";
            if (initialDelayMS < 0)
               throw "[Schedule.FIXED_RATE.initialDelayMS] must be >= 0";

         case HOURLY(minute, second):
            if (minute == null || minute < 0) throw "[Schedule.DAILY.minute] must be between >= 0 and <= 59";
            if (second == null || second < 0) throw "[Schedule.DAILY.second] must be between >= 0 and <= 59";

         case DAILY(hour, minute, second):
            if (hour   == null || hour   < 0) throw "[Schedule.DAILY.hour] must be between >= 0 and <= 23";
            if (minute == null || minute < 0) throw "[Schedule.DAILY.minute] must be between >= 0 and <= 59";
            if (second == null || second < 0) throw "[Schedule.DAILY.second] must be between >= 0 and <= 59";

         case WEEKLY(day, hour, minute, second):
            if (hour   == null || hour   < 0) throw "[Schedule.WEEKLY.hour] must be between >= 0 and <= 23";
            if (minute == null || minute < 0) throw "[Schedule.WEEKLY.minute] must be between >= 0 and <= 59";
            if (second == null || second < 0) throw "[Schedule.WEEKLY.second] must be between >= 0 and <= 59";
      }
      return schedule;
   }


   /**
    * @return time in milliseconds when the first run with this schedule would occur
    */
   public static function firstRunAt(schedule:Schedule):Float {

      schedule = assertValid(schedule);

      // validate schedule and calculate initial run
      @:nullSafety(Off)
      switch(schedule) {
         case ONCE(initialDelayMS):                    return Dates.now() + initialDelayMS;
         case FIXED_DELAY(intervalMS, initialDelayMS): return Dates.now() + initialDelayMS;
         case FIXED_RATE(intervalMS, initialDelayMS):  return Dates.now() + initialDelayMS;

         case HOURLY(minute, second):
            final nowMS:Float = Dates.now();
            final now = Date.fromTime(nowMS);

            final runAtSecondOfHour = minute * 60 + second;
            final elapsedSecondsThisHour = now.getMinutes() * 60 + now.getSeconds();

            return nowMS + (runAtSecondOfHour - elapsedSecondsThisHour) * 1000 + (elapsedSecondsThisHour > runAtSecondOfHour ? HOUR_IN_MS : 0);

         case DAILY(hour, minute, second):
            final nowMS:Float = Dates.now();
            final now = Date.fromTime(nowMS);

            final runAtSecondOfDay = hour * 60 * 60 + minute * 60 + second;
            final elapsedSecondsToday = now.getHours() * 60 * 60 + now.getMinutes() * 60 + now.getSeconds();

            return nowMS + (runAtSecondOfDay - elapsedSecondsToday) * 1000  + (elapsedSecondsToday > runAtSecondOfDay ? DAY_IN_MS : 0);


         case WEEKLY(day, hour, minute, second):
            final nowMS:Float = Dates.now();
            final now = Date.fromTime(nowMS);

            final runAtSecondOfDay = hour * 60 * 60 + minute * 60 + second;
            final elapsedSecondsToday = now.getHours() * 60 * 60 + now.getMinutes() * 60 + now.getSeconds();

            final dayIndex:Int = day;
            if (dayIndex == now.getDay())
               return nowMS + (runAtSecondOfDay - elapsedSecondsToday) * 1000 + (elapsedSecondsToday > runAtSecondOfDay ? WEEK_IN_MS : 0);
            else if (now.getDate() < dayIndex)
               return nowMS + (runAtSecondOfDay - elapsedSecondsToday) * 1000 + (DAY_IN_MS * (dayIndex - now.getDate()));
            else
               return nowMS + (runAtSecondOfDay - elapsedSecondsToday) * 1000 + (DAY_IN_MS * (7 - (dayIndex - now.getDate())));
      }
   }
}

