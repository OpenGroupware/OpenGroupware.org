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
/* 
   NGMD5Generator.h

   This code is:
    "derived from the RSA Data Security, Inc. MD5 Message-Digest Algorithm"
*/
// $Id$

#ifndef __NGExtensions_NGMD5Generator_H__
#define __NGExtensions_NGMD5Generator_H__

#import <Foundation/NSObject.h>

@class NSString, NSData;

// MD5 encoding class

NSString *NGMD5DigestForString(NSString *_input);
NSString *NGMD5DigestForData(NSData *_input);

@interface NGMD5Generator : NSObject
{
@protected
  unsigned int  state[4];   // state (ABCD)
  unsigned int  count[2];   // number of bits, modulo 2^64 (lsb first)
  unsigned char buffer[64]; // input buffer
  unsigned char digest[16];
  BOOL hasDigest;
}

- (id)init;

// encoding

- (void)encodeString:(NSString *)_string;
- (void)encodeBytes:(const void *)_bytes count:(unsigned)_length;
- (void)encodeData:(NSData *)_data;

// digest

- (NSData *)digestAsData;
- (NSString *)digestAsString;

- (NSData *)xorDigestAsDataWithData:(NSData *)_data;

@end

#endif /* __NGExtensions_NGMD5Generator_H__ */
