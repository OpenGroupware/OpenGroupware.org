/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include <OGoFoundation/SkyEditorPage.h>

@class NSArray;

@interface SkyJobAttributesEditor : SkyEditorPage
{
  id      item;
  id      patternName;
  NSArray *attributes;
}

@end /* SkyJobAttributesEditor */

#include <OGoJobs/SkyJobDocument.h>
#include <OGoJobs/SkyPersonJobDataSource.h>
#include "common.h"

@interface SkyJobAttributesEditor(PrivateMethodes)
- (NSString *)_violatedUniqueKeyName;
@end /* SkyJobAttributesEditor(PrivateMethodes) */

@implementation SkyJobAttributesEditor

static NSArray  *sensitivities = nil;
static NSArray  *percentages   = nil;
static NSArray  *priorities    = nil;
static NSNumber *yesNum        = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;

  yesNum = [[NSNumber numberWithBool:YES] retain];

  sensitivities = [[ud arrayForKey:@"JobAttrsEditor_sensitivities"] copy];
  percentages   = [[ud arrayForKey:@"JobAttrsEditor_percentages"]   copy];
  priorities    = [[ud arrayForKey:@"JobAttrsEditor_priorities"]   copy];
}

- (void)dealloc {
  [self->item        release];
  [self->patternName release];
  [self->attributes  release];
  [super dealloc];
}

/* activation */

- (void)_fetchDocument:(id)_eo {
  LSCommandContext       *ctx;
  SkyPersonJobDataSource *ds;
  SkyJobDocument *doc;

  ctx = (id)[[self session] commandContext];
  ds = [(SkyPersonJobDataSource *)[SkyPersonJobDataSource alloc] 
				  initWithContext:ctx];
    
  doc = [[SkyJobDocument alloc] initWithJob:_eo globalID:[_eo globalID]
				dataSource:ds];
  [ds release]; ds = nil;
  
  if (doc != nil)
    [self setObject:doc];
  [doc release];
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(id)_cfg
{
  BOOL r;

  r = [super prepareForActivationCommand:_command
             type:_type configuration:_cfg];
  if (!r) return NO;

  if ([[self object] isKindOfClass:[SkyDocument class]])
    return YES;
  
  [self _fetchDocument:[self object]];
  return YES;
}

/* accessors */

- (id)job {
  return [self object];
}

- (void)setItem:(NSString *)_item {
  ASSIGN(self->item,_item);
}
- (NSString *)item {
  return self->item;
}

- (void)setAttributes:(NSArray *)_attrs {
  ASSIGN(self->attributes, _attrs);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setPatternName:(id)_pattern {
  NSUserDefaults *ud;
  NSMutableArray *pats;
  NSEnumerator   *patEnum;
  NSString       *pat;

  if (_pattern == nil) return;

  ASSIGN(self->patternName, _pattern);

  ud      = [[self session] userDefaults];
  patEnum = [[[ud dictionaryForKey:@"jobs_view_attributes"]
                  objectForKey:_pattern] objectEnumerator];

  pats    = [NSMutableArray arrayWithObjects:
                            @"name", @"startDate", @"endDate", nil];

  while ((pat = [patEnum nextObject]))
    [pats addObject:pat];

  [self setAttributes:pats];
}
- (id)patternName {
  return self->patternName;
}

- (BOOL)checkConstraintsForSave {
  [self setErrorString:nil];
  return [super checkConstraintsForSave];
}

- (id)save {
  NSString *key   = nil;
  id       result = nil;

  result = [super save];
  
  if (result)
    return result;
  else if ((key = [self _violatedUniqueKeyName])) {
    NSMutableString *str;

    str = [[NSMutableString alloc] initWithCapacity:128];

    [str appendString:[[self labels] valueForKey:@"couldNotSaveJob"]];
    [str appendString:@". "];
    [str appendString:[[self labels] valueForKey:@"fieldMustBeUnique"]];
    [str appendString:@": "];
    [str appendString:[[self labels] valueForKey:key]];
    
    return nil;
  }
  return nil;
}

/* wod labels, etc. */

- (NSArray *)sensitivities {
  return sensitivities;
}

- (NSString *)sensitivity {
  return [[self labels] valueForKey:
                        [NSString stringWithFormat:@"sensitivity_%@", item]];
}

- (NSArray *)percentList {
  NSMutableArray *pList;
  int jobPercent;
  
  jobPercent = [[[self job] valueForKey:@"percentComplete"] intValue];
  if ((jobPercent % 10) == 0)
    return percentages;
  
  /* this is a non-standard percentage, insert it */
  pList = [[percentages mutableCopy] autorelease];
  [pList addObject:[NSNumber numberWithInt:jobPercent]];
  return [pList sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)priorities {
  return priorities;
}

- (NSString *)priorityName {
  NSString *pri;

  pri = [NSString stringWithFormat:@"priority_%d", [self->item intValue]];
  pri = [[self labels] valueForKey:pri];
  if (pri != nil)
    return pri;

  return [self->item stringValue];
}

- (BOOL)showPriority {
  return [[self attributes] containsObject:@"priority"];
}
- (BOOL)showSensitivity {
  return [[self attributes] containsObject:@"sensitivity"];
}
- (BOOL)showPercentComplete {
  return [[self attributes] containsObject:@"percentComplete"];
}

/* privates */

- (BOOL)_isKeyViolated:(NSString *)_key {
  static id searchRec = nil;  
  NSArray   *list     = nil;
  unsigned  maxCount;

  maxCount = ([self isInNewMode]) ? 0 : 1;

  if (searchRec == nil) {
    searchRec = [self runCommand:@"search::newrecord",
                      @"entity", @"Job", nil];
    [searchRec setComparator:@"EQUAL"];
    [searchRec retain];
  }
  
  [searchRec takeValue:[[self object] valueForKey:_key] forKey:_key];
  list = [self runCommand:@"job::extended-search",
               @"operator",       @"OR",
               @"searchRecords",  [NSArray arrayWithObject:searchRec],
               @"fetchIds",       yesNum,
               @"maxSearchCount", [NSNumber numberWithInt:2],
               nil];
  
  return ([list count] > maxCount) ? YES : NO;
}

- (NSString *)_violatedUniqueKeyName {
  if ([self _isKeyViolated:@"number"])
    return @"number";
  if ([self _isKeyViolated:@"name"])
    return @"name";
  
  return nil;
}

@end /* SkyJobAttributesEditor */
