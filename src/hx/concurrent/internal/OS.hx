/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.concurrent.internal;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class OS {

   public static var current(default, never):OSType =
      #if android
         OSType.Android;
      #elseif ios
         OSType.IOS;
      #else
         switch (Sys.systemName()) {
            case "Linux": OSType.Linux;
            case "Mac": OSType.MacOS;
            case "Windows": OSType.Windows;
            default: OSType.Unknown(Sys.systemName());
         };
      #end
}

enum OSType {
   Android;
   IOS;
   Linux;
   MacOS;
   Windows;
   Unknown(identifier:String);
}
