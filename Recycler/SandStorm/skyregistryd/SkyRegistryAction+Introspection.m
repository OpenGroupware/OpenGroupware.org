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

#include "SkyRegistryAction+Introspection.h"
#include "common.h"
#include "SkyRegistryAction.h"
#include "RegistryEntry.h"
#include "SkyRegistryApplication.h"
#include "SkyRegistryAction+PrivateMethods.h"

#include <NGXmlRpc/NGXmlRpcClient.h>

@implementation SkyRegistryAction(Introspection)

- (NSArray *)listComponentMethodsAction:(NSString *)_component {
  RegistryEntry *entry;
  NSArray       *masterKeys;

  if ((entry = [[self registry] objectForKey:_component]) != nil) {
    NSArray *methods;
    NSMutableArray *result;
    NSEnumerator   *methodEnum;
    NSString       *methodElem;    
    NSString       *lastNamespacePart = nil;
    
    if((methods = [entry listMethods]) != nil) {
      BOOL hasNoNamespace;

      if ([methods isKindOfClass:[NSException class]]) {
        [self logWithFormat:@"ERROR: Exception caught: %@", methods];
        return methods;
      }

      hasNoNamespace = ([entry namespace] == nil);
      
      methodEnum = [methods objectEnumerator];
      result = [NSMutableArray arrayWithCapacity:[methods count]];

      lastNamespacePart = [[_component componentsSeparatedByString:@"."]
                                       lastObject];
      
      while((methodElem = [methodEnum nextObject])) {
        NSString *tmp = nil;
        if (hasNoNamespace) {
          NSRange r;

          r = [methodElem rangeOfString:@"."];

          if (r.location == 0)
            tmp = methodElem;
        }

        else if([methodElem hasPrefix:_component]) {
          tmp = [methodElem stringWithoutPrefix:
                            [_component stringByAppendingString:@"."]];
        }
        else if ([methodElem hasPrefix:lastNamespacePart]) {
          tmp = methodElem;
        }
        
        if (tmp != nil)
          [result addObject:[tmp stringWithoutPrefix:
                                 [lastNamespacePart stringByAppendingString:
                                                    @"."]]];
      }
      return result;
    }
  }
  
  masterKeys = [self _fetchMasterKeys];
  if (![masterKeys containsObject:_component])
    return nil;
  
  return [[self masterRegistry] call:
              @"active.registry.listComponentMethods",_component,nil];
}

- (NSArray *)listMethodSignaturesAction:(NSString *)_component
                                       :(NSString *)_method
{
  RegistryEntry *entry;
  NSArray       *masterKeys;
  
  if ((entry = [[self registry] objectForKey:_component]) != nil) {
    return [entry methodSignature:_method];
  }
  /* check master registry */

  masterKeys = [self _fetchMasterKeys];
  if (![masterKeys containsObject:_component])
    return nil;
  
  return [[self masterRegistry] call:
              @"active.registry.componentMethodSignatures",_component,
              _method,nil];
}

- (NSString *)listMethodHelpAction:(NSString *)_component
                                  :(NSString *)_method
{
  RegistryEntry *entry;
  NSArray       *masterKeys;

  if ((entry = [[self registry] objectForKey:_component]) != nil) {
    return [entry methodHelp:_method];
  }

  /* check master */
  
  masterKeys = [self _fetchMasterKeys];
  if (![masterKeys containsObject:_component])
    return nil;
  
  return [[self masterRegistry] call:
              @"active.registry.componentMethodHelp",_component,
              _method,nil];
}

@end /* SkyRegistryAction(Introspection) */
