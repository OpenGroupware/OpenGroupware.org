/*
  Copyright (C) 2000-2006 SKYRIX Software AG

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

#include "common.h"

@interface AsteriskDialer : NSObject
{
  NSString *dialContext;
  NSString *outgoingContext;
  NSString *internalContext;
  unsigned internalExtensionLength;
}
-(void)setInternalExtensionLength:(unsigned )_length;
- (unsigned )internalExtensionLength;
-(void)setInternalContext:(NSString *)_context;
- (NSString *)internalContext;
-(void)setOutgoingContext:(NSString *)_context;
- (NSString *)outgoingContext;
-(void)setDialContext:(NSString *)_context;
- (NSString *)dialContext;
@end

#include "AsteriskConnection.h"

@implementation AsteriskDialer

- (id)init {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  [self setInternalExtensionLength:[[ud stringForKey:@"AsteriskInternalExtensionLength"] intValue]];
  [self setOutgoingContext:[ud stringForKey:@"AsteriskOutgoingContext"]];
  [self setInternalContext:[ud stringForKey:@"AsteriskInternalContext"]];
  [self setDialContext:[ud stringForKey:@"AsteriskInternalContext"]];

  return self; 
}


-(void)dealloc {
  RELEASE(self->dialContext);
  RELEASE(self->outgoingContext);
  RELEASE(self->internalContext);
  [super dealloc];
}

/* accessors */
-(void)setInternalExtensionLength:(unsigned )_length {
  self->internalExtensionLength = _length;
}
- (unsigned)internalExtensionLength {
  return self->internalExtensionLength;
}
-(void)setInternalContext:(NSString *)_context {
  ASSIGN(self->internalContext, _context);
}
- (NSString *)internalContext {
  return self->internalContext;
}
-(void)setOutgoingContext:(NSString *)_context {
  ASSIGN(self->outgoingContext, _context);
}
- (NSString *)outgoingContext {
  return self->outgoingContext;
}
-(void)setDialContext:(NSString *)_context {
  ASSIGN(self->dialContext, _context);
}
- (NSString *)dialContext {
  return self->dialContext;
}


- (NSString *)cleanupNumber:(NSString *)_number {
  NSDictionary *prefixMappings;
  NSEnumerator *prefixes;
  NSString     *prefix;
  NSString     *dialoutPrefix;


  prefixMappings = [[NSUserDefaults standardUserDefaults]
                                    dictionaryForKey:@"AsteriskDialerPrefixMap"];
  dialoutPrefix = [[NSUserDefaults standardUserDefaults] stringForKey:@"AsteriskDialOutPrefix"];

  _number = [_number stringByReplacingString:@" " withString:@""];
  _number = [_number stringByReplacingString:@"-" withString:@""];
  if ([_number length] != [self internalExtensionLength]) {
    [self setDialContext:[self outgoingContext]];
    if ([dialoutPrefix isNotEmpty]) {
      _number = [dialoutPrefix stringByAppendingString:_number];
    }
  }
return _number;
#if 1
  // first sort based on prefix length !!!
  prefixes = [prefixMappings keyEnumerator];
  while ((prefix = [prefixes nextObject])) {
    if ([_number hasPrefix:prefix]) {
      _number = [_number substringFromIndex:[prefix length]];
      _number = [[prefixMappings objectForKey:prefix]
                                 stringByAppendingString:_number];
      break;
    }
  }
#endif
  
/* #warning need prefix mapping table here ...
  if ([_number hasPrefix:@"+493916623"])
    _number = [_number substringFromIndex:10];
  else if ([_number hasPrefix:@"+49"]) {
    _number = [_number substringFromIndex:3];
    _number = [@"00" stringByAppendingString:_number];
  }
  else
    _number = nil; */
  return _number;
}

- (BOOL)canDialNumber:(NSString *)_number {
  _number = [self cleanupNumber:_number];
  return [_number length] > 0 ? YES : NO;
}


- (BOOL)dialNumber:(NSString *)_number fromDevice:(NSString *)_device {
  AsteriskConnection *asterisk;

  BOOL ok;
  ok = YES;

  _number = [self cleanupNumber:_number];
  if ([_number length] == 0)
    return NO;
  
  asterisk = [[AsteriskConnection alloc] init];
  if (![asterisk loginToAsterisk]) {
    NSLog(@"%s: couldn't login to the asterisk '%@': %@",
          __PRETTY_FUNCTION__, _device, [asterisk lastException]);
    [asterisk bye];
    RELEASE(asterisk);
    ok = NO;
    return NO;
  }
  
  /* place call */

#if DEBUG
  NSLog(@"AsteriskDialer: will dial '%@' from device '%@'",
        _number, _device);
#endif
  
  [asterisk setContext:[self dialContext]];
  ok = [asterisk makeCallTo:_number
             fromDevice:_device];
  
  /* tear down */
  
  [asterisk bye];
  RELEASE(asterisk);
  
  return ok;
}

@end /* AsteriskDialer */
