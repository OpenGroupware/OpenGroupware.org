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

#include "NGXmlRpcAction+Introspection.h"
#include <OGoIDL/SkyIDL.h>
#include <NGXmlRpc/WODirectAction+XmlRpcIntrospection.h>
#include "common.h"

#define SkyXmlRpcTypesNS @"http://www.skyrix.com/od/xmlrpc-types"

@interface NSString(SkyIDLXML)
- (NSString *)uriFromQName;
- (NSString *)valueFromQName;
@end /* NSString(Xml) */

@interface NGXmlRpcAction(IntrospectionPrivateMethods)
- (NSDictionary *)_signatureDictWithInterface:(SkyIDLInterface *)_interface
  andComponentName:(NSString *)_cName;
- (NSDictionary *)_infoDictWithInterface:(SkyIDLInterface *)_interface
  andComponentName:(NSString *)_cName;
@end

@implementation NGXmlRpcAction(Introspection)

static NSMutableDictionary *key2signatureDict = nil;
static NSMutableDictionary *key2infoDict      = nil;

- (NSString *)cacheKey {
  return NSStringFromClass([self class]);
}

- (void)registerInterfaceAtPath:(NSString *)_path
  forComponentName:(NSString *)_cName
  returnIfAlreadySet:(BOOL)_retIfSet
{
  NSString *key;
  
  key = [self cacheKey];

  if (_retIfSet)
    if ([key2signatureDict objectForKey:key]) return;
  
  if (key2signatureDict == nil)
    key2signatureDict = [[NSMutableDictionary alloc] initWithCapacity:32];

  if (key2infoDict == nil)
    key2infoDict = [[NSMutableDictionary alloc] initWithCapacity:32];
  
  {
    SkyIDLInterface *interface;
    NSDictionary    *dict;
    
    interface = [SkyIDLSaxBuilder parseInterfaceFromContentsOfFile:_path];
    dict      = [self _signatureDictWithInterface:interface
                      andComponentName:_cName];

    if (dict != nil) {
      if ([key2signatureDict objectForKey:key] == nil)
        [key2signatureDict setObject:dict forKey:key];
      else {
        NSMutableDictionary *mutDict;

        mutDict = [[key2signatureDict objectForKey:key] mutableCopy];

        [mutDict addEntriesFromDictionary:dict];
        if (mutDict != nil)
          [key2signatureDict setObject:mutDict forKey:key];
        RELEASE(mutDict); mutDict = nil;
      }
    }

    dict = [self _infoDictWithInterface:interface
                 andComponentName:_cName];
    
    if (dict != nil) {
      if ([key2infoDict objectForKey:key] == nil) {
        [key2infoDict setObject:dict forKey:key];
      }
      else {
        NSMutableDictionary *mutDict;

        mutDict = [[key2infoDict objectForKey:key] mutableCopy];

        [mutDict addEntriesFromDictionary:dict];
        [key2infoDict setObject:mutDict forKey:key];
        RELEASE(mutDict); mutDict = nil;
      }
    }
  }
}

- (void)registerInterfaceFilesForComponentNames:(NSDictionary *)_infos {
  NSString *keyElem;
  NSEnumerator *keyEnum;
  NSString *key;
  
  key = [self cacheKey];

  if ([key2signatureDict objectForKey:key]) return;

  keyEnum = [_infos keyEnumerator];
  while ((keyElem = [keyEnum nextObject])) {
    [self registerInterfaceAtPath:[_infos objectForKey:keyElem]
          forComponentName:keyElem
          returnIfAlreadySet:NO];
  }
}

- (void)registerInterfaceAtPath:(NSString *)_path
  forComponentName:(NSString *)_cName
{
  return [self registerInterfaceAtPath:_path forComponentName:_cName
               returnIfAlreadySet:NO];
}
  
- (void)registerInterfaceAtPath:(NSString *)_path {
  return [self registerInterfaceAtPath:_path forComponentName:nil
               returnIfAlreadySet:YES];
}

- (NSString *)_actionNameWithoutXmlRpcNamespacePrefix:(NSString *)_actionName {
  NSString *prefix;
  NSString *actionName;
  
  prefix     = [self xmlrpcComponentNamespace];
  actionName = _actionName;
  if ([actionName hasPrefix:prefix]) {
    prefix     = [prefix stringByAppendingString:@"."];
    actionName = [actionName stringWithoutPrefix:prefix];
  }
  return actionName;
}

- (NSArray *)system_methodSignatureAction:(NSString *)_xmlrpcMethod {
  NSString     *actionName = nil;
  NSDictionary *sigDict    = nil;
  NSArray      *signature  = nil;

  actionName = [self _actionNameWithoutXmlRpcNamespacePrefix:_xmlrpcMethod];

  if (actionName != nil) {
    sigDict   = [key2signatureDict objectForKey:[self cacheKey]];
    signature = [sigDict objectForKey:actionName];
  }
  return ([signature count] > 0) ? signature : nil;
}

- (NSString *)system_methodHelpAction:(NSString *)_xmlrpcMethod {
  NSString     *actionName = nil;
  NSDictionary *infoDict   = nil;
  NSString     *infoStr    = nil;

  actionName = [self _actionNameWithoutXmlRpcNamespacePrefix:_xmlrpcMethod];
  if (actionName != nil) {
    infoDict = [key2infoDict objectForKey:[self cacheKey]];
    infoStr  = [infoDict objectForKey:actionName];
  }
  
  /* calling super doesn't make sense here ... */
  return infoStr ? infoStr : @"";
}

@end /* NGXmlRpcAction(Introspection) */

@implementation NGXmlRpcAction(IntrospectionPrivateMethods)

- (NSString *)_typeOfPart:(SkyIDLInput *)_part {
  NSArray  *attrNames;
  unsigned i, cnt;

  attrNames = [_part extraAttributeNames];
  cnt       = [attrNames count];

  if (cnt == 0)
    return [[_part type] valueFromQName];
  else {
    for (i = 0; i < cnt; i++) {
      NSString *attrName = [attrNames objectAtIndex:i];
      
      if ([[attrName uriFromQName]   isEqualToString:SkyXmlRpcTypesNS] &&
          [[attrName valueFromQName] isEqualToString:@"type"]) {
        return [_part extraAttributeWithName:attrName];
      }
    }
    return nil;
  }
}

- (NSArray *)_signatureForMethod:(SkyIDLMethod *)_method {
  NSArray         *signatures;
  NSMutableArray  *result;
  NSArray         *parts;
  SkyIDLInput     *part;
  unsigned        i, cnt;

  signatures = [_method signatures];
  cnt        = [signatures count];
  result     = [[NSMutableArray alloc] initWithCapacity:cnt+1];

  for (i=0; i<cnt; i++) {
    SkyIDLSignature *signature = [signatures objectAtIndex:i];
    NSEnumerator    *partEnum  = nil;
    NSMutableArray  *types     = nil;
    NSString        *type;

    types = [[NSMutableArray alloc] initWithCapacity:4];
    
    parts = [signature outputs];
    if ([parts count] != 1) continue;

    // add result type
    type = [[[parts lastObject] type] valueFromQName];
  
    if (type == nil) continue;
  
    [types addObject:type];

    // add parameter types
    partEnum = [[signature inputs] objectEnumerator];

    while ((part = [partEnum nextObject])) {
      type = [self _typeOfPart:part];
      
      if (type)
        [types addObject:type];
    }
    [result addObject:types];
    RELEASE(types);
  }
  return AUTORELEASE(result);
}

- (NSDictionary *)_signatureDictWithInterface:(SkyIDLInterface *)_interface
  andComponentName:(NSString *)_cName
{
  NSMutableDictionary *sigDict;
  NSArray             *methodNames;
  unsigned            i, cnt;
  
  methodNames = [_interface methodNames];
  cnt         = [methodNames count];
  sigDict     = [[NSMutableDictionary alloc] initWithCapacity:cnt+1];

  for (i=0; i < cnt; i++) {
    NSString       *methodName = [methodNames objectAtIndex:i];
    SkyIDLMethod   *method     = [_interface methodWithName:methodName];

    if (method != nil) {
      NSArray *sig = [self _signatureForMethod:method];
      
      if (sig != nil) {
        if (_cName != nil)
          methodName = [NSString stringWithFormat:@"%@.%@",
                                 _cName, methodName];

        [sigDict setObject:sig forKey:methodName];
      }
    }
  }
  return AUTORELEASE(sigDict);
}

- (NSString *)_infoForMethod:(SkyIDLMethod *)_method {
  NSMutableString *info;
  NSString        *tmp;

  info = [[NSMutableString alloc] initWithCapacity:256];

  if ((tmp = [[_method documentation] characters])) {
    [info appendString:tmp];
  }
  if ((tmp = [[_method example] characters])) {
    [info appendString:@"\nExample:\n"];
    [info appendString:tmp];
  }
  return AUTORELEASE(info);
}

- (NSDictionary *)_infoDictWithInterface:(SkyIDLInterface *)_interface
  andComponentName:(NSString *)_cName
{
  NSMutableDictionary *infoDict;
  NSArray             *methodNames;
  unsigned            i, cnt;

  methodNames = [_interface methodNames];
  cnt         = [methodNames count];
  infoDict    = [[NSMutableDictionary alloc] initWithCapacity:cnt+1];

  for (i=0; i < cnt; i++) {
    NSString     *methodName = [methodNames objectAtIndex:i];
    SkyIDLMethod *method     = [_interface methodWithName:methodName];


    if (method != nil) {
      NSString *str = [self _infoForMethod:method];

      if (_cName != nil)
        methodName = [NSString stringWithFormat:@"%@.%@",
                               _cName, methodName];
      
      if (str) [infoDict setObject:str forKey:methodName];
    }
  }
  return AUTORELEASE(infoDict);
}


@end /* NGXmlRpcAction(IntrospectionPrivateMethods) */

@implementation NSString(SkyIDLXML)

- (NSString *)uriFromQName {
  NSRange r;

  if (![self hasPrefix:@"{"])
    return nil;
    
  r = [self rangeOfString:@"}"];
  if (r.length == 0) return nil;
  
  r.length = r.location - 1;
  r.location = 1;
  return [self substringWithRange:r];
}

- (NSString *)valueFromQName {
  NSRange r;
  
  r = [self rangeOfString:@"}"];
  if (r.length == 0) return self;
  
  return [self substringFromIndex:(r.location+r.length)];
}

@end /* NSString(Xml) */

