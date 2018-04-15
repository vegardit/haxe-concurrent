/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
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
