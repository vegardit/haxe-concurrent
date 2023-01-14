/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.event;

import hx.concurrent.Future;

interface EventDispatcher<EVENT> extends EventListenable<EVENT> {

   function fire(event:EVENT):Future<Int>;

   function unsubscribeAll():Void;
}
