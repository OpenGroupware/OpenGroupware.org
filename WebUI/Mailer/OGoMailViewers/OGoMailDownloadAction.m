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

#include <NGObjWeb/WODirectAction.h>

@interface OGoMailDownloadAction : WODirectAction
{
  id imap4handler; /* SkyImapContextHandler */
}

@end

@interface SkyImapDownloadAction : OGoMailDownloadAction // DEPRECATED
@end

#include <OGoFoundation/OGoFoundation.h>
#include "../OGoWebMail/SkyImapContextHandler.h"
#include "common.h"

@interface NSObject(Private)
- (NGImap4Context *)imapContext;
+ (NGImap4Context *)sessionImapContext:(id)_ses;
@end /* NSObject(Private) */

@implementation OGoMailDownloadAction

static BOOL UseOnly7BitHeadersForMailBlobDownload = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  UseOnly7BitHeadersForMailBlobDownload =
    [ud boolForKey:@"UseOnly7BitHeadersForMailBlobDownload"];
}

- (void)dealloc {
  [self->imap4handler release];
  [super dealloc];
}

/* 'smart' accesses */

- (NSString *)filenameForContentDispositionWithMIMEType:(NGMimeType *)_type {
  NSString *filename;
  
  filename = [[self request] formValueForKey:@"filename"];
  if ([filename length] == 0)
    filename = [_type valueOfParameter:@"name"];
  if ([filename length] == 0)
    filename = @"download";
  return filename;
}

- (NSURL *)urlAsNSURL {
  NSString *s;
  
  s = [[self request] formValueForKey:@"url"];
  if ([s length] == 0)
    return nil;
  return [NSURL URLWithString:s];
}

/* backend operations */

- (NSData *)encodeData:(NSData *)_data withEncoding:(NSString *)_encoding {
  NGMimePartParser *parser;
  NSData *result;

  if ([_encoding length] == 0) /* nothing to encode */
    return _data;
  
  parser    = [[NGMimePartParser alloc] init];
  _encoding = [_encoding lowercaseString];
  result    = [[parser applyTransferEncoding:_encoding onData:_data] retain];
  [parser release];
  return [result autorelease];
}
- (NSData *)encodeDataOrUseIt:(NSData *)_data 
  withEncoding:(NSString *)_encoding 
{
  /* try to encode, if this fails, use raw data */
  id tmp;
  
  if (_data == nil)
    return nil;
  if ((tmp = [self encodeData:_data withEncoding:_encoding]) != nil)
    return tmp;
  
  [self logWithFormat:@"encoding for '%@' failed on data 0x%08X(len=%d)",
          _encoding, _data, [_data length]];
  return _data;
}

/* IMAP4 client objects */

- (id)imapContextHandler {
  static Class HandlerClass = Nil;
  OGoSession *sn;

  if (self->imap4handler)
    return self->imap4handler;
  
  if ((sn = [self existingSession]) == nil) {
    [self logWithFormat:@"ERROR: could not retrieve IMAP4 client object due to"
          @" missing session."];
    return nil;
  }
  
  if (HandlerClass == Nil) {
    HandlerClass = NSClassFromString(@"SkyImapContextHandler");
    if (HandlerClass == Nil)
      [self logWithFormat:@"ERROR: did not find SkyImapContextHandler class!"];
  }
  self->imap4handler = [[HandlerClass imapContextHandlerForSession:sn] retain];
  return self->imap4handler;
}
- (NGImap4Context *)imapContext {
  return [[self imapContextHandler] sessionImapContext:[self existingSession]];
}

- (NGImap4Folder *)folderForURL {
  static Class RootFolderClass = Nil;
  NSString      *path;
  NGImap4Folder *folder;
  
  path = [[[self urlAsNSURL] path] stringByDeletingLastPathComponent];
  if ([path length] == 0) {
    [self logWithFormat:@"WARNING: missing folder path in URL: %@",
            [self urlAsNSURL]];
    return nil;
  }
  
  if ((folder = [[self imapContext] folderWithName:path]) == nil) {
    [self logWithFormat:@"WARNING: got no folder for path '%@' from URL: %@",
            path, [self urlAsNSURL]];
    return nil;
  }
  
  // TODO: explain how this can happen
  if (RootFolderClass == Nil)
    RootFolderClass = NSClassFromString(@"NGImap4ServerRoot");
  if ([folder isKindOfClass:RootFolderClass]) {
    [self logWithFormat:@"WARNING: could not load folder for URL: %@",
          [self urlAsNSURL]];
    return nil;
  }
  
  return folder;
}

/* reset action state */

- (void)reset {
  [self->imap4handler release]; self->imap4handler = nil;
}

/* UI operations */

- (id<WOActionResults>)missingSession:(NSString *)_action {
  // TODO: perform redirect to root URL
  // TODO: I think this is catched by the application object?, not sure
  [self debugWithFormat:@"missing session for action '%@'", _action];
  return nil;
}

- (id<WOActionResults>)errorResponse:(NSString *)_reason {
  WOResponse *r;
  
  [self reset];
  r = [[self context] response];
  [r appendContentString:@"mail download error: "];
  [r appendContentHTMLString:_reason];
  return r;
}

- (id<WOActionResults>)_downloadInline:(BOOL)_inline {
  WOSession      *sn;
  NSURL          *url;
  NGImap4Context *imapCtx;
  NGImap4Folder  *folder;
  NSData         *data;
  WORequest      *req;
  NGMimeType     *type;
  NSString       *encoding, *contentDisp, *filename, *path, *tmp;
  
  filename = nil;
  req      = [self request];
  type     = [NGMimeType mimeType:[req formValueForKey:@"mimeType"]];
  
  if (UseOnly7BitHeadersForMailBlobDownload) {
    // TODO: move this code to a separate method
    // TODO: explain what exactly it does
    /* modifies (at least): filename, args, type */
    BOOL changed;
    
    changed  = NO;
    filename = [req formValueForKey:@"filename"];
    if ([filename length] == 0)
      filename = [type valueOfParameter:@"name"];
    
    if ([filename length] > 0) {
      unsigned const char *cstr;
      unsigned char       *buf;
      int                 i, clen;
      
      cstr = [filename cString];
      clen = [filename cStringLength];
      buf = alloca(clen + 3);
      for (i = 0; i < clen; i++) {
        if (isalnum(cstr[i]) || cstr[i] == '.')
          buf[i] = cstr[i];
        else {
          changed = YES;
          buf[i]  = '_';
        }
      }
      if (changed) {
        buf[clen] = '\0';
        filename = [NSString stringWithCString:buf length:clen];
      }
    }
    if (changed) {
      NSDictionary *args;

      args = [NSDictionary dictionaryWithObject:filename forKey:@"name"];
      type = [NGMimeType mimeType:[type type] subType:[type subType]
                         parameters:args];
    }
  }
  encoding = [req formValueForKey:@"encoding"];
  
  if ((sn  = [self existingSession]) == nil) {
    [self logWithFormat:@"no session active !"];
    return [self missingSession:@"get"];
  }

  tmp = [req formValueForKey:@"url"];
  if ([tmp length] > 0) {
    /* 
       Example Query URL:
         /OpenGroupware.woa/x/SkyImapDownloadAction/get/FLOSS_Final0.pdf
           ?woinst=32276
           &url=imap%3A%2F%2Fmailhost%2FINBOX%2F20328%3Fpart%3D2
           &mimeType=application%2Fpdf%3B%20name%3DFLOSS_Final0%2Epdf
           &encoding=base64
           &wosid=7E147E140140F67527
       IMAP URL:
         imap://mailhost/INBOX/20328?part=2
    */
    NSString *partName;
    int msguid;
    
    imapCtx = [self imapContext];
    url     = [self urlAsNSURL];
    path    = [url path];

    if ((folder = [self folderForURL]) == nil)
      return [self errorResponse:@"did not find folder for specified URL"];
    
    msguid   = [[path lastPathComponent] intValue];
    partName = [[[url query] componentsSeparatedByString:@"="] lastObject];
    data = [folder blobForUid:msguid part:partName];
    if (data == nil) {
      [self logWithFormat:
              @"ERROR: could not fetch BLOB of uid %d, part '%@'\n"
              @"  folder: %@\n"
              @"  path:   '%@'",
              msguid, partName, folder, path];
      return [self errorResponse:@"could not fetch message for specified URL"];
    }
  }
  else {
    tmp = [req formValueForKey:@"data_key"];

    data = [[[[self session] valueForKey:tmp] retain] autorelease];
    [(OGoSession *)[self session] removeObjectForKey:tmp];
  }
  
  data = [self encodeDataOrUseIt:data withEncoding:encoding];
  
  if (!_inline) {
    if ([filename length] == 0)
      filename = [self filenameForContentDispositionWithMIMEType:type];
    
    contentDisp = [NSString stringWithFormat:@"attachment;filename=\"%@\"",
                              filename];
  }
  else
    contentDisp = nil;
  
  return [LSWMimeContent mimeContent:data ofType:type
                         contentDisposition:contentDisp
                         inContext:[sn context]];
}
  

- (id<WOActionResults>)downloadAction {
  return [self _downloadInline:NO];
}

- (id<WOActionResults>)getAction {
  return [self _downloadInline:YES];
}

@end /* OGoMailDownloadAction */

@implementation SkyImapDownloadAction // DEPRECATED
@end /* SkyImapDownloadAction */
