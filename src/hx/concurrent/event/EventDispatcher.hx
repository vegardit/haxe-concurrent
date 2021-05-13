/*
 * Copyright (c) 2016-2021 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.Future;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface EventDispatcher<EVENT> extends EventListenable<EVENT> {

   function fire(event:EVENT):Future<Int>;

   function unsubscribeAll():Void;
}
