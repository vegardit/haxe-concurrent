/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.internal;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:noCompletion
abstract AnyAsString(String) from String to String {

  @:from
  inline
  static function fromBool(value:Bool):AnyAsString return value ? "true" : "false";

  @:from
  inline
  static function fromAny<T>(value:T):AnyAsString return Std.string(value);
}
