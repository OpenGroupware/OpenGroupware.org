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

#include <OGoFoundation/OGoComponent.h>

@class NSMutableDictionary;

@interface SkyPalmRecordList : OGoComponent
{
  NSString            *database;
  NSMutableDictionary *lists;
}
@end /* SkyPalmRecordList */

#include "common.h"
#include <NGExtensions/NGBundleManager.h>
#include <EOControl/EOQualifier.h>

@implementation SkyPalmRecordList

- (id)init {
  id p;

  if ((p = [self persistentInstance])) {
    RELEASE(self);
    return RETAIN(p);
  }
  
  if ((self = [super init])) {
    [self registerAsPersistentInstance];
    self->lists    = [[NSMutableDictionary alloc] initWithCapacity:8];
    self->database = nil;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->database);
  RELEASE(self->lists);
  [super dealloc];
}

// the palm database
- (void)setDatabase:(NSString *)_db {
  ASSIGN(self->database,_db);
}
- (NSString *)database {
  return self->database;
}

- (id)listComponent {
  id c;
  
  if ([self->database length] == 0) {
    NSLog(@"WARNING[%s]: no palm db set", __PRETTY_FUNCTION__);
    return nil;
  }
  if ((c = [self->lists objectForKey:self->database]) != nil)
    return c;

  {
    NGBundleManager *bm;
    EOQualifier     *q;
    NSBundle        *bundle;

    bm = [NGBundleManager defaultBundleManager];
    q  = [EOQualifier qualifierWithQualifierFormat:
                      @"palmDb=%@", self->database];
    bundle = [bm bundleProvidingResourceOfType:@"SkyPalmEntryLists"
                 matchingQualifier:q];
    if (bundle != nil) {
      if (![bundle load]) {
        NSLog(@"%s: failed to load bundle: %@", __PRETTY_FUNCTION__, bundle);
        return nil;
      }
      {
        id resources, resource, cname;
        resources = [bundle providedResourcesOfType:@"SkyPalmEntryLists"];
        resources = [resources filteredArrayUsingQualifier:q];
        resource  = [resources lastObject];

        cname = [resource valueForKey:@"entryList"];
        if (![cname length]) {
          NSLog(@"%s invalid entryList for palmDb: %@",
                __PRETTY_FUNCTION__, self->database);
          return nil;
        }
        if ((c = [self pageWithName:cname])) {
          [self->lists setObject:c forKey:self->database];
          return c;
        }
      }
      NSLog(@"WARNING[%s]: could not load entryList for Palm DB %@",
            __PRETTY_FUNCTION__, self->database);
    }
  }
  return nil;
}

@end /* SkyPalmRecordList */
