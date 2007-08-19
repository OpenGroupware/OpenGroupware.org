/*
  Copyright (C) 2006-2007 Whitemice Consulting

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
#include "zOGIAction.h"
#include "zOGIAction+Object.h"
#include <Foundation/NSConcreteData.h>
#include <Foundation/NSConcreteNumber.h>

@implementation zOGIAction(Property)

NSString *OGoExtAttrSpace = @"http://www.opengroupware.org/properties/ext-attr";
NSString *AptExtAttrDefault = @"OGoExtendedAptAttributes";

-(NSString *)_takeNamespaceFromProperty:(NSString *)_property {
  return [[[_property componentsSeparatedByString:@"}"] objectAtIndex:0] substringFromIndex:1];
}

-(NSString *)_takeAttributeFromProperty:(NSString *)_property {
  return [[_property componentsSeparatedByString:@"}"] objectAtIndex:1];
}

-(NSDictionary *)_renderProperty:(id)_name
                       withValue:(id)_value 
                       forObject:(id)_objectId {
  NSMutableDictionary  *property;
  NSString             *namespace, *attribute;
  NSUserDefaults       *standardDefaults;
  NSArray              *extAttrSpecs;
  NSEnumerator         *enumerator;
  NSDictionary         *extAttrSpec;

  standardDefaults = nil;  
  namespace = [self _takeNamespaceFromProperty:_name];
  attribute = [self _takeAttributeFromProperty:_name];
  property = [[NSMutableDictionary alloc] initWithCapacity:12];
  [property addEntriesFromDictionary:
     [NSDictionary dictionaryWithObjectsAndKeys:
       _name, @"propertyName",
       namespace, @"namespace",
       attribute, @"attribute",
       [self NIL:_value], @"value",
       @"objectProperty", @"entityName",
       _objectId, @"parentObjectId",
       nil]];
  if (([_value class] == [NSShortInline8BitString class]) ||
      ([_value class] == [NSString class])) {
    [property setObject:@"string" forKey:@"valueType"];
   } else if ([_value class] == [NSIntNumber class]) {
    [property setObject:@"int" forKey:@"valueType"];
   } else if ([_value class] == [NSCalendarDate class]) {
    [property setObject:@"timestamp" forKey:@"valueType"];
   } else if ([_value class] == [NSConcreteData class]) {
    [property setObject:@"data" forKey:@"valueType"];
   } else  {
       [property setObject:@"unknown" forKey:@"valueType"];
      } 
  if ([namespace isEqualToString:OGoExtAttrSpace]) {
    if (standardDefaults == nil) {
      standardDefaults = [NSUserDefaults standardUserDefaults];
      extAttrSpecs = [[standardDefaults arrayForKey:AptExtAttrDefault] copy];
     }
    enumerator = [extAttrSpecs objectEnumerator];
    while ((extAttrSpec = [enumerator nextObject]) != nil) {
       if([[extAttrSpec objectForKey:@"key"] isEqualToString:attribute]) {
         /* Get type from defaults */
         if ([extAttrSpec objectForKey:@"type"] == nil)
           [property setObject:[NSString stringWithString:@"1"] 
                        forKey:@"type"];
          else
            [property setObject:[extAttrSpec objectForKey:@"type"]
                         forKey:@"type"];
         /* Get label from defaults */
         if ([extAttrSpec objectForKey:@"label"] == nil)
           [property setObject:[NSNull null] forKey:@"label"];
          else
            [property setObject:[extAttrSpec objectForKey:@"label"]
                         forKey:@"label"];
         /* Get value enumeration from defaults */
         if ([[property objectForKey:@"type"] isEqualToString:@"2"]) {
            [property setObject:[NSArray arrayWithObjects:@"YES", @"NO", nil]
                         forKey:@"values"];
          } else if ([extAttrSpec objectForKey:@"values"] != nil) {
            [property setObject:[[extAttrSpec objectForKey:@"values"] allKeys]
                         forKey:@"values"];
          } else { 
            [property setObject:[NSNull null] forKey:@"values"];
          }
        }
     }
   } else {
       [property setObject:[NSNull null] forKey:@"label"];
       [property setObject:[NSNull null] forKey:@"type"];
       [property setObject:[NSNull null] forKey:@"values"];
      }

  return property;
}

-(NSArray *)_propertiesForKey:(id)_objectId {
  id             properties, key;
  EOGlobalID     *eo;
  NSEnumerator   *enumerator;
  NSMutableArray *propertyList;

  propertyList = [[NSMutableArray alloc] initWithCapacity:64];
  eo = [self _getEOForPKey:_objectId];
  properties = [[[self getCTX] propertyManager] propertiesForGlobalID:eo];
  enumerator = [[properties allKeys] objectEnumerator];
  while ((key = [enumerator nextObject]) != nil) {
    [propertyList addObject:[self _renderProperty:key
                                        withValue:[properties objectForKey:key]
                                        forObject:_objectId]];
   }
  return propertyList;
}

/*
   THIS CODE CHEATS!
      This example uses a private method of the property manager to 
      dig out more details about the property.  This is bad practice
      so this code is not used - however, not using this code means
      we loose the ability to provide an objectId for the property. :(

-(NSDictionary *)_renderProperty:(id)_property {
  
    TODO: 1.) Deal with value types other than string
          2.) Add type and label information to rendered property from 
              system defaults if namespace is               
              "http://www.opengroupware.org/properties/ext-attr" as 
              those values are rendered in the UI as extended 
              attributes.
          3.) Figure out long string storage and BLOB encoding.
   
  return [NSDictionary dictionaryWithObjectsAndKeys:
       [_property objectForKey:@"key"], @"propertyName",
       [_property objectForKey:@"namespacePrefix"], @"namespace",
       [_property objectForKey:@"preferredType"], @"preferredType",
       [self NIL:[_property objectForKey:@"valueString"]], @"value",
       @"objectProperty", @"entityName",
       [_property objectForKey:@"objectPropertyId"], @"objectId",
       [_property objectForKey:@"objectId"], @"entityObjectId",
       nil];
}

-(NSArray *)_propertiesForKey:(id)_objectId {
  NSMutableArray *propertyList;
  NSArray        *properties, *keys;
  id             property;
  NSEnumerator   *enumerator;

  propertyList = [[NSMutableArray alloc] initWithCapacity:6];
  keys = [NSArray arrayWithObjects:[self _getEOForPKey:_objectId], nil];
  properties = [[[self getCTX] propertyManager] 
                 _fetchPropertyRowsForGlobalIDs:keys
                                      namespace:nil];
  enumerator = [properties objectEnumerator];
  while ((property = [enumerator nextObject]) != nil) {
     [propertyList addObject:[self _renderProperty:property]];
   }
  return propertyList;
}

  END OF CHEATING CODE
*/

-(void)_addPropertiesToObject:(NSMutableDictionary *)_object {
  [_object setObject:[self _propertiesForKey:[_object valueForKey:@"objectId"]]
              forKey:@"_PROPERTIES"];
}

-(id)_translateProperty:(NSDictionary *)_property {
  NSMutableString  *propertyName;
  
  if ([_property objectForKey:@"propertyName"] != nil)
    return [NSDictionary dictionaryWithObjectsAndKeys:
               [_property objectForKey:@"value"],
               [_property objectForKey:@"propertyName"],
               nil];
  if (([_property objectForKey:@"namespace"] != nil) &&
      ([_property objectForKey:@"attribute"] != nil)) {
    propertyName = [[NSMutableString alloc] init];
    [propertyName appendString:@"{"];
    [propertyName appendString:[_property objectForKey:@"namespace"]];
    [propertyName appendString:@"}"];
    [propertyName appendString:[_property objectForKey:@"attribute"]];
    return [NSDictionary dictionaryWithObjectsAndKeys:
               [_property objectForKey:@"value"],
               propertyName,
               nil];
   }
  return [NSException exceptionWithHTTPStatus:500
             reason:@"Encountered property without property name"];
}

-(NSException *)_saveProperties:(id)_properties 
                      forObject:(id)_objectId {
  id                   property;
  NSDictionary         *propertyEntity;
  EOGlobalID           *eo;
  NSEnumerator         *enumerator;
  NSMutableDictionary  *propertyList;

  eo = [self _getEOForPKey:_objectId];
  propertyList = [[NSMutableDictionary alloc] initWithCapacity:64];
  enumerator = [_properties objectEnumerator];
  while ((propertyEntity = [enumerator nextObject]) != nil) {
    property = [self _translateProperty:propertyEntity];
    if ([property class] == [NSException class]) 
      return property;
    [propertyList addEntriesFromDictionary:property];
   }
  return [[[self getCTX] propertyManager] takeProperties:propertyList
                                                namespace:nil
                                                 globalID:eo];
}

@end /* End zOGIAction(Property) */
