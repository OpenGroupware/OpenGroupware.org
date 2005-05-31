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

static struct { 
  NSString *key; 
  NSString *key2; 
  BOOL     opt; 
  NSString *type;
  NSString *alttype;
} hardPhoneTypes[] = { /* ordering matters, eg for matching FAX! */
  { @"WORK", @"FAX", NO, @"10_fax",         nil },
  { @"HOME", @"FAX", NO, @"15_fax_private", nil },
  
  { @"CELL",  @"VOICE", YES, @"03_tel_funk",    nil },
  { @"WORK",  @"VOICE", YES, @"01_tel",         @"02_tel" },
  { @"HOME",  @"VOICE", YES, @"05_tel_private", nil },

  { @"PAGER", @"WORK",  YES, @"30_pager",  nil },
  { @"VOICE", nil,      YES, @"31_other1", @"32_other2" },
  
  /* Note: we intentionally do not map "just VOICE" to tel_01, its 'other' */
  { NULL, NULL, NO, NULL }
};

static NSString     *skyrixId         = nil;
static Class        NGVCardClass      = Nil;
static NSNumber     *yesNum           = nil;
static NSNumber     *noNum            = nil;
static NSNull       *null             = nil;
static NSDictionary *personRevMapping          = nil;
static NSDictionary *enterpriseRevMapping      = nil;
static NSDictionary *personPhoneRevMapping     = nil;
static NSDictionary *enterprisePhoneRevMapping = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  yesNum = [[NSNumber numberWithBool:YES] retain];
  noNum  = [[NSNumber numberWithBool:NO]  retain];
  null   = [[NSNull null] retain];
  
  skyrixId = [ud stringForKey:@"skyrix_id"];
  skyrixId = [[NSString alloc] initWithFormat:@"skyrix://%@/%@/",
			         [[NSHost currentHost] name], skyrixId];
  
  if ((NGVCardClass = NSClassFromString(@"NGVCard")) == Nil)
    NSLog(@"Note: NGVCard class not available, vCard parsing not available.");
  
  personRevMapping = 
    [[ud dictionaryForKey:@"LSVCard_PersonAddressRevMapping"]  copy];
  enterpriseRevMapping = 
    [[ud dictionaryForKey:@"LSVCard_EnterpriseAddressRevMapping"]  copy];
  
  personPhoneRevMapping = 
    [[ud dictionaryForKey:@"LSVCard_PersonTelephoneRevMapping"]  copy];
  enterprisePhoneRevMapping = 
    [[ud dictionaryForKey:@"LSVCard_EnterpriseTelephoneRevMapping"]  copy];
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
      [self mapValue:null to:@"sourceUrl"];
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
    [self->changeset setObject:yesNum forKey:@"isPrivate"];
  else if ([tmp caseInsensitiveCompare:@"public"] == NSOrderedSame)
    [self->changeset setObject:noNum forKey:@"isPrivate"];
  // also: confidential
}

- (void)appendEMails:(NSArray *)_mails preferExtAttr:(BOOL)_preferExt {
  /*
    Just load them into properties in the same sequence as in the vCard.
    TODO: would be better to scan for PREF?
    
    TODO: We loose email types. We could add them as part of the attribute
          name, but then we would get issues with the WebUI in various places.
    TODO: We currently can't use the label to store the value, this gets
          overridden in the WebUI for unknown reasons.

    TODO: if we delete an email, mails in the sequence "push up", eg if
          email2 is deleted, email3 becomes email2!
  */
  NSEnumerator *mails;
  id  email; /* NGVCardSimpleValue */
  int i;
  
  mails = [_mails objectEnumerator];
  
  if (!_preferExt) {
    if ([(email = [mails nextObject]) isNotNull])
      [self->changeset setObject:[email stringValue] forKey:@"email"];
    else
      [self->changeset setObject:null forKey:@"email"];
  }
  
  // TODO: this is tricky, since we should also delete mail fields

  /* 
     Currently we write email1-4 even if neither the vCard nor the
     OGo contact previously had them (especially: enterprises+teams).
     
     We would need to pass in the EO to change that.
  */

  for (i = 1; i <= 4; i++) {
    NSString *k;

    k = [[NSString alloc] initWithFormat:@"email%i", i];
    email = [mails nextObject];
    email = [email isNotNull] ? [email stringValue] : (id)null;
    [self->changeset setObject:email forKey:k];
    [k release];
  }
}

/* main generators */

- (NSMutableDictionary *)extractPersonChangeSetFromVCard:(id)_vc
  inContext:(id)_ctx
{
  NSMutableDictionary *cs;
  id n, org;
  
  self->changeset = [[NSMutableDictionary alloc] initWithCapacity:48];
  [self->changeset setObject:yesNum forKey:@"isPerson"];
  
  [self appendIdentity:_vc];
  [self appendCommon:_vc];
  [self appendNote:_vc];
  [self appendPhoto:_vc];
  [self appendEMails:[_vc valueForKey:@"email"] preferExtAttr:YES];
  // [self appendClassification:_vc toChangeSet:md];

  /* TODO: name handling (what is missing?) */
  
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
  [self->changeset setObject:yesNum forKey:@"isEnterprise"];
  
  [self appendIdentity:_vc];
  [self appendCommon:_vc];
  [self appendNote:_vc];
  [self appendPhoto:_vc];
  [self appendEMails:[_vc valueForKey:@"email"] preferExtAttr:NO];
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

/* working on type arrays */

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

- (BOOL)doTypes:(NSArray *)_types containType:(NSString *)_key
  andType:(NSString *)_key2 optional:(BOOL)_optional
{
  /*
    Checks for types containing 1-3 items, eg:
      work
      work,voice
      home,fax,pref
    The first type-key must always be present, the second is optional.
  */
  int idx, secidx, prefidx, count;
  
  if ((count = [_types count]) == 0) return NO;
  if (count > 3) return NO;
  
  /* convert all types to uppercase */
  _types = [_types valueForKey:@"uppercaseString"];
  
#if 0
  [self debugWithFormat:@"CHECK %@ against %@/%@/%s",
        [_types componentsJoinedByString:@","],
        _key, _key2, (_optional ? "optional" : "mandatory")];
#endif
  
  if ((idx = [_types indexOfObject:_key]) == NSNotFound)
    return NO; /* does not contain primary type (WORK or HOME) */
  
  if (count == 1) /* just the primary type, eg WORK */
    return _optional ? YES : NO;
  
  secidx = [_types indexOfObject:_key2];
  if (!_optional && secidx == NSNotFound)
    return NO; /* second type is non-optional and missing */
  
  prefidx = [_types indexOfObject:@"PREF"];
  if (count == 2) {
    if (prefidx != NSNotFound) /* eg WORK,PREF */
      return _optional ? YES : NO;
    
    return secidx == NSNotFound ? NO : YES;
  }
  
  if (count != 3) {
    [self logWithFormat:@"ERROR(%s:%i): count should be 3 but is %i", 
          __PRETTY_FUNCTION__, __LINE__, count];
  }
  /* count is three, all must match: PREF + TYPE + TYPE 2 */
  if (secidx  == NSNotFound) return NO;
  if (prefidx == NSNotFound) return NO;
  return YES;
}

/* running the command */

- (void)_processVCardAddress:(id)_vadr mappedToType:(NSString *)_type
  intoContact:(id)_contact inContext:(id)_context
{
  /* _vadr is a NGVCardAddress */
  NSMutableDictionary *lChangeSet;
  NSString *tmp;
  id addressEO;
  
  [self debugWithFormat:@"save adr under type %@: %@", _type, _vadr];
  
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
  [lChangeSet takeValue:noNum forKey:@"shouldLog"];

  [lChangeSet takeValue:[_vadr valueForKey:@"street"]   forKey:@"street"];
  [lChangeSet takeValue:[_vadr valueForKey:@"locality"] forKey:@"city"];
  [lChangeSet takeValue:[_vadr valueForKey:@"region"]   forKey:@"state"];
  [lChangeSet takeValue:[_vadr valueForKey:@"pcode"]    forKey:@"zip"];
  [lChangeSet takeValue:[_vadr valueForKey:@"country"]  forKey:@"country"];
  
  // TODO: add field for extended attributes?
  
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

- (NSString *)infoValueForArguments:(NSDictionary *)_args {
  NSMutableString *argstr;
  NSEnumerator *e;
  NSString     *k;
  
  argstr = [NSMutableString stringWithCapacity:128];
  [argstr appendString:@"V:{"];
  e = [_args keyEnumerator];
  while ((k = [e nextObject]) != nil) {
    // TODO: escaping?!
    [argstr appendString:k];
    [argstr appendString:@"=\""];
    [argstr appendString:[[_args objectForKey:k] stringValue]];
    [argstr appendString:@"\";"];
  }
  [argstr appendString:@"}"];
  return argstr;
}

- (void)_processVCardPhone:(id)_vtel mappedToType:(NSString *)_type
  intoContact:(id)_contact inContext:(id)_context
{
  /* 
     _vtel is a NGVCardPhone 

     We reuse the 'info' field for additional vCard arguments (eg used by
     Evolution to store slot indices).
  */
  NSMutableDictionary *lChangeSet;
  NSString     *info;
  NSDictionary *args;
  id   phoneEO;
  
  [self debugWithFormat:@"save phone under type %@: %@", _type, _vtel];
  info = nil;
  
  /* fetch EO object to set the new values */
  
  // TODO: this performs a case insensitive match on the type.
  phoneEO = [_context runCommand:@"telephone::get",
                        @"operator",   @"AND",
                        @"comparator", @"EQUAL",
                        @"type",       _type,
                        @"companyId",  [_contact valueForKey:@"companyId"],
                      nil];
  if ([phoneEO isKindOfClass:[NSArray class]]) {
    phoneEO = ([phoneEO count] > 0) ? [phoneEO objectAtIndex:0] : nil;
    info = [phoneEO valueForKey:@"info"];
    if (![info isNotNull] || [info length] == 0)
      info = nil;
  }
  
  /* make changeset */
  
  lChangeSet = [NSMutableDictionary dictionaryWithCapacity:8];
  [lChangeSet takeValue:noNum               forKey:@"shouldLog"];
  [lChangeSet takeValue:[_vtel stringValue] forKey:@"number"];
  
  if ([(args = [_vtel valueForKey:@"arguments"]) isNotNull]) {
    NSString *argstr;

    if (info != nil && ![info hasPrefix:@"V:"]) { /* keep existing infos */
      if ([args objectForKey:@"X-OGO-INFO"] == nil) {
        /* add existing info */
        args = [[args mutableCopy] autorelease];
        [(NSMutableDictionary *)args setObject:[phoneEO valueForKey:@"info"] 
				     forKey:@"X-OGO-INFO"];
      }
    }
    
    if ([args count] == 0) {
      // TODO: should we do this? preserving/merging info might be useful
      //       when accessing with multiple (non-preserving) clients
      argstr = (id)null; /* reset info (eg args removed on client) */
    }
    else
      argstr = [self infoValueForArguments:args];
    
    // TODO: check limit against EO-Model!
    // TODO: expand info length in PostgreSQL?
    if ([argstr isNotNull] && [argstr length] > 254) {
      [self logWithFormat:
              @"ERROR: cannot store vCard arguments, too long: %i vs 254",
              [argstr length]];
      argstr = nil;
    }
    
    if (argstr != nil)
      [lChangeSet setObject:argstr forKey:@"info"];
  }
  
  /* check whether the address type already exists */

#if 0
  [self debugWithFormat:@"  phone: %@ (0x%08X)", lChangeSet, phoneEO];
#endif

  if (![phoneEO isNotNull]) {
    [lChangeSet takeValue:[_contact valueForKey:@"companyId"]
                forKey:@"companyId"];
    [lChangeSet takeValue:_type forKey:@"type"];
    //[lChangeSet setObject:@"vCard address import" forKey:@"logText"];
    phoneEO = [_context runCommand:@"telephone::new" arguments:lChangeSet];
  }
  else {
    [lChangeSet takeValue:[phoneEO valueForKey:@"telephoneId"]
                forKey:@"telephoneId"];
    //[lChangeSet setObject:@"vCard address update" forKey:@"logText"];
    phoneEO = [_context runCommand:@"telephone::set" arguments:lChangeSet];
  }
}

- (NSDictionary *)revAdrMappingForContact:(id)_contact {
  NSString *k;

  k = [[_contact valueForKey:@"globalID"] entityName];
  if ([k isEqualToString:@"Person"])
    return personRevMapping;
  if ([k isEqualToString:@"Enterprise"])
    return enterpriseRevMapping;

  [self logWithFormat:@"Note: not processing vCard ADR's for %@ objects.",k];
  return nil;
}

- (NSDictionary *)revPhoneMappingForContact:(id)_contact {
  NSString *k;

  k = [[_contact valueForKey:@"globalID"] entityName];
  if ([k isEqualToString:@"Person"])
    return personPhoneRevMapping;
  if ([k isEqualToString:@"Enterprise"])
    return enterprisePhoneRevMapping;

  [self logWithFormat:@"Note: not processing vCard TEL's for %@ objects.",k];
  return nil;
}

/* generic ADR/TEL mapping */

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

- (void)_processAddressField:(NSString *)_key fromVCard:(id)_vcard
  intoContact:(id)_contact usingSelector:(SEL)_cpu
  typeMapping:(NSDictionary *)mapping
  inContext:(id)_context
{
  /*
    Note: we do not try to be smart about typeless addresses in combination
          with unused addresses in OGo. We always treat such as custom addrs.
  */
  NSMutableSet *usedTypes;
  NSEnumerator *adrs;
  void (*cpu)(id, SEL, id, NSString *, id, id);
  id adr; // really: NGVCardAddress or NGVCardPhone object
  
  if (![_contact isNotNull]) {
    [self logWithFormat:@"ERROR(%s): got no contact!", __PRETTY_FUNCTION__];
    return;
  }
  
  if ((cpu = (void *)[self methodForSelector:_cpu]) == NULL ){
    [self logWithFormat:@"ERROR(%s): failed to lookup selector: '%@'",
            NSStringFromSelector(_cpu)];
    return;
  }
  
  /* walk over all addresses and map */
  
  usedTypes = [NSMutableSet setWithCapacity:8];
  
  adrs = [[_vcard valueForKey:_key] objectEnumerator];
  while ((adr = [adrs nextObject]) != nil) {
    NSArray  *atypes;
    NSString *mappedType;
    
    atypes     = [adr valueForKey:@"types"];
    mappedType = [self mapTypes:atypes 
                       usingMapping:mapping andUniquer:usedTypes];
    if (mappedType == nil) {
      [self logWithFormat:
              @"Note: did not store '%@', all slots are filled: %@",
              _key, atypes];
      continue;
    }
    
    /* process */
    
    cpu(self, _cpu, adr, mappedType, _contact, _context);
    
    /* mark type as consumed */
    if (mappedType != nil)
      [usedTypes addObject:mappedType];
  }
}

- (void)_processPhoneField:(NSString *)_key fromVCard:(id)_vcard
  intoContact:(id)_contact usingSelector:(SEL)_cpu
  typeMapping:(NSDictionary *)mapping
  inContext:(id)_context
{
  /*
    Note: we do not try to be smart about typeless addresses in combination
          with unused addresses in OGo. We always treat such as custom addrs.
  */
  NSMutableSet *usedTypes;
  NSEnumerator *adrs;
  void (*cpu)(id, SEL, id, NSString *, id, id);
  id adr; // really: NGVCardAddress or NGVCardPhone object
  
  if (![_contact isNotNull]) {
    [self logWithFormat:@"ERROR(%s): got no contact!", __PRETTY_FUNCTION__];
    return;
  }
  
  if ((cpu = (void *)[self methodForSelector:_cpu]) == NULL ){
    [self logWithFormat:@"ERROR(%s): failed to lookup selector: '%@'",
            NSStringFromSelector(_cpu)];
    return;
  }
  
  /* walk over all addresses and map */
  
  usedTypes = [NSMutableSet setWithCapacity:8];
  
  adrs = [[_vcard valueForKey:_key] objectEnumerator];
  while ((adr = [adrs nextObject]) != nil) {
    NSArray  *atypes;
    NSString *mappedType = nil;
    unsigned i;
    
    atypes = [adr valueForKey:@"types"];
    
    /* 
       Some hardcoded mapping (because phone-numbers are usually multi-type,
       eg work,voice (which we cannot do easily with a plist).
    */
    for (i = 0; hardPhoneTypes[i].key != nil; i++) {
      if ([self doTypes:atypes
                containType:hardPhoneTypes[i].key
                andType:hardPhoneTypes[i].key2
                optional:hardPhoneTypes[i].opt]) {
        mappedType = hardPhoneTypes[i].type;
        if ([usedTypes containsObject:mappedType]) {
          /* already used, check alt, then fallback */
          if ((mappedType = hardPhoneTypes[i].alttype) != nil) {
            if ([usedTypes containsObject:mappedType])
              mappedType = nil; /* also used */
          }
        }
        break;
      }
    }
    
    /* generic mapping */
    
    if (mappedType == nil) {
      mappedType = [self mapTypes:atypes 
                         usingMapping:mapping andUniquer:usedTypes];
    }
    if (mappedType == nil) {
      [self logWithFormat:
              @"Note: did not store '%@', all slots are filled: %@",
              _key, atypes];
      continue;
    }
    
    /* process */
    
    cpu(self, _cpu, adr, mappedType, _contact, _context);
    
    /* mark type as consumed */
    if (mappedType != nil)
      [usedTypes addObject:mappedType];
  }
}

/* primary run function */

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
    NSString *cmdname;
    
    ASSIGN(self->gid, lgid);
    [self logWithFormat:@"write to GID: %@", lgid];
    
    /* 
       Note: object::get-by-globalid apparently doesn't run person::get! So 
             we need to use generic methods (or optionally fetch extattrs etc
	     on our own).
    */
    cmdname = [[lgid entityName] lowercaseString];
    cmdname = [cmdname stringByAppendingString:@"::get-by-globalid"];
    
    eo = [_context runCommand:cmdname, @"gid", lgid, nil];
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
  
  [self _processAddressField:@"adr" fromVCard:self->vCardObject
        intoContact:eo
        usingSelector:
          @selector(_processVCardAddress:mappedToType:intoContact:inContext:)
        typeMapping:[self revAdrMappingForContact:eo]
        inContext:_context];

  /* Note: we are handling the phone relationship on our own */
  [self _processPhoneField:@"tel" fromVCard:self->vCardObject
        intoContact:eo
        usingSelector:
          @selector(_processVCardPhone:mappedToType:intoContact:inContext:)
        typeMapping:[self revPhoneMappingForContact:eo]
        inContext:_context];
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
