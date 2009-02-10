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

#include <LSFoundation/OGoObjectLinkManager.h>
#include <LSFoundation/OGoObjectLink.h>
#include "zOGIAction.h"
#include "zOGIAction+Object.h"
#include "zOGIAction+Property.h"
#include "zOGIAction+Appointment.h"
#include "zOGIAction+Team.h"
#include "zOGIAction+Enterprise.h"
#include "zOGIAction+Contact.h"
#include "zOGIAction+Task.h"
#include "zOGIAction+Project.h"
#include "zOGIAction+Defaults.h"
#include "zOGIAction+Resource.h"
#include "zOGIAction+Document.h"
#include "zOGIAction+Note.h"
#include "zOGIAction+News.h"

@implementation zOGIAction(Object)

-(NSDictionary *)_getObjectByObjectId:(id)_objectId 
                           withDetail:(NSNumber *)_detail {
  NSDictionary  *result;
  NSString      *entityName;

  result = nil;
  if ([_objectId isKindOfClass:[EOKeyGlobalID class]])
    entityName = [[_objectId entityName] valueForKey:@"stringValue"];
  else 
    entityName = [self _getEntityNameForPKey:_objectId];

  if ([entityName isEqualToString:@"Date"])
    result = [self _getDateForKey:_objectId withDetail:_detail];
  else if ([entityName isEqualToString:@"Enterprise"])
    result = [self _getEnterpriseForKey:_objectId withDetail:_detail];
  else if ([entityName isEqualToString:@"Person"])
    result = [self _getContactForKey:_objectId withDetail:_detail];
  else if ([entityName isEqualToString:@"Job"])
    result = [self _getTaskForKey:_objectId withDetail:_detail];
  else if ([entityName isEqualToString:@"Team"])
    result = [self _getTeamForKey:_objectId withDetail:_detail];
  else if ([entityName isEqualToString:@"Project"])
    result = [self _getProjectForKey:_objectId withDetail:_detail];
  else if ([entityName isEqualToString:@"AppointmentResource"])
    result = [self _getResourceForKey:_objectId withDetail:_detail];
  else if ([entityName isEqualToString:@"Doc"])
    result = [self _getDocumentForKey:_objectId withDetail:_detail];
  else if ([entityName isEqualToString:@"Note"])
    result = [self _getNoteById:_objectId];
  else if ([entityName isEqualToString:@"NewsArticle"])
    result = [self _getArticleForKey:_objectId withDetail:_detail];
  if (result == nil)
    return [self _makeUnknownObject:(id)_objectId];
  return result;
} /* end _getObjectByObjectId */

/* Add detail information that is common to all object types */
-(void)_addObjectDetails:(NSMutableDictionary *)_object 
               withDetail:(NSNumber *)_detail {
  if([_detail intValue] > 0) {
    if([_detail intValue] & zOGI_INCLUDE_OBJLINKS)
      [self _addLinksToObject:_object];
    if([_detail intValue] & zOGI_INCLUDE_PROPERTIES)
      [self _addPropertiesToObject:_object];
    if([_detail intValue] & zOGI_INCLUDE_LOGS)
      [self _addLogsToObject:_object];
    if([_detail intValue] & zOGI_INCLUDE_ACLS)
      [self _addACLsToObject:_object];
   }
  [self _stripInternalKeys:_object];
} /* end _addObjectDetails */

/* Add ACLs from Access Manager to object
   FYI: Contacts & enterprises get ACLs from object_acl,  projects get
        ACLs from project<->company assignments.  Wierd.
   TODO: This doesn't actually catch any errors or produce any exceptions */
-(NSException *)_addACLsToObject:(NSMutableDictionary *)_object {
  SkyAccessManager    *accessManager;
  NSMutableArray      *results;
  NSEnumerator        *enumerator;
  id                   tmp;
  id                   acls;
  id                   key; /* Is an EOGLobalId */

  results = [NSMutableArray arrayWithCapacity:16];
  if ([[_object objectForKey:@"entityName"] isEqualToString:@"Project"]) {
    if ([self isDebug])
      [self logWithFormat:@"Rendering project ACLs for %@",
        [_object valueForKey:@"objectId"]]; 
    tmp = [_object objectForKey:@"*eoObject"];
    enumerator = [[tmp objectForKey:@"companyAssignments"] objectEnumerator];
    while ((tmp = [enumerator nextObject]) != nil) {
      if ([[tmp valueForKey:@"hasAccess"] intValue] == 1) {
        key = [self _getEntityNameForPKey:[tmp valueForKey:@"companyId"]];
        [results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              @"acl", @"entityName",
                              [_object objectForKey:@"objectId"],
                                 @"parentObjectId", 
                              [self _izeEntityName:key],
                                 @"targetEntityName",
                              [tmp valueForKey:@"companyId"],
                                 @"targetObjectId",
                              [tmp valueForKey:@"accessRight"],
                                 @"operations",
                              [self NIL:[tmp valueForKey:@"info"]], @"info",
                              nil]];
      } /* end project-assignment-is-an-ACL */
    } /* end while */
    if ([self isDebug])
      [self logWithFormat:@"Found %d project ACLs for %@", 
        [results count],
        [_object valueForKey:@"objectId"]]; 
    /* end entity-is-a-project */
  } else {
      accessManager = [[self getCTX] accessManager];
      tmp = [self _getEOsForPKeys:[_object objectForKey:@"objectId"]];
      acls = [accessManager allowedOperationsForObjectIds:tmp];
      if ([acls count] > 0) {
        if ([self isDebug])
          [self logWithFormat:@"Rendering company ACLs for object %@", 
             [_object objectForKey:@"objectId"]];
        tmp = [acls objectForKey:[[acls allKeys] objectAtIndex:0]];
        enumerator = [[tmp allKeys] objectEnumerator];
        while ((key = [enumerator nextObject]) != nil) {
          [results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                @"acl", @"entityName",
                                [_object objectForKey:@"objectId"],
                                   @"parentObjectId",
                                [self _izeEntityName:[key entityName]],
                                   @"targetEntityName",
                                [[key keyValuesArray] objectAtIndex: 0],
                                    @"targetObjectId",
                                [tmp objectForKey:key], @"operations",
                                @"", @"info",
                                nil]];
        } /* end while */
        if ([self isDebug])
          [self logWithFormat:@"Found %d company ACLs for object %@",
             [results count],
             [_object objectForKey:@"objectId"]];
      } else {
          if ([self isDebug])
            [self logWithFormat:@"Found no company ACLs for object %@", 
               [_object objectForKey:@"objectId"]];
        }
    } /* end not-a-project-assuming-a-company-object */
  [_object setObject:results forKey:@"_ACCESS"];
  return nil;
} /* end _addACLs */

/* Add _OBJECTLINKS information to an object */
-(void)_addLinksToObject:(NSMutableDictionary *)_object {
  NSMutableArray      *linkList;
  NSArray             *links;
  NSEnumerator        *enumerator;
  EOGlobalID          *eo;
  id                  link;

  eo = [self _getEOForPKey:[_object valueForKey:@"objectId"]];
  linkList = [NSMutableArray arrayWithCapacity:16];
  links = [[[self getCTX] linkManager] allLinksTo:(id)eo];
  if (links != nil) {
    enumerator = [links objectEnumerator];
    while ((link = [enumerator nextObject]) != nil) {
      [linkList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
         @"to", @"direction",
         intObj([[self _getPKeyForEO:(id)[link globalID]] intValue]), @"objectId",
         @"objectLink", @"entityName",
         [self _getPKeyForEO:(id)[link sourceGID]], @"sourceObjectId",
         [self _getPKeyForEO:(id)[link targetGID]], @"targetObjectId",
         [self _izeEntityName:[self _getEntityNameForPKey:[link sourceGID]]], @"sourceEntityName",
         [self _izeEntityName:[self _getEntityNameForPKey:[link targetGID]]], @"targetEntityName",
         [self NIL:[link linkType]], @"type",
         [self NIL:[link label]], @"label",
         nil]];  
     }
   }
  links = [[[self getCTX] linkManager] allLinksFrom:(id)eo];
  if (links != nil) {
    enumerator = [links objectEnumerator];
    while ((link = (id)[enumerator nextObject]) != nil) {
      [linkList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
         @"from", @"direction",
         intObj([[self _getPKeyForEO:(id)[link globalID]] intValue]), @"objectId",
         @"objectLink", @"entityName",
         [self _getPKeyForEO:(id)[link targetGID]], @"targetObjectId",
         [self _getPKeyForEO:(id)[link sourceGID]], @"sourceObjectId",
         [self _izeEntityName:[self _getEntityNameForPKey:[link targetGID]]], @"targetEntityName",
         [self _izeEntityName:[self _getEntityNameForPKey:[link sourceGID]]], @"sourceEntityName",
         [self NIL:[link linkType]], @"type",
         [self NIL:[link label]], @"label",
         nil]];  
     }
   }
  [_object setObject:linkList forKey:@"_OBJECTLINKS"];
}

-(void)_addLogsToObject:(NSMutableDictionary *)_object {
  EOGlobalID      *eo;
  id              object;
  NSArray         *logs;
  NSMutableArray  *logEntries;
  NSDictionary    *logEntry;
  NSEnumerator    *enumerator;
 
  eo = [self _getEOForPKey:[_object valueForKey:@"objectId"]];
  object = [[[self getCTX] runCommand:@"object::get-by-globalid",
                                     @"gid", eo,
                                     nil] lastObject];
  logs = [[self getCTX] runCommand:@"object::get-logs", 
                                   @"object", object,
                                   nil];
  logEntries = [NSMutableArray arrayWithCapacity:[logs count]];
  enumerator = [logs objectEnumerator];
  while((logEntry = [enumerator nextObject]) != nil) {
    [logEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:
       [logEntry valueForKey:@"logId"], @"objectId",
       @"logEntry", @"entityName",
       [logEntry valueForKey:@"creationDate"], @"actionDate",
       [self NIL:[logEntry valueForKey:@"logText"]], @"message",
       [logEntry valueForKey:@"action"], @"action",
       [logEntry valueForKey:@"accountId"], @"actorObjectId",
       [_object valueForKey:@"objectId"], @"entityObjectId",
       nil]];
   }
  [_object setObject:logEntries forKey:@"_LOGS"];
}

/*
  _saveObjectLinks syncronizes the list of object lists provided in _links
  with the Object Links present in the OpenGroupware database.  If _links 
  is NIL then no operations are performed.  Only the links *FROM* the
  _objectId specified are syncronized; object links must be modified from 
  the source.
 */
-(NSException *)_saveObjectLinks:(NSArray *)_links
                       forObject:(NSString *)_objectId {
  NSEnumerator        *clientEnumerator, *serverEnumerator;
  NSDictionary        *clientLink;
  NSArray             *serverLinks;
  id                  linkManager, objectLink, serverLink, tmp;
  NSString            *linkPK;
  int                 match;

  linkManager = [[self getCTX] linkManager];
  if (_links == nil) {
    if ([self isDebug])
      [self logWithFormat:@"No OBJECTLINKS key, bailing out of link save."];
    return nil;
  }
  if ([_links count] == 0) {
    if ([self isDebug])
      [self logWithFormat:@"OBJECTLINKS key empty, deleting all links."];
    [linkManager deleteLinksFrom:(id)[self _getEOForPKey:_objectId]
                            type:[NSString stringWithString:@""]];             
    return nil;
  }
  if ([self isDebug]) {
    [self logWithFormat:@"Have %d links in OBJECTLINKS, processing changes.",
       [_links count]];
  }
  /* We must get the server links *before* we add new links or we end up
     deleting the new links when we loop the server links */
  serverLinks = [linkManager allLinksFrom:(id)[self _getEOForPKey:_objectId]];
  // Check for links to create (objectId = 0)
  if ([self isDebug]) 
    [self logWithFormat:@"Checking OBJECTLINKS for new links."];
  clientEnumerator = [_links objectEnumerator];
  while ((clientLink = [clientEnumerator nextObject]) != nil) {
    tmp = [[clientLink objectForKey:@"objectId"] stringValue];
    if ([tmp isEqualToString:@"0"]) {
      if ([self isDebug]) {
        [self logWithFormat:@"Creating new link to %@", 
           [clientLink objectForKey:@"targetObjectId"]];
      }
      [linkManager createLink:[self _translateObjectLink:clientLink
                                              fromObject:_objectId]];
    } // End objectId == 0
  } // End while clientLink = [clientEnumerator nextObject]
  /* Loop through links on server to finds ones modified by client
     or removed by the client;  if the client provided _OBJECTLINKS on
     and object put then we assume that links no longer provided should
     be deleted. */
  serverEnumerator = [serverLinks objectEnumerator];
  if ([self isDebug])
    [self logWithFormat:@"Server has %d objectLinks for object.",
       [serverLinks count]];
  while ((serverLink = [serverEnumerator nextObject]) != nil) {
    linkPK = [self _getPKeyForEO:(id)[serverLink globalID]];
    match = 0;
    clientEnumerator = [_links objectEnumerator];
    while ((clientLink = [clientEnumerator nextObject]) != nil) {
      tmp = [[clientLink objectForKey:@"objectId"] stringValue];
      if ([linkPK isEqualToString:tmp]) {
        objectLink = (OGoObjectLink *)[self _translateObjectLink:clientLink
                                                      fromObject:_objectId];
        match = 1;
        if (!([objectLink isEqual:serverLink])) {
          /* This link exists but the client has changed something
             Replace the link on the server; links cannot be updated */
          [linkManager deleteLink:serverLink];
          [linkManager createLink:objectLink];
         } // End if !([clientLink isEqualToObjectLink:serverLink])
       } // End if serverLink is clientLink
     } // End while clientLink = [clientEnumerator nextObject]
    if (match == 0)
      [linkManager deleteLink:serverLink];
   } // End while serverLink = [serverEnumerator nextObject]
  return nil;
} // End _saveObjectLinks

/*
  _translateObjectLink turns the _link ObjectLink dictionary into
  a OGoObjectLink object.  OGoObjectLink is the object used by the
  OpenGroupware logic layer to represent an Object Link.
 */
-(id)_translateObjectLink:(NSDictionary *)_link fromObject:(id)_objectId {
  id objectLink;
  EOGlobalID   *sourceEO, *targetEO;

  sourceEO = [self _getEOForPKey:_objectId];
  targetEO = [self _getEOForPKey:[_link objectForKey:@"targetObjectId"]];
  objectLink = [[OGoObjectLink alloc] initWithSource:(id)sourceEO 
                   target:(id)targetEO
                   type:[_link objectForKey:@"type"]
                   label:[_link objectForKey:@"label"]];
  return objectLink;
}

-(NSDictionary *)_makeUnknownObject:(id)_objectId {
  if ([_objectId isKindOfClass:[EOGlobalID class]]) {
    return [NSDictionary dictionaryWithObjectsAndKeys:
              @"Unknown", @"entityName",
              [self _getPKeyForEO:_objectId], @"objectId",
              nil];
   } else {
       return [NSDictionary dictionaryWithObjectsAndKeys:
                 @"Unknown", @"entityName",
          			 _objectId, @"objectId",
                 nil];
      }
} /* end _makeUnknownObject */

-(NSException *)_saveACLs:(NSArray *)_acls 
                forObject:(id)_objectId
               entityName:(id)_entityName {
  SkyAccessManager    *accessManager;
  NSMutableDictionary *acls;
  NSDictionary        *acl;
  NSEnumerator        *enumerator;
  EOGlobalID          *objectKey;

  if (_acls == nil)
    return nil;
  if ([_entityName isEqualToString:@"Project"]) {
    /* saving project ACLs */
    if ([self isDebug])
      [self logWithFormat:@"saving project ACLs for %@", _objectId];
    /* TODO: Implement */
    enumerator = [_acls objectEnumerator]; 
  } else {
      /* assuming this is a company object */
      if ([self isDebug])
        [self logWithFormat:@"saving company ACLs for %@", _objectId];
      accessManager = [[self getCTX] accessManager];
      objectKey = [self _getEOForPKey:_objectId];
      acls = [NSMutableDictionary dictionaryWithCapacity:[_acls count]];
      enumerator = [_acls objectEnumerator];
      while ((acl = [enumerator nextObject]) != nil)
        [acls setObject:[acl objectForKey:@"operations"]
                 forKey:[self _getEOForPKey:[acl objectForKey:@"targetObjectId"]]];
      [accessManager setOperations:acls onObjectID:objectKey];
    }
  acls = nil;
  enumerator = nil;
  return nil;
} /* end _saveACLs */

/* Remove objectId from favorite contacts list */
-(void)_unfavoriteObject:(id)_objectId defaultKey:(NSString *)_key {
  NSMutableArray    *favIds;

  if (![_objectId isKindOfClass:[NSString class]])
    _objectId = [_objectId stringValue];
  favIds = [[[self _getDefaults] arrayForKey:_key] mutableCopy];
  [favIds removeObject:_objectId];
  [[self _getDefaults] setObject:favIds forKey:_key];
  [[self _getDefaults] synchronize];
} /* end _unfavoriteObject */

/* Add objectId to list of favorite contacts */
-(void)_favoriteObject:(id)_objectId defaultKey:(NSString *)_key {
  NSMutableArray    *favIds;

  if (![_objectId isKindOfClass:[NSString class]])
    _objectId = [_objectId stringValue];
  favIds = [[[self _getDefaults] arrayForKey:_key] mutableCopy];
  if ([favIds indexOfObject:_objectId] == NSNotFound) {
    [favIds addObject:_objectId];
    [[self _getDefaults] setObject:favIds forKey:_key];
    [[self _getDefaults] synchronize];
  }
} /* end _favoriteObject */

@end
