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

#include "SkyObjectPropertyManager+Internals.h"
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#if !GNU_RUNTIME
#  include <objc/objc-class.h>
#endif

@implementation NSObject(SkyPropValues)

- (NSString *)_skyPropValueKind {
  return @"valueString";
}

- (void)_buildSkyPropValues:(SkyPropValues *)_vals {
#if DEBUG
  NSLog(@"WARNING(%s): getting sky property of value with class %@",
        __PRETTY_FUNCTION__, NSStringFromClass([self class]));
#endif
  [[self stringValue] _buildSkyPropValues:_vals];
}

@end /* NSObject(SkyPropValues) */

@implementation NSString(SkyPropValues)

static NSStringEncoding BlobPropStringEncoding = NSISOLatin1StringEncoding;
static NSNull *null = nil;

- (NSString *)_skyPropValueKind {
  return @"valueString";
}

- (void)_buildSkyPropValues:(SkyPropValues *)_vals {
  char *str = NULL;
  int  len  = 0;
  
  if (_vals == NULL) return;
  if (null  == nil)  null = [[EONull null] retain];
  
  _vals->pType   = @"valueString";
  
  len = [self cStringLength];
  
  if (len > 255) { /* only first part in valueString, whole string to blob */
    _vals->vString = [self substringToIndex:255];

    // TODO: Unicode
    _vals->vBlob = [self dataUsingEncoding:BlobPropStringEncoding];
    _vals->bSize = [NSNumber numberWithInt:[_vals->vBlob length]];
  }
  else {
    _vals->vString = [[self copy] autorelease];
    
    /* reset BLOB value */
    _vals->vBlob = (id)null;
    _vals->bSize = (id)null;
  }
  
  // Note: those values will be automatically set to null
  if (len > 0) {
    unichar c1;
    
    c1 = [self characterAtIndex:0];
    if (isdigit(c1) || c1 == '.' || c1 == '+' || c1 == '-') {
      int   i = 0;
      float f = 0;
      
      str = malloc(sizeof(unsigned char) * len + 1);
      [self getCString:str];
      str[len] = '\0';
      if (sscanf(str, " %d ", &i) == 1)
        _vals->vInt = [NSNumber numberWithInt:i];
      if (sscanf(str, " %f ", &f) == 1)
        _vals->vFloat = [NSNumber numberWithFloat:f];
    }
    
    // TODO: specify an explicit format string!
    _vals->vDate = [NSCalendarDate dateWithString:self];
  }
}

@end /* NSString(SkyPropValues) */


@implementation NSNumber(SkyPropValues)

- (NSString *)_skyPropValueKind {
  switch (*[self objCType]) {
    case _C_INT:
    case _C_UINT:
    case _C_CHR:
    case _C_UCHR:
    case _C_SHT:
    case _C_USHT:
    case _C_LNG:
    case _C_ULNG:
      return @"valueInt";
      
    case _C_FLT:
    case _C_DBL:
    default:
      return @"valueFloat";
  }
}

- (void)_buildSkyPropValues:(SkyPropValues *)_vals {
  _vals->pType   = [self _skyPropValueKind];
  _vals->vInt    = self;
  _vals->vFloat  = self;
  _vals->vString = [self stringValue];
}

@end /* NSNumber(SkyPropValues) */


@implementation NSCalendarDate(SkyPropValues)

- (NSString *)_skyPropValueKind {
  return @"valueDate";
}

- (void)_buildSkyPropValues:(SkyPropValues *)_vals {
  NSCalendarDate *date;
  NSTimeInterval ti;
    
  date = [[self copy] autorelease];
  [date setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
  ti = [date timeIntervalSince1970];
  
  _vals->pType   = @"valueDate";
  _vals->vDate   = date;
  _vals->vString = [date descriptionWithCalendarFormat:@"%Y%m%d %H:%M:%S %Z"];
  _vals->vFloat  = [NSNumber numberWithDouble:ti];
  _vals->vInt    = [NSNumber numberWithInt:ti];
}

@end /* NSCalendarDate(SkyPropValues) */


@implementation EOKeyGlobalID(SkyPropValues)

- (NSString *)_skyPropValueKind {
  return @"valueOID";
}

- (void)_buildSkyPropValues:(SkyPropValues *)_vals {
  _vals->pType   = @"valueOID";
  _vals->vOID    = [self keyValues][0];
  _vals->vString = [[self entity] name];
  _vals->vInt    = [self keyValues][0];
}

@end /* EOKeyGlobalID(SkyPropValues) */


@implementation NSData(SkyPropValues)

- (NSString *)_skyPropValueKind {
  return @"valueBlob";
}

- (void)_buildSkyPropValues:(SkyPropValues *)_vals {
  NSString *s;
  
  _vals->pType  = @"valueBlob";
  _vals->vBlob  = [[self copy] autorelease];
  _vals->bSize = [NSNumber numberWithInt:[self length]];

  s = [[NSString alloc] initWithData:self
                        encoding:[NSString defaultCStringEncoding]];
  _vals->vString = [[s copy] autorelease];
  [s release]; s = nil;
}

@end /* NSData(SkyPropValues) */


@implementation NSURL(SkyPropValues)

- (void)_buildSkyPropValues:(SkyPropValues *)_vals {
  _vals->pType   = @"url";
  _vals->vString = [self absoluteString];
}

@end /* NSURL(SkyPropValues) */
