/*
  Copyright (C) 2005 SKYRIX Software AG

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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  LSSetVCardCommand (company::set-vcard)
  
  NOTE: this requires SOPE 4.5 for the vCard parser!
  
  This commands parses and inserts a vCard into the contact database. You can
  (optionally) supply a gid to store the vCard under and an entity to be used
  for new vCards.
  If none of those is given the 'source_url' and heuristics are used to find
  a proper record.
*/

@class NSString, EOKeyGlobalID;

@interface LSSetVCardCommand : LSDBObjectBaseCommand
{
  NSString      *vCard;
  id            vCardObject;
  EOKeyGlobalID *gid;
  NSString      *newEntityName;
}

@end

#include "common.h"

// we need to cheat a bit to support both, SOPE 4.4 and SOPE 4.5

@interface NSObject(NGVCard)
+ (NSArray *)parseVCardsFromSource:(id)_src;
@end

@implementation LSSetVCardCommand

static Class NGVCardClass = Nil;

+ (void)initialize {
  if ((NGVCardClass = NSClassFromString(@"NGVCard")) == Nil)
    NSLog(@"Note: NGVCard class not available, vCard parsing not available.");
}

- (void)dealloc {
  [self->vCardObject   release];
  [self->vCard         release];
  [self->gid           release];
  [self->newEntityName release];
  [super dealloc];
}

/* prepare */

- (void)_prepareForExecutionInContext:(id)_context {
  [self assert:([self->vCard isNotNull] || [self->vCardObject isNotNull])
	reason:@"missing either vCard or vCardObject parameter!"];
  if ([self->vCard isNotNull])
    [self assert:([self->vCard length] > 0) reason:@"vCard has no content!"];
}

/* running the command */

- (void)_executeInContext:(id)_context {
  /* parse vCard object */
  
  if (self->vCardObject == nil) {
    NSArray *a;
    
    [self assert:(NGVCardClass != Nil) reason:@"vCard parsing not available."];
    
    a = [NGVCardClass parseVCardsFromSource:self->vCard];
    [self assert:([a count] < 2)
	  reason:@"More than one vCard in submitted vCard entity!"];
    [self assert:([a count] > 0)
	  reason:@"No vCard in submitted vCard entity!"];
  }
}

/* accessors */

- (void)setVCard:(NSString *)_vc {
  ASSIGNCOPY(self->vCard, _vc);
}
- (NSString *)vCard {
  return self->vCard;
}

- (void)setVCardObject:(id)_vc {
  ASSIGNCOPY(self->vCardObject, _vc);
}
- (id)vCardObject {
  return self->vCardObject;
}

- (void)setNewEntityName:(NSString *)_vc {
  ASSIGNCOPY(self->newEntityName, _vc);
}
- (NSString *)newEntityName {
  return self->newEntityName;
}

- (void)setGlobalID:(EOKeyGlobalID *)_gid {
  ASSIGNCOPY(self->gid, _gid);
}
- (EOKeyGlobalID *)globalID {
  return self->gid;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"vCard"])
    [self setVCard:_value];
  else if ([_key isEqualToString:@"vCardObject"])
    [self setVCardObject:_value];
  else if ([_key isEqualToString:@"gid"])
    [self setGlobalID:_value];
  else if ([_key isEqualToString:@"newEntityName"])
    [self setNewEntityName:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"vCard"])
    return [self vCard];
  else if ([_key isEqualToString:@"vCardObject"])
    return [self vCardObject];
  if ([_key isEqualToString:@"gid"])
    return [self globalID];
  if ([_key isEqualToString:@"newEntityName"])
    return [self newEntityName];
  
  return [super valueForKey:_key];
}

@end /* LSSetVCardCommand */
