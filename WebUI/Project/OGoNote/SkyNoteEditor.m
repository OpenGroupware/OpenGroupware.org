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

#import <OGoFoundation/LSWEditorPage.h>

@class NSString;

@interface SkyNoteEditor : LSWEditorPage
{
@private
  NSString *fileContent;
  id       project;
  id       appointment;
  BOOL     isProjectEnabled;
}

- (void)setProject:(id)_project;
- (id)project;
- (BOOL)isProjectAssigned;

- (void)setAppointment:(id)_date;
- (id)appointment;

- (NSString *)fileContent;

@end

#include "common.h"
#include <GDLAccess/EOFault.h>

@implementation SkyNoteEditor

static BOOL hasLSWProjects = NO;

+ (void)initialize {
  NGBundleManager *bm = nil;

  bm   = [NGBundleManager defaultBundleManager];
  hasLSWProjects = [bm bundleProvidingResource:@"LSWProjects"
		       ofType:@"WOComponents"] != nil ? YES : NO;
}

- (id)init {
  if ((self = [super init])) {
    self->isProjectEnabled = hasLSWProjects;
  }
  return self;
}

- (void)dealloc {
  [self->appointment release];
  [self->fileContent release];
  [self->project     release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForNewCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  self->fileContent = [[NSMutableString alloc] init];
  return YES;
}

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  NSString *fileName;
  id obj;

  obj = [self object];
  
  // TODO: do not use faults! seems to break on OSX
  self->appointment = [[obj valueForKey:@"toDate"]    retain];
  self->project     = [[obj valueForKey:@"toProject"] retain];
  
  fileName = [obj valueForKey:@"attachmentName"];
  if ([fileName isNotNull])
    self->fileContent = [[NSString alloc] initWithContentsOfFile:fileName];
  
  return YES;
}

/* accessors */

- (void)setProject:(id)_project { 
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}
- (BOOL)isProjectAssigned {
  return [self->project isNotNull];
}

- (void)setAppointment:(id)_date {
  ASSIGN(self->appointment, _date);
}
- (id)appointment {
  return self->appointment;
}
- (BOOL)isAppointmentAssigned {
  if ([EOFault isFault:self->appointment]) {
    // TODO: we do not want to use faults anywhere anymore
    //       yet in this case a fault means an object is connected
    [self logWithFormat:@"WARNING: appointment is still a fault!"];
    return YES;
  }
  return [self->appointment isNotNull];
}

- (NSMutableDictionary *)note {
  return [self snapshot];
}

- (void)setFileContent:(NSString *)_fileContent {
  ASSIGNCOPY(self->fileContent, _fileContent);
}
- (NSString *)fileContent {
  return self->fileContent;
}

- (BOOL)isProjectEnabled {
  return self->isProjectEnabled;
}

/* notifications */

- (NSString *)insertNotificationName {
  return LSWNewNoteNotificationName;
}
- (NSString *)updateNotificationName {
  return LSWUpdatedNoteNotificationName;
}
- (NSString *)deleteNotificationName {
  return LSWDeletedNoteNotificationName;
}

- (BOOL)checkConstraints {
  NSMutableString *error;
  NSString        *pTitle;
  
  error  = [NSMutableString stringWithCapacity:128];
  pTitle = [[self snapshot] valueForKey:@"title"];
  
  if (![pTitle isNotNull] || [pTitle length] == 0)
    [error appendString:@" No note name set."];

  if ([error length] > 0) {
    [self setErrorString:error];
    return YES;
  }
  
  [self setErrorString:nil];
  return NO;
}

- (BOOL)checkConstraintsForSave {
  return ![self checkConstraints];
}

/* actions */

- (id)insertObject {
  WOSession *sn;
  NSNumber  *accountId;
  int       flength   = 0;
  id        note;
  
  sn        = [self session];
  accountId = [[sn activeAccount] valueForKey:@"companyId"];
  note      = [self snapshot];

  if (self->fileContent == nil) self->fileContent = @"";
  
  flength = [self->fileContent length];
  
  [note takeValue:accountId                    forKey:@"firstOwnerId"];
  [note takeValue:accountId                    forKey:@"currentOwnerId"];
  [note takeValue:self->fileContent            forKey:@"fileContent"];
  [note takeValue:[NSNumber numberWithBool:NO] forKey:@"isFolder"];
  [note takeValue:[NSNumber numberWithInt:flength] forKey:@"fileSize"];

  if (self->project != nil)
    [note takeValue:self->project forKey:@"project"];

  if (self->appointment != nil) {
    [note takeValue:[self->appointment valueForKey:@"dateId"] 
	  forKey:@"dateId"];
  }
  return [self runCommand:@"note::new" arguments:note];
}

- (id)updateObject {
  int flength = 0;
  id  note    = [self snapshot];

  if (self->fileContent == nil) self->fileContent = @"";
  
  flength = [self->fileContent length];
  
  // TODO: the length should be written by the note::set command?!
  [note takeValue:[NSNumber numberWithInt:flength] forKey:@"fileSize"];
  [note takeValue:self->fileContent forKey:@"fileContent"];
    
  return [self runCommand:@"note::set" arguments:note];
}

- (id)deleteObject {
  id result = [[self object] run:@"note::delete",
                               @"reallyDelete", [NSNumber numberWithBool:YES],
                               nil];
  return result;
}

- (id)reallyDelete {
  return [self deleteAndGoBackWithCount:1];
}

@end /* SkyNoteEditor */
