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
   This code is:
    "derived from the RSA Data Security, Inc. MD5 Message-Digest Algorithm"
*/
// $Id$

#import <Foundation/Foundation.h>
#include <OGoPalm/NGMD5Generator.h>

// Constants for MD5Transform routine.
#define S11 7
#define S12 12
#define S13 17
#define S14 22
#define S21 5
#define S22 9
#define S23 14
#define S24 20
#define S31 4
#define S32 11
#define S33 16
#define S34 23
#define S41 6
#define S42 10
#define S43 15
#define S44 21

static unsigned char PADDING[64] = {
  0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

// Note: Replace "for loop" with standard memcpy if possible.

static inline void MD5_memcpy (void *output, void *input, unsigned int len) {
  register unsigned int i;

  for (i = 0; i < len; i++)
    ((char *)output)[i] = ((char *)input)[i];
}

// F, G, H and I are basic MD5 functions.

static inline unsigned int F(unsigned int x, unsigned int y, unsigned int z) {
  return (((x) & (y)) | ((~x) & (z)));
}
static inline unsigned int G(unsigned int x, unsigned int y, unsigned int z) {
  return (((x) & (z)) | ((y) & (~z)));
}
static inline unsigned int H(unsigned int x, unsigned int y, unsigned int z) {
  return ((x) ^ (y) ^ (z));
}
static inline unsigned int I(unsigned int x, unsigned int y, unsigned int z) {
  return ((y) ^ ((x) | (~z)));
}

// ROTATE_LEFT rotates x left n bits.

static inline unsigned int RotateLeft(unsigned int x, unsigned int n) {
  return (((x) << (n)) | ((x) >> (32-(n))));
}

// FF, GG, HH, and II transformations for rounds 1, 2, 3, and 4.
// Rotation is separate from addition to prevent recomputation.

static inline unsigned int FF(unsigned int a, unsigned int b, unsigned int c,
                              unsigned int d, unsigned int x, unsigned int s,
                              unsigned int ac) {
  return RotateLeft(a + F(b, c, d) + x + ac, s) + b;
}
static inline unsigned int GG(unsigned int a, unsigned int b, unsigned int c,
                              unsigned int d, unsigned int x, unsigned int s,
                              unsigned int ac) {
  return RotateLeft(a + G(b, c, d) + x + ac, s) + b;
}
static inline unsigned int HH(unsigned int a, unsigned int b, unsigned int c,
                              unsigned int d, unsigned int x, unsigned int s,
                              unsigned int ac) {
  return RotateLeft(a + H(b, c, d) + x + ac, s) + b;
}
static inline unsigned int II(unsigned int a, unsigned int b, unsigned int c,
                              unsigned int d, unsigned int x, unsigned int s,
                              unsigned int ac) {
  return RotateLeft(a + I(b, c, d) + x + ac, s) + b;
}

// MD5 basic transformation. Transforms state based on block.
static void MD5Transform (unsigned int state[4], const unsigned char block[64]) {
  unsigned int a = state[0];
  unsigned int b = state[1];
  unsigned int c = state[2];
  unsigned int d = state[3];
  unsigned int x[16];

  { //  Decode(x, block, 64);
    unsigned int i, j;

    for (i = 0, j = 0; j < 64; i++, j += 4) {
      x[i] =
         ((unsigned int)block[j])          |
        (((unsigned int)block[j+1]) << 8)  |
        (((unsigned int)block[j+2]) << 16) |
        (((unsigned int)block[j+3]) << 24);
    }
  }

  // Round 1
  a = FF (a, b, c, d, x[ 0], S11, 0xd76aa478); /* 1 */
  d = FF (d, a, b, c, x[ 1], S12, 0xe8c7b756); /* 2 */
  c = FF (c, d, a, b, x[ 2], S13, 0x242070db); /* 3 */
  b = FF (b, c, d, a, x[ 3], S14, 0xc1bdceee); /* 4 */
  a = FF (a, b, c, d, x[ 4], S11, 0xf57c0faf); /* 5 */
  d = FF (d, a, b, c, x[ 5], S12, 0x4787c62a); /* 6 */
  c = FF (c, d, a, b, x[ 6], S13, 0xa8304613); /* 7 */
  b = FF (b, c, d, a, x[ 7], S14, 0xfd469501); /* 8 */
  a = FF (a, b, c, d, x[ 8], S11, 0x698098d8); /* 9 */
  d = FF (d, a, b, c, x[ 9], S12, 0x8b44f7af); /* 10 */
  c = FF (c, d, a, b, x[10], S13, 0xffff5bb1); /* 11 */
  b = FF (b, c, d, a, x[11], S14, 0x895cd7be); /* 12 */
  a = FF (a, b, c, d, x[12], S11, 0x6b901122); /* 13 */
  d = FF (d, a, b, c, x[13], S12, 0xfd987193); /* 14 */
  c = FF (c, d, a, b, x[14], S13, 0xa679438e); /* 15 */
  b = FF (b, c, d, a, x[15], S14, 0x49b40821); /* 16 */

  // Round 2
  a = GG (a, b, c, d, x[ 1], S21, 0xf61e2562); /* 17 */
  d = GG (d, a, b, c, x[ 6], S22, 0xc040b340); /* 18 */
  c = GG (c, d, a, b, x[11], S23, 0x265e5a51); /* 19 */
  b = GG (b, c, d, a, x[ 0], S24, 0xe9b6c7aa); /* 20 */
  a = GG (a, b, c, d, x[ 5], S21, 0xd62f105d); /* 21 */
  d = GG (d, a, b, c, x[10], S22,  0x2441453); /* 22 */
  c = GG (c, d, a, b, x[15], S23, 0xd8a1e681); /* 23 */
  b = GG (b, c, d, a, x[ 4], S24, 0xe7d3fbc8); /* 24 */
  a = GG (a, b, c, d, x[ 9], S21, 0x21e1cde6); /* 25 */
  d = GG (d, a, b, c, x[14], S22, 0xc33707d6); /* 26 */
  c = GG (c, d, a, b, x[ 3], S23, 0xf4d50d87); /* 27 */
  b = GG (b, c, d, a, x[ 8], S24, 0x455a14ed); /* 28 */
  a = GG (a, b, c, d, x[13], S21, 0xa9e3e905); /* 29 */
  d = GG (d, a, b, c, x[ 2], S22, 0xfcefa3f8); /* 30 */
  c = GG (c, d, a, b, x[ 7], S23, 0x676f02d9); /* 31 */
  b = GG (b, c, d, a, x[12], S24, 0x8d2a4c8a); /* 32 */

  // Round 3
  a = HH (a, b, c, d, x[ 5], S31, 0xfffa3942); /* 33 */
  d = HH (d, a, b, c, x[ 8], S32, 0x8771f681); /* 34 */
  c = HH (c, d, a, b, x[11], S33, 0x6d9d6122); /* 35 */
  b = HH (b, c, d, a, x[14], S34, 0xfde5380c); /* 36 */
  a = HH (a, b, c, d, x[ 1], S31, 0xa4beea44); /* 37 */
  d = HH (d, a, b, c, x[ 4], S32, 0x4bdecfa9); /* 38 */
  c = HH (c, d, a, b, x[ 7], S33, 0xf6bb4b60); /* 39 */
  b = HH (b, c, d, a, x[10], S34, 0xbebfbc70); /* 40 */
  a = HH (a, b, c, d, x[13], S31, 0x289b7ec6); /* 41 */
  d = HH (d, a, b, c, x[ 0], S32, 0xeaa127fa); /* 42 */
  c = HH (c, d, a, b, x[ 3], S33, 0xd4ef3085); /* 43 */
  b = HH (b, c, d, a, x[ 6], S34,  0x4881d05); /* 44 */
  a = HH (a, b, c, d, x[ 9], S31, 0xd9d4d039); /* 45 */
  d = HH (d, a, b, c, x[12], S32, 0xe6db99e5); /* 46 */
  c = HH (c, d, a, b, x[15], S33, 0x1fa27cf8); /* 47 */
  b = HH (b, c, d, a, x[ 2], S34, 0xc4ac5665); /* 48 */

  // Round 4
  a = II (a, b, c, d, x[ 0], S41, 0xf4292244); /* 49 */
  d = II (d, a, b, c, x[ 7], S42, 0x432aff97); /* 50 */
  c = II (c, d, a, b, x[14], S43, 0xab9423a7); /* 51 */
  b = II (b, c, d, a, x[ 5], S44, 0xfc93a039); /* 52 */
  a = II (a, b, c, d, x[12], S41, 0x655b59c3); /* 53 */
  d = II (d, a, b, c, x[ 3], S42, 0x8f0ccc92); /* 54 */
  c = II (c, d, a, b, x[10], S43, 0xffeff47d); /* 55 */
  b = II (b, c, d, a, x[ 1], S44, 0x85845dd1); /* 56 */
  a = II (a, b, c, d, x[ 8], S41, 0x6fa87e4f); /* 57 */
  d = II (d, a, b, c, x[15], S42, 0xfe2ce6e0); /* 58 */
  c = II (c, d, a, b, x[ 6], S43, 0xa3014314); /* 59 */
  b = II (b, c, d, a, x[13], S44, 0x4e0811a1); /* 60 */
  a = II (a, b, c, d, x[ 4], S41, 0xf7537e82); /* 61 */
  d = II (d, a, b, c, x[11], S42, 0xbd3af235); /* 62 */
  c = II (c, d, a, b, x[ 2], S43, 0x2ad7d2bb); /* 63 */
  b = II (b, c, d, a, x[ 9], S44, 0xeb86d391); /* 64 */

  state[0] += a;
  state[1] += b;
  state[2] += c;
  state[3] += d;

  // Zeroize sensitive information.
  memset((void *)x, 0, sizeof (x));
}

@implementation NGMD5Generator

- (id)init {
  if ((self = [super init])){
    self->count[0] = self->count[1] = 0;
    // Load magic initialization constants.
    self->state[0] = 0x67452301;
    self->state[1] = 0xefcdab89;
    self->state[2] = 0x98badcfe;
    self->state[3] = 0x10325476;
  }
  return self;
}

- (void)updateBytes:(const char *)input count:(unsigned int)inputLen {
  unsigned int i, index, partLen;

  // Compute number of bytes mod 64
  index = (unsigned int)((self->count[0] >> 3) & 0x3F);

  // Update number of bits
  if ((self->count[0] += ((unsigned int)inputLen << 3))
      < ((unsigned int)inputLen << 3))
    self->count[1]++;
  self->count[1] += ((unsigned int)inputLen >> 29);

  partLen = 64 - index;

  // Transform as many times as possible.
  if (inputLen >= partLen) {
    MD5_memcpy((void *)&self->buffer[index], (void *)input, partLen);
    MD5Transform(self->state, self->buffer);

    for (i = partLen; i + 63 < inputLen; i += 64)
      MD5Transform (self->state, &input[i]);

    index = 0;
  }
  else
    i = 0;

  // Buffer remaining input
  MD5_memcpy((void *)&self->buffer[index], (void *)&input[i], inputLen-i);
}

static void Encode(unsigned char *output, unsigned int *input, unsigned int len) {
  // Encodes input(uint4) into output(unsigned char).
  // Assumes len is a multiple of 4.
  register unsigned int i, j;

  for (i = 0, j = 0; j < len; i++, j += 4) {
    output[j]   = (unsigned char)(input[i] & 0xff);
    output[j+1] = (unsigned char)((input[i] >> 8) & 0xff);
    output[j+2] = (unsigned char)((input[i] >> 16) & 0xff);
    output[j+3] = (unsigned char)((input[i] >> 24) & 0xff);
  }
}

- (void)finish {
  // MD5 finalization. Ends an MD5 message-digest operation, writing the
  // the message digest and zeroizing the self.

  unsigned char bits[8];
  unsigned int  index, padLen;

  if (self->hasDigest)
    return;

  // Save number of bits
  Encode (bits, self->count, 8);

  // Pad out to 56 mod 64.
  index  = (unsigned int)((self->count[0] >> 3) & 0x3f);
  padLen = (index < 56) ? (56 - index) : (120 - index);
  [self updateBytes:PADDING count:padLen];

  // Append length (before padding)
  [self updateBytes:bits count:8];

  // Store state in digest
  Encode (self->digest, self->state, 16);

  // Zeroize sensitive information.
  self->state[0] = 0;
  self->state[1] = 0;
  self->state[2] = 0;
  self->state[3] = 0;
  self->count[0] = 0;
  self->count[1] = 0;
  memset(self->buffer, 0, 64);

  self->hasDigest = YES;
}

/* interface */

- (void)encodeString:(NSString *)_string {
  unsigned len;
  void     *buf;
  
  if (self->hasDigest) {
    [NSException raise:@"MD5EncodeException"
                 format:@"<MD5 already has a digest !>"];
  }

  len = [_string cStringLength];
  buf = malloc(len + 10);
  [_string getCString:buf];
  
  [self updateBytes:buf count:len];
  free(buf);
}

- (void)encodeBytes:(const void *)_bytes count:(unsigned)_length {
  [self updateBytes:_bytes count:_length];
}

- (void)encodeData:(NSData *)_data {
  [self updateBytes:[_data bytes] count:[_data length]];
}

// getting the digest

- (NSData *)digestAsData {
  [self finish];
  
  return [NSData dataWithBytes:self->digest length:16];
}
- (NSString *)digestAsString {
  unsigned char buf[33];
  register int  i;

  [self finish];

  buf[32] = '\0';

  for (i = 0; i < 16; i++) {
    int high = (self->digest[i] & 0xf0) >> 4;
    int low  = (self->digest[i] & 0x0f);

    buf[i * 2]     = (high > 9) ? ('a' + high - 10) : ('0' + high);
    buf[i * 2 + 1] = (low  > 9) ? ('a' + low  - 10) : ('0' + low);
  }

  return [NSString stringWithCString:buf length:32];
}

- (NSData *)xorDigestAsDataWithData:(NSData *)_data {
  char buf[16];
  int  i;
  
  [self finish];

  [_data getBytes:buf length:16];

  for (i = 0; i < 16; i++)
    buf[i] ^= self->digest[i];

  return [NSData dataWithBytes:buf length:16];
}
- (NSString *)xorDigestAsString {
  unsigned char buf[33];
  register int  i;

  [self finish];

  buf[32] = '\0';

  for (i = 0; i < 16; i++) {
    unsigned char b = 0;
    int high, low;

    b    ^= self->digest[i];
    high =  (b & 0xf0) >> 4;
    low  =  (b & 0x0f);

    buf[i * 2]     = (high > 9) ? ('a' + high - 10) : ('0' + high);
    buf[i * 2 + 1] = (low  > 9) ? ('a' + low  - 10) : ('0' + low);
  }

  return [NSString stringWithCString:buf length:32];
}

@end /* NGMD5Generator */

NSString *NGMD5DigestForString(NSString *_string) {
  NGMD5Generator *md5 = [[NGMD5Generator alloc] init];

  [md5 encodeString:_string];
  _string = [[md5 digestAsString] retain];

  [md5 release]; md5 = nil;

  return [_string autorelease];
}

NSString *NGMD5DigestForData(NSData *_data) {
  NGMD5Generator *md5 = [[NGMD5Generator alloc] init];

  [md5 encodeData:_data];
  _data = [[md5 digestAsString] retain];

  [md5 release]; md5 = nil;

  return [_data autorelease];
}
