/*
  Copyright (C) 2002-2009 SKYRIX Software AG
  Copyright (C) 2009      Helge Hess

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
  This command fetches vCards for globalIds (Person or Enterprise).
  It first fetches the current ids and version of the objects
  (during that the access is checked)
  and looks for cached vCards ( <id>.<version>.vcf in LSAttachmentPath)
  and builds new if needed.

  The command supports grouping (groupBy parameter) and these attributes:
    vCardData
    companyId
    globalID
    objectVersion

  If no attribute is requested, an array of vCard strings is returned.
  
  @see: RFC 2426
*/

@class NSString, NSArray;

@interface LSGetVCardForGlobalIDsCommand : LSDBObjectBaseCommand
{
  NSArray  *gids;
  BOOL     buildResponse;
  NSArray  *attributes;
  NSString *groupBy;
}

@end

#include "NSString+VCard.h"
#include "LSVCardCompanyFormatter.h"
#include "common.h"

// TODO: do we really need to have a dependency on WOResponse?
#include <NGObjWeb/WOResponse.h>

@implementation LSGetVCardForGlobalIDsCommand

static NSString     *LSAttachmentPath = nil;
static BOOL          LSHashCache = NO;
static NSString     *skyrixId = nil;
static NSDictionary *telephoneMapping = nil;
static NSDictionary *addressMapping = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  skyrixId = [ud stringForKey:@"skyrix_id"];
  skyrixId = [[NSString alloc] initWithFormat:@"skyrix://%@/%@/",
			         [[NSHost currentHost] name], skyrixId];
  
  addressMapping   = [[ud dictionaryForKey:@"LSVCard_AddressMapping"]   copy];
  telephoneMapping = [[ud dictionaryForKey:@"LSVCard_TelephoneMapping"] copy];

  LSHashCache = [ud boolForKey:@"LSHashVCFCache"];
  if (LSHashCache)
    NSLog(@"Hashing of cached vCard data enabled.");

  LSAttachmentPath = [[ud stringForKey:@"LSVCFCachePath"] copy];
  if (![LSAttachmentPath isNotEmpty])
    LSAttachmentPath = [[ud stringForKey:@"LSAttachmentPath"] copy];
  if ([LSAttachmentPath isNotEmpty])
    NSLog(@"Note: storing cached vCards files in: '%@'", LSAttachmentPath);
  else
    NSLog(@"ERROR: did not find 'LSAttachmentPath'!");
}

- (void)dealloc {
  [self->attributes release];
  [self->groupBy    release];
  [self->gids       release];
  [super dealloc];
}

/* command methods */

- (id)_prepareResultForCount:(int)_cnt {
  /* Note: results are retained */
  
  if ([self->attributes isNotEmpty] && [self->groupBy isNotEmpty])
    return [[NSMutableDictionary alloc] initWithCapacity:(_cnt + 1)];
  
  return [[NSMutableArray alloc] initWithCapacity:(_cnt + 1)];
}

- (void)_addVCard:(NSString *)_vCard ofRecord:(id)_record
  toResult:(id)_result
{
  NSMutableDictionary *entry;
  id tmp;
  id val;
  
  if (![_vCard isNotNull]) {
    [self warnWithFormat:@"%s: got no vCard!", __PRETTY_FUNCTION__];
    return;
  }
  if (![self->attributes isNotEmpty]) {
    [_result addObject:_vCard];
    return;
  }
  
  entry = [[NSMutableDictionary alloc] initWithCapacity:4];
  [entry setObject:_vCard forKey:@"vCardData"];
  if ([self->attributes containsObject:@"companyId"]) {
    if ((tmp = [_record valueForKey:@"companyId"]))
      [entry setObject:tmp forKey:@"companyId"];
  }
  if ([self->attributes containsObject:@"globalID"]) {
    if ((tmp = [_record valueForKey:@"globalID"]))
      [entry setObject:tmp forKey:@"globalID"];
  }
  if ([self->attributes containsObject:@"objectVersion"]) {
    if ((tmp = [_record valueForKey:@"objectVersion"]))
      [entry setObject:tmp forKey:@"objectVersion"];
  }
  
  if (![self->groupBy isNotEmpty]) {
    [_result addObject:entry];
    return;
  }
      
  if ((tmp = [entry valueForKey:self->groupBy]) == nil) {
    [self warnWithFormat:@"%s: cannot map entry %@ by key %@",
	  __PRETTY_FUNCTION__, entry, self->groupBy];
    return;
  }
  if ((val = [_result valueForKey:tmp]) != nil) {
    [self warnWithFormat:@"%s: map already contains an entry for key %@: %@",
	  __PRETTY_FUNCTION__, tmp, val];
    return;
  }
  [(NSMutableDictionary *)_result setObject:entry forKey:tmp];
}

/* fetching */

- (NSArray *)_fetchIdsAndVersionsInContext:(id)_context {
  static NSArray *attrs = nil;
  NSMutableArray *result;
  NSMutableArray *persons;
  NSMutableArray *enterprises;
  NSMutableArray *teams;
  EOKeyGlobalID  *gid;
  int cnt;

  if (attrs == nil) {
    attrs = [[NSArray alloc] initWithObjects:
                             @"companyId", @"globalID",
                             @"objectVersion", nil];
  }
  
  cnt = [self->gids count];
  if (cnt == 0) return [NSArray array];

  persons     = [[NSMutableArray alloc] initWithCapacity:cnt];
  enterprises = [[NSMutableArray alloc] initWithCapacity:cnt];
  teams       = [[NSMutableArray alloc] initWithCapacity:cnt];
  
  while (cnt--) {
    gid = [self->gids objectAtIndex:cnt];
    if ([[gid entityName] isEqualToString:@"Person"])
      [persons addObject:gid];
    else if ([[gid entityName] isEqualToString:@"Enterprise"])
      [enterprises addObject:gid];
    else if ([[gid entityName] isEqualToString:@"Team"])
      [teams addObject:gid];
    else {
      NSString *s;
      
      s = [NSString stringWithFormat:
                      @"invalid entityName '%@' "
                      @"(Person, Team and Enterprise accepted)",
                    [gid entityName]];
      [self assert:NO reason:s];
    }
  }

  result =
    [NSMutableArray arrayWithCapacity:[persons count]+[enterprises count]+
                    [teams count]];
  if ([persons isNotEmpty]) {
    [result addObjectsFromArray:
            LSRunCommandV(_context,
                          @"person",     @"get-by-globalid",
                          @"gids",       persons,
                          @"attributes", attrs,
                          nil)];
  }
  if ([enterprises isNotEmpty]) {
    [result addObjectsFromArray:
            LSRunCommandV(_context,
                          @"enterprise", @"get-by-globalid",
                          @"gids",       enterprises,
                          @"attributes", attrs,
                          nil)];
  }
  if ([teams isNotEmpty]) {
    [result addObjectsFromArray:
            LSRunCommandV(_context,
                          @"team", @"get-by-globalid",
                          @"gids",       teams,
                          @"attributes", attrs,
                          nil)];
  }

  [persons     release];
  [enterprises release];
  [teams       release];
  return result;
}

/* caching */
- (id)_cachedVCardForRecord:(id)_record inContext:(id)_context {
  NSString      *path;
  NSString      *file;
  NSFileManager *manager;
  NSNumber      *cId, *oV;

  [self assert:(_record != nil) reason:@"no record to fetch vCard for!"];

  cId = [_record valueForKey:@"companyId"];
  oV  = [_record valueForKey:@"objectVersion"];
  if (cId == nil || oV == nil) {
    [self warnWithFormat:
            @"%s: missing companyId and/or objectVersion in record: %@",
            __PRETTY_FUNCTION__, _record];
    return nil;
  }
  
  path = LSAttachmentPath;
  
  file = [[NSString alloc] initWithFormat:@"%@.%@.vcf", cId, oV];
  if (LSHashCache)
  {
    int        offset;
    NSString  *hash;

    offset = [[cId stringValue] length] - 2;
    hash = [[cId stringValue] substringFromIndex:offset];
    hash = [NSString stringWithFormat:@"vcfdir%@", hash];
    path = [path stringByAppendingPathComponent:hash];
  }
  path = [path stringByAppendingPathComponent:file];
  [file release]; file = nil;
  
  manager = [NSFileManager defaultManager];
  
  if ([manager fileExistsAtPath:path]) 
    return [NSString stringWithContentsOfFile:path];  
  return nil;
}

- (void)_cacheVCard:(NSString *)_vCard forContact:(id)_comp
  inContext:(id)_context
{
  NSString       *path;
  NSString       *file;
  NSFileManager  *manager;
  BOOL           ok;
  id cId, oV;

  [self assert:(_vCard != nil) reason:@"no vCard to save!"];
  [self assert:(_comp != nil)  reason:@"no record to save vCard for!"];

  cId = [_comp valueForKey:@"companyId"];
  oV  = [_comp valueForKey:@"objectVersion"];
  if (cId == nil || oV == nil) {
    [self warnWithFormat:
            @"%s: missing companyId and/or objectVersion in record: %@",
            __PRETTY_FUNCTION__, _comp];
    return;
  }

  manager = [NSFileManager defaultManager];

  path = LSAttachmentPath;
  if (LSHashCache) {
    int        offset;
    NSString  *hash;

    offset = [[cId stringValue] length] - 2;
    hash = [[cId stringValue] substringFromIndex:offset];
    hash = [NSString stringWithFormat:@"vcfdir%@", hash];
    path = [path stringByAppendingPathComponent:hash];
    if (![manager fileExistsAtPath:path])
      [manager createDirectoryAtPath:path attributes:nil];
  }
  file = [NSString stringWithFormat:@"%@.%@.vcf", cId, oV];
  path = [path stringByAppendingPathComponent:file];

  if ([manager fileExistsAtPath:path])
    [manager removeFileAtPath:path handler:nil];
  
  ok = [_vCard writeToFile:path atomically:YES];
  if (!ok) 
    [self errorWithFormat:@"could not write cache file: %@", path];
  
#if 0 // no reason to crash on that?!
  [self assert:ok reason:@"error during save of vCard cache file"];
#endif
}

/* execution */

- (void)_buildAndCacheVCardsForContacts:(NSArray *)_uncachedContacts
  type:(NSString *)_type // person, enterprise, team
  result:(id)_result
  inContext:(id)_context
{
  NSArray  *globalIDs;
  NSArray  *contacts;
  unsigned cnt, i;
  
  globalIDs = [_uncachedContacts valueForKey:@"globalID"];
  contacts  = LSRunCommandV(_context, _type, @"get-by-globalid",
                            @"gids", globalIDs, nil);
  
  for (i = 0, cnt = [contacts count]; i < cnt; i++) {
    EOKeyGlobalID *gid;
    NSFormatter   *formatter;
    NSString      *vCard;
    id contact;
    
    contact = [contacts objectAtIndex:i];
    gid     = [contact valueForKey:@"globalID"];
    
    /* select vCard generator */
    
    if (([[gid entityName] isEqualToString:@"Person"]))
      formatter = [LSVCardPersonFormatter formatter];
    else if (([[gid entityName] isEqualToString:@"Enterprise"]))
      formatter = [LSVCardEnterpriseFormatter formatter];
    else if (([[gid entityName] isEqualToString:@"Team"]))
      formatter = [LSVCardTeamFormatter formatter];
    else {
      [self errorWithFormat:@"cannot process record: %@", gid];
      continue;
    }
    
    /* fetch addresses */
    
    if (![[gid entityName] isEqualToString:@"Team"]) {
      NSArray *addrs;
      
      addrs = LSRunCommandV(_context,
                            @"address", @"get",
                            @"companyId",  [contact valueForKey:@"companyId"],
                            @"returnType", intObj(LSDBReturnType_ManyObjects),
                            nil);
      [contact takeValue:addrs forKey:@"addresses"];
    }
    
    /* build vCard */
    
    if ((vCard = [formatter stringForObjectValue:contact]) == nil) {
      [self errorWithFormat:
              @"%s: failed building vCard for contact (%@): %@", 
              __PRETTY_FUNCTION__, formatter, contact];
      continue;
    }
    
    [self _cacheVCard:vCard forContact:contact inContext:_context];
    [self _addVCard:vCard   ofRecord:contact   toResult:_result];
  }

}

- (id)_buildResponseForVCards:(id)_vCards inContext:(id)_context {
  // TODO: this does not belong here, the command should only provide the
  //       NSData or NSString objects
  NSString *s;
  NSData   *data;
  id       response;
  
  if ([_vCards isKindOfClass:[NSDictionary class]]) 
    _vCards = [_vCards allValues];
  if ([self->attributes isNotEmpty])
    _vCards = [_vCards valueForKey:@"vCardData"];
  
  s    = [_vCards componentsJoinedByString:@""];
  data = [s dataUsingEncoding:NSUTF8StringEncoding];
  response = [[[NSClassFromString(@"WOResponse") alloc] init] autorelease];
  [response setStatus:200];
  [response setHeader:@"text/x-vcard; charset=utf-8" forKey:@"content-type"];
  [response setHeader:@"identity" forKey:@"content-encoding"];
  [response setContent:data];
  
  return response;
}

- (void)_executeInContext:(id)_context {
  NSArray *records;
  id      result; 
  int     cnt;

  /* fetch data */

  records = [self _fetchIdsAndVersionsInContext:_context];
  
  /* process data */
  
  if ((cnt = [records count]) != 0) {
    NSMutableArray *uncachedPersons;
    NSMutableArray *uncachedEnterprises;
    NSMutableArray *uncachedTeams;
    id cached, record;
    
    result = [self _prepareResultForCount:cnt]; // retained

    uncachedPersons     = [[NSMutableArray alloc] initWithCapacity:8];
    uncachedEnterprises = [[NSMutableArray alloc] initWithCapacity:8];
    uncachedTeams       = [[NSMutableArray alloc] initWithCapacity:8];
    
    while (cnt--) {
      record = [records objectAtIndex:cnt];
      cached = [self _cachedVCardForRecord:record inContext:_context];
      if (cached != nil) {
        [self _addVCard:cached ofRecord:record toResult:result];
      }
      else {
        EOKeyGlobalID *gid;
        NSString      *en;
	
        gid = [record valueForKey:@"globalID"];
        en  = [gid entityName];
        if ([en isEqualToString:@"Person"])
          [uncachedPersons addObject:record];
        else if ([en isEqualToString:@"Enterprise"])
          [uncachedEnterprises addObject:record];
        else if ([en isEqualToString:@"Team"])
          [uncachedTeams addObject:record];
        else {
      	  NSString *error;
	  
      	  error = [NSString stringWithFormat:
                                 @"invalid entityName '%@' "
                                 @"(Person, Enterprise and Team accepted)",
			    [gid entityName]];
          [self assert:NO reason:error];
        }
      }
    }

    if ([uncachedPersons isNotEmpty]) {
      [self _buildAndCacheVCardsForContacts:uncachedPersons
            type:@"person"
            result:result
            inContext:_context];
    }
    
    if ([uncachedEnterprises isNotEmpty]) {
      [self _buildAndCacheVCardsForContacts:uncachedEnterprises
            type:@"enterprise"
            result:result
            inContext:_context];
    }
    
    if ([uncachedTeams isNotEmpty]) {
      [self _buildAndCacheVCardsForContacts:uncachedTeams
            type:@"team"
            result:result
            inContext:_context];
    }
    

    [uncachedPersons     release];
    [uncachedEnterprises release];
    [uncachedTeams       release];

  }
  else
    result = [[NSArray alloc] init];

  // TODO: the build response should not be used
  [self setReturnValue:(self->buildResponse)
    ? [self _buildResponseForVCards:result inContext:_context]
    : result];
  [result release];
}

/* accessors */

- (void)setGlobalIDs:(NSArray *)_gids {
  ASSIGN(self->gids,_gids);
}
- (NSArray *)globalIDs {
  return self->gids;
}

- (void)setGlobalID:(EOGlobalID *)_gid {
  [self setGlobalIDs:[NSArray arrayWithObject:_gid]];
}
- (EOGlobalID *)globalID {
  return [[self globalIDs] lastObject];
}

- (void)setBuildResponse:(BOOL)_flag {
#if DEBUG
  if (_flag) {
    [self logWithFormat:
	    @"Note: uses vcard command to generate WOResponse which is "
	    @"deprecated"];
  }
#endif
  self->buildResponse = _flag;
}
- (BOOL)buildResponse {
  return self->buildResponse;
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setGroupBy:(NSString *)_group {
  ASSIGNCOPY(self->groupBy,_group);
}
- (NSString *)groupBy {
  return self->groupBy;
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"gid"])
    [self setGlobalID:_value];
  else if ([_key isEqualToString:@"gids"])
    [self setGlobalIDs:_value];
  else if ([_key isEqualToString:@"buildResponse"])
    [self setBuildResponse:[_value boolValue]];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value];
  else if ([_key isEqualToString:@"groupBy"])
    [self setGroupBy:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  id v;
  
  if ([_key isEqualToString:@"gid"])
    v = [self globalID];
  else if ([_key isEqualToString:@"gids"])
    v = [self globalIDs];
  else if ([_key isEqualToString:@"buildResponse"])
    v = [NSNumber numberWithBool:[self buildResponse]];
  else if ([_key isEqualToString:@"attributes"])
    v = [self attributes];
  else if ([_key isEqualToString:@"groupBy"])
    v = [self groupBy];
  else 
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetVCardForGlobalIDsCommand */
