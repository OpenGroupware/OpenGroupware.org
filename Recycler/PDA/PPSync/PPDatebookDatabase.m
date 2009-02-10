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

#include "PPDatebookDatabase.h"
#include "PPDatebookPacker.h"
#include "PPSyncContext.h"
#include "PPClassDescription.h"
#include "common.h"

static EONull *null = nil;

@implementation PPDatebookDatabase

+ (void)initialize {
  if (null == nil) null = [EONull null];
}

/* accessors */

- (BOOL)startOfWeek {
  return self->startOfWeek;
}

/* records */

- (EOClassDescription *)classDescriptionNeededForEntityName:(NSString *)_name {
  PPClassDescription *pp;
  
  pp = nil;
  if ([_name isEqualToString:@"DatebookDB"]) {
    pp = [[PPClassDescription alloc] initWithClass:[PPDatebookRecord class]
                                     creator:'date'
                                     type:'DATA'];
  }
  return AUTORELEASE(pp);
}

- (Class)databaseRecordClassForGlobalID:(EOGlobalID *)_oid {
  return [PPDatebookRecord class];
}

/* packing & unpacking */

- (NSData *)packRecord:(id)_eo {
  PPDatebookPacker *packer;
  NSData *data;

  packer = [[PPDatebookPacker alloc] initWithObject:_eo];
  data = [packer packWithDatabase:self];
  RELEASE(packer);
  return data;
}

- (int)decodeAppBlock:(NSData *)_block {
  const unsigned char *record;
  int                 len, i;
  const unsigned char *start;
  
  record = start = [_block bytes];
  len    = [_block length];

  i = [super decodeAppBlock:_block];
  record += i;
  len    -= i;

  if (len < 2)
    return 0;

  self->startOfWeek = get_byte(record);
  
  self->hasAppInfo = YES;
  return i + 2;
}

/* description */

- (NSString *)propertyDescription {
  if (self->hasAppInfo) {
    NSMutableString *s;

    s = [NSMutableString stringWithString:[super propertyDescription]];
    [s appendFormat:@" startOfWeek=%i", self->startOfWeek];
    return s;
  }
  else
    return [super propertyDescription];
}

@end /* PPDatebookDatabase */

@implementation PPDatebookRecord

+ (void)initialize {
  if (null == nil) null = [EONull null];
}

+ (long)palmCreator {
  return 'date';
}
+ (long)palmType {
  return 'DATA';
}

- (id)init {
  if ((self = [super init])) {
    self->cycleDays[0] = NO;
    self->cycleDays[1] = NO;
    self->cycleDays[2] = NO;
    self->cycleDays[3] = NO;
    self->cycleDays[4] = NO;
    self->cycleDays[5] = NO;
    self->cycleDays[6] = NO;
  }
  return self;
}

static NSString *mkString(const char *_cstr) __attribute__((unused));
static NSString *mkString(const char *_cstr) {
  if (_cstr == NULL)
    return nil;
  if (strlen(_cstr) == 0)
    return nil;

  return [[NSString alloc] initWithCString:_cstr];
}

- (void)awakeFromDatabase:(PPRecordDatabase *)_db
  objectID:(EOGlobalID *)_oid
  attributes:(int)_attrs
  category:(int)_category
  data:(NSData *)_data
{
  PPDatebookPacker *packer;

  [super awakeFromDatabase:_db objectID:_oid attributes:_attrs
         category:_category
         data:_data];
  
  if ([self isDeleted])
    return;

  packer = [[PPDatebookPacker alloc] initWithObject:self];
  [packer unpackWithDatabase:_db data:_data];
  RELEASE(packer);
}

- (void)dealloc {
  RELEASE(self->startDate);
  RELEASE(self->endDate);
  RELEASE(self->cycleEndDate);
  RELEASE(self->title);
  RELEASE(self->note);
  RELEASE(self->cycleExceptionsArray);
  [super dealloc];
}

/* accessors */

- (void)setTitle:(NSString *)_title {
  if (_title == (id)null) _title = nil;
  
  if (![_title isEqualToString:self->title]) {
    [self willChange];
    ASSIGN(self->title, _title);
  }
}
- (NSString *)title {
  return self->title;
}

- (void)setNote:(NSString *)_note {
  if (_note == (id)null)   _note = nil;
  if ([_note length] == 0) _note = nil;
  
  if (![_note isEqualToString:self->note]) {
    [self willChange];
    ASSIGN(self->note, _note);
  }
}
- (NSString *)note {
  if (self->note == (id)null)
    return nil;
  if ([self->note length] == 0)
    return nil;
  return self->note;
}

- (void)setIsEvent:(BOOL)_flag {
  _flag = _flag ? YES : NO;
  if (_flag != self->isEvent) {
    [self willChange];
    self->isEvent = _flag;
    //    if (_flag) {
    //      RELEASE(self->startDate); self->startDate = nil;
    //      RELEASE(self->endDate);   self->endDate   = nil;
    //    }
  }
}
- (BOOL)isEvent {
  return self->isEvent;
}

- (void)setStartDate:(NSCalendarDate *)_date {
  if (_date == (id)null) _date = nil;
  
  if (![_date isEqual:self->startDate]) {
    [self willChange];
    ASSIGN(self->startDate, _date);
    //    if (_date) self->isEvent = NO;
  }
}
- (NSCalendarDate *)startDate {
  return self->startDate;
}

- (void)setEndDate:(NSCalendarDate *)_date {
  if (_date == (id)null) _date = nil;
  
  if (![_date isEqual:self->endDate]) {
    [self willChange];
    ASSIGN(self->endDate, _date);
    //    if (_date) self->isEvent = NO;
  }
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

- (void)setHasAlarm:(BOOL)_flag {
  if (self->hasAlarm != _flag) {
    [self willChange];
    self->hasAlarm = _flag;
  }
}
- (BOOL)hasAlarm {
  return self->hasAlarm;
}

- (void)setAlarmAdvance:(NSTimeInterval)_value {
  if (self->alarmAdvance != _value) {
    [self willChange];
    self->alarmAdvance = _value;
  }
}
- (NSTimeInterval)alarmAdvance {
  return self->alarmAdvance;
}

- (void)setAlarmAdvanceUnit:(int)_value {
  if (self->alarmAdvanceUnit != _value) {
    [self willChange];
    self->alarmAdvanceUnit = _value;
  }
}
- (int)alarmAdvanceUnit {
  return self->alarmAdvanceUnit;
}

- (void)setCycleEndDate:(NSCalendarDate *)_date {
  if (_date == (id)null) _date = nil;
  
  if (![_date isEqual:self->cycleEndDate]) {
    [self willChange];
    ASSIGN(self->cycleEndDate, _date);
  }
}
- (NSCalendarDate *)cycleEndDate {
  return self->cycleEndDate;
}

- (void)setCycleDays:(NSArray *)_cycleDays {
  int i;

  if ([_cycleDays count] < 7)
    return;

  if ([_cycleDays isEqual:[self cycleDays]])
    return;

  [self willChange];
  for (i = 0; i < 7; i++)
    self->cycleDays[i] = [[_cycleDays objectAtIndex:i] boolValue];
}
- (NSArray *)cycleDays {
  NSNumber *vals[7];
  vals[0] = [NSNumber numberWithBool:self->cycleDays[0]];
  vals[1] = [NSNumber numberWithBool:self->cycleDays[1]];
  vals[2] = [NSNumber numberWithBool:self->cycleDays[2]];
  vals[3] = [NSNumber numberWithBool:self->cycleDays[3]];
  vals[4] = [NSNumber numberWithBool:self->cycleDays[4]];
  vals[5] = [NSNumber numberWithBool:self->cycleDays[5]];
  vals[6] = [NSNumber numberWithBool:self->cycleDays[6]];
  return [NSArray arrayWithObjects:vals count:7];
}

- (void)setCycleWeekStart:(int)_value {
  if (_value != self->cycleWeekstart) {
    [self willChange];
    self->cycleWeekstart = _value;
  }
}
- (int)cycleWeekStart {
  return self->cycleWeekstart;
}

- (void)setCycleExceptions:(int)_value {
  if (_value != self->cycleExceptions) {
    [self willChange];
    self->cycleExceptions = _value;
  }
}
- (int)cycleExceptions {
  return self->cycleWeekstart;
}

- (void)setCycleExceptionsArray:(NSArray *)_value {
  if (_value == (id)null) _value = nil;
  
  if (![_value isEqual:self->cycleExceptionsArray]) {
    [self willChange];
    ASSIGN(self->cycleExceptionsArray,_value);
    self->cycleExceptions = [_value count];
  }
}
- (NSArray *)cycleExceptionsArray {
  return self->cycleExceptionsArray;
}

- (void)setCycleType:(int)_value {
  if (self->cycleType != _value) {
    [self willChange];
    self->cycleType = _value;
  }
}
- (int)cycleType {
  return self->cycleType;
}

- (void)setCycleEndIsDistantFuture:(BOOL)_flag {
  _flag = _flag ? YES : NO;
  if (self->cycleEndIsDistantFuture != _flag) {
    [self willChange];
    self->cycleEndIsDistantFuture = _flag;
  }
}
- (BOOL)cycleEndIsDistantFuture {
  return self->cycleEndIsDistantFuture;
}

- (void)setCycleFrequency:(int)_value {
  if (self->cycleFrequency != _value) {
    [self willChange];
    self->cycleFrequency = _value;
  }
}
- (int)cycleFrequency {
  return self->cycleFrequency;
}

- (void)setDayCycle:(int)_value {
  if (self->dayCycle != _value) {
    [self willChange];
    self->dayCycle = _value;
  }
}
- (int)dayCycle {
  return self->dayCycle;
}

/* validation */

- (NSException *)validateForSave {
  NSException *e;

  if ((e = [self validateCategory:[self category]]))
    [self setCategory:@""];
  
  if ((e = [super validateForSave]))
    return e;
  
  e = nil;
  NS_DURING {
    //    if (self->isEvent) {
    //      NSAssert(self->startDate != nil, @"event has startdate ..");
    //      NSAssert(self->endDate   != nil, @"event has enddate ..");
    //    }
    //    else {
    //      NSAssert(self->startDate, @"missing startdate ..");
    //      NSAssert(self->endDate,   @"missing enddate ..");
    //    }
  }
  NS_HANDLER {
    e = RETAIN(localException);
  }
  NS_ENDHANDLER;
  
  return AUTORELEASE(e);
}

/* description */

- (NSString *)propertyDescription {
  NSMutableString *s;
  
  s = [NSMutableString stringWithCapacity:100];
  
  [s appendFormat:@" '%@'", [self title]];
  
  if ([self startDate])
    [s appendFormat:@" start=%@", [self startDate]];
  if ([self endDate])
    [s appendFormat:@" end=%@", [self endDate]];
  
  if ([self hasAlarm]) {
    [s appendFormat:@" alarm=%i", (int)[self alarmAdvance]];
    [s appendFormat:@" unit=%i", [self alarmAdvanceUnit]];
  }
  
  [s appendString:[super propertyDescription]];
  
  return s;
}

- (NSArray *)attributeKeys {
  static NSArray *keys = nil;
  if (keys == nil) {
    keys = [[NSArray alloc] initWithObjects:
                              @"isArchived", @"category", @"isPrivate",
                              @"isDirty",
                              @"isEvent", @"startDate", @"endDate",
                              @"hasAlarm", @"alarmAdvance", @"alarmAdvanceUnit",
                              @"cycleType", @"cycleEndIsDistantFuture",
                              @"cycleEndDate", @"cycleFrequency",
                              @"dayCycle", @"cycleDays", @"cycleWeekStart",
                              @"cycleExceptions", @"title", @"note",
                              @"cycleExceptionsArray",
                              nil];
  }
  return keys;
}

@end /* PPDatebookRecord */
