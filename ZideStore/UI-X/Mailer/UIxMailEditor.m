/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include <SOGoUI/UIxComponent.h>

/*
  UIxMailEditor
  
  An mail editor component which works on SOGoDraftObject's.
*/

@class NSArray, NSString;
@class SOGoMailFolder;

@interface UIxMailEditor : UIxComponent
{
  NSArray  *to;
  NSArray  *cc;
  NSArray  *bcc;
  NSString *subject;
  NSString *text;
  SOGoMailFolder *sentFolder;
}

@end

#include <SoObjects/Mailer/SOGoDraftObject.h>
#include <SoObjects/Mailer/SOGoMailFolder.h>
#include <SoObjects/Mailer/SOGoMailAccount.h>
#include <NGMail/NGMimeMessage.h>
#include <NGMail/NGMimeMessageGenerator.h>
#include "common.h"

@interface UIxComponent (Scheduler_Privates)
- (NSString *)emailForUser;
@end

@implementation UIxMailEditor

static BOOL         keepMailTmpFile    = NO;
static BOOL         showInternetMarker = NO;
static EOQualifier  *internetDetectQualifier = nil;
static NSDictionary *internetMailHeaders     = nil;
static NSArray      *infoKeys = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString *s;
  
  infoKeys = [[NSArray alloc] initWithObjects:
				@"subject", @"text", @"to", @"cc", @"bcc", 
			        @"from", @"replyTo",
			      nil];
  
  keepMailTmpFile = [ud boolForKey:@"SOGoMailEditorKeepTmpFile"];
  if (keepMailTmpFile)
    NSLog(@"WARNING: keeping mail files.");

  /* Internet mail settings */
  
  showInternetMarker = [ud boolForKey:@"SOGoShowInternetMarker"];
  if (!showInternetMarker) {
    NSLog(@"Note: visual Internet marker on mail editor disabled "
	  @"(SOGoShowInternetMarker)");
  }
  
  if ((s = [ud stringForKey:@"SOGoInternetDetectQualifier"]) != nil) {
    internetDetectQualifier = 
      [[EOQualifier qualifierWithQualifierFormat:s] retain];
    if (internetDetectQualifier == nil)
      NSLog(@"ERROR: could not parse qualifier: '%@'", s);
  }
  if (internetDetectQualifier == nil)
    NSLog(@"Note: no 'SOGoInternetDetectQualifier' configured.");
  else
    NSLog(@"Note: detect Internet access using: %@", internetDetectQualifier);
  
  internetMailHeaders = 
    [[ud dictionaryForKey:@"SOGoInternetMailHeaders"] copy];
  NSLog(@"Note: specified %d headers for mails send via the Internet.", 
	[internetMailHeaders count]);
}

- (void)dealloc {
  [self->sentFolder release];
  [self->text    release];
  [self->subject release];
  [self->to      release];
  [self->cc      release];
  [self->bcc     release];
  [super dealloc];
}

/* accessors */

- (void)setFrom:(NSString *)_ignore {
}
- (NSString *)from {
  return [self emailForUser];
}
- (void)setReplyTo:(NSString *)_ignore {
}
- (NSString *)replyTo {
  /* we are here for future extensibility */
  return @"";
}

- (void)setSubject:(NSString *)_value {
  ASSIGNCOPY(self->subject, _value);
}
- (NSString *)subject {
  return self->subject ? self->subject : @"";
}

- (void)setText:(NSString *)_value {
  ASSIGNCOPY(self->text, _value);
}
- (NSString *)text {
  return [self->text isNotNull] ? self->text : @"";
}

- (void)setTo:(NSArray *)_value {
  ASSIGNCOPY(self->to, _value);
}
- (NSArray *)to {
  return [self->to isNotNull] ? self->to : [NSArray array];
}

- (void)setCc:(NSArray *)_value {
  ASSIGNCOPY(self->cc, _value);
}
- (NSArray *)cc {
  return [self->cc isNotNull] ? self->cc : [NSArray array];
}

- (void)setBcc:(NSArray *)_value {
  ASSIGNCOPY(self->bcc, _value);
}
- (NSArray *)bcc {
  return [self->bcc isNotNull] ? self->bcc : [NSArray array];
}

/* title */

- (NSString *)panelTitle {
  return [self labelForKey:@"Compose Mail"];
}

/* detect webmail being accessed from the outside */

- (BOOL)isInternetRequest {
  // TODO: make configurable! (eg allow specification of a qualifier)
  WORequest *rq;
  
  rq = [[self context] request];
  return [(id<EOQualifierEvaluation>)internetDetectQualifier
				     evaluateWithObject:[rq headers]];
}

- (BOOL)showInternetMarker {
  if (!showInternetMarker)
    return NO;
  return [self isInternetRequest];
}

/* info loading */

- (void)loadInfo:(NSDictionary *)_info {
  if (![_info isNotNull]) return;
  [self debugWithFormat:@"loading info ..."];
  [self takeValuesFromDictionary:_info];
}
- (NSDictionary *)storeInfo {
  [self debugWithFormat:@"storing info ..."];
  return [self valuesForKeys:infoKeys];
}

/* requests */

- (BOOL)shouldTakeValuesFromRequest:(WORequest *)_rq inContext:(WOContext*)_c{
  return YES;
}

/* IMAP4 store */

- (NSException *)patchFlagsInStore {
  /*
    Flags we should set:
      if the draft is a reply   => [message markAnswered]
      if the draft is a forward => [message addFlag:@"forwarded"]
      
    This is hard, we would need to find the original message in Cyrus.
  */
  return nil;
}

- (id)lookupSentFolder {
  SOGoMailAccount *account;
  SOGoMailFolder  *folder;
  
  if (self->sentFolder != nil)
    return self;
  
  account = [[self clientObject] mailAccountFolder];
  if ([account isKindOfClass:[NSException class]]) return account;
  
  folder = [account sentFolderInContext:[self context]];
  if ([folder isKindOfClass:[NSException class]]) return folder;
  return ((self->sentFolder = [folder retain]));
}

- (NSException *)storeMailInSentFolder:(NSString *)_path {
  SOGoMailFolder *folder;
  NSData *data;
  id result;
  
  folder = [self lookupSentFolder];
  if ([folder isKindOfClass:[NSException class]]) return (id)folder;
  
  if ((data = [[NSData alloc] initWithContentsOfMappedFile:_path]) == nil) {
    return [NSException exceptionWithHTTPStatus:500 /* server error */
			reason:@"could not temporary draft file!"];
  }
  
  result = [folder postData:data flags:@"seen"];
  [data release]; data = nil;
  return result;
}

/* actions */

- (BOOL)_saveFormInfo {
  NSDictionary *info;
  
  if ((info = [self storeInfo]) != nil) {
    NSException *error;
    
    if ((error = [[self clientObject] storeInfo:info]) != nil) {
      [self errorWithFormat:@"failed to store draft: %@", error];
      // TODO: improve error handling
      return NO;
    }
  }
  
  // TODO: wrap content
  
  return YES;
}
- (id)failedToSaveFormResponse {
  // TODO: improve error handling
  return [NSException exceptionWithHTTPStatus:500 /* server error */
		      reason:@"failed to store draft object on server!"];
}

- (id)defaultAction {
  return [self redirectToLocation:@"edit"];
}

- (id)editAction {
  [self logWithFormat:@"edit action, load content from: %@",
	  [self clientObject]];
  
  [self loadInfo:[[self clientObject] fetchInfo]];
  return self;
}

- (id)saveAction {
  return [self _saveFormInfo] ? self : [self failedToSaveFormResponse];
}

- (id)sendAction {
  NSException  *error;
  NSString     *mailPath;
  NSDictionary *h;
  
  // TODO: need to validate whether we have a To etc
  
  /* first, save form data */
  
  if (![self _saveFormInfo])
    return [self failedToSaveFormResponse];

  /* setup some extra headers if required */
  
  h = [self isInternetRequest] ? internetMailHeaders : nil;
  
  /* save mail to file (so that we can upload the mail to Cyrus) */
  // TODO: all this could be handled by the SOGoDraftObject?
  
  mailPath = [[self clientObject] saveMimeMessageToTemporaryFileWithHeaders:h];
  
  /* then, send mail */
  
  if ((error = [[self clientObject] sendMimeMessageAtPath:mailPath]) != nil) {
    // TODO: improve error handling
    [[NSFileManager defaultManager] removeFileAtPath:mailPath handler:nil];
    return error;
  }
  
  /* patch flags in store for replies etc */
  
  if ((error = [self patchFlagsInStore]) != nil)
     return error;
  
  /* finally store in Sent */

  if ((error = [self storeMailInSentFolder:mailPath]) != nil)
    return error;
  
  /* delete temporary mail file */
  
  if (keepMailTmpFile)
    [self warnWithFormat:@"keeping mail file: '%@'", mailPath];
  else
    [[NSFileManager defaultManager] removeFileAtPath:mailPath handler:nil];
  mailPath = nil;
  
  /* delete draft */
  
  if ((error = [[self clientObject] delete]) != nil)
    return error;

  // if everything is ok, close the window (send a JS closing the Window)
  return [self pageWithName:@"UIxMailWindowCloser"];
}

- (id)deleteAction {
  NSException *error;
  id page;
  
  if ((error = [[self clientObject] delete]) != nil)
    return error;
  
#if 1
  page = [self pageWithName:@"UIxMailWindowCloser"];
  [page takeValue:@"YES" forKey:@"refreshOpener"];
  return page;
#else
  // TODO: if we just return nil, we produce a 500
  return [NSException exceptionWithHTTPStatus:204 /* No Content */
		      reason:@"object was deleted."];
#endif
}

@end /* UIxMailEditor */
