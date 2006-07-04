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

#include "LSWMimePartViewer.h"
#include "LSWPartBodyViewer.h"
#include "common.h"
#include <NGObjWeb/WEClientCapabilities.h>
#include <NGMime/NGMimeBodyPart.h>
#include <NGMime/NGConcreteMimeType.h>
#include <NGMime/NGMimeFileData.h>
#include <NGMail/NGMimeMessage.h>
#include <NGMail/NGMimeMessageGenerator.h>
#include "SkyDecodeWrapperData.h"

@interface NSObject(Private)
- (NGImap4Context *)imapContext;
- (void)setData:(NSData *)_data;
+ (NGImap4Context *)sessionImapContext:(id)_ses;
@end /* Private */

@interface LSWMimePartViewer(Private)
- (NSString *)url;
- (NSString *)mimeTypeString;
- (NSString *)encodingString;
- (NSString *)partUrl;
- (NSNumber *)showBodyDepSizeVar;
@end /* LSWMimePartViewer(Private) */

@implementation WOComponent(Download)

- (BOOL)isDownloadable {
  return NO;
}

@end /* WOComponent(Download) */

@implementation LSWMimePartViewer

static int CreateMailDownloadFileNamesDisable = -1;
static int ShowBodyDependingSizeDisable = -1;
static int ShowBodySize = -1;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  CreateMailDownloadFileNamesDisable =
    [ud boolForKey:@"CreateMailDownloadFileNamesDisable"] ? 1 : 0;
  ShowBodyDependingSizeDisable =
    [ud boolForKey:@"ShowBodySizeDisable"] ? 1 : 0;
  
  ShowBodySize = [ud integerForKey:@"ShowBodySize"];
  if (ShowBodySize < 1000) ShowBodySize = 100000;
}

- (id)init {
  if ((self = [super init])) {
    self->showBody  = YES;
    self->printMode = NO;
  }
  return self;
}

- (void)dealloc {
  [self->bodyViewer release];
  [self->part       release];
  [self->source     release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [super sleep];
  ASSIGN(self->bodyViewer, nil);
  ASSIGN(self->part,       nil);
  ASSIGN(self->source,     nil);
}

/* accessors */

- (BOOL)isDownloadable {
  return NO;
}

/* response generation */

- (void)appendToResponse:(WOResponse *)_resp
  inContext:(WOContext *)_ctx
{
  NSMutableArray *array;
  
  [super appendToResponse:_resp inContext:_ctx];

  if (![(LSWPartBodyViewer *)[self bodyViewerComponent] isDownloadable])
    return;

  array = [[self session] valueForKey:@"displayedAttachmentDownloadUrls"];
  [array addObject:
           [(LSWPartBodyViewer *)[self bodyViewerComponent] bodyDescription]];
}


- (void)setNestingDepth:(int)_depth {
  self->nestingDepth = _depth;
}
- (int)nestingDepth {
  return self->nestingDepth;
}
- (int)nextNestingDepth {
  return (self->nestingDepth + 1);
}

- (void)setPart:(id)_part {
  ASSIGN(self->part, _part);
}
- (id)part {
  return self->part;
}

- (void)setShowHeaders:(BOOL)_flag {
  self->showHeaders = _flag;
}
- (BOOL)showHeaders {
  return self->showHeaders;
}

/* body */

- (id)body {
  return [self->part body];
}

- (NSData *)contentForURL:(NSURL *)_url {
  NGImap4Context *imapCtx;
  NGImap4Folder  *folder;
  NSString       *path, *encoding;
  NSData         *data;
  
  encoding = [[self encodingString] lowercaseString];
  imapCtx  = [NSClassFromString(@"SkyImapContextHandler")
                               sessionImapContext:[self session]];
  path     = [_url path];

  folder = [imapCtx folderWithName:
		      [path stringByDeletingLastPathComponent]];
  if (folder == nil) {
    [self logWithFormat:
	    @"%s: could not find folder at path %@", __PRETTY_FUNCTION__,
            [path stringByDeletingLastPathComponent]];
    return [[[NSData alloc] init] autorelease];
  }
    
  data = [folder blobForUid:[[path lastPathComponent] intValue]
		 part:[[[_url query] componentsSeparatedByString:@"="]
                              lastObject]];
  if (data == nil) {
    [self logWithFormat:
	    @"%s: could not fetch blob for folder %@ path %@ uid %d part %@",
            __PRETTY_FUNCTION__, folder, path, 
	    [[path lastPathComponent] intValue],
            [[[_url query] componentsSeparatedByString:@"="] lastObject]];
    return [[[NSData alloc] init] autorelease];
  }
  
  if ([encoding isEqualToString:@"base64"])
    return [data dataByDecodingBase64];

  if ([encoding isEqualToString:@"quoted-printable"])
    return [data dataByDecodingQuotedPrintable];
  
  return data;
}

/* header fields */

// Correct content-type if possible. We're using
// the "content-type" field for getting the filename.
// A second filename may be exists in "content-disposition".

- (NGMimeType *)correctedContentType {
  NSString     *ext, *fn;
  NSArray      *e, *a;
  NSDictionary *mimeTypes = nil;
  NSString     *mt;
  id ct;

  ct = [self->part contentType];
  if (!([[[(NGMimeType *)ct type]
                     lowercaseString] isEqualToString:@"application"] &&
      [[[(NGMimeType *)ct subType] lowercaseString]
	isEqualToString:@"octet-stream"]))
    return ct;

  fn  = [[ct parametersAsDictionary] objectForKey:@"name"];
    
  if (![fn isNotNull])
    return ct;

  ext = @"";
  e = [fn componentsSeparatedByString:@"."];
  if ([e count] > 0)
    ext = [e lastObject];

  mimeTypes = [[[self session] userDefaults] dictionaryForKey:@"LSMimeTypes"];
  if (!([ext length] > 0 && [mimeTypes isNotNull]))
    return ct;

  if ((mt = [mimeTypes valueForKey:ext]) == nil)
    return ct;
  

  a = [mt componentsSeparatedByString:@"/"];
  if ([a count] == 2) {
    NGMimeType *mimeType = nil;

    mimeType = [NGMimeType mimeType:[a objectAtIndex:0]
			   subType:[a objectAtIndex:1]
			   parameters:[ct parametersAsDictionary]];
    return mimeType;
  }
  return ct;
}

- (NGMimeType *)contentType {
  //return [self->part contentType];
  return [self correctedContentType];
}
- (NSString *)contentId {
  return [self->part contentId];
}
- (NSArray *)contentLanguage {
  return [self->part contentLanguage];
}
- (NSString *)contentMd5 {
  return [self->part contentMd5];
}
- (NSString *)encoding {
  return [self->part encoding];
}
- (NSString *)contentDescription {
  return [self->part contentDescription];
}

- (NSString *)contentLength {
  id len;
  len = [self->part valuesOfHeaderFieldWithName:@"content-length"];
  len = [len nextObject];
  return [len stringValue];
}
- (NSString *)contentDisposition {
  id v;
  v = [self->part valuesOfHeaderFieldWithName:@"content-disposition"];
  v = [v nextObject];
  return [v stringValue];
}
- (NSString *)contentTransferEncoding {
  id v;
  v = [self->part valuesOfHeaderFieldWithName:@"content-transfer-encoding"];
  v = [v nextObject];
  return [v stringValue];
}

- (NSString *)downloadIconName {
  id cfg = nil;
  NGMimeType *contentType;
  
  contentType = [self contentType];
#if DEBUG
  NSAssert1(contentType == nil ||
            [contentType isKindOfClass:[NGMimeType class]],
            @"invalid content-type class '%@'", contentType);
#endif
  
  cfg = [[self config] valueForKey:@"typeIcons"];
  
  if (contentType == nil) {
    return [cfg valueForKey:@"unknown"];
  }
  else {
    cfg = [cfg valueForKey:[contentType type]];
    cfg = [cfg valueForKey:[contentType subType]];
    return cfg
      ? cfg
      : [[[self config] valueForKey:@"typeIcons"] valueForKey:@"unknown"];
  }
}

- (NSString *)downloadType {
  return [NSString stringWithFormat:@"%@/%@", [[self contentType] type],
                   [[self contentType] subType]];
}

- (NSString *)downloadTarget {
#if 0  
  NSString *t = [[self contentType] subType];

  return ([t isEqualToString:@"plain"]
          || [t isEqualToString:@"html"]
          || [t isEqualToString:@"gif"]
          || [t isEqualToString:@"jpeg"])
    ? [[self context] contextID]
    : @"";
#else
  return [[self context] contextID];
#endif  
}

/* actions */

- (NSString *)_checkFor8Bit:(NSString *)_str {
  unsigned char *c;
  int           len;
  int           i;
  BOOL          changed;

  changed = NO;
  len     = [_str length];
  c       = calloc(len + 6 /* be defensive */, sizeof(id));
  
  [_str getCString:(char *)c];
  for (i = 0; i < len; i++) {
    if (c[i] > 127) {
      c[i] = '_';
      changed = YES;
    }
  }
  if (changed) {
#if LIB_FOUNDATION_LIBRARY
    _str = [NSString stringWithCStringNoCopy:(char *)c length:len
		     freeWhenDone:YES];
#else
    _str = [NSString stringWithCString:c length:len];
    if (c) free(c); c = NULL;
#endif
  }
  else
    if (c) free(c); c = NULL;
  
  return _str;
}

- (id)downloadPart {
  // TODO: split up method
  WOResponse *response;
  id         content;
  NSString   *disposition, *transferEncoding, *fileName, *type;
  
  disposition       = [self contentDisposition];
  transferEncoding  = [self contentTransferEncoding];
  fileName          = [[[self contentType] parametersAsDictionary]
                              objectForKey:@"name"];
  if (![fileName length])
    fileName = nil;
  
  response = [WOResponse responseWithRequest:[[self context] request]];
  [response setStatus:200];

  [response setHeader:[self _checkFor8Bit:[[self contentType] stringValue]]
            forKey:@"content-type"];
  
  content = [self body];
  
  if ([content isKindOfClass:[NSData class]]) {
  }
  else if ([content isKindOfClass:[NSString class]]) {
    BOOL     useUTF8;
    NSString *ct;
    WORequest *req;

    req     = [[self context] request];
    useUTF8 = [[req clientCapabilities] doesSupportUTF8Encoding];

    if (!useUTF8) {
      NSRange r;
      
      r = [[req headerForKey:@"accept-charset"] rangeOfString:@"utf-8"];
      useUTF8 = (r.length > 0) ? YES : NO;
    }
    if (useUTF8) {
      content = [content dataUsingEncoding:NSUTF8StringEncoding
                         allowLossyConversion:YES];
      ct      = @"text/plain; charset=utf-8";
    }
    else {
      content = [content dataUsingEncoding:NSISOLatin1StringEncoding
                         allowLossyConversion:YES];
      ct      = @"text/plain; charset=iso-8859-1";
    }
    [response setHeader:ct forKey:@"content-type"];
  }
  else if ([content isKindOfClass:[NSURL class]]) {
    content = [self contentForURL:content];
  }
  else {
    [(id)[[self context] page]
            setErrorString:
              @"couldn't provide downloadable representation of body"];
    [self logWithFormat:
            @"couldn't provide downloadable representation of body"];
    return nil;
  }
  type = [[self contentType] type];
  if ([type isEqualToString:@"text"] || [type isEqualToString:@"image"]) {
    if (disposition) {
      [response setHeader:[self _checkFor8Bit:[disposition stringValue]]
                forKey:@"content-disposition"];
    }
  }
  else {
    static Class DispClass = Nil;
    id tmp;

    if (DispClass == Nil)
      DispClass = [NGMimeContentDispositionHeaderField class];

    if (![disposition isKindOfClass:DispClass]) {
      disposition =
        [[[DispClass alloc] initWithString:[disposition stringValue]]
                     autorelease];
    }
    tmp = [(NGMimeContentDispositionHeaderField *)disposition filename];

    if (![tmp length])
      tmp = fileName;
    
    if (tmp != nil) {
      tmp = [[tmp componentsSeparatedByString:@"\\"] lastObject];
      tmp = [NSString stringWithFormat:@"attachment; filename=\"%@\"", tmp];
    }
    else
      tmp = @"attachment";
    
      [response setHeader:[self _checkFor8Bit:tmp]
                forKey:@"content-disposition"];
  }
  [response setHeader:[NSString stringWithFormat:@"%d", [content length]]
            forKey:@"content-length"];

  if (transferEncoding) {
    if ([transferEncoding isEqualToString:@"base64"])
      content = [content dataByDecodingBase64];
    else if ([transferEncoding isEqualToString:@"quoted-printable"])
      content = [content dataByDecodingQuotedPrintable];
    else {
      [self logWithFormat:@"Unknown content-transfer-encoding: %@",
              transferEncoding];
    }
  }
  [response setHeader:@"identity" forKey:@"content-encoding"];

  [response setContent:content];
  return response;
}

- (id)buildDocumentBodyForPath {
  id body;
  
  body = [self body];
  if ([body isKindOfClass:[NSString class]])
    body = [body dataUsingEncoding:[NSString defaultCStringEncoding]];
  else if ([body isKindOfClass:[NSURL class]])
    body = [self contentForURL:body];
  return body;
}

- (NSString *)buildDocumentPathForPart {
  NSString *path;
  
  path = [self contentDisposition];
  if ([path length] > 0) {
    NGMimeContentDispositionHeaderField *cd;
    
    cd = [[NGMimeContentDispositionHeaderField alloc]
	   initWithString:[self contentDisposition]];
    path = [[[cd filename] copy] autorelease];
    [cd release]; cd = nil;
  }
  else
    path = nil;
  
  if (path == nil) {
    NGMimeType *ct;
    NSString   *subject;
    
    ct   = [self contentType];
    path = [[ct parametersAsDictionary] objectForKey:@"name"];
    
    if (path == nil) {
      if ([[ct type] isEqualToString:@"text"]) {
	path = ([[ct subType] isEqualToString:@"html"])
	  ? @".html" : @".txt";
      }
      else
	path = [@"." stringByAppendingString:[ct subType]];;
      
      if ((subject = [[self source] valueForKey:@"subject"]) == nil)
	subject = @"<unknown>";
      
      path = [subject stringByAppendingString:path];
    }
  }
#if LIB_FOUNDATION_LIBRARY
  if ([path isKindOfClass:[NSInlineUTF16String class]]) {
    path = [NSString stringWithFormat:@"%@", path];
    /* hack to avoid utf16 string confusings */
  }
#endif
  return path;
}

- (NSString *)buildDocumentTitleForPart {
  id       tmp;
  NSString *subject;

  tmp = [[self source] valueForKey:@"sendDate"];
  if ([tmp respondsToSelector:@selector(descriptionWithCalendarFormat:)])
    tmp = [tmp descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"];
  else
    tmp = @"<unknown>";
      
  if ([tmp length] == 0)
    tmp = @"<unknown>";
  
  subject = [[self source] valueForKey:@"subject"];
  if (![subject isNotNull])
    subject = @"<unknown>";
  
  return [NSString stringWithFormat:@"%@ [%@]", subject, tmp];
}

- (id)toDoc {
  OGoContentPage *page;
  
#if 1
  page = [self pageWithName:@"OGoDocumentImport"];
#else
  // TODO: shouldn't we use a separate page for imports?
  page = [self pageWithName:@"SkyProject4DocumentEditor"];
  [page takeValue:[NSNumber numberWithBool:YES]    forKey:@"isImport"];
#endif
  [page takeValue:[self buildDocumentBodyForPath]  forKey:@"blob"];
  [page takeValue:[self buildDocumentPathForPart]  forKey:@"fileName"];
  [page takeValue:[self buildDocumentTitleForPart] forKey:@"subject"];
  
  // TODO: is this required?
  [[[[self context] valueForKey:@"page"] navigation] enterPage:page];
  return page;
}

/* viewer */

- (WOComponent *)bodyViewerComponent {
  /* TODO: split up this method */
  if (self->bodyViewer)
    return self->bodyViewer;

  self->bodyViewer =
    [[[self session] instantiateComponentForCommand:@"mailview"
                    type:[self contentType]] retain];
  if (self->bodyViewer == nil) {
    NGMimeType *appOctet;

    appOctet = [NGMimeType mimeType:@"application/octet-stream"];
    
    self->bodyViewer = [[[self session]
                               instantiateComponentForCommand:@"mailview"
                               type:appOctet] retain];
  }
  {
    NSData *data;

    data = [self body];

    if ([data isKindOfClass:[NGMimeFileData class]]) {
      
      data = [(SkyDecodeWrapperData *)[SkyDecodeWrapperData alloc]
                                      initWithData:data
                                      encoding:[[self part]
						 valueForKey:@"encoding"]];
      [data autorelease];
    }
    [(id)self->bodyViewer setBody:data];
    [(id)self->bodyViewer setPartOfBody:[self part]];
    [(id)self->bodyViewer setSource:[self source]];
  }
  
  if ([[[self contentType] type] isEqualToString:@"eo-pkey"]) {
    if ([(id)self->bodyViewer object] == nil) {
      ASSIGN(self->bodyViewer, nil);
      self->bodyViewer =
        [[[self session] instantiateComponentForCommand:@"mailview"
                         type:[NGMimeType mimeType:@"eo" subType:@"deleted"]]
                retain];
    }
  }
  return self->bodyViewer;
}

- (BOOL)showBody {
  return self->showBody;
}
- (void)setShowBody:(BOOL)_body {
  self->showBody = _body;
}

- (BOOL)printMode {
  return self->printMode;
}
- (void)setPrintMode:(BOOL)_print {
  self->printMode = _print;
}

- (void)setSource:(id)_source {
  ASSIGN(self->source, _source);
}
- (id)source {
  return self->source;
}

- (BOOL)hasUrl {
  return [[self body] isKindOfClass:[NSURL class]];
}

- (NSString *)downloadPartActionName {
  /* 
     This appends a filename to the download action, this helps with browser
     detection of filenames and filetypes in case the browser does not
     properly work on the content disposition field.
  */
  NSString *name;
  
  if ((name = [[[self->part contentType] parametersAsDictionary]
                            objectForKey:@"name"]))
    return [@"get/" stringByAppendingString:[name stringValue]];
  
  if (CreateMailDownloadFileNamesDisable)
    return @"get";
  
  name = [[self->part contentType] subType];
  return [@"get/download." stringByAppendingString:name];
}

- (NSString *)url {
  if ([[self body] isKindOfClass:[NSURL class]])
    return [[self body] absoluteString];
  return nil;
}
- (NSString *)mimeTypeString {
  return [[self->part contentType] stringValue];
}

- (NSString *)encodingString {
  return [[self->part encoding] stringValue];
}

- (NSString *)partUrl {
  return [[self body] query];
}

- (BOOL)showBodyDepSize {
  if (ShowBodyDependingSizeDisable)
    return YES;
  
  if ([self showBodyDepSizeVar])
    return [[self showBodyDepSizeVar] boolValue];
  
  if ([[[self->part contentType] type] isEqualToString:@"application"])
    return NO;
  
  if (([[self contentLength] intValue] > ShowBodySize))
    return NO;
  
  return YES;
}

- (BOOL)isImageViewerComponent:(WOComponent *)_component {
  return [_component isKindOfClass:[LSWImageBodyViewer class]];
}

- (BOOL)showBodyDepSizeEnabled {
  BOOL       viewImageInline;
  
  viewImageInline =
    [[[self session] userDefaults] boolForKey:@"mail_viewImagesInline"];
  
  if ([self isImageViewerComponent:[self bodyViewerComponent]]
      && !viewImageInline) {
    return NO;
  }
  return ShowBodyDependingSizeDisable ? NO : YES;
}

- (NSString *)partKey {
  NSString *key;
  
  if ((key = [self url]) == nil) {
    char buf[32];
    
    // TODO: better use some part hier-id?
    sprintf(buf, "%p", [self body]); 
    key = [NSString stringWithCString:buf];
  }
  return key;
}

- (NSNumber *)showBodyDepSizeVar {
  NSMutableDictionary *cache;
  
  cache = [[self session] valueForKey:@"ShowBodyPartsCache"];
  if (cache == nil) {
    cache = [NSMutableDictionary dictionaryWithCapacity:64];
    [[self session] takeValue:cache forKey:@"ShowBodyPartsCache"];
  }
  return [cache objectForKey:[self partKey]];
}

- (void)setShowBodyDepSizeVar:(NSNumber *)_n {
  NSMutableDictionary *cache;

  cache = [[self session] valueForKey:@"ShowBodyPartsCache"];

  if (!cache) {
    cache = [NSMutableDictionary dictionaryWithCapacity:64];
    [[self session] takeValue:cache forKey:@"ShowBodyPartsCache"];
  }
  [cache takeValue:_n forKey:[self partKey]];
}

- (id)alternateShowBody {
  NSNumber *n;
  
  n = ((n = [self showBodyDepSizeVar]) != nil)
    ? [NSNumber numberWithBool:[n boolValue]          ? NO : YES]
    : [NSNumber numberWithBool:[self showBodyDepSize] ? NO : YES];
  
  [self setShowBodyDepSizeVar:n];
  return nil;
}

@end /* LSWMimePartViewer */

/* categories */

@implementation NSObject(ViewerSelection)

- (NSString *)lswPartViewer {
  return @"LSWMimePartViewer";
}

@end /* NSObject(ViewerSelection) */

@implementation NGMimeBodyPart(ViewerSelection)

- (NSString *)lswPartViewer {
  return @"LSWMimeBodyPartViewer";
}

@end /* NGMimeBodyPart(ViewerSelection) */

@implementation NGMimeMessage(ViewerSelection)

- (NSString *)lswPartViewer {
  //return @"LSWMimeMessageViewer";
  //return @"LSWMimeBodyPartViewer";
  return @"SkyMessageRfc822Viewer";
}

@end /* NGMimeMessage(ViewerSelection) */

@implementation WOSession(ViewerSelection)

- (NSString *)viewerComponentForPart:(id)_part {
  return [_part lswPartViewer];
}

@end /* WOSession(ViewerSelection) */
