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

#include "DirectAction.h"
#include "SOAPDirectAction+WSDL.h"
#include "common.h"
#include <NGObjWeb/WORequest.h>
#include <NGObjWeb/WOResponse.h>

@implementation DirectAction

- (id)initWithRequest:(WORequest *)_request {
  if ((self = [super initWithRequest:_request])) {
    [self registerWsdlAtPath:@"test/weatherDocumentStyle.wsdl"];
    // [self registerInterfaceAtPath:@"test/ServiceSummary.idl"];
  }
  return self;
}

- (id)defaultAction {
  WORequest *req = [self request];

  NSLog(@"req.headers = %@", [req headers]);
  NSLog(@"req.content = %@", [req contentAsString]);

  return [super soapAction];
  
  if ([[req method] isEqualToString:@"GET"]) {
    NSString   *str;
    NSString   *file;

    file = [req uri];
    if ([file hasPrefix:@"/"])
      file = [file substringWithRange:NSMakeRange(1, [file length]-1)];
    str  = [NSString stringWithContentsOfFile:file];

    if (str) {
      WOResponse *response;
    
      response = [[WOResponse alloc] init];
      [response setContentEncoding:NSUTF8StringEncoding];
      [response setHeader:@"text/xml" forKey:@"content-type"];
      [response appendContentString:str];
      return AUTORELEASE(response);
    }
  }
  else if (NO) {
    WOResponse *response;
    NSString   *str;

    str = [NSString stringWithContentsOfFile:@"test/getAllServiceSummaries_response.xml"];
    NSLog(@"str is %@", str);

    response = [[WOResponse alloc] init];
    [response appendContentString:str];
    return AUTORELEASE(response);
  }
  else if (YES) {
    NSString *tmp;
    
    tmp = [[NSString alloc] initWithData:
                            [req content] encoding:[req contentEncoding]];
    NSLog(@"\n%@\n", tmp);
    
    RELEASE(tmp);
  }
  return [super soapAction];
}


/* ----------------------------------------------------------------------- */

- (NSString *)HelloWorldAction {
  return @"+++ this is a first soap request +++";
}

- (NSDictionary *)documentAction {
  NSLog(@"perform documentAction...");
  return [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"string1", @"name",
                                  @"donald", @"firstname",
                                  @"personId_value", @"personId", nil];
}

- (NSNumber *)getTempAction:(NSString *)_zip {
  return [NSNumber numberWithFloat:57.123];
}

- (NSArray *)getArrayAction:(NSString *)_string {
  return [NSArray arrayWithObjects:@"object1", @"object2", @"object3", nil];
}

- (NSArray *)getAllServiceSummariesAction {
  NSLog(@"++++++++++++++ getAllServiceSummariesAction is called");
  return [NSArray arrayWithObjects:
                  [NSDictionary dictionaryWithObjectsAndKeys:
                                @"duck",               @"name",
                                @"donald",             @"firstname",
                                @"kurze beschreibung", @"shortDescription",
                                @"http://www.wsdl.de", @"wsdlURL",
                                @"12345",              @"id",
                                @"pub_id_1",           @"publisherID", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:
                                @"ente",               @"name",
                                @"daisy",              @"firstname",
                                @"flotte schnitte",    @"shortDescription",
                                @"www.daisy.com",      @"wsdlURL",
                                @"54321",              @"id",
                                @"pub_id_2",           @"publisherID", nil],
                  nil];
}

- (id)serviceSummaryAction {
  NSLog(@"++++++++++++ serviceSummaryAction is called +++++++++++++");
  
  return [NSDictionary dictionaryWithObjectsAndKeys:
                                @"duck",               @"name",
                                @"donald",             @"firstname",
                                @"kurze beschreibung", @"shortDescription",
                                @"http://www.wsdl.de", @"wsdlURL",
                                @"12345",              @"id",
                                @"pub_id_1",           @"publisherID", nil];
}

- (id)pingPongAction:(id)_summary1
                    :(id)_summary2
                    :(id)_summary3
{
  NSLog(@"pingPongAction is called with parameters: %@, %@, %@",
        _summary1, _summary2, _summary3);
  return _summary1;
}

@end /* DirectAction */
