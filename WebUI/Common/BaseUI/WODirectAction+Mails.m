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

#include "common.h"

/*
  Note: why is this not in the OGoWebMail bundle? Easy: because the webmail
        bundle may not yet be loaded when we want to access mail direct
        actions (which in turn will load the mailer bundle ...).
*/

@interface WOComponent(MailComponentAPI)

- (id)imapContext;
- (void)setSelectedFolder:(id)_folder;
- (void)setTabKey:(NSString *)_key;
- (void)setImapContext:(id)_ctx;
- (void)setAccount:(id)_account;

- (id)trashFolder;
- (id)sentFolder;
- (id)draftsFolder;

@end 

@interface WOComponent(MailEditorAPI)
- (void)setMailSubject:(NSString *)_s;
- (void)addMimePart:(id)_part type:(NGMimeType *)_type name:(NSString *)_name;
@end

@interface NSObject(ImapContext)
- (id)folderWithName:(NSString *)_name;
- (id)folderWithName:(NSString *)_name caseInsensitive:(BOOL)_flag;
@end

@interface WOComponent(LSWImapMailsPage)
- (id)folderClicked;
- (void)setContentWithoutSign:(NSString *)_sign;
@end

@implementation WODirectAction(Mails)

- (WOComponent *)_activateMailFolder:(NSString *)folderName
  inMailer:(WOComponent *)_mailer
{
  id ctx;
  id folder;

  if ((ctx = [_mailer imapContext]) == nil)
    /* show login page */
    return _mailer;
  
  if ([folderName isEqualToString:@"trash"])
    folder = [ctx trashFolder];
  else if ([folderName isEqualToString:@"sent"])
    folder = [ctx sentFolder];
  else if ([folderName isEqualToString:@"drafts"])
    folder = [ctx draftsFolder];
  else
    folder = nil;
  
  if (folder == nil) 
    folder = [ctx folderWithName:folderName caseInsensitive:YES];
  
  [_mailer setSelectedFolder:folder];
  [_mailer setTabKey:@"mail"];
  [_mailer folderClicked];
  
  return _mailer;
}

- (WOComponent *)_activateMailEditorWithIMAP4Context:(id)ctx {
  /* TODO: split up this big method */
  static NSDictionary *mimeTypes = nil;
  WOComponent  *editorPage;
  WORequest    *req;
  NSEnumerator *enumerator;
  NSString     *key, *tmp;

  if (mimeTypes == nil) {
    mimeTypes = [[[NSUserDefaults standardUserDefaults] 
		   dictionaryForKey:@"LSMimeTypes"] copy];
  }
  
  req = [self request];
  
  //  [self logWithFormat:@"httpReq %@", [req httpRequest]];

  editorPage = [self pageWithName:@"LSWImapMailEditor"];
  
  [editorPage setImapContext:ctx];
  
  if ((tmp = [req formValueForKey:@"subject"]))
    [editorPage setMailSubject:tmp];

  if (!(tmp = [req formValueForKey:@"mailText"]))
    tmp = @""; /* necessary to set the signature */
                  
  [editorPage setContentWithoutSign:tmp];
  
  // TODO: should work, but needs to be checked
  enumerator = [[req formValuesForKey:@"__attachment__"] objectEnumerator];
  enumerator = [[req formValueKeys] objectEnumerator];
  
  while ((key = [enumerator nextObject])) {
    NGMimeType   *mt;
    NSString     *fn, *ft, *type, *stype, *mimetype;
    NSDictionary *para;
    id           d;

    if (![key hasPrefix:@"__attachment_"])
      continue;
    
    fn = [key substringFromIndex:[@"__attachment_" length]];
    // NSLog(@"filename %@", fn);

    ft = [fn pathExtension];

    para =  (fn == nil) ? nil :
	[NSDictionary dictionaryWithObjectsAndKeys:
                        fn, @"name", nil];
    mimetype = nil;
        
    if ([ft length] > 0)
      mimetype = [mimeTypes valueForKey:ft];

    type  = nil;
    stype = nil;
    if (mimetype) { /* TODO: hh asks, can't we use the NGMimeType parsing? */
      NSArray *a;
	
      a = [mimetype componentsSeparatedByString:@"/"];
      if ([a count] > 1) { 
	type  = [a objectAtIndex:0];
	stype = [a objectAtIndex:1];
      }
    }
    if (type == nil) {
      type  = @"application";
      stype = @"octet-stream";
    }
    mt = [NGMimeType mimeType:type
		     subType:stype
		     parameters:para];
    d  = [req formValueForKey:key];

    if ([d isKindOfClass:[NSString class]])
	d = [d dataByDecodingBase64];
    else if ([d isKindOfClass:[NSData class]])
	d = [d dataByDecodingBase64];
    else {
	[self logWithFormat:@"unexpected data type for mail action: %@", 
	      NSStringFromClass([d class])];
    }
    if (d)
      [editorPage addMimePart:d type:mt name:fn];
  }
  [[[self session] navigation] enterPage:editorPage];
  return editorPage;
}

- (id<WOActionResults>)mailAction {
  NSString    *folderName;
  WOComponent *page;
  id          ctx;
  
  folderName = [[self request] formValueForKey:@"folder"];
  page       = [self pageWithName:@"LSWImapMails"]; /* init imap context */
  
  ctx = [page imapContext];
  
  if ([folderName length] > 0) { /* show folder */
    if (ctx == nil) /* to view the folder, login is required */
      return page;
    
    page = [self _activateMailFolder:folderName inMailer:page];
    [[[self session] navigation] enterPage:page];
    return page;
  }
  
  return [self _activateMailEditorWithIMAP4Context:ctx];
}

static NSArray  *AllPrefKeys  = nil;
static NSString *FolderKey    = nil;
static NSString *SignatureKey = nil;

- (id<WOActionResults>)mailPrefAction {
  NSString *key;
  id       page;

  if (AllPrefKeys == nil) {
    AllPrefKeys = [[NSArray alloc]
                            initWithObjects:
                            @"mail_pref_expand_mailList",
                            @"mail_pref_expand_searchMailList",
                            @"mail_pref_expand_generalDefaults",
                            @"mail_pref_expand_generalMailList",
                            @"mail_pref_expand_signature",
                            @"mail_pref_expand_specialFolder",
                            nil];
  }
  if (FolderKey == nil) {
    FolderKey = [@"mail_pref_expand_specialFolder" retain];
  }
  if (SignatureKey == nil) {
    SignatureKey = [@"mail_pref_expand_signature" retain];
  }

  key  = [[self request] formValueForKey:@"key"];
  page = [self pageWithName:@"LSWMailPreferences"];
  [page setAccount:[[self session] activeAccount]];

  if ([key isEqualToString:@"signature"])
    key = SignatureKey;
  else if ([key isEqualToString:@"folder"])
    key = FolderKey;
  else 
    key = nil;
  
  {
    NSEnumerator *enumerator;
    id           obj;
    id           ud;
    
    enumerator = [AllPrefKeys objectEnumerator];
    ud         = [[self session] userDefaults];
    while ((obj = [enumerator nextObject])) {
      if (key) {
        if ([obj isEqualToString:key])
          [ud setBool:YES forKey:obj];
        else
          [ud setBool:NO forKey:obj];
      }
      else {
        [ud setBool:YES forKey:obj];
      }
    }
  }
  [[[self session] navigation] enterPage:page];

  return page;
}

@end /* WODirectAction(Mails) */
