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

#include <LSMailDeliverCommand.h>
#include <NGMail/NGMimeMessageGenerator.h>
#include <GDLAccess/EONull.h>
#include "common.h"

#include <sys/wait.h>
#include <sys/types.h>
#include <unistd.h>

// TODO: should be changed to use the new NGSendMail object!

@interface LSMailDeliverCommand(Private)
- (NSArray *)emailForAccounts:(NSArray *)_accounts;
- (void)copyMailToSendFolder:(id)_context;
@end

@implementation LSMailDeliverCommand

static NSProcessInfo *npi           = nil;
static NSString      *bulkToolPath = nil;
static NSString      *SendMailPath = nil;
static NSDictionary  *env          = nil;
static int           DeniedStatusMailForMailingLists = -1;
static int           ParseMailAddress = -1;
static BOOL          ImapDebugEnabled = NO;
static BOOL          keepTmpFiles     = NO;
static EONull *null = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  npi = [[NSProcessInfo processInfo] retain];
  env = [[npi environment] retain];
  
  if (null == nil) null = [[EONull null] retain];
  
  /* defaults */
  
  bulkToolPath = 
    [[ud stringForKey:@"send_bulk_message_install_prefix_var"] copy];
  
  SendMailPath = [[ud stringForKey:@"SendmailPath"] copy];
  if ([SendMailPath length] == 0)
    SendMailPath = @"/usr/lib/sendmail";
  if (![[NSFileManager defaultManager] isExecutableFileAtPath:SendMailPath]) {
    NSLog(@"ERROR: did not find executable sendmail sendmail file: '%@'",
	  SendMailPath);
    [SendMailPath release]; SendMailPath = nil;
  }
  
  DeniedStatusMailForMailingLists =
    [ud boolForKey:@"DeniedStatusMailForMailingLists"] ? 1 : 0;
  ImapDebugEnabled = [ud boolForKey:@"ImapDebugEnabled"];
  ParseMailAddress = [ud boolForKey:@"UseOnlyMailboxNameForSendmail"] ? 1 : 0;
  
  if ((keepTmpFiles = [ud boolForKey:@"LSKeepMailTmpFiles"]))
    NSLog(@"WARNING: keeping temporary mail message files!");
}

- (void)dealloc {
  [self->addresses      release];
  [self->logins         release];
  [self->groups         release];
  [self->externals      release];
  [self->mimeData       release];
  [self->mimePart       release];
  [self->mailingLists   release];
  [self->messageTmpFile release];
  [super dealloc];
}

/* operations */

- (void)_prepareForExecutionInContext:(id)_context {
  [self assert:((self->mimePart == nil) || (self->mimeData == nil))
        reason:@"no mime(part or data) was set"];
  [self assert:(self->addresses != nil) reason:@"no address was set"];

  [super _prepareForExecutionInContext:_context];
}

- (NSArray *)getAccountsWithLogin:(NSString *)_login inContext:(id)_ctx {
  NSArray *result;
  
  result = LSRunCommandV(_ctx, @"account", @"get",
			 @"login",  _login,
			 @"returnType", intObj(LSDBReturnType_ManyObjects),
			 nil);
  return result;
}
- (NSArray *)getTeamsWithName:(NSString *)_teamName inContext:(id)_ctx {
  NSArray *result;
  
  result = LSRunCommandV(_ctx, @"team", @"get",
			 @"description", _teamName,
			 @"returnType", intObj(LSDBReturnType_ManyObjects),
			 nil);
  return result;
}
- (NSArray *)expandTeamEOsToAccountEOs:(NSArray *)_teams inContext:(id)_ctx {
  return LSRunCommandV(_ctx, @"team", @"expand", @"staffList", _teams, nil);
}

- (id)getSentFolderForAccountEO:(id)login inContext:(id)_ctx {
  id folder;
  
  folder = [LSRunCommandV(_ctx, @"emailFolder", @"get",
                          @"name"       , @"sent",
                          @"isSpecial"  , [NSNumber numberWithBool:YES],
                          @"ownerId"    , [login valueForKey:@"companyId"],
                          nil) lastObject];
  return folder;
}
- (void)createNewMail:(id)_part inFolder:(id)_folder ownerEO:(id)login 
  context:(id)_ctx
{
  LSRunCommandV(_ctx, @"email", @"new",
                @"mimePart",    _part,
                @"owner",       login,
                @"emailFolder", _folder,
                @"isNew",  [NSNumber numberWithBool:NO],
                @"isRead", [NSNumber numberWithBool:YES], 
                nil);
}

- (BOOL)isExternalAddress:(NSString *)_address {
  if ([_address rangeOfString:@"@"].length  > 0) return YES;
  if ([_address rangeOfString:@"'"].length  > 0) return YES;
  if ([_address rangeOfString:@"\""].length > 0) return YES;
  return NO;
}

- (void)sendMailToAccounts:(NSArray *)_addrs inContext:(id)_context {
  /*
    turn local account/team addresses to valid email addresses, then
    call -sendMailToExternals:
  */
  NSEnumerator *enumerator = nil;
  NSString     *address;
  
  /* turn OGo internal addresses into valid emails for sendmail */
  
  enumerator = [_addrs objectEnumerator];
  while ((address = [enumerator nextObject]) != nil) {
    NSArray *result;
    
    if ([self isExternalAddress:address]) {
      [self->externals addObject:address];
      continue;
    }
    
    /* treat address as an OGo account or team */
    
    result = [self getAccountsWithLogin:address inContext:_context];
    if ([result count] > 0) {
      [self->externals addObjectsFromArray:[self emailForAccounts:result]];
      continue;
    }

    result = [self getTeamsWithName:address inContext:_context];
    if ([result count] > 0) {
      result = [self expandTeamEOsToAccountEOs:result inContext:_context];
      [self->externals addObjectsFromArray:[self emailForAccounts:result]];
      continue;
    }
    
    /* fallback, treat as a local Unix account */
    
    [self->externals addObject:address];
  }

  /* actually deliver */

  [self sendMailToExternals:self->externals inContext:_context];
}

- (NSString *)sendBulkMessagesToolPath {
  // TODO: fix this junk
  static NSString *toolPath = nil;
  
  if (toolPath != nil)
    return toolPath;
  
  if ((toolPath = bulkToolPath) == nil)
    toolPath = @"GNUSTEP_USER_ROOT";
  
  toolPath =
    [[NSString alloc] 
      initWithFormat:@"%@/Tools/%@/%@/%@/sky_send_bulk_messages",
              [env objectForKey:toolPath],
              [env objectForKey:@"GNUSTEP_HOST_CPU"],
              [env objectForKey:@"GNUSTEP_HOST_OS"],
              [env objectForKey:@"LIBRARY_COMBO"]];
  return toolPath;
}

- (void)performMailingListDeliver:(NSString *)_sendMail for:(NSString *)_for
  context:(id)_ctx
{
  /* TODO: split up this huge method! */
  NSString       *tmpPath;
  NSString       *toolPath;
  NSMutableArray *arguments;

  // TODO: location of bulk-tool is weird!
  
  toolPath = [self sendBulkMessagesToolPath];

  if (![[NSFileManager defaultManager] isExecutableFileAtPath:toolPath]) {
    [self logWithFormat:@"ERROR: did not find executable "
          @"sky_send_bulk_messages binary '%@'",
            toolPath];
    return;
  }
  arguments = [NSMutableArray arrayWithCapacity:6];

  [arguments addObject:@"-sendMailCall"];
  [arguments addObject:_sendMail];

  if (!DeniedStatusMailForMailingLists) {
    if (_for) {
        [arguments addObject:@"-statusmail"];
        [arguments addObject:_for];
    }
  }
  
  if (self->mimeData) {
    tmpPath = [npi temporaryFileName];
    if (![self->mimeData writeToFile:tmpPath atomically:YES]) {
      NSLog(@"%s: couldn`t write data to file %@", __PRETTY_FUNCTION__,
            tmpPath);
      return;
    }
  }
  else {
    tmpPath = self->messageTmpFile;
  }
  [arguments addObject:@"-mimeDataFile"];
  [arguments addObject:tmpPath];

  tmpPath = [npi temporaryFileName];
  {
    NSEnumerator    *enumerator;
    NSDictionary    *obj;
    NSMutableString *str;

    str = [NSMutableString stringWithCapacity:128];

    enumerator = [self->mailingLists objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      NSString *s;
      
      s = [[obj objectForKey:@"emails"] componentsJoinedByString:@"\n"];
      if (s) {
        [str appendString:s];
        [str appendString:@"\n"];
      }
    }
    if (![str writeToFile:tmpPath atomically:YES]) {
      NSLog(@"%s: couldn`t write bulk data to file %@", __PRETTY_FUNCTION__,
            tmpPath);
      return;
    }
    [arguments addObject:@"-bulkFile"];
    [arguments addObject:tmpPath];
  }
  if (ImapDebugEnabled) {
    [arguments addObject:@"-ImapDebugEnabled"];
    [arguments addObject:@"YES"];
    NSLog(@"%s:call: %@ with %@", __PRETTY_FUNCTION__, toolPath, arguments);
  }
  { /*
      A hack to avoid zombies. Currently NSTask has problems with signal
       handling. Therefore the launched task will become a zombie-process.
       If you call fork() twice and exit the second process immediately,
       the init-process will be the parent of the third process. The 
       init-process always calls a wait() function to fetch the child 
       termination status.
       So no zombie process will be created.

       The db-channels will be closed to avoid confision.
    */
    pid_t pid;
    EODatabaseChannel *dbCh;
  
    dbCh = [_ctx valueForKey:LSDatabaseChannelKey];
    [_ctx commit];
    
    if ([dbCh isOpen])
      [dbCh closeChannel];

    if ((pid = fork()) < 0) {
      [self logWithFormat:@"%s: fork failed", __PRETTY_FUNCTION__];
    }
    else if (pid == 0) {
      [NSTask launchedTaskWithLaunchPath:toolPath arguments:arguments];
      exit(0);
    }
    if (waitpid(pid, NULL, 0) != pid) {
      [self logWithFormat:@"%s: waitpid error", __PRETTY_FUNCTION__];
    }
    [_ctx begin];
  }
}

- (NSMutableString *)buildSendMailCommandLineInContext:(id)_ctx
  sender:(NSString **)sender_
{
  NSMutableString *sendmail     = nil;
  id a;
  
  if (SendMailPath == nil)
    [self assert:NO reason:@"Missing sendmail binary"];
  
  sendmail = [NSMutableString stringWithCapacity:256];
  
  [sendmail setString:SendMailPath];
  [sendmail appendString:@" -i "];

  a = [_ctx valueForKey:LSAccountKey];

  *sender_ = [a valueForKey:@"email1"];
  if (![*sender_ isNotNull])
    *sender_ = [a valueForKey:@"login"];

  if (*sender_ != nil) {
    NSString *s;
    
    // TODO: explain why this is done
    s = [[*sender_ componentsSeparatedByString:@","]
	           componentsJoinedByString:@" "];
    
    [sendmail appendString:@"-f "];
    [sendmail appendString:s];
    [sendmail appendString:@" "];
  }
  return sendmail;
}

- (BOOL)_appendDataTo:(FILE *)_fd context:(id)_context {
  int written;

  if ([self->mimeData length] == 0)
    return YES;
  
  written = fwrite((char *)[self->mimeData bytes], [self->mimeData length],
		   1, _fd);
  if (written > 0)
    return YES;
  
  [self logWithFormat:@"[2] Could not write mail to sendmail <%d>", errno];
  
  if ([self->mimeData length] > 5000)
    [self logWithFormat:@"[2] message: [size: %d]", [self->mimeData length]];
  else
    [self logWithFormat:@"[2] message: <%s>", (char *)[self->mimeData bytes]];
  
  return NO;
}

- (NSException *)_handleAppendMessageException:(NSException *)_exception {
  [self logWithFormat:@"catched exception: %@", _exception];
  return nil;
}

- (BOOL)_appendMessageFileTo:(FILE *)_fd context:_context {
  NGFileStream *fs;
  int  fileLen;
  BOOL result;

  if (!self->messageTmpFile) {
    NSLog(@"ERROR: call %s without self->messageTmpFile",
          __PRETTY_FUNCTION__);
    return NO;
  }
  fileLen = [[[[NSFileManager defaultManager]
                              fileAttributesAtPath:self->messageTmpFile
                              traverseLink:NO]
                              objectForKey:NSFileSize] intValue];
  
  if (fileLen == 0) {
    NSLog(@"ERROR[%s] missing file at path %@", __PRETTY_FUNCTION__,
          self->messageTmpFile);
    [self assert:NO reason:@"Missing tmp-message file"];
    return NO;
  }

  fs = [(NGFileStream *)[NGFileStream alloc] 
                        initWithPath:self->messageTmpFile];

  if (![fs openInMode:@"r"]) {
    NSLog(@"ERROR[%s]: couldn`t open file stream for temp-file for "
          @"reading: %@", __PRETTY_FUNCTION__, self->messageTmpFile);
    [fs release]; fs = nil;
    [self assert:NO reason:@"Couldn`t open tmp-file for reading"];
    return NO;
  }
  result = YES;
  NS_DURING {
      int  read;
      int  alreadyRead;
      int  bufCnt = 8192;
      char buffer[bufCnt+1];

      alreadyRead = 0;
    
      read = (bufCnt > (fileLen - alreadyRead))
           ? fileLen - alreadyRead : bufCnt;
        
      while ((read = [fs readBytes:buffer count:read])) {
        alreadyRead += read;

        buffer[read] = '\0';

        if (fputs(buffer, _fd) == EOF) {
          fprintf(stderr, "%s: Failed to write %i bytes to process\n",
                  __PRETTY_FUNCTION__, alreadyRead);
          break;
        }
        if (alreadyRead == fileLen)
          break;
      }
  }
  NS_HANDLER {
    [[self _handleAppendMessageException:localException] raise];
    result = NO;
  }
  NS_ENDHANDLER;
  [self assert:result reason:@"Couldn`t write message file to sendmail"];
  [fs release]; fs = nil;
  return result;
}

- (NSString *)mailAddrForStr:(NSString *)_str {
  NGMailAddressParser *parser;
  NGMailAddress       *addr;
  
  if (!ParseMailAddress)
    return _str;

  parser = nil;
  addr   = nil;
  
  NS_DURING {
    parser = [NGMailAddressParser mailAddressParserWithString:_str];
    addr   = [[parser parseAddressList] lastObject];
  }
  NS_HANDLER {
    fprintf(stderr,"ERROR: get exception during parsing address %s\n",
            [[localException description] cString]);
    parser = nil;
    addr   = nil;
  }
  NS_ENDHANDLER;

  return (addr) ? [addr address] : _str;
}

- (void)_removeMailTmpFile {
  if ([self->messageTmpFile length] < 2)
    return;
  
  [[NSFileManager defaultManager] removeFileAtPath:self->messageTmpFile
				  handler:nil];
  [self->messageTmpFile release]; self->messageTmpFile = nil;
}

- (BOOL)_generateTemporaryFileForPart {
  NGMimeMessageGenerator *gen;

  gen = [[NGMimeMessageGenerator alloc] init];
      
  self->messageTmpFile = [gen generateMimeFromPartToFile:self->mimePart];
  self->messageTmpFile = [self->messageTmpFile retain];
  [gen release]; gen = nil;
  
  if (self->messageTmpFile == nil) {
    NSLog(@"ERROR[%s]: couldn`t write message %@ to path %@",
	  __PRETTY_FUNCTION__, self->mimePart, self->messageTmpFile);
    [self assert:NO reason:@"couldn`t write message to file"];
    return NO;
  }
  return YES;
}

- (void)_logMailSend:(NSString *)sendmail {
  fprintf(stderr, "%s \n", [sendmail cString]);

  if (self->mimeData == nil) {
    fprintf(stderr, "read data from %s\n", [self->messageTmpFile cString]);
    return;
  }
  
  if ([self->mimeData length] > 5000) {
    NSData *data;
    
    data = [self->mimeData subdataWithRange:NSMakeRange(0,5000)];
    fprintf(stderr, "%s...\n", (unsigned char *)[data bytes]);
  }
  else
    fprintf(stderr, "%s\n", (char *)[self->mimeData bytes]);
}

- (NSException *)_errorExceptionWithReason:(NSString *)_reason {
  return [LSDBObjectCommandException exceptionWithStatus:NO
				     object:self
				     reason:_reason userInfo:nil];
}

- (void)_handleSendMailErrorCode:(int)errorCode 
  sendMailPath:(NSString *)sendMailPath
  sendmail:(NSString *)sendmail
{
  if (errorCode == 32512) {
    NSString *str;

    str = [NSString stringWithFormat:@"NoExecutableSendmailBinary %@",
		    sendMailPath];
    [self logWithFormat:@"%@ is no executable file",
	  sendmail];

    [self setReturnValue:[self _errorExceptionWithReason:str]];
    return;
  }
  if (errorCode == 17664) {
    NSString *str;

    [self logWithFormat:@"sendmail: message file too big [%d]",
	  [self->mimeData length]];

    str = [NSString stringWithFormat:@"MessageFileTooBig %d",
		    [self->mimeData length]];

    [self setReturnValue:[self _errorExceptionWithReason:str]];
    return;
  }
  
  [self logWithFormat:@"[1] Could not write mail to sendmail! <%d>",
	  errorCode];
  if ([self->mimeData length] > 5000)
    [self logWithFormat:@"[1] message: [size: %d]", [self->mimeData length]];
  else
    [self logWithFormat:@"[1] message: <%s>", (char *)[self->mimeData bytes]];
  
  [NSException raise:@"LSMailDeliveryException"
	       format:@"Writing to '%@' failed with code [%d]", 
	         sendMailPath, errorCode];
}

- (void)sendMailToExternals:(NSArray *)_recipients inContext:(id)_context {
  NSString        *str          = nil;
  NSMutableString *sendmail     = nil;
  FILE            *toMail       = NULL;
  NSString        *sendMailPath = nil;
  id              email;
  BOOL            deleteTmp;
  NSEnumerator *enumerator;
  int errorCode;
  
  deleteTmp = NO;
  
  if (self->mimeData==nil && self->messageTmpFile==nil &&self->mimePart==nil){
    NSLog(@"ERROR[%s]: got no mime content ...",__PRETTY_FUNCTION__);
    [self assert:NO reason:@"Missing mime content"];
    return;
  }
  
  if (self->mimeData == nil && self->messageTmpFile == nil) {
    if (![self _generateTemporaryFileForPart])
      return;
    
    deleteTmp = keepTmpFiles ? NO : YES;
    if (!deleteTmp)
      [self logWithFormat:@"Note: keeping temporary message file!"];
  }
  email    = nil;
  sendmail = [self buildSendMailCommandLineInContext:_context sender:&email];

  if ([self->mailingLists count] > 0) {
    [self performMailingListDeliver:sendmail for:email context:_context];
    if (deleteTmp)
      [self _removeMailTmpFile];
  }

  
  enumerator = [_recipients objectEnumerator];
  while ((str = [enumerator nextObject])) {
    NSEnumerator *e;
    NSString     *s;

    if ([str rangeOfString:@","].length == 0) {
      [sendmail appendFormat:@"'%@' ", [self mailAddrForStr:str]];
      continue;
    }
    
    e = [[str componentsSeparatedByString:@","] objectEnumerator];
    while ((s = [e nextObject])) {
          s = [[s componentsSeparatedByString:@"'"]
                  componentsJoinedByString:@""];
          s = [[s componentsSeparatedByString:@","]
                  componentsJoinedByString:@""];
          
          [sendmail appendFormat:@"'%@'", [self mailAddrForStr:s]];
    }
    [sendmail appendString:@" "];
  }
  
  if ((toMail = popen([sendmail cString], "w")) == NULL) {
    if (deleteTmp) [self _removeMailTmpFile];
    return;
  }
    
  if (ImapDebugEnabled) [self _logMailSend:sendmail];
    
  if (self->messageTmpFile)
    [self _appendMessageFileTo:toMail context:_context];
  else
    [self _appendDataTo:toMail context:_context];
  
  if ((errorCode = pclose(toMail)) != 0) {
    [self _handleSendMailErrorCode:errorCode 
	  sendMailPath:sendMailPath sendmail:sendmail];
  }
  
  if (deleteTmp)
    [self _removeMailTmpFile];
}

- (void)copyMailToSendFolder:(id)_context {
  id folder  = nil;
  id login   = nil;

  login  = [_context valueForKey:LSAccountKey];
  folder = [self getSentFolderForAccountEO:login inContext:_context];
  [self assert:(folder != nil) reason:@"no sent folder"];
  
  [self createNewMail:self->mimePart inFolder:folder ownerEO:login
	context:_context];
}

/* primary execution method */

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];  

  [self->logins    release]; self->logins    = nil;
  [self->groups    release]; self->groups    = nil;
  [self->externals release]; self->externals = nil;
  
  self->logins    = [[NSMutableArray alloc] initWithCapacity:8];
  self->groups    = [[NSMutableArray alloc] initWithCapacity:8];
  self->externals = [[NSMutableArray alloc] initWithCapacity:8];
  
  [self sendMailToAccounts:self->addresses inContext:_context];
}

/* accessors */

- (void)setAddresses:(NSArray *)_addr {
  ASSIGN(self->addresses, _addr);
}
- (NSArray *)addresses {
  return self->addresses;
}
- (void)addAddress:(NSString *)_addr {
  if (![_addr isNotNull])
    return;
  
  if (self->addresses == nil) {
    self->addresses = [[NSMutableArray alloc] initWithObjects:&_addr count:1];
    return;
  }

  if (![self->addresses isKindOfClass:[NSMutableArray class]])
    self->addresses = [self mutableCopy];
  [(NSMutableArray *)self->addresses addObject:_addr];
}

- (void)setMimeData:(NSData *)_data {
  ASSIGN(self->mimeData, _data);
}
- (NSData *)mimeData {
  return self->mimeData;
}

- (void)setCopyToSentFolder:(BOOL)_bool {
  self->copyToSentFolder = _bool;
}
- (BOOL)copyToSentFolder {
  return self->copyToSentFolder;
}

- (void)setMimePart:(id)_part {
  if (![_part conformsToProtocol:@protocol(NGMimePart)]) {
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:@"mimeObject does not conform to "
                                       @"protocol <NGMimePart>"];
  }
  ASSIGN(self->mimePart, _part);
}
- (id<NGMimePart>)mimePart {
  return self->mimePart;
}

- (void)setMailingLists:(NSArray *)_a {
  ASSIGN(self->mailingLists, _a);
}
- (NSArray *)mailingLists {
  return self->mailingLists;
}

- (void)setMessageTmpFile:(NSString *)_a {
  ASSIGN(self->messageTmpFile, _a);
}
- (NSString *)messageTmpFile {
  return self->messageTmpFile;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"address"]) 
    [self addAddress:_value];
  else if ([_key isEqualToString:@"addresses"])
    [self setAddresses:_value];
  else if ([_key isEqualToString:@"mimePart"])
    [self setMimePart:_value];
  else if ([_key isEqualToString:@"messageTmpFile"])
    [self setMessageTmpFile:_value];
  else if ([_key isEqualToString:@"mimeData"])
    [self setMimeData:_value];
  else if ([_key isEqualToString:@"copyToSentFolder"])
    [self setCopyToSentFolder:[_value boolValue]];
  else if ([_key isEqualToString:@"mailingLists"])
    [self setMailingLists:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (NSArray *)emailForAccounts:(NSArray *)_accounts {
  NSMutableArray *array;
  NSEnumerator   *enum1;
  NSDictionary   *obj1;
  
  array = [NSMutableArray arrayWithCapacity:[_accounts count] + 1];
  
  enum1 = [_accounts objectEnumerator];
  while ((obj1 = [enum1 nextObject]) != nil) {
    NSString *email;
    
    email = [obj1 valueForKey:@"email1"];
    if ((email == nil) || ((id)null == email))
      email = [obj1 valueForKey:@"email2"];
    
    if ((email == nil) || ((id)null == email)) 
      email = [obj1 objectForKey:@"login"];

    [array addObject:email];
  }
  return array;
}

@end /* LSMailDeliverCommand */
