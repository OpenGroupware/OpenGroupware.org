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

#include "SkyContactAction.h"
#include "common.h"
#include "SkyContactAction+Caching.h"
#include "SkyContactAction+QueryMethods.h"
#include <XmlRpc/XmlRpcMethodCall.h>
#include <OGoIDL/NGXmlRpcAction+Introspection.h>
#include <OGoDaemon/SDXmlRpcFault.h>

@implementation SkyContactAction

+ (NSArray *)xmlrpcNamespaces {
  return [NSArray arrayWithObjects:@"contacts",@"enterprises",nil];
}

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx])) {
    NSBundle *bundle;
    NSString *pathContacts, *pathEnterprises;

    bundle = [NSBundle bundleForClass:[self class]];
    pathContacts    = [bundle pathForResource:@"INTERFACE-Contacts"
                              ofType:@"xml"];
    pathEnterprises = [bundle pathForResource:@"INTERFACE-Enterprises"
                              ofType:@"xml"]; 
    if (pathContacts != nil && pathEnterprises != nil) {
      NSDictionary *dict;

      dict = [NSDictionary dictionaryWithObjectsAndKeys:
                           pathContacts, @"contacts",
                           pathEnterprises, @"enterprises",
                           nil];

      [self registerInterfaceFilesForComponentNames:dict];
    }
    else
      [self logWithFormat:@"INTERFACE files not found in bundle path"];
  }
  return self;
}

- (NSString *)xmlrpcComponentName {
  return @"";
}

- (NSString *)xmlrpcComponentNamespace {
  return [self xmlrpcComponentNamespacePrefix];
}

/* actions */

- (id)getEnterprisesAction:(NSArray *)_urls {
  id result;

  if ((result = [self getObjectsForURLs:_urls entity:@"Enterprise"]) != nil)
    return result;

  [self logWithFormat:@"Invalid URLs", _urls];
  return [SDXmlRpcFault invalidObjectFaultForId:[_urls stringValue]
                        entity:@"enterprise"];
}

- (id)getEnterpriseAction:(NSString *)_url {
  id result;

  result = [self getObjectsForURLs:[NSArray arrayWithObject:_url]
                 entity:@"Enterprise"];

  if (result != nil)
    return [result lastObject];
  
  return [SDXmlRpcFault invalidObjectFaultForId:_url entity:@"enterprise"];  
}

- (id)getContactsAction:(NSArray *)_urls {
  id result;

  if ((result = [self getObjectsForURLs:_urls entity:@"Person"]) != nil)
    return result;

  [self logWithFormat:@"Invalid URLs", _urls];
  return [SDXmlRpcFault invalidObjectFaultForId:[_urls stringValue]
                        entity:@"person"];
}

- (id)getContactAction:(NSString *)_url {
  id result;

  result = [self getObjectsForURLs:[NSArray arrayWithObject:_url]
                 entity:@"Person"];

  if (result != nil)
    return [result lastObject];
  
  return [SDXmlRpcFault invalidObjectFaultForId:_url entity:@"person"];  
}

- (NSArray *)enterprisesAdvancedSearchAction:(NSDictionary *)_searchAttrs
                                            :(NSDictionary *)_extAttrs
                                            :(NSNumber *)_maxSearchCount
{
  NSDictionary *arguments;

  arguments = [self argumentsForAdvancedSearch:_searchAttrs
                    extendedAttributes:_extAttrs
                    maxSearchCount:_maxSearchCount
                    entity:@"Enterprise"];

  return [self enterprisesForSearchCommand:@"enterprise::extended-search"
               arguments:arguments];  
}

- (NSArray *)enterprisesAdvancedSearchAction:(NSDictionary *)_searchAttrs
                                            :(NSNumber *)_maxSearchCount
{
  return [self enterprisesAdvancedSearchAction:_searchAttrs
               :nil
               :_maxSearchCount];
}

- (NSArray *)contactsAdvancedSearchAction:(NSDictionary *)_searchAttrs
                                         :(NSDictionary *)_extAttrs
                                         :(NSNumber *)_maxSearchCount
{
  NSDictionary *arguments;
  
  arguments = [self argumentsForAdvancedSearch:_searchAttrs
                    extendedAttributes:_extAttrs
                    maxSearchCount:_maxSearchCount
                    entity:@"Person"];

  return [self personsForSearchCommand:@"person::extended-search"
               arguments:arguments withEnterprises:NO];
}

- (NSArray *)contactsAdvancedSearchAction:(NSDictionary *)_searchAttrs
                                         :(NSNumber *)_maxSearchCount
{
  return [self contactsAdvancedSearchAction:_searchAttrs
               :nil
               :_maxSearchCount];
}

- (id)enterprisesSearchAction:(NSString *)_searchString
                         :(NSNumber *)_maxSearchCount
{
  if (_searchString != nil && ([_searchString length] > 0)) {
    NSMutableDictionary *args;
    
    args = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                @"OR",         @"operator",
                                _searchString, @"description",
                                _searchString, @"number",
                                _searchString, @"keywords",
                                [NSNumber numberWithBool:YES],
                                @"fetchGlobalIDsAndVersions",
                                nil];
    
    if (_maxSearchCount != nil)
      [args setObject:_maxSearchCount forKey:@"maxSearchCount"];
  
    return [self enterprisesForSearchCommand:@"enterprise::extended-search"
                 arguments:args];
  }
  return [SDXmlRpcFault missingValueFaultForArgument:@"searchString"];
}

- (id)contactsSearchAction:(NSString *)_searchString
                                 :(NSNumber *)_maxSearchCount
{
  if (_searchString != nil && ([_searchString length] > 0)) {
    NSMutableDictionary *args;
    
    args = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                @"OR",         @"operator",
                                _searchString, @"name",
                                _searchString, @"firstname",
                                _searchString, @"description",
                                _searchString, @"login",
                                [NSNumber numberWithBool:YES],
                                @"fetchGlobalIDsAndVersions",
                                nil];
            
    if (_maxSearchCount != nil)
      [args setObject:_maxSearchCount forKey:@"maxSearchCount"];
  
    return [self personsForSearchCommand:@"person::extended-search"
                 arguments:args withEnterprises:NO];
  }
  return [SDXmlRpcFault missingValueFaultForArgument:@"searchString"];
}

- (id)enterprisesFulltextSearchAction:(NSString *)_searchString
                                 :(NSNumber *)_maxSearchCount
{
  if (_searchString != nil && ([_searchString length] > 0)) {
    NSMutableDictionary *args;

    args = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                _searchString, @"searchString",
                                [NSNumber numberWithBool:YES],
                                @"fetchGlobalIDsAndVersions",
                                nil];

    if (_maxSearchCount != nil)
      [args setObject:_maxSearchCount forKey:@"maxSearchCount"];
  
    return [self enterprisesForSearchCommand:@"enterprise::full-search"
                 arguments:args];
  }
  return [SDXmlRpcFault missingValueFaultForArgument:@"searchString"];
}

- (id)contactsFulltextSearchAction:(NSString *)_searchString
                                 :(NSNumber *)_maxSearchCount
{
  if (_searchString != nil && ([_searchString length] > 0)) {
    NSMutableDictionary *args;

    args = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                _searchString, @"searchString",
                                [NSNumber numberWithBool:YES],
                                @"fetchGlobalIDsAndVersions",
                                nil];

    if (_maxSearchCount != nil)
      [args setObject:_maxSearchCount forKey:@"maxSearchCount"];
  
    return [self personsForSearchCommand:@"person::full-search"
                 arguments:args withEnterprises:NO];
  }
  return [SDXmlRpcFault missingValueFaultForArgument:@"searchString"];
}

- (BOOL)requiresCommandContextForMethodCall:(NSString *)_method {
  static NSArray *methodNames = nil;
  NSString *methodName;
  NSRange range;
  
  range = [_method rangeOfString:[self xmlrpcComponentName]
                              options:NSBackwardsSearch];
  
  if (range.location != 0) {
    int index;

    index = range.location + [[self xmlrpcComponentName] cStringLength] + 1;
    methodName = [_method substringFromIndex:index];
  }
  else
    methodName = _method;
  
  if (methodNames == nil) {
    methodNames = [[NSArray alloc] initWithObjects:
                            @"system.listMethods",
                            @"system.methodSignature",
                            @"system.methodHelp",
                            nil];
  }
  
  if ([methodNames containsObject:methodName])
    return NO;
  
  return YES;
}

@end /* SkyContactAction */
