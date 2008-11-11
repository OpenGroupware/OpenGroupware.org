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
#include "zOGIAction+Company.h"
#include "zOGIAction+Contact.h"
#include "zOGIAction+Defaults.h"
#include "zOGIAction+Assignment.h"

@implementation zOGIAction(Contact)

/* Render contacts at the specified detail level
   _contacts must be an array of EOGenericRecords
   _detail must be an NSNumber, this value has no 
          default, must be provided */
-(NSArray *)_renderContacts:(NSArray *)_contacts 
                 withDetail:(NSNumber *)_detail {
  NSMutableArray      *result;
  EOGenericRecord     *eoContact;
  int                  count;
  NSString            *comment;

  /* [self logWithFormat:@"_renderContacts([%@])", _contacts]; */
  result = [NSMutableArray arrayWithCapacity:[_contacts count]];
  for (count = 0; count < [_contacts count]; count++) {
    eoContact = [_contacts objectAtIndex:count];
    comment = [[eoContact objectForKey:@"comment"] objectForKey:@"comment"];
    if ([[eoContact valueForKey:@"companyId"] intValue] == 10000) {
      [result addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
         eoContact, @"*eoObject",
         [eoContact valueForKey:@"companyId"], @"objectId",
         @"Account", @"entityName",
         [self ZERO:[eoContact valueForKey:@"objectVersion"]], @"version",
         [eoContact valueForKey:@"login"], @"login",
        nil]];
    } else {
        [result addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: 
           eoContact, @"*eoObject",
           [eoContact valueForKey:@"companyId"], @"objectId",
           @"Contact", @"entityName",
           [self ZERO:[eoContact valueForKey:@"objectVersion"]], @"version",
           [eoContact valueForKey:@"ownerId"], @"ownerObjectId",
           [self NIL:[eoContact valueForKey:@"assistantName"]], 
             @"assistantName",
           [self NIL:[eoContact valueForKey:@"associatedCategories"]], 
             @"associatedCategories",
           [self NIL:[eoContact valueForKey:@"associatedCompany"]], 
             @"associatedCompany",
           [self NIL:[eoContact valueForKey:@"associatedContacts"]], 
             @"associatedContacts",
           [self NIL:[eoContact valueForKey:@"birthday"]], @"birthDate",
           [self NIL:[eoContact valueForKey:@"nickname"]], @"displayName",
           [self NIL:[eoContact valueForKey:@"bossname"]], @"managersName",
           [self NIL:[eoContact valueForKey:@"degree"]], @"degree",
           [self NIL:[eoContact valueForKey:@"department"]], @"department",
           [self NIL:[eoContact valueForKey:@"description"]], @"description",
           [self NIL:[eoContact valueForKey:@"fileas"]], @"fileAs",
           [self NIL:[eoContact valueForKey:@"firstname"]], @"firstName",
           [self NIL:[eoContact valueForKey:@"middlename"]], @"middleName",
           [self NIL:[eoContact valueForKey:@"name"]], @"lastName",
           [self NIL:[eoContact valueForKey:@"imAddress"]], @"imAddress",
           [self NIL:comment], @"comment",
           [self NIL:[eoContact valueForKey:@"isPrivate"]], @"isPrivate",
           [self NIL:[eoContact valueForKey:@"isAccount"]], @"isAccount",
           [self NIL:[eoContact valueForKey:@"keywords"]], @"keywords",
           [self NIL:[eoContact valueForKey:@"occupation"]], @"occupation",
           [self NIL:[eoContact valueForKey:@"office"]], @"office",
           [self NIL:[eoContact valueForKey:@"salutation"]], @"salutation",
           [self NIL:[eoContact valueForKey:@"sensitivity"]], @"sensitivity",
           [self NIL:[eoContact valueForKey:@"sex"]], @"gender",
           [self NIL:[eoContact valueForKey:@"url"]], @"url",
           [self NIL:[eoContact valueForKey:@"login"]], @"login",
         nil]];
        [self _addAddressesToCompany:[result objectAtIndex:count]];
        [self _addPhonesToCompany:[result objectAtIndex:count]];
        /* Add flags */
        [[result objectAtIndex:count] 
            setObject:[self _renderCompanyFlags:eoContact entityName:@"Contact"]
              forKey:@"FLAGS"];
       } /* end if-not-10000-render-as-contact */
     /* Add detail if required */
     if([_detail intValue] > 0) {
       if([_detail intValue] & zOGI_INCLUDE_COMPANYVALUES)
         [self _addCompanyValuesToCompany:[result objectAtIndex:count]];
       if([_detail intValue] & zOGI_INCLUDE_MEMBERSHIP)
         [self _addMembershipToPerson:[result objectAtIndex:count]];
       if([_detail intValue] & zOGI_INCLUDE_ENTERPRISES)
         [self _addEnterprisesToPerson:[result objectAtIndex:count]];
       if([_detail intValue] & zOGI_INCLUDE_PROJECTS)
         [self _addProjectsToPerson:[result objectAtIndex:count]];
       /* Call the _addObjectDetails method that adds details, if requested,
          that are appropriate to all object types */
       [self _addObjectDetails:[result objectAtIndex:count] 
                    withDetail:_detail];
     } /* End if-some-detail-has-been-requested */
     [self _stripInternalKeys:[result objectAtIndex:count]];
   } /* End rendering loop */
  return result;
} /* end _renderContacts */

/* Get the EO object from the database for the specified keys.  Keys
   can be numbers, strings or EOGlobalIDs */
-(NSArray *)_getUnrenderedContactsForKeys:(id)_arg {
  NSArray       *contacts;

  contacts = [[[self getCTX] runCommand:@"person::get-by-globalid",
                                        @"gids", [self _getEOsForPKeys:_arg],
                                        nil] retain];
  return contacts;
} /* end _getUnrenderedContactsForKeys */

/*
  Singular instance of _getUnrenderedContactsForKeys;  still returns an array
  however so that it can be used with methods that also handle bulk actions.
  This array is guaranteed to be single-valued.
 */
-(id)_getUnrenderedContactForKey:(id)_arg {
  NSArray    *results;
 
  results = [self _getUnrenderedContactsForKeys:_arg];
  if (results == nil) return nil;
  if ([results count] == 0) return nil;
  return [results lastObject];
} /* end _getUnrenderedContactsForKey */

/* Return the rendered contacts at the specified detail level */
-(id)_getContactsForKeys:(id)_arg withDetail:(NSNumber *)_detail {
  return [self _renderContacts:[self _getUnrenderedContactsForKeys:_arg] 
                    withDetail:_detail];
} /* end _getContactsForKeys */

/* Return the rendered contacts at the default detail level, which is 0 */
-(id)_getContactsForKeys:(id)_arg {
  return [self _renderContacts:[self _getUnrenderedContactsForKeys:_arg] 
               withDetail:intObj(0)];
} /* end _getContactsForKeys */

/* Return singular contact with specified detail level */
-(id)_getContactForKey:(id)_pk withDetail:(NSNumber *)_detail {
  id               result;

  result = [self _getContactsForKeys:_pk withDetail:_detail];
  if ([result isKindOfClass:[NSException class]])
    return result;
  if ([result isKindOfClass:[NSMutableArray class]])
    if([result count] == 1)
      return [result objectAtIndex:0];
  return nil;
} /* end _getContactForKey */

/* Return singular contact with specified detail leve, which is 0 */
-(id)_getContactForKey:(id)_pk {
  return [[self _getContactsForKeys:_pk] objectAtIndex:0];
} /* End of _getContactForKey */

/* Add enterprises to contact dictionary 
   This method may return an exception 
   Uses the _getCompanyAssignments method */
-(NSException *)_addEnterprisesToPerson:(NSMutableDictionary *)_contact {
  id                  assignments;
  NSMutableArray      *enterpriseList;
  NSEnumerator        *enumerator;
  EOGenericRecord     *eo;
  NSMutableDictionary *assignment;

  assignments = [self _getCompanyAssignments:_contact key:@"subCompanyId"]; 
  if ([assignments class] == [NSException class]) 
    return assignments;
  enterpriseList = [NSMutableArray arrayWithCapacity:16];
  enumerator = [assignments objectEnumerator];
  while ((eo = [enumerator nextObject]) != nil) {
    if ([[self _getEntityNameForPKey:[eo valueForKey:@"companyId"]]
              isEqualToString:@"Enterprise"]) {
      assignment = [self _renderAssignment:
                             [eo valueForKey:@"companyAssignmentId"]
                      source:[eo valueForKey:@"subCompanyId"]
                      target:[eo valueForKey:@"companyId"]
                          eo:eo];
      [enterpriseList addObject:assignment];
    } /* end if-assignment-is-to-enterprise */
  } /* End loop-assignment-enumerator */
  [_contact setObject:enterpriseList forKey:@"_ENTERPRISES"];
  return nil;
} /* end _addEnterprisesToPerson */

/* Store the provided enterprise relationship
   Uses _saveCompanyAssignments */
-(NSException *)_saveEnterprisesToPerson:(NSArray *)_assignments 
                                objectId:(id)_objectId {
  return [self _saveCompanyAssignments:_assignments 
                              objectId:_objectId
                                   key:@"subCompanyId"
                          targetEntity:@"Enterprise"
                             targetKey:@"companyId"];
} /* end _saveEnterprisesToPerson */

/* Add team membership to contact dictionary
   This method may return an exception
   Uses the _getCompanyAssignments method */
-(NSException *)_addMembershipToPerson:(NSMutableDictionary *)_contact {
  id                   assignments;
  NSMutableArray      *teamList;
  NSEnumerator        *enumerator;
  EOGenericRecord     *eo;
  NSMutableDictionary *assignment;

  assignments = [self _getCompanyAssignments:_contact key:@"subCompanyId"];
  if ([assignments isKindOfClass:[NSException class]]) 
    return assignments;
  teamList = [NSMutableArray arrayWithCapacity:32];
  enumerator = [assignments objectEnumerator];
  while ((eo = [enumerator nextObject]) != nil) {
    if ([[self _getEntityNameForPKey:[eo valueForKey:@"companyId"]]
              isEqualToString:@"Team"]) {
      assignment = [self _renderAssignment:[eo valueForKey:@"companyAssignmentId"]
                                    source:[eo valueForKey:@"subCompanyId"]
                                    target:[eo valueForKey:@"companyId"]
                                        eo:eo];
      [teamList addObject:assignment];
    } /* End if-assignment-is-to-a-team */
  } /* End assignment-enumerator-loop */
  [_contact setObject:teamList forKey:@"_MEMBERSHIP"];
  return nil;
} /* end _addMembershipToPerson */

/* Adds project membership to contact dictionary
   No exception handling or production
   Uses the person::get-project-assignments Logic command */
-(NSException *)_addProjectsToPerson:(NSMutableDictionary *)_contact {
  id                   projects;    /* Results of logic command */
  NSMutableArray      *projectList; /* Rendered list of project assignments */
  NSEnumerator        *enumerator;  /* Enumerator for looping projects */
  EOGenericRecord     *eo;          /* Project assignment record */
  NSMutableDictionary *assignment;  /* Rendered project assignment */

  projects = [[self getCTX] runCommand:@"person::get-project-assignments",
                              @"withArchived", [NSNumber numberWithBool:YES],
                              @"object", [_contact objectForKey:@"*eoObject"],
                              nil];
  if ([projects isKindOfClass:[NSException class]])
    return projects;
  projectList = [NSMutableArray arrayWithCapacity:16];
  enumerator = [projects objectEnumerator];
  while ((eo = [enumerator nextObject]) != nil) {
    assignment = 
      [self _renderAssignment:[eo valueForKey:@"projectCompanyAssignmentId"]
                       source:[eo valueForKey:@"companyId"]
                       target:[eo valueForKey:@"projectId"]
                           eo:eo];
    [projectList addObject:assignment];
  } /* end loop-project-assignments */
  [_contact setObject:projectList forKey:@"_PROJECTS"];
  return nil;
} /* end _addProjectsToPerson */

-(NSArray *)_getFavoriteContacts:(NSNumber *)_detail {
  NSArray      *favoriteIds;

  favoriteIds = [[self _getDefaults] arrayForKey:@"person_favorites"];
  if (favoriteIds == nil)
    return [NSArray arrayWithObjects:nil];
  return [self _getContactsForKeys:favoriteIds withDetail:_detail];
} /* end _getFavoriteContacts */

/* Build up criteria and do a qsearch for contacts
   TODO: Scary!
   TODO: Should be case insensitive, is that possible?
   TODO: Support subordinate keys like address keys and telephone keys */
-(id)_searchForContacts:(NSArray *)_query 
             withDetail:(NSNumber *)_detail
              withFlags:(NSDictionary *)_flags {
  NSArray         *results;
  NSString        *query;
  NSString        *key;
  NSString        *expression;
  NSString        *conjunction;
  NSDictionary    *qualifier;
  int             count;
  id              tmp;

  query = [NSString stringWithString:@""];
  for(count = 0; count < [_query count]; count++) {
    qualifier = [_query objectAtIndex:count];
    conjunction = [qualifier objectForKey:@"conjunction"];
    key = [qualifier objectForKey:@"key"];
    expression = [qualifier objectForKey:@"expression"];
    if (count > 0) {
      if (conjunction == nil) {
        if ([self isDebug])
          [self logWithFormat:@"contact search - absent conjunction"];
        return [NSException exceptionWithHTTPStatus:500
            reason:@"No conjunction provided in query"];
      } else {
          if ([conjunction isEqualToString:@"AND"])
            query = [query stringByAppendingString:@" AND "];
          else if ([conjunction isEqualToString:@"OR"])
            query = [query stringByAppendingString:@" OR "];
          else {
            if ([self isDebug])
              [self logWithFormat:@"contact search - unknown conjunction"];
            return [NSException exceptionWithHTTPStatus:500
              reason:@"Unrecognized conjunction in query"];
          }
        }
    } // End if (count > 0)
    if(key == nil) {
      if ([self isDebug])
        [self logWithFormat:@"contact search - absent key"];
      return [NSException exceptionWithHTTPStatus:500
                reason:@"Missing key in query"];
    } else {
        key = [self _translateContactKey:key];
        if (key == nil) {
          if ([self isDebug])
            [self logWithFormat:@"contact search - unsupported key"];
          return [NSException exceptionWithHTTPStatus:500
                     reason:@"Unsupported key in query"];

        } else  query = [query stringByAppendingString:key];
      }
    if (expression == nil) {
      if ([self isDebug])
        [self logWithFormat:@"contact search - absent expression"];
      return [NSException exceptionWithHTTPStatus:500
                reason:@"Missing expression in query"];
    } else {
        if ([expression isEqualToString:@"EQUALS"])
          query = [query stringByAppendingString:@" = "];
        else if ([expression isEqualToString:@"LIKE"])
          query = [query stringByAppendingString:@" LIKE "];
        else if ([expression isEqualToString:@"ILIKE"])
          query = [query stringByAppendingString:@" caseInsensitiveLike "];
        else {
          // \todo Throw exception for unsupported expression
          if ([self isDebug])
            [self logWithFormat:@"contact search - unsupported expression"];
          return [NSException exceptionWithHTTPStatus:500
                    reason:@"Unsupported expression in query"];
         }
      }
    if([qualifier objectForKey:@"value"] == nil) {
      // \todo Throw exception for absent value
      if ([self isDebug])
        [self logWithFormat:@"contact search - absent value"];
      return [NSException exceptionWithHTTPStatus:500
                reason:@"Missing value in query"];
    } else {
        tmp = [qualifier objectForKey:@"value"];
        if ([tmp isKindOfClass:[NSNumber class]]) {
          // value is an NSNumber
          query = [query stringByAppendingString:[tmp stringValue]];
        } else if ([tmp isKindOfClass:[NSString class]]) {
           /* Value is an NSString; must be wrapped in quotes */
           query = [query stringByAppendingString:@"\""];
           if ([expression isEqualToString:@"LIKE"]) {
             //[value replaceOccurrencesOfString:@"*" withString:@"%"];
           }
           query = [query stringByAppendingString:tmp];
           query = [query stringByAppendingString:@"\""];
        } else {
            if ([self isDebug])
              [self logWithFormat:@"contact search - unhandled value type"];
            return [NSException exceptionWithHTTPStatus:500
                      reason:@"Unkown value type in query"];
          }
      } 
   } // End for loop of qualifiers
  if ([self isDebug])
    [self logWithFormat:@"contact query: %@", query];
  results = [[self getCTX] runCommand:@"person::qsearch",
                             @"qualifier", query, 
                             @"maxSearchCount", [_flags objectForKey:@"limit"],
                             nil];
  if (results == nil) {
    if ([self isDebug])
      [self logWithFormat:@"contact search - nil result"];
    return [NSNumber numberWithBool:NO];
  }
  return [self _renderContacts:results withDetail:_detail];
} /* end _searchForContacts */

/* Translate zOGI attribute names to OGo Logic attribute names
   TODO: Possibly it would be better to do this with SOPE rules? */
- (NSString *)_translateContactKey:(NSString *)_key {
  if ([_key isEqualToString:@"displayName"]) 
    return [NSString stringWithString:@"nickname"];
  else if ([_key isEqualToString:@"birthDate"])
    return [NSString stringWithString:@"birthday"];
  else if ([_key isEqualToString:@"managersName"])
    return [NSString stringWithString:@"bossname"];
  else if ([_key isEqualToString:@"fileAs"])
    return [NSString stringWithString:@"fileas"];
  else if ([_key isEqualToString:@"firstName"])
    return [NSString stringWithString:@"firstname"];
  else if ([_key isEqualToString:@"middleName"])
    return [NSString stringWithString:@"middlename"];
  else if ([_key isEqualToString:@"lastName"])
    return [NSString stringWithString:@"name"];
  else if ([_key isEqualToString:@"objectId"])
    return [NSString stringWithString:@"companyId"];
  else if ([_key isEqualToString:@"version"])
    return [NSString stringWithString:@"objectVersion"];
  else if ([_key isEqualToString:@"ownerObjectId"])
    return [NSString stringWithString:@"ownerId"];
  else if ([_key isEqualToString:@"managersName"])
    return [NSString stringWithString:@"bossname"];
  else if ([_key isEqualToString:@"gender"])
    return [NSString stringWithString:@"sex"];
  return _key;
} /* end _translateContactKey */

/*
  Delete a Contact/Person
  Currently there are no supported flags, the value of flags is ignored
*/
-(id)_deleteContact:(NSString *)_objectId
              withFlags:(NSArray *)_flags {
  EOGenericRecord   *eo;
  id                 result;

  eo = [self _getUnrenderedContactForKey:_objectId];
  /* delete any company assignments */
  result = [self _saveEnterprisesToPerson:[NSArray arrayWithObjects:nil]
                                 objectId:[eo objectForKey:@"companyId"]];
  if (result == nil) {
    /* delete the object */
    result = [[self getCTX] runCommand:@"person::delete",
                 @"object", eo,
                 @"reallyDelete", [NSNumber numberWithBool:YES],
                 nil];
  }
  eo = nil;
  if ([result isKindOfClass:[NSException class]]) {
    [[self getCTX] rollback];
    [self logWithFormat:@"deletion of contact %@ failed", _objectId];
    return [NSNumber numberWithBool:NO];
  }
  [[self getCTX] commit];
  return [NSNumber numberWithBool:YES]; 
} /* end _deleteContact */

/* Creates a new contact from the provided dictionary.
   Uses _writeContact method with a "new" command */
-(id)_createContact:(NSDictionary *)_contact
               withFlags:(NSArray *)_flags {
  return [self _writeContact:_contact
                 withCommand:@"new"
                   withFlags:_flags];
} /* end _createContact */

/* Update contact 
   Uses _writeContact method with a "set" command */
-(id)_updateContact:(NSDictionary *)_contact
           objectId:(NSString *)_objectId
          withFlags:(NSArray *)_flags {
  return [self _writeContact:_contact
                 withCommand:@"set"
                   withFlags:_flags];
} /* end _updateContact */

-(id)_writeContact:(NSDictionary *)_contact
       withCommand:(NSString *)_command
         withFlags:(NSArray *)_flags {
  return [self _writeCompany:_contact
                 withCommand:_command
                   withFlags:_flags
                   forEntity:@"person"];
} /* end _writeContact */

@end /* End zOGIAction(Contact) */
