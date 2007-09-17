/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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
  appointment::list-participants
  
  Fetch participants, resolveTeams and fetch enterprises for appointment
  attendee rows (DateCompanyAssignment table).
 
  Returns an array of participants (person and team dictionaries)
  team members are resolved, being dictionaries too

  BUG:
    Currently this only works properly with grouping or one appointment.

  Note: one often wants to use "groupBy: dateId", otherwise you get a plain
        array of entries.
        An "groupBy: companyId" might be interesting as well.
        
  accepts:
  attributes:
    dateCompanyAssignmentId
    companyId
    dateId
    partStatus
    role
    comment
    rsvp
 
    team.companyId
    team.description
    team.isTeam
    team.email
 
    team.members
 
    person.companyId
    person.globalID
    person.firstname
    person.extendedAttributes
    person.telephones
    person.name
    person.salutation
    person.degree
    person.isPrivate
    person.ownerId
 
    person.enterprises
                      
    enterprises.description
    enterprises.companyId
    enterprises.globalID
 
  dateId
  dateIds
  gid
  gids
 
  groupBy
*/

// TODO: needs more cleanup
// TODO: should check for apt permissions?

#include <LSFoundation/LSDBObjectBaseCommand.h>

@interface LSListParticipantsCommand : LSDBObjectBaseCommand
{
  NSArray  *dateIds;
  NSArray  *attributes;
  NSString *groupBy;
  struct {
    int listCSVResources:1;
    int reserved:31;
  } llpcFlags;
}

- (NSArray *)globalIDs;

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
static NSString *defaultPartStatus = nil; // ACCEPTED or NEEDS-ACTION?

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  yesNum = [[NSNumber numberWithBool:YES] retain];

  dateCompanyAssignmentAttributes =
    [[NSArray alloc] initWithObjects:
                       @"dateCompanyAssignmentId",
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
  // TODO: remove method if this is not overridden somewhere
  return dateCompanyAssignmentAttributes;
}
+ (NSArray *)teamAttributes {
  // TODO: remove method if this is not overridden somewhere
  return teamAttributes;
}
+ (NSArray *)personAttributes {
  // TODO: remove method if this is not overridden somewhere
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
  
  if (![_attributes isNotEmpty]) _attributes = _maxAttr;
  
  e = [_attributes objectEnumerator];
  ma = [NSMutableArray arrayWithCapacity:16];
  // go thru' the requested attributes
  // and filter those defined in _maxAttr
  
  while ((one = [e nextObject]) != nil) {
    if (_subKey != nil) {
      // key must have a prefix (i.e.: 'team.')
      if (![one hasPrefix:_subKey]) continue;
    }
    if ([_maxAttr containsObject:one]) {
      // key allowed
      if (_subKey != nil) one = [one substringFromIndex:[_subKey length]];
      if (_entity != nil) {
        /* create a proper EOAttribute */
	EOAttribute *a;

	if ((a = [_entity attributeNamed:one]) == nil) {
	  [self errorWithFormat:
		  @"did not find attribute in entity %@: '%@'",
		  _entity, one];
	}
	else
	  [ma addObject:a];
      }
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

  if ([in isNotEmpty])
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
  while ((in = [inEnum nextObject]) != nil) {
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

    while ((one = [channel fetchAttributes:_attributes withZone:NULL]) != nil)
      [ma addObject:one];
    
    [qual release]; qual = nil;
  }
  
  return ma;
}

- (NSDictionary *)mappedToCompanyId:(NSArray *)_ar {
  // TODO: move to an NSArray category? (maybe already in NGExt?)
  NSMutableDictionary *md;
  NSEnumerator *e;
  id           one;
  
  md = [NSMutableDictionary dictionaryWithCapacity:[_ar count]];
  e  = [_ar objectEnumerator];
  
  while ((one = [e nextObject]) != nil) {
    NSNumber *key;
    
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
  if (![in isNotEmpty]) {
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
  if (![_attributes isNotEmpty])
    // no team attributes requested
    return nil;
  
  ok = [channel selectAttributes:_attributes 
                describedByQualifier:qual
                fetchOrder:nil lock:NO];
  [self assert:ok reason:[sybaseMessages description]];

  ma = [NSMutableArray arrayWithCapacity:16];
  while ((one = [channel fetchAttributes:_attributes withZone:NULL]) != nil)
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
  if (![in isNotEmpty]) {
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
  NSEnumerator  *e;
  EOKeyGlobalID *tGID;
  
  (*_memberMap) =
    [self memberGIDsForTeamsIds:[_teams valueForKey:@"companyId"]
          context:_context];
  
  e = [(*_memberMap) keyEnumerator];
  while ((tGID = [e nextObject]) != nil) {
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
  NSDictionary   *pgidToEgids;
  NSEnumerator   *e;
  NSMutableArray *allEnterprises;
  NSDictionary   *id2Enterprise;
  NSArray        *pAttributes;

  tmp = LSRunCommandV(_context, @"person", @"enterprises",
                      @"persons",        _personGIDs,
                      @"fetchGlobalIDs", yesNum,
                      nil);
  
  if ([_personGIDs count] == 1) {
    pgidToEgids = [NSDictionary dictionaryWithObject:tmp
                                forKey:[_personGIDs lastObject]];
  }
  else
    pgidToEgids = tmp;

  e              = [pgidToEgids keyEnumerator];
  allEnterprises = [NSMutableArray arrayWithCapacity:8];
  while ((tmp = [e nextObject]) != nil)
    [allEnterprises addObjectsFromArray:[pgidToEgids objectForKey:tmp]];
  
  /* now 'allEnterprises' contains all gids of the enterprises */
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
  while ((tmp = [e nextObject]) != nil) {
    NSMutableArray *ma;
    NSEnumerator   *ee;
    EOKeyGlobalID  *gid;
    id entps;
    
    gid   = [tmp valueForKey:@"globalID"];
    entps = [pgidToEgids objectForKey:gid];
    ma    = [NSMutableArray arrayWithCapacity:8];
    ee    = [entps objectEnumerator];
    
    while ((gid = [ee nextObject]) != nil) {
      id tmp;

      tmp = [gid keyValues][0];
      tmp = [id2Enterprise objectForKey:tmp];
      
      if (tmp != nil)
        [ma addObject:tmp];
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
  /* called by -_groupResult..., maintains the entries in a grouping dict */
  NSString       *key;
  NSMutableArray *gr;
  
  if ((key = [_entry objectForKey:self->groupBy]) == nil) {
    // TODO: set some error status / return an exception?
    [self errorWithFormat:@"Invalid groupBy key: '%@'", self->groupBy];
    return;
  }
  
  if ((gr = [_dict objectForKey:key]) != nil) {
    /* group already exists, add record */
    [gr addObject:_entry];
    return;
  }

  /* create new group */
  gr = [[NSMutableArray alloc] initWithCapacity:8];
  [gr addObject:_entry];
  [_dict setObject:gr forKey:key];
  [gr release]; gr = nil;
}

- (void)fixupPartInfoInEntry:(NSMutableDictionary *)_entry {
  id tmp;
  
  /* fixup defaults (Note: the two if's are _intentional_!) */
  if ((tmp = [_entry objectForKey:@"partStatus"]) != nil &&
        defaultPartStatus != nil) {
      if (![tmp isNotNull])
        [_entry setObject:defaultPartStatus forKey:@"partStatus"];
  }
  if ((tmp = [_entry objectForKey:@"role"]) != nil) {
      if (![tmp isNotNull])
        [_entry setObject:@"REQ-PARTICIPANT" forKey:@"role"];
  }
}

- (NSDictionary *)fillEntry:(NSMutableDictionary *)_entry
  withCompany:(NSDictionary *)_company andAssignment:(NSDictionary *)_assi
{
  [_entry removeAllObjects];

  /* add information fetched for person/team */
  
  if ([_company isKindOfClass:[NSDictionary class]])
    [_entry addEntriesFromDictionary:_company];
  else {
      // TODO: this might happen if no attrs are given?
    [self warnWithFormat:
            @"Given company object is not a dictionary: %@",
            _company];
    [_entry setObject:_company forKey:@"company"];
  }

  /* add participation information (role/status) */
  
  if ([_assi count] > 1) {
    /* len=1, we already checked the companyId? */
    [_entry addEntriesFromDictionary:_assi];
    [self fixupPartInfoInEntry:_entry];
  }
  
  return [_entry copy];
}

- (id)_groupResult:(NSArray *)_assignments
  teams:(NSArray *)_teams
  personMap:(NSDictionary *)_idToPersons
  memberMap:(NSDictionary *)_memberMap
  resources:(NSArray *)_resources
{
  /*
    This is used if the 'groupBy' argument was used (otherwise _plainResu...).
    
    Duplicate participants may occur, so go through the assignments and not
    the persons and teams.
  */
  NSMutableDictionary *group, *mentry;
  NSDictionary        *idToTeams;
  NSEnumerator        *e;
  NSDictionary *assignmentRecord;
  
  group  = [NSMutableDictionary dictionaryWithCapacity:32];
  mentry = [[NSMutableDictionary alloc] initWithCapacity:16];
  
  idToTeams = [self mappedToCompanyId:_teams];
  
  e = [_assignments objectEnumerator];
  while ((assignmentRecord = [e nextObject]) != nil) {
    NSDictionary *entry;
    NSNumber *companyId;
    id company;
    
    companyId = [assignmentRecord objectForKey:@"companyId"];
    
    if ((company = [_idToPersons objectForKey:companyId]) != nil)
      ; // assignment is person
    else if ((company = [idToTeams objectForKey:companyId]) != nil) {
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
      [self warnWithFormat:
              @"%s: failed to resolve company for assignment "
	      @"(read protected?): %@",
            __PRETTY_FUNCTION__, assignmentRecord];
      continue;
    }
    
    /* build entry */
    
    entry = [self fillEntry:mentry 
                  withCompany:company andAssignment:assignmentRecord];
    [self _groupEntry:entry intoGroup:group];
    [entry release]; entry = nil;
  }
  [mentry release]; mentry = nil;
  
  /* add resources */
  
  e = [_resources objectEnumerator];
  while ((assignmentRecord = [e nextObject]) != nil)
    [self _groupEntry:assignmentRecord intoGroup:group];
  
  return group;
}

- (id)_plainResult:(NSArray *)_assignments
  teams:(NSArray *)_teams
  persons:(NSArray *)_personGIDs
  personMap:(NSDictionary *)_idToPersons
  memberMap:(NSDictionary *)_memberMap
{
  // TODO: add support for resources
  // TODO:
  //   This is broken for multiple appointments! It will reuse the same
  //   info record for all apts AND CAN LOOSE appointments.
  //   Probably we need to iterate over the assignments, not over the persons.
  // no grouping
  // just the participants listed
  NSMutableDictionary *mentry;
  NSDictionary   *idToAssignment;
  NSMutableArray *allPersons;
  NSEnumerator   *e;
  id one;
  id assign;

  idToAssignment = [self mappedToCompanyId:_assignments];    
  allPersons     = [NSMutableArray arrayWithCapacity:64];
  mentry         = [[NSMutableDictionary alloc] initWithCapacity:16];
  
  /* first the persons */
  e = [_personGIDs objectEnumerator];
  while ((one = [e nextObject]) != nil) {
    one    = [one keyValues][0];
    assign = [idToAssignment objectForKey:one];
    
    if ((one = [_idToPersons objectForKey:one]) == nil)
      continue;
    
    one = [self fillEntry:mentry withCompany:one andAssignment:assign];
    [allPersons addObject:one];
    [one release]; one = nil;
  }
  
  /* now the teams */
  e = [_teams objectEnumerator];
  while ((one = [e nextObject]) != nil) {
    NSNumber *teamId;
    
    /* make mutable */
    [mentry removeAllObjects];
    [mentry addEntriesFromDictionary:one];
    
    // get team id
    teamId = [mentry valueForKey:@"companyId"];
    // get assignment entry
    assign = [idToAssignment objectForKey:teamId];
    if ([assign count] > 1) // more than companyId
      // add assignment entries like status and role
      [mentry addEntriesFromDictionary:assign];

    if (_memberMap != nil) {
      [self _mapMembers:_memberMap
            outOfPersons:_idToPersons
            toTeam:mentry
            teamId:teamId];
    }

    one = [mentry copy];
    [allPersons addObject:one];
    [one release]; one = nil;
  }
  
  [mentry release]; mentry = nil;
  
  [allPersons sortUsingFunction:compareParticipants context:self];
  return allPersons;
}

- (BOOL)_containsPersonAttributes:(NSArray *)_attrs {
  return [[self _checkAttributes:_attrs
                maxAttributes:[LSListParticipantsCommand personAttributes]
                entity:nil subKey:nil] isNotEmpty];
}
- (BOOL)_containsTeamAttributes:(NSArray *)_attrs {
  return [[self _checkAttributes:_attrs
                maxAttributes:[LSListParticipantsCommand teamAttributes]
                entity:nil subKey:nil] isNotEmpty];
}

- (NSArray *)fetchResourceInfosInContext:(id)_ctx {
  static NSString *CSVResourceMarker = @", ";
  static NSArray *attrs = nil;
  NSMutableArray *results = nil;
  NSArray  *apts;
  unsigned i, count;
  
  if (attrs == nil) {
    attrs = [[NSArray alloc] initWithObjects:
                               @"dateId", @"globalID", @"resourceNames",
                               nil];
  }
  
  apts = [_ctx runCommand:@"appointment::get-by-globalid",
               @"gids", [self globalIDs],
               @"attributes", attrs,
               nil];
  count = [apts count];
  
  for (i = 0; i < count; i++) {
    NSDictionary *apt;
    unsigned j, jcount;
    id names;
    
    apt   = [apts objectAtIndex:i];
    names = [apt valueForKey:@"resourceNames"];
    if (![names isNotNull]) continue;
    
    if (results == nil)
      results = [NSMutableArray arrayWithCapacity:(count * 2)];
    
    names  = [names componentsSeparatedByString:CSVResourceMarker];
    jcount = [names count];
    
    for (j = 0; j < jcount; j++) {
      NSDictionary *rec;
      id keys[5];
      id values[5];
      
      keys[0] = @"dateId";       values[0] = [apt valueForKey:@"dateId"];
      keys[1] = @"partStatus";   values[1] = @"ACCEPTED";
      keys[2] = @"role";         values[2] = @"REQ-PARTICIPANT";
      keys[3] = @"resourceName"; values[3] = [names objectAtIndex:j];
      // TODO: should we also fetch the GID of the resource?
      
      rec = [[NSDictionary alloc] initWithObjects:values forKeys:keys
                                  count:4];
      [results addObject:rec];
      [rec release]; rec = nil;
    }
  }
  return results;
}

- (void)_executeInContext:(id)_context {
  /* TODO: split up method */
  NSArray        *resources;
  NSArray        *assignments;
  NSArray        *participantIds;
  NSArray        *teams;
  NSArray        *persons;
  NSArray        *allPersons;
  // members mapped to team gid
  NSDictionary   *teamGIDToMemberGIDs   = nil;
  NSDictionary   *idToPersons = nil;
  BOOL           fetchMembers = NO;
  BOOL           needExtraAttributes = NO;
  id result;
  
  if (![self->dateIds isNotEmpty]) {
    [self setReturnValue:[self->groupBy isNotEmpty]
            ? [NSDictionary dictionary] : [NSArray array]];
  }

  if ((self->attributes == nil) ||
      ([self->attributes containsObject:@"team.members"]))
    fetchMembers = YES;
  
  /* first fetch the assignments */
  
  assignments = [self fetchCompanyDateAssignments:self->attributes];

  /* then CSV resources when requested */

  resources = self->llpcFlags.listCSVResources
    ? [self fetchResourceInfosInContext:_context]
    : (NSArray *)nil;
  
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
    
    if (self->groupBy != nil) // TODO: support
      [self errorWithFormat:@"requested grouping, not applied!"];
    if (self->llpcFlags.listCSVResources) // TODO: support
      [self errorWithFormat:@"requested resources, not applied!"];
    
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
  
  if ([teams isNotEmpty] && fetchMembers) {
    NSMutableArray *maPers;
    
    maPers = [[persons mutableCopy] autorelease];

    /* this creates the teamGIDToMemberGIDs dictionary */
    [self _fetchTeamMembers:teams
          memberMap:&teamGIDToMemberGIDs
          allPersons:maPers /* filled with additional persons from the teams?*/
          inContext:_context];
    allPersons = maPers;
  }
  else {
    allPersons = persons;
  }

  /* now fetch all data for the persons */
  
  if ([allPersons isNotEmpty]) {
    NSArray *allp;
    
    allp        = [self _fetchAllPersonsForGIDs:allPersons inContext:_context];
    idToPersons = [self mappedToCompanyId:allp];
    
    /* fetch enterprises for persons */
    if ([self->attributes containsObject:@"person.enterprises"]) {
      [self _fetchEnterprisesForPersonGIDs:allPersons
            persons:allp
            inContext:_context];
    }
  }
  
  if ([self->groupBy isNotEmpty]) {
    result = [self _groupResult:assignments
                   teams:teams
                   personMap:idToPersons
                   memberMap:teamGIDToMemberGIDs
                   resources:resources];
  }
  else {
    if (self->llpcFlags.listCSVResources) // TODO: support
      [self errorWithFormat:@"requested resources, not applied!"];
    
    result = [self _plainResult:assignments
                   teams:teams
                   persons:persons
                   personMap:idToPersons
                   memberMap:teamGIDToMemberGIDs];
  }
  
  [self setReturnValue:result];
}


/* record initializer */

- (NSString *)entityName {
  return @"Date";
}

/* key/value coding */

- (void)setDateIds:(NSArray *)_dateIds {
  ASSIGNCOPY(self->dateIds,_dateIds);
}
- (void)setDateId:(id)_dateId {
  [self setDateIds:[NSArray arrayWithObject:_dateId]];
}

- (void)setGlobalIDs:(NSArray *)_gids {
  unsigned       i, max;
  NSMutableArray *ma;
  
  max = [_gids count];
  ma  = [NSMutableArray arrayWithCapacity:[_gids count]];
  for (i = 0; i < max; i++) {
    EOKeyGlobalID *gid;
    
    gid = [_gids objectAtIndex:i];
    [ma addObject:[gid keyValues][0]];
  }
  [self setDateIds:ma];
}
- (NSArray *)globalIDs {
  unsigned       i, max;
  NSMutableArray *ma;
  
  max = [self->dateIds count];
  ma  = [NSMutableArray arrayWithCapacity:max];
  for (i = 0; i < max; i++) {
    NSNumber *dateId;
    
    dateId = [self->dateIds objectAtIndex:i];
    [ma addObject:[EOKeyGlobalID globalIDWithEntityName:@"Date"
                                 keys:&dateId keyCount:1 zone:NULL]];
  }
  return ma;
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
  if ([_key isEqualToString:@"listCSVResources"]) {
    self->llpcFlags.listCSVResources = [_value boolValue] ? 1 : 0;
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
  if ([_key isEqualToString:@"listCSVResources"])
    return [NSNumber numberWithBool:self->llpcFlags.listCSVResources ?YES:NO];
  
  return [super valueForKey:_key];
}

@end /* LSListParticipantsCommand */


static int compareParticipants(id part1, id part2, void *context) {
  BOOL     part1IsTeam;
  BOOL     part2IsTeam;
  NSString *name1      = nil;
  NSString *name2      = nil;

  if (part1 == part2)
    return NSOrderedSame;
  
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
