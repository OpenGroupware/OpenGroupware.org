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

#include "SxEvoAptQueryInfo.h"
#include <ZSFrontend/EOQualifier+Additions.h>
#include <EOControl/EOControl.h>
#include "common.h"

@interface SxEvoAptQueryInfo(Privates)
- (void)_loadFetchSpecification:(EOFetchSpecification *)_fs;
- (BOOL)_processQualifier:(EOQualifier *)_q;
@end

/*
    (davIsCollection = 0 AND 
     davContentClass = 'urn:content-classes:appointment' AND 
     endDate > 2003-02-19T23:00:00Z AND startDate < 2003-02-20T23:00:00Z AND 
     (exInstanceType = 0 OR exInstanceType = 1 OR exInstanceType = 2)) 
   
   TODO: (new in Connector 2.0.x)
     SELECT "urn:schemas:calendar:uid", "DAV:getlastmodified"
     FROM ""
     WHERE "DAV:contentclass" = 'urn:content-classes:appointment' AND 
           ("urn:schemas:calendar:instancetype" = 0 OR 
            "urn:schemas:calendar:instancetype" = 1)
*/

@implementation SxEvoAptQueryInfo

static EOQualifier *davIsNoColl = nil;
static EOQualifier *davIsApt    = nil;
static EOQualifier *davIsInstType012 = nil;
static EOQualifier *davIsInstType01  = nil;

+ (void)initialize {
  if (davIsNoColl == nil) {
    davIsNoColl = [[EOQualifier qualifierWithQualifierFormat:
                                  @"davIsCollection = 0"] retain];
  }
  if (davIsApt == nil) {
    davIsApt = [[EOQualifier qualifierWithQualifierFormat:
                  @"davContentClass = 'urn:content-classes:appointment'"]
                 retain];
  }
  if (davIsInstType012 == nil) {
    davIsInstType012 = [[EOQualifier qualifierWithQualifierFormat:
       @"exInstanceType = 0 OR exInstanceType = 1 OR exInstanceType = 2"] 
       retain];
  }
  if (davIsInstType01 == nil) {
    davIsInstType01 = [[EOQualifier qualifierWithQualifierFormat:
       @"exInstanceType = 0 OR exInstanceType = 1"] 
       retain];
  }
}

- (id)initWithFetchSpecification:(EOFetchSpecification *)_fs {
  if (_fs == nil) {
    [self release];
    return nil;
  }
  if ((self = [super init])) {
    [self _loadFetchSpecification:_fs];
  }
  return self;
}

- (void)dealloc {
  [self->startDate release];
  [self->endDate   release];
  [super dealloc];
}

/* results */

- (NSCalendarDate *)startDate {
  return self->startDate;
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

- (BOOL)isInstance01AndAptTypeQuery {
  return ((self->isApt && self->isInst01 && !self->isInst012 &&
           !self->isNoColl) &&
          self->startDate == nil && self->endDate == nil) ? YES : NO;
}

/* disassemble fetch-spec */

- (BOOL)doExplainQueries {
  return YES;
}

- (void)_processRemainingAndQualifiers:(NSMutableArray *)_qs {
  int i, count;
  
  if ((count = [_qs count]) == 0)
    return;

  for (i = 0; i < count; ) {
    EOQualifier *q;
    
    q = [_qs objectAtIndex:i];
    if ([self _processQualifier:q]) {
      [_qs removeObjectAtIndex:i];
      count--;
    }
    else
      /* skip */
      i++;
  }
  if (count == 0)
    return;
  
  // see NOTES
  [self logWithFormat:@"WARNING: remaining[%i]: %@ !", [_qs count], _qs];
}

- (BOOL)_processAndQualifier:(EOAndQualifier *)_q {
  NSMutableArray *qs;

  qs = [[[(EOAndQualifier *)_q qualifiers] mutableCopy] autorelease];
  
  /* the following are ignored */
  self->isNoColl  = [qs removeQualifier:davIsNoColl];
  self->isApt     = [qs removeQualifier:davIsApt];
  self->isInst012 = [qs removeQualifier:davIsInstType012];
  self->isInst01  = [qs removeQualifier:davIsInstType01];
  
  // TODO: check operation
  // Note: this is weird, but correct (end=>start, start=>end) ;-)
  self->startDate = 
    [[qs removeKeyValueQualifierForKey:@"endDate"   operation:NULL] copy];
  self->endDate = 
    [[qs removeKeyValueQualifierForKey:@"startDate" operation:NULL] copy];
  
  [self _processRemainingAndQualifiers:qs];
  return YES;
}

- (BOOL)_processUnknownQualifier:(EOQualifier *)_q {
  [self logWithFormat:@"WARNING: cannot classify Evo qualifier(%@): %@ !", 
          NSStringFromClass([_q class]), _q];
  return NO;
}

- (BOOL)_processQualifier:(EOQualifier *)_q {
  BOOL ok;
  
  if ([_q isKindOfClass:[EOAndQualifier class]]) {
    ok = [self _processAndQualifier:(EOAndQualifier *)_q];
  }
  else if ([_q isEqual:davIsApt]) {
    self->isApt = YES;
    ok = YES;
  }
  else if ([_q isEqual:davIsNoColl]) {
    self->isNoColl = YES;
    ok = YES;
  }
  else if ([_q isEqual:davIsInstType012]) {
    self->isInst012 = YES;
    ok = YES;
  }
  else
    ok = [self _processUnknownQualifier:_q];
  return ok;
}

- (void)_loadFetchSpecification:(EOFetchSpecification *)_fs {
  [self _processQualifier:[_fs qualifier]];
}

@end /* SxEvoAptQueryInfo */
