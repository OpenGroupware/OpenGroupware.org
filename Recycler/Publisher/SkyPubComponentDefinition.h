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

#ifndef __SkyPubComponentDefinition_H__
#define __SkyPubComponentDefinition_H__

#import <Foundation/NSObject.h>

@class NSString, NSArray;
@class WOElement, WOComponent, WOResourceManager;

@interface SkyPubComponentDefinition : NSObject
{
  NSString  *cname;
  NSString  *path;
  Class     componentClass;
  id        fileManager;
  NSString  *renderFactoryName;
  
  WOElement *template;
  id        domDocument;
}

- (id)initWithName:(NSString *)_name path:(NSString *)_path
  baseURL:(NSString *)_baseURL frameworkName:(NSString *)_fwname;

/* accessors */

- (void)setComponentName:(NSString *)_name;
- (NSString *)componentName;
- (void)setComponentClass:(Class)_class;
- (Class)componentClass;

- (WOElement *)template;

- (void)setFileManager:(id)_fm;
- (id)fileManager;

/* template loading */

- (void)setRenderFactoryName:(NSString *)_name;
- (NSString *)renderFactoryName;
- (BOOL)load;

/* instantiation */

- (WOComponent *)instantiateWithResourceManager:(WOResourceManager *)_rm
  languages:(NSArray *)_languages;

@end

#endif /* __SkyPubComponentDefinition_H__ */
