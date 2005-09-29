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

#include "LSDBObjectGetCommand.h"
#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

@implementation LSDBObjectGetCommand

static BOOL     debugOn = NO;
static NSNumber *yesNum = nil;

+ (int)version {
  return [super version] + 2; /* v3 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {    
    self->operator   = @"OR";
    self->comparator = nil;  // nil | "EQUAL" | "LIKE"
    self->checkAccess = [yesNum retain];
  }
  return self;
}

- (void)dealloc {
  [self->comparator release];
  [self->operator   release];
  [self->qualifier  release];
  [super dealloc]; 
}

/* database commands */

- (NSString *)_primaryKeyQualifierFormat {
  NSMutableString *format;
  EOEntity        *myEntity;
  EOAdaptor       *dbAdaptor;
  NSString        *pKeyName;
  EOAttribute *attr;
  id          formattedAttr;
  id          formattedValue = nil;
  NSNumber    *pKey;
  
  dbAdaptor     = [self databaseAdaptor];
  format        = [NSMutableString stringWithCapacity:128];
  myEntity      = [self entity];
  pKey          = [self primaryKeyValue];
  pKeyName      = [self primaryKeyName];
  attr          = [myEntity attributeNamed:pKeyName];
  formattedAttr = [dbAdaptor formatAttribute:attr];
    
  if (![pKey isNotNull]) {
    [format appendString:@"1=0"];
  }
  else {
    formattedValue = [dbAdaptor formatValue:pKey forAttribute:attr];
    [format appendFormat:@"%@=%@", formattedAttr, formattedValue];
  }
  
  if (debugOn) [self logWithFormat:@"pKey format: %@\n", format];
  return format;
}

- (NSString *)_nonPrimaryKeyQualifierFormat {
  EOAdaptor       *dbAdaptor;
  NSString        *key;
  BOOL            first;
  NSEnumerator    *keyEnum;
  NSMutableString *format;
  EOEntity        *myEntity;
  
  dbAdaptor = [self databaseAdaptor];
  format    = [NSMutableString stringWithCapacity:128];
  myEntity  = [self entity];
  
  if (debugOn) [self logWithFormat:@"calc non pKey format ..."];
  
  first   = YES;
  keyEnum = [self->recordDict keyEnumerator];
  while ((key = [keyEnum nextObject])) {
    EOAttribute *attr;
    id          formattedAttr;
    id          formattedValue = nil;
    id          value          = nil;
      
    if ((attr = [myEntity attributeNamed:key]) == nil) {
      [self errorWithFormat:@"did not find attribute for key %@.", key];
      continue;
    }
    
    value         = [self->recordDict objectForKey:key];
    formattedAttr = [dbAdaptor formatAttribute:attr];
    
    if (!first) {
      [format appendString:@" "];
      [format appendString:[self operator]];
      [format appendString:@" "];
    }
    first = NO;
    
    if ([[attr valueClassName] isEqualToString:@"NSString"]) {
        BOOL            hasPrefix        = NO;
        BOOL            hasSuffix        = YES;
        NSString        *val;
        NSMutableString *formattedString;

        formattedString = [[NSMutableString alloc] init];
        val             = [value lowercaseString];
	
        [formattedString appendString:@"LOWER ("];
        [formattedString appendString:formattedAttr];
        [formattedString appendString:@") "];

        if ([self->comparator isEqualToString:@"LIKE"]) {
          hasPrefix = [val hasPrefix:@"*"];
          hasSuffix = [val hasSuffix:@"*"];

          if (hasPrefix && [val length] == 1)
            val = @"";
          if (hasPrefix && [val length] > 1)
            val = [val substringWithRange:NSMakeRange(1, [val length]-1)];
          if (hasSuffix && [val length] > 1)
            val = [val substringWithRange:NSMakeRange(0, [val length]-1)];
	  
          [formattedString appendString:@"LIKE"];
        }
        else if ([self->comparator isEqualToString:@"EQUAL"]) {
          hasPrefix = NO;
          [formattedString appendString:@"="];
          hasSuffix = NO;
        }
        else
          [formattedString appendString:@"LIKE"];

        [formattedString appendString:@" "];

        if (hasPrefix)
          val = [@"%%" stringByAppendingString:val];
        if (hasSuffix)
          val = [val stringByAppendingString:@"%%"];
        
        formattedValue = [dbAdaptor formatValue:val forAttribute:attr];
        [formattedString appendString:formattedValue];        
        
        [format appendString:formattedString];
        [formattedString release]; formattedString = nil;
    }
    else {
      if (debugOn) 
	[self logWithFormat:@"  add non-string attribute: '%@'", attr];
      
      [format appendString:formattedAttr];
        
      if (![value isNotNull]) {
	[format appendString:@" IS NULL"];
      }
      else {
	formattedValue = [dbAdaptor formatValue:value forAttribute:attr];
	[format appendString:@"="];
	[format appendString:formattedValue];
	
	if (debugOn) {
	  [self logWithFormat:@"    value: %@ (%@): '%@' (%@)", 
		  value, NSStringFromClass([value class]), formattedValue,
		  dbAdaptor];
	}
      }
    }
  }
  if (debugOn) [self logWithFormat:@"non pKey format: '%@'", format];
  return format;
}

- (NSString *)_qualifierFormat {
  return ([self->recordDict objectForKey:[self primaryKeyName]] != nil)
    ? [self _primaryKeyQualifierFormat]
    : [self _nonPrimaryKeyQualifierFormat];
}

- (EOSQLQualifier *)_qualifier {
  NSString *myFormat;
  
  myFormat = [self _qualifierFormat];
  if ([myFormat length] == 0)
    myFormat = @"1=1";
  return [[[EOSQLQualifier alloc]
	    initWithEntity:[self entity]
	    qualifierFormat:myFormat] autorelease];
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSNumber *pkey;
  
  if (self->qualifier != nil)
    [self warnWithFormat:@"qualifier already set ..."];
  
  if ((pkey = [self->recordDict objectForKey:@"oid"]) != nil) {
    [self setPrimaryKeyValue:pkey];
    [self->recordDict removeObjectForKey:@"oid"];
  }
  
  [self->qualifier release]; self->qualifier = nil;
  self->qualifier = [[self _qualifier] retain];
}

- (void)_executeInContext:(id)_context {
  EODatabaseChannel *dbChannel;
  int            cnt     = 0;
  NSMutableArray *result;
  id             obj;

  dbChannel = [self databaseChannel];
  [dbChannel selectObjectsDescribedByQualifier:self->qualifier fetchOrder:nil];
  
  result = [[NSMutableArray alloc] init];
  
  while ((obj = [dbChannel fetchWithZone:NULL])) {
    [result addObject:obj];
    cnt++;
    obj = nil;
  }
  
  if (result != nil) [self setReturnValue:result];
  [result release]; result = nil;
  
  [self assert:!(LSReturnsOneObject && (cnt > 1))
        reason:
	  @"More than one record fetched but returnType was set unique !"];
}

- (void)conjoinWithQualifier:(EOSQLQualifier *)_qualifier {
  [self->qualifier conjoinWithQualifier:_qualifier];
}

- (void)setCheckAccess:(NSNumber *)_n {
  ASSIGNCOPY(self->checkAccess, _n);
}
- (NSNumber *)checkAccess {
  return self->checkAccess;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"operator"])
    [self setOperator:_value];
  else if ([_key isEqualToString:@"comparator"])
    [self setComparator:_value];
  else if ([_key isEqualToString:@"returnType"])
    [self setReturnType:[_value intValue]];
  else if ([_key isEqualToString:@"object"])
    [self setObject:_value];
  else  if ([_key isEqualToString:@"primaryKey"])
    [self setPrimaryKeyValue:_value];
  else if ([_key isEqualToString:@"checkAccess"])
    [self setCheckAccess:_value];
  else {
    if (_value == nil) _value = [NSNull null];
    NSAssert(self->recordDict, @"no record dict available");
    [self->recordDict setObject:_value forKey:_key];
  }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"operator"])
    return [self operator];
  if ([_key isEqualToString:@"comparator"])
    return [self comparator];
  if ([_key isEqualToString:@"returnType"])
    return [NSNumber numberWithInt:[self returnType]];
  if ([_key isEqualToString:@"object"])
    return [self object];
  if ([_key isEqualToString:@"primaryKey"])
    return [self primaryKeyValue];
  if ([_key isEqualToString:@"checkAccess"])
    return [self checkAccess];
  
  return [self->recordDict objectForKey:_key];
}

/* accessors */

- (void)setOperator:(NSString *)_operator {
  if (self->operator == _operator)
    return;
  [self->operator autorelease]; self->operator = nil;
  self->operator = [_operator copy];
}
- (NSString *)operator {
  return self->operator;
}

- (void)setComparator:(NSString *)_comparator {
  if (self->comparator == _comparator)
    return;
  [self->comparator autorelease]; self->comparator = nil;
  self->comparator = [_comparator copy];
}
- (NSString *)comparator {
  return self->comparator;
}

@end /* LSDBObjectGetCommand */
