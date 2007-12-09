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

#import <NGObjWeb/WODirectAction.h>

@interface LSWDocumentDownloadAction : WODirectAction
{
  int pkey;
}

- (id<WOActionResults>)getAction;

@end

#include "common.h"

@interface LSWDocumentDownloadAction(PrivateMethods)
- (id)downloadAttachmentForType:(NSString *)_type pkey:(id)_pkey
  inContext:(WOContext *)_ctx;
@end

@implementation LSWDocumentDownloadAction

+ (int)version {
  return 1;
}
+ (void)initialize {
  NSAssert2([super version] == 4,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)setPkey:(int)_key {
  self->pkey = _key;
}
- (int)pkey {
  return self->pkey;
}

/* no session action */

- (id<WOActionResults>)missingSession:(NSString *)_action {
  if (self->pkey > 0) {
    WOComponent *mainPage;

    mainPage = [self pageWithName:@"Main"];

    [mainPage takeValue:self forKey:@"directActionObject"];

    if (_action)
      [mainPage takeValue:_action forKey:@"directAction"];
    
    return mainPage;
  }
  else
    return nil;
}

/* actions */

- (id<WOActionResults>)getAction {
  [self takeFormValuesForKeys:@"pkey", nil];
  
  if (self->pkey > 0) {
    WOSession *sn;
    WOContext *ctx;

    if ((sn  = [self existingSession]) == nil) {
      [self logWithFormat:@"no session active !"];
      return [self missingSession:@"get"];
    }
    ctx = [sn context];

    return [self downloadAttachmentForType:@"doc"
                 pkey:[NSNumber numberWithInt:self->pkey]
                 inContext:ctx];
  }
  else {
    [self logWithFormat:@"invalid pkey !"];
    return nil;
  }
}

- (id<WOActionResults>)getVersionAction {
  [self takeFormValuesForKeys:@"pkey", nil];
  
  if (self->pkey > 0) {
    WOSession *sn;
    WOContext *ctx;

    if ((sn  = [self existingSession]) == nil) {
      [self logWithFormat:@"no session active !"];
      return [self missingSession:@"getVersion"];
    }
    ctx = [sn context];

    return [self downloadAttachmentForType:@"documentversion"
                 pkey:[NSNumber numberWithInt:self->pkey]
                 inContext:ctx];
  }
  else {
    [self logWithFormat:@"invalid pkey !"];
    return nil;
  }
}

/* misc */

- (id<WOActionResults>)getEditingAction {
  [self takeFormValuesForKeys:@"pkey", nil];

  if (self->pkey > 0) {
    WOSession *sn;
    WOContext *ctx;

    if ((sn  = [self existingSession]) == nil) {
      [self logWithFormat:@"no session active !"];
      return [self missingSession:@"getEditing"];
    }
    ctx = [sn context];

    return [self downloadAttachmentForType:@"documentediting"
                 pkey:[NSNumber numberWithInt:self->pkey]
                 inContext:ctx];
  }
  else {
    [self logWithFormat:@"invalid pkey !"];
    return nil;
  }
}

- (id)downloadAttachmentForType:(NSString *)_type pkey:(id)_pkey
  inContext:(WOContext *)_ctx
{
  NSString     *cmd       = nil;
  NSString     *keyAttr   = nil;
  id           obj        = nil;
  NSData       *data      = nil;
  NSString     *mType     = nil;
  NGMimeType   *mt        = nil;
  NSArray      *result    = nil;
  NSDictionary *mimeTypes = nil;
  
  mimeTypes = [[[self session] userDefaults] dictionaryForKey:@"LSMimeTypes"];

  if ([_type isEqualToString:@"doc"]) {
    cmd     = @"doc::get";
    keyAttr = @"documentId";
  }
  else if ([_type isEqualToString:@"documentversion"]) {
    cmd     = @"documentversion::get";
    keyAttr = @"documentVersionId";
  }
  else if ([_type isEqualToString:@"documentediting"]) {
    cmd     = @"documentediting::get";
    keyAttr = @"documentEditingId";
  }
  
  result = [[_ctx session] runCommand:cmd, keyAttr, _pkey, nil];

  if ([result count] == 1) {
    obj = [result lastObject];
    //NSLog(@"one document matched direct action query.");
  }
  else if ([result count] == 0) {
    NSLog(@"no document matched direct action query.");
    //[self setErrorString:@"No entry matched URL query."];
  }
  else {
    NSLog(@"multiple documents matched direct action query.");
    obj = [result objectAtIndex:0];
  }

  if (obj != nil) {
    NSString *ext   = [obj valueForKey:@"fileType"];
    
    [obj run:[_type stringByAppendingString:@"::get-attachment-name"], nil];
    
    data  = [NSData dataWithContentsOfFile:[obj valueForKey:@"attachmentName"]];
    mType = [mimeTypes valueForKey:ext];
  }

  if (data == nil) {
    NSString *s = @"no permission to get document!";
    
    data  = [s dataUsingEncoding:NSASCIIStringEncoding];
    mType = @"text/plain";
  }
  
  if (mType == nil) 
    mType = @"application/octet-stream";

  mt = [NGMimeType mimeType:mType];

  //NSLog(@"data is %i bytes (file=%@).",
  //      [data length], [obj valueForKey:@"attachmentName"]);

  {
    WOResponse *response;
    NSString *tmp;

    response = [[LSWMimeContent mimeContent:data ofType:mt inContext:_ctx]
                                generateResponse];

    /* add content-disposition header (this is not a valid HTTP header !!!) */
    if ((tmp = [[_ctx request] headerForKey:@"user-agent"]) == nil)
      return response;

    if ([tmp rangeOfString:@"MSIE"].length == 0)
      return response;

    {
	unsigned int i, clen;
        NSString *filename;
	unichar  *buf;
    
        filename = [obj valueForKey:@"title"];
        filename = [filename stringByAppendingString:@"."];
        filename = [filename stringByAppendingString:
                               [obj valueForKey:@"fileType"]];
	
	clen = [filename length];
	buf  = malloc(sizeof(unichar) * (clen + 2));
	[filename getCharacters:buf];
	
	for (i = 0; i < clen; i++) {
          if (!isalnum(buf[i]) && buf[i] != '.')
            buf[i] = '_';
	}
        buf[clen] = '\0';
	
	filename = [[NSString alloc] initWithCharactersNoCopy:buf length:clen
				     freeWhenDone:YES];
	buf = NULL; /* ownership given to NSString */
	
        [response setHeader:
                  [@"attachment;filename=" stringByAppendingString:filename]
                  forKey:@"content-disposition"];
	
	[filename release]; filename = nil;
	
	return response;
    }
  }
}

@end /* LSWDocumentDownloadAction */
