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

#include <OGoPalm/SkyPalmJobDocument.h>
#include <OGoJobs/SkyJobDocument.h>
#include <OGoJobs/SkyPersonJobDataSource.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOKeyGlobalID.h>
#include <OGoPalm/SkyPalmConstants.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>

#include <NGExtensions/EODataSource+NGExtensions.h>

@interface SkyPalmEntryDataSource(SkyPalmJobDocument)
- (id)currentAccount;
@end

@implementation SkyPalmJobDocument

- (id)init {
  if ((self = [super init])) {
    self->description = nil;
    self->duedate     = nil;
    self->note        = nil;
    self->isCompleted = NO;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->description);
  RELEASE(self->duedate);
  RELEASE(self->note);
  [super dealloc];
}
#endif

//accessors
- (void)setDescription:(NSString *)_desc {
  ASSIGN(self->description,_desc);
}
- (NSString *)description {
  return self->description;
}

- (void)setDuedate:(NSCalendarDate *)_date {
  ASSIGN(self->duedate,_date);
}
- (NSCalendarDate *)duedate {
  return self->duedate;
}

- (void)setNote:(NSString *)_note {
  ASSIGN(self->note,_note);
}
- (NSString *)note {
  return self->note;
}

- (void)setPriority:(int)_pri {
  self->priority = _pri;
}
- (int)priority {
  return self->priority;
}

- (void)setIsCompleted:(BOOL)_flag {
  self->isCompleted = _flag;
}
- (BOOL)isCompleted {
  return self->isCompleted;
}

// additional
- (BOOL)isCompletable {
  if (![self isEditable])
    return NO;
  if ([self isCompleted])
    return NO;
  return YES;
}
- (BOOL)isUncompletable {
  if (![self isEditable])
    return NO;
  return [self isCompleted];
}
+ (NSString *)priorityStringForPriority:(int)_pri {
  static NSArray *ps = nil;

  if (ps == nil) {
    ps =
      [[NSArray alloc] initWithObjects:
                       @"",
                       @"pri_very_high",
                       @"pri_high",
                       @"pri_normal",
                       @"pri_low",
                       @"pri_very_low",
                       nil];
  }
  return [ps objectAtIndex:_pri];
}
- (NSString *)priorityString {
  return [SkyPalmJobDocument priorityStringForPriority:[self priority]];
}

// overwriting
- (NSMutableString *)_md5Source {
  NSMutableString *src = [NSMutableString stringWithCapacity:32];

  [src appendString:[self description]];
  [src appendString:
       [[self duedate] descriptionWithCalendarFormat:@"%Y-%m-%d"]];
  [src appendString:[self note]];
  [src appendString:
       [[NSNumber numberWithInt:[self priority]] stringValue]];
  [src appendString:
       [[NSNumber numberWithBool:[self isCompleted]] stringValue]];
  [src appendString:[super _md5Source]];
  return src;
}

- (void)takeValuesFromDictionary:(NSDictionary *)_dict {
  [self setDescription: [_dict valueForKey:@"description"]];
  [self setDuedate:     [_dict valueForKey:@"duedate"]];
  [self setNote:        [_dict valueForKey:@"note"]];
  [self setPriority:    [[_dict valueForKey:@"priority"] intValue]];
  [self setIsCompleted: [[_dict valueForKey:@"is_completed"] boolValue]];

  [super takeValuesFromDictionary:_dict];
}

- (NSMutableDictionary *)asDictionary {
  NSMutableDictionary *dict = [super asDictionary];

  [self _takeValue:self->description forKey:@"description" toDict:dict];
  if (([dict valueForKey:@"description"] == nil) ||
      ([[dict valueForKey:@"description"] length] == 0))
    [dict takeValue:@" " forKey:@"description"];
  [self _takeValue:self->duedate     forKey:@"duedate" toDict:dict];
  [self _takeValue:self->note        forKey:@"note" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->priority]
        forKey:@"priority" toDict:dict];
  [self _takeValue:[NSNumber numberWithBool:self->isCompleted]
        forKey:@"is_completed" toDict:dict];

  return dict;
}

- (void)takeValuesFromDocument:(SkyPalmDocument *)_doc {
  SkyPalmJobDocument *doc = (SkyPalmJobDocument *)_doc;
  [self setDescription:[doc description]];
  [self setDuedate:    [doc duedate]];
  [self setNote:       [doc note]];
  [self setPriority:   [doc priority]];
  [self setIsCompleted:[doc isCompleted]];

  [super takeValuesFromDocument:_doc];
}

- (void)prepareAsNew {
  [super prepareAsNew];

  [self setPriority:3];
}
- (NSString *)insertNotificationName {
  return SkyNewPalmJobNotification;
}
- (NSString *)updateNotificationName {
  return SkyUpdatedPalmJobNotification;
}
- (NSString *)deleteNotificationName {
  return SkyDeletedPalmJobNotification;
}

// actions
- (id)completeJob {
  if (![self isCompletable])
    return [NSString stringWithFormat:
                     @"Document '%@' not completable in this state",
                     [self description]];

  [self setIsCompleted:YES];
  self->isSaved = NO;
  return [self save];
}
- (id)uncompleteJob {
  if (![self isUncompletable])
    return [NSString stringWithFormat:
                     @"Document '%@' not uncompletable in this state",
                     [self description]];

  [self setIsCompleted:NO];
  self->isSaved = NO;
  return [self save];
}

// skyrix assignment
- (void)saveSkyrixRecord {
  // is class SkyJobDocument
  [(SkyJobDocument *)[self skyrixRecord] save];
  // force reload -> by notifications
}
- (void)takeValuesFromSkyrixRecord:(id)_skyrixRecord {
  [self setDescription:[_skyrixRecord name]];
  [self setDuedate:[_skyrixRecord endDate]];
  // category is not synced
  {
    NSString *state = [(SkyJobDocument *)_skyrixRecord status];
    if (([state isEqualToString:@"25_done"]) ||
        ([state isEqualToString:@"30_archived"]))
      [self setIsCompleted:YES];

    else  
      [self setIsCompleted:NO];
  }
  [self setPriority:[[(SkyJobDocument *)_skyrixRecord priority] intValue]];
}
- (void)putValuesToSkyrixRecord:(id)_skyrixRecord {
  NSCalendarDate *due = [self duedate];
  [(SkyJobDocument *)_skyrixRecord setName:[self description]];
  if (due != nil)
    [_skyrixRecord setEndDate:due];
  [_skyrixRecord setStatus:
                 ([self isCompleted])
                 ? @"25_done"
                 : @"20_processing"];
  [(SkyJobDocument *)_skyrixRecord setPriority:
                 [NSString stringWithFormat:@"%d", [self priority]]];
  // when first time sync, set comment
  if (([(SkyJobDocument *)_skyrixRecord isNew]) && ([[self note] length]))
    [_skyrixRecord setCreateComment:[self note]];
}

- (EOFetchSpecification *)_fetchSpecForSkyrixJob {
  EOQualifier *qual = nil;

  qual = [EOQualifier qualifierWithQualifierFormat:
                      @"type='toDoJob'"];
  return [EOFetchSpecification fetchSpecificationWithEntityName:@"job"
                               qualifier:qual sortOrderings:nil];
}
- (id)_qualifyAfterFetch:(NSArray *)_fetched {
  id           skyId = [self skyrixId];
  NSEnumerator *e    = nil;
  id           one   = nil;
  id           gid   = nil;
  id           pKey  = nil;

  e = [_fetched objectEnumerator];
  while ((one = [e nextObject])) {
    gid  = [one globalID];
    pKey = [[gid keyValuesArray] objectAtIndex:0];
    if (([pKey isEqual:skyId]))
      return one;
  }
  return nil;
}
- (void)_observeSkyrixRecord:(id)_skyrixRecord {
  NSNotificationCenter   *nc       = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
      selector:@selector(skyrixRecordChanged)
      name:EODataSourceDidChangeNotification
      object:[(SkyJobDocument *)_skyrixRecord dataSource]];
  self->isObserving = YES;
}
- (id)fetchSkyrixRecord {
  EOGlobalID             *personId = nil;
  SkyPersonJobDataSource *ds       = nil;
  SkyJobDocument         *skyJob   = nil;

  personId = [[self->dataSource currentAccount] valueForKey:@"globalID"];
  ds       =
    [[SkyPersonJobDataSource alloc] initWithContext:[self context]
                                    personId:personId];
  [ds setFetchSpecification:[self _fetchSpecForSkyrixJob]];

  skyJob = [self _qualifyAfterFetch:[ds fetchObjects]];
  RELEASE(ds);

  return skyJob;
}

@end /* SkyPalmJobDocument */

@implementation SkyPalmJobDocumentSelection

- (Class)mustBeClass {
  return [SkyPalmJobDocument class];
}

@end /* SkyPalmJobDocumentSelection */
