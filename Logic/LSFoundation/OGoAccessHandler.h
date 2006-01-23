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

#ifndef __OGo_LSFoundation_OGoAccessHandler__
#define __OGo_LSFoundation_OGoAccessHandler__

#import <Foundation/NSObject.h>

/*
  OGoAccessHandler protocol / OGoAccessHandler base class

  This is an abstract superclass for objects which check whether a user has
  access to a given object.
  
  Subclasses include:
  - OGoCompanyAccessHandler
  - OGoAptAccessHandler
  - ...
  
  TODO: document
*/

@class NSMutableDictionary, NSString, NSArray, NSNumber;
@class EOGlobalID, EOKeyGlobalID;
@class LSCommandContext;

@protocol OGoAccessHandler < NSObject >

+ (id)accessHandlerWithContext:(LSCommandContext *)_ctx;
- (id)initWithContext:(LSCommandContext *)_ctx;

/*
  This is the primary access-check method and must be overridden by subclasses.

  The 'access global-id' is the primary key of the login account.
*/
- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_access;

/*
  Returns all oids which have access for the given operation. Overwrite in
  subclasses for batch operation (performance).
*/
- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_str
  forAccessGlobalID:(EOGlobalID *)_accountID;

@end


@interface OGoAccessHandler : NSObject <OGoAccessHandler>
{
@private
  LSCommandContext *context;
}

+ (id)accessHandlerWithContext:(LSCommandContext *)_ctx;

- (id)initWithContext:(LSCommandContext *)_ctx;

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_accountID;

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_str
  forAccessGlobalID:(EOGlobalID *)_accessGID;

- (LSCommandContext *)context;
- (void)cacheOperation:(NSString *)_str for:(NSNumber *)_id;

@end

#endif /* __OGo_LSFoundation_OGoAccessHandler__ */
