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

#include "SkyJobQualifier.h"
#include "common.h"

@interface SkyJobQualifier(PrivateMethods)
- (void)_initWithArgumentsDictionary:(NSDictionary *)_arguments;
@end /* SkyJobQualifier(PrivateMethods) */

@implementation SkyJobQualifier

- (id)initWithMethodName:(NSString *)_methodName
  arguments:(NSDictionary *)_arguments
{
  if ((self = [super init])) {
    self->methodName = [_methodName copy];
    self->sortDescending = YES;
    self->showMyGroups = NO;
    self->isTeamSelected = NO;
    self->useListAttributes = YES;
    self->withCreator = NO;

    if (_arguments != nil)
      [self _initWithArgumentsDictionary:_arguments];
  }
  return self;
}

+ (SkyJobQualifier *)qualifierForMethodName:(NSString *)_methodName
  arguments:(NSDictionary *)_arguments
{
  return AUTORELEASE([[SkyJobQualifier alloc] initWithMethodName:_methodName
                                              arguments:_arguments]);
}

- (id)initWithMethodName:(NSString *)_methodName {
  return [self initWithMethodName:_methodName arguments:nil];
}

- (id)init {
  return [self initWithMethodName:nil arguments:nil];
}

- (void)dealloc {
  RELEASE(self->methodName);
  RELEASE(self->query);
  RELEASE(self->personURL);
  RELEASE(self->teamId);
  RELEASE(self->timeSelection);
  RELEASE(self->sortKey);

  [super dealloc];
}

- (void)_initWithArgumentsDictionary:(NSDictionary *)_arguments {
  NSString *tmp;
  
  if ((tmp = [_arguments valueForKey:@"query"]) != nil)
    [self setQuery:tmp];

  if ((tmp = [_arguments valueForKey:@"personURL"]) != nil)
    [self setPersonURL:tmp];

  if ((tmp = [_arguments valueForKey:@"teamId"]) != nil)
    [self setTeamId:tmp];

  if ((tmp = [_arguments valueForKey:@"timeSelection"]) != nil)
    [self setTimeSelection:tmp];

  if ((tmp = [_arguments valueForKey:@"sortKey"]) != nil)
    [self setSortKey:tmp];

  if ((tmp = [_arguments valueForKey:@"sortDescending"]) != nil)
    [self setSortDescending:[tmp boolValue]];

  if ((tmp = [_arguments valueForKey:@"showGroups"]) != nil)
    [self setShowMyGroups:[tmp boolValue]];  

  if ((tmp = [_arguments valueForKey:@"isTeamSelected"]) != nil)
    [self setIsTeamSelected:[tmp boolValue]];  

  if ((tmp = [_arguments valueForKey:@"withCreator"]) != nil)
    [self setWithCreator:[tmp boolValue]];    

  if ((tmp = [_arguments valueForKey:@"useListAttributes"]) != nil)
    [self setUseListAttributes:[tmp boolValue]];  
}

/* accessors */

- (NSString *)methodName {
  return self->methodName;
}

- (NSString *)query {
  return self->query;
}
- (void)setQuery:(NSString *)_query {
  ASSIGNCOPY(self->query, _query);
}

- (NSString *)personURL {
  return self->personURL;
}
- (void)setPersonURL:(NSString *)_personURL {
  if ([_personURL isKindOfClass:[NSNumber class]]) {
    _personURL = [NSString stringWithFormat:@"%d", [_personURL intValue]];
  }

  ASSIGNCOPY(self->personURL, _personURL);
}

- (NSString *)timeSelection {
  return self->timeSelection;
}
- (void)setTimeSelection:(NSString *)_timeSelection {
  ASSIGNCOPY(self->timeSelection, _timeSelection);
}

- (NSString *)teamId {
  return self->teamId;
}
- (void)setTeamId:(NSString *)_teamId {
  ASSIGNCOPY(self->teamId, _teamId);
}

- (NSString *)sortKey {
  return self->sortKey;
}
- (void)setSortKey:(NSString *)_sortKey {
  ASSIGNCOPY(self->sortKey, _sortKey);
}

- (BOOL)sortDescending {
  return self->sortDescending;
}
- (void)setSortDescending:(BOOL)_sortDescending {
  self->sortDescending = _sortDescending;
}

- (BOOL)showMyGroups {
  return self->showMyGroups;
}
- (void)setShowMyGroups:(BOOL)_showMyGroups {
  self->showMyGroups = _showMyGroups;
}

- (BOOL)isTeamSelected {
  return self->isTeamSelected;
}
- (void)setIsTeamSelected:(BOOL)_teamSelected {
  self->isTeamSelected = _teamSelected;
}

- (BOOL)withCreator {
  return self->withCreator;
}
- (void)setWithCreator:(BOOL)_creator {
  self->withCreator = _creator;
}

- (BOOL)useListAttributes {
  return self->useListAttributes;
}
- (void)setUseListAttributes:(BOOL)_listAttrs {
  self->useListAttributes = _listAttrs;
}

@end /* SkyJobQualifier */
