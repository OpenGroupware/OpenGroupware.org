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

@implementation zOGIAction(Assignment)

-(id)_renderAssignment:(id)_objectId
                source:(id)_source 
                target:(id)_target 
                    eo:(id)_eo {
  NSMutableDictionary   *assignment;
  NSString              *sourceEntity, *targetEntity;
 
  assignment = [NSMutableDictionary dictionaryWithCapacity:16];

  if ([_objectId isKindOfClass:[NSString class]])
    _objectId = [NSNumber numberWithInt:[_objectId intValue]];

  /* Normalize source id & entity */
  if ([_source isKindOfClass:[NSString class]])
    _source = [NSNumber numberWithInt:[_source intValue]];
  sourceEntity = [self _izeEntityName:[self _getEntityNameForPKey:_source]];

  /* Normalize target id & entity */
  if ([_target isKindOfClass:[NSString class]])
    _target = [NSNumber numberWithInt:[_target intValue]];
  targetEntity = [self _izeEntityName:[self _getEntityNameForPKey:_target]];

  [assignment setObject:_objectId forKey:@"objectId"];
  [assignment setObject:@"assignment" forKey:@"entityName"];
  [assignment setObject:_source forKey:@"sourceObjectId"];
  [assignment setObject:sourceEntity forKey:@"sourceEntityName"];
  [assignment setObject:_target forKey:@"targetObjectId"];
  [assignment setObject:targetEntity forKey:@"targetEntityName"];
  if (_eo != nil) {
    if (([_eo class] == [EOGenericRecord class]) ||
        ([_eo class] == [NSDictionary class]) ||
        ([_eo class] == [NSMutableDictionary class])) {
       [assignment setObject:[self NIL:[_eo objectForKey:@"accessRight"]]
                      forKey:@"accessRights"];
       [assignment setObject:[self NIL:[_eo objectForKey:@"info"]]
                      forKey:@"info"];
     }
   } else {
       [assignment setObject:[NSNull null] forKey:@"accessRight"];
       [assignment setObject:[NSNull null] forKey:@"info"];
      }
  return assignment;
} /* end _renderAssignment */

/* _getCompanyAssignments
   Concerning the _company parameter:
   1.) If _company is a dictionary that contains a "*companyAssignments" key 
   the value of that key will be returned unmodified.
   2.) If _company is a dictionary that contains an "objectId" key then 
   assignments where _key == objectId will be returned - by this function
   calling itself with that value - so you'll possibly see it twice in the
   logs.
   3.) If _company is an EOGenericRecord then the companyId key will be
   extracted and the search will be companyId == key
   4.) If _company is a number then it will be used directly
   5.) If _company is a string then the intValue of the string will be used
  
   Results:
   If _company is a mutable dictionary then the results will be stored
   in the "*companyAssignments" of that dictionary and the entire dictionary
   will be returned;  otherwise the results of the  logic command
   "companyassignment::get" are returned unmodified.  The result of this
   function will always be an array (possibly empty) or an exception.
 */
-(id)_getCompanyAssignments:(id)_company key:(NSString *)_key {
  NSNumber  *companyId;
  id         assignments;

  if ([_company isKindOfClass:[EOGenericRecord class]])
    companyId = [_company objectForKey:@"companyId"];
  else if ([_company isKindOfClass:[NSNumber class]])
    companyId = _company;
  else if ([_company isKindOfClass:[NSString class]])
    companyId = [NSNumber numberWithInt:[_company intValue]];
  else if (([_company isKindOfClass:[NSDictionary class]]) ||
           ([_company isKindOfClass:[NSMutableDictionary class]])) {
    if ([_company objectForKey:@"*companyAssignments"] != nil)
      return [_company objectForKey:@"*companyAssignments"];
    return [self _getCompanyAssignments:[_company objectForKey:@"objectId"]
                                    key:_key];
   }
  else return [NSException exceptionWithHTTPStatus:500
                 reason:@"Invalid company specification for assignment retrieval"];

  assignments = [[self getCTX] runCommand:@"companyassignment::get",
                    _key, companyId,
                    @"returnType", intObj(LSDBReturnType_ManyObjects),
                    nil];
  if ([assignments isKindOfClass:[NSException class]]) {
    [self warnWithFormat:@"Logic exception retrieving company assignments", 
       assignments];
    return assignments;
  }
  if (assignments == nil)
    assignments = [NSArray array];
  if ([_company isKindOfClass:[NSMutableDictionary class]])
    [_company setObject:assignments forKey:@"*companyAssignments"];
 
  return assignments;
} /* end _getCompanyAssignments */

/* Store the provided enterprise relationship  */
-(NSException *)_saveCompanyAssignments:(NSArray *)_assignments 
                               objectId:(id)_objectId 
                                    key:(NSString *)_key
                           targetEntity:(NSString *)_targetEntity 
                              targetKey:(NSString *)_targetKey {
  id                 assignments;
  NSMutableArray    *deletes;
  NSMutableArray    *inserts;
  NSEnumerator      *serverEnumerator, *clientEnumerator;
  id                 serverRecord, clientRecord;
  int                isFound;

  /* No data provided, bail out */
  if (_assignments == nil) return nil;

  if ([self isDebug])
    [self logWithFormat:@"saving company assignments for %@", _objectId];

  /* If the provided enterprises array is empty then just delete them all */
  if ([_assignments count] == 0) {
    if ([self isDebug])
      [self logWithFormat:@"client supplied no company assignments"];
    assignments = [self _getCompanyAssignments:_objectId key:_key];
    if ([assignments isKindOfClass:[NSException class]])
      return assignments;
    if ([assignments count] > 0) {
      if ([self isDebug])
        [self logWithFormat:@"deleting all company assignments for %@",
           _objectId];
      serverEnumerator = [assignments objectEnumerator];
      while ((serverRecord = [serverEnumerator nextObject]) != nil) {
        if ([[self _getEntityNameForPKey:[serverRecord 
                                            valueForKey:@"companyId"]]
                isEqualToString:_targetEntity]) {
          [[self getCTX] runCommand:@"companyassignment::delete",
                          @"object", serverRecord, nil];
        } /* End if-assignment-is-correct-type */
      } /* End delete-all-assignments loop */
    } else if ([self isDebug])
        [self logWithFormat:@"there are no company assignments for %@", 
           _objectId];
  } else {
      if ([self isDebug])
        [self logWithFormat:@"syncing company assignments for %@: scanning", 
           _objectId];
      /* Sigh... we have real work to do, process client-->server changes */
      inserts = [NSMutableArray arrayWithCapacity:16];
      deletes = [NSMutableArray arrayWithCapacity:16];
      assignments = [self _getCompanyAssignments:_objectId key:_key];
      if ([assignments isKindOfClass:[NSException class]])
        return assignments;
      /* Scan for records on the server that are not on the client */
      serverEnumerator = [assignments objectEnumerator];
      while ((serverRecord = [serverEnumerator nextObject]) != nil) {
        isFound = 0;
        clientEnumerator = [_assignments objectEnumerator];
        while (((clientRecord = [clientEnumerator nextObject]) != nil) &&
               (isFound == 0)) {
          if ([[clientRecord objectForKey:@"targetObjectId"] intValue] ==
             [[serverRecord objectForKey:@"companyId"] intValue])
            isFound = 1;
        } /* End of clientRecord loop */
        /* A match was NOT found so we need to delete a record */
        if (isFound == 0)
          [deletes addObject:serverRecord];
      } /* End of scan-for-deletes (serverRecord) loop */

      /* Scan for records on the client that are not on the server */
      clientEnumerator = [_assignments objectEnumerator];
      while ((clientRecord = [clientEnumerator nextObject]) != nil) {
        isFound = 0;
        serverEnumerator = [assignments objectEnumerator];
        while ((serverRecord = [serverEnumerator nextObject]) != nil) {
          if([[clientRecord objectForKey:@"targetObjectId"] intValue] ==
             [[serverRecord objectForKey:@"companyId"] intValue])
           isFound = 1;
        } /* End of serverRecord loop */
        /* A match was NOT found so we need to make a record */
        if (isFound == 0)
          [inserts addObject:clientRecord];
      } /* End of scan-for-inserts (clientRecord) loop */

      /* Process company assignment deletions */
      if ([self isDebug])
        [self logWithFormat:@"syncing company assignments for %@: changing", 
           _objectId];
      if ([deletes count] > 0) {
        serverEnumerator = nil;
        serverEnumerator = [deletes objectEnumerator];
        while ((serverRecord = [serverEnumerator nextObject]) != nil) {
          [[self getCTX] runCommand:@"companyassignment::delete",
                           @"object", serverRecord, nil];
        } /* End process-deletes-loop */
      } /* End if-there-are-deletes */

      /* Process new company assignments */
      if ([inserts count] > 0) {
        serverEnumerator = nil;
        serverEnumerator = [inserts objectEnumerator];
        while ((serverRecord = [serverEnumerator nextObject]) != nil) {
          [[self getCTX] runCommand:@"companyassignment::new"
             arguments:[NSDictionary dictionaryWithObjectsAndKeys:
                          [serverRecord objectForKey:@"targetObjectId"], 
                          _targetKey,
                          _objectId, 
                          _key,
                          nil]];
        } /* End process-inserts-loop */
      } /* End if-there-are-inserts */
    } /* End process client-->server changes */

  serverEnumerator = nil;
  serverRecord = nil;
  clientEnumerator = nil;
  clientRecord = nil;

  return nil;
} /* End _saveCompanyAssignments */

@end /* End zOGIAction(Assignment) */
