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

#import "common.h"
#import "LSGetInvoiceCommand.h"
#include <math.h>
#include <Foundation/NSNumberFormatter.h>

@implementation LSGetInvoiceCommand

- (id)initForOperation:(NSString*)_operation
              inDomain:(NSString*)_domain
{
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->from = nil;
    self->to   = nil;
    self->states = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->from);
  RELEASE(self->to);
  RELEASE(self->states);
  [super dealloc];
}
#endif

- (void)_prepareForExecutionInContext:(id)_context {
  id           account;
  NSEnumerator *teamEnum;
  id           team;
  BOOL         access = NO;
  
  account = [_context valueForKey:LSAccountKey];
  teamEnum =
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", account,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];
  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];
  [super _prepareForExecutionInContext:_context];
}

- (EOSQLQualifier *)_stateQualifier {
  EOAdaptor       *adaptor          = [self databaseAdaptor];
  EOEntity        *myEntity         = [self entity];
  EOAttribute     *invoiceStateAttr =
    [myEntity attributeNamed:@"status"];
  EOSQLQualifier *qual     = nil;
  EOSQLQualifier *tmp;
  NSEnumerator   *e        = [self->states objectEnumerator];
  id             state     = nil;

  while ((state = [e nextObject])) {
    id formattedState = nil;

    tmp = [EOSQLQualifier allocWithZone:[self zone]];
    formattedState = [adaptor formatValue:state forAttribute:invoiceStateAttr];

    tmp = [tmp initWithEntity:myEntity
               qualifierFormat:
               @"%A = %@",
               @"status", formattedState];
    AUTORELEASE(tmp);

    if (qual == nil)
      qual = tmp;
    else
      [qual disjoinWithQualifier:tmp];
  }

  return qual;
}

- (EOSQLQualifier *)_qualifier {
  EOAdaptor       *adaptor = [self databaseAdaptor];
  EOEntity        *myEntity = [self entity];
  EOAttribute     *invoiceDateAttr =
    [myEntity attributeNamed:@"invoiceDate"];
  EOSQLQualifier *qual;

  id formattedFrom = nil;
  id formattedTo = nil;

  if ((self->from == nil) || (self->to == nil)) {
    return [super _qualifier];
  }

  qual = [EOSQLQualifier allocWithZone:[self zone]];

  formattedFrom =
    [adaptor formatValue: self->from forAttribute:invoiceDateAttr];
  formattedTo =
    [adaptor formatValue: self->to forAttribute:invoiceDateAttr];

  qual = [qual initWithEntity: myEntity
               qualifierFormat:
               @"(%A >= %@ AND %A <= %@)",
               @"invoiceDate", formattedFrom,
               @"invoiceDate", formattedTo];
  if (self->states != nil)
    [qual conjoinWithQualifier:[self _stateQualifier]];
  return AUTORELEASE(qual);
}

- (NSString*)entityName {
  return @"Invoice";
}

//accessors

- (void)setFrom:(NSCalendarDate*)_from {
  ASSIGN(self->from,_from);
}
- (NSCalendarDate*)from {
  return self->from;
}

- (void)setTo:(NSCalendarDate*)_to {
  ASSIGN(self->to,_to);
}
- (NSCalendarDate*)to {
  return self->to;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"from"]) {
    [self setFrom:_value];
    return;
  }
  if ([_key isEqualToString:@"to"]) {
    [self setTo:_value];
    return;
  }
  if ([_key isEqualToString:@"states"]) {
    ASSIGN(self->states,_value);
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"from"])
    return [self from];
  if ([_key isEqualToString:@"to"])
    return [self to];
  if ([_key isEqualToString:@"states"])
    return self->states;
  return [super valueForKey:_key];
}

@end
