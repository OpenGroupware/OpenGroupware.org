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

#include <OGoFoundation/OGoContentPage.h>

@interface SkyMailingListViewer : OGoContentPage
{
  id item;
  id currentBatch;
}
@end

#include "SkyMailingListDataSource.h"
#include "common.h"

@implementation SkyMailingListViewer

- (void)dealloc {
  [self->currentBatch release];
  [self->item         release];
  [super dealloc];
}

/* accessors */

- (SkyMailingListDataSource *)dataSource {
  LSCommandContext *cmdctx;
  
  cmdctx = [[self session] commandContext];
  return [[(SkyMailingListDataSource *)[SkyMailingListDataSource alloc] 
				       initWithContext:(id)cmdctx] 
                                       autorelease];
}

- (void)setItem:(id)_i {
  ASSIGN(self->item, _i);
}
- (id)item {
  return self->item;
}
- (void)setCurrentBatch:(id)_i {
  ASSIGN(self->currentBatch, _i);
}
- (id)currentBatch {
  return self->currentBatch;
}

- (NSUserDefaults *)userDefaults {
  return [[self session] userDefaults];
}

- (void)setSortedKey:(NSString *)_k {
  [[self userDefaults] setObject:_k forKey:@"MailingListManagerSortkey"];
}
- (NSString *)sortedKey {
  return [[self userDefaults] stringForKey:@"MailingListManagerSortkey"];
}

- (void)setIsDescending:(id)_k {
  [[self userDefaults] setObject:_k forKey:@"MailingListManagerDescending"];
}
- (NSNumber *)isDescending {
  return [[self userDefaults] objectForKey:@"MailingListManagerDescending"];
}

/* notifications */

- (void)sleep {
  [self setItem:nil];
  [self setCurrentBatch:nil];
  [super sleep];
}

/* actions */

- (id)new {
  id p;
  
  p = [self pageWithName:@"SkyMailingListEditor"];
  [p takeValue:[NSMutableDictionary dictionaryWithCapacity:3] forKey:@"entry"];
  [p takeValue:[NSNumber numberWithBool:YES]                  forKey:@"isNew"];
  return p;
}

- (id)edit {
  id p;

  p = [self pageWithName:@"SkyMailingListEditor"];
  [p takeValue:[[self->item mutableCopy] autorelease] forKey:@"entry"];
  [p takeValue:[NSNumber numberWithBool:NO]          forKey:@"isNew"];
  return p;
}

@end /* SkyMailingListViewer */
