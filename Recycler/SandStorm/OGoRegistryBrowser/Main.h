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

#ifndef __SandStorm_Main_H__
#define __SandStorm_Main_H__

#include <NGObjWeb/WOComponent.h>

@class NSString, NSDictionary, NSArray;
@class SxComponentRegistry, SxXmlRpcComponent;
@class ComponentList;

@interface Main : WOComponent
{
  SxComponentRegistry    *registry;
  SxXmlRpcComponent      *componentInfo;
  ComponentList          *componentList;
  NSMutableDictionary    *state;
  NSArray                *componentNames;
  NSArray                *methods;
  NSArray                *components;
  NSArray                *currentPath;
  
  NSString               *component;
  NSString               *newComponentName;
  NSString               *newComponentURL;
  NSString               *currentPathString;
  NSString               *errorMessage;
  
  BOOL                   addMode;
  BOOL                   gotComponent;  
  BOOL                   hasError;
}
  
- (void)setCurrentPath:(NSArray *)_path;
- (NSArray *)currentPath;

- (void)setIsZoom:(BOOL)_flag;
- (BOOL)isZoom;

- (BOOL)isEndpoint;

- (BOOL)hasError;
- (void)setErrorMessage:(NSString *)_message;
- (NSString *)errorMessage;

- (NSString *)currentPathString;
  
- (void)setRegistry:(SxComponentRegistry *)_registry;
- (SxComponentRegistry*)registry;

- (void)setComponentInfo:(SxXmlRpcComponent *)_info;
- (SxXmlRpcComponent *)componentInfo;

- (void)setMethods:(NSArray *)_methods;
- (NSArray *)methods;

- (void)setComponent:(NSString *)_component;
- (NSString *)component;

- (void)setNewComponentName:(NSString *)_name;
- (NSString *)newComponentName;

- (void)setNewComponentURL:(NSString *)_url;
- (NSString *)newComponentURL;

- (NSArray *)components;
- (NSString *)componentURL;

- (BOOL)addMode;
- (BOOL)gotComponent;

- (NSArray *)rootElements;

/* actions */

- (id)getComponent;
- (id)addComponent;
- (id)addNewComponent;
- (id)removeComponent;
- (id)runMethod;

@end /* Main */

#endif /* __SandStorm_Main_H__ */
