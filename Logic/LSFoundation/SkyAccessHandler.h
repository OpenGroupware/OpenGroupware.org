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

#ifndef __OGo_LSFoundation_SkyAccessHandler__
#define __OGo_LSFoundation_SkyAccessHandler__

#import <Foundation/NSObject.h>

@class NSMutableDictionary, NSString, NSArray, NSNumber;
@class EOGlobalID, EOKeyGlobalID;
@class LSCommandContext;

@protocol SkyAccessHandler<NSObject>

+ (id)accessHandlerWithContext:(LSCommandContext *)_ctx;
- (id)initWithContext:(LSCommandContext *)_ctx;

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_access;

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_str
  forAccessGlobalID:(EOGlobalID *)_accountID;

@end

@interface SkyAccessHandler : NSObject <SkyAccessHandler>
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

#endif /* __OGo_LSFoundation_SkyAccessHandler__ */
