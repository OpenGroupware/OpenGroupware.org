/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#include "SxStoreInfoFolder.h"
#include "common.h"
#include "NGResourceLocator+ZSF.h"
#include <NGExtensions/NGPropertyListParser.h>

@implementation SxStoreInfoFolder

/* subfolders */

- (NSArray *)toManyRelationshipKeys {
  static NSArray *keys = nil;
  if (keys == nil) {
    keys = [[NSArray alloc] initWithObjects:@"Shortcuts", nil];
  }
  return keys;
}

/* lookup */

- (id)shortcutFolder:(NSString *)_key inContext:(id)_ctx {
  // TODO: return a folder object
  /*
    TODO: shortcut folder should implement search:
      SELECT "http://schemas.microsoft.com/mapi/proptag/x7c00001f", 
             "http://schemas.microsoft.com/mapi/proptag/x7c00001f", 
             "http://schemas.microsoft.com/mapi/proptag/x7c020102", 
             "http://schemas.microsoft.com/mapi/proptag/x7d020102", 
             "http://schemas.microsoft.com/mapi/proptag/x7d030003"
      FROM ""
  */
  return nil;
}

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  if ([_key isEqualToString:@"Shortcuts"])
    return [self shortcutFolder:_key inContext:_ctx];
  
  return [super lookupName:_key inContext:_ctx acquire:_flag];
}

/* DAV things */

- (BOOL)davHasSubFolders {
  /* user folders are there to have child folders */
  return YES;
}

- (id)davCreateCollection:(NSString *)_name inContext:(id)_ctx {
  WOResponse *r;
  
  [self logWithFormat:@"shall create collection: '%@'", _name];
  
  r = [(WOContext *)_ctx response];
  [r setStatus:201 /* Created */];
  [r appendContentString:@"collection already exists, faked creation !"];
  return r;
}

/* messages */

- (int)zlGenerationCount {
  /* root folders have no messages and therefore never change */
  return 1;
}

- (id)getIDsAndVersionsAction:(id)_ctx {
  WOResponse *response = [(WOContext *)_ctx response];
  [response setStatus:200]; /* OK */
  [response setHeader:@"text/plain" forKey:@"content-type"];
  return response;
}
- (int)cdoContentCount {
  return 0;
}

/* actions */

@end /* SxStoreInfoFolder */
