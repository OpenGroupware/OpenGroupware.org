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

#include <NGExtensions/NGFileManager.h>
#include <OGoDocuments/SkyDocumentFileManager.h>
#include <OGoDocuments/SkyDocument.h>
#include "common.h"

/*
  JavaScript

    Properties

    Methods

      Object loadDocument(String path)
      bool   saveDocument(document [,newpath])
      Object newDocument([String path] [,String blob] [,Dictionary attributes])
*/

@interface NGFileManager(DocCreation)

- (BOOL)writeDocument:(SkyDocument *)_doc toPath:(NSString *)_path;

- (SkyDocument *)createDocumentAtPath:(NSString *)_path
  contents:(NSData *)_data
  attributes:(NSDictionary *)_attrs;

@end

@implementation NGFileManager(DocJSSupport)

static NSNumber *boolYes = nil;
static NSNumber *boolNo  = nil;

static void _ensureBools(void) {
  if (boolYes == nil) boolYes = [[NSNumber numberWithBool:YES] retain];
  if (boolNo  == nil) boolNo  = [[NSNumber numberWithBool:NO]  retain];
}

/* documents */

- (id)_jsfunc_loadDocument:(NSArray *)_args {
  unsigned count;
  NSString *path;
  id doc;
  
  if ((count = [_args count]) == 0)
    return nil;
  
  path = [[_args objectAtIndex:0] stringValue];
  
  if (![self supportsFeature:NGFileManagerFeature_Documents atPath:path]) {
    /* NGFileManager subclass doesn't support documents ... */
    return nil;
  }
  
  doc = [(id<SkyDocumentFileManager>)self documentAtPath:path];
  
  return doc;
}

- (id)_jsfunc_saveDocument:(NSArray *)_args {
  unsigned count;
  NSString *path;
  id       doc;
  _ensureBools();

  if (![self respondsToSelector:@selector(writeDocument:toPath:)])
    return nil;
  
  if ((count = [_args count]) == 0)
    return nil;
  else if (count == 1) {
    doc  = [_args objectAtIndex:0];
    path = [doc valueForKey:@"NSFilePath"];
  }
  else {
    doc  = [_args objectAtIndex:0];
    path = [_args objectAtIndex:1];
  }
  
  if (![self supportsFeature:NGFileManagerFeature_Documents atPath:path]) {
    /* NGFileManager subclass doesn't support documents ... */
    return nil;
  }
  
  if ([self writeDocument:doc toPath:path]) {
#if DEBUG
    NSLog(@"%s: saved document %@ to path %@", __PRETTY_FUNCTION__, doc, path);
#endif
    return boolYes;
  }
  else {
#if DEBUG && 0
    NSLog(@"%s: couldn't save document %@ to path %@: %@",
          __PRETTY_FUNCTION__, doc, path, [(id)self lastException]);
#endif
    return boolNo;
  }
}

- (id)_jsfunc_newDocument:(NSArray *)_args {
  unsigned     count;
  NSString     *path;
  NSData       *blob;
  NSDictionary *attrs;
  
  if (![self respondsToSelector:
               @selector(createDocumentAtPath:contents:attributes:)])
    return nil;
  
  path  = nil;
  blob  = nil;
  attrs = nil;
  
  count = [_args count];
  
  if (count > 0)
    path = [_args objectAtIndex:0];
  
  if (![self supportsFeature:NGFileManagerFeature_Documents atPath:path]) {
    /* NGFileManager subclass doesn't support documents ... */
    return nil;
  }
  
  if (count > 1) {
    id tmp;
    
    tmp = [_args objectAtIndex:1];
    if ([tmp isKindOfClass:[NSData class]])
      blob = tmp;
    else if ([tmp respondsToSelector:@selector(dataUsingEncoding:)])
      blob = [tmp dataUsingEncoding:NSISOLatin1StringEncoding];
    else {
      tmp = [tmp stringValue];
      blob = [tmp dataUsingEncoding:NSISOLatin1StringEncoding];
    }
  }

  if (count > 2) {
    attrs = [_args objectAtIndex:2];
    
    if (![attrs isKindOfClass:[NSDictionary class]]) {
      if ([attrs respondsToSelector:@selector(asDictionary)]) {
        attrs = [(id)attrs asDictionary];
      }
      else {
        NSLog(@"%s: invalid attributes object as argument !",
              __PRETTY_FUNCTION__);
        return nil;
      }
    }
  }
  
  return [self createDocumentAtPath:path
               contents:blob attributes:attrs];
}

@end /* NGFileManager(DocJSSupport) */
