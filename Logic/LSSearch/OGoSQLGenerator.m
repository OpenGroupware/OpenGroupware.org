/*
  Copyright (C) 2006 Helge Hess

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

#include "OGoSQLGenerator.h"
#include <NGExtensions/EOTrueQualifier.h>
#include <EOControl/EOKeyGlobalID.h>
#include "common.h"

@implementation OGoSQLGenerator

- (void)dealloc {
  [self->prefixToEntity release];
  [self->prefixToAlias  release];
  [self->sql            release];
  [self->adaptor        release];
  [self->entity         release];
  [self->model          release];
  [super dealloc];
}

/* raw content */

- (void)appendSQL:(NSString *)_sql {
  if ([_sql isNotEmpty])
    [self->sql appendString:_sql];
}


/* entity */

- (BOOL)isCompanyEntity:(EOEntity *)_entity {
  NSString *en;
  
  if (_entity == nil)
    return NO;

  en = [_entity name];
  if ([en isEqualToString:@"Person"])     return YES;
  if ([en isEqualToString:@"Enterprise"]) return YES;
  if ([en isEqualToString:@"Team"])       return YES;
  if ([en isEqualToString:@"Company"])    return YES;
  return NO;
}


/* operators */

- (NSString *)sqlForOperator:(SEL)_sel {
  NSString *sop;
  
  sop = [EOQualifier stringForOperatorSelector:_sel];
  if (![sop isNotEmpty]) {
    [self errorWithFormat:@"could not resolve qualifier operator: %@", 
	    NSStringFromSelector(_sel)];
    return @"=";
  }
  
  if ([sop isEqualToString:@"caseInsensitiveLike"]) {
    return [[self->adaptor name] hasPrefix:@"Postgre"]
      ? @"ILIKE"
      : @"LIKE"; /* used with UPPER, see below */
  }
  else if ([sop isEqualToString:@"like"])
    return @"LIKE";
  
  return sop;
}

- (BOOL)needsUpperForOperator:(SEL)_sel {
  NSString *sop;
  
  sop = [EOQualifier stringForOperatorSelector:_sel];
  
  if ([[self->adaptor name] hasPrefix:@"Postgre"]) {
    if ([sop isEqualToString:@"caseInsensitiveLike"])
      /* directly supported by PostgreSQL */
      return NO;
  }  
  
  if ([sop rangeOfString:@"case"].length > 0)
    return YES;
  
  return NO;
}


/* column processing */

- (NSString *)prefixForRelationship:(NSString *)_name {
  // TODO: we should add support for those qualifiers supported by
  //       LSExtendedSearchCommand, eg 01_tel.info
  NSString *p;
  
  if ((p = [self->prefixToAlias objectForKey:_name]) != nil)
    return p;
  
  /* by default we just use the name! (eg 'address' or 'phone') */
  [self->prefixToAlias setObject:_name forKey:_name];
  return _name;
}

- (EOEntity *)entityForRelationship:(NSString *)_name {
  NSString *ename;
  EOEntity *e;
  
  if (![_name isNotEmpty])
    return nil;
  if ((e = [self->prefixToEntity objectForKey:_name]) != nil)
    return e;
  
  /* some hardcoded special names */
  
  if ([_name isEqualToString:@"address"])
    ename = @"Address";
  else if ([_name isEqualToString:@"person"])
    ename = @"Person";
  else if ([_name isEqualToString:@"enterprise"])
    ename = @"Enterprise";
  else if ([_name isEqualToString:@"phone"] || 
	   [_name isEqualToString:@"telephones"])
    ename = @"Telephone";
  else if ([_name isEqualToString:@"extendedAttributes"]) {
    if ([self isCompanyEntity:self->entity])
      ename = @"CompanyValue";
    else
      ename = @"ObjectProperty";
  }
  else
    ename = _name;
  
  /* lookup entity in model */
  e = [self->model entityNamed:ename];
  
  if (e != nil) [self->prefixToEntity setObject:e forKey:_name];
  return e;
}

- (NSString *)columnNameForKey:(NSString *)_key attribute:(EOAttribute **)_a {
  EOAttribute *a;
  NSRange r;
  
  if (_a != NULL) *_a = nil;
  
  if (_key == nil)
    return nil;
  
  /* first check whether its an attribute of the base entity */

  if ((a = [self->entity attributeNamed:_key]) != nil) {
    if (_a != NULL) *_a = a;
    return [@"B." stringByAppendingString:[a columnName]];
  }

  /* check for globalid */
  
  if ([_key isEqualToString:@"globalID"] || [_key isEqualToString:@"gid"] ||
      [_key isEqualToString:@"primaryKey"] || [_key isEqualToString:@"pkey"]) {
    a = [[self->entity primaryKeyAttributes] lastObject];
    if (_a != NULL) *_a = a;
    return [@"B." stringByAppendingString:[a columnName]];
  }
  
  /* check whether its a comment */

  if ([_key isEqualToString:@"comment"])
    /* handled in a different place */
    return nil;
  
  /* check whether its a relationship, eg 'address.city' */
  
  if ((r = [_key rangeOfString:@"."]).length > 0) {
    /* Note: we do not support nesting yet */
    EOEntity *relEntity;
    NSString *relship, *prefix;
    
    /* eg 'address' or 'phone' */
    relship   = [_key substringToIndex:r.location];
    _key      = [_key substringFromIndex:(r.location + r.length)];
    prefix    = [self prefixForRelationship:relship];
    relEntity = [self entityForRelationship:relship];
    a         = [relEntity attributeNamed:_key];
    
    if (_a != NULL) *_a = a;
    return [[prefix stringByAppendingString:@"."] 
	            stringByAppendingString:[a columnName]];
  }
  
  /* check a few special keys used in DocumentAPI (_mapKeyFromEOToDoc:) */

  if ([self isCompanyEntity:self->entity]) {
    if ([_key isEqualToString:@"nickname"])
      return [self columnNameForKey:@"description" attribute:_a];
    if ([_key isEqualToString:@"gender"])
      return [self columnNameForKey:@"sex" attribute:_a];
  }
  
  /* a custom attribute, this is handled in a different place */
  return nil;
}

- (BOOL)isCSVAttribute:(EOAttribute *)_attribute {
  /* eg 'keywords' */
  EOEntity *aentity;
  
  if ((aentity = [_attribute entity]) == nil)
    return NO;

  if ([self isCompanyEntity:aentity]) {
    if ([[_attribute name] isEqualToString:@"keywords"]) {
      /* keywords / categories are stored as: "KEY1, KEY1, KEY1" */
      return YES;
    }
  }
  
  return NO;
}


/* fullsearch qualifiers */

- (void)appendFullSearchKeyValueQualifier:(EOKeyValueQualifier *)_q {
  // TODO: implement fullsearch qualifiers
  [self errorWithFormat:
	  @"fullsearch qualifiers are not yet implemented: %@", _q];
}

/* extra attributes */

- (BOOL)doGenerateCompanyValueChecks {
  return [self isCompanyEntity:self->entity];
}
- (BOOL)doGenerateObjectPropertyChecks {
  return YES;
}

- (void)appendExtAttrKeyValueQualifier:(EOKeyValueQualifier *)_q
  prefix:(NSString *)_prefix
  keyAttribute:(EOAttribute *)_key
  valueAttribute:(EOAttribute *)_value
{
  NSString *operator, *sqlValue;
  BOOL     needsUpper, isNull;
  
  operator   = [self sqlForOperator:[_q selector]];
  needsUpper = [self needsUpperForOperator:[_q selector]];
  isNull     = ![[_q value] isNotNull];

  [self->sql appendString:@"( "];
  
  /* check key */
  
  sqlValue = [self->adaptor formatValue:[_q key] forAttribute:_key];
  if ([_prefix isNotEmpty]) {
    [self->sql appendString:_prefix];
    [self->sql appendString:@"."];
  }
  [self->sql appendString:[_key columnName]];
  [self->sql appendString:@" = "];
  [self->sql appendString:sqlValue];

  /* check value */
  
  [self->sql appendString:@" AND "];
  if (!isNull) {
    if (needsUpper) [self->sql appendString:@"UPPER("];
    if ([_prefix isNotEmpty]) {
      [self->sql appendString:_prefix];
      [self->sql appendString:@"."];
    }
    [self->sql appendString:[_value columnName]];
    if (needsUpper) [self->sql appendString:@")"];

    /* operator */
    [self->sql appendString:@" "];
    [self->sql appendString:operator];
    [self->sql appendString:@" "];
    
    /* RHS */
    if (needsUpper) [self->sql appendString:@"UPPER("];
    sqlValue = [self->adaptor formatValue:[_q value] forAttribute:_value];
    [self->sql appendString:sqlValue];
    if (needsUpper) [self->sql appendString:@")"];
  }
  else {
    // TODO: 'null' should also match if the attribute is not in the table!
    if ([_prefix isNotEmpty]) {
      [self->sql appendString:_prefix];
      [self->sql appendString:@"."];
    }
    [self->sql appendString:[_value columnName]];
    
    if ([operator isEqualToString:@"="])
      [self->sql appendString:@" IS NULL"];
    else if ([operator isEqualToString:@"!="])
      [self->sql appendString:@" IS NOT NULL"];
    else {
      [self->sql appendString:@" "];
      [self->sql appendString:operator];
      [self->sql appendString:@" NULL"];
    }
  }

  /* close check */
  [self->sql appendString:@" )"];
}

- (void)appendExtAttrKeyValueQualifier:(EOKeyValueQualifier *)_q {
  NSString *operator;
  BOOL     needsUpper, isNull;
  
  operator   = [self sqlForOperator:[_q selector]];
  needsUpper = [self needsUpperForOperator:[_q selector]];
  isNull     = ![[_q value] isNotNull];
  
  /* first generate company_value checks */
  
  if ([self doGenerateCompanyValueChecks]) {
    /*
       eg: email1 caseInsensitiveLike '*@def.de'
       =>  (CV.attribute = 'email1' AND CV.value_string ILIKE '%@def.de')
    */
    EOEntity *cvEntity;
    
    /* ensure that the join is setup, we use special alias 'CV' */
    cvEntity = [self->model entityNamed:@"CompanyValue"];
    [self->prefixToAlias  setObject:@"CV"    forKey:@"extendedAttributes"];
    [self->prefixToEntity setObject:cvEntity forKey:@"extendedAttributes"];
    
    [self appendExtAttrKeyValueQualifier:_q prefix:@"CV"
	  keyAttribute:[cvEntity attributeNamed:@"attribute"]
	  valueAttribute:[cvEntity attributeNamed:@"value"]];
  }
  
  /* then generate obj_property checks */
  // TODO: this is almost a DUP
  // TODO: we might want to support types, eg use valueInt if the value in the
  //       qualifier is an INT.
  //       Currently we always check against the valueString.

  if ([self doGenerateObjectPropertyChecks]) {
    /*
       eg: email1 caseInsensitiveLike '*@def.de'
       =>  (OP.attribute = 'email1' AND OP.value_string ILIKE '%@def.de')
    */
    EOEntity *opEntity;
    
    /* ensure that the join is setup, we use special alias 'OP' */
    opEntity = [self->model entityNamed:@"ObjectProperty"];
    [self->prefixToAlias  setObject:@"OP"    forKey:@"objectProperties"];
    [self->prefixToEntity setObject:opEntity forKey:@"objectProperties"];

    // TODO: add namespace support?
    [self appendExtAttrKeyValueQualifier:_q prefix:@"OP"
	  keyAttribute:[opEntity attributeNamed:@"key"]
	  valueAttribute:[opEntity attributeNamed:@"valueString"]];
  }
}

/* comments */

- (void)appendCommentKeyValueQualifier:(EOKeyValueQualifier *)_q {
  if ([self isCompanyEntity:self->entity]) {
    /* company_info */
    EOEntity *centity;
    id value;

    value = [_q value];
    
    /* ensure that the join is setup, we use special alias 'C' */
    centity = [self->model entityNamed:@"CompanyInfo"];
    [self->prefixToAlias  setObject:@"C"    forKey:@"comment"];
    [self->prefixToEntity setObject:centity forKey:@"comment"];
    
    if ([value isNotNull]) {
      EOAttribute *attribute;
      NSString    *sqlValue, *operator;
      BOOL        needsUpper;
      
      attribute = [centity attributeNamed:@"comment"];
      
      sqlValue   = [self->adaptor formatValue:value forAttribute:attribute];
      operator   = [self sqlForOperator:[_q selector]];
      needsUpper = [self needsUpperForOperator:[_q selector]];
      
      [self->sql appendString:needsUpper ? @"UPPER(C.comment) ":@"C.comment "];
      [self->sql appendString:operator];
      [self->sql appendString:@" "];
      if (needsUpper) [self->sql appendString:@"UPPER("];
      [self->sql appendString:sqlValue];
      if (needsUpper) [self->sql appendString:@")"];
    }
    else
      [self->sql appendString:@"C.comment IS NULL"];
    
    return;
  }
  
  // TODO: implement for appointments? jobs/jobhistory?
  
  [self errorWithFormat:
	  @"comment qualifiers are not yet implemented for entity: %@\n%@", 
	  _q, self->entity];
}

/* CSV attribute */

- (NSString *)sqlForCSVColumn:(NSString *)_column value:(NSString *)_value
  attribute:(EOAttribute *)_attribute
{
  NSMutableString *ms = [NSMutableString stringWithCapacity:256];

  if (![_value isNotEmpty])
    return nil;
  _value = [_value stringValue];
  
  [ms appendString:@"( "];
  
  /* exact match: 'Customer' */
  [ms appendString:_column];
  [ms appendString:@" = "];
  [ms appendString:[self->adaptor formatValue:_value forAttribute:_attribute]];
  
  // TODO: check formatValue, does it preserve or escape patterns?
  // TODO: check for SQL injection!
  
  /* prefix: 'Customer, Provider' */
  [ms appendString:@" OR "];
  [ms appendString:_column];
  [ms appendString:@" LIKE '"]; // PostgreSQL/SQL92 quotes
  [ms appendString:_value];
  [ms appendString:@", %'"];
  
  /* suffix: 'Provider, Customer'*/
  [ms appendString:@" OR "];
  [ms appendString:_column];
  [ms appendString:@" LIKE '%, "]; // PostgreSQL/SQL92 quotes
  [ms appendString:_value];
  [ms appendString:@"'"];
  
  /* infix: 'Provider, Customer, Client' */
  [ms appendString:@" OR "];
  [ms appendString:_column];
  [ms appendString:@" LIKE '%, "]; // PostgreSQL/SQL92 quotes
  [ms appendString:_value];
  [ms appendString:@", %'"];
  
  [ms appendString:@" )"];
  return ms;
}


/* specific qualifiers */

- (void)appendKeyValueQualifier:(EOKeyValueQualifier *)_q {
  EOAttribute *attribute = nil;
  NSString    *lk, *lkColumn;
  id          value;
  BOOL        needsUpper;
  NSString    *operator;
  NSString    *sqlValue;
  
  if ((lk = [_q key]) == nil) {
    [self warnWithFormat:@"EOKeyValueQualifier has no key: %@", _q];
    return;
  }
  
  /* special hack for fullsearch */
  
  if ([lk isEqualToString:@"fullSearchString"]) {
    [self appendFullSearchKeyValueQualifier:_q];
    return;
  }
  
  /* if we get nil we have a special case, either a comment or an extattr */
  
  if ((lkColumn = [self columnNameForKey:lk attribute:&attribute]) == nil) {
    if ([lkColumn isEqualToString:@"comment"])
      [self appendCommentKeyValueQualifier:_q];
    else
      [self appendExtAttrKeyValueQualifier:_q];
    return;
  }
  
  /* operator/value */
  
  value      = [_q value];
  operator   = [self sqlForOperator:[_q selector]];
  needsUpper = [self needsUpperForOperator:[_q selector]];

  /* check for CSV attributes */
  
  if ([self isCSVAttribute:attribute]) {
    if ([value isKindOfClass:[NSArray class]]) {
      /* eg person/company keywords */
      // TODO: implement
      [self errorWithFormat:@"array CSV syntax not supported yet: %@", _q];
      return;
    }
    
    if ([operator isEqualToString:@"="]) {
      [self->sql appendString:
	     [self sqlForCSVColumn:lkColumn value:value attribute:attribute]];
      return;
    }

    // the client used some own operator, so probably deals with the stuff
    // on its own
  }

  /* check for IN queries */
  
  if ([value isKindOfClass:[NSArray class]]) {
    unsigned i, count;

    if ((count = [value count]) == 0)
      value = nil; /* treat as NULL */
    else if (count == 1)
      value = [value lastObject]; /* regular processing */
    else if ([operator isEqualToString:@"="] || 
	     [operator isEqualToString:@"IN"]) {
      [self->sql appendString:lkColumn];
      [self->sql appendString:@" IN ("];

      for (i = 0; i < count; i++) {
	if (i > 0) [self->sql appendString:@", "];
	sqlValue = [self->adaptor formatValue:[value objectAtIndex:i] 
			          forAttribute:attribute];
	[self->sql appendString:sqlValue];
      }
      [self->sql appendString:@" )"];
      return;
    }
    else {
      /* some arbitary operator, we need to OR */
      [self->sql appendString:@"( "];
      for (i = 0; i < count; i++) {
	if (i > 0) [self->sql appendString:@" OR "];
	[self->sql appendString:lkColumn];
	[self->sql appendString:@" "];
	[self->sql appendString:operator];
	[self->sql appendString:@" "];
	
	sqlValue = [self->adaptor formatValue:[value objectAtIndex:i] 
			          forAttribute:attribute];
	if (needsUpper) [self->sql appendString:@"UPPER("];
	[self->sql appendString:sqlValue];
	if (needsUpper) [self->sql appendString:@")"];
      }
      [self->sql appendString:@" )"];
      return;
    }
  }
  
  /* check for NULL comparison */
  
  if (![value isNotNull]) {
    [self->sql appendString:lkColumn];
  
    if ([operator isEqualToString:@"="] || [operator isEqualToString:@"LIKE"])
      [self->sql appendString:@" IS NULL"];
    else if ([operator isEqualToString:@"!="])
      [self->sql appendString:@" IS NOT NULL"];
    else {
      /* stuff like >NULL, <NULL etc ... */
      [self->sql appendString:@" "];
      [self->sql appendString:operator];
      [self->sql appendString:@" NULL"];
    }
    return;
  }
  
  /* regular key/value comparison */
  
  sqlValue = [self->adaptor formatValue:value forAttribute:attribute];
  
  /* lhs */
  if (needsUpper) [self->sql appendString:@"UPPER("];
  [self->sql appendString:lkColumn];
  if (needsUpper) [self->sql appendString:@")"];
  [self->sql appendString:@" "];
  
  /* op */
  [self->sql appendString:operator];
  
  /* rhs */
  [self->sql appendString:@" "];
  if (needsUpper) [self->sql appendString:@"UPPER("];
  [self->sql appendString:sqlValue];
  if (needsUpper) [self->sql appendString:@")"];
}


/* key comparison qualifier, only supported for core attributes */

- (void)appendKeyComparisonQualifier:(EOKeyComparisonQualifier *)_q {
  NSString *lkColumn, *rkColumn;
  BOOL needsUpper;
  
  lkColumn = [self columnNameForKey:[_q leftKey]  attribute:NULL];
  rkColumn = [self columnNameForKey:[_q rightKey] attribute:NULL];
  
  if (lkColumn == nil || rkColumn == nil) {
    [self errorWithFormat:
	    @"key unsupported in key-comparison qualifier: %@", _q];
    return;
  }
  
  needsUpper = [self needsUpperForOperator:[_q selector]];

  /* LHS */
  if (needsUpper) [self->sql appendString:@"UPPER("];
  [self->sql appendString:lkColumn];
  if (needsUpper) [self->sql appendString:@")"];
  
  /* operator */
  [self->sql appendString:@" "];
  [self->sql appendString:[self sqlForOperator:[_q selector]]];
  [self->sql appendString:@" "];
  
  /* RHS */
  if (needsUpper) [self->sql appendString:@"UPPER("];
  [self->sql appendString:rkColumn];
  if (needsUpper) [self->sql appendString:@")"];
}


/* compound qualifiers */

- (void)appendCompoundQualifier:(EOQualifier *)_q operator:(NSString *)_op {
  NSArray  *sq;
  unsigned i, count;
  
  if (_q == nil) return;
  
  if (![(sq = [(EOAndQualifier *)_q qualifiers]) isNotEmpty]) {
    /* nothing to compare */
    return;
  }
  
  if ((count = [sq count]) == 1) {
    /* just a single subqualifier */
    [self appendQualifier:[sq objectAtIndex:0]];
    return;
  }

  if (![_op isNotEmpty]) {
    [self errorWithFormat:@"missing compound operator, using AND."];
    _op = @"AND";
  }
  
  [self->sql appendString:@"( "]; /* German 101: sicher ist sicher ;-) */
  
  for (i = 0; i < count; i++) {
    if (i != 0) {
      [self->sql appendString:@" "];
      [self->sql appendString:_op];
      [self->sql appendString:@" "];
    }
    
    [self->sql appendString:@"( "];
    [self appendQualifier:[sq objectAtIndex:i]];
    [self->sql appendString:@" )"];
  }
  
  [self->sql appendString:@" )"];
}

- (void)appendAndQualifier:(EOAndQualifier *)_q {
  [self appendCompoundQualifier:_q operator:@"AND"];
}
- (void)appendOrQualifier:(EOOrQualifier *)_q {
  [self appendCompoundQualifier:_q operator:@"OR"];
}

- (void)appendNotQualifier:(EONotQualifier *)_q {
  EOQualifier *q;
  
  if (_q == nil) return;
  
  if ((q = [_q qualifier]) != nil) {
    [self->sql appendString:@"NOT ( "];
    [self appendQualifier:q];
    [self->sql appendString:@" )"];
  }
  else {
    /* if we have no subqualifier, NOT defaults to false ... */
    [self->sql appendString:@" ( 1 = 0 )"];
    [self warnWithFormat:@"EONotQualifier w/o a subqualifier: %@", _q];
  }
}

- (void)appendTrueQualifier:(EOTrueQualifier *)_q {
  // don't need to generate anything for TRUE
}


/* qualifier generation */

- (void)appendQualifier:(EOQualifier *)_qualifier {
  if (_qualifier == nil)
    return;
  
  if ([_qualifier isKindOfClass:[EOKeyValueQualifier class]])
    [self appendKeyValueQualifier:(EOKeyValueQualifier *)_qualifier];
  else if ([_qualifier isKindOfClass:[EOAndQualifier class]])
    [self appendAndQualifier:(EOAndQualifier *)_qualifier];
  else if ([_qualifier isKindOfClass:[EOOrQualifier class]])
    [self appendOrQualifier:(EOOrQualifier *)_qualifier];
  else if ([_qualifier isKindOfClass:[EONotQualifier class]])
    [self appendNotQualifier:(EONotQualifier *)_qualifier];
  else if ([_qualifier isKindOfClass:[EOKeyComparisonQualifier class]])
    [self appendKeyComparisonQualifier:(EOKeyComparisonQualifier *)_qualifier];
  else if ([_qualifier isKindOfClass:[EOTrueQualifier class]])
    [self appendTrueQualifier:(EOTrueQualifier *)_qualifier];
  else {
    [self errorWithFormat:@"cannot handle qualifier: %@", _qualifier];
    [self->sql release]; self->sql = nil;
  }
}

/* generate joins */

- (NSString *)generateTableList {
  NSMutableString *ms;
  NSEnumerator *pe;
  NSString     *prefix;

  ms = [NSMutableString stringWithCapacity:512];
  
  /* first, the base entity */
  [ms appendString:[self->entity externalName]];
  [ms appendString:@" AS B"];

  pe = [self->prefixToEntity keyEnumerator];
  while ((prefix = [pe nextObject]) != nil) {
    EOEntity *jEntity = [self->prefixToEntity objectForKey:prefix];
    NSString *alias   = [self->prefixToAlias  objectForKey:prefix];
    
    [ms appendString:@", "];
    [ms appendString:[jEntity externalName]];
    if ([alias isNotEmpty]) {
      [ms appendString:@" AS "];
      [ms appendString:alias];
    }
  }
  
  return ms;
}

- (NSString *)generateJoinClause {
  NSMutableString *ms;
  NSEnumerator *pe;
  NSString     *prefix;
  EOAttribute  *pkey;
  NSString     *basePKeyColumn;
  NSString     *pkeyName;

  ms = [NSMutableString stringWithCapacity:512];
  
  /* first, construct the base entity primary key */
  
  pkey           = [[self->entity primaryKeyAttributes] lastObject];
  pkeyName       = [pkey name];
  basePKeyColumn = [@"B." stringByAppendingString:[pkey columnName]];
  
  /* now generate a join for each prefix ... */
  
  pe = [self->prefixToEntity keyEnumerator];
  while ((prefix = [pe nextObject]) != nil) {
    EOEntity    *jEntity;
    NSString    *jEName;
    EOAttribute *fkey;
    NSString    *alias;

    /* lookup foreign key */
    
    jEntity = [self->prefixToEntity objectForKey:prefix];
    jEName  = [jEntity name];
    alias   = [self->prefixToAlias  objectForKey:prefix];
    
    if ([jEName isEqualToString:@"ObjectLink"]) {
      fkey = [jEntity attributeNamed:@"sourceId"];
    }
    else if ([jEName hasPrefix:@"Object"] || [jEName isEqualToString:@"Log"]) {
      /* ObjectInfo, ObjectProperty, ObjectAcl */
      fkey = [jEntity attributeNamed:@"objectId"];
    }
    else {
      /* assume the foreign key is named just like the primary key ... */
      fkey = [jEntity attributeNamed:pkeyName];
    }

    if (fkey == nil) {
      [self errorWithFormat:@"did not find foreign key for prefix: %@",prefix];
      continue;
    }

    /* add separator */
    
    if ([ms length] > 0)
      [ms appendString:@" AND "];
    
    /* add join */

    [ms appendString:basePKeyColumn];
    [ms appendString:@" = "];
    if ([alias isNotEmpty])
      [ms appendString:alias];
    else
      [ms appendString:[jEntity externalName]];
    [ms appendString:@"."];
    [ms appendString:[fkey columnName]];
  }
  
  return ms;
}

/* ACL support */

- (NSNumber *)primaryKeyFromObject:(id)_obj {
  id tmp;
  
  if (![_obj isNotNull])
    return nil;

  if ([_obj isKindOfClass:[NSNumber class]])
    return _obj;
  
  if ([_obj isKindOfClass:[EOKeyGlobalID class]])
    return [(EOKeyGlobalID *)_obj keyValues][0];
  
  if ((tmp = [_obj valueForKey:@"globalID"]) != nil)
    return [self primaryKeyFromObject:tmp];

  if ((tmp = [_obj valueForKey:@"gid"]) != nil)
    return [self primaryKeyFromObject:tmp];
  
  /* hacks */
  if ((tmp = [_obj valueForKey:@"companyId"]) != nil)
    return [self primaryKeyFromObject:tmp];
  if ((tmp = [_obj valueForKey:@"dateId"]) != nil)
    return [self primaryKeyFromObject:tmp];
  if ((tmp = [_obj valueForKey:@"objectId"]) != nil)
    return [self primaryKeyFromObject:tmp];
  if ((tmp = [_obj valueForKey:@"jobId"]) != nil)
    return [self primaryKeyFromObject:tmp];

  [self errorWithFormat:
	  @"could not retrieve primary key from object: %@", _obj];
  return nil;
}

- (NSString *)aclClauseWithOwnerAttribute:(EOAttribute *)_ownerAttr
  privateAttribute:(EOAttribute *)_privateAttr
  loginId:(id)_loginId
  loginTeams:(NSArray *)_teams
{
  /* oh yes, this uses nested selects. but well, ... */
  NSMutableString *ms = [NSMutableString stringWithCapacity:2048];
  NSString     *loginPKeyStr;
  EOAttribute  *pkey;
  NSString     *basePKeyColumn;
  NSString     *pkeyName;
  
  loginPKeyStr = [[self primaryKeyFromObject:_loginId] stringValue];

  /* first, construct the base entity primary key */
  
  pkey           = [[self->entity primaryKeyAttributes] lastObject];
  pkeyName       = [pkey name];
  basePKeyColumn = [@"B." stringByAppendingString:[pkey columnName]];
  
  /* check owner */
  
  if (_ownerAttr != nil) {
    /* owners always have access and owners cannot be teams */
    [ms appendString:@"( B."];
    
    [ms appendString:[_ownerAttr columnName]];
    [ms appendString:@" = "];
    [ms appendString:loginPKeyStr];
    
    [ms appendString:@" ) OR ( "];
  }

  /* check whether private flag is set (if we have one) */

  if (_privateAttr != nil) {
    [ms appendString:@"( B."];
    [ms appendString:[_privateAttr columnName]];
    [ms appendString:@" = 0 OR B."];
    [ms appendString:[_privateAttr columnName]];
    [ms appendString:@" IS NULL"];
    
    [ms appendString:@" ) AND ( "];
  }

  [ms appendString:@" ( "];
  
  // TODO: possibly we could merge the next two subselects in one? */

  /* first check whether we an ACL is attached to the object */
  
  [ms appendString:
	@"0 = ( SELECT COUNT(*) FROM object_acl WHERE object_id = B."];
  [ms appendString:basePKeyColumn];
  [ms appendString:@" )"];
  
  /* next check whether we are in the ACL if there is one */
  
  [ms appendString:@" OR "]; /* only need to check IF we have an ACL */
  
  [ms appendString:
	@"0 < ( SELECT COUNT(*) FROM object_acl WHERE object_id = B."];
  [ms appendString:basePKeyColumn];

  // Note: we support no ordering and we support no 'forbidden'
  [ms appendString:@" AND action = 'allowed' AND permissions LIKE '%r%' AND "];
  
  [ms appendString:@"( auth_id = "];
  [ms appendString:loginPKeyStr];

  if (_teams == nil) {
    /* fetch all teams where the login is a member using a subselect ... */
    // Note: nested teams unsupported
    [ms appendString:@" OR auth_id IN ( "];
    [ms appendString:
	 @"SELECT company_id FROM company_assignment WHERE sub_company_id = "];
    [ms appendString:loginPKeyStr];
    [ms appendString:@" )"];
  }
  else if ([_teams isNotEmpty]) {
    /* we have a set of cached teams, add IDs */
    unsigned i, count;
    
    [ms appendString:@" OR auth_id IN ( "];
    for (i = 0, count = [_teams count]; i < count; i++) {
      if (i > 0) [ms appendString:@", "];
      [ms appendString:
	  [[self primaryKeyFromObject:[_teams objectAtIndex:i]] stringValue]];
    }
    [ms appendString:@" )"];
  }
  
  [ms appendString:@" )"]; /* close auth_id query */
  
  [ms appendString:@" )"]; /* close bigger ACL subselect */
  
  [ms appendString:@" ) "]; /* close top-level ACL section */
  
  /* close brackets */
  
  if (_privateAttr != nil)
    [ms appendString:@" )"];
  if (_ownerAttr != nil)
    [ms appendString:@" )"];
  
  return ms;
}

@end /* OGoSQLGenerator */
