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

#include "LSWDocumentMailPage.h"
#import "common.h"
#include <NGMime/NGMimeHeaderFields.h>

@implementation LSWDocumentMailPage

- (NSString *)entityName {
  return @"Doc";
}

- (NSString *)getCmdName {
  return @"doc::get";
}

- (NSString *)objectUrlKey {
  return [NSString stringWithFormat:
                     @"wa/LSWViewAction/viewDocument?documentId=%@",
                     [[self object] valueForKey:@"documentId"]];
}

- (NSString *)path {
  id             obj;
  NSMutableArray *folders;
  id             pFolder;
  NSString       *path;

  obj     = [self object];
  folders = [[NSMutableArray alloc] init]; 
  pFolder = [obj valueForKey:@"toParentDocument"];
  
  if ([pFolder isNotNull]) {  
    while ([pFolder isNotNull]) {
      [folders insertObject:[pFolder valueForKey:@"title"] atIndex:0];
      pFolder = [pFolder valueForKey:@"toParentDocument"];
    };
    [folders addObject:[obj valueForKey:@"title"]];
    path = [folders componentsJoinedByString:@" / "];

    RELEASE(folders); folders = nil;
  
    return path;
  }
  return @"";
}

- (NSString *)objectTitle {
  id       obj    = [self object];
  NSString *title = [self path];

  if ([[obj valueForKey:@"isFolder"] boolValue]) {
    return title;
  }
  return [title stringByAppendingPathExtension:[obj valueForKey:@"fileType"]];
}

- (NGMimeType *)objectDataType {
  id obj = [self object];  

  if (![[obj valueForKey:@"isFolder"] boolValue]) {
    NSString     *fName;
    NSString     *fileType;
    NSDictionary *mimeTypes;
    NGMimeType   *mType     = nil;
    NSString     *mt        = nil;
    
    fName     = [obj valueForKey:@"title"];
    fileType  = [obj valueForKey:@"fileType"];
    mimeTypes = [[[self session] userDefaults] dictionaryForKey:@"LSMimeTypes"];
    
    mt    = [mimeTypes objectForKey:fileType];
    fName = [fName stringByAppendingPathExtension:fileType];

    if (mt != nil) {
      mType = [NGMimeType mimeType:mt];
    }

    if (mType != nil) {
      return [NGMimeType mimeType:[mType type] subType:[mType subType]
                         parameters:[NSDictionary dictionaryWithObject:fName
                                                  forKey:@"name"]];
    }
    else {
      return [NGMimeType mimeType:@"application" subType:@"octet-stream"
                         parameters:[NSDictionary dictionaryWithObject:fName
                                                  forKey:@"name"]];
    }
  }
  return [super objectDataType];
}

- (NGMimeContentDispositionHeaderField *)objectDataContentDisposition {
  NGMimeContentDispositionHeaderField *cdField = nil;
  NSString *fName, *ext, *s;
  id obj;
  
  obj = [self object];
  if ([[obj valueForKey:@"isFolder"] boolValue])
    return [super objectDataContentDisposition];
  
  fName = [obj valueForKey:@"title"];
  ext   = [obj valueForKey:@"fileType"];
  fName = [fName stringByAppendingPathExtension:ext];
  
  s = [NSString stringWithFormat:@"%@; filename=\"%@\"",
                  NGMimeContentDispositionInlineType, fName];
  cdField = [[NGMimeContentDispositionHeaderField alloc] initWithString:s];
  return [cdField autorelease];
}

- (BOOL)isContactAttrEnabled {
  return [[[self session] userDefaults]
                 boolForKey:@"SkyEnableContactAttrInDocuments"];
}

- (NSData *)objectData {
  NSString *p;
  id obj = nil;
  
  if (!self->attachData) {
    static NSData *emptyData = nil;
    if (emptyData == nil) emptyData = [[NSData alloc] init];
    return emptyData;
  }

  obj = [self object];
  [obj run:@"doc::get-attachment-name", nil];
  p = [obj valueForKey:@"attachmentName"];
  if (![p isNotNull]) {
    [self logWithFormat:@"got no attachment name for object: %@", obj];
    return nil;
  }
  return [NSData dataWithContentsOfMappedFile:p];
}

- (id)viewObject {
  id result = nil;
  id obj    = [self object];
  id page   = [[[[self context] valueForKey:@"page"] navigation] activePage];

  if ([[obj valueForKey:@"isFolder"] boolValue]) {
    result = [self runCommand:@"project::get",
                   @"projectId",  [obj valueForKey:@"projectId"],
                   @"returnType", intObj(LSDBReturnType_OneObject), nil];

    if ([(NSArray *)result count] == 1) {
      result = [result lastObject];
      [result takeValue:obj forKey:@"currentFolder"];

      return [self activateObject:result withVerb:@"view"];
    }
    else {
      [page setErrorString:@"No project to view for document available."];
    }
  }
  else {
    return [super viewObject];
  }
  return nil;
}

@end

@implementation LSWDocumentHtmlMailPage
@end

@implementation LSWDocumentTextMailPage
@end
