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

#include "ExStoreEntryID.h"
#include "common.h"

#define XMLTAG_MS_DTTYPE @"{urn:uuid:c2f41010-65b3-11d1-a29f-00aa00c14882/}dt"

/*
  used for evo
  
    An opaque BLOB to identify a store (basically the 'skyrix_id' default) ?
    
<d:x0ffb0102 b:dt="bin.base64">AAAAABtV+iCqZhHNm8gAqgAvxFoMAAAAU0hJUkUAL289R2VsZHNwZWljaGVyL291PUZpcnN0IEFkbWluaXN0cmF0aXZlIEdyb3VwL2NuPVJlY2lwaWVudHMvY249aGVsZ2UA</d:x0ffb0102>

    Ex2003:
00000000  00 00 00 00 1b 55 fa 20  aa 66 11 cd 9b c8 00 aa  |.....Uú ªf.Í.È.ª|
00000010  00 2f c4 5a 0c 00 00 00  53 48 49 52 45 00 2f 6f  |./ÄZ....SHIRE./o|
00000020  3d 47 65 6c 64 73 70 65  69 63 68 65 72 2f 6f 75  |=Geldspeicher/ou|
00000030  3d 46 69 72 73 74 20 41  64 6d 69 6e 69 73 74 72  |=First Administr|
00000040  61 74 69 76 65 20 47 72  6f 75 70 2f 63 6e 3d 52  |ative Group/cn=R|
00000050  65 63 69 70 69 65 6e 74  73 2f 63 6e 3d 68 65 6c  |ecipients/cn=hel|
00000060  67 65 00                                          |ge.|
00000063

   00 00 00 00  1b 55 fa 20
   aa 66 11 cd  9b c8 00 aa
   00 2f c4 5a  0c 00 00 00
*/

@implementation ExStoreEntryID

static NSDictionary *base64TypeAttr = nil;

- (id)initWithDN:(NSString *)_dn hostName:(NSString *)_host {
  if ([_dn length] == 0) {
    /* invalid DN ... */
    [self release];
    return nil;
  }
  if ((self = [super init])) {
    self->dn       = [_dn copy];
    self->hostName = [[_host uppercaseString] copy];
    
    if (self->hostName == nil) { /* use localhost name */
      static NSHost *chost = nil;
      NSString *s;
      NSRange  r;
      
      if (chost == nil) chost = [[NSHost currentHost] retain];
      s = [chost name];
      r = [s rangeOfString:@"."];
      if (r.length > 0) s = [s substringToIndex:r.location];
      self->hostName = [[s uppercaseString] copy];
    }
  }
  return self;
}
- (id)initWithDN:(NSString *)_dn {
  return [self initWithDN:_dn hostName:nil];
}
- (id)init {
  return [self initWithDN:nil];
}

- (void)dealloc {
  [self->dn       release];
  [self->hostName release];
  [super dealloc];
}

/* accessors */

- (NSString *)dn {
  return self->dn;
}
- (NSString *)hostName {
  return self->hostName;
}

/* value generation */

- (NSData *)valueAsData {
  /*
    00  00 00 00 00 1b 55 fa 20  aa 66 11 cd 9b c8 00 aa  |.....Uú ªf.Í.È.ª|
    10  00 2f c4 5a 0c 00 00 00  53 48 49 52 45 00 2f 6f  |./ÄZ....SHIRE./o|
    20  3d 47 65 6c 64 73 70 65  69 63 68 65 72 2f 6f 75  |=Geldspeicher/ou|
    30  3d 46 69 72 73 74 20 41  64 6d 69 6e 69 73 74 72  |=First Administr|
    40  61 74 69 76 65 20 47 72  6f 75 70 2f 63 6e 3d 52  |ative Group/cn=R|
    50  65 63 69 70 69 65 6e 74  73 2f 63 6e 3d 68 65 6c  |ecipients/cn=hel|
    60  67 65 00                                          |ge.|
    63
  */
  static unsigned char prefix[] = {
    // TODO: find out the values ... (24 bytes prefix)
    0x00, 0x00, 0x00, 0x00, 0x1b, 0x55, 0xfa, 0x20,
    0xaa, 0x66, 0x11, 0xcd, 0x9b, 0xc8, 0x00, 0xaa,
    0x00, 0x2f, 0xc4, 0x5a, 0x0c, 0x00, 0x00, 0x00
  };
  NSMutableData *data;
  NSString *s;
  
  data = [NSMutableData dataWithCapacity:64];
  [data appendBytes:prefix length:sizeof(prefix)];
  
  s = [self hostName];
  [data appendBytes:[s cString] 
        length:([s cStringLength] + 1) /* include 0 ! */];

  s = [self dn];
  [data appendBytes:[s cString] 
        length:([s cStringLength] + 1) /* include 0 ! */];
  
  return data;
}

- (NSString *)valueAsBase64String {
  NSData   *data;
  NSString *s;
  
  if ((data = [[self valueAsData] dataByEncodingBase64]) == nil)
    return nil;
  
  s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
  return [s autorelease];
}

- (id)exDavBase64Value {
  NSString *s;
  
  if (base64TypeAttr == nil) {
    base64TypeAttr = 
      [[NSDictionary alloc] 
        initWithObjectsAndKeys:@"bin.base64", XMLTAG_MS_DTTYPE, nil];
  }
  
  if ((s = [self valueAsBase64String]) == nil)
    return nil;
  
  return [SoWebDAVValue valueForObject:s attributes:base64TypeAttr];
}

@end /* ExStoreEntryID */
