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

#ifndef __SkyComponentDefinition_H__
#define __SkyComponentDefinition_H__

#import <Foundation/NSObject.h>
#include <SaxObjC/SaxContentHandler.h>
#include <SaxObjC/SaxErrorHandler.h>
#include <SaxObjC/SaxXMLReader.h>

@class NSString, NSData, NSArray, NSMutableSet, NSMutableDictionary;
@class WOElement, WOComponent, WOResourceManager;

@interface SkyComponentDefinition : NSObject
{
  NSString  *cname;
  NSString  *path;
  Class     componentClass;
  
  WOElement *template;
  id        domDocument;
  
  /* input configuration */
  id<NSObject,SaxXMLReader> parser;
}

/* accessors */

- (void)setComponentName:(NSString *)_cname;
- (NSString *)componentName;
- (void)setComponentClass:(Class)_class;
- (Class)componentClass;

- (WOElement *)template;

- (void)setParser:(id<NSObject,SaxXMLReader>)_parser;
- (id<NSObject,SaxXMLReader>)parser;

/* loading */

- (BOOL)loadFromSource:(id)_source;
- (BOOL)load;

/* component creation */

- (WOComponent *)instantiateWithResourceManager:(WOResourceManager *)_rm
  languages:(NSArray *)_languages;

@end

#endif /* __SkyComponentDefinition_H__ */
