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

#include <WSDL/WSDL.h>
#include "SOAPDirectAction.h"
#include "SOAPDirectAction+WSDL.h"
#include <NGObjWeb/WORequest.h>
#include <NGObjWeb/WOResponse.h>
#include <SOAP/SOAP.h>
#include "common.h"

@implementation SOAPDirectAction

- (id)deliverWSDL {
  WOResponse *response;

  response = [[WOResponse alloc] init];
  [response setContentEncoding:NSUTF8StringEncoding];
  [response setHeader:@"text/xml" forKey:@"content-type"];
  [response appendContentString:[self wsdlString]];
  return AUTORELEASE(response);
}

- (BOOL)isSoapDebuggingEnabled {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"SOAPDebugging"];
}

- (void)performSoapBlock:(SOAPBlock *)_block {
  NSArray           *params;
  NSString          *name;
  NSMethodSignature *sign;
  NSInvocation      *invo;
  NSString          *actionName = @"Action";
  id   result = nil;
  SEL  sel;
  int  i, cnt;

  params = [_block values];
  name   = [_block name];
  cnt    = [params count];

  switch (cnt) {
    case 0:
      break;
    case 1:
      actionName = [actionName stringByAppendingString:@":"];
      break;
    case 2:
      actionName = [actionName stringByAppendingString:@"::"];
      break;
    case 3:
      actionName = [actionName stringByAppendingString:@":::"];
      break;
    case 4:
      actionName = [actionName stringByAppendingString:@"::::"];
      break;
      
    default:
      for (i = 0; i < cnt; i++)
        actionName = [actionName stringByAppendingString:@":"];
      break;
  }
  
  name       = [name stringByReplacingString:@"." withString:@"_"];
  actionName = [name stringByAppendingString:actionName];
  sel        = NSSelectorFromString(actionName);

  if (![self respondsToSelector:sel]) {
    [self logWithFormat:@"no such SOAP action: '%@'", actionName];
 
    result = [NSException exceptionWithName:@"NoSuchAction"
                          reason:@"action not implemented"
                          userInfo:nil];
  }
  else {
    sign = [[self class] instanceMethodSignatureForSelector:sel];
    invo = [NSInvocation invocationWithMethodSignature:sign];
    [invo setSelector:sel];

    [invo setTarget:self];

    cnt = (cnt > [params count]) ? [params count] : cnt;

    for (i = 0; i < cnt; i++) {
      id param = [params objectAtIndex:i];
      [invo setArgument:&param atIndex:i+2];
    }
        
    [invo invoke];
    [invo getReturnValue:&result];
  }
  
  [_block removeAllValues];
  if (result)
    [_block addValue:result];
}

- (id)soapAction {
  SOAPBlock       *block;
  NSArray         *blocks;
  NSMutableString *xmlStr;
  WORequest       *req;
  
  req = [self request];

  if ([[req method] isEqualToString:@"GET"])
    return [self deliverWSDL];

  if ([self isSoapDebuggingEnabled]) {
    NSString *str;

    str = [[NSString alloc] initWithData:
                            [req content] encoding:[req contentEncoding]];
    
    NSLog(@"request is %@", str);
    RELEASE(str);
  }
  
  /*
    nur der *letzte* block (das MUSS ein body sein) wird bearbeitet
  */
  blocks = [SOAPDecoder parseBlocksFromData:[req content]
                        service:[[self services] lastObject]
                        isRequest:YES];
  block  = [blocks lastObject];

  if ([self isSoapDebuggingEnabled]) {
    NSLog(@"block is %@", block);
  }

  if (![[block tagName] isEqualToString:@"Body"]) {
    /* ToDo: hier muss ein fehlercode zurueckgegeben werden */
    NSLog(@"%s: not a body block (%@)", __PRETTY_FUNCTION__, block);
  }

  [self performSoapBlock:block];

  xmlStr  = [[NSMutableString alloc] initWithCapacity:256];
  {
    SOAPEncoder *encoder;
    
    encoder = [[SOAPEncoder alloc] initForWritingWithMutableString:xmlStr];
    [encoder encodeEnvelopeWithBlocks:[NSArray arrayWithObject:block]];
    RELEASE(encoder);
  }

  if ([self isSoapDebuggingEnabled]) {
    NSLog(@"++++ result is %@", xmlStr);
  }
  
  {
    WOResponse *response;

    response = [[WOResponse alloc] init];
    [response appendContentString:xmlStr];
    RELEASE(xmlStr);
    return AUTORELEASE(response);
  }
}

@end /* SOAPDirectAction */
