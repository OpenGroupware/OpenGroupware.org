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
#include "zOGIAction+Enterprise.h"
#include "zOGIAction+Assignment.h"

@implementation zOGIAction(Enterprise)

-(NSArray *)_renderEnterprises:(NSArray *)_enterprises
                    withDetail:(NSNumber *)_detail 
{
  NSMutableArray      *result;
  EOGenericRecord     *eoEnterprise;
  int                  count;

  result = [NSMutableArray arrayWithCapacity:[_enterprises count]];
  for (count = 0; count < [_enterprises count]; count++) 
  {
    eoEnterprise = [_enterprises objectAtIndex:count];
    [result addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: 
       eoEnterprise, @"*eoObject",
       [eoEnterprise valueForKey:@"companyId"], @"objectId",
       @"Enterprise", @"entityName",
       [self ZERO:[eoEnterprise valueForKey:@"objectVersion"]], @"version",
       [eoEnterprise valueForKey:@"ownerId"], @"ownerObjectId",
       [self NIL:[eoEnterprise valueForKey:@"associatedCategories"]], @"associatedCategories",
       [self NIL:[eoEnterprise valueForKey:@"associatedContacts"]], @"associatedContacts",
       [self NIL:[eoEnterprise valueForKey:@"associatedCompany"]], @"associatedCompany",
       [self NIL:[eoEnterprise valueForKey:@"bank"]], @"bank",
       [self NIL:[eoEnterprise valueForKey:@"bankCode"]], @"bankCode",
       [self NIL:[eoEnterprise valueForKey:@"fileas"]], @"fileAs",
       [self ZERO:[eoEnterprise valueForKey:@"isPrivate"]], @"isPrivate",
       [self NIL:[eoEnterprise valueForKey:@"keywords"]], @"keywords",
       [self NIL:[eoEnterprise valueForKey:@"description"]], @"name",
       [self NIL:[eoEnterprise valueForKey:@"url"]], @"url",
       [self NIL:[eoEnterprise valueForKey:@"imAddress"]], @"imAddress",
       [self NIL:[eoEnterprise valueForKey:@"email"]], @"email",
       [self NIL:[[eoEnterprise objectForKey:@"comment"]
                     valueForKey:@"comment"]], @"comment",
       nil]];
     [self _addAddressesToCompany:[result objectAtIndex:count]];
     [self _addPhonesToCompany:[result objectAtIndex:count]];
     /* Add flags */
     [[result objectAtIndex:count] 
         setObject:[self _renderCompanyFlags:eoEnterprise entityName:@"Enterprise"]
            forKey:@"FLAGS"];
     /* Add detail if required */
     if([_detail intValue] > 0) 
     {
       if([_detail intValue] & zOGI_INCLUDE_COMPANYVALUES)
         [self _addCompanyValuesToCompany:[result objectAtIndex:count]];
       if([_detail intValue] & zOGI_INCLUDE_CONTACTS)
         [self _addContactsToEnterprise:[result objectAtIndex:count]];
       if([_detail intValue] & zOGI_INCLUDE_PROJECTS)
         [self _addProjectsToEnterprise:[result objectAtIndex:count]];
       [self _addObjectDetails:[result objectAtIndex:count] withDetail:_detail];
     } /* End detail-is-required */
     [self _stripInternalKeys:[result objectAtIndex:count]];
  } /* End rendering loop */
  return result;
} /* End _renderEnterprises */

-(NSArray *)_getUnrenderedEnterprisesForKeys:(id)_arg 
{
  NSArray       *enterprises;

  enterprises = [[[self getCTX] runCommand:@"enterprise::get-by-globalid",
                                           @"gids", [self _getEOsForPKeys:_arg],
                                           nil] retain];
  return enterprises;
} /* End _getUnrenderedEnterprisesForKeys */

/*
  Singular instance of _getUnrenderedEnterpriseForKey;  still returns an array
  however so that it can be used with methods that also handle bulk actions.
  This array is guaranteed to be single-valued.
 */
-(id)_getUnrenderedEnterpriseForKey:(id)_arg 
{
  return [[self _getUnrenderedEnterprisesForKeys:_arg] lastObject];
} /* End of _getUnrenderedEnterpriseForKeys */

-(id)_getEnterprisesForKeys:(id)_arg withDetail:(NSNumber *)_detail
{
  return [self _renderEnterprises:
            [self _getUnrenderedEnterprisesForKeys:_arg] withDetail:_detail];
}

-(id)_getEnterpriseForKeys:(id)_pk 
{
  return [self _getEnterprisesForKeys:_pk withDetail:[NSNumber numberWithInt:0]];
}

-(id)_getEnterpriseForKey:(id)_pk withDetail:(NSNumber *)_detail 
{
  id               result;

  result = [self _getEnterprisesForKeys:_pk withDetail:_detail];
  if ([result isKindOfClass:[NSException class]])
    return result;
  if ([result isKindOfClass:[NSMutableArray class]])
    if([result count] == 1)
      return [result objectAtIndex:0];
  return nil;
}

-(id)_getEnterpriseForKey:(id)_pk 
{
  return [self _getEnterpriseForKey:_pk withDetail:[NSNumber numberWithInt:0]];
}

-(void)_addProjectsToEnterprise:(NSMutableDictionary *)_enterprise 
{
  NSArray             *projects;
  NSMutableArray      *projectList;
  NSEnumerator        *enumerator;
  EOGenericRecord     *eo;
  NSMutableDictionary *assignment;

  projects = [[self getCTX] runCommand:@"enterprise::get-project-assignments",
                                       @"withArchived", [NSNumber numberWithBool:YES],
                                       @"object", [_enterprise objectForKey:@"*eoObject"],
                                       nil];
  if (projects == nil) projects = [NSArray array];
  projectList = [NSMutableArray arrayWithCapacity:[projects count]];
  enumerator = [projects objectEnumerator];
  while ((eo = [enumerator nextObject]) != nil) 
  {
    assignment = [self _renderAssignment:[eo valueForKey:@"projectCompanyAssignmentId"]
                                  source:[eo valueForKey:@"companyId"]
                                  target:[eo valueForKey:@"projectId"]
                                      eo:eo];
    [projectList addObject:assignment];
  }
  [_enterprise setObject:projectList forKey:@"_PROJECTS"];
} /* End _addProjectsToEnterprise */

/* Add the _CONTACTS key to the enterprise */
-(void)_addContactsToEnterprise:(NSMutableDictionary *)_enterprise 
{
  NSArray             *assignments;
  NSMutableArray      *contactList;
  NSEnumerator        *enumerator;
  EOGenericRecord     *eo;
  NSMutableDictionary *assignment;

  assignments = [self _getCompanyAssignments:_enterprise key:@"companyId"];
  contactList = [NSMutableArray arrayWithCapacity:[assignments count]];
  enumerator = [assignments objectEnumerator];
  while ((eo = [enumerator nextObject]) != nil) 
  {
    assignment = [self _renderAssignment:[eo valueForKey:@"companyAssignmentId"]
                                  source:[eo valueForKey:@"companyId"]
                                  target:[eo valueForKey:@"subCompanyId"]
                                      eo:eo];
    [contactList addObject:assignment];
  }
  [_enterprise setObject:contactList forKey:@"_CONTACTS"];
} /* End _addContactsToEnterprise */

/* Get the favorite enterprises at the specified detail level 
   TODO: Remove the clumsy creation of an empty array */
-(NSArray *)_getFavoriteEnterprises:(NSNumber *)_detail 
{
  NSArray      *favoriteIds;
  [self logWithFormat:@"_getFavoriteEnterprises()"];
  favoriteIds = [[self _getDefaults] arrayForKey:@"enterprise_favorites"];
  if (favoriteIds == nil)
    return [[NSArray alloc] initWithObjects:nil];
  return [self _getEnterprisesForKeys:favoriteIds withDetail:_detail];
} /* End _getFavoriteEnterprises */

-(id)_searchForEnterprises:(NSArray *)_query 
                withDetail:(NSNumber *)_detail 
{
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
    if (count > 0) 
    {
      if (conjunction == nil) 
      {
        if ([self isDebug])
          [self logWithFormat:@"enterprise search - absent conjunction"];
        return [NSException exceptionWithHTTPStatus:500
                  reason:@"Missing conjunction query"];
      } else
        {
          if ([conjunction isEqualToString:@"AND"])
            query = [query stringByAppendingString:@" AND "];
          else if ([conjunction isEqualToString:@"OR"])
            query = [query stringByAppendingString:@" OR "];
          else 
          {
            if ([self isDebug])
              [self logWithFormat:@"enterprise search - unknown conjunction"];
            return [NSException exceptionWithHTTPStatus:500
                      reason:@"Unsupported conjunction query"];
          }
        }
    } // End if (count > 0)
    if(key == nil) 
    {
      if ([self isDebug])
        [self logWithFormat:@"enterprise search - absent key"];
      return [NSException exceptionWithHTTPStatus:500
                reason:@"Missing key in query"];
    } else
      {
        key = [self _translateEnterpriseKey:key];
        if(key == nil) 
        {
          // \todo Throw exception for unsupported key
          if ([self isDebug])
            [self logWithFormat:@"enterprise search - unsupported key"];
          return [NSException exceptionWithHTTPStatus:500
                    reason:@"Unsupported key in query"];
        } else  query = [query stringByAppendingString:key];
      }
    if (expression == nil) 
    {
      // \todo Throw exception for absent expression
      if ([self isDebug])
        [self logWithFormat:@"enterprise search - absent expression"];
      return [NSException exceptionWithHTTPStatus:500
                reason:@"Missing expression in query"];
    } else 
      {
        if ([expression isEqualToString:@"EQUALS"])
          query = [query stringByAppendingString:@" = "];
        else if ([expression isEqualToString:@"LIKE"])
          query = [query stringByAppendingString:@" LIKE "];
        else if ([expression isEqualToString:@"ILIKE"])
          query = [query stringByAppendingString:@" caseInsensitiveLike "];
        else 
        {
          if ([self isDebug])
            [self logWithFormat:@"enterprise search - unsupported expression"];
          return [NSException exceptionWithHTTPStatus:500
                    reason:@"Unsupported expression in query"];
         }
      }
    if([qualifier objectForKey:@"value"] == nil) 
    {
      if ([self isDebug])
        [self logWithFormat:@"enterprise search - absent value"];
      return [NSException exceptionWithHTTPStatus:500
                reason:@"Missing value in query"];
    } else 
      {
        tmp = [qualifier objectForKey:@"value"];
        if ([tmp isKindOfClass:[NSNumber class]]) 
        {
          // value is an NSNumber
          query = [query stringByAppendingString:[tmp stringValue]];
        } else if ([tmp isKindOfClass:[NSString class]]) 
          {
           /* Value is an NSString; must be wrapped in quotes */
           query = [query stringByAppendingString:@"\""];
           if ([expression isEqualToString:@"LIKE"]) 
           {
             //[value replaceOccurrencesOfString:@"*" withString:@"%"];
           }
           query = [query stringByAppendingString:tmp];
           query = [query stringByAppendingString:@"\""];
        } else 
          {
            // \todo Throw exception for unhandled value class type
            if ([self isDebug])
              [self logWithFormat:@"enterprise search - unhandled value type"];
            return [NSException exceptionWithHTTPStatus:500
                      reason:@"Unknown value type in query"];
          }
      } 
   } // End for loop of qualifiers
  if ([self isDebug])
    [self logWithFormat:@"enterprise query: %@", query];
  results = [[self getCTX] runCommand:@"enterprise::qsearch",
                             @"qualifier", query, 
                             @"maxSearchCount", [NSNumber numberWithInt:100],
                             nil];
  if (results == nil) 
  {
    if ([self isDebug])
      [self logWithFormat:@"enterprise search - nil result"];
    return [NSNumber numberWithBool:NO];
  }
  return [self _renderEnterprises:results withDetail:_detail];
}

/*
  Delete an Enterprise
  Currently there are no supported flags, the value of flags is ignored
  TODO: Do we need to delete the fake project?
  TODO: Return exceptions
*/
-(id)_deleteEnterprise:(NSString *)_objectId
              withFlags:(NSArray *)_flags 
{
  id	eo;
  
  eo = [self _getUnrenderedEnterpriseForKey:_objectId];
  /* delete any company assignments */
  [self _savePersonsToEnterprise:[[NSArray alloc] init]
                        objectId:[eo objectForKey:@"companyId"]];
  [[self getCTX] runCommand:@"enterprise::delete",
                 @"object", eo,
                 @"reallyDelete", [NSNumber numberWithBool:YES],
                 nil];
  [[self getCTX] commit];
  return [NSNumber numberWithBool:YES];
} /* End _deleteEnterprise */

-(NSString *)_translateEnterpriseKey:(NSString *)_key 
{
  if ([_key isEqualToString:@"objectId"])
    return [NSString stringWithString:@"companyId"];
  else if ([_key isEqualToString:@"version"])
    return [NSString stringWithString:@"objectVersion"];
  else if ([_key isEqualToString:@"ownerObjectId"])
    return [NSString stringWithString:@"ownerId"];
  else if ([_key isEqualToString:@"name"])
    return [NSString stringWithString:@"description"];
  else if ([_key isEqualToString:@"fileAs"])
    return [NSString stringWithString:@"fileas"];
  return _key;
} /* End _translateEnterpriseKey */

/* Creates a new enterprise from the provided dictionary. */
-(id)_createEnterprise:(NSDictionary *)_enterprise
             withFlags:(NSArray *)_flags 
{
  return [self _writeEnterprise:_enterprise
                 withCommand:@"new"
                   withFlags:_flags];
} /* End _createEnterprise */

/* Update enterprise */
-(id)_updateEnterprise:(NSDictionary *)_enterprise
              objectId:(NSString *)_objectId
             withFlags:(NSArray *)_flags 
{
  return [self _writeEnterprise:_enterprise
                     withCommand:@"set"
                       withFlags:_flags];
} /* End _updateEnterprise */

/* Store the provided enterprise relationship  
   Uses _saveCompanyAssignments */
-(NSException *)_savePersonsToEnterprise:(NSArray *)_assignments 
                                objectId:(id)_objectId 
{
  return [self _saveCompanyAssignments:_assignments 
                              objectId:_objectId
                                   key:@"companyId"
                          targetEntity:@"Person"
                             targetKey:@"subCompanyId"];
} /* End _savePersonsToEnterprise */

-(id)_writeEnterprise:(NSDictionary *)_enterprise
          withCommand:(NSString *)_command
            withFlags:(NSArray *)_flags
{
  return [self _writeCompany:_enterprise
                  withCommand:_command
                    withFlags:_flags
                    forEntity:@"enterprise"];
} /* End _writeEnterprise */

/* Save contact entries */
-(NSException *)_saveBusinessCards:(NSArray *)_contacts
                      enterpriseId:(id)_enterpriseId
{
  NSEnumerator    *enumerator;
  NSDictionary    *contact;
  NSDictionary    *tmp;
  
  if (_contacts == nil) 
    return nil;
  enumerator = [_contacts objectEnumerator];
  while((contact = [enumerator nextObject]) != nil)
  {
    tmp = [self _createContact:contact 
                     withFlags:[NSArray arrayWithObject:@"noCommit"]];
    [[self getCTX] runCommand:@"companyassignment::new"
        arguments:[NSDictionary dictionaryWithObjectsAndKeys:
                     [tmp objectForKey:@"objectId"],
                     @"subCompanyId",
                     _enterpriseId, 
                     @"companyId",
                     nil]];
  } /* End save contacts loop */
  return nil;
} /* End _saveBusinessCards */

@end /* End zOGIAction(Enterprise) */
