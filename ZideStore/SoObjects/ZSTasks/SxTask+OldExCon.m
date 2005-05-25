/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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


// this file is not compiled
// stuff removed from main, to support the Evolution Exchange Connector

#include "SxTask.h"
#include "common.h"
#include <NGMail/NGMimeMessageParser.h> // for comments from Evolution
#include <ZSBackend/NSString+rtf.h>

@implementation SxTask(OldExCon)

static BOOL debugParser = YES;

- (BOOL)parser:(NGMimePartParser *)_parser
  parseRawBodyData:(NSData *)_data
  ofPart:(id<NGMimePart>)_part
{
  /* we keep the raw body */
  if (debugParser)
    [self logWithFormat:@"parser, keep data (len=%i)", [_data length]];
  [_part setBody:_data];
  return YES;
}

- (id)putEvoComment:(id)_ctx {
  /* 
     After Evo did a PROPPATCH, it does a PUT with content-type
     message/rfc822. The message has the comment as the body and 
     these relevant (mail) headers:
       content-class: urn:content-classes:task
       Subject:       test 3
       Thread-Topic:  test 3
       Priority:      normal
       Importance:    normal
       From:          "Helge Hess" <hh@skyrix.com>

     Was called in PUTAction:
#if 0 // old connector stuff
  if ([[[_ctx request] headerForKey:@"user-agent"] hasPrefix:@"Evolution/"])
    return [self putEvoComment:_ctx];
#endif
  */
  NGMimeMessageParser *mimeParser;
  WOResponse *r;
  id part;
  NSString *comment;
  
  r    = [(WOContext *)_ctx response];
  part = [[(WOContext *)_ctx request] content];
  if (debugParser)
    [self logWithFormat:@"should parse %d bytes ..", [part length]];
  
  if ([part length] == 0) {
    [self logWithFormat:@"missing content for PUT ..."];
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:
                          @"no content in task-comment PUT !"];
  }
  
  /* Evolution PUT's a MIME message containing an iCal file */
  mimeParser = [[NGMimeMessageParser alloc] init];
  [mimeParser setDelegate:self];
  part = [mimeParser parsePartFromData:part];
  [mimeParser release]; mimeParser = nil;
  
  if (part == nil) {
    [self logWithFormat:@"could not parse MIME structure for task comment."];
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:
                          @"could not parse MIME structure for task comment"];
  }
  
  // we are interested in the body of the mimepart (which is the comment
  // of our task object)
  comment = [[NSString alloc] initWithData:[part body] 
                              encoding:[NSString defaultCStringEncoding]];

  if ([self isNew]) {
    if ([comment length] > 0)
      [self logWithFormat:
              @"WARNING: losing comment, can't handle comments "
              @"on create yet: %@", comment];

    // if we return 204 (no-content) here, the new task won't show up in Evo
    [r setStatus:200];
    [comment release];
    return r;
  }
  
  if (![[[self object] valueForKey:@"comment"] isEqualToString:comment]) {
    NSDictionary *changes;
    LSCommandContext *cmdctx;
    
    [[self object] takeValue:comment forKey:@"comment"];

    changes = [NSDictionary dictionaryWithObjectsAndKeys:
                            [self object],@"object",
                            nil];

    if ((cmdctx = [self commandContextInContext:_ctx]) != nil) {
      EOModel     *model;
      NSNumber    *width;
      
      model = [[[cmdctx valueForKey:LSDatabaseKey] adaptor] model];
      width = [[[model entityNamed:@"Job"] attributeNamed:@"comment"]
                       valueForKey:@"width"];

      if ([width intValue] >= (int)[comment length]) {
        [cmdctx runCommand:@"job::set" arguments:changes];
        [cmdctx commit];
      }
      else
        [self logWithFormat:
              @"WARNING: losing comment, too long for DB field"
              @" (comment: %i - db: %@)", [comment length], width];
    }
  }

  [comment release]; comment = nil;
  [r setStatus:200];
  return r;
}

@end
