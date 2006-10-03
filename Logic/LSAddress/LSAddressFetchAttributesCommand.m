/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include <LSFoundation/LSBaseCommand.h>

/*
  address::fetchAttributes / LSAddressFetchAttributesCommand

  entityName - NSString (eg Person, Enterprise)
  searchKeys - array of companyIds (NSNumber primary keys)

  TODO: this is not used by anything?
     => this is used by address::build-converter-data, aka formletters

  TODO: I think this can be replaced by person::get-by-globalid

  Result for a person looks like:
    (
      { companyId = abc;
        gender    = "Herr";         <- special hack!
        email1    = "abc123@def.de";
        ...

        fax = { 
          companyId = 10280; info = "jjk"; number = "123"; type="10_fax";
        };
        10_fax = { 
          companyId = 10280; info = "jjk"; number = "123"; type="10_fax";
        };
        tel1 = { 
          companyId = 10280; info = "jjk"; number = "123"; type="01_tel";
        };
        01_tel = { 
          companyId = 10280; info = "jjk"; number = "123"; type="01_tel";
        };
        tel2 = { 
          companyId = 10280; info = "jjk"; number = "123"; type="02_tel";
        };
        02_tel = { 
          companyId = 10280; info = "jjk"; number = "123"; type="02_tel";
        };

        toAddress = {
          name1 = ....; name2 = ....;
          // no type!
        };
        toEnterprise = {
          // same thing like person but nested
        };
      }
    )
*/
// TODO: the whole file needs major cleanups

@class NSArray, NSString;

@interface LSAddressFetchAttributesCommand : LSBaseCommand
{
  NSArray  *searchKeys;
  NSString *entityName;
}

@end

#include "common.h"

#define _getEntityNamed(_a_)  [[[[_ctx valueForKey:LSDatabaseKey] adaptor] \
                                model] entityNamed:_a_]

@interface LSAddressFetchAttributesCommand(Private)

- (NSArray *)attributesForEntity:(EOEntity *)_entity inContext:(id)_ctx;
- (NSArray *)extendedAttrsForEntity:(EOEntity *)_entity inContext:(id)_ctx;

- (NSDictionary *)fetchRequiredAttributesForKeys:(NSArray *)_keys
  entity:(EOEntity *)_entity keyAttribute:(EOAttribute *)_keyAttr
  context:(LSCommandContext *)_ctx;

- (NSArray *)fetchAttributes:(NSArray *)_attrs keys:(id)_keys
  entity:(id)_entity keyAttribute:(EOAttribute *)_keyAttr
  context:(LSCommandContext *)_ctx ;

- (NSArray *)fetchExtendedAttrs:(NSArray *)_extAttrs keys:(NSArray *)_keys
  context:(LSCommandContext *)_ctx;

- (NSArray *)fetchValuesWithAttributes:(NSArray *)_attrs
  entity:(EOEntity *)_entity keys:(NSArray *)_keys
  keyAttribute:(EOAttribute *)_keyAttr qualifier:(EOSQLQualifier *)_qualifier
  context:(id)_ctx;

- (NSArray *)fetchManyToManyRelationWithSource:(EOEntity *)_src
  keys:(NSArray *)_keys target:(EOEntity *)_target
  assignment:(EOEntity *)_assignment sourceKeyAttr:(EOAttribute *)_srcAttr
  targetKeyAttr:(EOAttribute *)_trgAttr
  context:(LSCommandContext *)_ctx;
- (NSArray *)fetchAddressesForKeys:(NSArray *)_keys kind:(NSString *)_kind
  context:(LSCommandContext *)_ctx;
- (NSArray *)fetchTelephonesForKeys:(NSArray *)_keys entity:(EOEntity *)_entity
  context:(LSCommandContext *)_ctx;
- (NSArray *)fetchCommentsForKeys:(NSArray *)_keys entity:(EOEntity *)_entity
  context:(LSCommandContext *)_ctx;
- (NSArray *)fetchLogForKeys:(NSArray *)_keys entity:(EOEntity *)_entity
  context:(LSCommandContext *)_ctx;
- (NSArray *)fetchOwnerForKeys:(NSArray *)_keys entity:(EOEntity *)_entity
  context:(LSCommandContext *)_ctx;
@end

@implementation LSAddressFetchAttributesCommand

static NSDictionary *phoneCodeToNameMap = nil;
static EONull       *null = nil;

+ (void)initialize {
  if (phoneCodeToNameMap == nil) {
    phoneCodeToNameMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                 @"tel1", @"01_tel",
                                                 @"tel2", @"02_tel",
                                                 @"fax",  @"10_fax", nil];
  }
  if (null == nil) null = [[EONull null] retain];
}

- (void)dealloc {
  [self->searchKeys release];
  [self->entityName release];
  [super dealloc];
}

/* command methods */

- (void)_prepareForExecutionInContext:(id)_ctx {
  /* TODO: does this intentionally not call super? */
}

- (void)_executeInContext:(id)_ctx {
  EOEntity       *entity;
  NSEnumerator   *enumerator  = nil;
  NSDictionary   *obj         = nil;
  NSArray        *keys;
  NSString       *primAttr;
  NSDictionary   *source;
  NSDictionary   *target      = nil;  
  EOEntity       *trgEntity; 
  EOEntity       *assEntity   = nil;
  NSArray        *assignments = nil;
  NSMutableSet   *trgIds      = nil;
  NSString       *trgPrimKey  = nil;
  NSString       *targetKey;
  NSMutableSet   *result      = nil;
  BOOL           isPerson;
  
  /* get entity */

  entity   = _getEntityNamed(self->entityName);
  primAttr = [(EOAttribute *)[[entity primaryKeyAttributes] lastObject] name];
  keys     = self->searchKeys; /* those are the company-ids */
  
  /* array contains all ids for entity */

  source = [self fetchRequiredAttributesForKeys:keys entity:entity
                keyAttribute:[[entity primaryKeyAttributes] lastObject]
                context:_ctx];

  /*
    'source' dict contains all attributes (attributes and extended attributes)
    keyed by primary key
  */
  
  if ([[entity name] isEqualToString:@"Person"]) {
    isPerson  = YES;
    targetKey =  @"toEnterprise";
    trgEntity = _getEntityNamed(@"Enterprise");
  }
  else {
    isPerson  = NO;
    targetKey = @"toPerson";
    trgEntity = _getEntityNamed(@"Person");
  }
  
  assEntity = _getEntityNamed(@"CompanyAssignment");

  if (isPerson) {
    assignments = [self fetchManyToManyRelationWithSource:entity
                        keys:keys
                        target:trgEntity
                        assignment:assEntity
                        sourceKeyAttr:
			  [assEntity attributeNamed:@"subCompanyId"]
                        targetKeyAttr:
			  [assEntity attributeNamed:@"companyId"]
                        context:_ctx];
  }
  else {
    assignments = [self fetchManyToManyRelationWithSource:entity
                        keys:keys
                        target:trgEntity
                        assignment:assEntity
                        sourceKeyAttr:
			  [assEntity attributeNamed:@"companyId"]
                        targetKeyAttr:
			  [assEntity attributeNamed:@"subCompanyId"]
                        context:_ctx];
  }
  
  trgPrimKey = 
    [(EOAttribute *)[[trgEntity primaryKeyAttributes] lastObject] name];
  
  // TODO: cleanup
  if ([trgPrimKey isEqualToString:
		    [(EOAttribute *)[[entity primaryKeyAttributes] 
				      lastObject] name]]) {
    trgPrimKey = [trgPrimKey stringByAppendingString:@"2"];
  }
  
  trgIds = [[NSMutableSet alloc] initWithCapacity:[assignments count]];
  
  enumerator = [assignments objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil)
    [trgIds addObject:[obj objectForKey:trgPrimKey]];

  
  /* here we seem to fetch the attributes of the target relationship */
  
  target = [self fetchRequiredAttributesForKeys:[trgIds allObjects]
                 entity:trgEntity
                 keyAttribute:[[trgEntity primaryKeyAttributes] lastObject]
                 context:_ctx];
  [trgIds release]; trgIds = nil;

  
  /* create result set. Not sure why this is a set. Apparently 'result' is an
     array of dictionaries containing one dict per object.
     Possibly we used it instead of a DISTINCT fetch? */
  
  result = [[NSMutableSet alloc] 
	     initWithCapacity:([source count] + [assignments count])];
  

  // TODO: whats happening next?
  {
    NSMutableDictionary *dict;
    id assignment;
    
    dict = [source mutableCopy]; // the 'source' dict is kept the same
    
    enumerator = [assignments objectEnumerator];
    while ((assignment = [enumerator nextObject]) != nil)
      [dict removeObjectForKey:[assignment objectForKey:primAttr]];
    
    /* here we add an array to the result *set* */
    [result addObjectsFromArray:[dict allValues]];
    [dict release]; dict = nil;
  }
  // Note: in a test 'result' still contained no objects here
  

  // TODO: whats happening next?
  
  {
    NSEnumerator *enumerator;
    id assignment;
    
    enumerator = [assignments objectEnumerator];
    while ((assignment = [enumerator nextObject]) != nil) {
      NSMutableDictionary *sourceTmp;
      
      /* I think primAttr is always 'companyId'. 'sourceTmp' will contain
	 one record */
      sourceTmp = [source objectForKey:[assignment objectForKey:primAttr]];
      
      /* targetKey is either 'toPerson' or 'toEnterprise' */
      if ([sourceTmp objectForKey:targetKey] == nil) {
	/* we have no cached relationship/fault */
	NSDictionary *t;
	
	/* 'target' is a dict containing the enterprise/person ID with the
	   associated record dictionary.
	   't' will contain the dict.
	*/
	t = [target objectForKey:[assignment objectForKey:trgPrimKey]];
	if (t != nil) {
	  /* patch the source to include the relationship */
	  // TODO: should we copy prior patching?
	  [sourceTmp setObject:t forKey:targetKey];
	  if (isPerson) {
	    [sourceTmp setObject:[t objectForKey:@"toAddress"]
		       forKey:@"toAddress"];
	  }
	}
	
	[result addObject:sourceTmp];
      }
      else {
	NSMutableDictionary *tmp;
	NSDictionary        *t;
      
	// TODO: why the mutableCopy?
	tmp = [sourceTmp mutableCopy];
	
	t   = [target objectForKey:[assignment objectForKey:trgPrimKey]];
	if (t != nil) {
	  [tmp setObject:t forKey:targetKey];
	  if (isPerson)
	    [tmp setObject:[t objectForKey:@"toAddress"] forKey:@"toAddress"];
	}
	
	[result addObject:tmp];
	[tmp release]; tmp = nil;
      }
    }
  }
  
  /* convert the result *set* into an array and return it */
  [self setReturnValue:[result allObjects]];
  [result release]; result = nil;
}

- (NSArray *)attributesForEntity:(EOEntity *)_entity inContext:(id)_ctx {
  NSEnumerator *attrNames;
  NSMutableSet *attributes;
  NSArray      *result;
  id           obj;

  NSAssert(_entity != nil, @"_entity is nil");

  attrNames = [[[[_ctx userDefaults]
                       dictionaryForKey:@"RequiredAttributes"]
                       objectForKey:[_entity name]]
                       objectEnumerator];
  if (attrNames == nil)
    return nil;
  
  attributes = [[NSMutableSet alloc] initWithCapacity:32];
  
  while ((obj = [attrNames nextObject]) != nil) {
    id attr;
    
    if ((attr = [_entity attributeNamed:obj]) != nil)
      [attributes addObject:attr];
  }
  [attributes addObjectsFromArray:[_entity primaryKeyAttributes]];
  result = [attributes allObjects];
  [attributes release]; attributes = nil;
  return result;
}

- (NSArray *)extendedAttrsForEntity:(EOEntity *)_entity inContext:(id)_ctx {
  NSEnumerator *attrNames;
  NSMutableSet *attributes;
  NSArray      *result;
  id           obj;
  
  // TODO: is this really a context-specific default?!
  attributes    = [[NSMutableSet alloc] initWithCapacity:32];
  attrNames     = [[[[_ctx userDefaults]
                           dictionaryForKey:@"RequiredAttributes"]
                           objectForKey:[_entity name]]
                           objectEnumerator];
  while ((obj = [attrNames nextObject]) != nil) {
    id attr;
    
    if ((attr = [_entity attributeNamed:obj]) == nil)
      [attributes addObject:obj];
  }
  result = [attributes allObjects];
  [attributes release]; attributes = nil;
  return result;
}


- (NSDictionary *)fetchRequiredAttributesForKeys:(NSArray *)_pkeys
  entity:(EOEntity *)_entity keyAttribute:(EOAttribute *)_keyAttr
  context:(LSCommandContext *)_ctx 
{
  /* Remember: 'keys' are the companyId's (primary keys)! */
  NSArray             *values;
  NSMutableDictionary *result;
  NSString            *primAttr;
  NSEnumerator        *enumerator;
  NSMutableDictionary *obj        = nil;
  NSString            *addrKind   = nil;
  BOOL                isPerson;
  NSArray             *allKeys;
  
  isPerson = [[_entity name] isEqualToString:@"Person"];
  
  /* Required attributes */
  values = [self fetchAttributes:
                   [self attributesForEntity:_entity inContext:_ctx]
                 keys:_pkeys
                 entity:_entity keyAttribute:_keyAttr context:_ctx];
  primAttr = [(EOAttribute *)[[_entity primaryKeyAttributes] lastObject] name];
  result   = [NSMutableDictionary dictionaryWithCapacity:[values count]];
  
  /* build results dictionary, key is the company_id, value is a mutabledict */

  enumerator = [values objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    NSMutableDictionary *md;
    
    md = [obj mutableCopy]; // make it mutable
    [result setObject:md forKey:[md objectForKey:primAttr]];

    if (isPerson) {
      // TODO: localization! what is this?
      if ([md valueForKey:@"sex"] == nil)
        [md setObject:@"" forKey:@"gender"];
      else if ([[md valueForKey:@"sex"] isEqualToString:@"male"])
        [md setObject:@"Herr" forKey:@"gender"];
      else
        [md setObject:@"Frau" forKey:@"gender"];
    }
    [md release]; md = nil;
  }

  /* extended attributes */
  
  values = [self fetchExtendedAttrs:
                   [self extendedAttrsForEntity:_entity inContext:_ctx]
                 keys:_pkeys
                 context:_ctx];
  
  enumerator = [values objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSMutableDictionary *record;
    
    record = [result objectForKey:[obj objectForKey:@"companyId"]];
    [record setObject:[obj objectForKey:@"value"]
            forKey:[obj objectForKey:@"attribute"]];
  }


  allKeys = [result allKeys];
    
  /* addresses */
  
  if ([[_entity name] isEqualToString:@"Enterprise"])
    addrKind = @"bill";
  else if ([[_entity name] isEqualToString:@"Person"])
    addrKind = @"mailing";
    
  if (addrKind != nil) {
    NSArray  *addrKinds;
    unsigned i;

    addrKinds = [[[_ctx userDefaults]
                        dictionaryForKey:@"LSAddressType"]
		        objectForKey:[_entity name]];
    if (![addrKinds isNotEmpty])
      addrKinds = [NSArray arrayWithObject:addrKind];

    for (i = 0; i < [addrKinds count]; i++) {
      NSEnumerator *enumerator;
      NSArray  *values;
      NSString *currentAddrKind;
      id       obj;
      
      currentAddrKind = [addrKinds objectAtIndex:i];
      values = [self fetchAddressesForKeys:allKeys 
		     kind:currentAddrKind
		     context:_ctx];
      
      enumerator = [values objectEnumerator];
      while ((obj = [enumerator nextObject]) != nil) {
	NSMutableDictionary *record;
	
	/* find primary person/enterprise record for given address */
	record = [result objectForKey:[obj objectForKey:@"companyId"]];
	
	/* store address under kind (eg 'bill') */
	[record setObject:obj forKey:currentAddrKind];

	/* store primary address as 'toAddress' */
	if ([currentAddrKind isEqualToString:addrKind])
	  [record setObject:obj forKey:@"toAddress"];
      }
    }
  }

  /* telephone */

  values      = [self fetchTelephonesForKeys:allKeys entity:_entity
		      context:_ctx];
  enumerator  = [values objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSMutableDictionary *record;
    NSString *key;

    record = [result objectForKey:[obj objectForKey:@"companyId"]];
    key    = [phoneCodeToNameMap objectForKey:[obj objectForKey:@"type"]];

    /* here we store under a key like 'tel1', 'fax' */
    if (key != nil)
      [record setObject:obj  forKey:key];
    
    /* and the same info again under the type, eg '01_tel', '10_fax' */
    [record setObject:obj forKey:[obj objectForKey:@"type"]];
  }
    
  /* fetch comments */
    
  values      = [self fetchCommentsForKeys:allKeys entity:_entity
		      context:_ctx];
  enumerator  = [values objectEnumerator];
  while ((obj = [enumerator nextObject])) {
      NSMutableDictionary *record;
      
      record = [result objectForKey:[obj objectForKey:@"companyId"]];
      [record setObject:obj forKey:@"toComment"];
  }
    
  /* fetch logs */
    
  values      = [self fetchLogForKeys:allKeys entity:_entity
		      context:_ctx];
  enumerator  = [values objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSMutableDictionary *record;
      
    record = [result objectForKey:[obj objectForKey:@"companyId"]];
    [record setObject:obj forKey:@"toLog"];
  }
    
  /* fetch owner */
  {
    NSArray *ownerIds;

    ownerIds = [[result allValues] valueForKey:@"ownerId"];
    
    if ([ownerIds isNotEmpty] && ![ownerIds containsObject:[EONull null]]) {
      NSMutableDictionary *ownDict;
        
      ownDict = [NSMutableDictionary dictionaryWithCapacity:16];
      values      = [self fetchOwnerForKeys:ownerIds entity:_entity
			  context:_ctx];
      enumerator = [values objectEnumerator];
      while ((obj = [enumerator nextObject]))
	[ownDict setObject:obj forKey:[obj valueForKey:@"companyId"]];
        
      enumerator  = [result objectEnumerator];
      while ((obj = [enumerator nextObject])) {
	id own = [ownDict valueForKey:[obj valueForKey:@"ownerId"]];

	if ([own isNotNull])
	  [obj setObject:own forKey:@"toOwner"];
      }
    }
  }
  return [[result copy] autorelease];
}

- (NSArray *)fetchTelephonesForKeys:(NSArray *)_keys entity:(EOEntity *)_entity
  context:(LSCommandContext *)_ctx
{
  NSArray         *result    = nil;
  EOEntity        *entity;
  EOSQLQualifier  *qualifier = nil;
  NSArray         *types;
  NSMutableString *str       = nil;

  entity = _getEntityNamed(@"Telephone");
  types  = [[[_ctx valueForKey:LSUserDefaultsKey] valueForKey:@"LSTeleType"]
                   valueForKey:[_entity name]];

  {
    NSEnumerator *enumerator;
    id           obj         = nil;
    BOOL         isFirst     = YES;
    NSString     *type;

    type       = [[entity attributeNamed:@"type"] columnName];
    enumerator = [types objectEnumerator];
    str        = [[NSMutableString alloc] initWithCapacity:128];
    
    while ((obj = [enumerator nextObject]) != nil) {
      if (isFirst)
        isFirst = NO;
      else
        [str appendString:@"OR "];
      
      [str appendString:@"( "];
      [str appendString:type];
      [str appendString:@" = '"];
      [str appendString:obj];
      [str appendString:@"' )"];
    }
  }
  
  qualifier = [[EOSQLQualifier allocWithZone:[self zone]]
                               initWithEntity:entity
                               qualifierFormat:@"((%@) AND (%A IS NOT NULL))",
                               str, @"number", nil];
  [str release]; str = nil;
  result = [self fetchValuesWithAttributes:
                 [[self attributesForEntity:entity inContext:_ctx]
                        arrayByAddingObject:
		          [entity attributeNamed:@"companyId"]]
                 entity:entity keys:_keys
                 keyAttribute:[entity attributeNamed:@"companyId"]
                 qualifier:qualifier context:_ctx];
  [qualifier release]; qualifier = nil;
  return result;
}

- (NSArray *)fetchCommentsForKeys:(NSArray *)_keys entity:(EOEntity *)_entity
  context:(LSCommandContext *)_ctx
{
  NSArray  *result = nil;
  EOEntity *entity = _getEntityNamed(@"CompanyInfo");
  NSArray  *attrs  = nil;

  attrs  = [self attributesForEntity:entity inContext:_ctx];

  if (attrs == nil)
    return nil;
  
  result = [self fetchValuesWithAttributes:
                 [attrs arrayByAddingObject:
                        [entity attributeNamed:@"companyId"]]
                 entity:entity keys:_keys
                 keyAttribute:[entity attributeNamed:@"companyId"]
                 qualifier:nil context:_ctx];
  return result;
}

- (NSArray *)fetchLogForKeys:(NSArray *)_keys entity:(EOEntity *)_entity
  context:(LSCommandContext *)_ctx
{
  NSArray         *result    = nil;
  EOEntity        *entity    = _getEntityNamed(@"Log");
  NSArray         *attrs     = nil;
  EOSQLQualifier  *qualifier = nil;

  attrs = [self attributesForEntity:entity inContext:_ctx];

  if (attrs == nil)
    return nil;

  qualifier = [[EOSQLQualifier allocWithZone:[self zone]]
                               initWithEntity:entity
                               qualifierFormat:@"%A like '00_%%'",
                                 @"action", nil];
  
  result = [self fetchValuesWithAttributes:
                 [attrs arrayByAddingObject:
                        [entity attributeNamed:@"objectId"]]
                 entity:entity keys:_keys
                 keyAttribute:[entity attributeNamed:@"objectId"]
                 qualifier:qualifier context:_ctx];
  RELEASE(qualifier); qualifier = nil;
  return result;
}

- (NSArray *)fetchOwnerForKeys:(NSArray *)_keys entity:(EOEntity *)_entity
  context:(LSCommandContext *)_ctx
{
  NSArray  *result;
  EOEntity *entity;
  NSArray  *attrs;

  entity    = _getEntityNamed(@"Staff");
  attrs  = [self attributesForEntity:entity inContext:_ctx];

  if (attrs == nil)
    return nil;
  
  result = [self fetchValuesWithAttributes:
		   [attrs arrayByAddingObject:
			    [entity attributeNamed:@"companyId"]]
                 entity:entity keys:_keys
                 keyAttribute:[entity attributeNamed:@"companyId"]
                 qualifier:nil context:_ctx];
  return result;
}


- (NSArray *)fetchAddressesForKeys:(NSArray *)_keys kind:(NSString *)_kind
  context:(LSCommandContext *)_ctx
{
  NSArray        *result    = nil;
  EOEntity       *entity;
  EOSQLQualifier *qualifier;
  NSArray        *attrs;
  
  entity = _getEntityNamed(@"Address");
  
  qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
				      qualifierFormat:@"%A='%@'",
				        @"type", _kind, nil];
  attrs  = [[self attributesForEntity:entity inContext:_ctx]
	          arrayByAddingObject:[entity attributeNamed:@"companyId"]];
  result = [self fetchValuesWithAttributes:attrs
                 entity:entity keys:_keys
                 keyAttribute:[entity attributeNamed:@"companyId"]
                 qualifier:qualifier context:_ctx];
  [qualifier release]; qualifier = nil;
  return result;
}

- (NSArray *)fetchAttributes:(NSArray *)_attrs keys:(id)_keys
  entity:(id)_entity keyAttribute:(EOAttribute *)_keyAttr
  context:(LSCommandContext *)_ctx 
{
  return [self fetchValuesWithAttributes:_attrs entity:_entity
               keys:_keys keyAttribute:_keyAttr qualifier:nil context:_ctx];
}

- (NSArray *)fetchExtendedAttrs:(NSArray *)_extAttrs keys:(NSArray *)_keys
  context:(LSCommandContext *)_ctx
{
  NSArray         *attrs      = nil;
  NSArray         *result     = nil;  
  EOEntity        *entity     = _getEntityNamed(@"CompanyValue");
  EOSQLQualifier  *qualifier  = nil;
  NSMutableString *format     = nil;
  NSEnumerator    *enumerator = nil;  
  id              obj         = nil;
  BOOL            isFirst     = YES;

  if (![_extAttrs isNotEmpty])
    return nil;
  
  /* get CompanyValue Attribute */
  
  /* get the necessary attributes */

  attrs = [NSArray arrayWithObjects:
                   [entity attributeNamed:@"value"],
                   [entity attributeNamed:@"attribute"],
                   [entity attributeNamed:@"companyId"], nil];

  /* build the attributes IN select expression */
  
  format = [[NSMutableString alloc] initWithCapacity:512];
  [format appendString:@"%A IN ("];
  enumerator = [_extAttrs objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    if (isFirst)
      isFirst = NO;
    else
      [format appendString:@", "];
    
    [format appendString:@"'"];
    [format appendString:[obj stringValue]];
    [format appendString:@"'"];
  }
  [format appendString:@")"];

  /* build the qualifier */
  
  qualifier = [[EOSQLQualifier alloc]
                               initWithEntity:entity
                               qualifierFormat:format, @"attribute", nil];
  RELEASE(format); format = nil;
  
  result = [self fetchValuesWithAttributes:attrs entity:entity keys:_keys
                 keyAttribute:[entity attributeNamed:@"companyId"]
                 qualifier:qualifier context:_ctx];
  RELEASE(qualifier); qualifier = nil;
  return result;
}

- (NSArray *)fetchManyToManyRelationWithSource:(EOEntity *)_src
  keys:(NSArray *)_keys
  target:(EOEntity *)_target
  assignment:(EOEntity *)_assignment
  sourceKeyAttr:(EOAttribute *)_srcAttr
  targetKeyAttr:(EOAttribute *)_trgAttr
  context:(LSCommandContext *)_ctx
{
  // TODO: cleanup
  NSMutableString  *qualifier   = nil;
  NSEnumerator     *enumerator  = nil;
  BOOL             isFirst      = YES;
  EOAttribute      *srcPrimAttr = nil;
  EOAttribute      *trgPrimAttr = nil;
  NSMutableArray   *result      = nil;
  EOAdaptorChannel *channel     = nil;
  int cnt = 0;
  int pos = 0;

  if (![_keys isNotEmpty])
    return nil;
  
  channel     = [[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
  result      = [[NSMutableArray alloc] initWithCapacity:512];
  srcPrimAttr = [[_src primaryKeyAttributes] lastObject];
  trgPrimAttr = [[_target primaryKeyAttributes] lastObject];  
  
  qualifier = [[NSMutableString alloc]
                                initWithCapacity:256];
  [qualifier appendString:@"SELECT "];
  [qualifier appendString:@"t1."];
  [qualifier appendString:[srcPrimAttr columnName]];
  [qualifier appendString:@", t2."];            
  [qualifier appendString:[trgPrimAttr columnName]];
  [qualifier appendString:@" FROM "];
  [qualifier appendString:[_src externalName]];
  [qualifier appendString:@" t1, "];
  [qualifier appendString:[_target externalName]];
  [qualifier appendString:@" t2, "];
  [qualifier appendString:[_assignment externalName]];
  [qualifier appendString:@" t3 where "];
  [qualifier appendString:@"((t1."];
  [qualifier appendString:[srcPrimAttr columnName]];
  [qualifier appendString:@" IN (%@)) AND (t3."];
  [qualifier appendString:[_srcAttr columnName]];
  [qualifier appendString:@" = t1."];
  [qualifier appendString:[srcPrimAttr columnName]];
  [qualifier appendString:@") AND (t3."];
  [qualifier appendString:[_trgAttr columnName]];
  [qualifier appendString:@" = t2."];
  [qualifier appendString:[trgPrimAttr columnName]];
  [qualifier appendString:@"))"];
  
  cnt = [_keys count];
  pos = 0;

  if (cnt > 0) {
    do {
      int             lastPos  = 0;
      NSArray         *array   = nil;
      NSMutableString *format  = nil;
      NSString        *qual    = nil;
      id              key      = nil;
      id              fetchRes = nil;
      
      lastPos = pos;
      pos     += 200;

      if (pos >= cnt) 
        pos = cnt;

      /* get ranges */
      array = [_keys subarrayWithRange:NSMakeRange(lastPos, pos - lastPos)];
      /* build IN - Qualifier with ranges */
      format     = [[NSMutableString alloc] initWithCapacity:512];
      enumerator = [array objectEnumerator];

      isFirst = YES;
      while ((key = [enumerator nextObject])) {
        if (isFirst)
          isFirst = NO;
        else
          [format appendString:@", "];
        [format appendString:[key stringValue]];
      }

      qual = [[NSString alloc] initWithFormat:qualifier, format];
      RELEASE(format); format = nil;
      [channel evaluateExpression:qual];
      while ((fetchRes = [channel fetchAttributes:[channel describeResults]
                                  withZone:NULL])) {
        [result addObject:fetchRes];
      }
      RELEASE(qual); qual = nil;
    } while (pos != cnt);
  }
  [qualifier release]; qualifier = nil;
  return [result autorelease];
}

- (NSArray *)fetchValuesWithAttributes:(NSArray *)_attrs
  entity:(EOEntity *)_entity keys:(NSArray *)_keys
  keyAttribute:(EOAttribute *)_keyAttr qualifier:(EOSQLQualifier *)_qualifier
  context:(id)_ctx
{
  // TODO: cleanup
  NSMutableArray   *result  = nil;
  EOAdaptorChannel *channel = nil;
  int cnt = 0;
  int pos = 0;
  
  result  = [NSMutableArray arrayWithCapacity:512];
  channel = [[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
  cnt     = [_keys count];
  pos     = 0;

  if (cnt == 0)
    return result;
  
  do {
    int             lastPos     = 0;
    NSArray         *array      = nil;
    EOSQLQualifier  *qualifier  = nil;
    id              fetchRes    = nil;
    NSMutableString *format     = nil;
    NSEnumerator    *enumerator = nil;
    id              key         = nil;
    BOOL            isFirst     = YES;

    lastPos  = pos;
    pos     += 200;

    if (pos >= cnt) 
      pos = cnt;

    /* get ranges */
    array      = [_keys subarrayWithRange:NSMakeRange(lastPos, pos - lastPos)];
    /* build IN - Qualifier with ranges */
    format     = [[NSMutableString alloc] initWithCapacity:512];
    enumerator = [array objectEnumerator];
      
    [format appendString:@"%A IN ("];
    while ((key = [enumerator nextObject])) {
      if (isFirst)
	isFirst = NO;
      else
	[format appendString:@", "];
      [format appendString:[key stringValue]];
    }
    [format appendString:@")"];

    qualifier = [[EOSQLQualifier alloc]
		  initWithEntity:_entity
		  qualifierFormat:format, 
		  [_keyAttr name], nil];
    [format release]; format = nil;

    /* conjoin with additive qualifier */
    
    if (_qualifier != nil)
      [qualifier conjoinWithQualifier:_qualifier];

    [channel selectAttributes:_attrs
	     describedByQualifier:qualifier
	     fetchOrder:nil lock:NO];
    
    while ((fetchRes = [channel fetchAttributes:_attrs withZone:NULL]))
      [result addObject:fetchRes];
      
    [qualifier release]; qualifier = nil;
  } while (pos != cnt);
  return result;
}

/* accessors */

- (void)setSearchKeys:(id)_id {
  ASSIGN(self->searchKeys, _id);
}
- (id)searchKeys {
  return self->searchKeys;
}

- (void)setEntityName:(NSString *)_id {
  ASSIGNCOPY(self->entityName, _id);
}
- (NSString *)entityName {
  return self->entityName;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"searchKeys"])
    [self setSearchKeys:_value];
  else if ([_key isEqualToString:@"entityName"])
    [self setEntityName:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"searchKeys"])
    return [self searchKeys];
  
  if ([_key isEqualToString:@"entityName"])
    return [self entityName];
  
  return [super valueForKey:_key];
}

@end /* LSAddressFetchAttributesCommand */

#undef _getEntityNamed
