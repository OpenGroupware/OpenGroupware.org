/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#ifndef __OGoFoundation_LSWModuleManager_H__
#define __OGoFoundation_LSWModuleManager_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>

@class NSString, NSArray, NSMutableDictionary;
@class WOComponent;

@interface OGoModuleManager : NSObject
{
@protected
  NSMapTable *componentsConfig;
}

- (id)configValueForKey:(NSString *)_key
  inComponent:(WOComponent *)_component
  languages:(NSArray *)_languages;

@end

/* for compatibility, to be removed */

@interface LSWModuleManager : OGoModuleManager
@end

#endif /* __OGoFoundation_LSWModuleManager_H__ */
