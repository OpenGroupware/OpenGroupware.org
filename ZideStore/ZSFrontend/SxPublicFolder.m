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

#include "SxPublicFolder.h"
#include "NSObject+ExValues.h"
#include "common.h"

@implementation SxPublicFolder

/* SoObject */

- (NSString *)nameInContainer {
  NSString *n;
  if ((n = [super nameInContainer]))
    return n;
  return @"public";
}

- (id)container {
  id c;
  if ((c = [super container]))
    return c;
  return [WOApplication application];
}

/* security */

- (NSString *)ownerID {
  return nil;
}

- (NSString *)ownerInContext:(id)_ctx {
  return [self ownerID];
}

/* messages */

- (int)zlGenerationCount {
  /* public folders have no messages and therefore never change */
  return 1;
}

- (id)getIDsAndVersionsAction:(id)_ctx {
  WOResponse *response = [(WOContext *)_ctx response];
  [response setStatus:200]; /* OK */
  [response setHeader:@"text/plain" forKey:@"content-type"];
  return response;
}

/* subfolders */

- (NSArray *)toManyRelationshipKeys {
  static NSArray *keys = nil;
  if (keys == nil) {
    keys = [[NSArray alloc] initWithObjects:
			      @"Contacts",
			      @"Enterprises",
			      @"Accounts",
			      @"Calendar",
			      nil];
  }
  return keys;
}

- (id)enterpriseFolderInContext:(id)_ctx {
  id folder;
  folder = [[NGClassFromString(@"SxEnterpriseFolder") alloc] 
	     initWithName:@"Enterprises" inContainer:self];
  [folder takeValue:@"public"     forKey:@"type"];
  return [folder autorelease];
}

- (id)contactsFolderInContext:(id)_ctx {
  id folder;
  folder = [[NGClassFromString(@"SxPersonFolder") alloc] 
	     initWithName:@"Contacts" inContainer:self];
  [folder takeValue:@"public" forKey:@"type"];
  return [folder autorelease];
}

- (id)accountsFolderInContext:(id)_ctx {
  id folder;
  folder = [[NGClassFromString(@"SxPersonFolder") alloc] init];
  [folder takeValue:@"account"  forKey:@"type"];
  [folder takeValue:self        forKey:@"container"];
  [folder takeValue:@"Accounts" forKey:@"nameInContainer"];
  return [folder autorelease];
}

- (id)calendarFolderInContext:(id)_ctx {
  id folder;
  folder = [[NGClassFromString(@"SxAppointmentFolder") alloc] 
	     initWithName:@"Calendar" inContainer:self];
  [folder takeValue:@"all intranet" forKey:@"group"];
  return [folder autorelease];
}

- (id)freeBusyInContext:(id)_ctx {
  id cmd = [[NGClassFromString(@"SxFreeBusy") alloc] init];
  return [cmd autorelease];
}

/* lookup */

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  // Evo-Hack
  if ([_key isEqualToString:@"public"] || [_key isEqualToString:@"Public"])
    /* TODO: limit recursion ? */
    return self;
  
  if ([_key isEqualToString:@"Contacts"])
    return [self contactsFolderInContext:_ctx];
  if ([_key isEqualToString:@"Enterprises"])
    return [self enterpriseFolderInContext:_ctx];
  if ([_key isEqualToString:@"Accounts"])
    return [self accountsFolderInContext:_ctx];
  
  if ([_key isEqualToString:@"Calendar"])
    return [self calendarFolderInContext:_ctx];

  if ([_key isEqualToString:@"freebusy"])
    return [self freeBusyInContext:_ctx];
  
  return [super lookupName:_key inContext:_ctx acquire:_flag];
}

/* base URL */

- (NSString *)baseURL {
  return [self baseURLInContext:
		 [(WOApplication *)[WOApplication application] context]];
}

/* DAV things */

- (BOOL)davHasSubFolders {
  /* public folders are there to have child folders */
  return YES;
}

@end /* SxPublicFolder */
