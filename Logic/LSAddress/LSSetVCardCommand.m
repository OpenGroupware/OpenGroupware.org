/*
  Copyright (C) 2005 SKYRIX Software AG

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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  LSSetVCardCommand (company::set-vcard)
  
  NOTE: this requires SOPE 4.5 for the vCard parser!
  
  This commands parses and inserts a vCard into the contact database. You can
  (optionally) supply a gid to store the vCard under and an entity to be used
  for new vCards.
  If none of those is given the 'source_url' and heuristics are used to find
  a proper record - unless the 'sourceLookup' field is not set.
*/

@class NSString, EOKeyGlobalID, NSMutableDictionary;

@interface LSSetVCardCommand : LSDBObjectBaseCommand
{
  NSString      *vCard;
  id            vCardObject;
  EOKeyGlobalID *gid;
  NSString      *newEntityName;
  BOOL          sourceLookup;
  BOOL          createPrivate;
  
  /* transient */
  NSMutableDictionary *changeset;
}

- (void)setNewEntityName:(NSString *)_name;

@end

#include "common.h"

// we need to cheat a bit to support both, SOPE 4.4 and SOPE 4.5
@interface NSObject(NGVCard)
+ (NSArray *)parseVCardsFromSource:(id)_src;
@end

extern NSString *LSVUidPrefix;

@implementation LSSetVCardCommand

static NSString     *skyrixId         = nil;
static Class        NGVCardClass      = Nil;
static NSDictionary *personRevMapping = nil;
static NSDictionary *enterpriseRevMapping = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  skyrixId = [ud stringForKey:@"skyrix_id"];
  skyrixId = [[NSString alloc] initWithFormat:@"skyrix://%@/%@/",
			         [[NSHost currentHost] name], skyrixId];
  
  if ((NGVCardClass = NSClassFromString(@"NGVCard")) == Nil)
    NSLog(@"Note: NGVCard class not available, vCard parsing not available.");
  
  personRevMapping = 
    [[ud dictionaryForKey:@"LSVCard_PersonAddressRevMapping"]  copy];
  enterpriseRevMapping = 
    [[ud dictionaryForKey:@"LSVCard_EnterpriseAddressRevMapping"]  copy];
}

- (void)dealloc {
  [self->changeset     release];
  [self->vCardObject   release];
  [self->vCard         release];
  [self->gid           release];
  [self->newEntityName release];
  [super dealloc];
}

/* identity handling */

- (EOKeyGlobalID *)globalIDForUID:(NSString *)_uid inContext:(id)_ctx {
  // TODO: search in source_url field for Prefix:uid and uid
  // Note: should prefer private items (owner_id == login_id)
  return nil;
}

- (EOKeyGlobalID *)globalIDFromURL:(NSString *)_url inContext:(id)_ctx {
  EOGlobalID *lgid;
  int pkey;
  
  if (![_url hasPrefix:@"skyrix://"])
    return nil;
  
  if (![_url hasPrefix:skyrixId]) {
    [self logWithFormat:@"record from different OGo installation: %@", _url];
    return nil;
  }
  
  pkey = [[_url lastPathComponent] intValue];
  lgid = [[_ctx typeManager] globalIDForPrimaryKey:
                              [NSNumber numberWithInt:pkey]];
  if (lgid == nil) {
    [self logWithFormat:@"did not find OGo id: %@", _url];
    return nil;
  }
  
  return (EOKeyGlobalID *)lgid;
}

- (EOKeyGlobalID *)globalIDForCard:(id)_card inContext:(id)_ctx {
  EOKeyGlobalID *lgid;
  NSString *tmp;
  
  if ([self->gid isNotNull])
    return self->gid;
  
  if (!self->sourceLookup)
    return nil;
  
  // TODO: check UID, check SOURCE in source_url field
  
  if ((tmp = [_card valueForKey:@"uid"]) != nil) {
    if ([tmp hasPrefix:@"skyrix://"]) {
      if ((lgid = [self globalIDFromURL:tmp inContext:_ctx]) != nil)
        return lgid;
    }
    else {
      if ([tmp hasPrefix:LSVUidPrefix])
	tmp =  [tmp substringFromIndex:[LSVUidPrefix length]];
      if ((lgid = [self globalIDForUID:tmp inContext:_ctx]) != nil)
	return lgid;
    }
  }
  
  if ((tmp = [_card valueForKey:@"source"]) != nil) {
    if ([tmp hasPrefix:@"skyrix://"]) {
      if ((lgid = [self globalIDFromURL:tmp inContext:_ctx]) != nil)
        return lgid;
    }
    else if ([tmp hasPrefix:LSVUidPrefix]) {
      NSString *uid;
      
      uid = [tmp substringFromIndex:[LSVUidPrefix length]];
      if ((lgid = [self globalIDForUID:uid inContext:_ctx]) != nil)
	return lgid;
    }
  }
  
  return nil;
}

/* changeset mapping */

- (void)mapValue:(id)_value to:(NSString *)_key {
  //[self logWithFormat:@"V: '%@': '%@'", _key, _value];
  
  /* we get vCard values which we need to map */
  if ([_value isKindOfClass:[NSArray class]]) {
    NSMutableString *ms;
    unsigned i, count;

    ms = nil;
    for (i = 0, count = [_value count]; i < count; i++) {
      /* Note: filters out null and empty values */
      id tmp;
      
      tmp = [_value objectAtIndex:i];
      if (![tmp isNotNull]) continue;
      tmp = [tmp stringValue];
      if ([tmp length] == 0) continue;
      
      if (ms == nil)
        ms = [NSMutableString stringWithCapacity:32];
      else
        [ms appendString:@","];
      [ms appendString:tmp];
    }
    _value = (ms != nil) ? ms : (id)[EONull null];
  }
  else if (![_value isNotNull]) {
    if (_value == nil) 
      _value = [EONull null];
  }
  else if (![_value isKindOfClass:[NSCalendarDate class]]) {
    _value = [_value stringValue];
  }
  
  [self->changeset setObject:(_value ? _value : [EONull null]) forKey:_key];
}

- (void)mapVKey:(NSString *)_rkey to:(NSString *)_lkey {
  [self mapValue:[self->vCardObject valueForKey:_rkey] to:_lkey];
}
- (void)mapVXKey:(NSString *)_rkey to:(NSString *)_lkey {
  NSDictionary *x;

  x = [self->vCardObject valueForKey:@"x"];
  [self mapValue:[x objectForKey:_rkey] to:_lkey];
}

- (NSCalendarDate *)dateForVCardValue:(id)_value {
  // we expect 2005-03-03
  NSCalendarDate *cd;
  NSString *s;
  
  if ([_value isKindOfClass:[NSDate class]])
    return _value;
  if (![_value isNotNull])
    return _value;
  
  s = [_value stringValue];
  if ([s length] < 10) {
    [self logWithFormat:@"ERROR: cannot process vCard date: '%@'", _value];
    return nil;
  }
  
  s = [s stringByAppendingString:@" 12:00:00"];
  cd = [NSCalendarDate dateWithString:s calendarFormat:@"%Y-%m-%d %H:%M:%S"];
  return cd;
}

/* main entity changeset */

- (void)appendIdentity:(id)_vc {
  NSString *tmp;
  
  if ((tmp = [_vc valueForKey:@"uid"]) != nil) {
    if ([tmp hasPrefix:LSVUidPrefix]) /* keep UID-prefix URLs as is */
      [self mapValue:tmp to:@"sourceUrl"];
    else if ([tmp hasPrefix:skyrixId]) /* native "source_url", remove */
      [self mapValue:[NSNull null] to:@"sourceUrl"];
    else if ([tmp rangeOfString:@"://"].length > 0) /* reuse URLs as-is */
      [self mapValue:tmp to:@"sourceUrl"];
    else {
      /* prefix non-URL UIDs */
      [self mapValue:[LSVUidPrefix stringByAppendingString:[tmp stringValue]] 
            to:@"sourceUrl"];
    }
  }
  else if ((tmp = [_vc valueForKey:@"source"]) != nil)
    [self mapValue:[tmp stringValue] to:@"sourceUrl"];
}

- (void)appendCommon:(id)_vc {
  // TODO: title
  // TODO: add support for Kontact keys
  NSDictionary *x;
  id tmp;
  
  [self mapVKey:@"categories"             to:@"keywords"];
  [self mapVKey:@"role"                   to:@"occupation"];
  [self mapVXKey:@"X-EVOLUTION-FILE-AS"   to:@"fileas"];
  [self mapVXKey:@"X-EVOLUTION-MANAGER"   to:@"bossName"];
  [self mapVXKey:@"X-EVOLUTION-SPOUSE"    to:@"partnerName"];
  [self mapVXKey:@"X-EVOLUTION-ASSISTANT" to:@"assistantName"];
  [self mapVKey:@"freeBusyURL"            to:@"freebusyUrl"];
  
  if ([(tmp = [_vc valueForKey:@"bday"]) isNotNull])
    [self mapValue:[self dateForVCardValue:tmp] to:@"birthday"];
  
  x = [_vc valueForKey:@"x"];
  
  if ([(tmp = [x valueForKey:@"X-EVOLUTION-ANNIVERSARY"]) isNotNull])
    [self mapValue:[self dateForVCardValue:tmp] to:@"anniversary"];
  
  /* Note: we can only map one IM field */
  // TODO: fix silent discard
  
  if ([(tmp = [x valueForKey:@"X-JABBER"]) isNotNull])
    [self mapValue:tmp to:@"imAddress"];
  else if ([(tmp = [x valueForKey:@"X-AIM"]) isNotNull])
    [self mapValue:tmp to:@"imAddress"];
  else if ([(tmp = [x valueForKey:@"X-ICQ"]) isNotNull])
    [self mapValue:tmp to:@"imAddress"];
  
  /* URL */
  
  tmp = [_vc valueForKey:@"url"];
  if ([tmp isNotNull] && [tmp count] > 1) {
    if ([tmp count] > 1) {
      // TODO: just add to note? => beware, might add up (check substring)
      [self logWithFormat:@"ERROR: can only store one URL, loosing others."];
    }
    [self mapValue:[[tmp objectAtIndex:0] stringValue] to:@"url"];
  }
  else
    [self mapValue:[EONull null] to:@"url"];
  
  /* some unsupported fields */
  
  if ([(tmp = [_vc valueForKey:@"calURI"]) isNotNull])
    [self logWithFormat:@"ERROR: loosing unsupported field: CALURI"];
}

- (void)appendOrg:(id)_vc {
  id org; // NGVCardOrg
  NSArray *units;
  id tmp;
  
  org   = [_vc valueForKey:@"org"]; // NGVCardOrg
  units = [org valueForKey:@"orgunits"];
  
  tmp = [units count] > 1 ? [units objectAtIndex:0] : nil;
  [self mapValue:tmp to:@"department"];
  
  tmp = [units count] > 2 ? [units objectAtIndex:1] : nil;
  [self mapValue:tmp to:@"office"];
}

- (void)appendNote:(id)_vc {
  // TODO: check whether this works
  [self mapValue:[_vc valueForKey:@"note"] to:@"comment"];
}

- (void)appendPhoto:(id)_vc {
  // TODO: append photo
  // 'pictureData' command arg key
}

// ext-attrs: 'companyValue' key in command (company-value sets)
//   [obj valueForKey:[extAttr valueForKey:@"attribute"]]

- (void)appendClassification:(id)_vc {
  // TODO: use sensitivity instead
  id tmp;
  
  if ((tmp = [[_vc valueForKey:@"vClass"] stringValue]) == nil)
    return;
  
  // TODO: first check permissions! (should be done by the set command?)
  
  tmp = [tmp stringValue];
  if ([tmp caseInsensitiveCompare:@"private"] == NSOrderedSame)
    [self->changeset 
	 setObject:[NSNumber numberWithBool:YES] forKey:@"isPrivate"];
  else if ([tmp caseInsensitiveCompare:@"public"] == NSOrderedSame)
    [self->changeset
	 setObject:[NSNumber numberWithBool:NO] forKey:@"isPrivate"];
  // also: confidential
}

- (void)appendPersonEMails:(NSArray *)_mails {
  [self logWithFormat:@"process person emails: %@", _mails];
}

- (void)appendGenericEMails:(NSArray *)_mails {
  [self logWithFormat:@"process generic emails: %@", _mails];
}

/* main generators */

- (NSMutableDictionary *)extractPersonChangeSetFromVCard:(id)_vc
  inContext:(id)_ctx
{
  NSMutableDictionary *cs;
  id n, org;
  
  self->changeset = [[NSMutableDictionary alloc] initWithCapacity:48];
  [self->changeset 
       setObject:[NSNumber numberWithBool:YES] forKey:@"isPerson"];
  
  [self appendIdentity:_vc];
  [self appendCommon:_vc];
  [self appendNote:_vc];
  [self appendPhoto:_vc];
  [self appendPersonEMails:[_vc valueForKey:@"email"]];
  // [self appendClassification:_vc toChangeSet:md];

  /* TODO: name handling */
  
  n = [_vc valueForKey:@"n"]; // NGVCardName
  [self mapValue:[n valueForKey:@"family"] to:@"name"];
  [self mapValue:[n valueForKey:@"given"]  to:@"firstName"];
  [self mapValue:[n valueForKey:@"suffix"] to:@"nameAffix"];
  [self mapValue:[n valueForKey:@"prefix"] to:@"nameTitle"];
  // TODO: other?
  
  [self mapVKey:@"nickname" to:@"description"];
  
  org = [_vc valueForKey:@"org"]; // NGVCardOrg
  [self mapValue:[org valueForKey:@"orgname"] to:@"associatedCompany"];
  [self appendOrg:_vc];
  
  /* finish up */
  cs = [self->changeset count] > 0 ? self->changeset : nil;
  [self->changeset autorelease]; self->changeset = nil;
  return cs;
}

- (NSMutableDictionary *)extractEnterpriseChangeSetFromVCard:(id)_vc
  inContext:(id)_c
{
  NSMutableDictionary *cs;
  id n, org, tmp;
  
  self->changeset = [[NSMutableDictionary alloc] initWithCapacity:48];
  [self->changeset 
       setObject:[NSNumber numberWithBool:YES] forKey:@"isEnterprise"];
  
  [self appendIdentity:_vc];
  [self appendCommon:_vc];
  [self appendNote:_vc];
  [self appendPhoto:_vc];
  [self appendGenericEMails:[_vc valueForKey:@"email"]];
  // [self appendClassification:_vc toChangeSet:md];
  
  /* name handling */
  
  n   = [_vc valueForKey:@"n"]; // NGVCardName
  org = [_vc valueForKey:@"org"]; // NGVCardOrg
  if ([(tmp = [org valueForKey:@"orgnam"]) isNotNull])
    [self mapValue:tmp to:@"description"];
  else if ([(tmp = [org valueForKey:@"family"]) isNotNull])
    [self mapValue:tmp to:@"description"];
  
  [self appendOrg:_vc];
  
  /* finish up */
  cs = [self->changeset count] > 0 ? self->changeset : nil;
  [self->changeset autorelease]; self->changeset = nil;
  return cs;
}

/* prepare */

- (void)_prepareForExecutionInContext:(id)_context {
  [self assert:([self->vCard isNotNull] || [self->vCardObject isNotNull])
	reason:@"missing either vCard or vCardObject parameter!"];
  if ([self->vCard isNotNull])
    [self assert:([self->vCard length] > 0) reason:@"vCard has no content!"];
}

/* running the command */

// TODO: label, email, adr, tel

- (NSString *)findPrimaryTypeInArray:(NSArray *)_types {
  if (![_types isNotNull] || [_types count] == 0) /* no types => no primary */
    return nil;
  
  if ([_types count] == 1)
    return [_types lastObject];
  
  if ([_types count] == 2) {
    if ([[_types objectAtIndex:0] isEqualToString:@"PREF"])
      return [_types objectAtIndex:1];
    if ([[_types objectAtIndex:1] isEqualToString:@"PREF"])
      return [_types objectAtIndex:0];
  }
  
  /* more than one type => no primary */
  return nil;
}

- (void)_processVCardAddress:(id)_vadr mappedToType:(NSString *)_type
  intoContact:(id)_contact inContext:(id)_context
{
  NSMutableDictionary *lChangeSet;
  NSString *tmp;
  id addressEO;
  
  [self debugWithFormat:@"save under type %@: %@", _type, _vadr];
  
  /* fetch EO object to set the new values */
  
  // TODO: this performs a case insensitive match on the type.
  addressEO = [_context runCommand:@"address::get",
                        @"operator",   @"AND",
                        @"comparator", @"EQUAL",
                        @"type",       _type,
                        @"companyId",  [_contact valueForKey:@"companyId"],
                        nil];
  if ([addressEO isKindOfClass:[NSArray class]])
    addressEO = ([addressEO count] > 0) ? [addressEO objectAtIndex:0] : nil;

  /* make changeset */
  
  lChangeSet = [NSMutableDictionary dictionaryWithCapacity:8];
  [lChangeSet takeValue:[NSNumber numberWithBool:NO] forKey:@"shouldLog"];

  [lChangeSet takeValue:[_vadr valueForKey:@"street"]   forKey:@"street"];
  [lChangeSet takeValue:[_vadr valueForKey:@"locality"] forKey:@"city"];
  [lChangeSet takeValue:[_vadr valueForKey:@"region"]   forKey:@"state"];
  [lChangeSet takeValue:[_vadr valueForKey:@"pcode"]    forKey:@"zip"];
  [lChangeSet takeValue:[_vadr valueForKey:@"country"]  forKey:@"country"];
  
  // TODO: add fields for the two in the DB (OGo 1.1)
  if ([(tmp = [_vadr valueForKey:@"pobox"]) isNotNull]) {
    tmp = [@"pobox:" stringByAppendingString:tmp];
    [lChangeSet takeValue:tmp forKey:@"name2"];
  }
  if ([(tmp = [_vadr valueForKey:@"extadd"]) isNotNull]) {
    tmp = [@"extadd:" stringByAppendingString:tmp];
    [lChangeSet takeValue:tmp forKey:@"name3"];
  }
  
  /* check whether the address type already exists */
  
  if (![addressEO isNotNull]) {
    [lChangeSet takeValue:[_contact valueForKey:@"companyId"]
                forKey:@"companyId"];
    [lChangeSet takeValue:_type forKey:@"type"];
    //[lChangeSet setObject:@"vCard address import" forKey:@"logText"];
    addressEO = [_context runCommand:@"address::new" arguments:lChangeSet];
  }
  else {
    [lChangeSet takeValue:[addressEO valueForKey:@"addressId"]
                forKey:@"addressId"];
    //[lChangeSet setObject:@"vCard address update" forKey:@"logText"];
    addressEO = [_context runCommand:@"address::set" arguments:lChangeSet];
  }
}

- (NSString *)mapTypes:(NSArray *)atypes usingMapping:(NSDictionary *)mapping
  andUniquer:(NSMutableSet *)usedTypes
{
  NSString *primaryType, *mappedType;
  NSString *vct;
  short i;
  
  if ((primaryType = [self findPrimaryTypeInArray:atypes]) != nil) {
    if ((mappedType = [mapping valueForKey:primaryType]) != nil) {
      /* check for multiple addresses of the same type (forbidden in OGo) */
      if (![usedTypes containsObject:mappedType])
        return mappedType;
      
      /* already used (eg two 'work' addresses) */
    }
  }
    
  /* create custom types */
    
  // normalize
  vct = [[atypes sortedArrayUsingSelector:@selector(compare:)]
                 componentsJoinedByString:@","];
  vct = [vct uppercaseString];
  
  if ([vct length] == 0) vct = @"untyped";
      
  mappedType = [@"V:" stringByAppendingString:vct];
  if (![usedTypes containsObject:mappedType])
    /* first custom type of this vtype */
    return mappedType;
  
  /* ok, this type was already added, need a sequence ... */
        
  mappedType = nil;
  for (i = 1; i < 10 && mappedType == nil; i++) {
          mappedType = [@"V:" stringByAppendingFormat:@"%i%@", i, vct];
          if ([usedTypes containsObject:mappedType])
            mappedType = nil;
  }
  return mappedType;
}

- (void)_processAddressesFromVCard:(id)_vcard intoContact:(id)_contact
  inContext:(id)_context
{
  /*
    Note: we do not try to be smart about typeless addresses in combination
          with unused addresses in OGo. We always treat such as custom addrs.
  */
  NSMutableSet *usedTypes;
  NSEnumerator *adrs;
  NSDictionary *mapping;
  NSString     *k;
  id adr; // really: NGVCardAddress object

  if (![_contact isNotNull]) {
    [self logWithFormat:@"ERROR(%s): got no contact!", __PRETTY_FUNCTION__];
    return;
  }

  /* find type mapping table */
  
  k = [[_contact valueForKey:@"globalID"] entityName];
  if ([k isEqualToString:@"Person"])
    mapping = personRevMapping;
  else if ([k isEqualToString:@"Enterprise"])
    mapping = enterpriseRevMapping;
  else {
    [self logWithFormat:@"Note: not processing vCard ADR's for %@ objects.",k];
    return;
  }
  
  /* walk over all addresses and map */
  
  usedTypes = [NSMutableSet setWithCapacity:8];
  
  adrs = [[_vcard valueForKey:@"adr"] objectEnumerator];
  while ((adr = [adrs nextObject]) != nil) {
    NSArray  *atypes;
    NSString *mappedType;
    
    atypes     = [adr valueForKey:@"types"];
    mappedType = [self mapTypes:atypes 
                       usingMapping:mapping andUniquer:usedTypes];
    if (mappedType == nil) {
      [self logWithFormat:
              @"Note: did not store ADR, all slots are filled: %@", atypes];
      continue;
    }
    
    /* process */
    
    [self _processVCardAddress:adr mappedToType:mappedType
          intoContact:_contact inContext:_context];
    
    /* mark type as consumed */
    if (mappedType != nil)
      [usedTypes addObject:mappedType];
  }
}

- (void)_executeInContext:(id)_context {
  EOKeyGlobalID *lgid;
  NSMutableDictionary  *lChangeSet = nil;
  NSString      *cn;
  id eo;
  
  /* parse vCard object */
  
  if (self->vCardObject == nil) {
    NSArray *a;
    
    [self assert:(NGVCardClass != Nil) reason:@"vCard parsing not available."];
    
    a = [NGVCardClass parseVCardsFromSource:self->vCard];
    [self assert:([a count] < 2)
	  reason:@"More than one vCard in submitted vCard entity!"];
    [self assert:([a count] > 0)
	  reason:@"No vCard in submitted vCard entity!"];
    
    self->vCardObject = [[a objectAtIndex:0] retain];
  }
  
  /* check whether card exists and fetch EO if it does */
  
  if ((lgid = [self globalIDForCard:self->vCardObject inContext:_context])) {
    ASSIGN(self->gid, lgid);
    [self logWithFormat:@"write to GID: %@", lgid];
    
    eo = [_context runCommand:@"object::get-by-globalid",
		   @"gid", self->gid, nil];
    [self setNewEntityName:[lgid entityName]];
    
    if ([eo isKindOfClass:[NSArray class]])
      eo = [eo count] > 0 ? [eo lastObject] : nil;
  }
  else {
    [self logWithFormat:@"import new vCard .."];
    eo = nil;
    
    if (![self->newEntityName isNotNull]) // default to persons
      self->newEntityName = @"Person";
  }
  
  /* determine changeset */

  if ([self->newEntityName isEqualToString:@"Enterprise"]) {
    lChangeSet = [self extractEnterpriseChangeSetFromVCard:self->vCardObject
		       inContext:_context];
  }
  else if ([self->newEntityName isEqualToString:@"Person"]) {
    lChangeSet = [self extractPersonChangeSetFromVCard:self->vCardObject
		       inContext:_context];
  }
  else {
    [self logWithFormat:@"unsupported company type: %@", self->newEntityName];
  }
  
  [self assert:(lChangeSet != nil) reason:@"got no master changeset!"];
  [self debugWithFormat:@"lChangeSet: %@", lChangeSet];
  
  /* apply main change */
  
  if (![[changeset valueForKey:@"isPrivate"] isNotNull]) {
    [lChangeSet setObject:[NSNumber numberWithBool:self->createPrivate]
	       forKey:@"isPrivate"];
  }

  cn = [self->newEntityName lowercaseString];
  
  if (eo == nil) {
    cn = [cn stringByAppendingString:@"::new"];
    [lChangeSet setObject:@"vCard import" forKey:@"logText"];
    
    if ((eo = [_context runCommand:cn arguments:lChangeSet]) == nil) {
      [self logWithFormat:@"vCard insert failed."];
      [self setReturnValue:nil];
      return;
    }
    if ([eo isKindOfClass:[NSArray class]])
      eo = ([eo count] > 0) ? [eo lastObject] : nil;
    [self setReturnValue:eo];
  }
  else {
    cn = [cn stringByAppendingString:@"::set"];
    [lChangeSet setObject:[eo valueForKey:@"companyId"] forKey:@"companyId"];
    [lChangeSet setObject:@"vCard update"               forKey:@"logText"];
    
    if ((eo = [_context runCommand:cn arguments:lChangeSet]) == nil) {
      [self logWithFormat:@"vCard update failed."];
      [self setReturnValue:nil];
      return;
    }
    if ([eo isKindOfClass:[NSArray class]])
      eo = ([eo count] > 0) ? [eo lastObject] : nil;
    [self setReturnValue:eo];
  }
  
  /* apply telephone, address */
  
  [self _processAddressesFromVCard:self->vCardObject intoContact:eo
        inContext:_context];
  
  // TODO: phone (in creation step?)
  
#if 0
  [self logWithFormat:@"EO: %@", eo];
#endif
}

/* accessors */

- (void)setVCard:(NSString *)_vc {
  ASSIGNCOPY(self->vCard, _vc);
}
- (NSString *)vCard {
  return self->vCard;
}

- (void)setVCardObject:(id)_vc {
  ASSIGN(self->vCardObject, _vc);
}
- (id)vCardObject {
  return self->vCardObject;
}

- (void)setNewEntityName:(NSString *)_vc {
  ASSIGNCOPY(self->newEntityName, _vc);
}
- (NSString *)newEntityName {
  return self->newEntityName;
}

- (void)setGlobalID:(EOKeyGlobalID *)_gid {
  ASSIGN(self->gid, _gid);
}
- (EOKeyGlobalID *)globalID {
  return self->gid;
}

- (void)setSourceLookup:(BOOL)_flag {
  self->sourceLookup = _flag;
}
- (BOOL)sourceLookup {
  return self->sourceLookup;
}

- (void)setCreatePrivate:(BOOL)_flag {
  self->createPrivate = _flag;
}
- (BOOL)createPrivate {
  return self->createPrivate;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"vCard"])
    [self setVCard:_value];
  else if ([_key isEqualToString:@"vCardObject"])
    [self setVCardObject:_value];
  else if ([_key isEqualToString:@"gid"])
    [self setGlobalID:([_value isNotNull] ? _value : nil)];
  else if ([_key isEqualToString:@"newEntityName"])
    [self setNewEntityName:_value];
  else if ([_key isEqualToString:@"sourceLookup"])
    [self setSourceLookup:[_value boolValue]];
  else if ([_key isEqualToString:@"createPrivate"])
    [self setCreatePrivate:[_value boolValue]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"vCard"])
    return [self vCard];
  if ([_key isEqualToString:@"vCardObject"])
    return [self vCardObject];
  if ([_key isEqualToString:@"gid"])
    return [self globalID];
  if ([_key isEqualToString:@"newEntityName"])
    return [self newEntityName];
  if ([_key isEqualToString:@"sourceLookup"])
    return [NSNumber numberWithBool:self->sourceLookup];
  if ([_key isEqualToString:@"createPrivate"])
    return [NSNumber numberWithBool:self->createPrivate];
  
  return [super valueForKey:_key];
}

@end /* LSSetVCardCommand */
