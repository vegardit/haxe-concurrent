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
package hx.concurrent.collection;
import hx.concurrent.internal.Either3;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface OrderedCollection<T> extends Collection<T> {

    public function insertAt(idx:Int, x:T):Void;
    public function removeAt(idx:Int, throwIfOutOfRange:Bool=false):Null<T>;
    public function removeFirst(throwIfEmpty:Bool=false):Null<T>;
    public function removeLast(throwIfEmpty:Bool=false):Null<T>;

    public function get(idx:Int, throwIfOutOfRange:Bool=false):Null<T>;
    public function indexOf(x:T, startAt:Int=0):Int;
    public function lastIndexOf(x:T, ?startAt:Int):Int;
}
