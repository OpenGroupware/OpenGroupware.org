/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include "OLDavPropMapper.h"
#include "common.h"

@interface NSObject(Map)
+ (id)map;
@end /*  NSObject(Map) */

@implementation OLDavPropMapper

+ (int)version {
  return 3;
}

- (void)loadSubPropMapperWithDict:(NSDictionary *)_dict {
  Class clazz;
  id    pm;
  
  if ((clazz = NSClassFromString(@"ZLPropMapper")) == nil)
    return;
  
  if ((pm = [[[clazz alloc] initWithDictionary:_dict] autorelease]) == nil) {
    [self logWithFormat:@"could not instantiate prop mapper: %@", clazz];
    return;
  }
  
  self->subPropMapper = [[NSArray alloc] initWithObjects:&pm count:1];
}

- (id)initWithDictionary:(NSDictionary *)_dict {
  NSString *p;
  NSBundle *b;

  b = [NSBundle mainBundle];

  self->map =  (_dict != nil)
    ? [_dict mutableCopy] : [[NSMutableDictionary alloc] init];
  
  if ((p = [b pathForResource:@"E2KAttrMap" ofType:@"plist"]) != nil) {
    NSDictionary *tmp;

    if ((tmp = [NSDictionary dictionaryWithContentsOfFile:p]) != nil)
      [self->map addEntriesFromDictionary:tmp];
    else
      [self logWithFormat:@"Couldn't load DAV map .."];
  }
  
  if ((p = [b pathForResource:@"MAPIPropMap" ofType:@"plist"]) != nil) {
    NSDictionary *tmp;
    
    if ((tmp = [NSDictionary dictionaryWithContentsOfFile:p]) != nil)
      self->mapiTags = [tmp copy];
    else
      [self logWithFormat:@"Couldn't load MAPIPropMap property string "
            @"map .."];
  }

  if ((p = [b pathForResource:@"MAPIPropIDMap" ofType:@"plist"]) != nil) {
    NSDictionary *tmp;
    
    if ((tmp = [NSDictionary dictionaryWithContentsOfFile:p]) != nil)
      self->mapiIDs = [tmp copy];
    else
      [self logWithFormat:@"Couldn't load MAPIPropMap property string "
            @"map .."];
    [self loadSubPropMapperWithDict:_dict];
  }
  return self;
}

- (void)dealloc {
  [self->map      release];
  [self->mapiTags release];
  [self->mapiIDs  release];
  [super dealloc];
}

/* lookup */

- (id)objectForCadaverKey:(NSString *)_key {
  static NSString *p = @"{http://webdav.org/cadaver/custom-properties/}";
  [self logWithFormat:@"query cadaver key: %@", _key];
  if (![p hasPrefix:p]) return p;
  return [p substringFromIndex:[p length]];
}

static NSString *mp1 = @"{http://schemas.microsoft.com/mapi/proptag}x";
static NSString *mp2 = @"{http://schemas.microsoft.com/mapi/proptag/}x";
static NSString *mi  = @"{http://schemas.microsoft.com/mapi/proptag/id/{";
static NSString *mi2 = @"{http://schemas.microsoft.com/mapi/id/{";

- (id)objectForMapiIDKey:(NSString *)_key {
  NSDictionary *guidMap;
  NSRange  r;
  NSString *guid;
  NSString *mk, *tmp;
  NSEnumerator *enumerator;
  id           obj;

  enumerator = [self->subPropMapper objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    id res;
      
    if ((res = [obj objectForMapiIDKey:_key]))
      return res;
  }
  
  if (![_key hasPrefix:mi]) mi = mi2;
    
  /* first extract GUID from namespace */
    
  mk = [_key substringFromIndex:[mi length]];
  r = [mk rangeOfString:@"}"];
  if (r.length == 0) {
    NSLog(@"invalid MAPI-ID key '%@' (namespace not closed)", _key);
    return nil;
  }
  guid = [[mk substringToIndex:r.location] lowercaseString];

  /* lookup map */
    
  if ((guidMap = [self->mapiIDs objectForKey:guid]) == nil) {
    NSLog(@"NEW MAPI-ID namespace '%@'", guid);
    return nil;
  }
    
  mk = [mk substringFromIndex:(r.location + r.length)];
  r = [mk rangeOfString:@"x"];
  
  if (r.length == 0) {
    NSLog(@"invalid MAPI-ID key '%@' (missing hexcode 'x')", _key);
    return nil;
  }
  mk = [mk substringFromIndex:(r.location + r.length)];
  mk = [mk uppercaseString];

  if ([guid isEqualToString:@"00020329-0000-0000-c000-000000000046"] &&
      [mk isEqualToString:@"KEYWORDS"]) {
    return @"Keywords";
  }
  if ((tmp = [guidMap objectForKey:mk]) == nil) {
    NSLog(@"NEW MAPI-ID tag: namespace = '%@', code = '%@'", guid, mk);
    return nil;
  }
  
  return tmp;
}

- (id)objectForKey:(NSString *)_key {
  NSString *mk, *lk;
  id       tmp;
  
  
  {
    NSEnumerator *enumerator;
    id           obj;

    enumerator = [self->subPropMapper objectEnumerator];

    while ((obj = [enumerator nextObject])) {
      id res;
      
      if ((res = [obj objectForKey:_key]))
        return res;
    }
  }

  if ([_key hasPrefix:@"{http://webdav.org/cadaver/custom-properties/}"])
    return [self objectForCadaverKey:_key];

  mk = _key;
  lk = [_key lowercaseString];

  if ([lk hasPrefix:mp1]) {
    mk = [[_key substringFromIndex:[mp1 length]] uppercaseString];
    if ((tmp = [self->mapiTags objectForKey:mk]))
      return tmp;
  }
  else if ([lk hasPrefix:mp2]) {
    mk = [[_key substringFromIndex:[mp2 length]] uppercaseString];
    if ((tmp = [self->mapiTags objectForKey:mk]))
      return tmp;
  }
  else if ([lk hasPrefix:mi] || [lk hasPrefix:mi2]) {
    if ((tmp = [self objectForMapiIDKey:_key]))
      return tmp;
  }
  if ((tmp = [self->map objectForKey:_key]))
    return tmp;
  
  if (mk) {
    [self logWithFormat:@"NEW MAPI TAG: %@", mk];
    tmp = [@"mapi0" stringByAppendingString:mk];
    //    [self->mapiTags setObject:tmp forKey:mk];
    return tmp;
  }
  
  return nil;
}

- (id)valueForKey:(NSString *)_key {
  return [self objectForKey:_key];
}

@end /* OLDavPropMapper */
