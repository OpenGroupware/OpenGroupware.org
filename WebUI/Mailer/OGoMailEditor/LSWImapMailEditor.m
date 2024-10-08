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

#include "LSWImapMailEditor.h"
#include <OGoWebMail/SkyImapMailRestrictions.h>
#include <OGoWebMail/SkyImapContextHandler.h>
#include "NGMimeType+Mailer.h"
#include "NSString+MailEditor.h"
#include "OGoMailAddressSearch.h"
#include "common.h"
#include <NGExtensions/NSString+Ext.h>
#include <NGMime/NGMimeFileData.h>

// TODO: this file is WAY to big and needs to be split into several classes
// TODO: an address record 'dictionary' should probably be an own object?
// TODO: add a special object for 'uploadItem'

@class NSString, NSMutableDictionary;
@class NGImap4Context;

@interface LSWImapMailEditor(AddressFormation)
// TODO: move to a formatter subclass
+ (NSString *)_eAddressLabelForPerson:(id)_person
  andAddress:(NSString *)_addr;
+ (NSString *)_eAddressForPerson:(id)_person;
+ (NSString *)_eAddressLabelForPerson:(id)_person;
+ (NSString *)_formatEmail:(NSString *)_email forPerson:(id)_person;
@end /* LSWImapMailEditor(AddressFormation) */

@interface NSObject(LSWImapMailEditor_PRIVATE)

- (BOOL)useEpoz;
- (void)setDate:(id)_date;
- (void)setContent:(id)_ctn;
- (NGImap4Context *)imapContext;
- (void)setPart:(id)_id;
- (void)setShowBody:(BOOL)_bool;
- (NSString *)tabKey;
- (void)setTabKey:(NSString *)_str;
- (void)setShowRfc822:(BOOL)_bool;
- (void)setEscapeHtml:(BOOL)_b;

- (void)_confirmAddress;

- (void)_setBodyForReply:(id)_obj from:(NSString *)_from part:(id)_part;
- (void)_setBodyForForward:(id)_obj from:(NSString *)_from;

- (id)_buildMultipartAlternativePart:(NGMimeMessage *)_msg;

- (NSMutableArray *)_searchPersons:(NSString *)_s;
- (NSData *)_getIdForObject:(id)_obj;
- (NGMimeBodyPart *)_buildExternalViewerPart;
- (NGMimeBodyPart *)_buildInternalViewerPart;
- (void)_buildEditAsNewForText:(id<NGMimePart>)_part type:(NGMimeType *)_type;

- (id)confirmUpload;
- (id)confirmUploadWithData:(NSData *)_data fileName:(NSString *)_fileName;
- (NSString *)searchString;
- (void)setSearchString:(NSString *)_str;

- (void)setAttachment:(NSMutableDictionary *)_att;
- (NSMutableDictionary *)attachment;
- (id)attachmentContentType;
- (id)attachmentObject;

- (void)setAttachments:(NSMutableArray *)_att;
- (NSMutableArray *)attachments;

- (void)setMailText:(NSString *)_text;
- (NSString *)mailText;

- (void)setMailSubject:(NSString *)_subject;
- (NSString *)mailSubject;

- (void)setAddresses:(NSMutableArray *)_array;
- (NSMutableArray *)addresses;

- (void)setAddressEntry:(NSDictionary *)_entry;
- (NSDictionary *)addressEntry;

- (void)setCount:(unsigned)_count;
- (unsigned)count;

- (BOOL)isLastEntry;

- (id)attachmentParts;
- (NSArray *)addressKeys;

- (void)setAddressEntryPopupItem:(id)_item;
- (id)addressEntryPopupItem;

- (NSArray *)attachmentsAsMime;
- (BOOL)sendMessageToSent:(NSString *)_msg;
- (BOOL)sendMessageToDrafts:(NSString *)_msg;

- (SkyImapMailRestrictions *)mailRestrictions;
- (void)_initUploadArray;

- (NSString *)_checkTxtBody:(id)_body;
- (NSString *)_checkOther:(NGMimeBodyPart *)_part;
- (NSString *)_checkMixed:(NGMimeBodyPart *)_part;
- (NSString *)_checkAlternative:(NGMimeBodyPart *)_part;

@end

@implementation LSWImapMailEditor

static int          LSWMailLogEnabled             = -1;
static int          UseCCForMultipleAddressSearch = -1;
static int          SearchMailingLists  = -1;
static int          UseMemoryStoredMime = 0;
static int          IsEpozEnabled       = 0;
static int          MaxAttachmentSize   = 0;
static int          TextFieldSize       = 0;
static BOOL         Mail_Use_8bit_Encoding_For_Text = NO;
static NSString     *skyrixId           = nil;
static NSString     *CompanyDisclaimer  = nil;
static NSString     *htmlMailHeader     = nil;
static NSString     *htmlMailFooter     = nil;
static NSString     *OGoXMailer         = nil;
static NSDictionary *mimeTypeMap        = nil;

static NGMimeType *AppOctetType   = nil;
static NGMimeType *altType        = nil;
static NGMimeType *TextHtmlType   = nil;
static NGMimeType *TextPlainType  = nil;
static NGMimeType *MultiMixedType = nil;
static NGMimeType *MultiSxType    = nil;
static NGMimeType *MultiSxTypeID  = nil;
static NSNumber   *YesNum         = nil;
static NSNumber   *NoNum          = nil;
static Class      DataClass       = nil;
static Class      StrClass        = nil;

+ (void)initialize {
  // TODO: check superclass version
  static BOOL didInit = NO;
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  if (didInit) return;
  didInit = YES;
  
  DataClass = [NSData   class];
  StrClass  = [NSString class];

  OGoXMailer = [[ud stringForKey:@"OGoXMailer"] copy];
  
  LSWMailLogEnabled   = [ud boolForKey:@"LSWMailLogEnabled"]     ? 1 : 0;
  SearchMailingLists  = [ud boolForKey:@"UseMailingListManager"] ? 1 : 0;
  UseMemoryStoredMime = [ud boolForKey:@"UseMemoryStoredMime"]   ? 1 : 0;
  UseCCForMultipleAddressSearch = 
    [ud boolForKey:@"UseCCForMultipleAddressSearch"] ? 1 : 0;
  Mail_Use_8bit_Encoding_For_Text = 
    [ud boolForKey:@"Mail_Use_8bit_Encoding_For_Text"];
  
  IsEpozEnabled = [ud boolForKey:@"DisableEpozEditor"] ? 0 : 1;
  
  MaxAttachmentSize = [ud integerForKey:@"MaxMailAttachmentsSize"];
  TextFieldSize     = [ud integerForKey:@"MailEditor_TextFieldSize"];
  
  skyrixId          = [[ud stringForKey:@"skyrix_id"] copy];
  CompanyDisclaimer = [[ud stringForKey:@"CompanyMailDisclaimer"] copy];
  htmlMailHeader    = [[ud stringForKey:@"mail_editor_htmlmail_header"] copy];
  htmlMailFooter    = [[ud stringForKey:@"mail_editor_htmlmail_footer"] copy];
  
  mimeTypeMap = [[ud dictionaryForKey:@"LSMimeTypes"] copy];
  
  YesNum = [[NSNumber numberWithBool:YES] retain];
  NoNum  = [[NSNumber numberWithBool:NO]  retain];
  
  AppOctetType = 
    [[NGMimeType mimeType:@"application" subType:@"octet-stream"] copy];
  altType = [[NGMimeType mimeType:@"multipart" subType:@"alternative"] copy];
  TextPlainType  = [[NGMimeType mimeType:@"text"      subType:@"plain"]  copy];
  TextHtmlType   = [[NGMimeType mimeType:@"text"      subType:@"html"]   copy];
  MultiMixedType = [[NGMimeType mimeType:@"multipart" subType:@"mixed"]  copy];
  MultiSxType    = [[NGMimeType mimeType:@"multipart" subType:@"skyrix"] copy];
  
  if (skyrixId != nil) {
    NSDictionary *paras;
    
    paras = [[NSDictionary alloc] initWithObjectsAndKeys: 
				    skyrixId, @"skyrix_id", nil];
    MultiSxTypeID = [[NGMimeType mimeType:@"multipart" subType:@"skyrix"
				 parameters:paras] retain];
    [paras release]; paras = nil;
  }
  else
    MultiSxTypeID = [MultiSxType retain];
}

- (NSUserDefaults *)userDefaults {
  return [[self existingSession] userDefaults];
}

- (void)_setupFromPopUp {
  NSUserDefaults *def;
  NSString       *defKey;
  BOOL v;

  def = [self userDefaults]; 
  
  if ([def boolForKey:@"mail_enableFromPopup"])
    v = NO;
  else {
    id obj;
    
    obj = [def objectForKey:@"mail_from_type_enabled"];
    v = (obj == nil) ? YES : [obj boolValue];
  }

  defKey = v ? @"MailHeaderFields" : @"MailHeaderFieldsWithoutFrom";
  self->addressKeys = [[def arrayForKey:defKey] copy];
}

- (id)init {
  if ((self = [super init]) != nil) {
    self->addresses   = [[NSMutableArray alloc] initWithCapacity:4];
    self->attachments = [[NSMutableArray alloc] initWithCapacity:8];
    self->mimeParts   = [[NSMutableArray alloc] initWithCapacity:5];
    self->warningKind = Warning_Send;
    
    if ([self useEpoz]) {
      self->flags.sendPlainText = 1;
    }
    else {
      NSString *type;
      
      type = [[self userDefaults] objectForKey:@"mail_send_type"];
      self->flags.sendPlainText = ([type isNotNull] && [type isEqual:@"plain"])
        ? 1 : 0;
    }
    [self _setupFromPopUp];
    [self _initUploadArray];
  }
  return self;
}

- (void)dealloc {
  [self->addressKey     release];
  [self->addressKeys    release];
  [self->pwd            release];
  [self->login          release];
  [self->host           release];
  [self->addresses      release];
  [self->mimeParts      release];
  [self->mailText       release];
  [self->mailSubject    release];
  [self->attachments    release];
  [self->uploadArray    release];
  [self->uploadItem     release];
  [self->searchString   release];
  [self->selectedFrom   release];
  [super dealloc];
}

/* commands */

- (NSArray *)_getMemberEOsOfTeamEO:(id)_team {
  NSArray *members;
  
  if ((members = [_team valueForKey:@"members"]) != nil)
    return members;
  
  members = [self runCommand:@"team::members", @"object", _team, nil];
  return [_team valueForKey:@"members"];
}

- (NSArray *)_extSearch:(NSString *)_entity matchingRecord:(id)_rec {
  // TBD:hh(2024-09-19): This was unset, I assume the entity argument is the
  //                     necessary value (person or enterprise).
  NSString *scmd;
  if (_rec == nil) return nil;
  scmd = [_entity stringByAppendingString:@"::extended-search"]; // person or enterprise
  return [self runCommandInTransaction:scmd,
	         @"searchRecords", [NSArray arrayWithObjects:_rec, nil],
	         @"operator", @"OR",
	       nil];
}
- (NSArray *)_extSearch:(NSString *)_ent matchingAllRecords:(NSArray *)_recs {
  // TBD:hh(2024-09-19): This was unset, I assume the entity argument is the
  //                     necessary value (person or enterprise).
  NSString *scmd;
  if (_recs == nil) return nil;
  scmd = [_ent stringByAppendingString:@"::extended-search"]; // person or enterprise
  return [self runCommandInTransaction:scmd, 
	         @"searchRecords", _recs,
	         @"operator", @"AND",
	       nil];
}
- (id)_newPersonSearchRecord {
  return [self runCommand:@"search::newrecord", @"entity", @"Person", nil];
}
- (id)_newEnterpriseSearchRecord {
  return [self runCommand:@"search::newrecord", @"entity", @"Enterprise", nil];
}

- (id)_getTeamEOsMatchingName:(NSString *)_name {
  return [self runCommandInTransaction:@"team::get",
	         @"description", _name,
                 @"returnType",
                 [NSNumber numberWithInt:LSDBReturnType_ManyObjects], nil];
}

- (id)_deliverMailTo:(NSArray *)_addrs messageFilePath:(NSString *)_path {
  return [self runCommand:@"email::deliver",
	         @"copyToSentFolder", [NSNumber numberWithBool:NO],
	         @"addresses",        _addrs,
	         @"messageTmpFile",   _path,
	       nil];
}
- (NSException *)_deliverMailTo:(NSArray *)_addrs
  messageFilePath:(NSString *)_path
  mailingLists:(NSArray *)_lists
{
  NSException *e;
  
  e = [self runCommand:@"email::deliver",
	  @"copyToSentFolder", [NSNumber numberWithBool:NO],
	  @"addresses",        _addrs,
	  @"messageTmpFile",   _path,
	  @"mailingLists",     _lists,
	nil];
  if ([e isKindOfClass:[NSException class]])
    return e;
  
  return nil;
}

/* page restoration (used to save the mail if the sessions was killed) */

- (void)prepareForRestorePage {
  self->flags.sendPlainText = 0;
  self->flags.returnReceipt = 0;
}

/* operations */

- (NSDictionary *)_emptyEntry {
  NSString *l;
  
  // TODO: use some specific object instead of NSDictionary ...
  l = [[self labels] valueForKey:@"ignore"];
  return [[[NSDictionary alloc] initWithObjectsAndKeys:
                                  @"", @"email",
                                  l, @"label", nil] autorelease];
}

/* content-page type, triggers different portal behaviour */

- (BOOL)isEditorPage {
  return YES;
}

/* addresses */

+ (NSString *)_eAddressForPerson:(id)_person {
  NSString *eAddr;
  
  if ([(eAddr = [_person valueForKey:@"email1"]) isNotNull])
    return eAddr;
  if ([(eAddr = [_person valueForKey:@"email2"]) isNotNull])
    return eAddr;
  return [_person valueForKey:@"email3"];
}

- (NSString *)_eAddressForPerson:(id)_person {
  return [LSWImapMailEditor _eAddressForPerson:_person];
}

- (EODataSource *)mailingListDS {
  EODataSource     *ds;
  LSCommandContext *cmdctx;
  
  cmdctx = (id)[[self session] commandContext];
  ds = [NGClassFromString(@"SkyMailingListDataSource") alloc];
  
  // TODO: fix prototype (this is not a SkyAccessManager ..)
  ds = [(SkyAccessManager *)ds initWithContext:(id)cmdctx];
  return [ds autorelease];
}


- (NSString *)_eAddressLabelForPerson:(id)_pEO andAddress:(NSString *)_addr {
  return [LSWImapMailEditor _eAddressLabelForPerson:_pEO andAddress:_addr];
}

+ (NSString *)_eAddressLabelForPerson:(id)_person andAddress:(NSString *)_addr{
  // TODO: move to a formatter class!
  NSMutableString *ms;
  NSString *firstName, *lastName;
  
  ms = [NSMutableString stringWithCapacity:128];
  
  firstName = [_person valueForKey:@"firstname"];
  lastName  = [_person valueForKey:@"name"];
  
  if ([firstName isNotEmpty])
    [ms appendString:firstName];
  else
    firstName = nil;

  if ([lastName isNotEmpty]) {
    if (firstName != nil) [ms appendString:@" "];
    [ms appendString:lastName];
  }
  else
    lastName = nil;
  
  if (firstName != nil || lastName != nil) {
    [ms appendString:@" <"];
    [ms appendString:_addr];
    [ms appendString:@">"];
    return ms;
  }
  
  return _addr;
}

+ (NSString *)_formatEmail:(NSString *)_email forPerson:(id)_person {
  // TODO: is this a dup? looks almost the same like above
  NSString *firstName, *lastName, *sep;
  
  if ([_email mailAddressContainsPersonName])
    return _email;
  
  firstName = [_person valueForKey:@"firstname"];
  lastName  = [_person valueForKey:@"name"];
  sep       = @" ";

  if (firstName == nil) {
    firstName = @"";
    sep       = @"";
  }
  else
    firstName = [firstName stringByRemovingMailSpecialsInPersonName];
  
  if (lastName == nil) {
    lastName = @"";
    sep      = @"";                  
  }
  else
    lastName = [lastName stringByRemovingMailSpecialsInPersonName];
  
  if (([firstName length] == 0) && ([lastName length] == 0))
    return _email;
  
  return [StrClass stringWithFormat:@"\"%@%@%@\" <%@>",
                   firstName, sep, lastName, _email];
}

- (NSString *)_formatEmail:(NSString *)_email forPerson:(id)_person {
  return [LSWImapMailEditor _formatEmail:_email forPerson:_person];
}

- (NSString *)_eAddressLabelForPerson:(id)_person {
  return [LSWImapMailEditor _eAddressLabelForPerson:_person];
}

+ (NSString *)_eAddressLabelForPerson:(id)_person {
  NSString *str;

  if ((str = [LSWImapMailEditor _eAddressForPerson:_person]) == nil)
    str = [_person valueForKey:@"login"];
  
  if (![str isNotNull])
    str = @"";
  
  return [LSWImapMailEditor _eAddressLabelForPerson:_person andAddress:str];
}

/* actions */

- (NSString *)_preprocessSearchItem:(NSString *)searchItem {
  return [searchItem stringByTrimmingLeadSpaces];
}
- (id)_processesProhibitedAddresses:(NSArray *)prohibited {
  NSMutableString *ms;
  NSString *sAllowedDomains;

  sAllowedDomains = [[[self mailRestrictions] allowedDomains]
                            componentsJoinedByString:@", "];
  
  ms = [[NSMutableString alloc] initWithCapacity:256];
  [ms appendString:[[self labels] valueForKey:@"prohibitedAddressError"]];
  [ms appendString:@":\n"];
  [ms appendString:[prohibited componentsJoinedByString:@", "]];
  [ms appendString:@"\n"];
  [ms appendString:[[self labels] valueForKey:@"allowedAddressError"]];
  [ms appendString:@":\n"];
  [ms appendString:sAllowedDomains];
  [self setErrorString:ms];
  [ms release];
  return nil;
}

- (OGoMailAddressSearch *)newMailAddressSearcher {
  OGoMailAddressSearch *searcher;
  Class clazz;
  
  clazz = [self isExtendedSearch]
    ? [OGoComplexMailAddressSearch class]
    : [OGoSimpleMailAddressSearch  class];
  
  searcher = [[clazz alloc] initWithCommandContext:
                              [[self session] commandContext]];
  [searcher setMailRestrictions:[self mailRestrictions]];
  [searcher setLabels:[self labels]]; // labels do not really belong here!
  return searcher;
}

- (id)addAddress {
  OGoMailAddressSearch *searcher;
  NSArray      *prohibited = nil;
  NSArray      *result;
  
  /* request preprocessing */
  [self setErrorString:nil];
  [self confirmUpload];
  [self _confirmAddress];
  
  /* search */
  searcher = [self newMailAddressSearcher];
  
  result = [searcher findEmailAddressesForSearchStrings:
                       [self->searchString componentsSeparatedByString:@","]
                     addFirstFoundAsTo:([self->addresses count] == 0)
                     prohibited:&prohibited];
  
  if ([result isNotEmpty])
    [self->addresses addObjectsFromArray:result];
  
  [searcher release]; searcher = nil;
  
  /* intentional, reset extended search to make long running searches harder */
  self->flags.isExtendedSearch = 0;
  
  if ([prohibited isNotEmpty])
    return [self _processesProhibitedAddresses:prohibited];
  
  return self; /* stay on page */
}

/* IMAP4 handling for Sent mail */

- (SkyImapContextHandler *)imapCtxHandler {
  return [SkyImapContextHandler imapContextHandlerForSession:[self session]];
}
- (NGImap4Context *)imapContext {
  return [[self imapCtxHandler] sessionImapContext:[self session]];
}

- (BOOL)hasImapContext {
  NSString       *error;
  NGImap4Context *ctx; 

  error = nil;
  ctx   = [self imapContext];
  
  if (ctx == nil) { /* set login */
    [self->host release];  self->host = nil;
    [self->login release]; self->login = nil;
    ctx = [[self imapCtxHandler]
		 imapContextWithSession:[self session]
	         password:nil login:&self->login host:&self->host
	         errorString:&error];
    [self->host retain];
    [self->login retain];
  }
  if (ctx != nil) {
    NGImap4Client *client;

    [ctx resetLastException];

    client = [ctx client];
    /*res=*/ [client noop];
    
    if ([ctx lastException] != nil) {
      [[self imapCtxHandler] resetImapContextWithSession:[self session]];
      [self->host  release]; self->host = nil;
      [self->login release]; self->login = nil;
      
      ctx = [[self imapCtxHandler] imapContextWithSession:[self session]
                                    password:nil login:&self->login
                                    host:&self->host
                                    errorString:&error];
      
      if (ctx == nil) {
        [self setErrorString:error];
        [self->host  retain];
        [self->login retain];
      }
    }
  }
  return ([self imapContext] == nil) ? NO : YES;
}

/* sending a message */

- (id)buildMessageAndSend:(BOOL)_send save:(BOOL)_save {
  [self setIsInWarningMode:NO];
  return [self buildMessageAndSend:_send save:_save checkAddress:YES];
}

/* adding company disclaimer */

- (void)addCompanyDisclaimer {
  NSString *tmp;
  
  tmp = [self->mailText stringByAddingCompanyDisclaimer:CompanyDisclaimer];
  ASSIGNCOPY(self->mailText, tmp);
}

/* user specific defaults */

- (BOOL)shouldWrapOutgoingMails {
  return [[self userDefaults] boolForKey:@"LSWImapMailWrapOutgoingMails"];
}
- (BOOL)shouldWrapLongLines {
  return [[self userDefaults] boolForKey:@"mail_wrapLongLines"];
}
- (int)outgoingMailWrappingLength {
  int length;
  
  length = [[self userDefaults] 
	          integerForKey:@"LSWImapMailOutgoingMailWrapLength"];
  if (length == 0)
    length = 80;
  return length;
}

- (BOOL)useEpoz {
  if (!IsEpozEnabled) /* is it globally enabled? */
    return NO;
  
  return [[self userDefaults] boolForKey:@"mail_useEpozMailEditor"];
}
- (BOOL)isPlainTextCheckboxEnabled {
  if ([self useEpoz])
    return NO;
  
  return ![[self userDefaults] boolForKey:@"mail_disablePlainTextCheckbox"];
}
- (BOOL)doesAllowHTMLSignature {
  /* whether the signature should be HTML-escaped or not */
  return [[self userDefaults] boolForKey:@"mail_allowHtmlSignature"];
}

- (BOOL)viewAttachmentBodysInEditor {
  return [[self userDefaults] boolForKey:@"mail_viewAttachmentBodysInEditor"];
}

- (int)numberOfUploadFields {
  int num;
  num = [[self userDefaults] integerForKey:@"mail_numberOfUploadFields"];
  return num < 1 ? 1 : num;
}

- (BOOL)enableFromPopUp {
  return [[self userDefaults] boolForKey:@"mail_enableFromPopup"];
}

- (BOOL)sendMailsWithoutSkyrixPart {
  return [[self userDefaults] boolForKey:@"LSMailsSendMailsWithoutSkyrixPart"];
}

/* wrapping */

- (void)wrapMailText {
  NSString *contentStr;
  
  if (![self->mailText isNotNull]) {
    ASSIGN(self->mailText, @"");
    return;
  }
  
  if (![self shouldWrapOutgoingMails])
    return;
  
  contentStr = [self->mailText 
		    mailWrappedStringWithLength:
		      [self outgoingMailWrappingLength]
		    wrapLongLines:[self shouldWrapLongLines]];
  ASSIGNCOPY(self->mailText, contentStr);
}

/* building and sending */

// TODO: clean up this mess!

- (void)_patchWebMailMasterPageAfterSend {
  WOComponent *p;

  p = [self pageWithName:@"LSWImapMails"];
  if ([[p tabKey] isEqualToString:@"login"])
    [p setTabKey:@"mail"];
}

- (void)_addDispositionInfoToMap:(NGMutableHashMap *)map {
  NSArray *e;
  
  if (!self->flags.returnReceipt)
    return;
  
  // TODO: what about case sensitivity?
  if ([map countObjectsForKey:@"Disposition-Notification-To"] != 0)
    return;

  e = [map objectsForKey:@"reply-to"];
  if ([e count] == 0)
    e = [map objectsForKey:@"from"];
  
  [map addObjects:e forKey:@"Disposition-Notification-To"];
}
- (void)_addDefaultReplyToIfMissingToMap:(NGMutableHashMap *)map {
  NSString *replyTo;
  
  if ([[map objectsForKey:@"reply-to"] isNotEmpty])
    return; /* has reply-to set */
  
  replyTo = [[self userDefaults] stringForKey:@"mail_reply-to"];
  if ([replyTo isNotEmpty])
    [map setObject:replyTo forKey:@"reply-to"];
}
- (void)_addDefaultOrganizationIfMissingToMap:(NGMutableHashMap *)map {
  NSString *organ;
  
  if ([[map objectsForKey:@"organization"] isNotEmpty])
    return; /* has an organization set */
  
  organ = [[self userDefaults] stringForKey:@"mail_organization"];
  if ([organ isNotEmpty])
    [map setObject:organ forKey:@"organization"];
}

- (NSArray *)_collectMailingLists:(NSArray *)mailingLists {
  // TODO: explain what this code does
  NSMutableArray *ms;
  NSEnumerator   *enumerator;
  NSDictionary   *obj;

  enumerator = [[[self mailingListDS] fetchObjects] objectEnumerator];
  ms         = [NSMutableArray arrayWithCapacity:[mailingLists count]];

  while ((obj = [enumerator nextObject]) != nil) {
    if (![mailingLists containsObject:[obj objectForKey:@"name"]])
      continue;
    [ms addObject:obj];
  }
  return ms;
}

- (BOOL)_isMessageToBigDeliverException:(NSException *)_ex {
  return [[_ex reason] hasPrefix:@"MessageFileTooBig"];
}
- (BOOL)_isMissingSendmailDeliverException:(NSException *)_ex {
  return [[_ex reason] hasPrefix:@"NoExecutableSendmailBinary"];
}

- (void)_filterOutMailingLists:(NSMutableArray *)mailingLists
  emailAddresses:(NSMutableArray *)emailAddrs
  prohibitedAddresses:(NSMutableArray *)prohibited
  emailAddressHeaderMap:(NGMutableHashMap *)map
  fromAddressArray:(NSArray *)_addresses
{
  unsigned i, cnt;
  
  for (i = 0, cnt = [_addresses count]; i < cnt; i++) {
    NSDictionary *entry;
    NSString     *addr;
    NSString     *header;
    
    entry = [_addresses objectAtIndex:i];
    addr  = [(NSDictionary *)[entry objectForKey:@"email"] 
                                    objectForKey:@"email"];
    if ([addr length] == 0)
      continue;
    
    /* check for mailing lists */
    if ([addr hasPrefix:@"@@MAILING_LIST_STRING@@:"]) {
      [mailingLists addObject:[addr substringFromIndex:24]];
      continue;
    }

    /* check for restrictions */
    if (![[self mailRestrictions] emailAddressAllowed:addr]) {
      [prohibited addObject:addr];
      continue;
    }
    
    header = [entry objectForKey:@"header"];
    [map addObject:addr forKey:header]; /* add to envelope */
    if (![header isEqualToString:@"from"] &&
	![header isEqualToString:@"reply-to"])
      [emailAddrs addObject:addr]; /* add to actual recipients */
  }
}

- (void)_setErrorStringForProhibitedAddresses:(NSArray *)prohibited {
  NSString *s;
  
  s = [StrClass stringWithFormat:@"%@:\n%@\n%@:\n%@",
                    [[self labels] valueForKey:@"prohibitedAddressError"],
                    [prohibited componentsJoinedByString:@", "],
                    [[self labels] valueForKey:@"allowedAddressError"],
                    [[[self mailRestrictions] allowedDomains]
		            componentsJoinedByString:@", "]];
  [self setErrorString:s];
}

- (NSString *)saveMessageToFile:(id)message {
  NGMimeMessageGenerator *gen;
  NSString *path;
  
  if (message == nil)
    return nil;
  gen  = [[NGMimeMessageGenerator alloc] init];
  path = [gen generateMimeFromPartToFile:message];
  [gen release]; gen = nil;
  
  if (path != nil)
    return path;
  
  if (LSWMailLogEnabled)
    [self logWithFormat:@"could not write message to file: %@", message];
  return nil;
}

- (void)addStandardSendHeadersToMap:(NGMutableHashMap *)map {
  [map addObject:self->mailSubject              forKey:@"subject"];
  [map addObject:[NSCalendarDate date]          forKey:@"date"];
  [map addObject:@"1.0"                         forKey:@"MIME-Version"];
  [map addObject:OGoXMailer                     forKey:@"X-Mailer"];
}

- (NGMimeMessage *)_buildMultiPartMessageWithHeaders:(NGMutableHashMap *)map
  andAttachments:(NSArray *)atts
{
  NGMimeMessage       *message;  
  NGMimeMultipartBody *mBody;
  NGMimeBodyPart      *part;
  NSEnumerator        *enumerator;
  id                  obj;
    
  [map addObject:MultiMixedType forKey:@"content-type"];
    
  message = [[[NGMimeMessage alloc] initWithHeader:map] autorelease];
  mBody   = [[NGMimeMultipartBody alloc] initWithPart:message];

  if ([self sendMailsWithoutSkyrixPart]) {
    part = [self _buildExternalViewerPart];
  }
  else {
    NGMutableHashMap *h;
      
    h = [[NGMutableHashMap alloc] initWithCapacity:4];
    [h setObject:altType forKey:@"content-type"];
    part = [[[NGMimeBodyPart alloc] initWithHeader:h] autorelease];
    [part setBody:[self _buildMultipartAlternativePart:message]];
    [h release]; h = nil;                           
  }
  [mBody addBodyPart:part];
  
  enumerator = [atts objectEnumerator];
  while ((obj = [enumerator nextObject]))
    [mBody addBodyPart:obj];
    
  [message setBody:mBody];
  [mBody release]; mBody = nil;
  return message;
}

- (void)_purgeMessageFile:(NSString *)_path andSetError:(NSString *)_error {
  if ([_error isNotNull])
    [self setErrorString:_error];
  if ([_path isNotNull])
    [[NSFileManager defaultManager] removeFileAtPath:_path handler:nil];
}

- (void)_handleDeliverException:(NSException *)_exc
  path:(NSString *)messageFileName
{
  NSString *reason;

  reason = [_exc reason];
  if ([self _isMessageToBigDeliverException:_exc] ||
      [self _isMissingSendmailDeliverException:_exc]) {
    NSArray  *a;
    NSString *errorStr;
      
    a = [reason componentsSeparatedByString:@" "];
    if ([a count] != 2) {
      if (LSWMailLogEnabled) {
	[self logWithFormat:@"%s:%d: Unexpected error string %@",
	      __PRETTY_FUNCTION__, __LINE__, reason];
      }
      [self _purgeMessageFile:messageFileName andSetError:reason];
      return;
    }
    errorStr = [StrClass stringWithFormat:
			   [[self labels] valueForKey:[a objectAtIndex:0]],
			 [a objectAtIndex:1]];
    [self _purgeMessageFile:messageFileName andSetError:errorStr];
  }
  else
    [self _purgeMessageFile:messageFileName andSetError:reason];
}

- (BOOL)_sendMessage:(NGMimeMessage *)message path:(NSString *)messageFileName
  to:(NSArray *)emailAddrs
{
  NSException *result;

  if ([emailAddrs count] == 0)
    return YES;

  result = [self _deliverMailTo:emailAddrs messageFilePath:messageFileName];
  if ([result isKindOfClass:[NSException class]]) {
    message = nil;
    [self _handleDeliverException:result path:messageFileName];
    return NO;
  }
  if (![self commit]) {
    [self rollback];
    [self _purgeMessageFile:messageFileName andSetError:nil];
    return NO;
  }
  return YES;
}
- (BOOL)_sendMessage:(NGMimeMessage *)message path:(NSString *)messageFileName
  to:(NSArray *)emailAddrs mailingLists:(NSArray *)mailingLists
{
  /* sends mail to email addrs, mailing lists and copies the message to Sent */
  
  if (![self _sendMessage:message path:messageFileName to:emailAddrs])
    return NO;
  
  if ([mailingLists isNotEmpty]) {
    // TODO: explain this code
    // TODO: do we really need the emailAddrs here?
    // TODO: error handling!
    [self _deliverMailTo:emailAddrs messageFilePath:messageFileName
	  mailingLists:[self _collectMailingLists:mailingLists]];
  }
  if (![self sendMessageToSent:messageFileName]) {
    NSException *exc;
    NSString    *wp, *reason;
    id          l;

    exc = [[self imapContext] lastException];
    l   = [self labels];
    wp  = [l valueForKey:@"copyToSendOrdnerFailed"];
        
    if ((reason = [exc reason])) {
      reason = [l valueForKey:reason];
    }
    wp = [wp stringByAppendingFormat:@": '%@'.", reason];
    [self _purgeMessageFile:messageFileName andSetError:wp];
    return NO;
  }
  
  return YES;
}

- (NGMimeBodyPart *)newBodyPartForAttachmentObject:(id)_attachInfo {
  /* 
     Create a body part object for an attachment object as stored in the
     self->attachments array.
     
     Note: returns a _retained_ body part object!
     
     The _attachInfo contains the following keys:
     - attachData     [yes/no]
     - sendObject     [yes/no]
     - mimeType       [eg eo/date]
     - object         [EO object]
     - objectData     [NSData]
     - objectDataContentDisposition
     - objectDataType [eg application/octet-stream]
  */
  NGMimeBodyPart   *bp;
  NGMutableHashMap *h;
  
  if (![[_attachInfo valueForKey:@"attachData"] boolValue])
    return nil;
  
  h = [[NGMutableHashMap alloc] initWithCapacity:4];

  [h setObject:[_attachInfo valueForKey:@"objectDataType"]
     forKey:@"content-type"];
  [h setObject:[_attachInfo valueForKey:@"objectDataContentDisposition"]
     forKey:@"content-disposition"];
    
  bp = [[NGMimeBodyPart alloc] initWithHeader:h];
  
  if ([(NGMimeType *)[_attachInfo valueForKey:@"objectDataType"] isTextType]) {
    // TODO: is this really necessary?
    NSString *s;
    
    s = [[StrClass alloc]
	    initWithData:[_attachInfo valueForKey:@"objectData"]
	    encoding:[StrClass defaultCStringEncoding]];
    [bp setBody:s];
    [s release]; s = nil;
  }
  else
    [bp setBody:[_attachInfo valueForKey:@"objectData"]];
  [h release];
  return bp;
}

- (BOOL)_checkAttachmentsToSend:(NSMutableArray *)atts_ {
  /*
    Adds attachment objects to 'atts' array.
    
    Walks over 'self->attachments' and 'self->mimeParts' arrays. The first
    array is transformed to 'NGMimeBodyPart' objects while the latter already
    contains such (and objects are directly added to the result).
  */
  NSEnumerator   *enumerator;
  NGMimeBodyPart *bodyPart;
  NSDictionary   *obj;
  
  enumerator = [self->attachments objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    if ((bodyPart = [self newBodyPartForAttachmentObject:obj]) == nil) {
      /* this happens if attachData in the dict is set to 0 */
      // TODO: what about 'sendObject' objects?
      if ([[obj valueForKey:@"sendObject"] boolValue]) {
	[self warnWithFormat:@"not attaching: %@/%@/%p", 
	      [obj valueForKey:@"mimeType"],
	      NSStringFromClass([obj class]), obj];
      }
      continue;
    }
    
    [atts_ addObject:bodyPart];
    [bodyPart release];
  }
  
  enumerator = [self->mimeParts objectEnumerator];
  while ((bodyPart = [enumerator nextObject]) != nil)
    [atts_ addObject:bodyPart];
  
  return YES;
}

- (void)_processSenderAddressesInMap:(NGMutableHashMap *)map {
  // TODO: what exactly does this do? improve variable names!
  /*
    if 'e' is available:
    - if there is no reply-to in 'map', sets to e
    - if there is no from     in 'map', sets to e
    - always set return path to <$oe>
  */
  id oe, e, a;

  e  = nil;
  oe = nil;
    
  if ([self enableFromPopUp]) {
    NGMailAddressParser *p;
      
    e  = self->selectedFrom;
    p  = [NGMailAddressParser mailAddressParserWithString:e];
    oe = [[[p parseAddressList] objectEnumerator] nextObject];
  }
  if ([e length] == 0) {
    a =  [[self session] activeAccount];
    oe = [self _eAddressForPerson:a];
    
    if ([oe length] == 0) {
      oe = [a valueForKey:@"login"];
      e  = oe;
    }
    else
      e = [self _formatEmail:oe forPerson:a];
  }

  if (e == nil)
    return;
  
  /* set some headers based on 'e' */
  
  if ([map countObjectsForKey:@"reply-to"] == 0)
    [map setObject:e forKey:@"reply-to"]; // only email
  
  [map setObject:[StrClass stringWithFormat:@"<%@>", oe]
       forKey:@"return-path"]; // only email
  
  // better method for email: _eAddressLabelForPerson
  
  if ([map countObjectsForKey:@"from"] == 0) 
    [map setObject:e forKey:@"from"]; // name and email
}

- (NSString *)defaultMailSubject {
  return @"no subject";
}

- (id)buildMessageAndSend:(BOOL)_send save:(BOOL)_save
  checkAddress:(BOOL)_checkAddr
{
  // TODO: split up this huge method!
  // TODO: we probably need some "send transaction" object which takes
  //       care of disposing the temporary object (_purgeMessageFile: method)
  /*
    Operation:
    1. wraps mail text
    2. adds company disclaimer to mail text
    3. if required, set default mail subject
    4. add recipients to header map
       - filter out mailing lists
       - filter out prohibited addresses
    5. add standard headers
    6. collect body parts of attachments to send
    7. if missing, add disposition-notification-to
    8. add default reply-to
    9. add default organization header
    10. create message object
    11. save message to file
    12. send message || save-to-drafts
    13. cleanups
    14. set IMAP4 flags for forwarded/replied
  */
  NSAutoreleasePool *pool;
  NGMutableHashMap  *map;
  NSMutableArray    *emailAddrs, *atts, *prohibited, *mailingLists;
  NGMimeMessage     *message;  
  NSString          *messageFileName;
  
  pool         = [[NSAutoreleasePool alloc] init];
  prohibited   = [NSMutableArray arrayWithCapacity:4];
  map          = [[[NGMutableHashMap alloc] initWithCapacity:16] autorelease];
  message      = nil;  
  atts         = nil;  
  
  [self setErrorString:nil];
  [self wrapMailText];
  [self addCompanyDisclaimer];
  
  if ([self->mailSubject length] == 0) {
    ASSIGNCOPY(self->mailSubject, [self defaultMailSubject]);
  }
  
  emailAddrs   = [NSMutableArray arrayWithCapacity:[self->addresses count]];
  mailingLists = [NSMutableArray arrayWithCapacity:2];
  
  /* filter addresses (this fills the To/Cc/Bcc fields) */
  
  [self _filterOutMailingLists:mailingLists
	emailAddresses:emailAddrs
	prohibitedAddresses:prohibited
	emailAddressHeaderMap:map
	fromAddressArray:self->addresses];
  
  if ([prohibited count] != 0) {
    [self _setErrorStringForProhibitedAddresses:prohibited];
    return nil;
  }
  
  /* check whether any recipients are left */

  if (([emailAddrs count] == 0 && [mailingLists count] == 0) && _checkAddr) {
    if (LSWMailLogEnabled) {
      [self logWithFormat:@"%s:%d: missing emailAddrs %@ mailingLists %@",
            __PRETTY_FUNCTION__, __LINE__, emailAddrs, mailingLists];
    }
    [self setErrorString:[[self labels] valueForKey:@"noAddressError"]];
    return nil;
  }
  
  [self addStandardSendHeadersToMap:map]; /* subject, date, MIME, X-Mailer */
  
  /* check whether to attach data */
  
  atts = [NSMutableArray arrayWithCapacity:16];
  if (![self _checkAttachmentsToSend:atts])
    return nil;
  
  // TODO: this seems to setup sender addresses
  [self _processSenderAddressesInMap:map];
  
  [self _addDispositionInfoToMap:map];         // 'Disposition-Notification-To'
  [self _addDefaultReplyToIfMissingToMap:map]; // default 'reply-to' header
  [self _addDefaultOrganizationIfMissingToMap:map]; // 'organization' header
  
  if ([atts isNotEmpty]) { 
    /* add attachments */
    message = [self _buildMultiPartMessageWithHeaders:map
		    andAttachments:atts];
  }
  else {
    /* no explicit attachments */
    if ([self sendMailsWithoutSkyrixPart]) {
      NGMimeBodyPart *part;
      
      part = [self _buildExternalViewerPart];
      
      [map addObject:[part contentType] forKey:@"content-type"];
      message = [[[NGMimeMessage alloc] initWithHeader:map] autorelease];
      [message setBody:[part body]];
    }
    else {
      [map addObject:altType forKey:@"content-type"];
      message = [[[NGMimeMessage alloc] initWithHeader:map] autorelease];
      [message setBody:[self _buildMultipartAlternativePart:message]];
    }
  }
  
  /* at this point 'message' should contain a message, save that to a file */
  
  if ((messageFileName = [self saveMessageToFile:message]) == nil) {
    [self setErrorString:@"Message generation failed"];
    return nil;
  }
  
  /* after that we need to ensure that the tmpfile is deleted! */
  
  /* section to actually send using mail */
  if (_send) {
    if (![self _sendMessage:message path:messageFileName to:emailAddrs
	       mailingLists:mailingLists])
      return nil;
  }
  
  /* section to save mail in drafts */
  if (_save && ![self sendMessageToDrafts:messageFileName]) {
    NSString *error;
    
    error = [[self labels] valueForKey:@"couldNotSaveMessageToDraft"];
    [self _purgeMessageFile:messageFileName andSetError:error];
    return nil;
  }
  [self _purgeMessageFile:messageFileName andSetError:nil];
  message = nil;
  
  [self leavePage];
  [self->mimeParts   removeAllObjects];
  [self->attachments removeAllObjects];
  /* mark message */
  {
    id m;

    m = [[self session] getTransferObject];
    
    if ([m isKindOfClass:[NGImap4Message class]]) {
      if (self->flags.isReply)
        [m markAnswered];
      if (self->flags.isForward)
        [m addFlag:@"forwarded"];
    }
  }
  [pool release]; pool = nil;
  
  [self _patchWebMailMasterPageAfterSend];
  return nil; /* Note: leavePage is called above */
}

- (id)send {
  [self confirmUpload];
  
  if (![self hasImapContext]) {
    if ([self isInWarningMode])
      [self setIsInWarningMode:NO];
    else {
      [self setIsInWarningMode:YES];
      self->warningKind = Warning_Send;
      return nil;
    }
  }
  return [self buildMessageAndSend:YES save:NO];
}

- (id)sendIm {
  // TODO: explain?! add a better selector?
  return [self buildMessageAndSend:YES save:NO];
}

- (id)save {
  [self confirmUpload];
  
  if (![self hasImapContext]) {
    [self setIsInWarningMode:YES];
    self->warningKind = Warning_Save;
    return nil;
  }
  return [self buildMessageAndSend:NO save:YES checkAddress:NO];
}

- (BOOL)sendMessage:(NSString *)_msgName to:(NGImap4Folder *)_folder {
  NSData            *data;
  NSAutoreleasePool *pool;

  if (!([self hasImapContext] && [_folder isNotNull]))
    return YES;

  pool = [[NSAutoreleasePool alloc] init];

  if ((data=[[DataClass alloc] initWithContentsOfMappedFile:_msgName])==nil) {
    [pool release];
    return YES;
  }
  data = [data autorelease];
  
  [[self imapContext] resetLastException];
  if (![_folder appendMessage:data]) {
    NSException *localException;
    
    if ((localException = [[self imapContext] lastException])) {
      if (LSWMailLogEnabled) {
        [self logWithFormat:@"ERROR[%s:%d]: couldn't copy mail to sent "
                @"folder, got exception %@\n",
                __PRETTY_FUNCTION__, __LINE__, localException];
      }
      return NO;
    }
  }
  [pool release];
  return YES;
}

- (BOOL)sendMessageToSent:(NSString *)_msgName {
  if ([self hasImapContext])
    return [self sendMessage:_msgName to:[[self imapContext] sentFolder]];
  return YES;
}
- (BOOL)sendMessageToDrafts:(NSString *)_msgName {
  if ([self hasImapContext])
    return [self sendMessage:_msgName to:[[self imapContext] draftsFolder]];
  return YES;
}

- (id)cancel {
  [self setErrorString:nil];
  [self leavePage];
  [self->mimeParts removeAllObjects];
  [self->attachments removeAllObjects];
  return nil;
}

/* Gets called, if this is a notification mail and cancel was pressed. */

- (void)_deleteAppointment:(id)_apt {
  BOOL cyc;
  
  if (![_apt isNotNull])
    return;

  if (![[_apt valueForKey:@"globalID"] isNotNull]) {
    /* BUG: this somehow happens when a conflict occurred */
    [self errorWithFormat:
	    @"Got no global-id for appointment object, can't delete it."];
    return;
  }
  
  cyc = [[_apt valueForKey:@"type"] isNotEmpty] ? YES : NO;
  
  [self runCommand:@"appointment::delete",
	  @"object",          _apt,
	  @"deleteAllCyclic", [NSNumber numberWithBool:cyc],
	  @"reallyDelete",    [NSNumber numberWithBool:YES],
	nil];
}

- (id)cancelAndDeleteAppointment {
  id appointment = nil;
  
  if (!self->flags.isAppointmentNotification) {
    [self cancel];
    return self;
  }

  if ([self->attachments isNotEmpty]) {
    id obj;

    obj = [self->attachments objectAtIndex:0];
    if ([obj isKindOfClass:[NSDictionary class]])
      appointment = [(NSDictionary *)obj objectForKey:@"object"];
  }
    
  [self _deleteAppointment:appointment];
  [self cancel];
  return self;
}

- (id)nothing {
  [self setIsInWarningMode:NO];
  return nil;
}

/* accessors */

- (void)setIsExtendedSearch:(BOOL)_flag {
  self->flags.isExtendedSearch = _flag ? 1 : 0;
}
- (BOOL)isExtendedSearch {
  return self->flags.isExtendedSearch ? YES : NO;
}

- (WOComponent *)currentAttachedObjectComponent {
  WOComponent *viewer;
  id          object;
  NGMimeType  *mt;
  
  mt     = [self attachmentContentType];
  object = [self attachmentObject];
  
  if ([[mt type] isEqualToString:@"eo"]) {
    viewer = [[self session] instantiateComponentForCommand:@"htmlMail"
                             type:mt];
    if (viewer == nil)
      viewer = [[self application] pageWithName:@"LSWObjectHtmlMailPage"];
    [(id)viewer setObject:object];
    return viewer;
  }
  
  viewer = [[self session]
                  instantiateComponentForCommand:@"mailview"
                  type:mt];
  
  [viewer takeValue:object forKey:@"partOfBody"];
  if ([object respondsToSelector:@selector(body)])
    // TODO: should object always respond to body?
    [viewer takeValue:[object body] forKey:@"body"];
  else {
    [self logWithFormat:
	    @"WARNING(%s): object does not respond -body: %p<%@>",
	    __PRETTY_FUNCTION__, object, NSStringFromClass([object class])];
  }
  return viewer;
}

- (id)removeAttachment {
  [self->mimeParts removeObject:self->attachment];
  return nil;
}

- (id)currentAttachmentComponent {
  WOComponent *viewer;
  
  viewer = [[self application] pageWithName:@"LSWMimeBodyPartViewer"];

  [(id)viewer setPart:self->attachment];
  [(id)viewer setShowBody:[self viewAttachmentBodysInEditor]];
  [(id)viewer setShowRfc822:YES];
  
  return viewer;
}

- (BOOL)isLastEntry {
  return (self->count == ([self->addresses count] - 1)) ? YES : NO;
}

- (void)setSearchString:(NSString *)_str {
  ASSIGN(self->searchString, _str);
}
- (NSString *)searchString {
  return self->searchString;
}

- (id)attachmentParts {
  NGMimeMultipartBody *body;
  NSEnumerator        *enumerator;
  id                  obj;
  
  body = [[[NGMimeMultipartBody alloc] 
	    initWithPart:(id)[NSNull null]] autorelease];
  enumerator = [[self attachmentsAsMime] objectEnumerator];
  while ((obj  = [enumerator nextObject]) != nil)
    [body addBodyPart:obj];
  
  return body;
}

- (void)setAttachment:(NSMutableDictionary *)_att {
  self->attachment = _att; // non-retained?
}
- (NSMutableDictionary *)attachment {
  return self->attachment;
}

- (id)attachmentContentType {
  return [(NSDictionary *)self->attachment objectForKey:@"mimeType"];
}
- (id)attachmentObject {
  return [(NSDictionary *)self->attachment objectForKey:@"object"];
}

- (void)setAttachments:(NSMutableArray *)_att {
  ASSIGN(self->attachments, _att);
}
- (NSMutableArray *)attachments {
  return self->attachments;
}

- (void)setMailText:(NSString *)_text {
  ASSIGN(self->mailText, _text);
}
- (NSString *)mailText {
  return self->mailText;
}

- (void)setMailSubject:(NSString *)_subject {
  ASSIGN(self->mailSubject, _subject);
}
- (NSString *)mailSubject {
  return self->mailSubject;
}

- (void)setAddresses:(NSMutableArray *)_array {
  ASSIGN(self->addresses, _array);
}
- (NSMutableArray *)addresses {
  return self->addresses;
}
- (void)addAddressRecord:(NSDictionary *)_record {
  // DEPRECATED
  // Note: not called by -addReceiver:type: anymore
  if ([_record isNotNull]) [self->addresses addObject:_record];
}

- (void)setAddressEntry:(NSDictionary *)_entry {
  // TODO: actually the entry is of class 'OGoMailAddressRecordResult'
  self->addressEntry = _entry;
}
- (NSDictionary *)addressEntry {
  return self->addressEntry;
}

- (void)setCount:(unsigned)_count {
  // this is bound to the _index_ binding of the 'addresses' repetition?!
  self->count = _count;
}
- (unsigned)count {
  return count;
}

/* address keys (header fields in the popup) */

- (NSArray *)addressKeys {
  return self->addressKeys;
}

- (void)setAddressKey:(NSString *)_key {
  ASSIGNCOPY(self->addressKey, _key);
}
- (NSString *)addressKey {
  return self->addressKey;
}

- (NSString *)addressKeyLabel {
  return [[self labels] valueForKey:[self addressKey]];
}

/* attachments */

- (NSArray *)attachmentsAsMime {
  NSMutableArray *mimeAtt; 
  NSEnumerator   *enumerator;
  NSDictionary   *dict;

  enumerator = [self->attachments objectEnumerator];
  mimeAtt = [NSMutableArray arrayWithCapacity:16];
  
  while ((dict = [enumerator nextObject]) != nil) {
    NGMimeBodyPart   *mimePart;
    NGMutableHashMap *map;
    id               obj;
    
    map = [[NGMutableHashMap alloc] initWithCapacity:8];
    if ((obj = [dict objectForKey:@"content-disposition"]) != nil)
      [map setObject:obj forKey:@"content-disposition"];
    if ((obj = [dict objectForKey:@"mimeType"]) != nil)
      [map setObject:obj forKey:@"content-type"];

    mimePart = [NGMimeBodyPart bodyPartWithHeader:map];
    [mimePart setBody:[dict objectForKey:@"object"]];
    [map release]; map = nil;
    [mimeAtt addObject:mimePart];
    mimePart = nil;
  }
  return mimeAtt;
}

- (BOOL)hasAttachments {
  return (BOOL)[self->attachments count];
}

- (BOOL)hasMimeAttachments { 
  return (BOOL)[self->mimeParts count]; 
}

- (NSString *)mimeAttachmentName {
  return @"";
}

- (NSString *)mimeAttachmentType {
  return [[(id)self->attachment contentType] stringValue];
}

- (NSArray *)mimeParts {
  return self->mimeParts;
}
- (void)addMimePart:(id)_part {
  if ([_part isNotNull]) [self->mimeParts addObject:_part];
}

- (void)setAddressEntrySelection:(NSString *)_str {
  [self->addressEntry takeValue:_str forKey:@"email"];
}

- (void)setAddressEntryPopupItem:(id)_item {
  self->addressEntryPopupItem = _item;
}
- (id)addressEntryPopupItem {
  return self->addressEntryPopupItem;
}

- (void)setSendPlainText:(BOOL)_plainText {
  self->flags.sendPlainText = _plainText ? 1 : 0;
}
- (BOOL)sendPlainText {
  return self->flags.sendPlainText ? YES : NO;
}

- (void)setReturnReceipt:(BOOL)_flag {
  self->flags.returnReceipt = _flag ? 1 : 0;
}
- (BOOL)returnReceipt {
  return self->flags.returnReceipt ? YES : NO;
}

- (void)setImapContext:(NGImap4Context *)_ctx {
  //  ASSIGN(self->imapContext, _ctx);
}

- (void)setIsAppointmentNotification:(BOOL)_value {
  self->flags.isAppointmentNotification = _value ? 1 : 0;
}
- (BOOL)isAppointmentNotification {
  return self->flags.isAppointmentNotification ? YES : NO;
}

- (SkyImapMailRestrictions *)mailRestrictions {
  if (self->mailRestrictions == nil) {
    LSCommandContext *ctx;
    
    ctx = [[self session] commandContext];
    self->mailRestrictions =
      [(SkyImapMailRestrictions *)[SkyImapMailRestrictions alloc] 
				  initWithContext:(id)ctx];
  }
  return self->mailRestrictions;
}

/*
  LSWImapMailEditorComponent - Protocol
*/

/* accessors */

- (void)setSubject:(NSString *)_subject {
  ASSIGNCOPY(self->mailSubject, _subject);
}

- (void)setContent:(NSString *)_content {
  ASSIGNCOPY(self->mailText, _content);
}

- (void)setContentAndAppendSignature:(NSString *)_content {
  if (![_content isKindOfClass:StrClass])
    _content = @"";
  
  _content = [_content stringByAddingSignature:
                         [[self userDefaults] stringForKey:@"signature"]
                       useHTML:[self useEpoz]
                       escapeSignature:![self doesAllowHTMLSignature]];
  [self setContent:_content];
}
- (void)setContentWithoutSign:(NSString *)_content {
  // DEPRECATED
  [self setContentAndAppendSignature:_content];
}

- (NSString *)_recipientLabelForTeam:(id)_teamEO address:(NSString *)addr {
  NSString *teamName;
  
  teamName = [_teamEO valueForKey:@"description"];
  
  if ([[_teamEO valueForKey:@"email"] isNotNull])
    return [StrClass stringWithFormat:@"%@ <%@>", teamName, addr];
  
  return [StrClass stringWithFormat:@"%@: %@", teamName, [addr shortened:80]];
}

- (NSString *)_getRecipientAddressForTeam:(id)_person {
  NSString        *addr;
  NSArray         *members;
  NSMutableString *eAddrs;
  int             i, cnt;
  BOOL            first; 
  
  if ([(addr = [_person valueForKey:@"email"]) isNotNull])
    return addr;

  /* collect addresses of members */
  
  eAddrs  = [NSMutableString stringWithCapacity:32];
  members = [self _getMemberEOsOfTeamEO:_person];
  
  for (i = 0, cnt = [members count], first = YES; i < cnt; i++) {
    NSString *a;
    id       p;
    
    p = [members objectAtIndex:i];
    a = [self _formatEmail:[self _eAddressForPerson:p] forPerson:p];

    if (a == nil)
      continue;
    
    if (!first) 
      [eAddrs appendString:@","];
    else
      first = NO;
            
    // TODO: fix to use proper escaping?
    a = [[a componentsSeparatedByString:@","] componentsJoinedByString:@""];
    a = [[a componentsSeparatedByString:@"'"] componentsJoinedByString:@""];
    
    [eAddrs appendString:a];
  }
  return eAddrs;
}

- (void)addReceiver:(id)_person type:(NSString *)_rcvType {
  // TODO: split up this mess, clean up
  NSString *addr, *label;
  NSArray  *array;
  NSString *objType;

  label   = nil;
  addr    = nil;
  
  /* decode special args inreceiver type */
  
  objType = nil;
  if ([_rcvType rangeOfString:@":"].length > 0) {
    // TODO: explain why this is done!
    if ((array = [_rcvType componentsSeparatedByString:@":"]) != nil) {
      _rcvType = [array objectAtIndex:0];
      objType  = [array lastObject];
    }
  }
  
  if ([_person isKindOfClass:StrClass]) {
    label = _person;
    addr  = _person;
  }
  else {
    BOOL isTeam, isEp;
    
    // TODO: so many sideeffects :-( hard to refacture
    isTeam = [[_person valueForKey:@"isTeam"] boolValue];
    isEp   = ([[_person valueForKey:@"isEnterprise"] boolValue]);
    
    if (isTeam)
      addr = [self _getRecipientAddressForTeam:_person];
    else if (isEp)
      addr = [_person valueForKey:@"email"];
    else {
      addr = [objType isEqualToString:@"email2"]
        ? (NSString *)[_person valueForKey:@"email2"]
	: [self _eAddressForPerson:_person];
      
      if (addr == nil && [[_person valueForKey:@"isAccount"] boolValue])
        addr = [_person valueForKey:@"login"];
    }
    if (![addr isNotNull]) {
      [self debugWithFormat:
	      @"WARNING: could not find address for person %@", _person];
      return;
    }
    if (!isTeam && !isEp) { // build person label
      label = [self _eAddressLabelForPerson:_person andAddress:addr];
      addr  = [self _formatEmail:addr forPerson:_person];
    }
    else if (isTeam)
      label = [self _recipientLabelForTeam:_person address:addr];
    else if (isEp) {
      if ([(label = [_person valueForKey:@"name"]) isNotEmpty]) {
	NSMutableString *ms;
	
	ms = [[NSMutableString alloc] initWithCapacity:128];
	[ms appendString:label];
	[ms appendString:@" <"];
	[ms appendString:[addr stringValue]];
	[ms appendString:@">"];
	label = [[ms copy] autorelease];
	[ms release]; ms = nil;
      }
      else
	label = [addr stringValue];
    }
  }
  
  // TODO: what does the stuff below do?
  {  
    NSMutableDictionary *dict;
    NSMutableArray      *e;
    NSDictionary        *record;
    
    dict = [NSMutableDictionary dictionaryWithCapacity:4];
    e    = [NSMutableArray arrayWithCapacity:2];

    [dict setObject:e        forKey:@"emails"];
    [dict setObject:_rcvType forKey:@"header"];
    
    [self->addresses addObject:dict];
    
    if ((![[self mailRestrictions] emailAddressAllowed:addr])) {
      label = [label stringByAppendingFormat:@" (%@)",
                     [[self labels] valueForKey:@"label_prohibited"]];
      addr  = @"";
    }
    
    record = [[NSDictionary alloc] initWithObjectsAndKeys:
				     addr, @"email", label, @"label", nil];
    [e addObject:record];
    [record release]; record = nil;
    
    [e addObject:[self _emptyEntry]];
    [dict setObject:[e objectAtIndex:0] forKey:@"email"];    
  }
}
- (void)addReceiver:(id)_person { // type == "to"
  [self addReceiver:_person type:@"to"];
}

/* attachments */

- (NSString *)contentDispositionForFilename:(NSString *)_fname {
  NSMutableString *ms;

  if ([_fname length] == 0) 
    return nil;
  
  ms = [NSMutableString stringWithCapacity:[_fname length] + 24];
  [ms appendString:@"inline; filename=\""];
  [ms appendString:_fname];
  [ms appendString:@"\""];
  return ms;
}

- (NSString *)extensionOfFilename:(NSString *)_fname {
  /* a bit different behaviour of the return-values wrt -pathExtension */
  NSRange r;
  
  if ([_fname length] == 0)
    return nil;
  
  r = [_fname rangeOfString:@"." options:NSBackwardsSearch];
  if (r.length == 0)
    return nil;
  
  return [_fname substringFromIndex:(r.location + r.length)];
}

- (NGMimeType *)mimeTypeForFilename:(NSString *)_fileName
  cleanedFilename:(NSString *)fileName
{
  NSString     *ext, *type, *subType, *t;
  NSDictionary *disp;
  
  t = ((ext = [self extensionOfFilename:_fileName]) == nil)
    ? nil
    : [mimeTypeMap valueForKey:ext];
  
  type    = @"application";
  subType = @"octet-stream";
  
  if (t != nil) { // TODO: weird, probably use NGMimeType instead!
    NSArray *a;
    
    a = [t componentsSeparatedByString:@"/"];

    if ([a count] == 2) {
      type    = [a objectAtIndex:0];
      subType = [a objectAtIndex:1];
    }
  }
  
  disp = fileName 
    ? [NSDictionary dictionaryWithObject:fileName forKey:@"name"]
    : nil;
  
  return [NGMimeType mimeType:type subType:subType parameters:disp];
}

- (void)addMimePart:(id)_obj type:(NGMimeType *)_type
  name:(NSString *)_name
{
  NGMimeContentDispositionHeaderField *disposition;
  NGMutableHashMap                    *map;
  id                                  body;
  NGMimeBodyPart                      *part;
  NSAutoreleasePool                   *pool;
  NSString                            *t, *st;
  id tmp;

  pool = [[NSAutoreleasePool alloc] init];
  map  = [NGMutableHashMap hashMapWithCapacity:16];
  
  /* content-disposition */
  
  t = [[self contentDispositionForFilename:_name] copy];
  disposition = [[NGMimeContentDispositionHeaderField alloc] initWithString:t];
  [t release]; t = nil;
  [map setObject:disposition forKey:@"content-disposition"];

  /* content-type */
  
  if ((t = [_type type]) == nil)
    t = @"application";
  if (!(st = [_type subType]))
    st = @"octet-stream";

  tmp = [NSDictionary dictionaryWithObject:_name forKey:@"name"];
  tmp = [NGMimeType mimeType:t subType:st parameters:tmp];
  [map setObject:tmp forKey:@"content-type"];
  [disposition release]; disposition = nil;
  
  if ([_type isTextType]) {
    if ([_obj isKindOfClass:DataClass]) {
      // TODO: unicode?
      body = [StrClass stringWithCString:[_obj bytes]
                       length:[_obj length]];
    }
    else
      body = _obj;
  }
  else {
    if ([_obj isKindOfClass:DataClass])
      body = _obj;
    else
      body = [_obj dataUsingEncoding:[StrClass defaultCStringEncoding]];
  }
  part = [NGMimeBodyPart bodyPartWithHeader:map];
  [part setBody:body];
  [self addMimePart:part];
  [pool release]; pool = nil;
}

- (void)addAttachment:(id)_obj type:(NGMimeType *)_t sendObject:(NSNumber *)_s{
  NSMutableDictionary *md;
  
  md = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      _obj, @"object",
                                      _t,   @"mimeType",
                                      _s,   @"sendObject", nil];
  [self->attachments addObject:md];
  [md release];
}
- (void)addAttachment:(id)_object type:(NGMimeType *)_type {
  [self addAttachment:_object type:_type
        sendObject:[NSNumber numberWithBool:YES]];
}
- (void)addAttachment:(id)_object { // type=[_obj mimeType]
  [self addAttachment:_object type:[_object valueForKey:@"mimeType"]
        sendObject:[NSNumber numberWithBool:YES]];
}

/* private functions */

- (id)_emailSearchRecord:(NSString *)_key value:(NSString *)_value {
  id rec;
  
  rec = [self runCommand:@"search::newrecord", @"entity", @"CompanyValue",nil];
  [rec takeValue:_key   forKey:@"attribute"];
  [rec takeValue:_value forKey:@"value"];
  return rec;
}
- (NSMutableArray *)_searchPersons:(NSString *)_search {
  // TODO: somehow this looks similiar to some other code
  // TODO: such a "search" functionality should be moved to a command
  NSArray        *persons, *teams, *enterprises;
  NSMutableArray *res;
  id             rec, email1Rec, email2Rec, email3Rec;
  
  if ([_search length] == 0)
    return nil;
  
  rec       = [self _newPersonSearchRecord];
  email1Rec = [self _emailSearchRecord:@"email1" value:_search];
  email2Rec = [self _emailSearchRecord:@"email2" value:_search];
  email3Rec = [self _emailSearchRecord:@"email3" value:_search];
  
  [rec takeValue:_search forKey:@"name"];
  [rec takeValue:_search forKey:@"firstname"];
  [rec takeValue:_search forKey:@"description"];
  [rec takeValue:_search forKey:@"login"];
  
  {
    NSArray      *emailPersons, *tmp;
    NSMutableSet *extSearchResult;
    
    persons         = [self _extSearch:@"person" matchingRecord:rec];
    extSearchResult = [NSMutableSet setWithArray:persons];
    rec             = [self _newPersonSearchRecord];
    
    tmp          = [NSArray arrayWithObjects:rec, email1Rec, nil];
    emailPersons = [self _extSearch:@"person" matchingAllRecords:tmp];
    [extSearchResult addObjectsFromArray:emailPersons];
    
    tmp          = [NSArray arrayWithObjects:rec, email2Rec, nil];
    emailPersons = [self _extSearch:@"person" matchingAllRecords:tmp];
    [extSearchResult addObjectsFromArray:emailPersons];
    
    tmp          = [NSArray arrayWithObjects:rec, email3Rec, nil];
    emailPersons = [self _extSearch:@"person" matchingAllRecords:tmp];
    [extSearchResult addObjectsFromArray:emailPersons];
    
    persons = [extSearchResult allObjects];
  }
  {
    NSArray      *tmp;
    NSMutableSet *extSearchResult;
    
    rec = [self _newEnterpriseSearchRecord];
    email2Rec = [self _emailSearchRecord:@"email2" value:_search];
    email3Rec = [self _emailSearchRecord:@"email2" value:_search];
   
    [rec takeValue:_search forKey:@"description"];
    [rec takeValue:_search forKey:@"email"];
    
    enterprises     = [self _extSearch:@"enterprise" matchingRecord:rec];
    extSearchResult = [NSMutableSet setWithArray:enterprises];
    rec             = [self _newEnterpriseSearchRecord];
    
    tmp         = [NSArray arrayWithObjects:rec, email2Rec, nil];
    enterprises = [self _extSearch:@"enterprise" matchingAllRecords:tmp];
    [extSearchResult addObjectsFromArray:enterprises];
    
    tmp         = [NSArray arrayWithObjects:rec, email3Rec, nil];
    enterprises = [self _extSearch:@"enterprise" matchingAllRecords:tmp];
    [extSearchResult addObjectsFromArray:enterprises];
     
    enterprises = [extSearchResult allObjects];
  }
  teams = [self _getTeamEOsMatchingName:_search];
 
  res = [NSMutableArray arrayWithCapacity:[persons count] + [teams count]];
  
  if ([persons isNotEmpty])
    [res addObjectsFromArray:persons];
  if ([teams isNotEmpty])
    [res addObjectsFromArray:teams];

  if ([enterprises isNotEmpty])
    [res addObjectsFromArray:enterprises];

  return res;
}

- (void)_confirmAddress {
  // TODO: rework, document
  //       I guess that this works over all addresses and "fixes" duplicates
  //       and removes popups set to "ignore"
  int i, cnt;
  
  for (i = 0, cnt = [self->addresses count]; i < cnt; i++) {
    NSDictionary *addrEntry;

    addrEntry = [self->addresses objectAtIndex:i];
    
    if ([[[addrEntry valueForKey:@"email"] valueForKey:@"email"] length] == 0){
      [self->addresses removeObjectAtIndex:i];
      i--;
      cnt--;
    }
    else {
      NSMutableArray *emails;
      int            k, cnt2;
      id             one     = nil;

      emails = [addrEntry valueForKey:@"emails"];
      if (![emails isKindOfClass:[NSMutableArray class]])
        emails = [[emails mutableCopy] autorelease];

      for (k = 0, cnt2 = [emails count]; k < cnt2; k++) {
        one = [emails objectAtIndex:k];
        if (((k + 1) != cnt2) && ([[one valueForKey:@"email"] length] == 0)) {
          // marked as prohibited entry by email lenght 0
          [emails removeObjectAtIndex:k];
	}
        k--;
        cnt2--;
      }
      if ([addrEntry isKindOfClass:[NSMutableDictionary class]])
        [(NSMutableDictionary *)addrEntry setObject:emails forKey:@"emails"];
      else {
        addrEntry = [[addrEntry copy] autorelease];
        [self->addresses replaceObjectAtIndex:i withObject:addrEntry];
      }
      one = [addrEntry valueForKey:@"email"];
      if ([emails indexOfObject:one] == NSNotFound) {
        // prohibited one was selected
        [self->addresses removeObjectAtIndex:i];
        i--;
        cnt--;
      }
    }
  }
}

- (NSString *)_checkTxtBody:(id)_body {
  if ([_body isKindOfClass:DataClass]) {
    NSString *res;
    
    res = [[StrClass alloc] initWithData:_body
                            encoding:[StrClass defaultCStringEncoding]];
    return [res autorelease];
  }
  
  if ([_body isKindOfClass:StrClass])
    return _body;
  
  return @"";
}

- (NSString *)_checkOther:(NGMimeBodyPart *)_part {
  NGMimeType *mt;
  
  if ((mt = [_part contentType]) == nil)
    return nil;
  
  if ([mt isTextHtmlType])
    return nil;
  if ([mt isTextType])
    return [self _checkTxtBody:[_part body]];
  
  return nil;
}

- (NSString *)_checkMixed:(NGMimeBodyPart *)_part {
  NSArray      *parts;
  NSEnumerator *enumerator;
  id           mp;
  NSString     *result;

  result     = nil;
  parts      = [[_part body] parts];  
  enumerator = [parts objectEnumerator];    
  while ((mp = [enumerator nextObject])) {
    NGMimeType *mt;
    
    if ((mt = [mp contentType]) == nil)
      continue;
    
    if (([[mt type] isEqualToString:@"multipart"]) &&
        ([[mt subType] isEqualToString:@"alternative"])) {
      if ((result = [self _checkAlternative:mp]) != nil)
        return result;
    }
    else if ([[mt type] isEqualToString:@"multipart"]) {
      if ((result = [self _checkMixed:mp]) != nil)
        return result;
    }
    else {
      if ((result = [self _checkOther:mp]) != nil)
        return result;
    }
  }
  return nil;
}

- (NSString *)_checkAlternative:(NGMimeBodyPart *)_part {
  NSArray      *parts;
  NSEnumerator *enumerator;
  id           mp;
  NSString     *result;

  result     = nil;
  parts      = [[_part body] parts];  
  enumerator = [parts objectEnumerator];
  while ((mp = [enumerator nextObject])) {
    NGMimeType *mt;
    
    if ((mt = [mp contentType]) != nil) {
      if ([mt hasSameType:MultiSxType]) {
        if ((result = [self _checkMixed:mp]) != nil)
          return result;
      }
    }
    
    enumerator = [parts objectEnumerator];    
    while ((mp = [enumerator nextObject])) {
      if ((mt = [mp contentType]) == nil)
	continue;
      
      if ([mt hasSameType:TextPlainType]) {
	if ((result = [self _checkOther:mp]) != nil)
	  return result;
      }
    }
    
    enumerator = [parts objectEnumerator];    
    while ((mp = [enumerator nextObject])) {
      if ((mt = [mp contentType]) == nil)
	continue;

      if ([mt hasSameType:altType]) {
	if ((result = [self _checkAlternative:mp]) != nil)
	  return result;
      }
      else if ([[mt type] isEqualToString:@"multipart"]) {
	if ((result = [self _checkMixed:mp]) != nil)
	  return result;
      }
      else {
	if ((result = [self _checkOther:mp]) != nil)
	  return result;
      }
    }
  }
  return nil;
}

- (void)_processReplyMessageString:(NSString *)messageString 
  from:(NSString *)from
{
  /* called by _setBodyForReply:from:part: */
  static NSString *QuoteString = @"> ";
  NSArray         *array;
  NSMutableString *mString;
  NSEnumerator    *enumerator;
  NSString        *tmp;
      
  // TODO: explain that code and probably move it to an own object
  mString = [NSMutableString stringWithCapacity:128];
      
  array   = [messageString componentsSeparatedByString:@"\n"];

  if (from == nil) from = @"<no sender>";
  
  if ([self useEpoz]) {
    /* Note: do not use XHTML/XML, might confuse Epoz */
    [mString appendString:[from stringByEscapingHTMLAttributeValue]];
    [mString appendString:@" wrote: <br>\n"];
    enumerator = [array objectEnumerator];
    while ((tmp = [enumerator nextObject]) != nil) {
      [mString appendString:QuoteString];
      [mString appendString:[tmp stringByEscapingHTMLAttributeValue]];
      [mString appendString:@"<br>\n"];
    }
  }
  else {
    [mString appendString:from];
    [mString appendString:@" wrote: \n"];
    enumerator = [array objectEnumerator];
    while ((tmp = [enumerator nextObject]) != nil) {
      [mString appendString:QuoteString];
      [mString appendString:tmp];
      [mString appendString:@"\n"];
    }
  }
  tmp            = self->mailText;
  self->mailText = [mString copy];
        
  [tmp release]; tmp = nil;
}
- (void)_setBodyForReply:(id)_obj from:(NSString *)_from part:(id)_part {
  // TODO: split up
  NSString   *messageString;
  NSString   *from;
  NGMimeType *type;
  id         part;
  
  from = _from;
  part = (_part == nil) ? [(NGImap4Message *)_obj message] : _part;
  
  if ((type = [part contentType]) == nil)
    return;
  
  if ([type hasSameType:altType])
    messageString = [self _checkAlternative:part];
  else if ([[type type] isEqualToString:@"multipart"])
    messageString = [self _checkMixed:part];
  else
    messageString = [self _checkOther:part];
  
  if (messageString != nil) {
    [self _processReplyMessageString:messageString from:from];
  }
  else if ([type hasSameType:TextHtmlType]) {
    if ([self useEpoz]) {
      NSString *t;
	
      t = [self _checkTxtBody:[part body]];
      ASSIGNCOPY(self->mailText, t);
    }
    else
      [self addAttachment:[part body] type:TextHtmlType];
  }
}

- (void)_setBodyForForward:(id)_obj from:(NSString *)_from {
  // TODO: who calls that?
  // TODO: type 'obj' argument to NGImap4Message?
  NGMimeBodyPart   *bPart;
  NGMutableHashMap *map;
  id               part;

  part = [(NGImap4Message *)_obj message];
  map = [[NGMutableHashMap alloc] initWithCapacity:16];
  [map setObject:[NGMimeType mimeType:@"message/rfc822"]
       forKey:@"content-type"];
  
  bPart = [NGMimeBodyPart bodyPartWithHeader:map];
  [bPart setBody:part];
  [self addMimePart:bPart];
  [map release]; map = nil;
}

- (void)_mailtext:(NSString **)text_ subtype:(NSString **)subType_ {
  if ([self useEpoz]) {
    NSString *str;

    str = self->mailText;
    str = [str stringByRemovingString:@"<br>"];
    str = [str stringByRemovingString:@"<p>"];
    
    if ([str rangeOfString:@"<"].length > 0) { /* already html content */
      *text_    = self->mailText;
      *subType_ = @"html";
    }
    else {
      str = [[str stringByReplacingString:@"&lt;"
                  withString:@"<"] stringByReplacingString:@"&gt;"
                                   withString:@">"];
      *text_ = str;
      *subType_ = @"plain";
    }
  }
  else {
    *text_    = self->mailText;
    *subType_ = @"plain";
  }
}

- (NGMimeBodyPart *)_buildExternalViewerPart {
  id               p;
  NSString         *st, *text;
  NGMutableHashMap *map;
  NGMimeBodyPart   *part;
  WOResponse *response;
  id         content;
  
  /* this does some string processing when used with Epoz */
  [self _mailtext:&text subtype:&st];
  
  /* setup render page */
  
  if (self->flags.sendPlainText) {
    p  = [[self application] pageWithName:@"LSWMailTextRenderPage"];
  }
  else {
    p  = [[self application] pageWithName:@"LSWMailHtmlRenderPage"];
    st = @"html";
    
    if ([self useEpoz])
      [p setEscapeHtml:NO];
  }

  /* fill render page values */
  
  [(NSObject *)p setContent:text];

  [p setSubject:self->mailSubject];
  [(id)p setDate:(id)[NSCalendarDate date]];
  
  [p setAttachments:self->attachments];

  [p setInlineLink:NO];

  /*  gen response */

  response = [p generateResponse];
  if ([response status] != 200)
      /* could not generate response */
    return nil;
  
  content = [response contentAsString];
  
  /* fixup content */
  
  if (!self->flags.sendPlainText) {
    /* wrap in HTML header and footer */
    content = [htmlMailHeader stringByAppendingString:content];
    content = [content stringByAppendingString:htmlMailFooter];
  }

  /* determine content-type */
  
  st = [@"text/" stringByAppendingString:st];
  
  if ([content canBeConvertedToEncoding:NSASCIIStringEncoding]) {
    st      = [st stringByAppendingString:@"; charset=US-ASCII"];
    content = [content dataUsingEncoding:NSASCIIStringEncoding];
  }
  else if ([content canBeConvertedToEncoding:NSISOLatin1StringEncoding]) {
    st      = [st stringByAppendingString:@"; charset=ISO-8859-1"];
    content = [content dataUsingEncoding:NSISOLatin1StringEncoding];
  }
#if LIB_FOUNDATION_LIBRARY
  else if ([content canBeConvertedToEncoding:NSISOLatin9StringEncoding]) {
    st      = [st stringByAppendingString:@"; charset=ISO-8859-9"];
    content = [content dataUsingEncoding:NSISOLatin1StringEncoding];
  }
#endif
  else {
    st      = [st stringByAppendingString:@"; charset=UTF-8"];
    content = [content dataUsingEncoding:NSUTF8StringEncoding];
  }
  
  /* setup part */

  map = [[NGMutableHashMap alloc] initWithCapacity:4];
  [map addObject:[NGMimeType mimeType:st] forKey:@"content-type"];
  
  part = [NGMimeBodyPart bodyPartWithHeader:map];  
  [part setBody:content];
  [map release]; map = nil;
  
  return part;
}

- (NSData *)_getIdForObject:(id)_obj {
  NSArray  *pkeys;
  NSString *pk;

  pkeys = [[_obj entity] primaryKeyAttributeNames];

  if ([pkeys count] != 1) {
    [NGTextErr writeFormat:@"! can only handle entities with one primary key "
               @"(entity=%@, keys=%@) !\n", [_obj entity], pkeys];
    return nil;
  }
  pk = [_obj valueForKey:[pkeys objectAtIndex:0]];
  pk = [pk stringValue];
  return [DataClass dataWithBytes:[pk cString] length:[pk cStringLength]];
};

- (NGMimeBodyPart *)_buildInternalViewerPart {
  NGMutableHashMap    *map;
  NGMimeBodyPart      *part;
  NGMimeMultipartBody *mBody;
  
  map  = [[NGMutableHashMap alloc] initWithCapacity:4];
  [map setObject:MultiSxTypeID forKey:@"content-type"];
  part  = [NGMimeBodyPart bodyPartWithHeader:map];
  [map release]; map = nil;

  mBody = [[NGMimeMultipartBody alloc] initWithPart:part];
  { // build mailtextPart
    NGMimeBodyPart *p_aa = nil;

    map  = [[NGMutableHashMap alloc] initWithCapacity:4];
    [map setObject:TextPlainType forKey:@"content-type"];
    
    p_aa = [[NGMimeBodyPart alloc] initWithHeader:map];
    [p_aa setBody:self->mailText];
    [mBody addBodyPart:p_aa];
    
    [map release];  map = nil;
    [p_aa release]; p_aa   = nil;
  }
  { // build eo-objectParts
    NSEnumerator   *enumerator;
    NSDictionary   *obj;
    NGMimeBodyPart *p;
    
    p   = nil;
    map = [[NGMutableHashMap alloc] initWithCapacity:4];
    enumerator = [self->attachments objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      NGMimeType *t;
      
      t = [NGMimeType mimeType:@"eo-pkey"
                      subType:[[obj objectForKey:@"mimeType"] subType]];
      [map setObject:t forKey:@"content-type"];
      p = [[NGMimeBodyPart alloc] initWithHeader:map];
      [p setBody:[self _getIdForObject:[obj objectForKey:@"object"]]];
      [mBody addBodyPart:p];
      [p release]; p = nil;
    }
    [map release]; map = nil;
  }
  [part setBody:mBody];
  [mBody release]; mBody = nil;
  return part;
}

- (id)_buildMultipartAlternativePart:(NGMimeMessage *)_message {
  NGMimeMultipartBody *body;
  id part;
  
  body = [[[NGMimeMultipartBody alloc] initWithPart:_message] autorelease];
    
  if ((part = [self _buildExternalViewerPart]))
    [body addBodyPart:part];    

  if ((part = [self _buildInternalViewerPart]))
    [body addBodyPart:part];
  
  return body;
}

- (NSString *)_fNameForPath:(NSString *)_path {
  NSArray  *cmpts;
  
  cmpts = [_path componentsSeparatedByString:@"\\"];
  if ([cmpts count] == 1)
    cmpts = [_path componentsSeparatedByString:@"/"];
  
  return [cmpts lastObject];
}

- (BOOL)checkAttachmentsWith:(NSData *)_data {
  NSEnumerator *enumerator;
  id           att;
  int          currentAttachmentSize;
  
  if (MaxAttachmentSize == 0) /* do not check, always OK */
    return YES;
  
  currentAttachmentSize = [_data length];
  enumerator            = [self->mimeParts objectEnumerator];

  att = nil;
  do { // TODO: whis is this a "do" loop?
    currentAttachmentSize += [[att body] length];

    if (currentAttachmentSize > MaxAttachmentSize) {
      NSString *s;
      
      if (LSWMailLogEnabled) {
        [self logWithFormat:
                @"[%s:%d]: could not add new attachment, mail size "
                @"limit exeeded", __PRETTY_FUNCTION__, __LINE__];
      }
      s = [[self labels] valueForKey:@"CouldntAddAttachmentSizeExceeded"];
      [self setErrorString:s];
      
      return NO;
    }
  } while ((att = [enumerator nextObject]));
  return YES;
}

- (id)_buildFileData:(id)_data header:(NGMutableHashMap *)_map {
  // TODO: split up method
  // TODO: make unicode safe?
  NSString     *transEnc;  
  const char   *bytes, *bytesOrg;
  unsigned     length, lengthOrg;
  BOOL         isString;
  int          cntBound;
  NSAutoreleasePool *pool;
  
  if (UseMemoryStoredMime)
    return _data;
                                             
  transEnc = nil;  
  pool     = [[NSAutoreleasePool alloc] init];
  isString = [_data isKindOfClass:StrClass];

  if (isString)
    bytes  = [_data cString];
  else /* got data */
    bytes  = [_data bytes];

  bytesOrg = bytes;
  
  length    = [_data length];
  lengthOrg = length;
  cntBound = 0;
  
  while (length > 0) {
    static const char *BoundaryPrefix = NULL;
    static int        BoundLen        = 0;

    
    if (BoundaryPrefix == NULL) {
      NSString *str;
      
      str            = [NGMimeMultipartBodyGenerator boundaryPrefix];
      BoundaryPrefix = [str cString];
      BoundLen       = [str length];
    }
    
    if ((unsigned char)*bytes > 127) {
      break;
    }

    if (BoundaryPrefix) {
      if (*bytes == BoundaryPrefix[cntBound]) {
        if (++cntBound == BoundLen) {
          break;
        }
      }
      else {
        cntBound = 0;
      }
    }
    bytes++;
    length--;
  }
  if (length > 0) { // should be encoded
    NGMimeType *type;

    type = [_map objectForKey:@"content-type"];
    
    if ([[type type] isEqualToString:@"text"]) {
      if (Mail_Use_8bit_Encoding_For_Text)
        transEnc = @"8bit";
      else {
        // TODO: always convert to NSData?
        _data = isString
          ? (NSData *)[_data stringByEncodingQuotedPrintable]
          : [_data dataByEncodingQuotedPrintable];
        
        transEnc = @"quoted-printable";
      }
    }
    else {
      // TODO: always convert to NSData?
      _data = isString
        ? (NSData *)[_data stringByEncodingBase64]
        : [_data dataByEncodingBase64];
      
      transEnc = @"base64";
      
      if (type == nil)
        [_map setObject:AppOctetType forKey:@"content-type"];
    }
    if (isString) {
      bytesOrg  = [_data cString];
      lengthOrg = [_data length];
    }
    else {
      bytesOrg  = [_data bytes];
      lengthOrg = [_data length];
    }
  }
  else { // no encoding
    transEnc = @"7bit";
  }
  [_map setObject:transEnc forKey:@"content-transfer-encoding"];
  [_map setObject:[NSNumber numberWithInt:[_data length]]
        forKey:@"content-length"];
  
  _data = [[NGMimeFileData alloc] initWithBytes:bytesOrg length:lengthOrg];
  [pool release];
  return [_data autorelease];
}

- (NSArray *)uploadArray {
  return self->uploadArray;
}

- (void)setUploadItem:(id)_i {
  // TODO: document type of _i
  ASSIGN(self->uploadItem, _i);
}
- (id)uploadItem {
  return self->uploadItem;
}


- (void)_initUploadArray {
  int num, i;
  
  num = [self numberOfUploadFields];
  
  if (self->uploadArray == nil)
    self->uploadArray = [[NSMutableArray alloc] initWithCapacity:num];
  else
    [self->uploadArray removeAllObjects];

  for (i = 0; i < num; i++) {
    NSMutableDictionary *md;
    
    // TODO: better use a specific object for the upload records?
    md = [[NSMutableDictionary alloc] initWithCapacity:2];
    [self->uploadArray addObject:md];
    [md release]; md = nil;
  }
}

- (int)uploadArrayIdx {
  return self->uploadArrayIdx;
}
- (void)setUploadArrayIdx:(int)_i {
  self->uploadArrayIdx = _i;
}

- (id)confirmUpload {
  // TODO: document, I guess that this processes the upload attachments of each
  //       form - I guess this should be triggered in -takeValues instead 
  //       before each method?
  NSEnumerator *enumerator;
  NSDictionary *dict;

  enumerator = [self->uploadArray objectEnumerator];
  [self setErrorString:nil];

  while ((dict = [enumerator nextObject]) != nil) {
    [self confirmUploadWithData:[dict objectForKey:@"data"]
          fileName:[dict objectForKey:@"fileName"]];

    if ([[self errorString] isNotEmpty])
      break;
  }
  [self _initUploadArray];
  return nil;
}

- (id)confirmUploadWithData:(NSData *)_data fileName:(NSString *)_fileName {
  NSAutoreleasePool *pool;
  id               contDisp, body;
  NGMimeType       *mimeType;
  NSString         *fileName;
  NGMutableHashMap *map;
  NGMimeBodyPart   *part;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  if (![self checkAttachmentsWith:_data]) {
    [pool release];
    return nil;
  }
  if (![_data isNotEmpty] || ![_fileName isNotEmpty]) {
    [pool release];
    return nil;
  }
  
  fileName = [self _fNameForPath:_fileName];
  
  map = [NGMutableHashMap hashMapWithCapacity:16];

  contDisp = [NGMimeContentDispositionHeaderField alloc];
  contDisp = [contDisp initWithString:
                         [self contentDispositionForFilename:fileName]];
  [map setObject:contDisp forKey:@"content-disposition"];
  [contDisp release]; contDisp = nil;    
  
  mimeType = [self mimeTypeForFilename:_fileName cleanedFilename:fileName];
  [map setObject:mimeType forKey:@"content-type"];
  
  body = [self _buildFileData:_data header:map];
  part = [NGMimeBodyPart bodyPartWithHeader:map];

  [part setBody:body];
  
  [self addMimePart:part];
  
  [pool release];
  return nil;
}

- (void)_buildEditAsNewForText:(id<NGMimePart>)_part type:(NGMimeType *)_type {
  // TODO: document when this is called
  NSString *s;
  id txt;
  
  if (![[_type subType] isEqualToString:@"plain"]) {
    [self addMimePart:_part];
    return;
  }
  
  txt = [_part body];
  if ([txt isKindOfClass:DataClass]) {
    // TODO: dubious, probably we want to use some other encoding?
    s = [[StrClass alloc] initWithData:txt
                          encoding:[StrClass defaultCStringEncoding]];
  }
  else
    s = [txt copy];
  
  [self setMailText:s];
  [s release];
}  

- (void)setUploadData:(NSData *)_data {
  if (_data != nil) [self->uploadItem setObject:_data forKey:@"data"];
}
- (NSData *)uploadData {
  return [self->uploadItem objectForKey:@"data"];
}

- (void)setUploadFileName:(NSString *)_file {
  if (_file) [self->uploadItem setObject:_file forKey:@"fileName"];
}
- (NSString *)uploadFileName {
  return [self->uploadItem objectForKey:@"fileName"];
}

- (int)textFieldSize {
  // TODO: should be user-configurable?
  return TextFieldSize;
}

- (NSString *)_strForHeader:(NSString *)_header {
  /* called by: prevToSelections, prevBccSelections, prevCcSelections */
  NSEnumerator   *enumerator;
  NSString       *result;
  NSDictionary   *obj;
  
  result = nil;
  
  enumerator = [self->addresses objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    NSString *header;
    NSString *value;
    
    header = [obj objectForKey:@"header"];
    
    if (![header isEqualToString:_header])
      continue;
    
    value = [(NSDictionary *)[obj valueForKey:@"email"] objectForKey:@"email"];
    if (value == nil)
      continue;
    
    value = [[value componentsSeparatedByString:@"''"]
                    componentsJoinedByString:@""];
    result = (result)
      ? [[result stringByAppendingString:@"''"] stringByAppendingString:value]
      : value;
  }
  return result;
}

- (NSDictionary *)_createAddressMailDictForObject:(id)obj
  header:(NSString *)_header
{
  // returns retain valued!
  NSDictionary *dict, *tmp;
  NSArray *mails;
    
  tmp = [[NSDictionary alloc] initWithObjectsAndKeys:
                                obj, @"email", obj, @"label", nil];
    
  mails = [[NSArray alloc] initWithObjects:tmp, [self _emptyEntry], nil];
  dict  = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  tmp,     @"email", 
                                  mails,   @"emails",
                                  _header, @"header", nil];
  [tmp   release]; tmp   = nil;
  [mails release]; mails = nil;
  return dict;
}
- (void)_setStr:(NSString *)_mail forHeader:(NSString *)_header {
  NSEnumerator *enumerator;
  NSDictionary *obj;

  if ([_mail length] == 0)
    return;
  
  enumerator = [self->addresses objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    if ([[obj objectForKey:@"header"] isEqualToString:_header])
      break;
  }
  if (obj != nil)  /* already set */
    return;
  
  // TODO: explain the split
  enumerator = [[_mail componentsSeparatedByString:@"''"] objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    NSDictionary *dict;
    
    dict = [self _createAddressMailDictForObject:obj header:_header];
    if ([dict isNotNull]) [self->addresses addObject:dict];
    [dict release]; dict = nil;
  }
}

- (NSString *)prevToSelections {
  return [self _strForHeader:@"to"];
}
- (void)setPrevToSelections:(NSString *)_str {
  [self _setStr:_str forHeader:@"to"];
}

- (NSString *)prevBccSelections {
  return [self _strForHeader:@"bcc"];
}
- (void)setPrevBccSelections:(NSString *)_str {
  [self _setStr:_str forHeader:@"bcc"];
}

- (NSString *)prevCcSelections {
  return [self _strForHeader:@"cc"];
}
- (void)setPrevCcSelections:(NSString *)_str {
  [self _setStr:_str forHeader:@"cc"];
}

- (void)setHost:(id)_value {
  ASSIGN(self->host, _value);
}
- (id)host {
  return self->host;
}
- (void)setLogin:(id)_value {
  ASSIGN(self->login, _value);
}
- (id)login {
  return self->login;
}
- (void)setPassword:(id)_value {
  ASSIGN(self->pwd, _value);
}
- (id)password {
  return self->pwd;
}

- (void)setSavePassword:(BOOL)_passwd {
  self->savePasswd = _passwd;
}
- (BOOL)savePassword {
  return self->savePasswd;
}

- (id)isLoginNumber {
  return [NSNumber numberWithBool:NO];
}

- (id)doLogin {
  // TODO: move somewhere else
  [self session]; // hh(2024-09-20): create session
  id       ctx;
  NSString *errorStr = nil;

  [[self imapCtxHandler] resetImapContextWithSession:[self session]];

  [[self imapCtxHandler] prepareForLogin:self->login passwd:self->pwd
                         host:self->host savePwd:self->savePasswd
                         session:[self session]];

  [self setErrorString:nil];

  [self->login release]; self->login = nil;
  [self->host  release]; self->host  = nil;
  ctx = [[self imapCtxHandler] imapContextWithSession:[self session]
                               password:self->pwd login:&self->login
                               host:&self->host errorString:&errorStr];
  
  if (ctx == nil && [errorStr isNotEmpty])
    [self setErrorString:[[self labels] valueForKey:errorStr]];
  
  self->login = [self->login retain];
  self->host  = [self->host retain];

  [self->pwd release]; self->pwd = nil;
  [self setIsInWarningMode:NO];

  return (self->warningKind == Warning_Save) ? [self save] : [self send];
}

- (void)setBindingDictionary:(NSDictionary *)_dict { // TODO: what is this for?
}
- (void)setBindingLabels:(id)_labels { // TODO: what is this for?
}

/* upload handling */

- (BOOL)isLastUploadField {
  return ([self->uploadArray count] == (self->uploadArrayIdx + 1)) ? YES : NO;
}
- (BOOL)isFirstUploadField {
  return (self->uploadArrayIdx == 0) ? YES : NO;
}

/* handling of from addresses */

- (NSArray *)fromList {
  NSArray  *list;
  id       sn, acc;
  NSString *str;

  sn   = [self session];

  /* check whether we have a from default */
  
  list = [[sn userDefaults] objectForKey:@"mail_fromPopupList"];
  if ([list isNotEmpty])
    return list;
  
  /* otherwise build the address */

  // TODO: the EO=>email could actually be a formatter object?
  acc = [sn activeAccount];
  str = [LSWImapMailEditor _eAddressLabelForPerson:acc];
  if (str == nil)
    str = [acc valueForKey:@"login"];
  
  str = [LSWImapMailEditor _formatEmail:str forPerson:acc];
  return [NSArray arrayWithObject:str];
}

- (void)setSelectedFrom:(NSString *)_s {
  ASSIGNCOPY(self->selectedFrom, _s);
}
- (NSString *)selectedFrom {
  return self->selectedFrom;
}

/* Epoz */

- (BOOL)isEpozEnabled {
  return IsEpozEnabled ? YES : NO;
}

/* Warning Panel */

- (NSString *)warningPhrase {
  id l;

  l = [self labels];
  
  return self->warningKind == Warning_Send
    ? [l valueForKey:@"noCopyToSentFolder"]
    : [l valueForKey:@"noSavingMail"];
}

- (BOOL)hideSendField {
  return (self->warningKind == Warning_Save) ? YES : NO;
}

@end /* LSWImapMailEditor */
