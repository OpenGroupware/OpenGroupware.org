/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/

#ifndef __LSAccess_LSBundleCmdFactory_H__
#define __LSAccess_LSBundleCmdFactory_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>
#import <LSFoundation/LSCommandFactory.h>

@class NSSet, NSDate;

/**
 * @class LSBundleCmdFactory
 * @brief Bundle-based command factory for the Logic
 *        layer.
 *
 * LSBundleCmdFactory implements the LSCommandFactory
 * protocol by loading command definitions from
 * commands.plist resources inside Logic bundles. It
 * discovers, caches and instantiates command objects
 * identified by "domain::operation" names (e.g.
 * "person::get"). Bundles are loaded on demand via
 * NGBundleManager.
 *
 * @see LSCommandFactory
 * @see LSModuleManager
 * @see NGBundleManager
 */
@interface LSBundleCmdFactory : NSObject < LSCommandFactory >
{
@private
  NSMapTable *nameToInfo;
  NSSet      *commandsProvidedByBundles;
  NSDate     *lastBundleQuery;
}

@end

#endif /* __LSAccess_LSBundleCmdFactory_H__ */
