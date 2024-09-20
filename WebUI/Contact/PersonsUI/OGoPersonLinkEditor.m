/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include <OGoFoundation/SkyEditorPage.h>

@class NSString, NSArray;
@class EOKeyGlobalID;

@interface OGoPersonLinkEditor : SkyEditorPage
{
  NSString      *linkType;
  EOKeyGlobalID *sourceGlobalID;
  
  NSArray    *participants;
  NSArray    *selectedParticipants;
}

@end

#include "common.h"
#include <LSFoundation/OGoObjectLinkManager.h>
#include <LSFoundation/OGoObjectLink.h>
#include <EOControl/EOKeyGlobalID.h>

@implementation OGoPersonLinkEditor

- (void)dealloc {
  [self->selectedParticipants release];
  [self->participants   release];
  [self->linkType       release];
  [self->sourceGlobalID release];
  [super dealloc];
}

/* accessors */

- (void)setLinkType:(NSString *)_value {
  ASSIGNCOPY(self->linkType, _value);
}
- (NSString *)linkType {
  return self->linkType;
}

- (void)setSourceGlobalID:(EOKeyGlobalID *)_gid {
  ASSIGN(self->sourceGlobalID, _gid);
}
- (EOKeyGlobalID *)sourceGlobalID {
  return self->sourceGlobalID;
}

- (void)setParticipants:(NSArray *)_array {
  ASSIGN(self->participants, _array);
}
- (NSArray *)participants {
  return self->participants;
}

- (void)setSelectedParticipants:(NSArray *)_array {
  ASSIGN(self->selectedParticipants, _array);
}
- (NSArray *)selectedParticipants {
  return self->selectedParticipants;
}

- (NSString *)objectLabel {
  return [self linkType];
}

/* creating links */

- (void)setLinkCreationError:(NSException *)error {
  NSString *s;
  
  s = [@"Link creation failed: " stringByAppendingString:[error reason]];
  [self setErrorString:s];
}

- (BOOL)createLinkForParticipant:(id)obj {
  OGoObjectLinkManager *linkManager;
  EOGlobalID    *targetID;
  OGoObjectLink *link;
  NSString      *label;
  NSException   *error;
  
  linkManager = [[[self session] commandContext] linkManager];

  targetID = [obj valueForKey:@"globalID"];
  label    = [[self session] labelForObject:targetID];
  
  link = [[[OGoObjectLink alloc] initWithSource:[self sourceGlobalID]
				 target:targetID
				 type:[self linkType]
				 label:label] autorelease];
  [self debugWithFormat:@"create link: %@", link];
  
  if ((error = [linkManager createLink:link]) != nil) {
    [self logWithFormat:@"ERROR: could not create link (type=%@): %@", 
	    linkType, error];
    
    [self setLinkCreationError:error];
    [[[self session] commandContext] rollback];
    return NO;
  }
    
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:@"OGoLinkWasCreated" object:link];
  return YES;
}

/* actions */

- (id)save {
  LSCommandContext *cmdctx;
  NSEnumerator     *e;
  id obj;
  
  if ([self->selectedParticipants count] == 0)
    /* nothing selected */
    return [[self navigation] leavePage];
  
  cmdctx = [[self session] commandContext];

  /* walk over each record and create a link ... */
  
  e = [self->selectedParticipants objectEnumerator];
  while ((obj = [e nextObject]) != nil) {
    if (![self createLinkForParticipant:obj])
      return nil;
  }
  
  if ([cmdctx isTransactionInProgress] && ![cmdctx commit]) {
    [self setErrorString:@"could not commit transaction!"];
    [cmdctx rollback];
    return nil;
  }
  
  return [[self navigation] leavePage];
}

@end /* OGoPersonLinkEditor */
