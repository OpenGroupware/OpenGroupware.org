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

#include <OGoFoundation/OGoComponent.h>

/*
  This component generates a PopUp containing groups and accounts. It should
  be extended to allow any kind of person.

    Input parameters:

      showAccount     - should include the login account in the list
      showTeams       - should include the teams in the list
      showSearchField - add ability to search for persons
      fetchGlobalIDs  - work with EOGlobalIDs
      onChange        - JavaScript to execute in the PopUp's onChange attribute

    In/Output parameters:
      
      selectedCompany  - the company which was selected by the user
    
    Output parameters:
      
      selectedGlobalID - the gid of the company which was selected by the user
*/

@interface SkyPersonSelectPopUp : OGoComponent
{
  id       selectedCompany;
  BOOL     fetchGlobalIDs;
  
  /* temporary state */
  NSArray  *visibleCompanies;
  id       item;
  NSString *searchPerson;
}

@end

#include "common.h"

static NSComparisonResult compareParticipants(id part1, id part2, void *context);

@implementation SkyPersonSelectPopUp

static NSArray *teamCoreAttrs = nil;

+ (void)initialize {
  if (teamCoreAttrs == nil) {
      id objs[4];
      objs[0] = @"companyId";
      objs[1] = @"description";
      objs[2] = @"globalID";
      objs[3] = @"isTeam";
      
      teamCoreAttrs = [[NSArray alloc] initWithObjects:objs count:4];
  }
}

- (void)dealloc {
  [self->searchPerson     release];
  [self->selectedCompany  release];
  [self->item             release];
  [self->visibleCompanies release];
  [super dealloc];
}

/* component sync */

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

/* accessors */

- (void)setSelectedCompany:(id)_company {
  ASSIGN(self->selectedCompany, _company);
  
  [self setValue:_company
        forBinding:@"selectedCompany"];
  [self setValue:[_company valueForKey:@"globalID"]
        forBinding:@"selectedGlobalID"];
}
- (id)selectedCompany {
  return self->selectedCompany;
}

- (NSArray *)visibleCompanies {
  return self->visibleCompanies;
}

- (void)setSearchPerson:(NSString *)_searchPerson {
  ASSIGNCOPY(self->searchPerson, _searchPerson);
}
- (NSString *)searchPerson {
  return self->searchPerson;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)itemLabel {
  NSString *fd;
  NSString *d;
  
  if ([[self->item valueForKey:@"isTeam"] boolValue]) 
    return [self->item valueForKey:@"description"];
  
  if ((d = [self->item valueForKey:@"name"]) == nil)
    return [self->item valueForKey:@"login"];
  
  fd = [self->item valueForKey:@"firstname"];
  if ([fd isNotNull])
    d = [NSString stringWithFormat:@"%@, %@", d, fd];
  
  return d;
}

/* processing */

- (NSArray *)_getTeams {
  NSArray *teams;
  
  teams = [self runCommand:@"team::get-all",
                  @"fetchGlobalIDs",
                  [NSNumber numberWithBool:self->fetchGlobalIDs],
                  nil];
  if (self->fetchGlobalIDs) {
    teams = [self runCommand:@"team::get-by-globalid",
                    @"gids",       teams,
                    @"attributes", teamCoreAttrs,
		  nil];
  }
  return teams;
}

- (void)_buildCompanyList {
  NSMutableArray *array;
  BOOL showAccount;
  BOOL showTeams;
  
  showAccount = [[self valueForBinding:@"showAccount"] boolValue];
  showTeams   = [[self valueForBinding:@"showTeams"]   boolValue];
  
  array = [[NSMutableArray alloc] init];
  
  if (showAccount)
    [array addObject:[(id)[self session] activeAccount]];
  
  if (showTeams)
    [array addObjectsFromArray:[self _getTeams]];
  
  [array sortUsingFunction:compareParticipants context:self];
  
  [self->visibleCompanies release]; self->visibleCompanies = nil;
  self->visibleCompanies = [array copy];
  [array release]; array = nil;
  
  if ([self selectedCompany] == nil)
    [self setSelectedCompany:[(id)[self session] activeAccount]];
}

- (void)personSearch {
  NSArray      *result;
  NSMutableSet *array;
  BOOL showAccount;
  BOOL showTeams;
  
  if (self->searchPerson == nil)
    return;
    
  result = [self runCommand:
                     @"person::extended-search",
                     @"operator",       @"OR",
                     @"name",           self->searchPerson,
                     @"firstname",      self->searchPerson,
                     @"description",    self->searchPerson,
                     @"login",          self->searchPerson,
                     @"maxSearchCount", [NSNumber numberWithInt:50],
                     nil];
    
  if ([result count] == 0)
    return;

  /* postprocess results */
      
  [self->visibleCompanies release]; self->visibleCompanies = nil;

  showAccount = [[self valueForBinding:@"showAccount"] boolValue];
  showTeams   = [[self valueForBinding:@"showTeams"] boolValue];
  
  array = [[NSMutableSet alloc] initWithCapacity:16];
      
  if (showAccount)
    [array addObject:[(id)[self session] activeAccount]];
      
  [array addObjectsFromArray:result];
      
  if (showTeams)
    [array addObjectsFromArray:[self _getTeams]];

  self->visibleCompanies =
    [[[array allObjects]
                 sortedArrayUsingFunction:compareParticipants context:self]
                 copy];
  [array release]; array = nil;

  [self setSelectedCompany:[result objectAtIndex:0]];
}

/* notifications */

- (void)reconfigure {
  id company;
  
  self->fetchGlobalIDs = [[self valueForBinding:@"fetchGlobalIDs"] boolValue];
  
  if ((company = [self valueForBinding:@"selectedCompany"]))
    ASSIGN(self->selectedCompany, company);
  
  if (self->visibleCompanies == nil)
    [self _buildCompanyList];
}

- (void)syncAwake {
  [self reconfigure];
  [super syncAwake];
}

- (void)sleep {
  [self->item release]; self->item = nil;
  [super sleep];
}

/* catch nil-assignments to selected-company */

- (void)takeValuesFromRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  [super takeValuesFromRequest:_request inContext:_ctx];
  
  if ([self->searchPerson length] > 0) {
    [self personSearch];
    [self setSearchPerson:nil];
  }
  else if ([self selectedCompany] == nil)
    [self setSelectedCompany:[(id)[self session] activeAccount]];
}

@end /* SkyPersonSelectPopUp */

// TODO: move to some generic file?
static NSComparisonResult compareParticipants(id part1, id part2, void *context) 
{
  BOOL     part1IsTeam;
  BOOL     part2IsTeam;
  NSString *name1 = nil;
  NSString *name2 = nil;

  part1IsTeam = [[part1 valueForKey:@"isTeam"] boolValue];
  part2IsTeam = [[part2 valueForKey:@"isTeam"] boolValue];
  
  if (part1IsTeam != part2IsTeam)
    return part2IsTeam ? -1 : 1;
  
  if (part1IsTeam) {
    name1 = [part1 valueForKey:@"description"];
    name2 = [part2 valueForKey:@"description"];

    if (name1 == nil) name1 = @"";
    if (name2 == nil) name2 = @"";
  }
  else {
    NSString *fname1 = nil;
    NSString *fname2 = nil;
    
    name1  = [part1 valueForKey:@"name"];
    name2  = [part2 valueForKey:@"name"];
    fname1 = [part1 valueForKey:@"firstname"];
    fname2 = [part2 valueForKey:@"firstname"];

    if (name1 == nil) name1 = @"";
    if (name2 == nil) name2 = @"";
    if (fname1 == nil) name1 = @"";
    if (fname2 == nil) name2 = @"";

    name1 = [NSString stringWithFormat:@"%@ %@", name1, fname1];
    name2 = [NSString stringWithFormat:@"%@ %@", name2, fname2];
  }
  return [name1 caseInsensitiveCompare:name2];    
}
