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
#include "zOGIRPCAction.h"
#include "NSObject+zOGI.h"
#include "zOGIAction+Appointment.h"
#include "zOGIAction+Contact.h"
#include "zOGIAction+Enterprise.h"
#include "zOGIAction+Project.h"
#include "zOGIAction+Resource.h"
#include "zOGIAction+Task.h"
#include "zOGIAction+Account.h"
#include "zOGIAction+Team.h"
#include "zOGIAction+Object.h"
#include "zOGIAction+Note.h"
#include "common.h"

/*
  zOGI Generic Action
*/
@implementation zOGIRPCAction

- (void)dealloc {
  [super dealloc];
}

/* methods */

-(id)getLoginAccountAction {
  return [self _getLoginAccount:arg1];
} /* End getLoginAccountAction */

-(id)getTypeOfObjectAction {
  return [self _izeEntityName:[self _getEntityNameForPKey:[self arg1]]];
  //return [self arg];
}

-(id)getFavoritesByTypeAction
{
  if([arg1 isKindOfClass:[NSString class]]) 
  {
    if ([arg1 isEqualToString:@"Contact"])
      return [self _getFavoriteContacts:arg2];
    else if ([arg1 isEqualToString:@"Enterprise"])
      return [self _getFavoriteEnterprises:arg2];
    else if ([arg1 isEqualToString:@"Project"])
      return [self _getFavoriteProjects:arg2];
  }
  return [NSException exceptionWithHTTPStatus:500
            reason:@"Favorites not supported for this entity"];
}

-(id)flagFavoritesAction 
{
  NSArray      *objectList;
  NSEnumerator *enumerator;
  id            objectId;
  NSString     *entityName;

  if ([arg1 isKindOfClass:[NSString class]])
    objectList = [arg1 componentsSeparatedByString:@","];
  else if ([arg1 isKindOfClass:[NSNumber class]])
    objectList = [NSArray arrayWithObject:arg1];
  else 
    objectList = arg1;
  enumerator = [objectList objectEnumerator];
  while ((objectId = [enumerator nextObject]) != nil) 
  {
    entityName = [self _getEntityNameForPKey:objectId];
    if ([entityName isEqualToString:@"Project"])
      [self _favoriteObject:objectId defaultKey:@"project_favorites"];
    else if ([entityName isEqualToString:@"Enterprise"])
      [self _favoriteObject:objectId defaultKey:@"enterprise_favorites"];
    else if ([entityName isEqualToString:@"Person"])
      [self _favoriteObject:objectId defaultKey:@"person_favorites"];
    else return [NSException exceptionWithHTTPStatus:500
                   reason:@"Favorites not supported for this entity"];
  }
  return [NSNumber numberWithBool:YES];
} /* End flagFavoritesAction */

-(id)unflagFavoritesAction 
{
  NSArray      *objectList;
  NSEnumerator *enumerator;
  id            objectId;
  NSString     *entityName;

  [self logWithFormat:@"flagFavoritesAction(%@)", arg1];
  if ([arg1 isKindOfClass:[NSString class]])
    objectList = [arg1 componentsSeparatedByString:@","];
  else if ([arg1 isKindOfClass:[NSNumber class]])
    objectList = [NSArray arrayWithObject:arg1];
  else
    objectList = arg1;
  enumerator = [objectList objectEnumerator];
  while ((objectId = [enumerator nextObject]) != nil) 
  { 
    entityName = [self _getEntityNameForPKey:objectId];
    if ([entityName isEqualToString:@"Project"])
      [self _unfavoriteObject:objectId defaultKey:@"project_favorites"];
    else if ([entityName isEqualToString:@"Enterprise"])
      [self _unfavoriteObject:objectId defaultKey:@"enterprise_favorites"];
     else if ([entityName isEqualToString:@"Person"])
      [self _unfavoriteObject:objectId defaultKey:@"person_favorites"];
    else return [NSException exceptionWithHTTPStatus:500
                   reason:@"Favorites not supported for this entity"];
  }
  [self logWithFormat:@"unflagFavoritesAction - complete"];
  return [NSNumber numberWithBool:YES];
} /* End unflagFavoritesAction */

-(id)getObjectsByObjectIdAction 
{
  
  NSArray    	  *objectList;
  NSMutableArray  *result;
  NSEnumerator    *enumerator;
  id              objectId, object;

  if (![arg1 isKindOfClass:[NSArray class]])
    objectList = [NSArray arrayWithObject:arg1];
   else 
     objectList = arg1;
  enumerator = [objectList objectEnumerator];
  result = [NSMutableArray arrayWithCapacity:[objectList count]];
  while ((objectId = [enumerator nextObject]) != nil) 
  {
    object = [self _getObjectByObjectId:objectId withDetail:arg2];
    if ([object isKindOfClass:[NSException class]])
      return object;
    else
      [result addObject:object];
  }
  return result;
} /* End getObjectsByObjectIdAction */

-(id)getObjectByObjectIdAction 
{
  id               object;

  object = [self _getObjectByObjectId:arg1 withDetail:arg2];
  if (object == nil)
    return [self _makeUnknownObject:arg1];
  return object;
}

-(id)getObjectVersionsByObjectIdAction {
  NSArray    	  *objectList;
  NSString        *entityName;
  NSMutableArray  *result;
  NSEnumerator    *enumerator;
  NSNumber        *version;
  id              objectId;
  id              document;

  if (![arg1 isKindOfClass:[NSArray class]])
    objectList = [NSArray arrayWithObject:arg1];
   else 
     objectList = arg1;
  enumerator = [objectList objectEnumerator];
  result = [[NSMutableArray alloc] initWithCapacity:[objectList count]];
  while ((objectId = [enumerator nextObject]) != nil) {
    document = [[self getCTX] runCommand:@"object::get-by-globalid", 
                                         @"gid", [self _getEOForPKey:objectId], 
                                         nil];
    if (document != nil) {
      version = [[document valueForKey:@"objectVersion"] lastObject];
      if ([version class] == [EONull class])
        version = [NSNumber numberWithInt:0];
      if (version != nil) {
        entityName = [self _izeEntityName:[self _getEntityNameForPKey:objectId]];
        [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                             objectId, @"objectId", 
                             entityName, @"entityName",
                             version, @"version",
                             nil]];
       } // End If version is not nil
     } // End if document is not nil
   } // End while nextObject
  return result;
}

-(id)putObjectAction 
{ 
  NSString      *objectId;
  id             obj;
  NSArray       *flags;

  /* Initialize the update operation flags */
  if ([arg1 objectForKey:@"_FLAGS"] == nil) 
  {
    flags = [[NSArray alloc] init];
  } else {
      if ([[arg1 objectForKey:@"_FLAGS"] isKindOfClass:[NSArray class]])
        flags = [arg1 objectForKey:@"_FLAGS"];
      else if ([[arg1 objectForKey:@"_FLAGS"] isKindOfClass:[NSString class]])
        flags = [[arg1 objectForKey:@"_FLAGS"] componentsSeparatedByString:@","];
      else flags = [[NSArray alloc] init];
     }

  obj = nil;
  // Determine objectId
  if ([arg1 objectForKey:@"objectId"] == nil) {
    objectId = [NSString stringWithString:@"0"];
   } else {
        if ([[arg1 objectForKey:@"objectId"] isKindOfClass:[NSNumber class]])
          objectId = [[arg1 objectForKey:@"objectId"] stringValue];
        else 
          objectId = [arg1 objectForKey:@"objectId"];
      }
  // Do the deed
  if ([objectId isEqualToString:@"0"]) {
    obj = [self _createObject:arg1 withFlags:flags];
   } else {
       obj = [self _updateObject:arg1 objectId:objectId withFlags:flags];
      }
  if (obj == nil) {
    // \todo Throw Exception
   } 
  return obj;
} /* End putObjectAction */

-(id)deleteObjectAction 
{
  NSString     *entityName, *objectId;
  NSArray      *flags;

  objectId = nil;
  entityName = nil;
  /* Deal with arg1 (determining objectId) */
  if ([arg1 isKindOfClass:[NSDictionary class]]) 
  {
    entityName = [arg1 objectForKey:@"entityName"];
    objectId = [arg1 objectForKey:@"objectId"];
  } else if ([arg1 isKindOfClass:[NSString class]] ||
              [arg1 isKindOfClass:[NSNumber class]]) 
       objectId = arg1;
  if (objectId == nil)
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"Unable to determine id of object to delete"];
  if ([objectId isKindOfClass:[NSNumber class]])
    objectId = [objectId stringValue];
  /* Deal with arg2 (flags) */
  if (arg2 == nil)
    flags = [[NSArray alloc] init];
  else if ([arg2 isKindOfClass:[NSString class]])
    flags = [arg2 componentsSeparatedByString:@","];
  else if ([arg2 isKindOfClass:[NSArray class]])
    flags = arg2;
  else return [NSException exceptionWithHTTPStatus:500
                        reason:@"Unrecognized flags type for object deletion"];
  /* Find the entity name if it was not set. */
  if (entityName == nil)
    entityName = [self _getEntityNameForPKey:objectId];
  if (entityName == nil)
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"Deletion of invalid key requested"];
  /* Select the correct deletion method based on entityName */
  if ([entityName isEqualToString:@"Task"])
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"Deletion of tasks is not supported"];
  else if ([entityName isEqualToString:@"Appointment"] ||
            [entityName isEqualToString:@"Date"])
    return [self _deleteAppointment:objectId withFlags:flags];
  else if ([entityName isEqualToString:@"Person"] ||
            [entityName isEqualToString:@"Contact"])
    return [self _deleteContact:objectId withFlags:flags];
  else if ([entityName isEqualToString:@"Enterprise"])
    return [self _deleteEnterprise:objectId withFlags:flags];
  else if ([entityName isEqualToString:@"Project"])
    return [self _deleteProject:objectId withFlags:flags];
  /* Blow back an exception if we got this far */
  return [NSException exceptionWithHTTPStatus:500
                      reason:@"Unknown deletion requested"];
} /* End deleteObjectAction */

- (id)_createObject:(id)_dictionary 
          withFlags:(NSArray *)_flags 
{
  NSString      *entityName;

  entityName = [_dictionary objectForKey:@"entityName"];
  if ([entityName isEqualToString:@"Task"])
    return [self _createTask:_dictionary];
  else if ([entityName isEqualToString:@"taskNotation"])
    return [self _createTaskNotation:_dictionary];
  else if ([entityName isEqualToString:@"Appointment"])
    return [self _createAppointment:_dictionary withFlags:_flags];
  else if ([entityName isEqualToString:@"Project"])
    return [self _createProject:_dictionary withFlags:_flags];
  else if ([entityName isEqualToString:@"Contact"])
    return [self _createContact:_dictionary withFlags:_flags];
  else if ([entityName isEqualToString:@"Enterprise"])
    return [self _createEnterprise:_dictionary withFlags:_flags];
  return nil;
} /* End _createObject */

- (id)_updateObject:(id)_dictionary  
           objectId:(NSString *)_objectId 
          withFlags:(NSArray *)_flags {
  NSString      *entityName;

  entityName = [_dictionary objectForKey:@"entityName"];
  if ([entityName isEqualToString:@"Project"]) {
    return [self _updateProject:_dictionary 
                    objectId:_objectId
                   withFlags:_flags];
  } else if ([entityName isEqualToString:@"Task"]) {
    return [self _updateTask:_dictionary 
                    objectId:_objectId
                   withFlags:_flags];
  } else if ([entityName isEqualToString:@"Appointment"]) {
    return [self _updateAppointment:_dictionary 
                           objectId:_objectId 
                          withFlags:_flags];
  } else if ([entityName isEqualToString:@"note"]) {
       return [self _updateNote:[_dictionary objectForKey:@"objectId"]
                      withTitle:[_dictionary objectForKey:@"title"]
                    withContent:[_dictionary objectForKey:@"content"]];
  } else if ([entityName isEqualToString:@"Contact"]) {
        return [self _updateContact:_dictionary
                           objectId:_objectId
                          withFlags:_flags];
  } else if ([entityName isEqualToString:@"Enterprise"]) {
         return [self _updateEnterprise:_dictionary
                                objectId:_objectId
                               withFlags:_flags];
  } else if ([entityName isEqualToString:@"ParticipantStatus"]) {
         return [self _setParticipantStatus:_dictionary 
                                   objectId:_objectId
                                  withFlags:_flags];
  }
  return nil;
}

// \brief Search for Objects
// \param arg1 Entity Name (string)
// \param arg2 Search criteria (mixed)
// \param arg3 Detail Level (int)
-(id)searchForObjectsAction 
{
  if ([arg1 isEqualToString:@"Contact"])
    return [self _searchForContacts:arg2 withDetail:arg3];
  else if ([arg1 isEqualToString:@"Enterprise"])
    return [self _searchForEnterprises:arg2 withDetail:arg3];
  else if ([arg1 isEqualToString:@"Appointment"])
    return [self _searchForAppointments:arg2 withDetail:arg3];
  else if ([arg1 isEqualToString:@"Task"])
    return [self _searchForTasks:arg2 withDetail:arg3];
  else if ([arg1 isEqualToString:@"Project"])
    return [self _searchForProjects:arg2 withDetail:arg3];
  else if ([arg1 isEqualToString:@"Resource"])
    return [self _searchForResources:arg2 withDetail:arg3];
  else if ([arg1 isEqualToString:@"Team"])
    return [self _searchForTeams:arg2 withDetail:arg3];
  return [NSNumber numberWithBool:NO];
}

@end
