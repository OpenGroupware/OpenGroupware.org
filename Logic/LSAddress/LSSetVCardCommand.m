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

extern NSString *LSVUidPrefix;

@implementation LSSetVCardCommand

static NSString *skyrixId = nil;
static Class    NGVCardClass = Nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  skyrixId = [ud stringForKey:@"skyrix_id"];
  skyrixId = [[NSString alloc] initWithFormat:@"skyrix://%@/%@/",
			         [[NSHost currentHost] name], skyrixId];
  
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

- (EOKeyGlobalID *)globalIDFromURL:(NSString *)_url inContext:(id)_ctx {
  EOGlobalID *lgid;
  int pkey;
  
  if (![_url hasPrefix:@"skyrix://"])
    return nil;
  
  if (![_url hasPrefix:skyrixId]) {
    [self logWithFormat:@"record from different OGo installation: %@", _url];
    return nil;
  }
  
  pkey = [[_url lastPathComponent] intValue];
  lgid = [[_ctx typeManager] globalIDForPrimaryKey:
                              [NSNumber numberWithInt:pkey]];
  if (lgid == nil) {
    [self logWithFormat:@"did not find OGo id: %@", _url];
    return nil;
  }
  
  return (EOKeyGlobalID *)lgid;
}

- (EOKeyGlobalID *)globalIDForCard:(id)_card inContext:(id)_ctx {
  EOKeyGlobalID *lgid;
  NSString *tmp;
  
  if ([self->gid isNotNull])
    return self->gid;
  
  // TODO: check UID, check SOURCE in source_url field
  
  if ((tmp = [_card valueForKey:@"uid"]) != nil) {
    if ([tmp hasPrefix:@"skyrix://"]) {
      if ((lgid = [self globalIDFromURL:tmp inContext:_ctx]) != nil)
        return lgid;
    }
  }
  
  if ((tmp = [_card valueForKey:@"source"]) != nil) {
    if ([tmp hasPrefix:@"skyrix://"]) {
      if ((lgid = [self globalIDFromURL:tmp inContext:_ctx]) != nil)
        return lgid;
    }
  }
  
  return nil;
}

- (void)_executeInContext:(id)_context {
  EOKeyGlobalID *lgid;
  id eo;
  
  /* parse vCard object */
  
  if (self->vCardObject == nil) {
    NSArray *a;
    
    [self assert:(NGVCardClass != Nil) reason:@"vCard parsing not available."];
    
    a = [NGVCardClass parseVCardsFromSource:self->vCard];
    [self assert:([a count] < 2)
	  reason:@"More than one vCard in submitted vCard entity!"];
    [self assert:([a count] > 0)
	  reason:@"No vCard in submitted vCard entity!"];
    
    self->vCardObject = [[a objectAtIndex:0] retain];
  }
  
  /* check whether card exists and fetch EO if it does */
  
  if ((lgid = [self globalIDForCard:self->vCardObject inContext:_context])) {
    ASSIGN(self->gid, lgid);
    [self logWithFormat:@"write to GID: %@", lgid];
    
    eo = [_context runCommand:@"object::get-by-global-id",
		   @"gid", self->gid, nil];
  }
  else {
    [self logWithFormat:@"import new vCard .."];
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
  ASSIGN(self->vCardObject, _vc);
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
  ASSIGN(self->gid, _gid);
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
