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

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>

@interface EOGlobalID(OGoSessionLabelPrivates)

- (NSString *)_labelForDocFSGlobalIDInSession:(id)_sn;

@end

@interface EOKeyGlobalID(OGoSessionLabelPrivates)

- (NSString *)_labelForPersonGlobalIDInSession:(id)_sn;
- (NSString *)_labelForEnterpriseGlobalIDInSession:(id)_sn;
- (NSString *)_labelForProjectGlobalIDInSession:(id)_sn;
- (NSString *)_labelForDocGlobalIDInSession:(id)_sn;
- (NSString *)_labelForAppointmentGlobalIDInSession:(id)_sn;
- (NSString *)_labelForTeamGlobalIDInSession:(id)_sn;
- (NSString *)_labelForTaskGlobalIDInSession:(id)_sn;

@end

@implementation EOGlobalID(OGoSessionLabel)

- (NSString *)labelForObjectInSession:(id)_sn {
  static Class SkyFSGlobalIdClass = Nil;

  if (SkyFSGlobalIdClass == Nil)
    SkyFSGlobalIdClass = NSClassFromString(@"SkyFSGlobalID");
    
  if (SkyFSGlobalIdClass) {
    if ([self isKindOfClass:SkyFSGlobalIdClass])
      return [self _labelForDocFSGlobalIDInSession:_sn];
  }
  
  return @"[unknown-globalid]";
}

- (NSString *)_labelForDocGlobalIDInSession:(id)_sn {
  id       object;
  NSString *fn, *ext;
  
  object = [_sn runCommand:@"doc::get", @"gid", self, nil];
  object = ([object count] == 0)
    ? nil
    : [object objectAtIndex:0];
  
  fn  = [object valueForKey:@"title"];
  ext = [object valueForKey:@"fileType"];

  if ([fn length] > 0 && [ext length] > 0)
    return [NSString stringWithFormat:@"%@.%@", fn, ext];
  if ([fn length] == 0)
    return ext;
  if ([ext length] == 0)
    return fn;
  
  return nil;
}

- (NSString *)_labelForDocFSGlobalIDInSession:(id)_sn {
  static Class SkyFSGlobalIdClass = NULL;

  if (!SkyFSGlobalIdClass) {
    SkyFSGlobalIdClass = NSClassFromString(@"SkyFSGlobalID");
  }

  if (SkyFSGlobalIdClass) {
    if ([self isKindOfClass:SkyFSGlobalIdClass])
      return [[(id)self path] lastPathComponent];
  }
  return @"Doc";
}

@end /* EOGlobalID(OGoSessionLabel) */

@implementation EOKeyGlobalID(OGoSessionLabel)

- (NSString *)labelForObjectInSession:(id)_sn {
  NSString *lEntityName, *l;
  
  lEntityName = [self entityName];
  
  if ([lEntityName isEqualToString:@"Person"]) {
    if ((l = [self _labelForPersonGlobalIDInSession:_sn]))
      return l;
  }
  else if ([lEntityName isEqualToString:@"Enterprise"]) {
    if ((l = [self _labelForEnterpriseGlobalIDInSession:_sn]))
      return l;
  }
  else if ([lEntityName isEqualToString:@"Project"]) {
    if ((l = [self _labelForProjectGlobalIDInSession:_sn]))
      return l;
  }
  else if ([lEntityName isEqualToString:@"Doc"]) {
    if ((l = [self _labelForDocGlobalIDInSession:_sn]))
      return l;
  }
  else if ([lEntityName isEqualToString:@"Date"]) {
    if ((l = [self _labelForAppointmentGlobalIDInSession:_sn]))
      return l;
  }
  else if ([lEntityName isEqualToString:@"Team"]) {
    if ((l = [self _labelForTeamGlobalIDInSession:_sn]))
      return l;
  }
  else if ([lEntityName isEqualToString:@"Job"]) {
    if ((l = [self _labelForTaskGlobalIDInSession:_sn]))
      return l;
  }
  
  return [NSString stringWithFormat:@"%@<%@>", 
                     lEntityName, [self keyValues][0]];
}

/* specialized labels */

- (NSString *)_labelForPersonGlobalIDInSession:(id)_sn {
  static NSArray *pTitleAttrs = nil;
  id person;
  
  if (pTitleAttrs == nil) {
    pTitleAttrs =
      [[NSArray alloc] initWithObjects:
                       @"login", @"name", @"firstname", @"isAccount", nil];
  }
  
  person = [_sn runCommand:@"person::get-by-globalid",
                 @"gids", [NSArray arrayWithObject:self],
                 @"attributes", pTitleAttrs,
                 nil];
  person = ([person count] == 0) ? nil : [person objectAtIndex:0];
  
  if ([[person valueForKey:@"isAccount"] boolValue])
    return [person valueForKey:@"login"];
  
  if (person) {
    NSString *n, *fn;
    
    n  = [person valueForKey:@"name"];
    fn = [person valueForKey:@"firstname"];
      
    if ((n != nil) && (fn != nil))
      return [NSString stringWithFormat:@"%@ %@", fn, n];
    if (n != nil)
      return n;
    if (fn != nil)
      return fn;
    
    return [person valueForKey:@"login"];
  }
  return nil;
}

- (NSString *)_fetchLabelWithGIDCommandDomain:(NSString *)_domain
  attributes:(NSArray *)_attrs inSession:(id)_sn
{
  unsigned i, attrCount;
  id       object;
  NSArray  *gids;
  
  gids = [[NSArray alloc] initWithObjects:&self count:1];
  object = [_sn runCommand:
                  [_domain stringByAppendingString:@"::get-by-globalid"],
                  @"gids",       gids,
                  @"attributes", _attrs,
                  nil];
  [gids release]; gids = nil;
  object = ([object count] == 0) ? nil : [object objectAtIndex:0];
  if (object == nil) return nil;
  
  for (i = 0, attrCount = [_attrs count]; i < attrCount; i++) {
    NSString *l;
    
    l = [object valueForKey:[_attrs objectAtIndex:i]];
    if ([l isNotNull]) return l;
  }
  return nil;
}

- (NSString *)_labelForEnterpriseGlobalIDInSession:(id)_sn {
  static NSArray *pTitleAttrs = nil;
  if (pTitleAttrs == nil) {
    pTitleAttrs =
      [[NSArray alloc] initWithObjects:@"number", @"description", nil];
  }
  return [self _fetchLabelWithGIDCommandDomain:@"enterprise"
               attributes:pTitleAttrs inSession:_sn];
}

- (NSString *)_labelForProjectGlobalIDInSession:(id)_sn {
  static NSArray *pTitleAttrs = nil;
  if (pTitleAttrs == nil)
    pTitleAttrs = [[NSArray alloc] initWithObjects:@"name", @"number", nil];
  
  return [self _fetchLabelWithGIDCommandDomain:@"project"
               attributes:pTitleAttrs inSession:_sn];
}

- (NSString *)_labelForAppointmentGlobalIDInSession:(id)_sn {
  static NSArray *pTitleAttrs = nil;
  if (pTitleAttrs == nil)
    pTitleAttrs = [[NSArray alloc] initWithObjects:@"title", nil];
  
  return [self _fetchLabelWithGIDCommandDomain:@"appointment"
               attributes:pTitleAttrs inSession:_sn];
}

- (NSString *)_labelForTeamGlobalIDInSession:(id)_sn {
  static NSArray *pTitleAttrs = nil;
  if (pTitleAttrs == nil)
    pTitleAttrs = [[NSArray alloc] initWithObjects:@"description", nil];
  
  return [self _fetchLabelWithGIDCommandDomain:@"team"
               attributes:pTitleAttrs inSession:_sn];
}

- (NSString *)_labelForTaskGlobalIDInSession:(id)_sn {
  static NSArray *pTitleAttrs = nil;
  if (pTitleAttrs == nil)
    pTitleAttrs = [[NSArray alloc] initWithObjects:@"name", nil];
  
  return [self _fetchLabelWithGIDCommandDomain:@"job"
               attributes:pTitleAttrs inSession:_sn];
}

@end /* EOGlobalID(OGoSessionLabel) */
