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

#include <SOAP/SOAP.h>
#include <XmlSchema/XmlSchema.h>
#include <XmlSchema/NSString+XML.h>
#include <DOM/DOM.h>
#include "common.h"

@interface SOAPBody(DocumentStylePrivateMethods)
- (id)_valueForNode:(id)_node element:(XmlSchemaElement *)_element;
@end

@implementation SOAPBody(DocumentStyle)

- (void)setDocumentValues:(NSArray *)_values {
  if ([self->operation isRpcStyle]) {
    NSLog(@"Warning(%s): document style is expcected!", __PRETTY_FUNCTION__);
  }
  else {
    SOAPWSDLPart     *part        = [[[self message] parts] lastObject];
    NSString         *elementName = [part element];
    XmlSchema        *schema      = nil;
    XmlSchemaElement *element     = nil;

    schema  = [XmlSchema schemaForNamespace:[elementName uriFromQName]];
    element = [schema elementWithName:[elementName valueFromQName]];

    [self removeAllValues];
    if ([element isSimpleType]) {
      NSLog(@"Warning(%s): element <%@> is not complex",
            __PRETTY_FUNCTION__,
            [element name]);
    }
    else {
      NSMutableDictionary *dict    = nil;
      NSEnumerator        *nameEnum= [[element elementNames] objectEnumerator];
      unsigned            i, maxCnt;

      i      = 0;
      maxCnt = [_values count];
      dict   = [[NSMutableDictionary alloc] initWithCapacity:maxCnt+1];
      
      while ((name = [nameEnum nextObject]) && (i < maxCnt)) {
        [dict setObject:[_values objectAtIndex:i] forKey:name];
        i++;
      }
      [self addValue:dict];
      RELEASE(dict);
    }
  }
}

- (id)valueWithXmlSchema {
  NSString         *elementName;
  XmlSchemaElement *element;
  NSEnumerator     *nameEnum;
  NSString         *elName;
  DOMNode          *node;
  id               result;

  // ToDo: compare parts.count and node.count !!! (should be 1==1)
  elementName = [[[[self message] parts] lastObject] element];
  element     = [XmlSchema elementWithQName:elementName];
  element     = [element elementWithName:[[element elementNames] lastObject]];
  nameEnum    = [[element elementNames] objectEnumerator];
  node        = [[[[self values] lastObject] firstChild] firstChild];

  if ([element isSimpleType]) {
    result = [self _valueForNode:node element:element];
  }
  else {
    result = [NSMutableDictionary dictionaryWithCapacity:8];
    while ((elName = [nameEnum nextObject])) {
      XmlSchemaElement *el;
      id val;

      el  = [element elementWithName:elName];
      val = [self _valueForNode:node element:el];
      if (val)
        [result setObject:val forKey:elName];
    }
  }
  return result;
}

@end /* SOAPBody(DocumentStyle) */


@implementation SOAPBody(DocumentStylePrivateMethods)

- (id)_valueForNode:(id)_node element:(XmlSchemaElement *)_element {
  if ([_element isSimpleType]) {
    id val = [[_node getElementsByTagName:[_element name]] lastObject];
    return [[[val childNodes] lastObject] nodeValue];
  }
  else {
    NSString *tagName = [[[_element contentType] content] tagName];
    
    if ([tagName isEqualToString:@"sequence"]) {
      NSMutableArray *array;
      NSEnumerator   *nameEnum;
      NSString       *elName;

      array    = [[NSMutableArray alloc] initWithCapacity:8];
      nameEnum = [[_element elementNames] objectEnumerator];

      while ((elName = [nameEnum nextObject])) {
        XmlSchemaElement *element = [_element elementWithName:elName];
        id               child    = nil;
        id               val      = nil;

        if (element == nil)
          continue;
        else if ([[element maxOccurs] intValue] != 1) {
          NSArray *childEnum;

          childEnum = [[_node getElementsByTagName:elName] objectEnumerator];

          while ((child = [childEnum nextObject])) {
            val = [self _valueForNode:child element:element];
            if (val) [array addObject:val];
          }
        }
        else {
          child = [[_node getElementsByTagName:elName] lastObject];
          val = [self _valueForNode:child element:element];
          if (val) [array addObject:val];
        }
      }
      return AUTORELEASE(array);
    }
    else if ([tagName isEqualToString:@"all"]) {
      NSMutableDictionary *dict;

      dict = [[NSMutableDictionary alloc] initWithCapacity:8];
      return AUTORELEASE(dict);
    }
    else
      NSLog(@"don't know...");
    
    return nil;
  }
}

@end /* SOAPBody(DocumentStylePrivateMethods) */
