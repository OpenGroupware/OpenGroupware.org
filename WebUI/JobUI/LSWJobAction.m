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

#include "LSWJobAction.h"
#include "LSWJobMailPage.h"
#include <NGObjWeb/WOMailDelivery.h>
#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/LSWMailEditorComponent.h>
#include <LSFoundation/OGoObjectLinkManager.h>
#include "common.h"

@implementation LSWJobAction

static NGMimeType *eoJobType = nil;

+ (void)initialize {
  if (eoJobType == nil)
    eoJobType = [[NGMimeType mimeType:@"eo" subType:@"job"] copy];
}

- (id)init {
  if ((self = [super init])) {
    id account;
    
    account      = [[self session] activeAccount];
    self->userId = [[account valueForKey:@"companyId"] retain];
  }
  return self;
}

- (void)dealloc {
  [self->jobHierarchy      release];
  [self->selectedAttribute release];
  [self->jobId   release];
  [self->userId  release];
  [self->tabKey  release];
  [self->comment release];
  [self->action  release];
  [self->subJob  release];
  [self->item    release];
  [self->job     release];
  [self->jobHistory release];
  [super dealloc];
}

/* accessors */

- (BOOL)isEditorPage {
  return YES;
}

/* notifications */

- (void)syncAwake {
  NSTimeZone *tz;
  
  [super syncAwake];

  /* correct timezone */
  tz = [[self session] timeZone];
  [[self->job valueForKey:@"startDate"] setTimeZone:tz];
  [[self->job valueForKey:@"endDate"]   setTimeZone:tz];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if (![super prepareForActivationCommand:_command type:_type
	      configuration:_cmdCfg])
    return NO;
  
  self->action = [_command copy];
  //hh: self->action = [[_cmdCfg objectForKey:@"action"] retain];
  
  if (self->job == nil) {
      self->job   = [[self object] retain];
      self->jobId = [[self->job valueForKey:@"jobId"] retain];
  }
    
  if ([self->job valueForKey:@"executant"] == nil) {
      [self runCommand:@"job::setexecutant",
            @"object",      self->job,
            @"relationKey", @"executant", nil];
  }
  if ([self->job valueForKey:@"creator"] == nil) {
      [self runCommand:@"job::setcreator",
            @"object",      self->job,
            @"relationKey", @"creator", nil];
  }
  return YES;
}

/* accessors */

- (NSString *)jobUrlPrefix {
  // TODO: this should not be done manually!
  NSString  *urlPrefix = nil;
  NSString  *url       = nil;
  WOContext *ctx;
  WORequest *req;
  
  ctx = [self context];
  req = [ctx request];
  
  urlPrefix = [ctx urlSessionPrefix];
  url       = [req headerForKey:@"x-webobjects-server-url"];
  
  if ([url length] > 0)
    return [url stringByAppendingString:urlPrefix];
  
  return [NSString stringWithFormat:@"http://%@%@",
		     [req headerForKey:@"host"], urlPrefix];
}
- (NSString *)jobUrl {
  // TODO: this should not be done manually!
  NSString *s;

  s = [self jobUrlPrefix];
  s = [s stringByAppendingFormat:@"/viewJob?jobId=%@", 
	   [self->job valueForKey:@"jobId"]];
  return s;
}

/* mail accessors */

- (NSString *)executantMailSubject {
  NSString *subject;
  id l, creator;
  
  l       = [self labels];
  creator = [self jobCreatorEO];
  subject = [NSString stringWithFormat:@"%@: '%@' %@ %@ %@",
                        [l valueForKey:@"job"],
                        [self->job valueForKey:@"name"],
                        [l valueForKey:self->action],
                        [l valueForKey:@"byLabel"], 
                        [creator valueForKey:@"login"]];
  return subject;
}
- (NSString *)creatorMailSubject {
  NSMutableString *ms;
  id l;
  
  l  = [self labels];
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendString:[l valueForKey:@"jobLabel"]];
  [ms appendString:@": '"];
  [ms appendString:[[self->job valueForKey:@"name"] stringValue]];
  [ms appendString:@"' "];
  [ms appendString:[[l valueForKey:self->action] stringValue]];
  [ms appendString:@" "];
  [ms appendString:[l valueForKey:@"byLabel"]];
  [ms appendString:@" "];
  [ms appendString:
        [[[[self session] activeAccount] valueForKey:@"login"] stringValue]];
  
  return [[ms copy] autorelease];
}

/* mail actions */

- (id)_sendMessageToExecutant {
  NSString     *subject = nil;
  id           res;
  id           creator;
  id<LSWMailEditorComponent, OGoContentPage> editor = nil;
  id l;
  
  l = [self labels];
  creator = [self jobCreatorEO];
  
  editor  = (id)[self pageWithName:@"LSWImapMailEditor"];
  [self enterPage:editor];
  
  subject = [self executantMailSubject];
  [editor setContentWithoutSign:@""];
  [editor setSubject:subject];
  [editor addReceiver:[self->job valueForKey:@"executant"] type:@"to"];
  [editor addAttachment:self->job type:eoJobType];
  res = [editor send];
  return res;
}

- (id)_sendMessageToCreator {
  id<LSWMailEditorComponent, OGoContentPage> editor = nil;
  NSString *subject = nil;
  id       res;
  id       l;

  l = [self labels];

  editor  = (id)[self pageWithName:@"LSWImapMailEditor"];
  [self enterPage:editor];
  
  subject = [self creatorMailSubject];
  [editor setContentWithoutSign:@""];
  [editor setSubject:subject];
  [editor addReceiver:[self jobCreatorEO] type:@"to"];
  [editor addAttachment:self->job type:eoJobType];
  res = [editor send];
  [self leavePage];
  return res;
}

- (void)sendMessage {
  NSNumber *nfs;
  int notifyStatus = 0;    

  nfs = [self->job valueForKey:@"notify"];
  
  if (![nfs isNotNull])
    return;
  if ((notifyStatus = [nfs intValue]) == OGoJobNotifyNever)
    return;
  
  if (![self isJobCreatorLoginAccount]) {
    if (notifyStatus == OGoJobNotifyAlways) {
      [self _sendMessageToCreator];
    }
    else if (notifyStatus == OGoJobNotifyOnAcceptAndDone) {
      if ([self->action isEqualToString:@"done"] ||
          [self->action isEqualToString:@"accept"]) {
        [self _sendMessageToCreator];
      }
    }
  }
  
  if ([self isJobCreatorLoginAccount] && notifyStatus == OGoJobNotifyAlways) {
    if ([self->action isEqualToString:@"comment"])
      [self _sendMessageToExecutant];
    else if ([self->action isEqualToString:@"reject"])
      [self _sendMessageToExecutant];
  }
}

/* actions */

- (void)_removedPreferredExecutantsFromJobEO:(id)_job {
  OGoObjectLinkManager *linkManager;
  
  linkManager = [[[self session] commandContext] linkManager];
  
  [linkManager deleteLinksFrom:(EOKeyGlobalID *)[_job globalID]
               type:@"Preferred Job Executant"];
  [_job takeValue:[NSArray array] forKey:@"prefExec"];
}

- (id)handleJobCommitFailed {
  [self setErrorString:@"Could not commit jobaction command (rolled back)!"];
  [self rollback];
  return nil;
}

- (id)saveAction {
  if ([self->action isEqualToString:@"annotate"])
    self->action = @"comment";
  
  [self->job run:@"job::jobaction",
              @"action",  self->action, @"comment", self->comment, nil];
  
  if ([self->action isEqualToString:@"accept"])
    [self _removedPreferredExecutantsFromJobEO:self->job];
  
  if (![self commit])
    return [self handleJobCommitFailed];
  
  [self sendMessage];
  [self postChange:LSWJobHasChanged onObject:[self object]];
  [self leavePage];
  
  if ([self->action isEqualToString:@"archive"] ||
      [self->action isEqualToString:@"done"]) {
    [self leavePage];
  }
  return nil;
}

/* accessors */

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  ASSIGN(self->selectedAttribute, _selectedAttribute);
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;    
}

- (void)setTabKey:(NSString *)_tabKey {
  ASSIGN(self->tabKey, _tabKey);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;    
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY(self->comment, _comment);
}
- (NSString *)comment {
  return self->comment;    
}

- (void)setAction:(NSString *)_action {
  ASSIGNCOPY(self->action, _action);
}
- (NSString *)action {
  return self->action;    
}

- (id)job {
  return self->job;
}
- (id)jobCreatorEO {
  return [self->job valueForKey:@"creator"];
}
- (NSNumber *)jobCreatorId {
  // TODO: first check 'creatorId'?
  return [[self jobCreatorEO] valueForKey:@"companyId"];
}
- (BOOL)isJobCreatorLoginAccount {
  return [[[[self session] activeAccount] valueForKey:@"companyId"]
                  isEqual:[self jobCreatorId]] ? YES : NO;
}

- (void)setSubJob:(id)_subJob {
  // TODO: remove if unused
  ASSIGN(self->subJob,_subJob);
}
- (id)subJob {
  // TODO: remove if unused
  return self->subJob;
}

- (void)setJobHistory:(id)_jobHistory {
  ASSIGN(self->jobHistory, _jobHistory);
}
- (id)jobHistory {
  return self->jobHistory;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setRepIdx:(int)_repIdx {
  self->repIdx = _repIdx;
}
- (int)repIdx {
  return self->repIdx;
}
                                
- (NSArray *)jobHierarchy {
  return self->jobHierarchy;
}

- (NSString *)jobActionHeadLine {
  NSString *s;
  s = [@"jobActionHeadLine_" stringByAppendingString:self->action];
  return [[self labels] valueForKey:s];
}

- (NSString *)saveButtonLabel {
  NSString *s;
  s = [@"saveButtonLabel_" stringByAppendingString:self->action];
  return [[self labels] valueForKey:s];
}

- (NSString *)statusValue {
  return [[self labels] valueForKey:[self->job valueForKey:@"jobStatus"]];
}

- (BOOL)isCurrentJob {
  return ([[item valueForKey:@"jobId"] isEqual:self->jobId]);
}

- (BOOL)moreJobs {
  return !(self->repIdx == self->cntJobHierarchy);
}

- (BOOL)endDateOnTime {
  return ([[self->job valueForKey:@"endDate"] timeIntervalSinceNow] > 0);
}

- (BOOL)userIsExecutant {
  return [self->userId isEqual:[job valueForKey:@"executantId"]];
}
- (BOOL)userIsCreator {
  return [self->userId isEqual:[job valueForKey:@"creatorId"]];
}

/* actions */

- (id)cancel {
  [self leavePage];
  return nil;
}

@end /* LSWJobAction */
