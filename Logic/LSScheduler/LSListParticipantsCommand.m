/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

/*
 * fetch participants, resolveTeams and fetch enterprises for one appointment
 *
 * returns an array of participants (person and team dictionaries)
 * team members are resolved, beeing dictionarys too
 *
 * accepts:
 * attributes:
 *   dateCompanyAssigmentId
 *   companyId
 *   dateId
 *   partStatus
 *   role
 *   comment
 *   rsvp
 *
 *   team.companyId
 *   team.description
 *   team.isTeam
 *   team.email
 *
 *   team.members
 *
 *   person.companyId
 *   person.globalID
 *   person.firstname
 *   person.extendedAttributes
 *   person.telephones
 *   person.name
 *   person.salutation
 *   person.degree
 *   person.isPrivate
 *   person.ownerId
 *
 *   person.enterprises
 *                     
 *   enterprises.description
 *   enterprises.companyId
 *   enterprises.globalID
 *
 *  dateId
 *  dateIds
 *  gid
 *  gids
 *
 *  groupBy
 *
 */

// TODO: needs more cleanup
// TODO: should check for apt permissions?

#include <LSFoundation/LSDBObjectBaseCommand.h>

@interface LSListParticipantsCommand : LSDBObjectBaseCommand
{
  NSArray  *dateIds;
  NSArray  *attributes;
  NSString *groupBy;
}
@end /* LSDBObjectBaseCommand */


#include <EOControl/EOKeyGlobalID.h>
#include "common.h"

static int compareParticipants(id part1, id part2, void *context);

@implementation LSListParticipantsCommand

static unsigned batchSize = 200;
static NSArray  *dateCompanyAssignmentAttributes = nil;
static NSArray  *teamAttributes                  = nil;
static NSArray  *personAttributes               = nil;
static NSNumber *yesNum                         = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  yesNum = [[NSNumber numberWithBool:YES] retain];

  dateCompanyAssignmentAttributes =
    [[NSArray alloc] initWithObjects:
                       @"dateCompanyAssigmentId",
                       @"companyId",
                       @"dateId",
                       @"partStatus",
                       @"role",
                       @"comment",
                       @"rsvp", nil];
  teamAttributes =
    [[NSArray alloc] initWithObjects:@"team.companyId",
                       @"team.description", @"team.isTeam",
                       @"team.email",
                       nil];
  personAttributes =
    [[NSArray alloc] initWithObjects:
                       @"person.companyId",
                       @"person.globalID",
                       @"person.firstname",
                       @"person.extendedAttributes",
                       @"person.telephones",
                       @"person.name",
                       @"person.salutation",
                       @"person.degree",
                       @"person.enterprises",
                       @"person.isPrivate",
                       @"person.ownerId",
                       @"person.isPerson",
                       
                       @"enterprises.description",
                       @"enterprises.companyId",
                       @"enterprises.globalID",
                       nil];
}

+ (NSArray *)dateCompanyAssignmentAttributes {
  return dateCompanyAssignmentAttributes;
}
+ (NSArray *)teamAttributes {
  return teamAttributes;
}
+ (NSArray *)personAttributes {
  return personAttributes;
}

- (void)dealloc {
  [self->attributes release];
  [super dealloc];
}

/* implementation */

- (NSArray *)_checkAttributes:(NSArray *)_attributes
  maxAttributes:(NSArray *)_maxAttr
  entity:(id)_entity
  subKey:(NSString *)_subKey
{
  NSMutableArray *ma;
  NSEnumerator *e;
  NSString *one;
  
  if ([_attributes count] == 0) _attributes = _maxAttr;
  
  e = [_attributes objectEnumerator];
  ma = [NSMutableArray array];
  // go thru' the requested attributes
  // and filter those defined in _maxAttr
  
  while ((one = [e nextObject])) {
    if (_subKey != nil) {
      // key must have a prefix (i.e.: 'team.')
      if (![one hasPrefix:_subKey]) continue;
    }
    if ([_maxAttr containsObject:one]) {
      // key allowed
      if (_subKey != nil) one = [one substringFromIndex:[_subKey length]];
      if (_entity != nil)
        // create a proper EOAttribute
        [ma addObject:[_entity attributeNamed:one]];
      else
        // just add the string
        [ma addObject:one];
    }
  }
  return ma;
}
- (NSArray *)_enterpriseAttributes:(NSArray *)_attributes {
  return [self _checkAttributes:_attributes
               maxAttributes:[LSListParticipantsCommand personAttributes]
               entity:nil subKey:@"enterprises."];
}

- (NSArray *)_createInQuerys {
  /* TODO: this probably should be a NSString category?! */
  NSEnumerator    *idEnum;
  unsigned        i, max;
  NSMutableArray  *ins;
  NSMutableString *in;
  id              dateId;
  
  max = [self->dateIds count];
  ins = [NSMutableArray arrayWithCapacity:(max / batchSize) + 1];
  in  = [NSMutableString stringWithCapacity:256];
  i   = 0;
  
  idEnum = [self->dateIds objectEnumerator];
  while ((dateId = [idEnum nextObject])) {
    if (i == batchSize) {
      // reached batchSize
      [ins addObject:[[in copy] autorelease]];
      [in setString:@""];
      i = 0;
    }
    
    if (i != 0) [in appendString:@","];
    [in appendString:[dateId stringValue]];
    
    // increase count of INs
    i++;
  }

  if ([in length] > 0)
    [ins addObject:in];
  
  return ins;
}

- (NSArray *)fetchCompanyDateAssignments:(NSArray *)_attributes {
  /* TODO: split up? */
  EOAdaptorChannel *channel;
  EOEntity         *entity;
  NSMutableArray   *ma;
  NSEnumerator     *inEnum;
  NSString         *in;
  
  channel = [[self databaseChannel] adaptorChannel];
  entity  = [[self databaseModel] entityNamed:@"DateCompanyAssignment"];

  // check attributes to fetch
  _attributes =
    [self _checkAttributes:_attributes
          maxAttributes:
          [LSListParticipantsCommand dateCompanyAssignmentAttributes]
          entity:entity subKey:nil];

  ma = [NSMutableArray arrayWithCapacity:32];
  // create "IN" query
  inEnum = [[self _createInQuerys] objectEnumerator];
  while ((in = [inEnum nextObject])) {
    EOSQLQualifier *qual;
    id             one;
    BOOL           ok;
    
    qual = [[EOSQLQualifier alloc] initWithEntity:entity
                                   qualifierFormat:@"%A IN (%@)",
                                     @"dateId", in];
    
    ok = [channel selectAttributes:_attributes 
                  describedByQualifier:qual
                  fetchOrder:nil lock:NO];
    [self assert:ok reason:[sybaseMessages description]];

    while ((one = [channel fetchAttributes:_attributes withZone:NULL]))
      [ma addObject:one];
    
    [qual release]; qual = nil;
  }
  
  return ma;
}

- (NSDictionary *)mappedToCompanyId:(NSArray *)_ar {
  NSMutableDictionary *md;
  NSEnumerator *e;
  id           one, key;

  md = [NSMutableDictionary dictionaryWithCapacity:[_ar count]];
  e  = [_ar objectEnumerator];
  
  while ((one = [e nextObject])) {
    key = [one valueForKey:@"companyId"];
    if ((one != nil) && (key != nil))
      [md setObject:one forKey:key];
  }
  return md;
}

- (NSArray *)teamsForParticipantIds:(NSArray *)_cids
  attributes:(NSArray *)_attributes
{
  /* returns teams in assignments, nil means no team attributes requested */
  EOAdaptorChannel *channel;
  EOEntity         *entity;
  EOSQLQualifier   *qual;
  id               one;
  NSMutableArray   *ma;
  BOOL             ok;
  NSString         *in;

  in = [self joinPrimaryKeysFromArrayForIN:_cids];
  if ([in length] == 0) {
    [self logWithFormat:@"got no primary keys for IN query!"];
    return nil;
  }
  
  channel = [[self databaseChannel] adaptorChannel];
  entity  = [[self databaseModel] entityNamed:@"Team"];
  
  qual = [[EOSQLQualifier alloc] initWithEntity:entity
                                 qualifierFormat:@"%A IN (%@)",
                                 @"companyId", in];
  _attributes =
    [self _checkAttributes:_attributes
          maxAttributes:[LSListParticipantsCommand teamAttributes]
          entity:entity subKey:@"team."];
  if ([_attributes count] == 0)
    // no team attributes requested
    return nil;
  
  ok = [channel selectAttributes:_attributes 
                describedByQualifier:qual
                fetchOrder:nil lock:NO];
  [self assert:ok reason:[sybaseMessages description]];

  ma = [NSMutableArray arrayWithCapacity:16];
  while ((one = [channel fetchAttributes:_attributes withZone:NULL]))
    [ma addObject:one];
  
  [qual release]; qual = nil;
  return ma;
}

- (NSArray *)personGIDsForParticipantIds:(NSArray *)_cids {
  EOAdaptorChannel *channel;
  EOEntity         *entity;
  EOSQLQualifier   *qual;
  id               one;
  NSArray          *attrs;
  NSMutableArray   *ma;
  BOOL             ok;
  NSString         *in;

  in = [self joinPrimaryKeysFromArrayForIN:_cids];
  if ([in length] == 0) {
    [self logWithFormat:@"got no primary keys for IN query!"];
    return nil;
  }
  
  channel = [[self databaseChannel] adaptorChannel];
  entity  = [[self databaseModel] entityNamed:@"Person"];

  attrs = [NSArray arrayWithObject:[entity attributeNamed:@"companyId"]];

  qual = [[EOSQLQualifier alloc] initWithEntity:entity
                                 qualifierFormat:@"%A IN (%@)",
				   @"companyId", in];
  
  ok = [channel selectAttributes:attrs
                describedByQualifier:qual
                fetchOrder:nil lock:NO];
  [qual release]; qual = nil;
  [self assert:ok reason:[sybaseMessages description]];
  
  ma = [NSMutableArray arrayWithCapacity:16];
  while ((one = [channel fetchAttributes:attrs withZone:NULL])) {
    one = [one valueForKey:@"companyId"];
    one = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                         keys:&one keyCount:1 zone:NULL];
    if (one)
      [ma addObject:one];
  }
  return ma;
}

- (NSDictionary *)memberGIDsForTeamsIds:(NSArray *)_tids
  context:(id)_context
{
  NSMutableArray *gids;
  NSEnumerator   *e;
  NSString       *one;
  id             result;
  
  gids = [NSMutableArray array];
  e    = [_tids objectEnumerator];
  while ((one = [e nextObject])) {
    one = [EOKeyGlobalID globalIDWithEntityName:@"Team"
                         keys:&one keyCount:1 zone:NULL];
    if (one)
      [gids addObject:one];
  }

  result =  LSRunCommandV(_context, @"team", @"members",
                          @"groups",         gids,
                          @"fetchGlobalIDs", yesNum,
                          nil);
  if ([gids count] == 1) {
    result = [NSDictionary dictionaryWithObject:result
                           forKey:[gids lastObject]];
  }
  return result;
}

- (void)_fetchTeamMembers:(NSArray *)_teams
  memberMap:(NSDictionary **)_memberMap
  allPersons:(NSMutableArray *)_allPersons
  inContext:(id)_context
{
  NSEnumerator *e;
  id           tGID;
  
  (*_memberMap) =
    [self memberGIDsForTeamsIds:[_teams valueForKey:@"companyId"]
          context:_context];
  e = [(*_memberMap) keyEnumerator];
  while ((tGID = [e nextObject])) {
    NSArray  *ms;
    unsigned i, max;
    
    ms = [(*_memberMap) objectForKey:tGID];
    for (i = 0, max = [ms count]; i < max; i++) {
      tGID = [ms objectAtIndex:i];
      if (![_allPersons containsObject:tGID])
        [_allPersons addObject:tGID];
    }
  }
}

- (id)_fetchAllPersonsForGIDs:(NSArray *)_gids inContext:(id)_context {
  NSArray *pAttributes;
  
  pAttributes =
    [self _checkAttributes:self->attributes
          maxAttributes:[LSListParticipantsCommand personAttributes]
          entity:nil subKey:@"person."];
  
  return LSRunCommandV(_context, @"person", @"get-by-globalid",
                       @"gids",       _gids,
                       @"attributes", pAttributes,
                       nil);
}

- (void)_fetchEnterprisesForPersonGIDs:(NSArray *)_personGIDs
  persons:(NSArray *)_allPersons
  inContext:(id)_context
{
  id             tmp;
  NSDictionary   *enterprises;
  NSEnumerator   *e;
  NSMutableArray *allEnterprises;
  NSDictionary   *id2Enterprise;
  NSArray        *pAttributes;

  tmp = LSRunCommandV(_context, @"person", @"enterprises",
                      @"persons",        _personGIDs,
                      @"fetchGlobalIDs", yesNum,
                      nil);
  
  if ([_personGIDs count] == 1) {
    enterprises = [NSDictionary dictionaryWithObject:tmp
                                forKey:[_personGIDs lastObject]];
  }
  else
    enterprises = tmp;

  e              = [enterprises keyEnumerator];
  allEnterprises = [NSMutableArray arrayWithCapacity:8];
  while ((tmp = [e nextObject])) {
    [allEnterprises addObjectsFromArray:[enterprises objectForKey:tmp]];
  }
  /* now allEnterprises contains all gids of the enterprises */
  pAttributes    = [self _enterpriseAttributes:self->attributes];
  allEnterprises =
    LSRunCommandV(_context, @"enterprise", @"get-by-globalid",
                  @"gids",       allEnterprises,
                  @"attributes", pAttributes, nil);
  /* now allEnterprises contains all enterprise dictionaries */
  id2Enterprise = [self mappedToCompanyId:allEnterprises];
  // going thru all the persons

  /* assign the enterprises to the persons */
  e = [_allPersons objectEnumerator];
  while ((tmp = [e nextObject])) {
    NSMutableArray *ma;
    NSEnumerator   *ee;
    EOKeyGlobalID  *gid;
    id entps;
    
    gid   = [tmp valueForKey:@"globalID"];
    entps = [enterprises objectForKey:gid];
    ma    = [NSMutableArray arrayWithCapacity:8];
    ee    = [entps objectEnumerator];
    
    while ((gid = [ee nextObject])) {
      gid = [gid keyValues][0];
      gid = [id2Enterprise objectForKey:gid];
      
      if (gid != nil)
        [ma addObject:gid];
    }
    [(NSMutableDictionary *)tmp setObject:ma forKey:@"enterprises"];
  }

}

- (void)_mapMembers:(NSDictionary *)_memberMap
  outOfPersons:(NSDictionary *)_idToPersons
  toTeam:(NSMutableDictionary *)_team
  teamId:(id)_teamId
{
  NSArray        *memberGIDs;
  NSEnumerator   *me;
  NSMutableArray *teamMembers;
  EOKeyGlobalID  *gid, *m;

  // create team GID
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Team"
                       keys:&_teamId keyCount:1 zone:NULL];
  // get the members of the team
  memberGIDs  = [_memberMap objectForKey:gid];
  teamMembers = [NSMutableArray arrayWithCapacity:[memberGIDs count]];
          
  me = [memberGIDs objectEnumerator];
  while ((m = [me nextObject])) {
    m = [m keyValues][0];
    m = [_idToPersons objectForKey:m];
    if (m != nil)
      [teamMembers addObject:m];
  }
  [teamMembers sortUsingFunction:compareParticipants context:self];
  [_team setObject:teamMembers forKey:@"members"];
}

- (void)_groupEntry:(NSDictionary *)_entry 
  intoGroup:(NSMutableDictionary *)_dict 
{
  id             key;
  NSMutableArray *gr;
  
  if ((key = [_entry objectForKey:self->groupBy]) == nil) {
    [self assert:NO reason:@"invalid groupBy key"];
    return;
  }

  gr = [_dict objectForKey:key];
  if (gr == nil)
    [_dict setObject:[NSMutableArray arrayWithObject:_entry] forKey:key];
  else
    [gr addObject:_entry];
}

- (id)_groupResult:(NSArray *)_assignments
  teams:(NSArray *)_teams
  personMap:(NSDictionary *)_idToPersons
  memberMap:(NSDictionary *)_memberMap
{
  /*
    if grouped
    double participants may occure
    so go thru the assignments and not the persons and teams
  */
  NSMutableDictionary *group;
  NSDictionary        *idToTeams;
  NSEnumerator        *e;
  NSNumber     *companyId;
  NSDictionary *one;
  id company;

  group = [NSMutableDictionary dictionaryWithCapacity:[_assignments count]];
    
  idToTeams   = [self mappedToCompanyId:_teams];
  e           = [_assignments objectEnumerator];
    
  while ((one = [e nextObject])) {
    companyId = [one objectForKey:@"companyId"];
    
    if ((company = [_idToPersons objectForKey:companyId]))
      ; // assignment is person
    else if ((company = [idToTeams objectForKey:companyId])) {
      // assignment is team
      if (![company isKindOfClass:[NSMutableDictionary class]])
        company = [[company mutableCopy] autorelease];
      
      if (_memberMap != nil) {
        [self _mapMembers:_memberMap
              outOfPersons:_idToPersons
              toTeam:company
              teamId:companyId];
      }
    }
    else {
      NSLog(@"WARNING[%s] didn't find company for assignment: %@",
            __PRETTY_FUNCTION__, one);
      NSLog(@"WARNING[%s] the company seems to not exist any more. ignoring.",
            __PRETTY_FUNCTION__);
      continue;
    }
    if ([one count] > 1)
      /* more than just companyId in assignment dict */
      [company addEntriesFromDictionary:one];

    /* now group that entry */
    [self _groupEntry:company intoGroup:group];
  }
  return group;
}

- (id)_plainResult:(NSArray *)_assignments
             teams:(NSArray *)_teams
           persons:(NSArray *)_personGIDs
         personMap:(NSDictionary *)_idToPersons
         memberMap:(NSDictionary *)_memberMap
{
  // no grouping
  // just the participants listed
  NSDictionary   *idToAssignment;
  NSMutableArray *allPersons;
  NSEnumerator   *e;

  id one;
  id assign;

  idToAssignment = [self mappedToCompanyId:_assignments];    
  allPersons     = [NSMutableArray array];
  // first the persons
  e = [_personGIDs objectEnumerator];
  while ((one = [e nextObject])) {
    one    = [one keyValues][0];
    assign = [idToAssignment objectForKey:one];
    one    = [_idToPersons objectForKey:one];
    if (one != nil) {
      if ([assign count] > 1) // more than companyId
        // add assignment entries like status and role
        [one addEntriesFromDictionary:assign];
      [allPersons addObject:one];
    }
  }
  // now the teams
  e = [_teams objectEnumerator];
  while ((one = [e nextObject])) {
    id teamId;
    // make mutable
    if (![one isKindOfClass:[NSMutableDictionary class]]) {
      one = [one mutableCopy];
      AUTORELEASE(one);
    }
    // get team id
    teamId = [one valueForKey:@"companyId"];
    // get assignment entry
    assign = [idToAssignment objectForKey:teamId];
    if ([assign count] > 1) // more than companyId
      // add assignment entries like status and role
      [one addEntriesFromDictionary:assign];

    if (_memberMap != nil) {
      [self _mapMembers:_memberMap
            outOfPersons:_idToPersons
            toTeam:one
            teamId:teamId];
    }
    [allPersons addObject:one];
  }

  [allPersons sortUsingFunction:compareParticipants context:self];

  return allPersons;
}

- (BOOL)_containsPersonAttributes:(NSArray *)_attrs {
  return [[self _checkAttributes:_attrs
                maxAttributes:[LSListParticipantsCommand personAttributes]
                entity:nil subKey:nil] count] > 0 ? YES : NO;
}
- (BOOL)_containsTeamAttributes:(NSArray *)_attrs {
  return [[self _checkAttributes:_attrs
                maxAttributes:[LSListParticipantsCommand teamAttributes]
                entity:nil subKey:nil] count] > 0 ? YES : NO;
}

- (void)_executeInContext:(id)_context {
  /* TODO: split up method */
  NSArray        *assignments;
  NSArray        *participantIds;
  NSArray        *teams;
  NSArray        *persons;
  NSArray        *allPersons;
  // members mapped to team gid
  NSDictionary   *memberMap   = nil;
  NSDictionary   *idToPersons = nil;

  BOOL           fetchMembers = NO;
  BOOL           needExtraAttributes = NO;

  if (![self->dateIds count]) {
    if ([self->groupBy length]) {
      [self setReturnValue:[NSDictionary dictionary]];
    }
    else {
      [self setReturnValue:[NSArray array]];
    }
    return;
  }

  if ((self->attributes == nil) ||
      ([self->attributes containsObject:@"team.members"]))
    fetchMembers = YES;
  
  /* first fetch the assignments */
  assignments = [self fetchCompanyDateAssignments:self->attributes];

  /* special case: no extra attributes (teams/persons/enterprises requested)*/
    
  if (fetchMembers)
    needExtraAttributes = YES;
  else if ([self _containsPersonAttributes:self->attributes]) {
    /* need person/enterprise attributes */
    needExtraAttributes = YES;
  }
  else if ([self _containsTeamAttributes:self->attributes])
    /* need team attributes */
    needExtraAttributes = YES;

  if (!needExtraAttributes) {
    // don't need any extra attributes, so return just the
    // dateCompanyAssignments
      
    // TODO: support grouping here
    [self setReturnValue:assignments];
    return; /* special case match */
  }
  
  /* extract participant ids */
  participantIds = [assignments valueForKey:@"companyId"];
  
  /* get the assigned teams */
  teams   = [self teamsForParticipantIds:participantIds
                  attributes:self->attributes];
  /* get the assigned person gids */
  persons = [self personGIDsForParticipantIds:participantIds];
  
  /* get the members of the teams */
  if (([teams count] > 0) && fetchMembers) {
    NSMutableArray *maPers;

    maPers = [[persons mutableCopy] autorelease];
    [self _fetchTeamMembers:teams
          memberMap:&memberMap
          allPersons:maPers
          inContext:_context];
    allPersons = maPers;
  }
  else {
    allPersons = persons;
  }

  /* now fetch all data for the persons */
  if ([allPersons count] > 0) {
    NSArray *allp;
    allp        = [self _fetchAllPersonsForGIDs:allPersons inContext:_context];
    idToPersons = [self mappedToCompanyId:allp];

    // fetch enterprises for persons
    if ([self->attributes containsObject:@"person.enterprises"]) {
      [self _fetchEnterprisesForPersonGIDs:allPersons
            persons:allp
            inContext:_context];
    }
  }

  if ([self->groupBy length]) {
    [self setReturnValue:[self _groupResult:assignments
                               teams:teams
                               personMap:idToPersons
                               memberMap:memberMap]];
  }

  else {
    [self setReturnValue:[self _plainResult:assignments
                               teams:teams
                               persons:persons
                               personMap:idToPersons
                               memberMap:memberMap]];
  }
}

/* record initializer */

- (NSString *)entityName {
  return @"Date";
}

/* key/value coding */

- (void)setDateIds:(NSArray *)_dateIds {
  ASSIGN(self->dateIds,_dateIds);
}

- (void)setDateId:(id)_dateId {
  [self setDateIds:[NSArray arrayWithObject:_dateId]];
}

- (void)setGlobalIDs:(NSArray *)_gids {
  unsigned       i, max;
  NSMutableArray *ma;
  id             gid;
  
  max = [_gids count];
  ma  = [NSMutableArray arrayWithCapacity:[_gids count]];
  for (i = 0; i < max; i++) {
    gid = [_gids objectAtIndex:i];
    [ma addObject:[(EOKeyGlobalID *)gid keyValues][0]];
  }
  [self setDateIds:ma];
}

- (void)setGlobalID:(id)_gid {
  [self setDateId:[(EOKeyGlobalID *)_gid keyValues][0]];
}

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] ||
      [_key isEqualToString:@"date"]   ||
      [_key isEqualToString:@"appointment"]) {
    [self setDateId:[_value valueForKey:@"dateId"]];
    return;
  }
  if ([_key isEqualToString:@"objects"] ||
      [_key isEqualToString:@"dates"]   ||
      [_key isEqualToString:@"appointments"]) {
    [self setDateIds:[_value valueForKey:@"dateId"]];
    return;
  }
  if ([_key isEqualToString:@"dateId"]) {
    [self setDateId:_value];
    return;
  }
  if ([_key isEqualToString:@"dateIds"]) {
    [self setDateIds:_value];
    return;
  }
  if ([_key isEqualToString:@"gid"]) {
    [self setGlobalID:_value];
    return;
  }
  if ([_key isEqualToString:@"gids"]) {
    [self setGlobalIDs:_value];
    return;
  }
  if ([_key isEqualToString:@"attributes"]) {
    ASSIGN(self->attributes,_value);
    return;
  }
  if ([_key isEqualToString:@"groupBy"]) {
    ASSIGN(self->groupBy,_value);
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"dateId"])
    return [self->dateIds lastObject];
  if ([_key isEqualToString:@"dateIds"])
    return self->dateIds;
  if ([_key isEqualToString:@"attributes"])
    return self->attributes;
  if ([_key isEqualToString:@"groupBy"])
    return self->groupBy;
  
  return [super valueForKey:_key];
}

@end /* LSListParticipantsCommand */

static int compareParticipants(id part1, id part2, void *context) {
  BOOL     part1IsTeam;
  BOOL     part2IsTeam;
  NSString *name1      = nil;
  NSString *name2      = nil;
  
  part1IsTeam = [[part1 valueForKey:@"isTeam"] boolValue];
  part2IsTeam = [[part2 valueForKey:@"isTeam"] boolValue];
  if (part1IsTeam != part2IsTeam)
    return part2IsTeam ? -1 : 1;
  
  if (part1IsTeam) {
    if ((name1 = [part1 valueForKey:@"description"]) == nil) name1 = @"";
    if ((name2 = [part2 valueForKey:@"description"]) == nil) name2 = @"";
  }
  else {
    if ((name1 = [part1 valueForKey:@"name"]) == nil) name1 = @"";
    if ((name2 = [part2 valueForKey:@"name"]) == nil) name2 = @"";
  }
  return [name1 compare:name2];    
}