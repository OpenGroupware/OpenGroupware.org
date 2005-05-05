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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  This command runs queries against the CompanyValue entity and returns an
  array of EOGlobalIDs.
*/

@class NSArray;

@interface LSQueryCompanyValues : LSDBObjectBaseCommand
{
  NSArray  *companies;
  NSArray  *attributes;
}

@end

#import <Foundation/Foundation.h>
#import <GDLAccess/GDLAccess.h>
#import <EOControl/EOControl.h>
#import <LSFoundation/LSFoundation.h>

@implementation LSQueryCompanyValues

// TODO: document and make batchSize configurable
static unsigned int batchSize = 100;
static EONull *null = nil;

+ (void)initialize {
  null = [[EONull null] retain];
}

- (void)dealloc {
  [self->companies  release];
  [self->attributes release];
  [super dealloc];
}

/* qualifier construction */

- (EOSQLQualifier *)_buildAttributesQualifierInContext:(id)_ctx {
  EOEntity        *entity   = nil;
  NSEnumerator    *attrEnum = nil;
  NSString        *attr     = nil;
  NSMutableString *qualStr  = nil;
  EOSQLQualifier  *result   = nil;

  entity  = [[self database] entityNamed:@"CompanyValue"];
  
  if (self->attributes) {
    qualStr = [NSMutableString stringWithCapacity:32];
  
    attrEnum = [self->attributes objectEnumerator];
    [qualStr appendString:@"("];
  
    while ((attr = [attrEnum nextObject])) {
      [qualStr appendString:@"attribute = '"];
      [qualStr appendString:attr];
      [qualStr appendString:@"' OR "];
    }
    if ([qualStr length] > 3) {
      [qualStr deleteCharactersInRange:NSMakeRange([qualStr length]-4, 4)];
      [qualStr appendString:@")"];
    }
    else
      qualStr = (NSMutableString *)@"1=1";
  }
  else
    qualStr = (NSMutableString *)@"1=1";

  result = [[EOSQLQualifier alloc] initWithEntity:entity
                                   qualifierFormat:qualStr];
  [result setUsesDistinct:YES];
  
  return AUTORELEASE(result);
}


- (NSArray *)_buildQualifierInContext:(id)_ctx {
  EOEntity        *entity         = nil;
  NSMutableString *in             = nil;
  NSMutableArray  *ins            = nil;
  NSEnumerator    *enumerator     = nil;
  NSEnumerator    *ine            = nil;
  id              obj             = nil;
  NSMutableArray  *qualifiers     = nil;
  EOSQLQualifier  *attrsQualifier = nil;
  
  entity         = [[self database] entityNamed:@"CompanyValue"];
  attrsQualifier = [self _buildAttributesQualifierInContext:_ctx];

  if (self->companies != nil) {
    unsigned  i;
    
    ins        = [NSMutableArray arrayWithCapacity:16];
    in         = [NSMutableString stringWithCapacity:256];
    enumerator = [self->companies objectEnumerator];

    i = 0;
    while ((obj = [enumerator nextObject])) {
      NSString *pkey;
      
      if (i != 0) [in appendString:@","];

      pkey = [[obj valueForKey:@"companyId"] stringValue];
      
      [in appendString:pkey];
      i++;
      
      if (i == batchSize) {
        NSString *s;
        s = [in copy];
        [ins addObject:s];
        [s release];
        [in setString:@""];
        i = 0;
      }
    }
    if ([in length] > 0)
      [ins addObject:in];
  }

  /* build qualifiers */

  qualifiers = [NSMutableArray arrayWithCapacity:[ins count]];
  ine = ([ins count] > 0)
    ? [ins objectEnumerator]
    : [[NSArray arrayWithObject:null] objectEnumerator];
  
  while ((in = [ine nextObject])) {
    EOSQLQualifier *q = nil;
    
    if (in != (id)null && [in length] > 0) {
      q = [[EOSQLQualifier alloc]
                           initWithEntity:entity
                           qualifierFormat:@"%A IN (%@)", @"companyId", in];
      [q conjoinWithQualifier:attrsQualifier];
      NSLog(@"conjoined qualifier...");
    }
    else {
      NSLog(@"only attributes qualifier...");
      ASSIGN(q, attrsQualifier);
    }
    [q setUsesDistinct:YES];
    [qualifiers addObject:q];
    [q release]; q = nil;
  }
  return qualifiers;
}

/* execute query */

- (void)_executeInContext:(id)_context {
  NSAutoreleasePool *pool       = nil;
  EOSQLQualifier    *q          = nil;
  NSArray           *gids       = nil;
  
  pool = [[NSAutoreleasePool alloc] init];

  /* build qualifiers and fetch gids */
  {
    NSEnumerator *qs;
    NSMutableArray *mgids;
    
    qs = [[self _buildQualifierInContext:_context] objectEnumerator];
    
    mgids = [NSMutableArray arrayWithCapacity:200];
    while ((q = [qs nextObject])) {
      gids = [[self databaseChannel]
                    globalIDsForSQLQualifier:q
                    sortOrderings:nil];
      q = nil;
      [self assert:(gids != nil) reason:@"could not get company value ids"];
      
      [mgids addObjectsFromArray:gids];
    }
    gids = [[mgids copy] autorelease];
  }
  
  [self setReturnValue:gids];
  
  [self debugWithFormat:@"gids count is %d", [[self returnValue] count]];
  
  [pool release];
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"companies"]) {
    ASSIGN(self->companies, _value);
  }
  else if ([_key isEqualToString:@"company"]) {
    NSArray *tmp;
    
    tmp = (_value != nil) 
      ? [[NSArray alloc] initWithObjects:&_value count:1] : nil;
    ASSIGN(self->companies, tmp);
    [tmp release];
  }
  else if ([_key isEqualToString:@"attributes"]) {
    ASSIGN(self->attributes, _value);
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"companies"])
    return self->companies;
  if ([_key isEqualToString:@"attributes"])
    return self->attributes;

  return [super valueForKey:_key];
}

@end /* LSQueryCompanyValues */
