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
//$Id: OGoObjectLink.m 1 2004-08-20 11:17:52Z znek $

#include <LSFoundation/OGoObjectLink.h>
#include "common.h"

@interface OGoObjectLink(ManagerInternals)
- (id)_initWithSource:(EOKeyGlobalID *)_gid target:(id)_target
  type:(NSString *)_type label:(NSString *)_label
  globalID:(EOGlobalID *)_globalID;

- (NSNumber *)_sourceId;
- (NSString *)_sourceType;
- (NSString *)_target;
- (NSNumber *)_targetId;
- (NSString *)_targetType;
- (NSString *)_linkType;
- (NSString *)_label;
- (void)_setGlobalID:(EOGlobalID *)_gid;
@end /* OGoObjectLink(ManagerInternals) */

@implementation OGoObjectLink

static Class EOKeyGlobalIDClass = NULL;
static Class NSStringClass      = NULL;
static Class NSNumberClass      = NULL;

static NSString *ExternalType = @"external";
static NSString *InternalType = @"internal";

+ (void)initialize {
  if (EOKeyGlobalIDClass == Nil) EOKeyGlobalIDClass = [EOKeyGlobalID class];
  if (NSStringClass      == Nil) NSStringClass = [NSString class];
  if (NSNumberClass      == Nil) NSNumberClass = [NSNumber class];
}

+ (id)objectLinkWithAttributes:(NSDictionary *)_attrs {
  EOKeyGlobalID *sgid;
  id            t;
  NSString      *ename;
  NSNumber      *oid;
  OGoObjectLink *ol;

  ename = [_attrs objectForKey:@"sourceType"];
  oid   = [_attrs objectForKey:@"sourceId"];

  if (([ename length] == 0) || ([oid intValue] == 0)) {
    [self logWithFormat:@"couldn`t initialize OGoObjectLink, missing"
          @" source type or source id _attrs %@", _attrs];
    return nil;
  }

  sgid = [EOKeyGlobalID globalIDWithEntityName:ename
                        keys:&oid keyCount:1 zone:NULL];
  
  ename = [_attrs objectForKey:@"targetType"];
  oid   = [_attrs objectForKey:@"targetId"];

  if (([ename length] > 0) && [oid intValue] > 0) {
    t = [EOKeyGlobalID globalIDWithEntityName:ename
                            keys:&oid keyCount:1 zone:NULL];
  }
  else {
    t = [_attrs objectForKey:@"target"];
  }
  oid = [_attrs objectForKey:@"objectLinkId"];
  ol  = [[self alloc] initWithSource:sgid target:t
                      type:[_attrs objectForKey:@"linkType"]
                      label:[_attrs objectForKey:@"label"]];
  
  [ol _setGlobalID:[EOKeyGlobalID globalIDWithEntityName:@"ObjectLink"
                                  keys:&oid keyCount:1 zone:NULL]];
  return ol;
}
 
- (id)initWithSource:(EOKeyGlobalID *)_gid target:(id)_target
  type:(NSString *)_type label:(NSString *)_label
{
  return [self _initWithSource:_gid target:_target type:_type label:_label
               globalID:nil];
}

- (void)dealloc {
  [self->sourceGID release];
  [self->targetGID release];

  [self->sourceType release];
  [self->targetType release];

  [self->target   release];
  [self->label    release];
  [self->linkType release];
  [self->globalID release];

  [super dealloc];
}

/* accessors */

- (EOGlobalID *)sourceGID {
  return self->sourceGID;
}
- (EOGlobalID *)targetGID {
  return self->targetGID;
}

- (unsigned int)sourceId {
  return self->sourceID;
}
- (unsigned int)targetId {
  return self->targetID;
}

- (NSString *)target {
  return self->target;
}
- (NSString *)targetType {
  return self->targetType;
}

- (NSString *)label {
  return self->label;
}

- (NSString *)linkType {
  return self->linkType;
}

- (BOOL)isNew {
  return (self->globalID == nil) ? YES : NO;
}

- (EOGlobalID *)globalID {
  return self->globalID;
}

/* NSCopying */

- (id)copyWithZone:(NSZone *)_zone {
  // OGoObjectLink objects are immutable!
  return [self retain];
}

/* equality */

- (BOOL)isEqualToObjectLink:(OGoObjectLink *)_other {
  if (_other == nil)  return NO;
  if (_other == self) return YES;
  
  // TODO: everything considered?
  
  if (![[self sourceGID] isEqual:[_other sourceGID]])
    return NO;
  if (![[self targetGID] isEqual:[_other targetGID]])
    return NO;
  if (![[self label] isEqual:[_other label]])
    return NO;
  if (![[self linkType] isEqual:[_other linkType]])
    return NO;
  
  return YES;
}
- (BOOL)isEqual:(id)_other {
  if (_other == nil)  return NO;
  if (_other == self) return YES;
  
  if (![_other isKindOfClass:[OGoObjectLink class]])
    return NO;
  
  return [self isEqualToObjectLink:_other];
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"%@: sourceGID=%@ targetGID=%@ type=%@"
                   @" label=%@", [super description],
                   self->sourceGID, self->targetGID, self->linkType,
                   self->label];
}

@end /* OGoObjectLink */

@implementation OGoObjectLink(ManagerInternals)

- (void)_setTarget:(NSString *)_tStr
  targetID:(int)_tid
  type:(NSString *)_type
{
  ASSIGN(self->target,     _tStr);
  ASSIGN(self->targetType, _type);
  self->targetID = _tid;
}

- (id)_initWithSource:(EOKeyGlobalID *)_gid target:(id)_target
  type:(NSString *)_type label:(NSString *)_label
  globalID:(EOGlobalID *)_globalID
{
  if ((self = [super init])) {
    self->sourceGID  = [_gid retain];
    self->sourceID   = 
      _gid ? [[(EOKeyGlobalID *)_gid keyValues][0] intValue] : 0;
    self->sourceType = [[_gid entityName] copy];
    
    self->linkType = [_type copy];
    self->label    = [_label copy];
    self->globalID = [_globalID retain];
    
    if ([_target isKindOfClass:EOKeyGlobalIDClass]) {
      NSNumber *n;

      self->targetGID = [_target retain];
      
      n = _target ? [(EOKeyGlobalID *)_target keyValues][0] : nil;
      
      [self _setTarget:[n stringValue] targetID:[n intValue]
            type:[(EOKeyGlobalID *)_target entityName]];
      
    }
    else if ([_target isKindOfClass:NSStringClass]) {
      [self _setTarget:_target targetID:0 type:ExternalType];
    }
    else if ([_target isKindOfClass:NSNumberClass]) {
      [self _setTarget:[_target stringValue]
            targetID:[_target intValue] type:InternalType];
    }
    else if ([_target respondsToSelector:@selector(globalID)]) {
      EOKeyGlobalID *gid;
      NSNumber      *n;

      gid             = (EOKeyGlobalID *)[_target globalID];
      self->targetGID = [gid retain];
      n               = gid ? [gid keyValues][0] : nil;
      
      [self _setTarget:[n stringValue] targetID:[n intValue]
            type:[(EOKeyGlobalID *)gid entityName]];
    }
    else {
      [self logWithFormat:@"unsupportet target[%@] %@ for _gid %@ "
            @"and label <%@>", NSStringFromClass([_target class]),
            _target, _gid, _label];
      [self release];
      return nil;
    }
 }
  return self;
}

- (void)_setGlobalID:(EOGlobalID *)_gid {
  ASSIGN(self->globalID, _gid);
}
                      
- (NSNumber *)_sourceId {
  return [NSNumber numberWithInt:self->sourceID];
}

- (NSString *)_sourceType {
  return self->sourceType;
}

- (NSString *)_target {
  return self->target;
}

- (NSNumber *)_targetId {
  return [NSNumber numberWithInt:self->targetID];
}

- (NSString *)_targetType {
  return self->targetType;
}

- (NSString *)_linkType {
  return self->linkType;
}

- (NSString *)_label {
  return self->label;
}

@end /* OGoObjectLink(ManagerInternals) */
