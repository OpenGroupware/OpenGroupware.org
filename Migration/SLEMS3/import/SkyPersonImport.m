/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SkyPersonImport.h"
#include "SkyPersonUidHandler.h"
#include "SkyGroupUidHandler.h"
#include "common.h"
#include <LSFoundation/LSFoundation.h>

@implementation SkyPersonImport

- (id)initWithPersonsPath:(NSString *)_path {
  if ((self = [super init])) {
    self->path = [_path copy];
  }
  return self;
}

- (void)dealloc {
  [self->path release];
  [super dealloc];
}

/* operations */

- (NSArray *)objects {
  NSArray        *array;
  NSEnumerator   *enumerator;
  id             obj;
  NSMutableArray *result;

  array  = [self->fm directoryContentsAtPath:self->path];
  result = [NSMutableArray arrayWithCapacity:[array count]];
  enumerator = [array objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    NSMutableDictionary *dict;
    
    dict = [[NSMutableDictionary alloc] initWithContentsOfFile:
                                [path stringByAppendingPathComponent:obj]];
    [dict setObject:[obj stringByDeletingPathExtension] forKey:@"uid"];
    [result addObject:dict];
    [dict release];
  }
  return result;
}

- (Class)uidHandlerClass {
  return [SkyPersonUidHandler class];
}

- (NSNumber *)ownerId {
  return nil;
}

- (BOOL)importObject:(id)_obj withId:(int)_id {
  id ctx;
  id obj;
  id type;
  NSMutableDictionary *addrs; 
  NSMutableDictionary *tels;
 
  static NSArray *AddrType     = nil;
  static NSArray *TelType     = nil;
  static NSArray *AddrAttr = nil;
  
  NSEnumerator *enumerator;

  if (AddrType == nil) {
    AddrType = [[NSArray alloc]
                      initWithObjects:@"location", @"mailing",
                      @"private", nil];
  }
  if (AddrAttr == nil) {
    AddrAttr = [[NSArray alloc]
                      initWithObjects:@"name1", @"name2", @"name3",
                         @"country", @"state", @"street", @"zip", @"city",
                         nil];
  }
  if (TelType == nil) {
    TelType = [[NSArray alloc]
                      initWithObjects:
                         @"01_tel", @"03_tel_funk", @"05_tel_private",
                         @"10_fax",nil];
  }
  
  ctx = [self commandContext];
  
  if (![_obj isKindOfClass:[NSMutableDictionary class]])
    _obj = [[_obj mutableCopy] autorelease];
  
  [_obj setObject:[NSNumber numberWithInt:_id] forKey:@"companyId"];

  {
    NSNumber *owner;

    if ((owner = [self ownerId])) {
      [_obj setObject:owner forKey:@"ownerId"];
      [_obj setObject:[NSNumber numberWithBool:YES] forKey:@"isPrivate"];
    }
  }
  
  obj = [ctx runCommand:@"person::new" arguments:_obj];

  {
    NSEnumerator *enumerator;
    id           o;

    addrs      = [NSMutableDictionary dictionaryWithCapacity:3];
    enumerator = [[obj valueForKey:@"toAddress"] objectEnumerator];
    
    while ((o = [enumerator nextObject]) != nil) {
      [addrs setObject:[o valueForKey:@"addressId"]
             forKey:[o valueForKey:@"type"]];
    }
  }    
  {
    NSEnumerator *enumerator;
    id           o;

    tels       = [NSMutableDictionary dictionaryWithCapacity:3];
    enumerator = [[obj valueForKey:@"toTelephone"] objectEnumerator];

    while ((o = [enumerator nextObject]) != nil) {
      [tels setObject:[o valueForKey:@"telephoneId"]
             forKey:[o valueForKey:@"type"]];
    }
  }    


  
  enumerator = [TelType objectEnumerator];

  while ((type = [enumerator nextObject])) {
    NSMutableDictionary *dict;
    id                  t;

    dict = [NSMutableDictionary dictionaryWithCapacity:8];
    if ((t = [_obj valueForKey:type])) {
      [dict setObject:t forKey:@"number"];
      [dict setObject:type forKey:@"type"];
      [dict setObject:[tels objectForKey:type] forKey:@"telephoneId"];
      [dict setObject:[obj valueForKey:@"companyId"] forKey:@"companyId"];
      [ctx runCommand:@"telephone::set" arguments:dict];
    }
  }
  
  enumerator = [AddrType objectEnumerator];
  while ((type = [enumerator nextObject]) != nil) {
    NSEnumerator        *attrEnum;
    id                  attr;
    NSMutableDictionary *dict;

    attrEnum = [AddrAttr objectEnumerator];
    dict     = [NSMutableDictionary dictionaryWithCapacity:8];
    
    while ((attr = [attrEnum nextObject])) {
      NSString *k, *v;

      k = [NSString stringWithFormat:@"addr_%@_%@",
                    type, attr];
      
      if ((v = [_obj objectForKey:k])) {
        [dict setObject:v forKey:attr];
      }
    }
    if ([dict count]) {
      [dict setObject:type forKey:@"type"];
      [dict setObject:[addrs objectForKey:type] forKey:@"addressId"];
      [dict setObject:[obj valueForKey:@"companyId"] forKey:@"companyId"];
      [ctx runCommand:@"address::set" arguments:dict];
    }
  }

  
  /* handle address */
  /* location/private/mailing */
  
  
  return YES;
}

@end /* SkyPersonImport */
