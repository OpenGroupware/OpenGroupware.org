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

#include "SkyInvoiceDocument.h"

#import <Foundation/Foundation.h>
#include "SkyInvoiceDataSource.h"
#include <EOControl/EOGlobalID.h>

@implementation SkyInvoiceDocument

- (id)init {
  if ((self = [super init])) {
    self->invoiceNr   = nil;
    self->invoiceDate = nil;
    self->state       = nil;
    self->kind        = nil;
    
    self->netAmount     = nil;
    self->grossAmount   = nil;
    self->paid          = nil;
    self->toPay         = nil;
    self->monitionLevel = nil;

    self->debitorId          = nil;
    self->debitorDescription = nil;

    self->globalID   = nil;
    self->dataSource = nil;
  }
  return self;
}

- (id)initWithValues:(id)_values dataSource:(SkyInvoiceDataSource *)_ds {
  if ((self = [self init])) {
    ASSIGN(self->dataSource, _ds);

    self->globalID = ([_values respondsToSelector:@selector(globalID)])
      ? [_values globalID] : [_values valueForKey:@"globalID"];
    RETAIN(self->globalID);

    self->invoiceNr = [_values valueForKey:@"invoiceNr"];
    RETAIN(self->invoiceNr);

    self->invoiceDate = [_values valueForKey:@"invoiceDate"];
    RETAIN(self->invoiceDate);

    self->state = [_values valueForKey:@"status"];
    RETAIN(self->state);

    self->kind = [_values valueForKey:@"kind"];
    RETAIN(self->kind);

    self->netAmount = [_values valueForKey:@"netAmount"];
    RETAIN(self->netAmount);

    self->grossAmount = [_values valueForKey:@"grossAmount"];
    RETAIN(self->grossAmount);

    self->paid = [_values valueForKey:@"paid"];
    RETAIN(self->paid);

    self->toPay = [_values valueForKey:@"toPay"];
    RETAIN(self->toPay);

    self->monitionLevel = [_values valueForKey:@"monitionLevel"];
    RETAIN(self->monitionLevel);

    self->debitorId = [_values valueForKey:@"debitorId"];
    RETAIN(self->debitorId);

    self->debitorDescription =
      [[_values valueForKey:@"debitor"] valueForKey:@"description"];
    RETAIN(self->debitorDescription);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->invoiceNr);
  RELEASE(self->invoiceDate);
  RELEASE(self->state);
  RELEASE(self->kind);
  
  RELEASE(self->netAmount);
  RELEASE(self->grossAmount);
  RELEASE(self->paid);
  RELEASE(self->monitionLevel);
  RELEASE(self->toPay);

  RELEASE(self->debitorId);
  RELEASE(self->debitorDescription);

  RELEASE(self->globalID);
  RELEASE(self->dataSource);
  [super dealloc];
}
#endif

/* accessors */

- (EOGlobalID *)globalID {
  return self->globalID;
}

- (NSString *)invoiceNr {
  return self->invoiceNr;
}
- (NSCalendarDate *)invoiceDate {
  return self->invoiceDate;
}
- (NSString *)state {
  return self->state;
}
- (NSString *)kind {
  return self->kind;
}

- (NSNumber *)netAmount {
  return self->netAmount;
}
- (NSNumber *)grossAmount {
  return self->grossAmount;
}
- (NSNumber *)paid {
  return self->paid;
}
- (NSNumber *)toPay {
  return self->toPay;
}
- (NSNumber *)monitionLevel {
  return self->monitionLevel;
}

- (NSNumber *)debitorId {
  return self->debitorId;
}
- (NSString *)debitorDescription {
  return self->debitorDescription;
}

// check
- (BOOL)isPrintable { // only printable in created state
  return [self->state isEqualToString:@"00_created"];
}
- (BOOL)isMoveable { // only moveable/editable int created state
  return [self->state isEqualToString:@"00_created"];
}
- (BOOL)isFinishable {
  return ([self->state isEqualToString:@"05_printed"] ||
          [self->state isEqualToString:@"15_monition"] ||
          [self->state isEqualToString:@"16_monition2"] ||
          [self->state isEqualToString:@"17_monition3"]);
}

// comparing
- (BOOL)isEqual:(id)_other {
  if (_other == self)                       return YES;
  if (![_other isKindOfClass:[self class]]) return NO;
  return [[self globalID] isEqual:[_other globalID]];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"status"])
    return [self state];
  return [super valueForKey:_key];
}

@end /* SkyInvoiceDocument */
