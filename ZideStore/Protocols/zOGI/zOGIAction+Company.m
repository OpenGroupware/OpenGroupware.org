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

@implementation zOGIAction(Company)

/* Makes flags for an Enterprise or a Contact 
   READONLY if user does not have "w" permissions, otherwise WRITE
   SELF if the user is the creator/owner
   PRIVATE if the privacy flag is set to one
   TODO: Flag if there are ACLS on the object */
-(NSMutableArray *)_renderCompanyFlags:(EOGenericRecord *)_company 
                            entityName:(NSString *)_entityName
{
  NSMutableArray      *flags;
  SkyAccessManager    *accessManager;
  NSArray             *favIds;
 
  flags = [NSMutableArray arrayWithCapacity:16];
  accessManager = [[self getCTX] accessManager];

  /* Add access flags */
  if([accessManager operation:@"w"
        allowedOnObjectIDs:[self _getEOsForPKeys:[_company objectForKey:@"companyId"]]
        forAccessGlobalID:[self _getGlobalId]])
    [flags addObject:@"WRITE"];
  else [flags addObject:@"READONLY"];
  /* Add favorites flag */
  if ([_entityName isEqualToString:@"Enterprise"])
    favIds = [[self _getDefaults] arrayForKey:@"enterprise_favorites"];
  else 
    favIds = [[self _getDefaults] arrayForKey:@"person_favorites"];
  if ([favIds indexOfObject:[[_company objectForKey:@"companyId"] stringValue]] != NSNotFound)
    [flags addObject:@"FAVORITE"];
  /* Add ownership flag */
  if ([[_company valueForKey:@"ownerId"] intValue] ==
      [[self _getCompanyId] intValue])
    [flags addObject:@"SELF"];
  if ([[_company valueForKey:@"isPrivate"] intValue])
    [flags addObject:@"PRIVATE"];
  return flags;
} /* End _renderCompanyFlags */

-(NSException *)_addAddressesToCompany:(NSMutableDictionary *)_company {
  NSMutableArray      *addressList;
  NSEnumerator        *enumerator;
  id                   addresses;
  id                   address;
  id                   companyId;

  companyId = [[_company objectForKey:@"*eoObject"] objectForKey:@"companyId"];
  addresses = [[self getCTX] runCommand:@"address::get",
                 @"companyId",  companyId,
                 @"returnType", intObj(LSDBReturnType_ManyObjects),
                 nil];
  if (addresses == nil) 
  {
    [_company setObject:[NSArray array] forKey:@"_ADDRESSES"];  
    return nil;
  } else if ([addresses isKindOfClass:[NSException class]])
      return addresses;
  if ([addresses count] == 0)
  {
    [_company setObject:[NSArray array] forKey:@"_ADDRESSES"];  
    return nil;
  }
  addressList = [NSMutableArray arrayWithCapacity:[addresses count]];
  enumerator = [addresses objectEnumerator];
  while ((address = [enumerator nextObject]) != nil) {
    [addressList addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: 
       [address valueForKey:@"addressId"], @"objectId",
       @"address", @"entityName",
       [address valueForKey:@"companyId"], @"companyObjectId",
       [self NIL:[address valueForKey:@"name1"]], @"name1",
       [self NIL:[address valueForKey:@"name2"]], @"name2",
       [self NIL:[address valueForKey:@"name3"]], @"name3",
       [self NIL:[address valueForKey:@"city"]], @"city",
       [self NIL:[address valueForKey:@"state"]], @"state",
       [self NIL:[address valueForKey:@"street"]], @"street",
       [self NIL:[address valueForKey:@"zip"]], @"zip",
       [self NIL:[address valueForKey:@"country"]], @"country",
       [address valueForKey:@"type"], @"type",
       nil]];
   }
  [_company setObject:addressList forKey:@"_ADDRESSES"];
  return nil;
} /* End _addAddressesToCompany */

-(NSException *)_addPhonesToCompany:(NSMutableDictionary *)_company {
  NSArray             *phones;
  NSMutableArray      *phoneList;
  NSEnumerator        *enumerator;
  NSNumber            *companyId;
  id                   phone;

  companyId = [NSNumber numberWithInt:[[_company objectForKey:@"objectId"] intValue]];
  phones = [[self getCTX] runCommand:@"telephone::get",
              @"companyId",  companyId,
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              nil];
  if (phones == nil) phones = [NSArray array];
  phoneList = [NSMutableArray arrayWithCapacity:[phones count]];
  enumerator = [phones objectEnumerator];
  while ((phone = [enumerator nextObject]) != nil) {
    [phoneList addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: 
       [phone valueForKey:@"telephoneId"], @"objectId",
       @"telephone", @"entityName",
       [phone valueForKey:@"companyId"], @"companyObjectId",
       [self NIL:[phone valueForKey:@"info"]], @"info",
       [self NIL:[phone valueForKey:@"number"]], @"number",
       [self NIL:[phone valueForKey:@"realNumber"]], @"realNumber",
       [self NIL:[phone valueForKey:@"type"]], @"type",
       [self NIL:[phone valueForKey:@"url"]], @"url",
       nil]];
   }
  [_company setObject:phoneList forKey:@"_PHONES"];
  return nil;
}

-(NSException *)_addCompanyValuesToCompany:(NSMutableDictionary *)_company {
  NSMutableArray      *valueList;
  NSEnumerator        *enumerator;
  id                   value;

  valueList = [NSMutableArray new];
  enumerator = [[[_company objectForKey:@"*eoObject"] valueForKey:@"attributeMap"] objectEnumerator];
  while ((value = [enumerator nextObject]) != nil) {
    if ([value isKindOfClass:[EOGenericRecord class]]) {
      [valueList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
           @"companyValue", @"entityName",
           [value valueForKey:@"companyValueId"], @"objectId",
           [value valueForKey:@"companyId"], @"companyObjectId",
           [self NIL:[value valueForKey:@"label"]], @"label",
           [self NIL:[value valueForKey:@"type"]], @"type",
           [self NIL:[value valueForKey:@"uid"]], @"uid",
           [self NIL:[value valueForKey:@"value"]], @"value",
           [value valueForKey:@"attribute"], @"attribute",
           nil]];
     }
   }
  [_company setObject:valueList forKey:@"_COMPANYVALUES"];
  return nil;
}

-(NSMutableDictionary *)_translateAddress:(NSDictionary *)_address 
                               forCompany:(id)_objectId
{
  NSMutableDictionary   *address;

  address = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                [self NIL:[_address objectForKey:@"name1"]], @"name1",
                [self NIL:[_address objectForKey:@"name2"]], @"name2",
                [self NIL:[_address objectForKey:@"name3"]], @"name3",
                [self NIL:[_address objectForKey:@"street"]], @"street",
                [self NIL:[_address objectForKey:@"city"]], @"city",
                [self NIL:[_address objectForKey:@"zip"]], @"zip",
                [self NIL:[_address objectForKey:@"state"]], @"state",
                [self NIL:[_address objectForKey:@"country"]], @"country",
                _objectId, @"companyId",
                [_address objectForKey:@"type"], @"type",
                nil];
  if ([self isDebug])
    [self logWithFormat:@"Translated address to %@", address];
  return address;
} /* End _translateAddress */

-(NSException *)_saveAddresses:(NSArray *)_addresses forCompany:(id)_objectId
{
  NSMutableDictionary  *address;
  id                    eo;
  int                   count;

  for (count = 0; count < [_addresses count]; count++)
  {
    address = [self _translateAddress:[_addresses objectAtIndex:count]
                           forCompany:_objectId];
    eo = [[self getCTX] runCommand:@"address::get",
             @"companyId", [address objectForKey:@"companyId"],
             @"type", [address objectForKey:@"type"],
             @"operator", @"AND",
             @"comparator", @"EQUALS",
             nil];
    if ([eo isKindOfClass:[NSArray class]])
    {
      if ([eo isNotEmpty])
      {
        [address setObject:[eo lastObject] forKey:@"object"];
        eo = [[self getCTX] runCommand:@"address::set" arguments:address];
      } else
        {
          eo = [[self getCTX] runCommand:@"address::new" arguments:address];
        }
    }
    if ([eo isKindOfClass:[NSException class]])
      return eo;
  }
  return nil;
} /* End _saveAddresses */

-(NSMutableDictionary *)_translatePhone:(NSDictionary *)_phone 
                             forCompany:(id)_objectId
{
  NSMutableDictionary   *phone;

  phone = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
              [self NIL:[_phone objectForKey:@"number"]], @"number",
              [_phone objectForKey:@"type"], @"type",
              _objectId, @"companyId",
              nil];

  if ([_phone objectForKey:@"info"] != nil)
    [phone setObject:[_phone objectForKey:@"info"] forKey:@"info"];

  return phone;
} /* End of _translatePhone */

/* Save the phone records for a contact/enterprise */
-(NSException *)_savePhones:(NSArray *)_phones 
                 forCompany:(id)_objectId
{
  NSMutableDictionary  *phone;
  id                    eo;
  int                   count;

  for (count = 0; count < [_phones count]; count++)
  {
    phone = [self _translatePhone:[_phones objectAtIndex:count]
                       forCompany:_objectId];
    if ([self isDebug])
      [self logWithFormat:@"_savePhones saving %@ phone", 
         [phone objectForKey:@"type"]];
    eo = [[self getCTX] runCommand:@"telephone::get",
             @"companyId", [phone objectForKey:@"companyId"],
             @"type", [phone objectForKey:@"type"],
             @"operator", @"AND",
             @"comparator", @"EQUALS",
             nil];
    /* If the results are empty then we must be creating phone for 
       a new contact so choose the "new" command,  otherwise select the
       "set" command.
       BUG: What happens if the result is not an array?  Looks like a logic
            command will be attempted with no command selected.*/
    if ([eo isKindOfClass:[NSArray class]])
    {
      if ([eo isNotEmpty])
      {
        /* What does this line do, why? */
        [phone setObject:[eo lastObject] forKey:@"object"];
        eo = [[self getCTX] runCommand:@"telephone::set" arguments:phone];
      } else
        {
          eo = [[self getCTX] runCommand:@"telephone::new" arguments:phone];
        }
    } /* End of if-the-result-an-array */
    if ([eo isKindOfClass:[NSException class]])
      return eo;
  }
  return nil;
} /* End of _savePhones */

/* Store a comapny 
   Used by _updateContact, _createContact, _updateEnterprise, _createEnterprise
   _command should be "new" or "set"
   Flags supports: favorite, unfavorite, noCommit
   Flags supported only for enterprises: businessCard*/
-(id)_writeCompany:(NSDictionary *)_company
       withCommand:(NSString *)_command
         withFlags:(NSArray *)_flags 
        forEntity:(NSString *)_entity
{
  NSArray              *keys;
  NSString             *key;
  NSString             *command;
  id                    value, company, eo;
  int                   count;
  NSException          *exception;

  command = [[NSString alloc] initWithString:_entity];
  command = [command stringByAppendingString:@"::"];
  command = [command stringByAppendingString:_command];
  if ([self isDebug])
    [self logWithFormat:@"_writeCompany using %@ command", command];
  company = [[NSMutableDictionary alloc] initWithCapacity:[_company count]];
  keys = [_company allKeys];
  for (count = 0; count < [keys count]; count++) 
  {
    value = [_company objectForKey:[keys objectAtIndex:count]];
    if ([_entity isEqualToString:@"person"])
    {
      key = [self _translateContactKey:[keys objectAtIndex:count]];
      if (key != nil)
      {
        if ([key isEqualToString:@"birthday"])
        {
          if ([value isKindOfClass:[NSCalendarDate class]])
          {
            /* TODO: Set timezone on birthdate to GMT? */
          } else
            {
              /* value is not a date; convert from string */
              if ([value isEqualToString:@""])
                value = [EONull null];
              else
                value = [self _makeCalendarDate:value];
            }
        } else if ([key isEqualToString:@"gender"])
          {
            if (([value isEqualToString:@"undefined"]) ||
                ([value isEqualToString:@""]))
              value = [EONull null];
          }
      }
    } else
        key = [self _translateEnterpriseKey:[keys objectAtIndex:count]];
    if (key != nil)
    {
      if ([value isKindOfClass:[NSException class]])
        return value;
      [company setObject:value forKey:key];
    }
  } /* End for loop-through-key-translation */
  if ([_command isEqualToString:@"new"])
    [company removeObjectForKey:@"companyId"];
  keys = nil;

  /* Process company values */
  if ([_company objectForKey:@"_COMPANYVALUES"] != nil)
  {
    for (count = 0;
         count < [[_company objectForKey:@"_COMPANYVALUES"] count];
         count++) {
      value = [[_company objectForKey:@"_COMPANYVALUES"] objectAtIndex:count];
      if ([self isDebug])
        [self logWithFormat:@"Company Value: Storing value %@ as %@", 
          [value objectForKey:@"value"],
          [value objectForKey:@"attribute"]];
      [company setObject:[value objectForKey:@"value"]
                  forKey:[value objectForKey:@"attribute"]];
     }
  } /* End if-COMPANYVALUES-supplied-by-client */

  /* Add & test snapshot if event is an update */
  if ([_command isEqualToString:@"set"])
  {
    if ([self isDebug])
      [self logWithFormat:@"Performing update of %@", 
         [company objectForKey:@"companyId"]];
    if ([_entity isEqualToString:@"enterprise"])
      eo = [self _getUnrenderedEnterpriseForKey:[company objectForKey:@"companyId"]];
    else
      eo = [self _getUnrenderedContactForKey:[company objectForKey:@"companyId"]];
    if (eo == nil)
    {
      if ([self isDebug])
        [self logWithFormat:@"Null snapshot when attempting company update"];
      return [NSException exceptionWithHTTPStatus:500
                reason:@"Snapshot object for update could not be retrieved"];
    }
    /* Object version check is not performed if ignoreVersion flag was provided
       by the client.  But this is generally a bad idea and clients should ONLY
       use this to offer an explicit force-overwrite option. */
    if (!([_flags containsObject:[NSString stringWithString:@"ignoreVersion"]]))
    {
      if ([_company objectForKey:@"version"] == nil)
        return [NSException exceptionWithHTTPStatus:500
                  reason:@"No version supplied on company update"];
      if ([[_company objectForKey:@"version"] intValue] !=
          [[eo objectForKey:@"objectVersion"] intValue])
      {
        if ([self isDebug])
        {
          [self warnWithFormat:@"Client object version: %@", [_company objectForKey:@"version"]];
          [self warnWithFormat:@"Server object version: %@", [eo objectForKey:@"objectVersion"]];
        }
        return [NSException exceptionWithHTTPStatus:500
                  reason:@"Client object is out of date"];
      }
    } /* If ignoreVersion-not-specified */
    [company setObject:eo forKey:@"object"];
  } else
    {
      /* Creating a new company, remove companyId */
      [company removeObjectForKey:@"companyId"];
    }

  /* Execute Logic Command */
  company = [[self getCTX] runCommand:command arguments:company];
  /* Create exception on failure */
  if ([company objectForKey:@"companyId"] == nil) {
    if ([self isDebug])
      [self logWithFormat:@"exception occured writing company data"];
    exception = [NSException exceptionWithHTTPStatus:500
                             reason:@"Failure to write company data"];
    return exception;
   }
  
  /* Save addresses */
  exception = nil;
  value = [_company objectForKey:@"_ADDRESSES"];
  if (value != nil)
    exception = [self _saveAddresses:value 
                          forCompany:[company objectForKey:@"companyId"]];
  if (exception != nil) 
  {
    if ([self isDebug])
      [self logWithFormat:@"exception occured saving company addresses"];
    [[self getCTX] rollback];
    return exception;
  } /* End if-exception-is-realized */

  /* Save phone numbers */
  exception = nil;
  value = [_company objectForKey:@"_PHONES"];
  if (value != nil)
    exception = [self _savePhones:value
                          forCompany:[company objectForKey:@"companyId"]];
  if (exception != nil) 
  {
    if ([self isDebug])
      [self logWithFormat:@"exception occured saving company phones"];
    [[self getCTX] rollback];
    return exception;
  } /* End if-exception-is-realized */

  /* Save ACLs */
  exception = [self _saveACLs:[_company objectForKey:@"_ACCESS"]
                    forObject:[company objectForKey:@"companyId"]];
  if (exception != nil) 
  {
    if ([self isDebug])
      [self logWithFormat:@"exception occured saving company ACLs"];
    [[self getCTX] rollback];
    return exception;
  } /* End if-exception-is-realized */

  /* Save object links */
  exception = [self _saveObjectLinks:[_company objectForKey:@"_OBJECTLINKS"]
                           forObject:[company objectForKey:@"companyId"]];
  if (exception != nil) 
  {
    if ([self isDebug])
      [self logWithFormat:@"exception occured saving company object links"];
    [[self getCTX] rollback];
    return exception;
  } /* End if-exception-is-realized */

  /* Save properties */
  if (exception == nil)
    exception = [self _saveProperties:[_company objectForKey:@"_PROPERTIES"]
                            forObject:[company objectForKey:@"companyId"]];
  if (exception != nil) 
  {
    if ([self isDebug])
      [self logWithFormat:@"exception occured saving company properties"];
    [[self getCTX] rollback];
    return exception;
  } /* End if-exception-is-realized */

  /* Save assignments */
  if ([_entity isEqualToString:@"person"])
  {
    /* save enterprise assignments from contact */
    if (exception == nil)
      exception = [self _saveEnterprisesToPerson:[_company objectForKey:@"_ENTERPRISES"]
                                        objectId:[company objectForKey:@"companyId"]];
    /* End save-enteprise-assignments-from-contact */
  } else 
    {
      /* save contact assignments from enterprise */
      if ([_flags containsObject:[NSString stringWithString:@"businessCard"]])
      {
        /* save contacts in business card mode */
        exception = [self _saveBusinessCards:[_company objectForKey:@"_CONTACTS"]
                                enterpriseId:[company objectForKey:@"companyId"]
                                 defaultACLs:[_company objectForKey:@"_ACCESS"]];
        /* End save-contacts-in-business-card-mode */
      } else
        {
          /* else contact assignments in traditional way */
          exception = [self _savePersonsToEnterprise:[_company objectForKey:@"_CONTACTS"]
                                            objectId:[company objectForKey:@"companyId"]];
        } /* End not-in-businessCard-mode */
    } /* End saving-contact-assignments-from-contact */
  if (exception != nil) 
  {
    if ([self isDebug])
      [self logWithFormat:@"exception occured saving contact<->enterprise assignments"];
    [[self getCTX] rollback];
    return exception;
  } /* End exception-is-realized */

  /* Save complete */
  if ([self isDebug])
    [self logWithFormat:@"saving company %@ complete", [company objectForKey:@"companyId"]];
  if ([_flags containsObject:[NSString stringWithString:@"noCommit"]])
  {
    /* database commit has been disabled by the noCommit flag 
       return an Unknown object to the client */
    if ([self isDebug])
      [self logWithFormat:@"commit disabled via flag!"];
  } else 
    { 
      /* committing database transaction */
      [[self getCTX] commit];
    }

  /* do favorite flags  */
  if ([_flags containsObject:[NSString stringWithString:@"favorite"]]) 
  {
    [self _favoriteObject:[company objectForKey:@"companyId"] 
               defaultKey:[_entity stringByAppendingString:@"_favorites"]];
  }
  if ([_flags containsObject:[NSString stringWithString:@"unfavorite"]])
  {
    [self _unfavoriteObject:[company objectForKey:@"companyId"]
                 defaultKey:[_entity stringByAppendingString:@"_favorites"]];
  }

  /* render object and return */
  if ([_entity isEqualToString:@"person"])
    company = [self _getContactForKey:[company objectForKey:@"companyId"]
                           withDetail:[NSNumber numberWithInt:65535]];
  else
    company = [self _getEnterpriseForKey:[company objectForKey:@"companyId"]
                              withDetail:[NSNumber numberWithInt:65535]];
  return company;
} /* End _writeCompany */

@end /* End zOGIAction(Company) */
