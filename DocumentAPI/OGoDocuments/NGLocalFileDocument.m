/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "NGLocalFileDocument.h"
#include "NGLocalFileManager.h"
#include "NGLocalFileGlobalID.h"
#include <NGExtensions/NGFileManager.h>
#include <NGExtensions/NSFileManager+Extensions.h>
#include "common.h"

@implementation NGLocalFileDocument

static NSDictionary *mimeTypes  = nil;
static BOOL debugContentAccess  = NO;
static int  maxContentCacheSize       = 32000;
static int  maxContentStringCacheSize = 32000;

- (id)initWithPath:(NSString *)_path fileManager:(id)_fm {
  return [self initWithPath:_path fileManager:_fm context:nil];
}

- (id)_isDictPathContext:(NSDictionary *)_ctx {
  NSDictionary *attr;
  
  if (![_ctx isKindOfClass:[NSDictionary class]])
    return nil;
  if ((attr = [_ctx objectForKey:[self->path lastPathComponent]]) == nil)
    return nil;
  if (![attr isKindOfClass:[NSDictionary class]])
    return nil;
  if ([attr count] < 2)
    return nil;
  return attr;
}

- (id)initWithPath:(NSString *)_path fileManager:(id)_fm context:(id)_ctx {
  if ((self = [super init])) {
    id attr;
    
    if ((self->globalID = [[_fm globalIDForPath:_path] retain]) == nil) {
      [self logWithFormat:@"WARNING: got no global-id for path: %@", _path];
      [self release];
      return nil;
    }
    self->path = [[[_fm currentDirectoryPath]
		        stringByAppendingPathComponent2:_path] copy];
    if (self->path == nil) {
      [self release];
      return nil;
    }
    self->fm = [_fm retain];
    
    if ((attr = [self _isDictPathContext:_ctx]))
      self->attributes = [attr retain];
    else {
      self->attributes = 
	[[self->fm fileAttributesAtPath:self->path traverseLink:NO] retain];
    }
  }
  return self;
}

- (id)initWithGlobalID:(EOGlobalID *)_gid {
  return [self initWithGlobalID:_gid context:nil];
}

- (id)initWithGlobalID:(EOGlobalID *)_gid context:(id)_ctx {
  if ((self = [super init])) {
    id attr;

    if (_gid == nil) {
      [self logWithFormat:@"WARNING: missing global-id parameter !"];
      [self release];
      return nil;
    }
    self->path     = [[(NGLocalFileGlobalID *)_gid path] copy];
    self->globalID = [_gid retain];
    self->fm       =
      [[NGLocalFileManager alloc] initWithRootPath:
                                  [(NGLocalFileGlobalID *)_gid rootPath]
                                  allowModifications:NO];
    if ((attr = [self _isDictPathContext:_ctx]) != nil)
      self->attributes = [attr retain];
    else {
      self->attributes = 
	[[self->fm fileAttributesAtPath:self->path traverseLink:NO] retain];
    }
  }
  return self;
}

- (void)dealloc {
  [self->contentDOM    release];
  [self->content       release];
  [self->contentString release];
  
  [self->globalID   release];
  [self->path       release];
  [self->fm         release];
  [self->attributes release];
  [super dealloc];
}

/* accessors */

- (EOGlobalID *)globalID {
  return self->globalID;
}

- (id)fileManager {
  return self->fm;
}

- (void)setContent:(NSData *)_blob {
  // TODO
}
- (NSData *)content {
  NSData *data;
  
  if (self->content) /* cached ? */
    return self->content;
  if (self->fm == nil)
    [self logWithFormat:@"ERROR: missing filemanager !"];
  
  data = [self->fm contentsAtPath:self->path];
  if ((int)[data length] < maxContentCacheSize) /* cache */
    self->content = [data retain];
  return data;
}

- (void)setContentString:(NSString *)_blob {
}
- (NSString *)contentAsString {
  NSString *s;

  if (debugContentAccess) [self logWithFormat:@"get content string ..."];
  if (self->contentString) /* cached ? */
    return self->contentString;
  
  s = [[NSString alloc]
	    initWithData:[self content]
	    encoding:[NSString defaultCStringEncoding]];
  if (debugContentAccess) [self logWithFormat:@"  content: %@", s];
  if ((int)[s length] < maxContentStringCacheSize) /* cache */
    self->contentString = [s retain];
  return [s autorelease];
}

- (NSString *)subject {
  return [self->attributes objectForKey:@"NSFileSubject"];
}

- (NSString *)path {
  return self->path;
}

- (NSDictionary *)attributes {
  return self->attributes;
}

- (NSDictionary *)fileAttributes {
  return self->attributes;
}

- (NSString *)contentType {
  NSString *mt, *ext;
  
  if ((mt = [self->attributes valueForKey:@"NSFileMimeType"]))
    /* explicitly stored type ... */
    return mt;

  /* check by file extension */
  
  if ((ext = [[self path] pathExtension]) == nil)
    return @"text/plain";
  
  if (mimeTypes == nil) {
    mimeTypes = [[[NSUserDefaults standardUserDefaults] 
                                  dictionaryForKey:@"LSMimeTypes"] copy];
    if (mimeTypes == nil) {
      NSLog(@"Note: LSMimeTypes default not set (LSBase not loaded?)");
      mimeTypes = [[NSDictionary alloc] init];
    }
  }
  
  if ((mt = [mimeTypes objectForKey:ext]))
    return mt;
  
  /* some hardcoded types, TODO: add systemwide registry in NGExtensions */
  if ([ext isEqualToString:@"html"])  return @"text/html";
  if ([ext isEqualToString:@"css"])   return @"text/css";
  if ([ext isEqualToString:@"txt"])   return @"text/plain";
  if ([ext isEqualToString:@"xhtml"]) return @"text/xhtml";
  if ([ext isEqualToString:@"xml"])   return @"text/xml";
  if ([ext isEqualToString:@"gif"])   return @"image/gif";
  if ([ext isEqualToString:@"jpg"])   return @"image/jpg";
  if ([ext isEqualToString:@"png"])   return @"image/png";
  if ([ext isEqualToString:@"xtmpl"]) return @"skyrix/xtmpl";
  if ([ext isEqualToString:@"wox"])   return @"skyrix/wox";
  
  return @"application/octet-stream";
}

/* KVC */

- (id)valueForKey:(NSString *)_key {
  unsigned len;
  
  if ((len = [_key length]) == 0)
    return nil;
  
  switch (len) {
  case 4: {
    unichar c1 = [_key characterAtIndex:0];
    if (c1 == 'p' && [@"path" isEqualToString:_key])
      return [self path];
    if (c1 == 'n' && [@"name" isEqualToString:_key])
      return [[self path] lastPathComponent];
    if (c1 == 's' && [@"self" isEqualToString:_key])
      return self;
    break;
  }
    
  case 10:
    if ([_key characterAtIndex:0] == 'N') {
      if ([_key isEqualToString:@"NSFilePath"])
	return [self path];
      if ([_key isEqualToString:@"NSFileName"])
	return [[self path] lastPathComponent];
    }
    break;
    
  case 14:
    if ([_key characterAtIndex:0] == 'N') {
      if ([_key isEqualToString:@"NSFileMimeType"])
	return [self contentType];
    }
    break;
  }
  
  /* 
     HH: does someone know, why don't we call [super valueForKey:] if
         we miss the attribute ? Security ?
  */
  return [self->attributes objectForKey:_key];
}

/* mimic dictionary */

- (id)objectForKey:(id)_key {
  return [self valueForKey:[_key stringValue]];
}

/* SkyDocument feature query */

- (BOOL)supportsFeature:(NSString *)_featureURI {
  if ([_featureURI isEqualToString:SkyDocumentFeature_BLOB])
    return YES;
  if ([_featureURI isEqualToString:SkyDocumentFeature_STRINGBLOB])
    return YES;
  if ([_featureURI isEqualToString:SkyDocumentFeature_DOMBLOB])
    return YES;
  
  return NO;
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<NGLocalFileDocument %@>",
                   [self path]];
}

@end /* NGLocalFileDocument */

@implementation NGLocalFileDocument(JSSupport)

static NSNumber *yesNum = nil;
static NSNumber *noNum  = nil;

static void _ensureBools(void) {
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  if (noNum  == nil) noNum  = [[NSNumber numberWithBool:NO]  retain];
}

- (id)_jsprop_path {
  return [self path];
}
- (id)_jsprop_name {
  return [self valueForKey:@"NSFileName"];
}

- (id)_jsprop_isDirectory {
  _ensureBools();
  return [[self valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory]
    ? yesNum : noNum;
}

@end /* NGLocalFileDocument(JSSupport) */
