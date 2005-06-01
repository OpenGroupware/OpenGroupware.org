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

#include "NSObject+ExValues.h"
#include <NGObjWeb/SoWebDAVValue.h>
#include "common.h"

#define XMLTAG_MS_DTTYPE @"{urn:uuid:c2f41010-65b3-11d1-a29f-00aa00c14882/}dt"

#define MS_CAL_FMT       @"%Y-%m-%dT%H:%M:%S.000Z"

static NSDictionary *intTypeAttr    = nil;
static NSDictionary *floatTypeAttr  = nil;
static NSDictionary *dateTypeAttr   = nil;
static NSDictionary *base64TypeAttr = nil;
static NSDictionary *mvStrTypeAttr  = nil;
static NSTimeZone   *gmt            = nil;

@implementation NSObject(ExValues)

- (id)exDavFloatValue {
  float v = [self floatValue];
  
  if (floatTypeAttr == nil) {
    floatTypeAttr = [[NSDictionary alloc] 
		    initWithObjectsAndKeys:@"float",  XMLTAG_MS_DTTYPE, nil];
  }
  
  return [SoWebDAVValue valueForObject:[NSString stringWithFormat:@"%.2f", v]
			attributes:floatTypeAttr];
}
- (id)exDavIntValue {
  static SoWebDAVValue *v0 = nil;
  static SoWebDAVValue *v1 = nil;
  int v = [self intValue];
  
  if (intTypeAttr == nil) {
    intTypeAttr = [[NSDictionary alloc] 
		    initWithObjectsAndKeys:@"int",  XMLTAG_MS_DTTYPE, nil];
  }
  if (v0 == nil)
    v0 = [[SoWebDAVValue valueForObject:@"0" attributes:intTypeAttr] retain];
  if (v1 == nil)
    v1 = [[SoWebDAVValue valueForObject:@"1" attributes:intTypeAttr] retain];
  
  if (v == 0) return v0;
  if (v == 1) return v1;
  return [SoWebDAVValue valueForObject:[NSString stringWithFormat:@"%i", v]
			attributes:intTypeAttr];
}

- (id)exDavStringArrayValue {
  if (mvStrTypeAttr == nil) {
    mvStrTypeAttr = [[NSDictionary alloc] 
                         initWithObjectsAndKeys:@"mv.string", XMLTAG_MS_DTTYPE,
                         nil];
  }
  return [SoWebDAVValue valueForObject:[self stringValue]
			attributes:mvStrTypeAttr];
}

- (id)exDavBase64Value {
  /*
    <d:x0ffb0102 b:dt="bin.base64">AAAAABtV+iCqZhHNm8gAqgAvxFoMAAAAU0hJUkUAL289R2VsZHNwZWljaGVyL291PUZpcnN0IEFkbWluaXN0cmF0aXZlIEdyb3VwL2NuPVJlY2lwaWVudHMvY249aGVsZ2UA</d:x0ffb0102>
  */
  NSString *s;
  
  if (base64TypeAttr == nil) {
    base64TypeAttr = [[NSDictionary alloc] 
		    initWithObjectsAndKeys:@"bin.base64", 
		       XMLTAG_MS_DTTYPE, nil];
  }
  
  s = [self stringValue];
  
  return [SoWebDAVValue valueForObject:[s stringByEncodingBase64]
			attributes:base64TypeAttr];
}

- (NSString *)asExUID {
  NSString *s;
  unsigned char buf[50], *ptr;
  int i, len, slen;
  
  if ((s = [self stringValue]) == nil)
    return nil;
  
  len = 22;
  if ((slen = [s length]) > len) {
    [self logWithFormat:
	    @"%s: too long for use as a UID: '%@' (len=%i)", s, [s length]];
    s = [s substringToIndex:len];
  }
  for (i = 0, ptr = buf; i < len; i++) {
    sprintf((char *)ptr, "%02x", slen <= i ? 0xEA : [s characterAtIndex:i]);
    ptr += 2;
  }
  *ptr = '\0';
  return [NSString stringWithCString:(char *)buf length:(len * 2)];
}

@end /* NSObject(ExValues) */

@implementation NSDate(ExValues)

+ (id)dateWithExDavDateString:(NSString *)_s {
  return [self dateWithExDavString:_s];
}

+ (id)dateWithExDavString:(NSString *)_s {
  /* parses: 1969-12-30T23:00:00Z (len=20) or 19691230T230000Z (len=16) */
  NSString *fmt;
  NSRange r;

  if (gmt == nil)
    gmt = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
  
  if ([_s length] == 0)
    return nil;
  
  r = [_s rangeOfString:@"T"];
  if (r.length == 0) {
    [self logWithFormat:@"cannot parse Ex date string '%@' yet.", _s];
    // TODO: timezone !
    return [NSCalendarDate dateWithString:_s calendarFormat:@"%Y-%m-%d"];
  }
  
  if ([_s length] == 16 && [_s hasSuffix:@"Z"]) {
    int year, month, day, hour, minute, second;
    
    year  = [[_s substringToIndex:4] intValue];
    month = [[_s substringWithRange:NSMakeRange(4, 2)] intValue];
    day   = [[_s substringWithRange:NSMakeRange(6, 2)] intValue];
    // T is 8
    hour   = [[_s substringWithRange:NSMakeRange(9, 2)] intValue];
    minute = [[_s substringWithRange:NSMakeRange(11, 2)] intValue];
    second = [[_s substringWithRange:NSMakeRange(13, 2)] intValue];
    return [[[NSCalendarDate alloc] initWithYear:year month:month day:day
                                    hour:hour minute:minute second:second
                                    timeZone:gmt]
             autorelease];
  }
  else if ([_s length] == 20 && [_s hasSuffix:@"Z"]) {
    int year, month, day, hour, minute, second;
    
    _s = [_s substringToIndex:19];
    _s = [_s stringByAppendingString:@" GMT"];
    fmt = @"%Y-%m-%dT%H:%M:%S %Z";
    
    year  = [[_s substringToIndex:4] intValue];
    month = [[_s substringWithRange:NSMakeRange(5, 2)] intValue];
    day   = [[_s substringWithRange:NSMakeRange(8, 2)] intValue];
    // T is 10
    hour   = [[_s substringWithRange:NSMakeRange(11, 2)] intValue];
    minute = [[_s substringWithRange:NSMakeRange(14, 2)] intValue];
    second = [[_s substringWithRange:NSMakeRange(17, 2)] intValue];
    return [[[NSCalendarDate alloc] initWithYear:year month:month day:day
                                    hour:hour minute:minute second:second
                                    timeZone:gmt]
             autorelease];
  }
  else {
    [self logWithFormat:@"cannot parse Ex date string '%@' yet.", _s];
    // TODO: timezone !
    fmt = @"%Y-%m-%dT%H:%M:%S";
  }
  return [NSCalendarDate dateWithString:_s calendarFormat:fmt];
}

- (id)exDavDateValue {
  NSCalendarDate *cd;
  id v;
  if (dateTypeAttr == nil) {
    dateTypeAttr = [[NSDictionary alloc] 
		    initWithObjectsAndKeys:@"dateTime.tz", 
		     XMLTAG_MS_DTTYPE, nil];
  }
  if (gmt == nil)
    gmt = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
  
#if COCOA_Foundation_LIBRARY || APPLE_Foundation_LIBRARY || \
    NeXT_Foundation_LIBRARY
  cd = [[NSCalendarDate alloc] initWithTimeIntervalSinceReferenceDate:
                                 [self timeIntervalSinceReferenceDate]];
#else
  cd = [[NSCalendarDate alloc] initWithTimeIntervalSince1970:
                                 [self timeIntervalSince1970]];
#endif
  [cd setTimeZone:gmt];
  v = [SoWebDAVValue valueForObject:
                       [cd descriptionWithCalendarFormat:MS_CAL_FMT]
                     attributes:dateTypeAttr];
  [cd release];
  return v;
}

@end /* NSDate(ExValues) */

@implementation NSString(ExValues)

// this is used for Folder-URLs in OL 2000
- (NSString *)asEncodedHomePageURL:(BOOL)_show {
  /*
    002 - 0 - 0 - 0
    001 - 0 - 0 - 0
    002 - 0 - 0 - 0
      0 - 0 - 0 - 0

      0 - 0 - 0 - 0
      0 - 0 - 0 - 0
      0 - 0 - 0 - 0
      0 - 0 - 0 - 0

      0 - 0 - 0 - 0
      0 - 0 - 0 - 0
      , - 0 - 0 - 0
      
      http://..../ (jeweils mit 0 dahinter)
      
      0 - 0 (zwei abschliessende 0-bytes)
  */
  static unsigned char prefix[] = {
    0x02, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x02 /* 03 means show always */, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  };
  static unsigned char comma[] = {
    0x2C /* , */, 0x00, 0x00, 0x00
  };
  static unsigned char suffix[] = { 0x00, 0x00 }; /* terminator */
  NSMutableData *data;
  NSString *url;
  int i, len;
  id enc;
  
  url  = self;
  data = [[NSMutableData alloc] initWithCapacity:128];
  
  prefix[8] = _show ? 0x03 : 0x02; // THREAD: shouldn't change in static ..
  [data appendBytes:prefix length:sizeof(prefix)];
  [data appendBytes:comma  length:sizeof(comma)];
  
  // TODO: allow unicode
  len = [url length];
  for (i = 0; i < len; i++) {
    unichar c = [url characterAtIndex:i];
    char cb[2];
    cb[0] = c;
    cb[1] = 0x00;
    [data appendBytes:cb length:sizeof(cb)];
  }
  
  [data appendBytes:suffix  length:sizeof(suffix)];
  
  /* convert to Base64 ASCII string */
  enc = [data dataByEncodingBase64];
  enc = [[NSString alloc] initWithData:enc encoding:NSASCIIStringEncoding];
  [data release];
  return [enc autorelease];
}

- (NSString *)asEncodedEmailStruct {
  // this is used in AB queries (and in recipients table ?)
  /*
    prefix(binary):
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3
      00000000812B1FA4BEA310199D6E00DD010F540200000110
    content:
      email\0
      SMTP\0
      email\0
  */
  static unsigned char nullByte = 0;
  static unsigned char prefix[] = {
    /* TODO: this is taken from an Exchange email-struct, maybe it contains
             a store id or something */
    0x00, 0x00, 0x00, 0x00, 0x81, 0x2B, 0x1F, 0xA4,
    0xBE, 0xA3, 0x10, 0x19, 0x9D, 0x6E, 0x00, 0xDD,
    0x01, 0x0F, 0x54, 0x02, 0x00, 0x00, 0x01, 0x10
  };
  static unsigned char *SMTP = (unsigned char *)"SMTP";
  NSMutableData *data;
  NSData        *selfdata;
  id enc;
  
  if ((selfdata = [self dataUsingEncoding:NSUTF8StringEncoding]) == nil)
    return nil;
  
  data = [[NSMutableData alloc] initWithCapacity:128];
  [data appendBytes:prefix length:sizeof(prefix)];
  [data appendData:selfdata];
  [data appendBytes:&nullByte length:1];
  [data appendBytes:SMTP length:4];
  [data appendBytes:&nullByte length:1];
  [data appendData:selfdata];
  [data appendBytes:&nullByte length:1];

  /* convert to Base64 ASCII string */
  enc = [data dataByEncodingBase64LineWidth:10000];
  enc = [[NSString alloc] initWithData:enc encoding:NSASCIIStringEncoding];
  [data release];
  return [enc autorelease];
}

- (id)exDavDateValue {
  [self logWithFormat:
          @"WARNING: called -exDavDateValue on NSString "
          @"(probably due to a missing date-key in the cache !)"];
  return self;
}

@end /* NSString(ExValues) */

@implementation NSData(Base64)

// TODO: why is this contained here ? Isn't Base64 part of NGExtensions ??

- (NSData *)dataByEncodingBase64LineWidth:(unsigned int)_width {
  size_t destSize   = ([self length] + 2) / 3 * 4; // 3:4 conversion ratio
  size_t destLength = -1;
  char   *dest;

  if (_width < 1)
    _width = 1;
  
  destSize += destSize / _width + 2; // space for newlines and '\0'
  destSize += 64;

  dest = NGMallocAtomic(destSize + 1);

  NSAssert(destSize > 0, @"invalid buffer size ..");
  NSAssert(dest,         @"invalid buffer ..");

  destLength = NGEncodeBase64([self bytes], [self length],
                              dest, destSize, _width);

  if (destLength >= 0) {
    return [NSData dataWithBytesNoCopy:dest length:destLength];
  }
  else {
    NGFree((void *)dest); dest = NULL;
    return nil;
  }
}

@end /* NSData(Base64) */

@implementation NSTimeZone(ExTimeZoneID)

- (id)exTimeZoneID {
  int offset;
  
  offset = ([self secondsFromGMT] / 60);
  
  switch (offset) { // TODO: is offset really in minutes?
    case    0: return @"0";
    case  -60: return @"3";
    case -120: return @"5";
    case -180: return @"51";
    case -210: return @"25";
    case -240: return @"24"; /* Abu Dhabi */
    case -270: return @"48"; /* Kabul */
    case -300: return @"47"; /* Islamabad */
    case -330: return @"23"; /* Bombay */
    case -360: return @"46"; /* Dhaka */
    case -420: return @"22"; /* Bangkok */
    case -480: return @"45"; /* Beijing */
    case -540: return @"20"; /* Tokyo */
    case -570: return @"44"; /* Darwin */
    case -600: return @"18"; /* Brisbane */
    case -660: return @"41"; /* Solomon Islands */
    case -720: return @"17"; /* Auckland */
    case  60:  return @"29"; /* Azores */
    case 120:  return @"30"; /* Mid Atlantic */
    case 180:  return @"8";  /* Brasilia */
    case 210:  return @"28"; /* Newfoundland */
    case 240:  return @"9";  /* Atlantic time Canada */
    case 300:  return @"10"; /* Eastern */
    case 360:  return @"11"; /* Central time */
    case 420:  return @"12"; /* Mountain time */
    case 480:  return @"13"; /* Pacific time */
    case 540:  return @"14"; /* Alaska time */
    case 600:  return @"15"; /* Hawaii */
    case 660:  return @"16"; /* Midway Island */
    case 720:  return @"39"; /* Eniwetok */
    
    default:   
      return @"52"; // Invalid time zone
  }
}

@end /* NSTimeZone(ExTimeZoneID) */
