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

#ifndef __SkyForms_used_privates_H__
#define __SkyForms_used_privates_H__

@interface WOComponent(PrivateMethods)
- (NSDictionary *)_bindings;
@end

@interface WOComponent(Privates)
- (BOOL)isScriptedComponent;
- (id)scriptedComponentWithName:(NSString *)_name;
- (void)setName:(NSString *)_name;
- (void)setSubComponents:(NSDictionary *)_children;
- (void)setTemplate:(WOElement *)_template;
@end

@interface WOElement(ComponentFault)
- (id)initWithResourceManager:(WOResourceManager *)_rm
  pageName:(NSString *)_name
  languages:(NSArray *)_langs
  bindings:(NSDictionary *)_bindings;
@end

@interface NSObject(MiscPrivates)
+ (BOOL)isDynamicElement;
@end

@interface WOElement(JSScripts)
- (NSArray *)jsScripts;
- (id)evaluateJavaScript:(NSString *)_script;
@end

@interface WODynamicElement(CompoundElems)
+ (id)allocForCount:(unsigned)_count zone:(NSZone *)_zone;
- (id)initWithContentElements:(NSArray *)_elems;
@end

#endif /* __SkyForms_used_privates_H__ */
