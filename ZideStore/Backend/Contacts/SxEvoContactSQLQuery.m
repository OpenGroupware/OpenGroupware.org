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

#include "SxEvoContactSQLQuery.h"
#include "common.h"
#include "NSObject+DBColumns.h"

@implementation SxEvoContactSQLQuery

- (void)dealloc {
  [super dealloc];
}

/* controlling generation */

- (BOOL)shouldFetchAllEmails {
  return YES;
}
- (BOOL)shouldFetchAllPhoneNumbers {
  return YES;
}

- (BOOL)shouldFetchJobTitle {
  return YES;
}

- (BOOL)shouldFetchLocationAddress {
  return YES;
}
- (BOOL)shouldFetchMailingAddress {
  return YES;
}
- (BOOL)shouldFetchPrivateAddress {
  return YES;
}

- (BOOL)limitFetchToAccountGroups {
  return NO;// [self isGroupQuery];
}

/* SQL generation */

- (void)addAddrResultOfTable:(NSString *)_alias prefix:(NSString *)_p
  to:(NSMutableString *)_sql 
{
  NSString *pn1, *pn2, *pn3, *ps, *pz, *pc, *pco, *pst;
  
  pn1 = [_p stringByAppendingString:@"name1"];
  pn2 = [_p stringByAppendingString:@"name2"];
  pn3 = [_p stringByAppendingString:@"name3"];
  ps  = [_p stringByAppendingString:@"street"];
  pz  = [_p stringByAppendingString:@"zip"];
  pc  = [_p stringByAppendingString:@"city"];
  pco = [_p stringByAppendingString:@"country"];
  pst = [_p stringByAppendingString:@"state"];
  
  [self addColumn:@"name1"   of:_alias as:pn1 to:_sql];
  [self addColumn:@"name2"   of:_alias as:pn2 to:_sql];
  [self addColumn:@"name3"   of:_alias as:pn3 to:_sql];
  [self addColumn:@"street"  of:_alias as:ps  to:_sql];
  [self addColumn:@"zip"     of:_alias as:pz  to:_sql];
  [self addColumn:@"zipcity" of:_alias as:pc  to:_sql];
  [self addColumn:@"country" of:_alias as:pco to:_sql];
  [self addColumn:@"state"   of:_alias as:pst to:_sql];
}

- (void)generateSelect:(NSMutableString *)_sql {
  NSString *t;
  
  [self addFirstColumn:@"c1.company_id" as:@"pkey" to:_sql];
  
  if ([self isPersonQuery]) {
    t = [@"c1." stringByAppendingString:[self nameColumn]];
    [self addColumn:t as:@"sn" to:_sql];
  
    [self addColumn:@"c1.firstname"      as:@"givenname"          to:_sql];
    [self addColumn:@"c1.middlename"     as:@"middlename"         to:_sql];
    [self addColumn:@"c1.salutation"     as:@"salutation"         to:_sql];
    [self addColumn:@"c1.birthday"       as:@"bday"               to:_sql];
    [self addColumn:@"c1.description"    as:@"nickname"           to:_sql];
    [self addColumn:@"c1.boss_name"      as:@"manager"            to:_sql];
    [self addColumn:@"c1.partner_name"   as:@"spousecn"           to:_sql];
    [self addColumn:@"c1.assistant_name" as:@"secretarycn"        to:_sql];
    [self addColumn:@"c1.department"     as:@"department"         to:_sql];
    [self addColumn:@"c1.office"         as:@"roomnumber"         to:_sql];
    [self addColumn:@"c1.occupation"     as:@"profession"         to:_sql];
    [self addColumn:@"c1.anniversary"    as:@"weddinganniversary" to:_sql];
    [self addColumn:@"c1.freebusy_url"   as:@"fburl"              to:_sql];
    [self addColumn:@"c1.name_title"     as:@"nametitle"          to:_sql];
    [self addColumn:@"c1.name_affix"     as:@"nameaffix"          to:_sql];
    [self addColumn:@"c1.im_address"     as:@"imaddress"          to:_sql];
    [self addColumn:@"c1.associated_contacts"
          as:@"associatedcontacts" to:_sql];
    [self addColumn:@"c1.associated_categories"
          as:@"associatedcategories" to:_sql];
    [self addColumn:@"c1.associated_company"
          as:@"associatedcompany" to:_sql];
  }
  else if ([self isEnterpriseQuery] || [self isGroupQuery]) {
    [self addColumn:@"c1.description" as:@"cn" to:_sql];
    [self addColumn:@"c1.email"       as:@"email1" to:_sql];

  }

  [self addColumn:@"c1.fileas"         as:@"fileas"             to:_sql];
  [self addColumn:@"c1.url"            as:@"url"            to:_sql];
  [self addColumn:@"c1.object_version" as:@"object_version" to:_sql];
  [self addColumn:@"c1.login"          as:@"login"          to:_sql];
  
  if ([self shouldFetchAllEmails] && [self isPersonQuery]) {
    [self addColumn:@"email1.value_string" as:@"email1" to:_sql];
    [self addColumn:@"email2.value_string" as:@"email2" to:_sql];
    [self addColumn:@"email3.value_string" as:@"email3" to:_sql];
  }
  if ([self isPersonQuery])
    [self addColumn:@"extjobtitle.value_string" as:@"jobtitle" to:_sql];
  
  if ([self shouldFetchAllPhoneNumbers] && ![self isGroupQuery]) {
    if (![self isNumberReserved]) {
      [self addColumn:@"t1.number"  as:@"tel01" to:_sql];
      [self addColumn:@"t5.number"  as:@"tel05" to:_sql];
      if ([self isPersonQuery])
	[self addColumn:@"t3.number"  as:@"tel03" to:_sql];
      [self addColumn:@"t10.number" as:@"tel10" to:_sql];
      if ([self isPersonQuery])
	[self addColumn:@"t15.number" as:@"tel15" to:_sql];
    }
    else {
      [self addColumn:@"t1.fnumber"  as:@"tel01" to:_sql];
      [self addColumn:@"t5.fnumber"  as:@"tel05" to:_sql];
      if ([self isPersonQuery])
        [self addColumn:@"t3.fnumber"  as:@"tel03" to:_sql];
      [self addColumn:@"t10.fnumber" as:@"tel10" to:_sql];
      if ([self isPersonQuery])
        [self addColumn:@"t15.fnumber" as:@"tel15" to:_sql];
    }
  }
  
  if ([self isPersonQuery]) {
    if ([self shouldFetchLocationAddress])
      [self addAddrResultOfTable:@"location" prefix:@"loc"  to:_sql];
    if ([self shouldFetchMailingAddress])
      [self addAddrResultOfTable:@"mailing"  prefix:@"mail" to:_sql];
    if ([self shouldFetchPrivateAddress])
      [self addAddrResultOfTable:@"private"  prefix:@"priv" to:_sql];
  }
  else if ([self isEnterpriseQuery]) {
    [self addAddrResultOfTable:@"ship" prefix:@"ship"  to:_sql];
    [self addAddrResultOfTable:@"bill" prefix:@"bill"  to:_sql];
  }
}

- (NSString *)queryStringForType:(NSString *)_type
                            from:(NSString *)_from
                      withFormat:(NSString *)_fmt
{
  return [NSString stringWithFormat:_fmt,
                   _from, _from, [self typeColumn], _type];
}

- (NSString *)stringForType:(NSString *)_type
  from:(NSString *)_from
{
  return [self queryStringForType:_type
               from:_from
               withFormat:
               @"%@.company_id = c1.company_id AND %@.%@ = '%@'"];
}

- (NSString *)andStringForType:(NSString *)_type
  from:(NSString *)_from
{
  return [self queryStringForType:_type
               from:_from
               withFormat:
               @" AND (%@.company_id = c1.company_id(+) AND %@.%@ = '%@')"];
}


- (void)generateFrom:(NSMutableString *)_sql {
  [_sql appendString:@"company c1"];
  
  if ([self limitFetchToAccountGroups])
    [_sql appendString:@", company_assignment a"];
  
  if ([self dbHasAnsiOuterJoins]) {
    if ([self shouldFetchAllEmails] && [self isPersonQuery]) {
      [self addLeftOuterJoin:@"email1" toFromOn:@"company_value"
            query:
              @"email1.company_id = c1.company_id AND "
              @"email1.attribute = 'email1'"
            to:_sql];
      [self addLeftOuterJoin:@"email2" toFromOn:@"company_value"
            query:
              @"email2.company_id = c1.company_id AND "
              @"email2.attribute = 'email2'"
            to:_sql];
      [self addLeftOuterJoin:@"email3" toFromOn:@"company_value"
            query:
              @"email3.company_id = c1.company_id AND "
              @"email3.attribute = 'email3'"
            to:_sql];
    }
    if ([self isPersonQuery]) {
      [self addLeftOuterJoin:@"extjobtitle" toFromOn:@"company_value"
            query:@"(extjobtitle.company_id = c1.company_id AND "
              @"extjobtitle.attribute = 'job_title')"
            to:_sql];
    }
    
    if ([self shouldFetchAllPhoneNumbers] && ![self isGroupQuery]) {
      [self addLeftOuterJoin:@"t1" toFromOn:@"telephone"
            query:[NSString stringWithFormat:@"(%@)",
                            [self stringForType:@"01_tel" from:@"t1"]]
            to:_sql];
      [self addLeftOuterJoin:@"t5" toFromOn:@"telephone"
            query:[self stringForType:@"05_tel_private" from:@"t5"]
            to:_sql];
      [self addLeftOuterJoin:@"t10" toFromOn:@"telephone"
            query:[self stringForType:@"10_fax" from:@"t10"]
            to:_sql];

      if ([self isPersonQuery]) {
        [self addLeftOuterJoin:@"t3" toFromOn:@"telephone"
              query:[self stringForType:@"03_tel_funk" from:@"t3"]
              to:_sql];
	[self addLeftOuterJoin:@"t15" toFromOn:@"telephone"
              query:[self stringForType:@"15_fax_private" from:@"t15"]
	      to:_sql];
      }
    }
    
    if ([self isPersonQuery]) {
      if ([self shouldFetchLocationAddress]) {
        [self addLeftOuterJoin:@"location" toFromOn:@"address"
              query:[self stringForType:@"location" from:@"location"]
              to:_sql];
      }
      if ([self shouldFetchMailingAddress]) {
        [self addLeftOuterJoin:@"mailing" toFromOn:@"address"
              query:[self stringForType:@"mailing" from:@"mailing"]
              to:_sql];
      }
      if ([self shouldFetchPrivateAddress]) {
        [self addLeftOuterJoin:@"private" toFromOn:@"address"
              query:[self stringForType:@"private" from:@"private"]
              to:_sql];
      }
    }
    else if ([self isEnterpriseQuery]) {
      [self addLeftOuterJoin:@"ship" toFromOn:@"address"
            query:[self stringForType:@"ship" from:@"ship"]
            to:_sql];
      [self addLeftOuterJoin:@"bill" toFromOn:@"address"
            query:[self stringForType:@"bill" from:@"bill"]
            to:_sql];
    }
  }
  else {
    /* eg Oracle */
    if ([self isPersonQuery]) {
      [_sql appendString:@", company_value email1"];
      [_sql appendString:@", company_value email2"];
      [_sql appendString:@", company_value email3"];
      [_sql appendString:@", company_value extjobtitle"];
    }
    
    if ([self shouldFetchAllPhoneNumbers]) {
      [_sql appendString:@", telephone t1"];
      [_sql appendString:@", telephone t2"];
      if ([self isPersonQuery])
	[_sql appendString:@", telephone t3"];
      [_sql appendString:@", telephone t10"];
      if ([self isPersonQuery])
	[_sql appendString:@", telephone t15"];
    }
    if ([self isPersonQuery]) {
      if ([self shouldFetchLocationAddress])
	[_sql appendString:@", address location"];
      if ([self shouldFetchMailingAddress])
	[_sql appendString:@", address mailing"];
      if ([self shouldFetchPrivateAddress])
	[_sql appendString:@", address private"];
    }
    else if ([self isEnterpriseQuery]) {
      [_sql appendString:@", address bill"];
      [_sql appendString:@", address ship"];
    }
  }
}

- (void)generateWhereJoins:(NSMutableString *)_sql {
  if ([self limitFetchToAccountGroups]) {
    [_sql appendString:@" AND (a.sub_company_id="];
    [_sql appendString:[[self loginPrimaryKey] stringValue]];
    [_sql appendString:@" AND a.company_id=c1.company_id)"];
  }
  
  if ([self dbHasAnsiOuterJoins])
    return;

  /* Oracle (probably does not work ...) */
  
  if ([self shouldFetchAllEmails]) {
    [_sql appendString:
            @" AND (email1.company_id = c1.company_id(+) AND "
            @"    email1.attribute = 'email1')"
            @" AND (email2.company_id = c1.company_id(+) AND"
            @"    email2.attribute = 'email2')"
            @" AND (email3.company_id = c1.company_id(+) AND"
            @"    email3.attribute = 'email3')"];
  }
  [_sql appendString:
          @" AND (extjobtitle.company_id = c1.company_id(+) AND"
          @"    extjobtitle.attribute = 'job_title')"];
  
  if ([self shouldFetchAllPhoneNumbers]) {
    [_sql appendString:[self andStringForType:@"01_tel" from:@"t1"]];
    [_sql appendString:[self andStringForType:@"02_tel" from:@"t2"]];
    [_sql appendString:[self andStringForType:@"03_tel_funk" from:@"t3"]];
    [_sql appendString:[self andStringForType:@"10_fax" from:@"t10"]];
    [_sql appendString:[self andStringForType:@"15_fax_private" from:@"t15"]];
  }
  
  if ([self isPersonQuery]) {
    if ([self shouldFetchLocationAddress]) {
      [_sql appendString:[self andStringForType:@"location" from:@"location"]];
    }
    if ([self shouldFetchMailingAddress]) {
      [_sql appendString:[self andStringForType:@"mailing" from:@"mailing"]];
    }
    if ([self shouldFetchPrivateAddress]) {
      [_sql appendString:[self andStringForType:@"private" from:@"private"]];
    }
  }
  else if ([self isEnterpriseQuery]) {
      [_sql appendString:[self andStringForType:@"bill" from:@"bill"]];
      [_sql appendString:[self andStringForType:@"ship" from:@"ship"]];
  }
}

@end /* SxEvoContactSQLQuery */
