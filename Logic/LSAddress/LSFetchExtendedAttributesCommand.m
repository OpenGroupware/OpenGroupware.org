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
// $Id$

#include <LSFoundation/LSDBFetchRelationCommand.h>

@class NSDictionary;

@interface LSFetchExtendedAttributesCommand : LSDBFetchRelationCommand
{
@private
  NSDictionary *defaultAttrs;
}

@end

#import "common.h"

@interface LSFetchExtendedAttributesCommand(PrivateMethodes)
- (void)_fetchDefaultExtendedAttributes:(id)_context;
- (NSMutableDictionary *)_getDefaults:(NSString *)_status with:(id)_context;
@end

@implementation LSFetchExtendedAttributesCommand

- (void)dealloc {
  [self->defaultAttrs release];
  [super dealloc];
}

/* operation */

- (void)_updateAttributeMap:(NSMutableDictionary *)_map {
  NSEnumerator *keyEnum;
  NSArray      *attrKeys;
  NSString     *key;

  keyEnum  = [[_map allKeys] objectEnumerator];
  attrKeys = [self->defaultAttrs allKeys];  // supported keys
  
  // remove non supported keys (with defaults in mind)
  while ((key = [keyEnum nextObject])) {
    if ([attrKeys containsObject:key])
      continue;

    [_map removeObjectForKey:key];
  }
    
  keyEnum  = [attrKeys objectEnumerator];
  attrKeys = [_map allKeys];

  /* add missing keys (with defaults in mind) */
  while ((key = [keyEnum nextObject])) {
    if ([attrKeys containsObject:key])
      continue;

    [_map setObject:[self->defaultAttrs objectForKey:key] forKey:key];
  }
}

- (void)_setExtAttrs:(id)_context  {
  id  account;
  int i, cnt;
  
  account = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
  cnt     = [[self object] count];
  
  for (i = 0; i < cnt; i++) {
    NSMutableDictionary *map;
    id             obj;
    NSArray        *extAttrs;
    NSMutableArray *newAttrs;
    int             j, cnt2;
    
    obj = [[self object] objectAtIndex:i];

    if (![obj isNotNull]) {
#if DEBUG
      [self logWithFormat:
              @"WARNING: got invalid item %@ in set %@",
              obj, [self object]];
#endif
      continue;
    }
    
    extAttrs = [obj valueForKey:@"companyValue"];
    newAttrs = [NSMutableArray arrayWithCapacity:8];
    cnt2     = [extAttrs count];
    map      = [NSMutableDictionary dictionaryWithCapacity:cnt2];
    
    for (j = 0; j < cnt2; j++) {
      id extAttr;
      id uid;
      
      extAttr = [extAttrs objectAtIndex:j];
      uid     = [extAttr valueForKey:@"uid"];

      if (![uid isNotNull] || [uid isEqual:account]) {
        NSString *key;
        id value;
        
        value = [extAttr valueForKey:@"value"];
        key   = [extAttr valueForKey:@"attribute"];

        NSAssert1(key, @"got nil name for ext attribute %@", extAttr);

        if (value != nil)
          [obj takeValue:value forKey:key];

        {
          NSArray *array;
          
          array = [(NSDictionary *)[self->defaultAttrs objectForKey:key]
                                                       objectForKey:@"values"];
          if ([array count] > 0)
            [extAttr takeValue:array forKey:@"values"];
        }        
        [map setObject:extAttr forKey:key];
        [newAttrs addObject:extAttr];
      }
    }
    [self _updateAttributeMap:map];
    [obj takeValue:map       forKey:@"attributeMap"];
    [obj takeValue:newAttrs  forKey:@"companyValue"];
  }
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  if ([[self object] count] > 0) {
    [self _fetchDefaultExtendedAttributes:_context];
    [self _setExtAttrs:_context];
  }
}

- (NSString *)entityName {
  NSString *tmp;

  if ([super entityName] != nil)
    return [super entityName];
  
  [self assert:([[self object] count] > 0) reason:@"missing object"];
  tmp = [[self object] lastObject];

  if ([tmp respondsToSelector:@selector(entityName)])
    tmp = [tmp entityName];
  else
    tmp = [tmp valueForKey:@"entityName"];

  return tmp;
}

- (EOEntity *)destinationEntity {
  return [[self databaseModel] entityNamed:@"CompanyValue"];
}
 
- (BOOL)isToMany {
  return YES; 
}
 
- (NSString *)sourceKey {
  return @"companyId";
}

- (NSString *)destinationKey {
  return @"companyId";
}

/* PrivateMethodes */

- (void)_fetchDefaultExtendedAttributes:(id)_context {
  NSMutableDictionary *attrs = [self _getDefaults:@"Public" with:_context];

  [attrs addEntriesFromDictionary:[self _getDefaults:@"Private" with:_context]];
  ASSIGN(self->defaultAttrs, (NSDictionary *)attrs);
}

// _status should be "Private" or "Public"
- (NSMutableDictionary *)_getDefaults:(NSString *)_status with:(id)_context {
  BOOL           isPrivate;
  id             account;
  NSString       *key;
  NSUserDefaults *defs = nil;
  
  isPrivate = [_status isEqualToString:@"Private"];
  account   = [_context valueForKey:LSAccountKey];
  key       = [NSString stringWithFormat:@"Sky%@Extended", _status];

  if (account)
    defs = LSRunCommandV(_context, @"userdefaults", @"get",
                         @"user", account, nil);
  else
    defs = [NSUserDefaults standardUserDefaults];
  
  key = [key stringByAppendingString:[self entityName]];
  key = [key stringByAppendingString:@"Attributes"];

  //e.g. key = "SkyPublicExtendedPersonAttributes"
  {
    // TODO: this is duplicate code, seen that in another command as well
    NSMutableDictionary *result;
    NSEnumerator        *attrEnum;
    NSMutableDictionary *attr;
    
    result   = [NSMutableDictionary dictionaryWithCapacity:4];
    attrEnum = [[defs arrayForKey:key] objectEnumerator];
    while ((attr = [attrEnum nextObject])) {
      [self assert:([attr objectForKey:@"key"] != nil)
            reason:@"Extended attribute: missing attribute 'key'"];
      if (isPrivate)
        [attr setObject:[NSNumber numberWithBool:YES] forKey:@"isPrivate"];
      [result setObject:attr forKey:[attr objectForKey:@"key"]];
    }
    return result;
  }
}

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"entityName"])
    [self setEntityName:_value];
  else
    [super takeValue:_value forKey:_key];
}

// TODO: no -valueForKey:?

@end /* LSFetchExtendedAttributesCommand */
