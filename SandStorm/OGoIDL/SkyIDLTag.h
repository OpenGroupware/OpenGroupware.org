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

#ifndef __SkyIDL_SkyIDLTag_H__
#define __SkyIDL_SkyIDLTag_H__

#import <Foundation/NSObject.h>
#import <SaxObjC/SaxAttributes.h>

@class NSString, NSDictionary, NSMutableDictionary, NSMutableString;
@class SkyIDLDocumentation, SkyIDLInterface;

@interface SkyIDLTag : NSObject
{
  NSString            *namespace;
  NSMutableDictionary *extraAttributes;
  SkyIDLDocumentation *documentation;
}

/* accessors */
- (SkyIDLDocumentation *)documentation;
- (NSArray *)extraAttributeNames;
- (NSString *)extraAttributeWithName:(NSString *)_name;

@end

@interface SkyIDLTag(SkyIDLSaxBuilder)
- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_namespaces;
- (NSString *)tagName;
- (NSString *)namespace;
- (BOOL)isTagAccepted:(SkyIDLTag *)_tag;
- (BOOL)addTag:(SkyIDLTag *)_tag;
- (void)setCharacters:(NSString *)_characters;
- (void)prepareWithInterface:(SkyIDLInterface *)_interface;
- (NSArray *)qnamedExtraAttributes; // e.g. ({some-uri}arrayType, ...)
@end /* SkyIDLTag(SkyIDLSaxBuilder) */

@interface SkyIDLTag(SkyIDLSaxBuilder_PrivateMethods)
- (BOOL)_insertTag:(SkyIDLTag *)_tag intoDict:(NSMutableDictionary *)_dict;
- (NSString *)copy:(NSString *)_key
             attrs:(id<SaxAttributes>)_attrs
                ns:(NSDictionary *)_ns;
- (void)append:(NSString *)_value
          attr:(NSString *)_attrName
      toString:(NSMutableString *)_str;

- (void)_prepareTags:(id)_tags withInterface:(SkyIDLInterface *)_interface;
- (NSString *)_getQNameFrom:(NSString *)_value ns:(NSDictionary *)_ns;

@end /* SkyIDLTag(SkyIDLSaxBuilder_PrivateMethods) */

#endif /* __SkyIDL_SkyIDLTag_H__ */
