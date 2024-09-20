/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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
  if (![filename isNotEmpty])
    filename = [_type valueOfParameter:@"name"];
  if (![filename isNotEmpty])
    filename = @"download";
  return filename;
}

- (NSURL *)urlAsNSURL {
  NSString *s;
  
  s = [[self request] formValueForKey:@"url"];
  return [s isNotEmpty] ? [NSURL URLWithString:s] : nil;
}


/* backend operations */

- (NSData *)decodeData:(NSData *)_data withEncoding:(NSString *)_encoding {
  NGMimePartParser *parser;
  NSData *result;

  if (![_encoding isNotEmpty]) /* nothing to encode */
    return _data;
  
  // TBD: in SOPE 4.7 we can use -dataByApplyingMimeContentTransferEncoding:
  parser    = [[NGMimePartParser alloc] init];
  result    = [[parser applyTransferEncoding:_encoding onData:_data] retain];
  [parser release]; parser = nil;
  
  return [result autorelease];
}

- (NSData *)decodeDataOrUseIt:(NSData *)_data 
  withEncoding:(NSString *)_encoding 
{
  /* try to encode, if this fails, use raw data */
  id tmp;
  
  if (_data == nil)
    return nil;
  if ((tmp = [self decodeData:_data withEncoding:_encoding]) != nil)
    return tmp;
  
  [self logWithFormat:@"encoding for '%@' failed on data 0x%p(len=%d)",
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
    [self errorWithFormat:@"could not retrieve IMAP4 client object due to"
          @" missing session."];
    return nil;
  }
  
  if (HandlerClass == Nil) {
    HandlerClass = NSClassFromString(@"SkyImapContextHandler");
    if (HandlerClass == Nil)
      [self errorWithFormat:@"did not find SkyImapContextHandler class!"];
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
  if (![path isNotEmpty]) {
    [self warnWithFormat:@"missing folder path in URL: %@", [self urlAsNSURL]];
    return nil;
  }
  
  if ((folder = [[self imapContext] folderWithName:path]) == nil) {
    [self warnWithFormat:@"got no folder for path '%@' from URL: %@",
            path, [self urlAsNSURL]];
    return nil;
  }
  
  // TODO: explain how this can happen
  if (RootFolderClass == Nil)
    RootFolderClass = NSClassFromString(@"NGImap4ServerRoot");
  if ([folder isKindOfClass:RootFolderClass]) {
    [self warnWithFormat:@"could not load folder for URL: %@", 
	    [self urlAsNSURL]];
    return nil;
  }
  
  return folder;
}

- (NSString *)stripProblematicCharactersFromFilename:(NSString *)filename {
  // => this code replaces all non-char, non-digit, non-dot characters
  //    in filenames with underlines
  // TBD: fix cString
  const unsigned char *cstr;
  unsigned char       *buf;
  int                 i, clen;
  BOOL changed;
  
  cstr = (unsigned char *)[filename cString];
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
    filename = [NSString stringWithCString:(char *)buf length:clen];
  }

  return filename;
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
  NGImap4Folder  *folder;
  NSData         *data;
  WORequest      *req;
  NGMimeType     *type;
  NSString       *encoding, *contentDisp, *filename, *path, *tmp;

  /* first check for a session */

  if ((sn = [self existingSession]) == nil) {
    [self logWithFormat:@"no session active !"];
    return [self missingSession:@"get"];
  }

  /* next retrieve content-type and download filename */
  
  req  = [self request];
  type = [NGMimeType mimeType:[req formValueForKey:@"mimeType"]];


  if (UseOnly7BitHeadersForMailBlobDownload) {
    // TODO: move this code to a separate method
    // TODO: explain what exactly it does
    /* SIDEEFFECT: modifies (at least): filename, args, type */
    
    filename = [req formValueForKey:@"filename"];
    if (![filename isNotEmpty])
      filename = [type valueOfParameter:@"name"];
    
    if ([filename isNotEmpty]) {
      NSString *newName;
      
      newName = [self stripProblematicCharactersFromFilename:filename];
      if (newName != filename) {
	NSDictionary *args;
	
	args = [NSDictionary dictionaryWithObject:newName forKey:@"name"];
	type = [NGMimeType mimeType:[type type] subType:[type subType]
			   parameters:args];
      }
    }
  }
  

  /* what now? */
  
  if ([(tmp = [req formValueForKey:@"url"]) isNotEmpty]) {
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
    
    /*unused:imapCtx =*/[self imapContext]; // may have side effects
    url     = [self urlAsNSURL];
    path    = [url path];
    
    if ((folder = [self folderForURL]) == nil)
      return [self errorResponse:@"did not find folder for specified URL"];
    
    msguid   = [[path lastPathComponent] intValue];
    partName = [[[url query] componentsSeparatedByString:@"="] lastObject];
    data = [folder blobForUid:msguid part:partName];
    if (data == nil) {
      [self errorWithFormat:
              @"could not fetch BLOB of uid %d, part '%@'\n"
              @"  folder: %@\n"
              @"  path:   '%@'",
              msguid, partName, folder, path];
      return [self errorResponse:
		     @"could not fetch message for specified URL"];
    }
  }
  else if ((tmp = [req formValueForKey:@"data_key"]) != nil) {
    data = [[[sn valueForKey:tmp] retain] autorelease];
    [sn removeObjectForKey:tmp];
  }
  else {
    [self errorWithFormat:@"missing 'url' or 'data_key' form parameters?!"];
    return nil;
  }
  
  
  /* encode/decode data */
  
  /* eg 'quoted-printable' or 'base64' */
  encoding = [req formValueForKey:@"encoding"];
  data = [self decodeDataOrUseIt:data withEncoding:encoding];
  
  
  /* apply content-disposition */
  
  if (!_inline) {
    if (![filename isNotEmpty])
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
