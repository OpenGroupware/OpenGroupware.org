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

#include "SkyInvoiceCopyPanel.h"
#include "common.h"
#include <Foundation/NSNumberFormatter.h>
#include <OGoFoundation/LSWSession.h>

@interface SkyInvoiceCopyPanel(PrivateMethods)
- (void)setMonths:(NSArray*)_months;
- (NSString*)_labelForKey:(NSString*)_key;
- (void)_computeYears;
- (void)setYears:(NSArray*)_years;
- (void)setSelected:(NSMutableArray *)_selected;
- (void)setCopyTo:(NSString*)_copyTo;
- (BOOL)isInCopyMode;
- (BOOL)isInMoveMode;
@end

@implementation SkyInvoiceCopyPanel

- (id)init {
  if ((self = [super init])) {
    [self setMonths:[[[self session] userDefaults]
                            valueForKey:@"invoice_overview_months"]];
    [self _computeYears];
    [self setCopyTo:
          [[NSCalendarDate date] descriptionWithCalendarFormat:@"%Y-%m-%d"]];
    self->selected = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->invoices);
  RELEASE(self->action);
  RELEASE(self->selected);
  RELEASE(self->months);
  RELEASE(self->selectedMonth);
  RELEASE(self->years);
  RELEASE(self->selectedYear);
  RELEASE(self->item);
  RELEASE(self->copyTo);
  [super dealloc];
}
#endif

- (NSString *)_labelForKey:(NSString*)_key {
  NSString *label = [[self labels] valueForKey:_key];

  return (label != nil) ? label : _key;
}

- (void)_computeYears {
  NSCalendarDate *today;
  NSMutableArray *ys;
  unsigned       i;
  unsigned       thisYear;

  today    = [NSCalendarDate date];
  ys       = [NSMutableArray array];
  thisYear = [[today descriptionWithCalendarFormat:@"%Y"] intValue];

  for (i = 0; i < 3; i++)
    [ys addObject:[NSString stringWithFormat:@"%d",(thisYear+i)]];
  [self setYears:ys];
}

//accessors

- (void)setInvoices:(NSArray *)_invoices {
  ASSIGN(self->invoices, _invoices);
}
- (NSArray *)invoices {
  return self->invoices;
}

- (void)setSelected:(NSMutableArray *)_selected {
  ASSIGN(self->selected, _selected);
}
- (NSMutableArray *)selected {
  if (self->selected == nil) {
    self->selected = [NSMutableArray array];
    RETAIN(self->selected);
  }
  return self->selected;
}

- (void)setMonths:(NSArray *)_months {
  ASSIGN(self->months, _months);
}
- (NSArray*)months {
  return self->months;
}

- (void)setSelectedMonth:(id)_month {
  ASSIGN(self->selectedMonth, _month);
}
- (id)selectedMonth {
  return self->selectedMonth;
}

- (void)setYears:(NSArray *)_years {
  ASSIGN(self->years, _years);
}
- (NSArray *)years {
  return self->years;
}

- (void)setSelectedYear:(NSString *)_year {
  ASSIGN(self->selectedYear, _year);
}
- (NSString *)selectedYear {
  return self->selectedYear;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setAction:(NSString *)_action {
  ASSIGN(self->action, _action);
}
- (NSString *)action {
  return self->action;
}

- (void)setCopyTo:(NSString *)_copyTo {
  ASSIGN(self->copyTo, _copyTo);
}
- (NSString *)copyTo {
  return self->copyTo;
}

- (NSString *)monthName {
  return [self _labelForKey:[self->item valueForKey:@"labelKey"]];
}

- (NSCalendarDate *)date {
  NSString *dateString;

  dateString = [NSString stringWithFormat:
                         @"%@ %@",
                         self->selectedYear,
                         [self->selectedMonth valueForKey:@"number"]];

  return [NSCalendarDate dateWithString:dateString calendarFormat:@"%Y %m"];
}

- (NSCalendarDate *)manualDate {
  return [NSCalendarDate dateWithString:self->copyTo calendarFormat:@"%Y-%m-%d"];
}

- (NSString *)windowTitle {
  if ([self isInCopyMode]) {
    return [[self labels] valueForKey:@"invoiceCopyPanelWindowTitle"];
  }
  if ([self isInMoveMode]) {
    return [[self labels] valueForKey:@"invoiceMovePanelWindowTitle"];
  }
  return @"";
}

- (NSFormatter *)numberFormatter {
  NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
  [format setFormat:@".__0,00"];
  [format setThousandSeparator:@"."];
  [format setDecimalSeparator:@","];
  return AUTORELEASE(format);
}

// conditional

- (BOOL)isInCopyMode {
  return ([self->action isEqualToString:COPY_ACTION]) ? YES : NO;
}

- (BOOL)isInMoveMode {
  return ([self->action isEqualToString:MOVE_ACTION]) ? YES : NO;
}

//actions

- (NSArray *)selectedEOs {
  NSMutableArray *ma = [NSMutableArray array];
  NSEnumerator   *e  = [self->selected objectEnumerator];
  id             one = nil;
  while ((one = [e nextObject]))
    [ma addObject:[one globalID]];

  one = [self runCommand:@"invoice::get-by-globalid",
              @"gids", ma, nil];
  [self runCommand:@"invoice::set-debitor",
        @"relationKey", @"debitor",
        @"objects", one,
        nil];
  
  return one;
}

- (id)copyInvoices {
  NSCalendarDate *copyToD;
  id result;

  copyToD = [self date];
  result  = [self runCommand: @"invoice::copy-invoices",
                  @"invoices", [self selectedEOs],
                  @"copyTo",   copyToD,
                  nil];
  [self postChange:@"LSWNewInvoice" onObject:result];
  [self setSelected:nil];
  [[self navigation] leavePage];
  return nil;
}

- (id)manualCopyInvoices {
  NSCalendarDate *copyToD;
  id result;

  copyToD = [self manualDate];
  
  result =
    [self runCommand: @"invoice::copy-invoices",
          @"invoices", [self selectedEOs],
          @"copyTo", copyToD,
          nil];
  [self postChange:@"LSWNewInvoice" onObject: result];
  [self setSelected:nil];
  [[self navigation] leavePage];
  return nil;
}

- (id)moveInvoices {
  NSCalendarDate *moveTo;
  id result;

  moveTo = [self date];

  result = [self runCommand:@"invoice::move-invoices",
                 @"invoices", [self selectedEOs],
                 @"moveTo",   moveTo,
                 nil];
  [self postChange:@"LSUpdatedInvoice" onObject: result];
  [self setSelected:nil];
  [[self navigation] leavePage];
  return nil;
}

- (id)manualMoveInvoices {
  NSCalendarDate *moveTo;
  id result;

  moveTo = [self manualDate];

  result = [self runCommand:@"invoice::move-invoices",
                 @"invoices", [self selectedEOs],
                 @"moveTo",   moveTo,
                 nil];
  [self postChange:@"LSUpdatedInvoice" onObject:result];
  [self setSelected:nil];
  [[self navigation] leavePage];
  return nil;
}

//key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"invoices"]) {
    [self setInvoices:_value];
    return;
  }
  if ([_key isEqualToString:@"action"]) {
    [self setAction:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"invoices"]) {
    return [self invoices];
  }
  if ([_key isEqualToString:@"action"]) {
    return [self action];
  }
  return [super valueForKey:_key];
}

@end
