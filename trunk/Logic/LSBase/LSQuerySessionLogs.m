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
  This command runs queries against the SessionLog entity and returns an
  array of EOGlobalIDs.
  
*/

@class NSCalendarDate, NSMutableSet;

@interface LSQuerySessionLogs : LSDBObjectBaseCommand
{
  NSCalendarDate *fromDate;
  id             accounts;
}

@end

#import <Foundation/Foundation.h>
#import <GDLAccess/GDLAccess.h>
#import <EOControl/EOControl.h>
#import <LSFoundation/LSFoundation.h>

@implementation LSQuerySessionLogs

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->fromDate);
  RELEASE(self->accounts);
  [super dealloc];
}
#endif

/* qualifier construction */

- (NSArray *)_buildQualifierInContext:(id)_ctx {
  static id null = nil;
  NSString        *fmtFromDate  = nil;
  EOAdaptor       *adaptor      = nil;
  EOEntity        *entity       = nil;
  EOAttribute     *fmtAttribute = nil;
  EOSQLQualifier  *q            = nil;
  EOSQLQualifier  *tq           = nil;
  NSMutableString *in           = nil;
  NSMutableArray  *ins          = nil;
  NSEnumerator    *enumerator   = nil;
  NSEnumerator    *ine          = nil;
  id              obj           = nil;
  NSMutableArray  *qualifiers   = nil;

  if (null == nil) null = [EONull null];
  
  adaptor      = [self databaseAdaptor];
  entity       = [[self database] entityNamed:@"SessionLog"];
  fmtAttribute = [entity attributeNamed:@"logDate"]; /* can be any date-attr */
  [self assert:(fmtAttribute != nil) reason:@"missing fmt attribute"];
  
  /* format date attributes */
  
  fmtFromDate = self->fromDate
    ? [adaptor formatValue:self->fromDate forAttribute:fmtAttribute]
    : nil;

  if (self->accounts != nil) {
    unsigned i;
    const int batchSize = 200;
    
    ins        = [NSMutableArray arrayWithCapacity:16];
    in         = [NSMutableString stringWithCapacity:256];
    enumerator = [self->accounts objectEnumerator];

    i = 0;
    while ((obj = [enumerator nextObject])) {
      NSString *pkey;
      
      if (i != 0) [in appendString:@","];

      pkey = [[obj keyValues][0] stringValue];
      
      [in appendString:pkey];
      i++;
      
      if (i == batchSize) {
        [ins addObject:AUTORELEASE([in copy])];
        [in setString:@""];
        i = 0;
      }
    }
    if ([in length] > 0) {
      [ins addObject:in];
    }
  }

  /* build qualifiers */

  qualifiers = [NSMutableArray arrayWithCapacity:[ins count]];
  ine = ([ins count] > 0)
    ? [ins objectEnumerator]
    : [[NSArray arrayWithObject:null] objectEnumerator];
  
  while ((in = [ine nextObject])) {
    if (in != null) {
      if ([in length] > 0) {
        tq = [[EOSQLQualifier alloc]
                              initWithEntity:entity
                              qualifierFormat:
                              @"%A IN (%@)", @"accountId",
                              in];
        if (q == nil)
          q = tq;
        else {
          [q conjoinWithQualifier:tq];
          RELEASE(tq); tq = nil;
        }
      }
    }
    else {
        tq = [[EOSQLQualifier alloc]
                              initWithEntity:entity
                              qualifierFormat:@"1=1"];
        if (q == nil)
          q = tq;      
    }
  
    if (fmtFromDate) {
      tq = [[EOSQLQualifier alloc]
                            initWithEntity:entity
                            qualifierFormat:@"%A >= %@",
                                            @"logDate", fmtFromDate];
      if (q == nil) q = tq;
      else {
        [q conjoinWithQualifier:tq];
        RELEASE(tq); tq = nil;
      }
    }
    [q setUsesDistinct:YES];
    
    [qualifiers addObject:q];
    RELEASE(q); q = nil;
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
      [self assert:(gids != nil) reason:@"could not get session log ids"];
      
      [mgids addObjectsFromArray:gids];
    }
    gids = AUTORELEASE([mgids copy]);
  }
  
  [self setReturnValue:gids];

  RELEASE(pool);
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"fromDate"]) 
    ASSIGN(self->fromDate, _value);
  else if ([_key isEqualToString:@"accounts"]) 
    ASSIGN(self->accounts, _value);
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  id v = nil;
  
  if ([_key isEqualToString:@"fromDate"])
    v = self->fromDate;
  else if ([_key isEqualToString:@"accounts"])
    v = self->accounts;
  
  return v;
}

@end /* LSQuerySessionLogs */
