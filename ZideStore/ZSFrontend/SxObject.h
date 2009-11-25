/*
  Copyright (C) 2002-2009 SKYRIX Software AG
  Copyright (C) 2009      Helge Hess

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

#ifndef __ZideStore_SxObject_H__
#define __ZideStore_SxObject_H__

#import <Foundation/NSObject.h>

/*
  SxObject

  This is the root class for OGo based objects (not folders). Objects
  are identified by a numeric primary key, eg "12345".
  
  It's mostly used for these operations:
  - update
  - delete
  - create
  
  But also (sometimes, when ?) for
  - fetch
*/

@class NSNumber, NSString, NSMutableDictionary, NSSet, NSException;
@class EOGlobalID;
@class LSCommandContext;
@class WOContext;

@interface SxObject : NSObject
{
  id       container; /* can be non-retained, depends on container */
  NSString *nameInContainer;
  id       eo;
  struct {
    BOOL isNew:1;
    int  reserved:31;
  } flags;
}

- (id)initWithEO:(id)_eo                inFolder:(id)_folder;
- (id)initWithName:(NSString *)_key     inFolder:(id)_folder;
- (id)initNewWithName:(NSString *)_name inFolder:(id)_folder;
- (id)initWithName:(NSString *)_key     inContainer:(id)_folder;

/* accessors */

- (BOOL)isNew;
- (NSNumber *)primaryKey;
- (EOGlobalID *)globalID;
- (void)detachFromContainer;

/* resolving the object */

- (LSCommandContext *)commandContextInContext:(id)_ctx;
- (id)objectInContext:(id)_ctx;
- (id)object;

/* E2K Security */

- (BOOL)isReadAllowed;
- (BOOL)isModificationAllowed;
- (BOOL)isDeletionAllowed;

/* property sets */

- (NSSet *)propertySetNamed:(NSString *)_name;

/* actions */

- (id)GETAction:(WOContext *)_ctx;
- (id)DELETEAction:(id)_ctx;

- (NSException *)matchesRequestConditionInContext:(id)_ctx;

/* reflection necessary for operation */

- (id)primaryDeleteObjectInContext:(id)_ctx;

+ (NSString *)primaryKeyName;
+ (NSString *)entityName;
+ (NSString *)getCommandName;
+ (NSString *)deleteCommandName;
+ (NSString *)newCommandName;
+ (NSString *)setCommandName;

@end

#endif /* __ZideStore_SxObject_H__ */
