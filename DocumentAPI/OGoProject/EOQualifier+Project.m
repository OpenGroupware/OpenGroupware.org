/*
  Copyright (C) 2004 SKYRIX Software AG

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

#include "EOQualifier+Project.h"
#include "common.h"

@implementation EOQualifier(Project)

- (BOOL)isProjectCheckKindQualifier {
  return NO;
}

- (NSArray *)flattenQualifierForProjectKindsCheck {
  /* does not check qualifiers at deeper levels currently */
  
  if ([self respondsToSelector:@selector(qualifiers)])
    return [(EOAndQualifier *)self qualifiers];
  
  if ([self respondsToSelector:@selector(qualifier)]) {
    return [[(EONotQualifier *)self qualifier] 
             flattenQualifierForProjectKindsCheck];
  }
  
  return self != nil? [NSArray arrayWithObject:self] : nil;
}

- (NSArray *)reduceProjectKindRestrictionByUsedNames:(NSArray *)_hiddenKinds {
  /* extracts a set of project kinds (strings) from a qualifier */
  NSArray             *quals;
  NSMutableArray      *all;
  NSEnumerator        *e;
  EOKeyValueQualifier *one;
  
  all = [[_hiddenKinds mutableCopy] autorelease];
  
  quals = [self flattenQualifierForProjectKindsCheck];
  e     = [quals objectEnumerator];
  while ((one = [e nextObject]) != nil) {
    id val;
    
    if (![one isProjectCheckKindQualifier])
      continue;
    
    val = [one value];
    if ([all containsObject:val])
      [all removeObject:val];
  }

  return all;
}

/* factory */

+ (EOQualifier *)qualifierForProjectType:(NSString *)_type {
  if (_type == nil)
    return nil;
  
  if ([_type isEqualToString:@"archived"]) {
    static EOQualifier *archivedQualifier = nil;
    if (archivedQualifier == nil) {
      archivedQualifier = 
        [[EOQualifier qualifierWithQualifierFormat:@"type='archived'"] retain];
    }
    return archivedQualifier;
  }
  if ([_type isEqualToString:@"common"]) {
    static EOQualifier *commonQualifier = nil;
    if (commonQualifier == nil) {
      commonQualifier = 
        [[EOQualifier qualifierWithQualifierFormat:@"type='common'"] retain];
    }
    return commonQualifier;
  }
  if ([_type isEqualToString:@"private"]) {
    static EOQualifier *privateQualifier = nil;
    if (privateQualifier == nil) {
      privateQualifier = 
        [[EOQualifier qualifierWithQualifierFormat:@"type='private'"] retain];
    }
    return privateQualifier;
  }
  
  return [EOQualifier qualifierWithQualifierFormat:@"type = %@", _type];
}

+ (EOQualifier *)qualifierForProjectIDs:(NSArray *)_projectIds {
  /* Note: IDs are allowed to be either NSNumber *or* NSString! */
  NSMutableArray *qualArray = nil;
  EOQualifier  *result;
  unsigned int i, cnt;
  
  cnt       = [_projectIds count];
  qualArray = [[NSMutableArray alloc] initWithCapacity:cnt];

  for (i = 0; i < cnt; i++) {
    NSNumber    *projectId;
    EOQualifier *qual;
    NSString    *qs;
    
    projectId = [_projectIds objectAtIndex:i];
    // TODO: support EOKeyGlobalID's?
    qs = [projectId stringValue];
    
    qs = [@"projectId = " stringByAppendingString:qs];
    qual = [EOQualifier qualifierWithQualifierFormat:qs];
    [qualArray addObject:qual];
  }
  result = [[EOOrQualifier alloc] initWithQualifierArray:qualArray];
  [qualArray release];
  
  return [result autorelease];
}

@end /* EOQualifier(Project) */


@implementation EOKeyValueQualifier(Project)

- (BOOL)isProjectCheckKindQualifier {
  if (![[self key] isEqualToString:@"kind"]) 
    return NO;
  
  // TODO: replace with proper sel_eq! (GNU/Apple runtime)
  if (![NSStringFromSelector([self selector]) isEqualToString:@"isEqualTo:"])
    return NO;
  
  return YES;
}

@end /* EOKeyValueQualifier(Project) */
