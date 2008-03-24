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
#include "zOGIAction+Defaults.h"
#include "zOGIAction+Enterprise.h"
#include "zOGIAction+Project.h"
#include "zOGIAction+Resource.h"
#include "zOGIAction+Task.h"
#include "zOGIAction+Account.h"
#include "zOGIAction+Team.h"
#include "zOGIAction+Object.h"
#include "zOGIAction+Note.h"
#include "zOGIAction+Notifications.h"
#include "common.h"

/*
  zOGI Generic Action
*/
@implementation zOGIRPCAction

-(id)init
{
  self = [super init];
  if (self)  {
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

/* methods */

-(id)getLoginAccountAction {
  return [self _getLoginAccount:arg1];
} /* end getLoginAccountAction */

-(id)getTypeOfObjectAction {
  return [self _izeEntityName:[self _getEntityNameForPKey:[self arg1]]];
} /* end getTypeOfObjectAction */

-(id)getFavoritesByTypeAction {
  if([arg1 isKindOfClass:[NSString class]]) {
    if ([arg1 isEqualToString:@"Contact"])
      return [self _getFavoriteContacts:arg2];
    else if ([arg1 isEqualToString:@"Enterprise"])
      return [self _getFavoriteEnterprises:arg2];
    else if ([arg1 isEqualToString:@"Project"])
      return [self _getFavoriteProjects:arg2];
  }
  return [NSException exceptionWithHTTPStatus:500
            reason:@"Favorites not supported for this entity"];
} /* end getFavoritesByTypeAction */

-(id)flagFavoritesAction {
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
  while ((objectId = [enumerator nextObject]) != nil) {
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
} /* end flagFavoritesAction */

-(id)unflagFavoritesAction {
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
} /* end unflagFavoritesAction */

-(id)getObjectsByObjectIdAction {
  NSArray    	         *keyList;
  NSMutableDictionary  *flags;
  NSEnumerator         *enumerator;
  NSString             *filterString;
  EOQualifier          *eoFilter;
  id                    pkey, gid, object, tmp, results;
  NSTimeInterval        start, end;

  if (arg3 == nil) {
    flags = [NSMutableDictionary new];
    if ([self isDebug])
      [self logWithFormat:@"No flags provided, assuming an empty set of flags."];
  } else flags = [arg3 mutableCopy];

  NSMutableArray  *contacts = nil;
  NSMutableArray  *enterprises = nil;

  /* remainder accumulates all the objects that are not setup
     to perform bulk get from Logic. */
  NSMutableArray  *remainder = nil;

  if ([self isProfile])
    start = [[NSDate date] timeIntervalSince1970];

  /* if arg1 is not an array then make a single object array
     from the arg1 */
  if (![arg1 isKindOfClass:[NSArray class]])
    keyList = [NSArray arrayWithObject:arg1];
  else 
    keyList = arg1;

  results = [NSMutableArray arrayWithCapacity:[keyList count]];

  /* classify requested objects by type so we can do bulk fetches */
  enumerator = [keyList objectEnumerator];
  while ((pkey = [enumerator nextObject]) != nil) {
    gid = [self _getEOForPKey:pkey]; 
    if (gid == nil) {
      /* if no gid can be identified for the specified objectId
         then we generate and UnknownObject entity.  this 
         signals the client to purge the specified entity from
         its cache as it no longer exists or never existed */
      [results addObject:[self _makeUnknownObject:pkey]];
    } else if ([[gid entityName] isEqualToString:@"Person"]) {
      if (contacts == nil)
        contacts = [NSMutableArray arrayWithCapacity:128];
      [contacts addObject:gid];
    } else if ([[gid entityName] isEqualToString:@"Enterprise"]) {
      if (enterprises == nil)
        enterprises = [NSMutableArray arrayWithCapacity:128];
      [enterprises addObject:gid];
    } else {
        if (remainder == nil)
          remainder = [NSMutableArray arrayWithCapacity:128];
        [remainder addObject:gid];
      }
  } /* end while */

  if ([self isDebug]) {
     if ([contacts isNotNull])
       [self logWithFormat:@"prepared to request %d contact entities", 
               [contacts count]];
     if ([enterprises isNotNull])
       [self logWithFormat:@"prepared to request %d enterprise entities", 
               [enterprises count]];
     if ([remainder isNotNull])
       [self logWithFormat:@"prepared to request %d other entities", 
               [remainder count]];
  }

  /* get the results */
  if ([contacts isNotNull]) {
    /* get requested contacts as a bulk operation */
    if ([self isDebug])
      [self logWithFormat:@"performing contact bulk request"];
    tmp = [self _getContactsForKeys:contacts withDetail:arg2];
    if ([self isDebug])
      [self logWithFormat:@"bulked %d contacts", [tmp count]];
    [results addObjectsFromArray:tmp];
  } /* end get-contacts */
  if ([enterprises isNotNull]) {
    /* get requested enterprises as a bulk operation */
    if ([self isDebug])
      [self logWithFormat:@"performing enterprise bulk request"];
    tmp = [self _getEnterprisesForKeys:enterprises withDetail:arg2];
    if ([self isDebug])
      [self logWithFormat:@"bulked %d enterprises", [tmp count]];
    [results addObjectsFromArray:tmp];
  } /* end get-enterprises */
  if ([remainder isNotNull]) {
    /* Get the non-bulk operation entities */
    if ([self isDebug])
      [self logWithFormat:@"performing one-by-one requests"];
    enumerator = [remainder objectEnumerator];
    while ((gid = [enumerator nextObject]) != nil) {
      if ([self isDebug])
        [self logWithFormat:@"requesting %@ one-by-one", gid];
      object = [self _getObjectByObjectId:gid withDetail:arg2];
      if ([object isNotNull]) {
        if ([object isKindOfClass:[NSException class]])
          return object;
        else
          [results addObject:object];
      } else {
          [self warnWithFormat:@"getObjectByObjectId produced a NULL object"];
         }
    } /* end while remainder */
  } /* end get-remainder */

  if ([flags objectForKey:@"filter"]) {
    filterString = [flags objectForKey:@"filter"];
    if ([self isDebug])
      [self logWithFormat:@"Filtering %d objects with EOQualifier",
         [results count]];
    eoFilter = [EOQualifier qualifierWithQualifierFormat:filterString];
    results = [results filteredArrayUsingQualifier:eoFilter];
  }

  /* log command duration */
  if ([self isProfile]) {
    end = [[NSDate date] timeIntervalSince1970];
    [self logWithFormat:@"getObjectsByObjectId returning %d objects",
            [results count]];
    [self logWithFormat:@"getObjectsByObjectId consumed %.3f seconds", 
            (end - start)];
    [self logWithFormat:@"end getObjectsByObjectId"];
  }

  return results;
} /* end getObjectsByObjectIdAction */

-(id)getObjectByObjectIdAction {
  id               object;

  object = [self _getObjectByObjectId:arg1 withDetail:arg2];
  if (object == nil)
    return [self _makeUnknownObject:[arg1 stringValue]];
  return object;
} /* end getObjectByObjectIdAction */

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
  result = [NSMutableArray arrayWithCapacity:[objectList count]];
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
       } // end if version is not nil
     } // end if document is not nil
   } // end while nextObject
  return result;
} /* end getObjectVersionsByObjectIdAction */

-(id)putObjectAction {
  NSString      *objectId;
  id             obj;
  NSArray       *flags;

  /* initialize the update operation flags */
  if ([arg1 objectForKey:@"_FLAGS"] == nil) {
    flags = [[NSArray alloc] init];
  } else {
      if ([[arg1 objectForKey:@"_FLAGS"] isKindOfClass:[NSArray class]])
        flags = [arg1 objectForKey:@"_FLAGS"];
      else if ([[arg1 objectForKey:@"_FLAGS"] isKindOfClass:[NSString class]])
        flags = [[arg1 objectForKey:@"_FLAGS"] componentsSeparatedByString:@","];
      else flags = [[NSArray alloc] init];
     }

  obj = nil;
  // determine objectId
  if ([arg1 objectForKey:@"objectId"] == nil) {
    objectId = [NSString stringWithString:@"0"];
   } else {
        if ([[arg1 objectForKey:@"objectId"] isKindOfClass:[NSNumber class]])
          objectId = [[arg1 objectForKey:@"objectId"] stringValue];
        else 
          objectId = [arg1 objectForKey:@"objectId"];
      }
  // do the deed
  if ([objectId isEqualToString:@"0"]) {
    obj = [self _createObject:arg1 withFlags:flags];
   } else {
       obj = [self _updateObject:arg1 objectId:objectId withFlags:flags];
      }
  if (obj == nil) {
    // \todo Throw Exception
   } 
  return obj;
} /* end putObjectAction */

-(id)deleteObjectAction {
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

  /* feal with arg2 (flags) */
  if (arg2 == nil)
    flags = [[NSArray alloc] init];
  else if ([arg2 isKindOfClass:[NSString class]])
    flags = [arg2 componentsSeparatedByString:@","];
  else if ([arg2 isKindOfClass:[NSArray class]])
    flags = arg2;
  else return [NSException exceptionWithHTTPStatus:500
                        reason:@"Unrecognized flags type for object deletion"];

  /* find the entity name if it was not set. */
  if (entityName == nil)
    entityName = [self _getEntityNameForPKey:objectId];
  if (entityName == nil)
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"Deletion of invalid key requested"];

  /* select the correct deletion method based on entityName */
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

  /* blow back an exception if we got this far */
  return [NSException exceptionWithHTTPStatus:500
                      reason:@"Unknown deletion requested"];
} /* end deleteObjectAction */

- (id)_createObject:(id)_dictionary 
          withFlags:(NSArray *)_flags {
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
  else if ([entityName isEqualToString:@"defaults"])
    return [self _storeDefaults:_dictionary withFlags:_flags];
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
  } else if ([entityName isEqualToString:@"Team"]) {
         return [self _updateTeam:_dictionary
                         objectId:_objectId
                        withFlags:_flags];
  }
  return nil;
} /* end _updateObject */

-(id)searchForObjectsAction {
  id                   result;
  NSString            *filterString;
  EOQualifier         *eoFilter;
  NSMutableDictionary *flags;
  NSTimeInterval       start, end;

  if ([self isProfile]) 
    start = [[NSDate date] timeIntervalSince1970];

  if (arg4 == nil) {
    flags = [NSMutableDictionary dictionaryWithCapacity:4];
    if ([self isDebug])
      [self logWithFormat:@"No flags provided, assuming an empty set of flags."];
  } else flags = [arg4 mutableCopy];

  /* if no limit flag is provided we assume a limit of 150 */
  if ([flags objectForKey:@"limit"] == nil) {
    if ([self isDebug])
      [self logWithFormat:@"No limit in flags, assuming default."];
    [flags setObject:intObj(150) forKey:@"limit"];
  }

  if ([arg1 isEqualToString:@"Contact"]) {
    /* SEARCH FOR CONTACTS */
    result = [self _searchForContacts:arg2 withDetail:arg3 withFlags:flags];
    if ([[flags objectForKey:@"revolve"] isEqualToString:@"YES"]) {
      id                   tmp1, tmp2, enterpriseId;
      NSMutableArray      *tmpList;
      NSEnumerator        *enumerator1, *enumerator2;

      if ([self isDebug])
        [self logWithFormat:@"revolving enterprises for %d contacts",
           [result count]];
      tmpList = [NSMutableArray arrayWithCapacity:[result count]];
      enumerator1 = [result objectEnumerator];
      while ((tmp1 = [enumerator1 nextObject]) != nil) {
        if ([self isDebug])
          [self logWithFormat:@"revolving enterprises for contact#%@",
             [tmp1 objectForKey:@"objectId"]];
        if ([tmp1 objectForKey:@"_ENTERPRISES"] != nil) {
          enumerator2 = [[tmp1 objectForKey:@"_ENTERPRISES"] objectEnumerator];
          while ((tmp2 = [enumerator2 nextObject]) != nil) {
            if ([self isDebug])
              [self logWithFormat:@"contact assigned to enterprise#%@",
                 [tmp2 objectForKey:@"targetObjectId"]];
            enterpriseId = [tmp2 objectForKey:@"targetObjectId"];
            if([tmpList indexOfObjectIdenticalTo:enterpriseId] == NSNotFound)
              [tmpList addObject:enterpriseId];
          } /* end while tmp2 */
        } /* end if-tmp1-has-enterprises */
      } /* end while tmp1 */
      if ([self isDebug])
        [self logWithFormat:@"requesting %d enterprises for revolution",
           [tmpList count]];
      if ([tmpList count] > 0)
        [result addObjectsFromArray:[self _getEnterprisesForKeys:tmpList withDetail:arg2]];
    } /* end if-revolve-requested */
  } else if ([arg1 isEqualToString:@"Enterprise"]) {
    /* SEARCH FOR ENTERPRISE */
    result = [self _searchForEnterprises:arg2 withDetail:arg3 withFlags:flags];
    if ([[flags objectForKey:@"revolve"] isEqualToString:@"YES"]) {
      NSMutableArray      *tmpList;
      id	           tmp1, tmp2, contactId;
      NSEnumerator        *enumerator1, *enumerator2;

      if ([self isDebug])
        [self logWithFormat:@"revolving contacts for %d enterprises",
          [result count]];
      tmpList = [NSMutableArray arrayWithCapacity:[result count]];
      enumerator1 = [result objectEnumerator];
      while ((tmp1 = [enumerator1 nextObject]) != nil) {
        if ([self isDebug])
          [self logWithFormat:@"revolving contacts for enterprise#%@",
             [tmp1 objectForKey:@"objectId"]];
        if ([tmp1 objectForKey:@"_CONTACTS"] != nil) {
          enumerator2 = [[tmp1 objectForKey:@"_CONTACTS"] objectEnumerator];
          while ((tmp2 = [enumerator2 nextObject]) != nil) {
            if ([self isDebug])
              [self logWithFormat:@"enterprise assigned to contact#%@",
                 [tmp2 objectForKey:@"targetObjectId"]];
            contactId = [tmp2 objectForKey:@"targetObjectId"];
            if([tmpList indexOfObjectIdenticalTo:contactId] == NSNotFound)
              [tmpList addObject:contactId];
          } /* end while tmp2 */
        } /* end if-tmp1-has-enterprises */
      } /* end while tmp1 */
      if ([self isDebug])
        [self logWithFormat:@"requesting %d contacts for revolution",
           [tmpList count]];
      if ([tmpList count] > 0)
        [result addObjectsFromArray:[self _getContactsForKeys:tmpList withDetail:arg2]];
    } /* end if-revolve-requested */
  } else if ([arg1 isEqualToString:@"Appointment"])
    /* SEARCH FOR APPOINTMENTS */
    result = [self _searchForAppointments:arg2 withDetail:arg3 withFlags:flags];
  else if ([arg1 isEqualToString:@"Task"])
    /* SEARCH FOR TASKS */
    result = [self _searchForTasks:arg2 withDetail:arg3 withFlags:flags];
  else if ([arg1 isEqualToString:@"Project"])
    /* SEARCH FOR PROJECTS */
    result = [self _searchForProjects:arg2 withDetail:arg3 withFlags:flags];
  else if ([arg1 isEqualToString:@"Resource"])
    /* SEARCH FOR RESOURCES */
    result = [self _searchForResources:arg2 withDetail:arg3 withFlags:flags];
  else if ([arg1 isEqualToString:@"Team"])
    /* SEARCH FOR TEAMS */
    result = [self _searchForTeams:arg2 withDetail:arg3 withFlags:flags];
  else if ([arg1 isEqualToString:@"TimeZones"])
    /* SEARCH FOR TIMEZONES */
    result = [self _searchForTimeZones:arg2 withDetail:arg3 withFlags:flags];
  else if ([arg1 isEqualToString:@"Time"]) {
    /* SEARCH FOR TIME */
    result = [NSArray arrayWithObject:[self _getServerTime]];
  } else {
    [self warnWithFormat:@"search for unknown entity, returning empty array"];
    return [NSArray arrayWithObjects:nil];
  }

  if ([result isKindOfClass:[NSException class]]) {
    [self warnWithFormat:@"search failed, returning exception %@", result];
    return result;
  }

  if ([flags objectForKey:@"filter"]) {
    filterString = [flags objectForKey:@"filter"];
    if ([self isDebug])
      [self logWithFormat:@"Filtering %d objects with EOQualifier",
         [result count]];
    eoFilter = [EOQualifier qualifierWithQualifierFormat:filterString];
    result = [result filteredArrayUsingQualifier:eoFilter];
  }
 
  /* log command duration */
  if ([self isProfile]) {
    end = [[NSDate date] timeIntervalSince1970];
    [self logWithFormat:@"searchForObjects returning %d objects",
            [result count]];
    [self logWithFormat:@"searchForObjects consumed %.3f seconds",
            (end - start)];
    [self logWithFormat:@"end searchForObjects"];
  } 
 
 ///[flags release];
 return result;
} /* end searchForObjectsAction */

-(id)getNotificationsAction {
  NSMutableDictionary *flags;

  if ([[self _getCompanyId] intValue] != 10000)
    return [NSException exceptionWithHTTPStatus:500
             reason:@"RPC only available to superuser."];

  if (arg3 == nil) {
    flags = [NSMutableDictionary new];
    if ([self isDebug])
      [self logWithFormat:@"No flags provided, assuming an empty set of flags."];
  } else flags = [arg3 mutableCopy];

  if ([arg1 isKindOfClass:[NSString class]])
    arg1 = [self _makeCalendarDate:arg1];
  if ([arg2 isKindOfClass:[NSString class]])
    arg2 = [self _makeCalendarDate:arg2];
  return [self _getNotifications:arg1 until:arg2 withFlags:flags];
} /* end getNotificationsAction */

-(id)_searchForTimeZones:(id)_criteria 
              withDetail:(id)_detail
               withFlags:(id)_flags {
  
  NSMutableArray   *results;
  NSDictionary     *timeZones;
  NSEnumerator     *enumerator;
  id                key, zone;
  NSCalendarDate   *current;
  
  current = [NSCalendarDate calendarDate];
  timeZones = [NSTimeZone abbreviationDictionary];
  results = [NSMutableArray arrayWithCapacity:[timeZones count]];
  enumerator = [[timeZones allKeys] objectEnumerator];
  while ((key = [enumerator nextObject]) != nil) {
    zone = [NSTimeZone timeZoneWithAbbreviation:key];
    [results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
       @"timeZone", @"entityName",
       [zone abbreviation], @"abbreviation",
       [zone description], @"description",
       [NSNumber numberWithInt:[zone secondsFromGMT]],
          @"offsetFromGMT",
       [NSNumber numberWithBool:[zone isDaylightSavingTime]],
          @"isCurrentlyDST",
       current,  @"serverDateTime",
       nil]];
  }
  return results; 
} /* end _searchForTimeZones */

-(id)_getServerTime {
   NSDictionary   *entity;
   NSCalendarDate *date;
   NSTimeZone     *zone;

   zone = [self _getTimeZone];
   if (zone == nil)
     zone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
   date = [NSCalendarDate calendarDate];
   entity = [NSDictionary dictionaryWithObjectsAndKeys:
               @"time", @"entityName",
               date, @"gmtTime",
               [zone abbreviation], @"offsetTimeZone",
               intObj([zone secondsFromGMT]), @"offsetFromGMT",
               intObj([zone isDaylightSavingTime]), @"isDST",
               [date dateByAddingYears:0
                                months:0
                                  days:0
                                 hours:0
                               minutes:0
                               seconds:[zone secondsFromGMT]],
                  @"userTime",
               nil];
   return entity;
} /* end _getServerTime */

-(id)getAuditEntriesAction {
  NSArray           *logs;
  NSEnumerator      *enumerator;
  NSDictionary      *logEntry;
  NSMutableArray    *results;

  logs = [[self getCTX] runCommand:@"log::since",
                                   @"logId", arg1,
                                   nil];
  results = [NSMutableArray arrayWithCapacity:150];
  enumerator = [logs objectEnumerator];
  while ((logEntry = [enumerator nextObject]) != nil) {
    [results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
       [logEntry valueForKey:@"logId"], @"objectId",
       @"logEntry", @"entityName",
       [logEntry valueForKey:@"creationDate"], @"actionDate",
       [self NIL:[logEntry valueForKey:@"logText"]], @"message",
       [logEntry valueForKey:@"action"], @"action",
       [logEntry valueForKey:@"accountId"], @"actorObjectId",
       [logEntry valueForKey:@"objectId"], @"entityObjectId",
       nil]];
  }
  return results;
}

@end
