/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include "SkyPubInlineViewer.h"

@class SkyPubResourceManager;

@interface SkyPubPartPreview : SkyPubInlineViewer
{
  SkyPubResourceManager *crm;
}

@end

#include "SkyPubComponentDefinition.h"
#include "SkyPubComponent.h"
#include "SkyDocument+Pub.h"
#include "PubKeyValueCoding.h"
#include "SkyPubResourceManager.h"
#include "common.h"

@interface SkyPubResourceManager(UsedPrivates)
- (SkyPubComponentDefinition *)definitionForComponent:(NSString *)_name 
  languages:(NSArray *)_langs;
@end

@implementation SkyPubPartPreview

- (void)dealloc {
  [self->crm release];
  [super dealloc];
}

/* accessors */

- (BOOL)isTemplate {
  BOOL isTemplate = NO;

  isTemplate = [[[self document] npsDocumentType] isEqualToString:@"template"];
  
  return isTemplate;
}

- (SkyPubResourceManager *)pubResourceManager {
  if (self->crm == nil) {
    id fm;

    if ((fm = [self fileManager]) == nil) {
      [self logWithFormat:@"missing filemanager !!!"];
      return nil;
    }
    
    self->crm = [[SkyPubResourceManager alloc] initWithFileManager:fm];
  }
  if (self->crm == nil)
    [self logWithFormat:@"got no resource manager !!!"];
  
  return self->crm;
}

- (SkyPubComponentDefinition *)definitionForComponent:(NSString *)_name {
  return [[self pubResourceManager]
                definitionForComponent:_name languages:nil];
}

- (SkyPubComponent *)previewComponent {
  SkyPubComponentDefinition *cdef;
  NSString *dpath;
  id c;

  dpath = [[self document] valueForKey:@"NSFilePath"];
  
  if ((cdef = [self definitionForComponent:dpath]) == nil) {
    [self debugWithFormat:@"got no component definition for path '%@'",dpath];
    return nil;
  }
  
  [cdef setRenderFactoryName:@"SkyPubPreviewNodeRenderFactory"];

  if ((c = [cdef instantiateWithResourceManager:[self pubResourceManager]
                 languages:nil]) == nil) {
    [self debugWithFormat:@"couldn't instantiate component for path '%@'",
            dpath];
    return nil;
  }
  
  return c;
}

- (id)odrSourceFactory {
  static id factory = nil;
  
  if (factory == nil) {
    factory =
      [[NSClassFromString(@"SkyPubSourceNodeRenderFactory") alloc] init];
  }
  
  return factory;
}
- (id)odrPreviewFactory {
  static id factory = nil;

  if (factory == nil) {
    factory =
      [[NSClassFromString(@"SkyPubPreviewNodeRenderFactory") alloc] init];
  }
  
  return factory;
}

- (id)odrFactory {
  return [self isTemplate]
    ? [self odrSourceFactory]
    : [self odrPreviewFactory];
}

@end /* SkyPubPartPreview */
