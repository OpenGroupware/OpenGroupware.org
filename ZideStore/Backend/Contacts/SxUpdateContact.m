/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "SxUpdateContact.h"
#include "SxFetchContact.h"
#include "common.h"
#include "NSMutableDictionary+SetSafeObject.h"
#include "NSString+rtf.h"
#include "NSObject+DBColumns.h"
#include <GDLAccess/GDLAccess.h>

@implementation SxUpdateContact

- (id)initWithContext:(id)_ctx primaryKey:(id)_pkey
  attributes:(NSDictionary *)_attrs
{
  if ((self = [super init])) {
    self->cmdCtx = [_ctx   retain];
    self->pKey   = [_pkey  retain];
    self->attrs  = [_attrs retain];
  }
  return self;
}

- (void)dealloc {
  [self->cmdCtx      release];
  [self->object      release];
  [self->pKey        release];
  [self->attrs       release];
  [self->fetchObject release];
  [self->type        release];
  [super dealloc];
}

/* accessors */

- (NSString *)entityName {
  [self logWithFormat:@"ERROR: subclass must implement %@", 
	  NSStringFromSelector(_cmd)];
  return nil;
}

- (NSString *)setCommand {
  [self logWithFormat:@"ERROR: subclass must implement %@", 
	  NSStringFromSelector(_cmd)];
  return nil;
}

- (NSString *)newCommand {
  [self logWithFormat:@"ERROR: subclass must implement %@", 
	  NSStringFromSelector(_cmd)];
  return nil;
}

- (void)updatePhone:(NSString *)_key value:(id)_value {
  NSMutableString *tms;
  NSString        *org;

  org = [[self fetchObject] phoneForType:_key];

  if ([org isEqual:_value])
    return;

  
  self->incVersion = YES;
  tms = [NSMutableString stringWithCapacity:128];
  {
    EOAdaptorChannel *channel;

    channel = [[self->cmdCtx valueForKey:LSDatabaseChannelKey]
                             adaptorChannel];
    
    if (org == nil) {
      NSDictionary *keyDict;
      EOModel      *model;
      
      if (![_value length])
        return;
      
      model   = [[[channel adaptorContext] adaptor] model];

      keyDict = [channel primaryKeyForNewRowWithEntity:
                         [model entityNamed:@"Telephone"]];

                         
      [tms appendString:@"INSERT into telephone (telephone_id, "];
      [tms appendString:[self numberColumn]];
      [tms appendString:@", db_status, company_id, "];
      [tms appendString:[self typeColumn]];
      [tms appendString:@") VALUES ("];
           
      [tms appendString:[[keyDict valueForKey:@"telephoneId"] stringValue]];
      [tms appendString:@", '"];
      [tms appendString:[_value stringValue]];
      [tms appendString:@"', 'inserted', '"];
      [tms appendString:[[[self object] valueForKey:@"companyId"]
                                stringValue]];
      [tms appendString:@"', '"];
      [tms appendString:[_key stringValue]];
      [tms appendString:@"');"];
      [[self fetchObject] clearCache];
    }
    else {
      [tms appendString:@"UPDATE telephone"];

      [tms appendString:@" SET "];
      [tms appendString:[self numberColumn]];
      [tms appendString:@"='"];
      [tms appendString:[_value stringValue]];
      [tms appendString:@"', db_status='updated'"];
  
      [tms appendString:@" WHERE company_id="];
      [tms appendFormat:@"%i", [[[self object] valueForKey:@"companyId"]
                                       intValue]];
      [tms appendString:@" AND "];
      [tms appendString:[self typeColumn]];
      [tms appendString:@"='"];
      [tms appendString:[_key stringValue]];
      [tms appendString:@"'"];
    }

    if (![channel evaluateExpression:tms]) {
      // TODO: rollback & give back exception
      [self logWithFormat:@"failed to update phone key %@: %@", _key, tms];
    }
  }
}

- (NSMutableDictionary *)checkForModifications:(id)_genRec
  in:(NSDictionary *)_dict
{
  NSMutableDictionary *result;
  NSEnumerator        *enumerator;
  NSString            *key;

  result = [NSMutableDictionary dictionaryWithCapacity:[_dict count]];

  enumerator = [_genRec keyEnumerator];

  while ((key = [enumerator nextObject])) {
    id eov, dv;

    eov = [_genRec valueForKey:key];
    dv  = [_dict objectForKey:key];

    if (!dv)
      continue;

    if ([eov isEqual:dv])
      continue;

    [result setObject:dv forKey:key];
  }

  return result;
}

- (void)updateAddress:(NSString *)_type values:(NSDictionary *)_vars {
  id genRec;

  genRec = [[self fetchObject] addressObjForType:_type];

  if ([genRec isNotNull]) {
    _vars  = [self checkForModifications:genRec in:_vars];
    if (![_vars count])
      return;
  
    [genRec updateFromSnapshot:_vars];
  
    [self->cmdCtx runCommand:@"address::set" arguments:genRec];
  }
  else {
    NSMutableDictionary *dict;
    
    if ([_vars isNotNull])
      dict = [[_vars mutableCopy] autorelease];
    else
      dict = [NSMutableDictionary dictionaryWithCapacity:16];
    
    [dict setObject:[[[self fetchObject] eo] valueForKey:@"companyId"]
          forKey:@"companyId"];
    [dict setObject:_type forKey:[self typeColumn]];
    [self->cmdCtx runCommand:@"address::new" arguments:dict];
  }
}

- (Class)fetchObjectClass {
  [self logWithFormat:@"ERROR: subclass must implement %@", 
	  NSStringFromSelector(_cmd)];
  return Nil;
}

- (SxFetchContact *)fetchObject {
  if (self->fetchObject == nil) {
    BOOL insert = NO;
    
    self->fetchObject = [[[self fetchObjectClass] alloc] initWithContext:
                                                         self->cmdCtx];
    if ([self->pKey intValue] == 0) {
      insert = YES;
    }
    else {
      [self->fetchObject loadEOForID:self->pKey];
      if (![self->fetchObject eo]) {
        NSLog(@"missing eo object for %@", self->pKey);
        insert = YES;
      }
    }
    if (insert) {
      id                  eo;
      NSMutableDictionary *dict;

      dict = [NSMutableDictionary dictionaryWithCapacity:4];

      if ([self->type isEqualToString:@"private"])

        [dict setObject:[NSNumber numberWithBool:YES]
              forKey:@"isPrivate"];

      [dict setObject:@"description" forKey:@"description"];
      
      eo = [self->cmdCtx runCommand:[self newCommand] arguments:dict];

      self->wasNew = YES;
      
      ASSIGN(self->pKey, [eo valueForKey:@"companyId"]);

      [self->fetchObject loadEOForID:self->pKey];
      if (![self->fetchObject eo]) {
        NSLog(@"couln`t insert new object");
        return nil;
      }
    }
  }
  return self->fetchObject;
}

- (id)object {
  if (self->object == nil) {
    self->object = [[[self fetchObject] eo] retain];
  }
  return self->object;
}

- (NSMutableDictionary *)setObjectValues:(NSDictionary *)_vars {
  NSMutableDictionary *result;
  NSString            *str;

  result = [NSMutableDictionary dictionaryWithCapacity:16];

  [result setSafeObject:[_vars objectForKey:@"url"] forKey:@"url"];
  
  str  = [_vars objectForKey:@"comment-compressed"];

  if (![str isNotNull])
    str = @"";
  
  if ([str length]) {
    NSString *s;

    s = [[str stringByDecodingBase64] plainTextStringByDecodingRTF];

    if (![s length]) {
      s = [@"ZideLook rich-text compressed comment: "
            stringByAppendingString:str];
    }
    [result setSafeObject:s forKey:@"comment"];
  }

  [result setSafeObject:[_vars objectForKey:@"associatedCategories"]
          forKey:@"associatedCategories"];
  
  [result setSafeObject:[_vars objectForKey:@"associatedContacts"]
          forKey:@"associatedContacts"];

  [result setSafeObject:[_vars objectForKey:@"email2"]
          forKey:@"email2"];
  [result setSafeObject:[_vars objectForKey:@"email3"]
          forKey:@"email3"];
  [result setSafeObject:[_vars objectForKey:@"showEmailAs"]
          forKey:@"showEmailAs"];
  [result setSafeObject:[_vars objectForKey:@"showEmail2As"]
          forKey:@"showEmail2As"];
  [result setSafeObject:[_vars objectForKey:@"showEmail3As"]
          forKey:@"showEmail3As"];

  [result setSafeObject:[_vars objectForKey:@"department"]
          forKey:@"department"];
  [result setSafeObject:[_vars objectForKey:@"office"]
          forKey:@"office"];
  [result setSafeObject:[_vars objectForKey:@"partnerName"]
          forKey:@"partnerName"];
  [result setSafeObject:[_vars objectForKey:@"title"]
          forKey:@"job_title"];
  [result setSafeObject:[_vars objectForKey:@"bossName"]
          forKey:@"bossName"];
  [result setSafeObject:[_vars objectForKey:@"profession"]
          forKey:@"occupation"];
  [result setSafeObject:[_vars objectForKey:@"fburl"]
          forKey:@"freebusyUrl"];
  [result setSafeObject:[_vars objectForKey:@"department"]
          forKey:@"department"];
  [result setSafeObject:[_vars objectForKey:@"bday"]
          forKey:@"birthday"];
  [result setSafeObject:[_vars objectForKey:@"anniversary"]
          forKey:@"anniversary"];
  [result setSafeObject:[_vars objectForKey:@"associatedCompany"]
          forKey:@"associatedCompany"];
  [result setSafeObject:[_vars objectForKey:@"imAddress"]
          forKey:@"imAddress"];
  [result setSafeObject:[_vars objectForKey:@"netMeetingSettings"]
          forKey:@"dirServer"];
  [result setSafeObject:[_vars objectForKey:@"assistantName"]
          forKey:@"assistantName"];
  [result setSafeObject:[_vars objectForKey:@"fileas"]
          forKey:@"fileas"];
  
  return result;
}

- (NSMutableDictionary *)checkForObjectModifications:(id)_eo
  in:(NSMutableDictionary *)_dict
{
  NSMutableDictionary *upd;
  id                  tmp;
  
  upd = [self checkForModifications:_eo in:_dict];

  if ((tmp = [_dict valueForKey:@"job_title"])) {
    if (![[_eo valueForKey:@"job_title"] isEqual:tmp]) {
      [upd setSafeObject:tmp forKey:@"job_title"];
    }
  }

  if ((tmp = [_dict valueForKey:@"comment"])) {
    if (![[_eo valueForKey:@"comment"] isEqual:tmp]) {
      [upd setSafeObject:tmp forKey:@"comment"];
    }
  } 

  if ((tmp = [_dict valueForKey:@"email2"])) {
    if (![[_eo valueForKey:@"email2"] isEqual:tmp]) {
      [upd setSafeObject:tmp forKey:@"email2"];
    }
  }

  if ((tmp = [_dict valueForKey:@"email3"])) {
    if (![[_eo valueForKey:@"email3"] isEqual:tmp]) {
      [upd setSafeObject:tmp forKey:@"email3"];
    }
  }
 
  return upd;
}

- (void)updateObject:(NSDictionary *)_vars {
  id                  obj;
  NSMutableDictionary *dict, *upd;

  dict = [self setObjectValues:_vars];
  obj  = [self object];
  upd  = [self checkForObjectModifications:obj in:dict];
  

  if (![upd count] && !self->incVersion)
    return;
  
  [obj updateFromSnapshot:upd];

  [self->cmdCtx runCommand:[self setCommand] arguments:obj];

  self->incVersion = NO;
}

- (void)updatePhones:(NSDictionary *)_phones {
  NSEnumerator *enumerator;
  NSString     *key;

  enumerator = [_phones keyEnumerator];

  while ((key = [enumerator nextObject])) {
    [self updatePhone:key value:[_phones objectForKey:key]];
  }
}

- (id)update {
  [self updateObject:self->attrs];
  
  [self updatePhones:[self->attrs objectForKey:@"phoneNumbers"]];

  if (![self->cmdCtx commit]) {
    NSLog(@"commit failed ....");
    return nil;
  }
  return self->object;
}

- (BOOL)wasNew {
  return self->wasNew;
}

- (NSString *)type {
  return self->type;
}

- (void)setType:(NSString *)_type {
  ASSIGN(self->type, _type);
}

@end /* SxUpdateContact */
