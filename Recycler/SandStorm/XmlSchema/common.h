// $Id$

#ifndef __XSchema_common_H__
#define __XSchema_common_H__

#import <Foundation/Foundation.h>

#if LIB_FOUNDATION_LIBRARY
#  import <Foundation/exceptions/GeneralExceptions.h>
#elif NeXT_Foundation_LIBRARY || COCOA_Foundation_LIBRARY
#  import <FoundationExt/NSObjectMacros.h>
#  import <FoundationExt/NSString+Ext.h>
#  import <FoundationExt/GeneralExceptions.h>
#endif

#include <SaxObjC/SaxObjC.h>

static inline BOOL isXmlSchemaNamespace(NSString *_namespace) {
  static NSString *W3C2001SchemaNS = @"http://www.w3.org/2001/XMLSchema";
  static NSString *W3C1999SchemaNS = @"http://www.w3.org/1999/XMLSchema";
  
  if ([_namespace isEqualToString:W3C2001SchemaNS])
    return YES;
  else if ([_namespace isEqualToString:W3C1999SchemaNS])
    return YES;
  else
    return NO;
}

#endif /* __XSchema_common_H__ */
