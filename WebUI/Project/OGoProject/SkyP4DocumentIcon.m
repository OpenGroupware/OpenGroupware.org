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

#include <NGObjWeb/WODynamicElement.h>

@interface SkyP4DocumentIcon : WODynamicElement
{
  WOAssociation *projectName;
  WOAssociation *documentPath;
  WOAssociation *mimeType;
}

@end

#include <NGMime/NGMimeType.h>
#include "common.h"
#include <NGExtensions/NSString+Ext.h>

@implementation SkyP4DocumentIcon

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_assocs
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_assocs template:_t])) {
    self->projectName  = [[_assocs objectForKey:@"projectName"]  copy];
    self->documentPath = [[_assocs objectForKey:@"documentPath"] copy];
    self->mimeType     = [[_assocs objectForKey:@"mimeType"]     copy];
  }
  return self;
}

- (void)dealloc {
  [self->mimeType     release];
  [self->projectName  release];
  [self->documentPath release];
  [super dealloc];
}

/* generating response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOResourceManager *rm;
  NSString   *path, *src;
  NSString   *mType = nil, *mmType = nil;
  NSString   *key;
  NSArray    *langs;
  NGMimeType *nMType;

  src   = nil;
  rm    = [[WOApplication application] resourceManager];
  langs = [[_ctx session] languages];
  path  = [self->documentPath stringValueInComponent:[_ctx component]];
  mType = [self->mimeType     stringValueInComponent:[_ctx component]];

  if (mType == nil)
    mType = @"application/octet-stream";
  
  /* check for special link icons */
  
  if ([mType isEqualToString:@"x-skyrix/filemanager-link"]) {
    NSString *pext;
    
    pext = [[path pathExtension] lowercaseString];
    pext = [@"link_" stringByAppendingString:pext];
    pext = [pext stringByAppendingString:@".gif"];
    
    src = [rm urlForResourceNamed:pext
              inFramework:nil
              languages:langs
              request:[_ctx request]];
  }
  
  /* check for mimeicon_type_subtype_16x19.gif */

  nMType = [NGMimeType mimeType:mType];
  mmType = [[nMType type] stringByReplacingString:@"-" withString:@"_"];
  
  if (src == nil) {
    NSString *msType;
    
    msType = [[nMType subType] stringByReplacingString:@"-" withString:@"_"];
    
    key = [NSString stringWithFormat:
                      @"mimeicon_%@_%@_16x19.gif", mmType, msType];
    
    src = [rm urlForResourceNamed:key
              inFramework:nil
              languages:langs
              request:[_ctx request]];
  }

  /* check for mimeicon_type_16x19.gif (without subtype) */
  
  if (src == nil) {
    NSLog(@"%s: did not find mime-icon '%@'", __PRETTY_FUNCTION__, key);
    
    key = [NSString stringWithFormat:@"mimeicon_%@_16x19.gif", mmType];
    
    src = [rm urlForResourceNamed:key inFramework:nil
              languages:langs request:[_ctx request]];
  }
  
  /* check for document_extension.gif */
  
  if (src == nil) {
    key = [NSString stringWithFormat:@"document_%@.gif", [path pathExtension]];

    src = [rm urlForResourceNamed:key
              inFramework:nil
              languages:langs
              request:[_ctx request]];
  }

  /* fallback to document_unknown.gif */
  
  if (src == nil) {
    src = [rm urlForResourceNamed:@"document_unknown.gif"
              inFramework:nil
              languages:langs
              request:[_ctx request]];
  }
  
  if ([src length] > 0) {
    [_response appendContentString:@"<img src=\""];
    [_response appendContentString:src];
    [_response appendContentString:@"\" alt=\""];
    [_response appendContentHTMLAttributeValue:path];
    [_response appendContentString:
                 @"\" border='0' align='bottom' height='16' width='19' />"];
  }
  else {
    [_response appendContentHTMLString:[path lastPathComponent]];
  }
}

@end /* SkyP4DocumentIcon */
