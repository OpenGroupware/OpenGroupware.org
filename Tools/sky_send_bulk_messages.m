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

#import <Foundation/NSObject.h>

@class NSString, NSFileManager;

@interface SkySendBulkMessagesTool : NSObject
{
  NSFileManager  *fm;
  BOOL           imapDebug;
  NSString       *mimeDataFile;
  NSString       *bulkFile;
  NSString       *sendMailCall;
  NSString       *status;
}

- (void)usage;
- (int)run;

@end

#import <Foundation/Foundation.h>
#include <NGMail/NGMimeMessageGenerator.h>
#include <NGMail/NGMailAddressParser.h>
#include <NGMail/NGMailAddress.h>

@implementation SkySendBulkMessagesTool

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *ud;
    
    self->fm = [[NSFileManager defaultManager] retain];
    
    ud = [[NSUserDefaults standardUserDefaults] retain];
    self->imapDebug    = [ud boolForKey:@"ImapDebugEnabled"];
    self->mimeDataFile = [[ud stringForKey:@"mimeDataFile"] copy];
    self->bulkFile     = [[ud stringForKey:@"bulkFile"]     copy];
    self->sendMailCall = [[ud stringForKey:@"sendMailCall"] copy];
    self->status       = [[ud stringForKey:@"statusmail"]   copy];
  }
  return self;
}
- (void)dealloc {
  [self->fm release];
  [super dealloc];
}

- (NSMutableDictionary *)sendMail:(NSString *)_call
  to:(char *)_to len:(int)_len
  header:(NSString *)_header data:(NSData *)_data
{
  FILE *toMail;
  int  errorCode;
  NSData                 *data;
  NGMimeMessageGenerator *gen;
  NSMutableDictionary    *res;
  NSString               *error;
  
  error = nil;
  res   = [NSMutableDictionary dictionaryWithCapacity:8];
  
  gen   = [[NGMimeMessageGenerator alloc] init];
  data  = [gen generateDataForHeaderField:@"to" value:_header];
  [gen release]; gen = nil;
  
  if (data == nil)
    data = [NSData dataWithBytes:_to length:_len];
  
  [res setObject:
       [[[NSString alloc] initWithData:data
                         encoding:[NSString defaultCStringEncoding]]
                   autorelease]
       forKey:@"to"];

  _call = [NSString stringWithFormat:@"%@ \"%s\"",
                    _call, _to];

  [res setObject:_call forKey:@"sendmail"];
  
  if ((toMail = popen([_call cString], "w")) != NULL) {
    int len   = [data length];
    char bytes[len+1];

    [data getBytes:bytes length:len];
    bytes[len] = '\0';
    
    if ((errorCode = fprintf(toMail, "to: %s\n", bytes)) < 0) {

      error = [NSString stringWithFormat:@"[2] Couldn`t write to arg to "
                        @"sendmail! <errorCode: %d>", errorCode];
    }
    else if ((errorCode = fprintf(toMail, "%s", (char *)[_data bytes])) < 0) {
      error = [NSString stringWithFormat:
                        @"[3] Couldn`t write blob to sendmail! <%d>",
                        errorCode];

      if ([_data length] > 5000) {
        fprintf(stderr, "[3] message: [size: %d]",
                [_data length]);
      }
      else {
        fprintf(stderr, "[3] message: <%s>",
                (char *)[_data bytes]);
      }
    }
    if ((errorCode = pclose(toMail)) != 0) {
      NSString *e;
      if (errorCode == 32512) {
        e =  [NSString stringWithFormat:
                       @"%s is no executable file", [_call cString]];

      }
      else if (errorCode == 17664) {
        e = [NSString stringWithFormat:
                      @"sendmail: message file too big [%d]", [_data length]];
      }
      else {
        e = [NSString stringWithFormat:
                      @"[1] Couldn`t write mail to sendmail! <%d>", errorCode];
        if ([_data length] > 5000) {
          fprintf(stderr, "[1] message: [size: %d]", [_data length]);
        }
        else {
          fprintf(stderr, "[1] message: <%s>", (char *)[_data bytes]);
        }
      }
      if (error) {
        error = [error stringByAppendingString:@"\n"];
        error = e;
      }
      else
        error = e;
    }
  }
  if (error) {
    NSLog(@"%s: got error %@", __PRETTY_FUNCTION__, error);
    [res setObject:error forKey:@"error"];
  }

  return res;
}

NSString *checkEmail(NSString *_email) {
  static int ParseMailAddress = -1;

  NGMailAddressParser *parser;
  NGMailAddress       *addr;

  if (ParseMailAddress == -1) {
    ParseMailAddress =
      [[NSUserDefaults standardUserDefaults]
                       boolForKey:@"UseOnlyMailboxNameForSendmail"]?1:0;
  }
  if (!ParseMailAddress)
    return _email;

  parser = nil;
  addr   = nil;
  
  NS_DURING {
    parser = [NGMailAddressParser mailAddressParserWithString:_email];
    addr   = [[parser parseAddressList] lastObject];
  }
  NS_HANDLER {
    fprintf(stderr, "WARNING: got exception during parsing %s\n",
            [[localException description] cString]);
    addr = nil;
  }
  NS_ENDHANDLER;

  return (addr) ? [addr address] : _email;
}

- (void)usage {
    printf("  sky_send_bulk_messages 1.0\n");
    printf("\n");
    printf("  Author Jan Reichmann (jr@skyrix.com)\n\n");    
    printf("  Send spam messages.\n");
    printf("  \n");
    printf("  Defaults/Arguments\n");
    printf("\n");
    printf("  mimeDataFile -  message filename\n");
    printf("  bulkFile     -  filename with mails\n");
    printf("  sendMailCall -  call to sendmail\n");
    printf("  statusmail   -  address for status mail\n");
    printf("\n");
    printf("  return values : 0   - OK\n");
    printf("\n");
}

- (int)_validateDefaults {
  if ([mimeDataFile length] == 0) {
    NSLog(@"%s: missing mime-data file", __PRETTY_FUNCTION__);
    return 1;
  }
  if (!bulkFile) {
      NSLog(@"%s: missing bulkFile file", __PRETTY_FUNCTION__);
      return 1;
  }
  if (!sendMailCall) {
    NSLog(@"%s: missing sendMailCall file", __PRETTY_FUNCTION__);
    return 1;
  }
  
  return 0;
}
- (int)_validateInputFiles {
  if (![fm fileExistsAtPath:mimeDataFile]) {
    NSLog(@"missing mimeDataFile %@", mimeDataFile);
    return 2;
  }
  if (![fm fileExistsAtPath:bulkFile]) {
    NSLog(@"missing bulkFile %@", bulkFile);
    return 2;
  }
  return 0;
}

- (void)processStatusForData:(NSData *)data 
  ok:(NSArray *)ok failed:(NSArray *)failed 
{
  NSMutableString *sendMailBlob;
  
  sendMailBlob = [NSMutableString stringWithCapacity:[data length]];

  [sendMailBlob appendString:@"subject: Mailing List status report\n"];
  [sendMailBlob appendString:@"content-type: multipart/mixed; "
                    @"boundary=\"----------=_1040317835-14692-234_\"\n"];
      
  [sendMailBlob appendString:
                    @"This is a multi-part message in MIME format...\n"
                    @"\n"
                    @"------------=_1040317835-14692-234_\n"
                    @"Content-Type: text/plain\n"
                    @"Content-Disposition: inline\n"
                    @"\n"];
  [sendMailBlob appendFormat:
                    @"Mailing List status report:\n"
                    @"\n"
                    @"Send OK: %d\n"
                    @"Send Failed: %d\n"
                    @"\n", [ok count], [failed count]];
  if ([failed count] > 0) {
        NSEnumerator *enumerator;
	NSDictionary *o;

        [sendMailBlob appendString:@"Send Failed:\n\n"];
        
        enumerator = [failed objectEnumerator];
        while ((o = [enumerator nextObject]) != nil) {
          [sendMailBlob appendFormat:
                        @"List Entry: <%@>; To Header: <%@>; Sendmail call:"
                        @"<%@> status: FAILED <%@>\n",
                        [o objectForKey:@"entry"],
                        [o objectForKey:@"to"],
                        [o objectForKey:@"sendmail"],
                        [o objectForKey:@"error"]];
        }
  }
  if ([ok count] > 0) {
    NSEnumerator *enumerator;
    NSDictionary *o;

    [sendMailBlob appendString:@"Send OK:\n\n"];
        
    enumerator = [ok objectEnumerator];
    while ((o = [enumerator nextObject]) != nil) {
          [sendMailBlob appendFormat:
                        @"List Entry: <%@>; To Header: <%@>; Sendmail call:"
                        @"<%@> status: OK\n",
                        [o objectForKey:@"entry"],
                        [o objectForKey:@"to"],
                        [o objectForKey:@"sendmail"]];
    }
  }
  [sendMailBlob appendString:@"\n"];
  [sendMailBlob appendString:
                @"------------=_1040317835-14692-234_\n"
                @"Content-Type: message/rfc822\n"
                @"\n"];
  {
    NSString *s;

    s = [[NSString alloc] initWithData:data
			  encoding:[NSString defaultCStringEncoding]];
    [sendMailBlob appendString:s];
    [s release]; s = nil;

  }
  [sendMailBlob appendString:@"\n"];
  [sendMailBlob appendString:@"------------=_1040317835-14692-234_--\n"];
  {
    NSString *em;
    int      cnt;
    NSData   *infos;
    char     *cString;
    
    em  = checkEmail(status);
    cnt = [em cStringLength];
    cString = calloc(cnt + 4, sizeof(char));
    
    [em getCString:cString maxLength:cnt];
    cString[cnt] = '\0';

    infos = [sendMailBlob dataUsingEncoding:[NSString defaultCStringEncoding]];
    [self sendMail:sendMailCall to:(char *)cString len:(cnt-1)
	  header:status data:infos];
  }
}

- (void)cleanupTemporaryFiles {
  if (imapDebug)
    /* not deleting temporary files in debug mode, should print a warning? */
    return;
  
  [fm removeFileAtPath:bulkFile     handler:nil];
  [fm removeFileAtPath:mimeDataFile handler:nil];
}

- (int)run {
  NSString       *email;
  NSData         *data;
  NSArray        *mails;
  NSEnumerator   *enumerator;
  NSMutableArray *failed, *ok;
  int rc;
  
  if ((rc = [self _validateDefaults]) != 0)
    /* some default argument was invalid */
    return rc;
  if ((rc = [self _validateInputFiles]) != 0)
    /* some input file does not exist? */
    return rc;
  
  NS_DURING {
    if (imapDebug) {
      fprintf(stderr, "got bulkFile %s and mimeDataFile %s\n",
              [self->bulkFile cString], [self->mimeDataFile cString]);
    }
    
    mails = [[NSString stringWithContentsOfFile:self->bulkFile]
                       componentsSeparatedByString:@"\n"];
    
    if ([mails count] == 0) {
      NSLog(@"%s: missing mail in bulkFile %@",
            __PRETTY_FUNCTION__, bulkFile);
      return 3;
    }
    enumerator = [mails objectEnumerator];
    data       = [NSData dataWithContentsOfMappedFile:mimeDataFile];

    failed = [NSMutableArray arrayWithCapacity:[mails count]];
    ok     = [NSMutableArray arrayWithCapacity:[mails count]];
    
    while ((email = [enumerator nextObject])) {
      NSString *emailAddr;
      
      emailAddr = checkEmail(email);
      {
        int        max = [emailAddr cStringLength];
        char       mail[(max * 2)+1];
        const char *org;
        int        cnt, mailCnt;
        BOOL       containsOnlySpaces;
      
        NSMutableDictionary *dict;

        org       = [emailAddr cString];
        mailCnt   = 0;

        containsOnlySpaces = YES;
      
        for (cnt = 0; cnt < max; cnt++) {
          if (org[cnt] == 34) {
            mail[mailCnt++] = '\\';
            mail[mailCnt++] = '"';
          }
          else if (org[cnt] > 32 && org[cnt] < 127) {
            mail[mailCnt++]    = org[cnt];
            containsOnlySpaces = NO;
          }
          else if (org[cnt] == 32) {
            mail[mailCnt++] = org[cnt];
          }

        }
        mail[mailCnt] = '\0';
        if (!containsOnlySpaces) {
          if (imapDebug) {
            fprintf(stderr, "bulk_message: %s || <%s>\n",[sendMailCall cString],
                    mail);
          }
          dict = [self sendMail:sendMailCall to:mail len:mailCnt 
		       header:email data:data];
          [dict setObject:email forKey:@"entry"];

          if ([dict objectForKey:@"error"])
            [failed addObject:dict];
          else
            [ok addObject:dict];
        }
      }
    }
    if ([status length] > 0)
      [self processStatusForData:data ok:ok failed:failed];
    
    [self cleanupTemporaryFiles];
  }
  
  NS_HANDLER {
    printf("got exception %s\n", [[localException description] cString]);
  }
  NS_ENDHANDLER;
  
  return rc;
}

@end /* SkySendBulkMessagesTool */



int main(int argc, const char **argv, char **env) {
  NSAutoreleasePool       *pool;
  SkySendBulkMessagesTool *tool;
  int rc;

  pool = [[NSAutoreleasePool alloc] init];
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv 
                 count:argc environment:env];
  [NSAutoreleasePool enableDoubleReleaseCheck:NO];
#endif

  tool = [[SkySendBulkMessagesTool alloc] init];
  if (argc == 1) {
    [tool usage];
    rc = 0; /* shouldn't that return an error code? */
  }
  else
    rc = [tool run];

  // do not release pool or tool, process will exit anyway ...
  
  exit(rc);
  return rc;
}
