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

#include "DirectAction.h"
#include "common.h"
#include "EOControl+XmlRpcDirectAction.h"

@implementation DirectAction(Resource)

/* utility methods */

- (NSArray *)_searchRecordForQualifier:(id)_qual {
  LSCommandContext *ctx;
  
  if ((ctx = [self commandContext]) != nil) {
    id searchRecord;
    NSArray *quals;
    NSEnumerator *qualEnum;
    id qualifier;
    
    searchRecord = [ctx runCommand:@"search::newrecord",
                        @"entity", @"AppointmentResource", nil];
    [searchRecord setComparator:@"LIKE"];

    quals = ([_qual respondsToSelector:@selector(qualifiers)])
      ? [(id)_qual qualifiers]
      : [NSArray arrayWithObject:_qual];

    qualEnum = [quals objectEnumerator];
    while ((qualifier = [qualEnum nextObject])) {
      id key, value;
      
      key = [qualifier key];
      value = [[qualifier value] stringValue];
      [searchRecord takeValue:value forKey:key];
    }
    return [NSArray arrayWithObject:searchRecord];
  }
  [self logWithFormat:@"Invalid command context"];
  return nil;
}

- (NSDictionary *)_dictionaryForResourceEOGenericRecord:(id)_record {
  static NSArray *resKeys = nil;
  if (resKeys == nil)
    resKeys = [[NSArray alloc] initWithObjects:
                               @"category", @"name", @"email",
                               @"emailSubject", @"notificationTime",nil];

  return [self _dictionaryForEOGenericRecord:_record withKeys:resKeys];
}

- (NSArray *)_dictionariesForResourceEOGenericRecords:(NSArray *)_records {
  NSMutableArray *result;
  NSEnumerator *recEnum;
  id record;

  result = [NSMutableArray arrayWithCapacity:[_records count]];
  recEnum = [_records objectEnumerator];
  while ((record = [recEnum nextObject]))
    [result addObject:[self _dictionaryForResourceEOGenericRecord:record]];
  return result;
}

- (id)_getEOGenericRecordForURL:(id)_url {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    EOGlobalID *gid;

    if ((gid = [[ctx documentManager] globalIDForURL:_url]) != nil) {
      NSArray *results;
      id result;
      int rLength;

      results = [ctx runCommand:@"appointmentresource::get-by-globalid",
                     @"gid", gid,
                     nil];

      if ((rLength = [results count]) == 0) {
        [self logWithFormat:@"No result found, but global ID is valid"];
        return nil;
      }

      if (rLength >= 2) {
        [self logWithFormat:@"Too many results for one global ID found"];
        return nil;
      }

      result = [results objectAtIndex:0];
      
      if ([result isKindOfClass:[EOGenericRecord class]]) {
        return result;
      }

      [self logWithFormat:@"Invalid result type for command"];
      return nil;
    }
    [self logWithFormat:@"Couldn't lookup global ID for URL '%@'", _url];
    return nil;
  }

  [self logWithFormat:@"Invalid command context"];
  return nil;
}

/* actions */

- (id)resource_insertAction:(NSDictionary *)_resource {
  LSCommandContext *ctx;

  if (![_resource isKindOfClass:[NSDictionary class]])
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"Invalid parameter format"];
  
  if ([[_resource valueForKey:@"name"] length] == 0)
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:@"No resource name set"];
  
  if ((ctx = [[self session] commandContext]) != nil) {
    id result;

    result = [ctx runCommand:@"appointmentresource::new" arguments:_resource];
    if ([result isKindOfClass:[EOGenericRecord class]])
      return [[ctx documentManager] urlForGlobalID:[result globalID]];
    return [self invalidResultFault];
  }
  return [self invalidCommandContextFault];
}

- (id)resource_getByIdAction:(id)_resId {
  id resource;

  if ((resource = [self _getEOGenericRecordForURL:_resId]) == nil)
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"Couldn't find entity for URL"];

  return [self _dictionaryForResourceEOGenericRecord:resource];
}

- (id)resource_updateAction:(NSDictionary *)_resource {
  NSString *resId;
  id resource;
  LSCommandContext *ctx;
  
  if (![_resource isKindOfClass:[NSDictionary class]])
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"Invalid parameter format"];

  if ((resId = [_resource valueForKey:@"id"]) == nil)
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:@"'id' element missing"];

  if ((resource = [self _getEOGenericRecordForURL:resId]) == nil)
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"Invalid resource URL"];

  [resource takeValuesFromDictionary:_resource];
  
  if ((ctx = [self commandContext]) != nil) {
    id result;

    result = [ctx runCommand:@"appointmentresource::set",
                  @"object", resource,
                  nil];
    if ([result isKindOfClass:[EOGenericRecord class]]) {
      return [self _dictionaryForResourceEOGenericRecord:result];
    }
    return [self invalidResultFault];
  }
  return [self invalidCommandContextFault];
}

- (id)resource_deleteAction:(id)_resId {
  id resource;
  LSCommandContext *ctx;

  if ((resource = [self _getEOGenericRecordForURL:_resId]) == nil)
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"Invalid resource URL"];

  if ((ctx = [self commandContext]) != nil) {
    id result;

    result = [ctx runCommand:@"appointmentresource::delete",
                  @"object", resource,
                  nil];

    if ([result isKindOfClass:[EOGenericRecord class]])
      return [NSNumber numberWithBool:YES];

    return [self invalidResultFault];
  }
  return [self invalidCommandContextFault];
}

- (id)resource_fetchAction:(id)_arg {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    EOFetchSpecification *fSpec;
    id result;
    id qualifier;
    NSString *operator = @"OR";
    
    fSpec = [[EOFetchSpecification alloc] initWithBaseValue:_arg];
    [fSpec setEntityName:@"AppointmentResource"];

    qualifier = [fSpec qualifier];
    if ([qualifier isKindOfClass:[EOAndQualifier class]])
      operator = @"AND";
    
    result = [ctx runCommand:@"appointmentresource::extended-search",
                  @"operator", operator,
                  @"searchRecords",
                  [self _searchRecordForQualifier:[fSpec qualifier]],
                  nil];

    [fSpec release];
    return [self _dictionariesForResourceEOGenericRecords:result];
  }
  return [self invalidCommandContextFault];
}

- (id)resource_getByNameAction:(NSString *)_name {
  NSString *fetchString;

  fetchString = [NSString stringWithFormat:@"name = '%@'", _name];
  return [self resource_fetchAction:fetchString];
}

- (id)resource_categoriesAction:(NSString *)_category {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    id result;

    if ([_category length] > 0)
      result = [ctx runCommand:@"appointmentresource::categories",
                    @"category", _category,
                    nil];
    else
      result = [ctx runCommand:@"appointmentresource::categories",nil];
    return result;
  }
  return [self invalidCommandContextFault];
}

@end /* DirectAction(Resource) */
