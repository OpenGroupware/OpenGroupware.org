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

#include "LSWImapMailViewer.h"
#include "common.h"
#include "LSWImapMailMove.h"
#include "SkyImapMailListState.h"
#include <NGObjWeb/WEClientCapabilities.h>
#include "SkyImapMailRestrictions.h"

// TODO: this class is way too large - split up!

#define MAX_LENGTH 100

@interface NSObject(PRIVATE)
- (void)setMessages:(NSArray *)_mes;
@end

@interface LSWImapMailViewer(PrivateMethods)
- (NGMimeMessage *)_mdnMessage;
- (id)showMail:(BOOL)_next;
- (id)showMail:(BOOL)_next unread:(BOOL)_unread alsoOther:(BOOL)_alsoOthers;
- (void)resetUrlState;
@end /* LSWImapMailViewer(MDNPrivateMethods) */

@implementation LSWImapMailViewer

static NSString   *FileNameDateFmt         = @"%Y-%m-%d_%H:%M.mail";
static int        UseOldMailSourceSubject  = -1;
static int        BodyStructureInViewerBoundary = -1;
static int        NoBodyStructureInViewer  = -1;
static int        MaxSubjectLength         = -1;
static NGMimeType *multipartReportType     = nil;
static NGMimeType *textRfc822HeadersType   = nil;
static NGMimeType *textPlainType           = nil;
static NGMimeType *msgDispositionNotiType  = nil;
static NGMimeType *objcMessageType         = nil;
static NSString   *xMailer                 = @"OpenGroupware.org 0.9";
static NSString   *winJSSizing = @"width=100,height=100,left=10,top=10";
static NSString   *sendDateDateFmt = @"%Y-%m-%d %H:%M";

+ (void)initialize {
  // TODO: check superclass version
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSDictionary *paras;
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  UseOldMailSourceSubject = [ud boolForKey:@"UseOldMailSourceSubject"]?1:0;
  NoBodyStructureInViewer = [ud boolForKey:@"NoBodyStructureInViewer"]?1:0;
  
  BodyStructureInViewerBoundary =
    [ud integerForKey:@"BodyStructureInViewerBoundary"];
  if (BodyStructureInViewerBoundary < 100)
    BodyStructureInViewerBoundary = 5000;

  if ((MaxSubjectLength = [ud integerForKey:@"mail_maxSubjectLenght"]) < 5)
    MaxSubjectLength = 30;

  paras = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"disposition-notification", @"report-type", nil];
  multipartReportType = 
    [[NGMimeType mimeType:@"multipart" subType:@"report" parameters:paras]
                 retain];
  textRfc822HeadersType = 
    [[NGMimeType mimeType:@"text" subType:@"rfc822-headers"] retain];
  textPlainType = [[NGMimeType mimeType:@"text" subType:@"plain"] retain];
  msgDispositionNotiType = 
    [[NGMimeType mimeType:@"message" subType:@"disposition-notification"] 
                 retain];
  objcMessageType = 
    [[NGMimeType mimeType:@"objc" subType:@"NGImap4Message"] retain];
}

- (id)init {
  if ((self = [super init])) {
    self->url = [[LSWMailViewerURLState alloc] init];

    [self setTabKey:@"mail"];
    [self setIsInWarningMode:NO];
  }
  return self;
}

- (void)dealloc {
  // TODO: it is *MORE* than questionable to access the session in -dealloc!
  [(WOSession *)[self session] 
                removeObjectForKey:@"displayedAttachmentDownloadUrls"];
  
  [self resetUrlState]; /* Note: this *must* be run prior releasing the url..*/
  [self->url                       release];
  
  [self->bcc                       release];
  [self->cc                        release];
  [self->dispositionNotificationTo release];
  [self->emailContent              release];
  [self->imapContext               release];
  [self->mailDS                    release];
  [self->mailSource                release];
  [self->mailSourceString          release];
  [self->state                     release];
  [self->tabKey                    release];
  [self->to                        release];
  [self->downloadAllItem           release];
  [self->downloadAllObjs           release];
  [super dealloc];
}

- (NSString *)_receiverForHeaderFieldWithName:(NSString *)_fieldName {
  NSMutableString *receiver;
  NSString        *str;
  NSEnumerator    *enumerator;

  receiver   =  [NSMutableString stringWithCapacity:32];
  enumerator = [self->emailContent valuesOfHeaderFieldWithName:_fieldName];
  [receiver setString:[enumerator nextObject]];

  while ((str = [enumerator nextObject])) {
    [receiver appendString:@", "];
    [receiver appendString:str];
  }
  return receiver;
}

- (void)initRawData {
  NGMimeMessageParser *parser;

  parser = [[NGMimeMessageParser alloc] init];

  ASSIGN(self->mailSource,   [[self object] rawData]);
  ASSIGN(self->emailContent, [parser parsePartFromData:self->mailSource]);
  
  [parser release]; parser = nil;
}

/* response generation */

- (void)appendToResponse:(WOResponse *)_response 
  inContext:(WOContext *)_context 
{
  WOSession *sn;

  sn = (WOSession *)[self session];
  if ([[[[sn context] request] clientCapabilities] doesSupportUTF8Encoding])
    [_response setContentEncoding:NSUTF8StringEncoding];
  
  [sn takeValue:[NSMutableArray arrayWithCapacity:4] 
      forKey:@"displayedAttachmentDownloadUrls"];
  
  [super appendToResponse:_response inContext:_context];
}

/* activation */

- (void)_loadReceiverInfoFromContent {
  ASSIGN(self->to,  [self _receiverForHeaderFieldWithName:@"to"]);
  ASSIGN(self->cc,  [self _receiverForHeaderFieldWithName:@"cc"]);
  ASSIGN(self->bcc, [self _receiverForHeaderFieldWithName:@"bcc"]);
}

- (void)_setupMessageDispositionInfo {
    NSEnumerator   *e;
    id             one;
    NSMutableArray *mdn;

    e   = [self->emailContent valuesOfHeaderFieldWithName:
                               @"disposition-notification-to"];
    mdn = [NSMutableArray array];

    while ((one = [e nextObject])) 
      [mdn addObject:one];
    
    if ([mdn count] > 1) {
      [self logWithFormat:
	      @"%s INVALID Disposition-Notification-To - header in mail %@"
              @" .. ignoring",
              __PRETTY_FUNCTION__, [self object]];
    }
    else if ([mdn count] == 1) {
        id      tmp;
	NSRange r;
        
        tmp                      = [mdn lastObject];
        self->askToReturnReceipt = YES;
	
        /* filtering address */
	  
	r = [tmp rangeOfString:@"<"];
	if (r.length > 0) {
            tmp = [tmp substringFromIndex:r.location + r.length];
            r = [tmp rangeOfString:@">"];
            if (r.length > 0)
              tmp = [tmp substringToIndex:r.location];
        }
        ASSIGN(self->dispositionNotificationTo, tmp);
    }
}

- (void)_loadAccountDefaults {
  NSUserDefaults *ud;

  ud                  = [[self session] userDefaults];
  self->isCcCollapsed = [ud boolForKey:@"mail_is_cc_collapsed"];
  self->isToCollapsed = [ud boolForKey:@"mail_is_to_collapsed"];
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id email;
  
  if (![super prepareForActivationCommand:_command
	      type:_type configuration:_cmdCfg])
    return NO;
    
  email = [self object];
  NSAssert(email, @"no email is sets !");

  ASSIGN(self->imapContext, [(NGImap4Message *)email context]);
  ASSIGN(self->mailSource, nil);
    
  if ([email size] < BodyStructureInViewerBoundary || NoBodyStructureInViewer)
    [self initRawData];
  else {
    ASSIGN(self->emailContent, [email bodyStructure]);
  }

  if (self->emailContent == nil) {
    [self setErrorString:@"no content in email !"];
    return NO;
  }
  
  [self _loadReceiverInfoFromContent];
  [self _setupMessageDispositionInfo];
  [self _loadAccountDefaults];
  return YES;
}

- (void)resetUrlState {
  [self->url reset];
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  return [[self existingSession] userDefaults];
}
- (BOOL)shouldGoToNextMessageAfterDelete {
  return [[self userDefaults] boolForKey:@"mail_nextMesgAfterDelete"];
}
- (BOOL)shouldShowNextUnreadMessageAsNext {
  return [[self userDefaults] boolForKey:@"mail_showUnreadMesgAsNext"];
}
- (NSString *)mailMDNType {
  return [[self userDefaults] stringForKey:@"mail_MDN_type"];
}
- (NSString *)mailMDNText {
  return [[self userDefaults] stringForKey:@"mail_MDN_text"];
}
- (NSString *)mailMDNSubject {
  return [[self userDefaults] stringForKey:@"mail_MDN_subject"];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];

  [self resetUrlState];

  if ((self->askToReturnReceipt) && (self->messageWasUnread)) {
    NSString *mdnType;

    mdnType = [self mailMDNType];
    
    // three types: automatic, ask, never
    if (mdnType == nil)
      mdnType = @"ask";

    if ([mdnType isEqualToString:@"never"])
      self->askToReturnReceipt = NO;
    else if ([mdnType isEqualToString:@"automatic"]) {
      [self sendMDN];
      self->askToReturnReceipt = NO;
    }
    else if ([mdnType isEqualToString:@"ask"]) {
      // just ask
      [self setIsInWarningMode:NO];
      self->askToReturnReceipt = YES;
    }
    else {
      [self logWithFormat:
	      @"%s unknown message disposition notification type: %@",
              __PRETTY_FUNCTION__, mdnType];
    }
    // no more checks
    self->messageWasUnread = NO;
  }
  else
    // no more questions
    self->askToReturnReceipt = NO;
}

- (void)syncSleep {
  NSUserDefaults *ud;
  
  /* store defaults */
  ud = [self userDefaults];
  [ud setBool:self->isCcCollapsed forKey:@"is_cc_collapsed"];
  [ud setBool:self->isToCollapsed forKey:@"is_to_collapsed"];
  [ud synchronize];

  [self resetUrlState];
  [self->downloadAllObjs release]; self->downloadAllObjs = nil;
  [super syncSleep];
}

/* accessors */

- (void)setTabKey:(NSString *)_key {
  ASSIGN(self->tabKey, _key);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (BOOL)askToReturnReceipt {
  return self->askToReturnReceipt;
}

- (id)emailContent {
  return self->emailContent;
}

- (NSString *)subject {
  NSString *str;

  str = [[self object] valueForKey:@"subject"];
  if (![str isNotNull])
    return @"";
  
  if ([str length] < MaxSubjectLength)
    return str;
  
  return [[str substringToIndex:MaxSubjectLength]
               stringByAppendingString:@".."];
}


- (NSString *)to {
  if ([self->to length] < MAX_LENGTH) return self->to;

  if (self->isToCollapsed) { // TODO: category!
    return [[self->to substringToIndex:MAX_LENGTH]
                      stringByAppendingString:@".."];
  }
  return self->to;
}


- (NSString *)cc {
  if ([self->cc length] < MAX_LENGTH) return self->cc;

  if (self->isCcCollapsed) { // TODO: category!
    return [[self->cc substringToIndex:MAX_LENGTH]
                      stringByAppendingString:@".."];
  }
  return self->cc;
}

- (NSString *)bcc {
  return self->bcc;
}

- (NSCalendarDate *)sendDate {
  NSCalendarDate *result;
  
  result = [[self object] valueForKey:@"sendDate"];

  if ([result respondsToSelector:@selector(setTimeZone:)])
    [result setTimeZone:[[self session] timeZone]];
  
  return result;
}

/* to and cc collapsing */

- (BOOL)showToCollapser {
  if ([self->to length] < MAX_LENGTH) return NO;
  
  return !self->isToCollapsed;
}
- (BOOL)showToExpander {
  if ([self->to length] < MAX_LENGTH) return NO;
  
  return self->isToCollapsed;
}

- (BOOL)showCcCollapser {
  if ([self->cc length] < MAX_LENGTH) return NO;
  
  return !self->isCcCollapsed;
}
- (BOOL)showCcExpander {
  if ([self->cc length] < MAX_LENGTH) return NO;
  
  return self->isCcCollapsed;
}

- (id)expandTo {
  self->isToCollapsed = NO;
  return nil;
}
- (id)collapseTo {
  self->isToCollapsed = YES;
  return nil;
}
- (id)expandCc {
  self->isCcCollapsed = NO;
  return nil;
}
- (id)collapseCc {
  self->isCcCollapsed = YES;
  return nil;
}

- (BOOL)hasCC {
  return (self->cc != nil && [self->cc length] > 0) ? YES : NO;
}

- (NSData *)mailSource {
  if (self->mailSource == nil)
    [self initRawData];
  
  return self->mailSource;
}

- (NSString *)mailSourceString {
  if (self->mailSourceString == nil) {
    NSData *data;

    data = [self mailSource];

    self->mailSourceString =
      [[NSString alloc] initWithData:data
                        encoding:[NSString defaultCStringEncoding]];
  }
  return self->mailSourceString;
}

- (void)setImapContext:(NGImap4Context *)_ctx {
  ASSIGN(self->imapContext, _ctx);
}

/* actions */

- (id)printMail {
  WOComponent *page;
  WOResponse  *response;
  
  // TODO: shouldn't we use an action lookup?!
  page = [self pageWithName:@"SkyImapMailPrintViewer"];
  [page takeValue:self->emailContent forKey:@"emailContent"];
  [page takeValue:[self object]      forKey:@"object"];
  response = [page generateResponse];
  [response setHeader:@"text/html" forKey:@"content-type"];
  return response;
}

- (id)tabClicked {
  return nil;
}

- (id)newMail {
  WOComponent *ct;
  
  ct = [[self session] instantiateComponentForCommand:@"new" 
                       type:objcMessageType];
  [(id)ct setImapContext:self->imapContext];
  return ct;
}

- (id)reply {
  return [self activateObject:[self object] withVerb:@"reply"];
}
- (id)replyAll {
  return [self activateObject:[self object] withVerb:@"reply-all"];
}
- (id)forward {
  return [self activateObject:[self object] withVerb:@"forward"];
}
- (id)editAsNew {
  return [self activateObject:[self object] withVerb:@"edit-as-new"];
}

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}
- (void)postMailsDeletedNotification:(NSArray *)_mails {
  [[self notificationCenter]
    postNotificationName:@"LSWImapMailWasDeleted" object:_mails];
}

- (id)_processMessageDeleteFailure:(id)_folder {
  NSException *exc;
  NSString    *wp, *reason;
  id          l;

        exc = [_folder lastException];

        [self logWithFormat:@"%s: could not copy: %@", __PRETTY_FUNCTION__, 
	        exc];
	
        l  = [self labels];
        wp = [l valueForKey:@"MoveMailToTrashFailedWithReason"];
        if ((reason = [exc reason])) {
          reason = [l valueForKey:reason];
        }
        wp = [NSString stringWithFormat:@"%@: '%@'. %@", wp, reason,
                       [l valueForKey:@"DeleteMailsAnyway"]];

        [self setWarningPhrase:wp];
        [self setIsInWarningMode:YES];
        [self setWarningOkAction:@"reallyDeleteMail"];

        [self leavePage];
        return self;
}

- (id)reallyDeleteMail {
  NSArray        *msg;
  NGImap4Folder  *folder;
  OGoContentPage *page;
  
  [self setIsInWarningMode:NO];
  
  if ([self object] == nil) {
    [self setErrorString:@"No object available for delete operation."];
    return nil;
  }
  
  page = nil;
  if ([self shouldGoToNextMessageAfterDelete]) {
    page = [self showMail:YES
                 unread:[self shouldShowNextUnreadMessageAsNext]
                 alsoOther:YES];
    page = [[page retain] autorelease];
  }

  msg    = [NSArray arrayWithObject:[self object]];
  folder = [[self object] folder];
    
  [folder deleteMessages:msg];
  [self postMailsDeletedNotification:msg];
  
  if (page) {
    [self leavePage];
    [self leavePage];
    [self enterPage:page]; // TODO: somehow this doesn't work if I return page
    return nil;
  }
  else
    return [self leavePage];
}

- (id)delete {
  NSArray        *msg;
  NGImap4Folder  *folder;
  OGoContentPage *page = nil;
  
  if ([self object] == nil) {
    [self setErrorString:@"No object available for delete operation."];
    return nil;
  }
  
  if ([self shouldGoToNextMessageAfterDelete]) {
    page = [self showMail:YES
                 unread:[self shouldShowNextUnreadMessageAsNext]
                 alsoOther:YES];
    page = [[page retain] autorelease];
  }
  
  msg    = [NSArray arrayWithObject:[self object]];
  folder = [[self object] folder];
    
  if ([folder isInTrash]) {
    [folder deleteMessages:msg];
  }
  else {
    if (![folder moveMessages:msg toFolder:[self->imapContext trashFolder]])
      return [self _processMessageDeleteFailure:folder];
  }
  [self postMailsDeletedNotification:msg];
  
  if (page) {
    [self leavePage];
    [self leavePage];
    [self enterPage:page]; // TODO: somehow this doesn't work if I return page
    return nil;
  }
  else 
    return [self leavePage];
}

- (id)cancel {
  [self setIsInWarningMode:NO];
  return nil;
}

- (id)move {
  NGImap4Message  *msg;
  LSWImapMailMove *page;
  
  if ((msg = [self object]) == nil) {
    [self setErrorString:@"No object available for move operation."];
    return nil;
  }
  
  page = [self pageWithName:@"LSWImapMailMove"];
  [page setMails:[NSArray arrayWithObject:msg]];
  [self leavePage];
  
  // Note: for whatever reason just returning the page is *not* sufficient
  [self enterPage:page];
  return page;
}

- (id)downloadSource {
  WOResponse *response;
  id         content;

  response = [WOResponse responseWithRequest:[[self context] request]];
  [response setStatus:200];
  [response setHeader:@"text/plain" forKey:@"content-type"];

  content = [self mailSource];

  if ([content isKindOfClass:[NSData class]]) {
    ;
  }
  else if ([content isKindOfClass:[NSString class]]) {
    content = [NSData dataWithBytes:[content cString]
                      length:[content cStringLength]];
  }
  else {
    [(id)[[self context] page]
            setErrorString:
              @"couldn't provide downloadable representation of body"];
    [self logWithFormat:
	    @"couldn't provide downloadable representation of body"];
    return nil;
  }
  [response setHeader:[NSString stringWithFormat:@"%d", [content length]]
            forKey:@"content-length"];

  [response setHeader:@"identity" forKey:@"content-encoding"];
  [response setContent:content];
  return response;
}

- (id)toDoc {
  OGoContentPage *page;
  id             nv;

  nv   = [[[self context] valueForKey:@"page"] navigation];  
  page = [self pageWithName:@"SkyProject4DocumentEditor"];
  
  [page takeValue:[NSNumber numberWithBool:YES] forKey:@"isImport"];

  [nv enterPage:page];

  [page takeValue:[self mailSource] forKey:@"blob"];
  {
    id tmp = nil;

    tmp = [[self object] valueForKey:@"sendDate"];
    if ([tmp respondsToSelector:@selector(descriptionWithCalendarFormat:)])
      [page takeValue:[tmp descriptionWithCalendarFormat:FileNameDateFmt]
            forKey:@"fileName"];
  }

  if (!UseOldMailSourceSubject) { /* build abstract */
      id       tmp;
      NSString *subject;

      tmp = [[self object] valueForKey:@"sendDate"];
      tmp = [tmp respondsToSelector:@selector(descriptionWithCalendarFormat:)]
	? [tmp descriptionWithCalendarFormat:sendDateDateFmt]
	: @"<unknown>";
      
      if ([tmp length] == 0)
        tmp = @"<unknown>";
      
      subject = [[self object] valueForKey:@"subject"];
      if (!subject)
        subject = @"<unknown>";
      
      [page takeValue:[NSString stringWithFormat:@"%@ [%@]", subject, tmp]
            forKey:@"subject"];
  }
  else {
    id tmp;
    
    tmp = [[self object] valueForKey:@"subject"];
    if (tmp) {
#if LIB_FOUNDATION_LIBRARY
      if ([tmp isKindOfClass:[NSInlineUTF16String class]]) {
	/* TODO: hack to avoid uff16 string confusings */
	tmp = [NSString stringWithFormat:@"%@", tmp];
      }
#endif
      [page takeValue:tmp forKey:@"subject"];
    }
  }
  return page;
}

- (BOOL)projectAllowed {
  return YES;
}

- (NSString *)downloadTarget {
  return [[self context] contextID];
}

- (id)copyToProject {
  WOComponent *page;

  page = [self pageWithName:@"LSWImapMail2Project"];
  [page setMessages:[NSArray arrayWithObject:[self object]]];
  return page;
}


- (id)sendNoMDN {
  self->askToReturnReceipt = NO;
  [self setIsInWarningMode:NO];
  return nil;
}
- (id)sendMDN {
  // see RFC 2298 (Message Disposition Notification) for further information
  NGMimeMessage *message;
  NSArray       *addresses;

  [self setIsInWarningMode:NO];
  message = [self _mdnMessage];
  if (message == nil) {
    // failed to build message
    NSString *mdnType;

    mdnType = [self mailMDNType];
    
    if ([mdnType isEqualToString:@"automatic"]) {
      // automatic, no warnings
      [self setErrorString:nil];
      self->askToReturnReceipt = NO;
      return nil;
    }
    
    if (![[self errorString] length]) {
      [self setErrorString:
            [[self labels] valueForKey:@"mdnBuildMessageError"]];
    }
    self->askToReturnReceipt = NO; // only one try
    return nil;    
  }

  addresses = [NSArray arrayWithObject:self->dispositionNotificationTo];

  [self runCommand:@"email::deliver",
        @"copyToSentFolder", [NSNumber numberWithBool:NO],
        @"addresses",        addresses,
        @"mimePart",         message, nil];

  if (![self commit]) {
    [self rollback];
    [self setErrorString:
          [[self labels] valueForKey:@"mdnSendMessageError"]];
  }
  // no more questions / panels
  self->askToReturnReceipt = NO;
  return nil;
}

/* KVC */

- (void)takeValue:(id)_val forKey:(NSString *)_key {
  if ([_key isEqualToString:@"messageWasUnread"]) {
    self->messageWasUnread = [_val boolValue];
  }
  else if ([_key isEqualToString:@"mailDS"]) {
    ASSIGN(self->mailDS, _val);
  }
  else if ([_key isEqualToString:@"state"]) {
    ASSIGN(self->state, _val);
  }
  else 
    [super takeValue:_val forKey:_key];
}

/* more accessors */

- (void)setState:(SkyImapMailListState *)_s {
  ASSIGN(self->state, _s);
}
- (SkyImapMailListState *)state {
  return self->state;
}

/* actions */
 
- (id)showMail:(BOOL)_next { // DEPRECATED
  BOOL showUnreadAsNext;
  
  showUnreadAsNext = [self shouldShowNextUnreadMessageAsNext];
  return [self showMail:_next unread:showUnreadAsNext alsoOther:YES];
}

- (id)nextMail {
  return [self showMail:YES unread:NO alsoOther:NO];
}
- (id)nextUnread {
  return [self showMail:YES unread:YES alsoOther:NO];
}
- (id)prevUnread {
  return [self showMail:NO unread:NO alsoOther:NO];
}
- (id)prevMail {
  return [self showMail:NO
               unread:[self shouldShowNextUnreadMessageAsNext]
               alsoOther:YES];
}

- (NGImap4Message *)nextMail:(BOOL)_next unread:(BOOL)_unread
  alsoOther:(BOOL)_alsoOthers
{
  NSEnumerator   *mails;
  NGImap4Message *msg, *unreadMsg, *obj, *org, *prevUnread;

  mails      = [[self->mailDS fetchObjects] objectEnumerator];
  org        = [self object];
  msg        = nil;
  unreadMsg  = nil;
  prevUnread = nil;

  while ((obj = [mails nextObject])) {
    if ([obj isEqual:org])
      break;

    if (!_next) {
      msg = obj;

      if (![obj isRead])
        prevUnread = obj;
    }
    else if (_unread) {
      if (![obj isRead])
        prevUnread = obj;
    }
  }
  if (_next) {
    while ((obj = [mails nextObject])) {
      if (!msg)
        msg = obj;

      if (![obj isRead])
        unreadMsg = obj;

      if (!unreadMsg && _unread)
        continue;

      break;
    }
  }
  obj = nil;
  if (_unread) {
    obj = (_next) ? unreadMsg : prevUnread;
    if (_alsoOthers && !obj)
      obj = msg;
  }
  else
    obj = msg;

  return obj;
}

- (id)showMail:(BOOL)_next unread:(BOOL)_unread alsoOther:(BOOL)_alsoOthers {
  NGImap4Message *obj;
  WOComponent    *page;

  if ((obj=[self nextMail:_next unread:_unread alsoOther:_alsoOthers])==nil)
    return nil;

  page = [[[self session] navigation] activateObject:obj withVerb:@"view"];
    
  [page takeValue:[NSNumber numberWithBool:![obj isRead]]
	forKey:@"messageWasUnread"];
  [page takeValue:self->mailDS forKey:@"mailDS"];

  if (![obj isRead])
    [obj markRead];

  return page;
}

- (NSString *)viewUrlWithArguments:(NSDictionary *)_args
  message:(NGImap4Message *)_message
{
  id       dict;
  NSString *listName;
  Class    c;
  int      cnt;

  if (_message == nil) {
    [self logWithFormat:@"%s: Missing message, args %@", __PRETTY_FUNCTION__,
          _args];
    return nil;
  }
  
  listName = [self->state name];

  if (![listName length])
    listName = @"MailList";

  c = ((cnt = [_args count]) > 0)
    ? [NSMutableDictionary class]
    : [NSDictionary class];

  dict = [c dictionaryWithObjectsAndKeys:
            [[_message url] stringValue], @"url",
            listName,                     @"listName",
            [[self session] sessionID],   @"wosid", 
            [[self context] contextID],   @"cid",
            nil];

  if (cnt > 0)
    [(NSMutableDictionary *)dict addEntriesFromDictionary:_args];

  return [[self context]
                directActionURLForActionNamed:@"SkyImapMailActions/viewImapMail"
                queryDictionary:dict];
}

- (NSString *)flagUrl {
  static NSDictionary *Dict = nil;

  if (Dict == nil) {
    NSString *v, *k;

    v = @"markFlagged";
    k = @"action";
    
    Dict = [[NSDictionary alloc]
                          initWithObjects:&v forKeys:&k count:1];
  }
  return [self viewUrlWithArguments:Dict message:[self object]];
}

- (NSString *)unFlagUrl {
  static NSDictionary *Dict = nil;

  if (Dict == nil) {
    NSString *v, *k;

    v = @"markUnFlagged";
    k = @"action";
    
    Dict = [[NSDictionary alloc]
                          initWithObjects:&v forKeys:&k count:1];
  }
  return [self viewUrlWithArguments:Dict message:[self object]];
}

- (NSString *)urlNext:(BOOL)_next unread:(BOOL)_unread {
  NGImap4Message *m;
  
  if ((m = [self nextMail:_next unread:_unread alsoOther:NO]) == nil)
    return nil;
  
  return [self viewUrlWithArguments:nil message:m];
}

- (NSString *)nextUrl {
  if (!self->url->nextCalled)
    [self->url applyNext:[self urlNext:YES unread:NO]];
  return self->url->next;
}
- (NSString *)prevUrl {
  if (!self->url->prevCalled)
    [self->url applyPrev:[self urlNext:NO unread:NO]];
  return self->url->prev;
}
- (NSString *)prevUnreadUrl {
  if (!self->url->prevUnreadCalled) {
    self->url->prevUnread       = [[self urlNext:NO unread:YES] retain];
    self->url->prevUnreadCalled = YES;
  }
  return self->url->prevUnread;
}

- (NSString *)nextUnreadUrl {
  if (!self->url->nextUnreadCalled) {
    self->url->nextUnread       = [[self urlNext:YES unread:YES] retain];
    self->url->nextUnreadCalled = YES;
  }
  return self->url->nextUnread;
}


- (BOOL)viewSourceEnabled {
  return self->viewSourceEnabled;
}
- (id)alternateShowSource {
  self->viewSourceEnabled = !self->viewSourceEnabled;
  return nil;
}

- (BOOL)hasUnFlag {
  return [[self object] isFlagged];
}

- (BOOL)hasFlag {
  return ![[self object] isFlagged];
}


- (BOOL)isDownloadAllEnabled {
  return ([[[self session]
                  valueForKey:@"displayedAttachmentDownloadUrls"] count] > 1)
    ? YES : NO;
}
- (BOOL)downloadAllEnabled {
  /* ignore first object */
  return ([self->downloadAllObjs count] < 2) ? NO : YES; 
}

- (id)downloadAll {
  id tmp;
  
  tmp = [[self session] valueForKey:@"displayedAttachmentDownloadUrls"];
  ASSIGN(self->downloadAllObjs, tmp);
  return nil;
}

- (NSString *)downloadAllString {
  // TODO: move to sepearate component
  NSMutableString *str;
  NSEnumerator *enumerator;
  NSDictionary *obj;
  int          cnt;

  str = [NSMutableString stringWithCapacity:128];

  [str appendString:@"<script type=\"text/javascript\">\n"];
  [str appendString:@"<!-- \n"];
  
  // TODO: document what kind of object the 'downloadAllObjs' array contains
  enumerator = [self->downloadAllObjs objectEnumerator];
  
  cnt        = 0;
  [enumerator nextObject]; /* ignore first object */
  
  while ((obj = [enumerator nextObject])) { 
    NSDictionary *dict;
    NSString     *name, *fname;
    
    fname = [obj objectForKey:@"name"];
    
    if ([fname length] == 0)
      fname = @"download";
    
    // TODO: construct URLs using WOContext methods!
    name = [@"SkyImapDownloadAction/download/" stringByAppendingString:fname];
    
    if ([obj objectForKey:@"url"]) {
      dict = [NSDictionary dictionaryWithObjectsAndKeys:
                           [obj objectForKey:@"url"],      @"url",
                           [obj objectForKey:@"mimeType"], @"mimeType",
                           [obj objectForKey:@"encoding"], @"encoding",
                           fname, @"filename",
                           nil];
    }
    else {
      NSString *k;
      id       d;
      
      if ((d = [obj objectForKey:@"data"]) == nil) {
        [self logWithFormat:@"missing object data for %@", obj];
        continue;
      }
      k = [NSString stringWithFormat:@"download_%d", cnt];
      [[self session] takeValue:d forKey:k];
      
      dict = [NSDictionary dictionaryWithObjectsAndKeys:
                           k, @"data_key",
                           [obj objectForKey:@"mimeType"], @"mimeType",
                           [obj objectForKey:@"encoding"], @"encoding",
                           fname, @"filename",
                           nil];
    }
  
    [str appendString:@"window.open(\""];
    [str appendString:[[self context]
                             directActionURLForActionNamed:name
                             queryDictionary:dict]];
    [str appendString:@"\", \"download_"];
    [str appendString:[[NSNumber numberWithInt:cnt++] stringValue]];
    [str appendString:@"\", \""];
    [str appendString:winJSSizing];
    [str appendString:@"\");\n"];
  }
  [str appendString:@"self.focus(); \n"];
  [str appendString:@"//-->\n"];
  [str appendString:@"</script> \n"];
  return str;
}

/* MDNPrivateMethods */

// FIRST BodyPart: the human readable part
+ (NSString *)_mdnDefaultNotification {
  // TODO: this should be localized !
  static NSString *defNotification =
    @"This is a Return Receipt for the mail you sent on "
    @"$date$ \nto $to$ with subject '$subject$'.\n\n"
    @"This only acknowledges that the message was displayed on "
    @"the recipient's machine.\n"
    @"This is no guarantee that the message has been read or understood.";
  return defNotification;
}

static inline NSString *_a(NSString *_obj) {
  return (_obj == nil)? @"" : (id)_obj;
}

- (NSDictionary *)_messageProperties {
  NGImap4Message *o;
  
  o = [self object];
  return [NSDictionary dictionaryWithObjectsAndKeys:
                       _a(self->to),                        @"to",
                       _a(self->cc),                        @"cc",
                       _a(self->bcc),                       @"bcc",
                       _a([o valueForKey:@"subject"]),      @"subject",
                       _a([o valueForKey:@"sender"]),       @"sender",
                       _a([o valueForKey:@"contentLen"]),   @"size",
                       _a([o valueForKey:@"organization"]), @"organization",
                       _a([o valueForKey:@"priority"]),     @"priority",
                       _a([o valueForKey:@"messageId"]),    @"messageId",
                       _a([o valueForKey:@"contentType"]),  @"contentType",
                       [o valueForKey:@"sendDate"],         @"date",
                       nil];
}

- (NGMimeBodyPart *)_readableMDNPart {
  NGMutableHashMap *h;
  NGMimeBodyPart   *part;
  NSString         *text;
  NSDictionary     *props;

  /* prepare header */
  h = [[NGMutableHashMap alloc] initWithCapacity:1];
  [h setObject:textPlainType forKey:@"content-type"];
  
  /* build body part */
  part  = [NGMimeBodyPart bodyPartWithHeader:h];
  text  = [self mailMDNText];
  props = [self _messageProperties];
  
  if ([text length] == 0) text = [LSWImapMailViewer _mdnDefaultNotification];
  text = [text stringByReplacingVariablesWithBindings:props];

  [part setBody:text];
  [h release]; h = nil;
  return part;
}

/* SECOND Part: the MDN part */

- (NSString *)_mdnReportingUserAgent {
  NSString *hostname;

  hostname = [[NSHost currentHost] name];
  
  if ([hostname length] == 0) hostname = [[NSHost currentHost] address];
  if ([hostname length] == 0) hostname = @"mail";
  return [[hostname description] stringByAppendingString:
                                   @"; OpenGroupware.org"];
}

- (NSString *)_mdnFinalRecipient {
  NSString *str, *t;
  id       acc;
  NSRange  r;
  
  acc = [[self session] activeAccount];
  str = [acc valueForKey:@"email1"];
  
  t = str;
  if ([t length] == 0)
    t = [acc valueForKey:@"login"];
  else if ((r = [t rangeOfString:@"<"]).length > 0) {
    // TODO: make this wrapping code a NSString category!
    t = [t substringFromIndex:(r.location + r.length)];
    
    r = [t rangeOfString:@">"];
    if (r.length == 0) {
      // can not handle address format
      [self logWithFormat:@"ERROR(%s) can not handle to - address format: %@",
            __PRETTY_FUNCTION__, str];
      // take it anyway
      t = str;
    }
    else
      t = [t substringToIndex:r.location];
  }
  return [@"rfc822;" stringByAppendingString:[t description]];
}

- (NSString *)_mdnOriginalRecipient {
  NSString       *str;
  NSEnumerator   *e;
  NSMutableArray *t;
  id             one;
  NSRange        r;

  e   = [self->emailContent valuesOfHeaderFieldWithName:@"to"];
  t   = [NSMutableArray array];

  while ((one = [e nextObject])) 
    [t addObject:one];
  if ([t count] != 1)
    return nil;

  // TODO: move to a string category
  str = [t lastObject];
  r = [str rangeOfString:@"<"];
  if (r.length > 0) {
    str = [str substringFromIndex:r.location + r.length];
    r = [str rangeOfString:@">"];
    if (r.length == 0) {
      // can not handle address format
      [self logWithFormat:@"ERROR(%s): can not handle to - address format: %@",
            __PRETTY_FUNCTION__, [t lastObject]];
      return nil;
    }
    str = [str substringToIndex:r.location];
  }
  return [@"rfc822;" stringByAppendingString:str];
}

- (NSString *)_mdnDisposition {
  NSString *type;

  type = [self mailMDNType];
  type = [type isEqualToString:@"automatic"]
    ? @"MDN-sent-automatically"
    : @"MDN-sent-manually";
  return [NSString stringWithFormat:@"manual-action/%@; displayed", type];
}

- (NGMimeBodyPart *)_mdnPart {
  NGMutableHashMap *h;
  NGMimeBodyPart   *part;
  NSMutableArray   *lines;
  NSString         *text;

  /* prepare header */
  h = [[NGMutableHashMap alloc] initWithCapacity:1];
  [h setObject:msgDispositionNotiType forKey:@"content-type"];
  
  // build body part
  part  = [NGMimeBodyPart bodyPartWithHeader:h];
  lines = [NSMutableArray array];

  // reportin UA
  text  = [self _mdnReportingUserAgent];
  if ([text length] > 0)
    [lines addObject:[@"Reporting-UA: " stringByAppendingString:text]];

  // original recipient
  text  = [self _mdnOriginalRecipient];
  if ([text length] > 0)
    [lines addObject:[@"Original-Recipient: " stringByAppendingString:text]];
  
  // final recipient
  text = [self _mdnFinalRecipient];
  if ([text length] == 0) {
    [self logWithFormat:
	    @"WARNING[%s]: invalid final recipient field for MDN, failed to "
            @"build MDN - part for disposition notification",
          __PRETTY_FUNCTION__];
    return nil;
  }
  [lines addObject:[@"Final-Recipient: " stringByAppendingString:text]];
  
  // original message id
  text = [[self object] valueForKey:@"messageId"];
  if ([text length] > 0)
    [lines addObject:[@"Original-Message-ID: " stringByAppendingString:text]];
  
  /* disposition */
  text = [self _mdnDisposition];
  [lines addObject:[@"Disposition: " stringByAppendingString:text]];
  
  /* build body */
  [lines addObject:@""];
  text = [lines componentsJoinedByString:@"\r\n"];
  
  [part setBody:[text dataUsingEncoding:NSUTF8StringEncoding]];
  [h release]; h = nil;
  return part;
}

/* THIRD PART */
- (NGMimeBodyPart *)_originalMessageHeadersPart {
  NGMutableHashMap       *h;
  NGMimeBodyPart         *part;
  NGMimeMessageGenerator *gen;
  NSData                 *data;
  NSString               *body;

  h = [[NGMutableHashMap alloc] initWithCapacity:1];
  [h setObject:textRfc822HeadersType forKey:@"content-type"];
  
  // build body part
  part = [NGMimeBodyPart bodyPartWithHeader:h];
  gen  = [[NGMimeMessageGenerator alloc] init];
  data = [gen generateHeaderData:[(NGImap4Message *)[self object] headers]];
  body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  
  [part setBody:body];

  [body release]; body = nil;
  [gen  release]; gen  = nil;
  [h    release]; h    = nil;
  
  return part;
}

/* THE MDN MESSAGE (TODO: move MDN composition to own class) */
- (NSString *)_mdnSubject {
  NSString *subject;
  
  subject = [self mailMDNSubject];

  if ([subject length] == 0) 
    subject = [[self labels] valueForKey:@"mdn_subject"];
  if ([subject length] == 0) 
    subject = @"Disposition Notification (displayed)";
  
  return [subject stringByAppendingFormat:@" - %@",
                    [[self object] valueForKey:@"subject"]];
}

- (NSString *)errorStringForDispositionNotificationTo:(NSString *)_disp
  withMailRestrictions:(SkyImapMailRestrictions *)mailRestrictions
{
  NSMutableString *ms;
  id labels;
  
  labels = [self labels];
  ms = [NSMutableString stringWithCapacity:256];
  [ms appendString:[labels valueForKey:@"mdnSendProhibitedToError"]];
  [ms appendString:@"\n"];
  [ms appendString:[labels valueForKey:@"prohibitedAddressError"]];
  [ms appendString:@":\n"];
  [ms appendString:[self->dispositionNotificationTo stringValue]];
  [ms appendString:@"\n"];
  [ms appendString:[labels valueForKey:@"allowedAddressError"]];
  [ms appendString:@":\n"];
  [ms appendString:[[mailRestrictions allowedDomains] description]];
  return ms;
}

- (BOOL)_checkMailRestrictionsWithHeaderMap:(NGMutableHashMap *)hs {
  SkyImapMailRestrictions *mailRestrictions;
  LSCommandContext *cmdctx;
  
  cmdctx           = [[self session] commandContext];
  mailRestrictions = [SkyImapMailRestrictions alloc]; // to avoid warnings
  mailRestrictions = [mailRestrictions initWithContext:(id)cmdctx];
  
  if (![mailRestrictions emailAddressAllowed:
                           self->dispositionNotificationTo]) {
    NSString *s;
    
    s = [self errorStringForDispositionNotificationTo:
		self->dispositionNotificationTo
	      withMailRestrictions:mailRestrictions];
    [self setErrorString:s];
    [mailRestrictions release]; mailRestrictions = nil;
    return NO;
  }
  
  [hs addObject:self->dispositionNotificationTo forKey:@"to"];
  [mailRestrictions release]; mailRestrictions = nil;
  return YES;
}
- (void)_applyMdnMessageFromHeaderWithMap:(NGMutableHashMap *)hs {
  NSString *from;
  id       acc;

  acc  = [[self session] activeAccount];
  from = [acc valueForKey:@"email1"];
    
  if ([from length] == 0) from = [acc valueForKey:@"login"];

  [hs setObject:from forKey:@"from"];
}

- (NGMimeMessage *)_mdnMessage {
  NGMutableHashMap    *hs;
  NGMimeMessage       *message;
  NGMimeMultipartBody *body;

  hs = [[NGMutableHashMap alloc] initWithCapacity:16];
  
  if (![self _checkMailRestrictionsWithHeaderMap:hs])
    return nil;
  
  /* setting headers */
  [hs addObject:[self _mdnSubject]    forKey:@"subject"];
  [hs addObject:[NSCalendarDate date] forKey:@"date"];
  [hs addObject:@"1.0"                forKey:@"MIME-Version"];
  [hs addObject:xMailer               forKey:@"X-Mailer"];

  [self _applyMdnMessageFromHeaderWithMap:hs];
  [hs addObject:multipartReportType forKey:@"content-type"];
  
  /* building message */
  message = [[NGMimeMessage alloc] initWithHeader:hs];
  [hs release]; hs = nil;
  
  // building multipart body

  body = [[NGMimeMultipartBody alloc] initWithPart:message];
  [body addBodyPart:[self _readableMDNPart]];
  [body addBodyPart:[self _mdnPart]];
  [body addBodyPart:[self _originalMessageHeadersPart]];

  [message setBody:body];
  [body release]; body = nil;
  
  return [message autorelease];
}

@end /* LSWImapMailViewer */

@implementation LSWMailViewerURLState

- (void)dealloc {
  [self->next       release];
  [self->prev       release];
  [self->prevUnread release];
  [self->nextUnread release];
  [super dealloc];
}

/* operations */

- (void)applyNext:(NSString *)_next {
  self->next       = [_next copy];
  self->nextCalled = YES;
}
- (void)applyPrev:(NSString *)_prev {
  self->prev       = [_prev copy];
  self->prevCalled = YES;
}

- (void)reset {
  [self->next       release]; self->next       = nil;
  [self->prev       release]; self->prev       = nil;
  [self->prevUnread release]; self->prevUnread = nil;
  [self->nextUnread release]; self->nextUnread = nil;
  
  self->nextCalled       = NO;
  self->prevCalled       = NO;
  self->prevUnreadCalled = NO;
  self->nextUnreadCalled = NO;
}

@end /* LSWMailViewerURLState */
