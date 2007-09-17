/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include "LSExtendedSearch.h"
#include "LSGenericSearchRecord.h"
#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

@implementation LSExtendedSearch

static BOOL debugOn = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);

  if ((debugOn = [ud boolForKey:@"LSDebugExtSearch"]))
    NSLog(@"Note: LSDebugExtSearch is enabled for %@",NSStringFromClass(self));
}

- (id)init {
  if ((self = [super init]) != nil) {
    self->operator = @"AND";
  }
  return self;
} 

- (id)initWithSearchRecord:(LSGenericSearchRecord *)_searchRecord
  andRelatedRecords:(NSArray *)_relatedRecords
{
  if ((self = [self init])) {
    self->searchRecord   = [_searchRecord   retain];
    self->relatedRecords = [_relatedRecords retain];
  }
  return self;
}

- (void)dealloc {
  [self->operator       release];
  [self->searchRecord   release];
  [self->relatedRecords release];
  [super dealloc];
}


/* qualifiers */

- (void)_appendKey:(NSString *)key ofRecord:(LSGenericSearchRecord *)_record
  toFormat:(NSMutableString *)format
{
  EOAttribute *attr;
  id          value;
  NSString    *extType;

  attr    = [[_record entity]     attributeNamed:key];
  value   = [[_record searchDict] valueForKey:key];
  extType = [[attr externalType]  lowercaseString];

  NSAssert2(attr, @"missing attribute for key %@ in entity %@",
	    key, [_record entity]);
    
  value = [value stringValue];
  if (![value isNotEmpty])
    return;

  if ([format isNotEmpty]) {
    [format appendString:@" "];
    [format appendString:self->operator];
    [format appendString:@" "];
  }
  
  if ([[attr valueClassName] isEqualToString:@"NSNumber"] ||
      [[attr valueClassName] isEqualToString:@"NSCalendarDate"]) {
    [format appendString:[self _formatForNumberAttribute:attr andValue:value]];
  }
  else if ([[attr valueClassName] isEqualToString:@"NSString"] &&
                 [extType hasSuffix:@"text"]) {
    [format appendString:[self _formatForTextAttribute:attr andValue:value]];
  }
  else if ([[attr valueClassName] isEqualToString:@"NSString"] &&
                 ![extType hasSuffix:@"text"]) {
    [format appendString:[self _formatForStringAttribute:attr andValue:value]];
  }
}

- (NSString *)_qualifierFormatForRecord:(LSGenericSearchRecord *)_record {
  NSMutableString *format;
  NSEnumerator    *keys;
  id              key;

  format = [NSMutableString stringWithCapacity:32];
  keys   = [[_record searchDict] keyEnumerator];
  
  [self setComparator:[_record comparator]];
  
  while ((key = [keys nextObject]) != nil)
    [self _appendKey:key ofRecord:_record toFormat:format];
  
  return format;
}

- (NSString *)_qualifierFormat {
  /* 
     Note: the command still modifies searchRecords between the -init call and
           qualifier generation!
  */
  NSMutableString *format;
  NSEnumerator    *listEnum;
  id              record;
  NSString        *startQ;
  int             startQLength;
  
  startQ       = @"( ";
  startQLength = [startQ length];

  if (debugOn) {
    [self logWithFormat:@"S: %@", self->searchRecord];
    [self logWithFormat:@"R: %@", self->relatedRecords];
  }
  
  format = [NSMutableString stringWithCapacity:128];

  [format appendString:startQ];
  [format appendString:[self _qualifierFormatForRecord:self->searchRecord]];

  listEnum = [self->relatedRecords objectEnumerator];
  while ((record = [listEnum nextObject]) != nil) {
    NSString *tmp;
    
    tmp = [self _qualifierFormatForRecord:record];
    if (![tmp isNotEmpty])
      continue;
    
    if ([format length] > startQLength) {
      [format appendString:@" "];
      [format appendString:self->operator];
      [format appendString:@" "];
    }
    [format appendString:tmp];
  }
  if ([format length] == startQLength)
    return @"1=2";
  
  [format appendString:@" )"];

  if (debugOn)
    [self logWithFormat:@"Q: '%@'", format];
  
  return format;
}

- (EOSQLQualifier *)qualifier {
  EOSQLQualifier *qualifier;
  
  qualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                      qualifierFormat:[self _qualifierFormat]];
  [qualifier setUsesDistinct:YES];

  return [qualifier autorelease];
}

- (EOEntity *)entity {
  return [self->searchRecord entity];
}

/* accessors */

- (void)setOperator:(NSString *)_operator {
  NSMutableString *string;
  
  string = [[NSMutableString alloc] initWithString:@" "];
  [string appendString:_operator];
  [string appendString:@" "];
  if (self->operator != nil) {
    [self->operator release]; 
    self->operator = nil;
  }
  self->operator = string;
}
- (NSString *)operator {
  return self->operator;
}

- (void)setSearchRecord:(LSGenericSearchRecord *)_searchRecord {
  /* Note: do not use -copy, the command still modifies the records */
  ASSIGN(self->searchRecord, _searchRecord);
}
- (LSGenericSearchRecord *)searchRecord {
  return self->searchRecord;
}

- (void)setRelatedRecords:(NSArray *)_relatedRecords {
  ASSIGN(self->relatedRecords, _relatedRecords);
}
- (NSArray *)relatedRecords {
  return self->relatedRecords;
}

@end /* LSExtendedSearch */
