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

#include "SkyNoteList.h"
#include <NGMime/NGMimeType.h>
#include <NGObjWeb/WOResponse.h>
#include "common.h"

@interface SkyNoteList(PrivateMethodes)
- (id)_getNoteOfAppointment:(id)_app;
@end

static NSComparisonResult compareNotes(id part1, id part2, void *context) {
  NSCalendarDate *d1;
  NSCalendarDate *d2;
  
  d1 = [part1 valueForKey:@"creationDate"];
  d2 = [part2 valueForKey:@"creationDate"];
  
  if (d1 == nil || d2 == nil)
    return NSOrderedDescending;
  if (d1 == d2)
    return NSOrderedSame;
  
  return [d2 compare:d1];
}

@implementation SkyNoteList

static BOOL       hasLSWProjects = NO;
static NGMimeType *eoNoteType    = nil;

+ (void)initialize {
  NGBundleManager *bm = nil;

  bm = [NGBundleManager defaultBundleManager];
  hasLSWProjects = 
    [bm bundleProvidingResource:@"LSWProjects" ofType:@"WOComponents"] != nil
    ? YES : NO;

  if (eoNoteType == nil)
    eoNoteType = [[NGMimeType mimeType:@"eo/note"] retain];
}

- (id)init {
  if ((self = [super init])) {
    self->snlFlags.isProjectEnabled = hasLSWProjects ? 1 : 0;
  }
  return self;
}

- (void)dealloc {
  [self->newNoteTitle release];
  [self->newNoteBody  release];
  [self->projectId    release];
  [self->project      release];
  [self->rootDocument release];
  [self->title        release];
  [self->notes        release];
  [self->note         release];
  [self->appointment  release];
  [super dealloc];
}

/* fetching */

- (void)_fetchNotes {
  // TODO: we really, really need a command for that!
  id ns = nil;

  if (self->rootDocument == nil) {
    id p = nil;

    if ((p = [self project])) {
      [self runCommand:@"project::get-root-document",
            @"object"     , p,
            @"relationKey", @"rootDocument", nil];
      self->rootDocument = [[p valueForKey:@"rootDocument"] retain];
    }
  }

  // TODO: remove use of faults!!
  if (self->rootDocument != nil) {
    ns = [self->rootDocument valueForKey:@"toNote"];
    if ([ns respondsToSelector:@selector(clear)])
      [ns clear];
    ns = [self->rootDocument valueForKey:@"toNote"];
  }
  else if (self->appointment != nil) {
    if (![self->appointment isKindOfClass:[NSDictionary class]]) {
      ns = [self->appointment valueForKey:@"toNote"];
      if ([ns respondsToSelector:@selector(clear)])
        [ns clear];
    }
    ns = [self _getNoteOfAppointment:self->appointment];
  }
  else {
    NSLog(@"No object to get notes!!!");
    return;
  }
  ns = [ns sortedArrayUsingFunction:compareNotes context:NULL];
  ASSIGN(self->notes, ns);

  [[self->notes mappedArrayUsingSelector:@selector(objectForKey:)
                withObject:@"creationDate"]
                makeObjectsPerformSelector:@selector(setTimeZone:)
                withObject:[[self session] timeZone]];
  [self runCommand:@"note::get-attachment-name", @"notes", self->notes, nil];
  
  [self runCommand:@"note::get-current-owner",
        @"objects",     self->notes,
        @"relationKey", @"currentOwner", nil];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  [self _fetchNotes];
}

/* accessors */

- (BOOL)isEditDisabled {
  BOOL       isEnabled;
  OGoSession *sn;
  NSNumber   *accountId;
  id         account;

  sn        = [self session];
  account   = [sn activeAccount];
  accountId = [account valueForKey:@"companyId"];
  
  isEnabled = (([accountId isEqual:[self->note valueForKey:@"currentOwnerId"]])
               || ([sn activeAccountIsRoot]));
  return !isEnabled ? YES : NO;
}

- (BOOL)isProjectEnabled {
  return self->snlFlags.isProjectEnabled ? YES : NO;
}

- (BOOL)isAppointmentAssigned {
  return [[self->note valueForKey:@"dateId"] isNotNull] ? YES : NO;
}

- (EOKeyGlobalID *)noteProjectGlobalID {
  EOKeyGlobalID *pGid;
  NSNumber      *pId;
  
  pId  = [self->note valueForKey:@"projectId"];
  if (![pId isNotNull]) return nil;
  
  pGid = [EOKeyGlobalID globalIDWithEntityName:@"Project" 
			keys:&pId keyCount:1 zone:NULL];
  return pGid;
}
- (EOKeyGlobalID *)noteAptGlobalID {
  EOKeyGlobalID *aptGid;
  NSNumber      *aptId;
  
  aptId  = [self->note valueForKey:@"dateId"];
  if (![aptId isNotNull]) return nil;
  aptGid = [EOKeyGlobalID globalIDWithEntityName:@"Date" 
                          keys:&aptId keyCount:1 zone:NULL];
  return aptGid;
}
- (BOOL)printMode {
  return self->printMode ? YES : NO;
}

- (void)setPrintMode:(BOOL)_printMode {
  self->printMode = _printMode;
}

- (id)printNotes {
  WOResponse *r;

    id page;

  page = [self pageWithName:@"SkyNotePrint"];
  [page takeValue:self->projectId   forKey:@"projectId"];
  [page takeValue:self->title       forKey:@"title"];
  [page takeValue:self->notes       forKey:@"Notes"];
  [page takeValue:self->note       forKey:@"note"];
  r = [page generateResponse];
  [r setHeader:@"text/html" forKey:@"content-type"];
  return r;
}


- (BOOL)isAppointmentViewAllowed {
  NSString *perms;
  
  perms = [self runCommand:@"appointment::access", 
		  @"gid", [self noteAptGlobalID], nil];
  if (perms == nil)
    return NO;
  
  return ([perms rangeOfString:@"v"].length > 0) ? YES : NO;
}

- (BOOL)isProjectAssigned {
  return [[self->note valueForKey:@"projectId"] isNotNull] ? YES : NO;
}

- (BOOL)isProjectLinkDisabled {
  NSArray *pj;

  pj = [self runCommand:@"project::get",
               @"projectId", [self->note valueForKey:@"projectId"], nil];
  
  return ([pj count] == 1) ? NO : YES;
}

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  if (self->project)
    return self->project;
  
  if (self->projectId) {
    self->project =
      [[self run:@"project::get", @"gid", self->projectId, nil] lastObject];
    
    [self->project retain];
  }
  
  return self->project;
}

- (void)setProjectId:(EOGlobalID *)_gid {
  ASSIGNCOPY(self->projectId, _gid);
}
- (id)projectId {
  return self->projectId;
}

- (void)setNotes:(NSArray *)_notes {
  ASSIGN(self->notes, _notes);
}
- (NSArray *)notes {
  return self->notes;
}

- (void)setNote:(id)_note; {
  ASSIGN(self->note, _note);
}
- (id)note {
  return self->note;
}

- (void)setAppointment:(id)_apmt; {
  ASSIGN(self->appointment, _apmt);
}
- (id)appointment {
  return self->appointment;
}

- (NSString *)noteContent {
  NSString *fileName = [self->note valueForKey:@"attachmentName"];
  return [NSString stringWithContentsOfFile:fileName];
}

- (void)setTitle:(NSString *)_title {
  ASSIGNCOPY(self->title, _title);
}
- (NSString *)title {
  return self->title;
}

- (void)setNewNoteTitle:(NSString *)_title {
  ASSIGNCOPY(self->newNoteTitle, _title);
}
- (NSString *)newNoteTitle {
  return self->newNoteTitle;
}
- (void)setNewNoteBody:(NSString *)_body {
  ASSIGNCOPY(self->newNoteBody, _body);
}
- (NSString *)newNoteBody {
  return self->newNoteBody;
}

- (NSUserDefaults *)userDefaults {
  return [[self session] userDefaults];
}

- (void)setShouldShowQuickCreate:(BOOL)_flag {
  [[self userDefaults] setObject:[NSNumber numberWithBool:(_flag ? NO : YES)]
		       forKey:@"notelist_hidequickcreate"];
}
- (BOOL)shouldShowQuickCreate {
  return [[self userDefaults] boolForKey:@"notelist_hidequickcreate"]?NO:YES;
}

/* actions */

- (id)createNewNote {
  WOComponent *ct;
  
  ct = [[self session] instantiateComponentForCommand:@"new" type:eoNoteType];
  if ([self project])
    [ct takeValue:[self project] forKey:@"project"];
  if (self->appointment)
    [ct takeValue:self->appointment forKey:@"appointment"];
  
  return ct;
}

- (id)editNote {
  NSNumber *pId;
  
  if (self->note == nil) {
    [self setErrorString:@"No note available for edit operation."];
    return nil;
  }

  if ((pId = [self->note valueForKey:@"projectId"]) == nil)
    [self->note takeValue:self->projectId forKey:@"projectId"];
  
  [[[self session] navigation] activateObject:self->note withVerb:@"edit"];    
  return nil;
}

- (id)viewProject {
  return [[[self session] navigation] activateObject:[self noteProjectGlobalID]
				      withVerb:@"view"];
}
- (id)viewAppointment {
  return [[[self session] navigation] activateObject:[self noteAptGlobalID]
				      withVerb:@"view"];
}

- (id)view {
  if ([self project] != nil)
    return [self viewAppointment];
  else if (self->appointment != nil) {
    return [self viewProject];
  }
  return nil;
}

- (id)toggleQuickCreate {
  [self setShouldShowQuickCreate:([self shouldShowQuickCreate] ? NO : YES)];
  return nil;
}

- (NSString *)defaultNoteTitle {
  NSCalendarDate *now;
    
  now = [[[NSCalendarDate alloc] init] autorelease];
  [now setTimeZone:[[self session] timeZone]];
  return [now descriptionWithCalendarFormat:@"%Y%m%d"];
}

- (id)noteQuickCreate {
  NSMutableDictionary *newNote;
  NSNumber *accountId;
  id tmp;
  
  if (![self->newNoteBody isNotNull] || [self->newNoteBody length] == 0) {
    [self setErrorString:@"Cannot create note without body!"];
    return nil;
  }
  
  /* provide a default title */
  
  if ([self->newNoteTitle length] == 0)
    self->newNoteTitle = [[self defaultNoteTitle] copy];
  
  /* create note record */

  newNote   = [NSMutableDictionary dictionaryWithCapacity:16];
  accountId = [[[self session] activeAccount] valueForKey:@"companyId"];
  
  [newNote takeValue:self->newNoteTitle           forKey:@"title"];
  [newNote takeValue:accountId                    forKey:@"firstOwnerId"];
  [newNote takeValue:accountId                    forKey:@"currentOwnerId"];
  [newNote takeValue:self->newNoteBody            forKey:@"fileContent"];
  [newNote takeValue:[NSNumber numberWithBool:NO] forKey:@"isFolder"];
  [newNote takeValue:[NSNumber numberWithInt:[self->newNoteBody length]] 
	   forKey:@"fileSize"];
  
  if ((tmp = [self project]) != nil)
    [newNote takeValue:tmp forKey:@"project"];
  
  if ((tmp = [self appointment]) != nil)
    [newNote takeValue:[tmp valueForKey:@"dateId"] forKey:@"dateId"];
  
  /* create note */
  
  tmp = [[[self session] commandContext] runCommand:@"note::new" 
					 arguments:newNote];
  if (![[[self session] commandContext] commit]) {
    [self setErrorString:@"could not create note!"];
    return nil;
  }

  [self->newNoteTitle release]; self->newNoteTitle = nil;
  [self->newNoteBody  release]; self->newNoteBody  = nil;
  
  /* post notification */

  [[self session] transferObject:tmp owner:self];
  [self postChange:LSWNewNoteNotificationName onObject:tmp];
  [self _fetchNotes];
  return nil;
}

/* PrivateMethodes */

- (id)_getNoteOfAppointment:(id)_app {
  NSNumber *dateId;
  NSArray  *theNotes;
  
  theNotes = [_app valueForKey:@"toNote"];
  if ([theNotes isNotNull])
    return theNotes;

  dateId = [_app valueForKey:@"dateId"];
    
  if ([dateId isNotNull]) {
    theNotes = [self runCommand:@"note::get",
                       @"dateId", dateId,
                       @"returnType", intObj(LSDBReturnType_ManyObjects),
		     nil];
  }
  
  if (theNotes == nil)
    theNotes = [NSArray array];
  
  [_app takeValue:theNotes forKey:@"toNote"];
  return theNotes;
}

@end /* SkyNoteList */
