/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent;

import hx.concurrent.internal.Dates;
import hx.concurrent.internal.Either2;
import hx.concurrent.lock.RLock;


typedef FutureCompletionListener<T> = (FutureResult<T>) -> Void;


/**
 * https://en.wikipedia.org/wiki/Futures_and_promises
 */
interface Future<T> {

   /**
    * @return true if `Future.result` holds either `FutureResult.DONE` or `FutureResult.FAILURE`
    */
   function isComplete():Bool;

   /**
    * @return the future's result, i.e. computed result or exception
    */
   var result(default, null):FutureResult<T>;

   /**
    * Callback function `function(result:FutureResult<T>):Void` to be executed when a result
    * becomes available or immediately in case the future is already complete.
    */
   function onCompletion(listener:FutureCompletionListener<T>):Void;
}


enum FutureResult<T> {
   /**
    * Indicates the future completed successfully.
    *
    * @param time when the result was computed
    */
   VALUE(result:T, time:Float, future:Future<T>);

   /**
    * Indicates the future completed with an error.
    *
    * @param time when the failure occured
    */
   FAILURE(ex:ConcurrentException, time:Float, future:Future<T>);

   /**
    * Indicates the future is not yet complete.
    */
   PENDING(future:Future<T>);
}



abstract class AbstractFuture<T> implements Future<T> {

   final completionListeners = new Array<FutureCompletionListener<T>>();
   final sync = new RLock();

   #if java @:volatile #end
   public var result(default, null):FutureResult<T>;

   inline
   function new()
      result = FutureResult.PENDING(this);

   public function isComplete():Bool {
      return switch(result) {
         case PENDING(_): false;
         default: true;
      }
   }

   public function onCompletion(listener:FutureCompletionListener<T>):Void {
      sync.execute(() -> {
         // immediately invoke the listener in case a result is already present
         switch(result) {
            case PENDING(_):
            default: listener(result);
         }
         completionListeners.push(listener);
      });
   }
}


/**
 * Future that can be completed via `CompletableFuture#done` or `CompletableFuture#failed`
 */
class CompletableFuture<T> extends AbstractFuture<T> {

   inline
   public function new()
      super();

   /**
    * @return true if the result was set and false if `overwriteResult == false` and the future was already completed
    */
   public function complete(result:Either2<T, ConcurrentException>, overwriteResult = false):Bool {
      return sync.execute(() -> {
         if (overwriteResult || !isComplete()) {
            switch(result.value) {
               case a(value): this.result = FutureResult.VALUE(value, Dates.now(), this);
               case b(ex):    this.result = FutureResult.FAILURE(ex, Dates.now(), this);
            }
            for (listener in completionListeners)
               try listener(this.result) catch (ex) trace(ex);
            return true;
         }
         return false;
      });
   }
}


/**
 * Future with a pre-calculated result.
 */
final class CompletedFuture<T> implements Future<T> {

   public final result:FutureResult<T>;

   public function new(value:T)
      this.result = FutureResult.VALUE(value, Dates.now(), this);

   inline
   public function isComplete():Bool
      return true;

   inline
   public function onCompletion(listener:FutureCompletionListener<T>):Void
      listener(result);
}

