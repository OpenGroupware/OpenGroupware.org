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

#import <Foundation/Foundation.h>
#import <Foundation/NSUserDefaults.h>

#include <EOControl/EOControl.h>
#include <OGoProject/SkyProject.h>
#include <NGMail/NGMail.h>
#include <NGMime/NGMime.h>
#include <NGHttp/NGHttpHeaderFields.h>
#include <NGImap4/NGImap4.h>
#include <NGImap4/NGImap4FileManager.h>
#include <NGImap4/NGImap4DataSource.h>

#include <stdio.h>
#include <unistd.h>

#include "common.h"
#include "Application.h"
#include "DirectAction.h"
#include "Session.h"
#include "SieveManager.h"

@implementation DirectAction(Mail)

- (NGHttpCredentials *)credentials {
  return [NGHttpCredentials credentialsWithString:
                            [[self request] headerForKey:@"authorization"]];
}
- (NSString *)username {
  return [[self credentials] userName];
}
- (NSString *)password {
  return [[self credentials] password];
}

- (SieveManager *)sieveManager {
  SieveManager *sm = nil;

  sm = [[SieveManager alloc] initWithServer:@"localhost"
                             port:20000
                             fileName:nil
                             userName:[self username]
                             password:[self password]];
  return AUTORELEASE(sm);
}

- (NSDictionary *)account {
  NSDictionary        *accounts = nil;
  NSMutableDictionary *account  = nil;
  NSMutableDictionary *dict     = nil;
  NSString            *text     = nil;
  NSUserDefaults      *ud       = nil;

  ud = [NSUserDefaults standardUserDefaults];

  accounts = [ud dictionaryForKey:@"skymaild.accounts"];

  if (![accounts isNotNull]) {
    NSLog(@"%s: No mail accounts key.", __PRETTY_FUNCTION__);
    return nil;
  }

  if (![accounts count]) {
    NSLog(@"%s: No mail accounts configured.", __PRETTY_FUNCTION__);
    return nil;
  }

  account = [NSMutableDictionary dictionaryWithCapacity:0];
  [account setDictionary:[accounts objectForKey:@"smart.in.skyrix.com"]];

  if (![account isNotNull]) {
    NSLog(@"%s: Named mail account not found.", __PRETTY_FUNCTION__);
    return nil;
  }

  dict = [NSMutableDictionary dictionaryWithCapacity:2];

  [dict setObject:[self username] forKey:@"HTTP_USER"];
  [dict setObject:[self password] forKey:@"HTTP_PWD"];

  text = [account objectForKey:@"username"];
  text = [text stringByReplacingVariablesWithBindings:dict
               stringForUnknownBindings:@""];
  [account setObject:text forKey:@"username"];

  text = [account objectForKey:@"password"];
  text = [text stringByReplacingVariablesWithBindings:dict
               stringForUnknownBindings:@""];
  [account setObject:text forKey:@"password"];

  return AUTORELEASE([account copy]);
}

- (NSString *)mailhost {
  return [[self account] objectForKey:@"receive_server"];
}

- (NSString *)fromAddress {
  return [NSString stringWithFormat:@"%@@%@",
                   [self username],
                   [[self account] objectForKey:@"receive_server"]];
}
- (NSString *)fullFromAddress {
  return [NSString stringWithFormat:@"\"XXX YYY\" <%@>", [self fromAddress]];
}

- (NGImap4FileManager *)imapFileManager {
  NGImap4FileManager *fm = nil;

  fm = [[NGImap4FileManager alloc] initWithUser:[self username]
                                   password:[self password]
                                   host:[self mailhost]];
  return AUTORELEASE(fm);
}

- (NSString *)sendMailPath {
  NSString *sendMailPath = nil;

  sendMailPath = [[NSUserDefaults standardUserDefaults]
                                  stringForKey:@"SendMailPath"];
  if ([sendMailPath length] == 0)
    return @"/usr/lib/sendmail";

  return sendMailPath;
}

- (NSArray *)getFilterNamesAction {
  return [[self sieveManager] filterNames];
}

- (NSArray *)getFiltersAction {
  NSEnumerator   *enu    = nil;
  Filter         *filter = nil;
  NSMutableArray *result = nil;

  enu = [[[self sieveManager] filters] objectEnumerator];
  result = [NSMutableArray array];

  while ((filter = [enu nextObject]))
    [result addObject:[filter dictionaryRepresentation]];

  return result;
}

- (NSNumber *)insertFilterAction:(NSDictionary *)_filter {
  Filter       *filter = nil;
  SieveManager *sm     = nil;

  if (! [_filter isNotNull]) {
    NSLog(@"%s can't insert null object", __PRETTY_FUNCTION__);
    return NO;
  }

  NSLog(@"_filter = %@", _filter);

  filter = [Filter filterWithDictionary:_filter];

  NSLog(@"filter = %@", filter);

  sm = [self sieveManager];
  if ([sm insertFilter:filter])
    if ([sm saveFile])
      return [NSNumber numberWithBool:YES];

  return [NSNumber numberWithBool:NO]; // error
}

- (NSNumber *)updateFilterAction:(int)_filterPos
                                :(NSDictionary *)_filter
{
  Filter       *filter = nil;
  SieveManager *sm     = nil;

  if (! [_filter isNotNull]) {
    NSLog(@"%s can't use null object", __PRETTY_FUNCTION__);
    return NO;
  }

  sm = [self sieveManager];
  filter = [sm filterAtPosition:_filterPos];
  if (! [filter isNotNull]) {
    NSLog(@"%s can't find object to be updated", __PRETTY_FUNCTION__);
    return [NSNumber numberWithBool:NO];
  }

  filter = [Filter filterWithDictionary:_filter];
  if ([sm replaceFilter:filter atPosition:_filterPos])
    if ([sm saveFile])
      return [NSNumber numberWithBool:YES];

  return [NSNumber numberWithBool:NO]; // YES = ok, NO = error
}

- (NSNumber *)deleteFilterAction:(id)_handle {
  SieveManager *sm = nil;
  BOOL         rc;

  sm = [self sieveManager];
  if ([_handle isKindOfClass:[NSNumber class]]) { // filterPos
    rc = [sm deleteFilterAtPosition:[(NSNumber *)_handle intValue]];

  } else if ([_handle isKindOfClass:[NSString class]]) { // name
    rc = [sm deleteFilterWithName:(NSString *)_handle];

  } else if ([_handle isKindOfClass:[NSDictionary class]]) { // Filter
    Filter *filter = nil;

    filter = [Filter filterWithDictionary:(NSDictionary *)_handle];

    rc = [sm deleteFilter:filter];
  }

  if (rc)
    if ([sm saveFile])
      return [NSNumber numberWithBool:YES];

  return [NSNumber numberWithBool:NO]; // NO = error, YES = okay
}

- (NSNumber *)setFiltersAction:(NSArray *)_filters {
  NSMutableArray *ma  = nil;
  NSEnumerator   *enu = nil;
  SieveManager   *sm  = nil;
  id             obj;

  if (! [_filters isNotNull]) {
    NSLog(@"%s: got empty filter list", __PRETTY_FUNCTION__);
    return [NSNumber numberWithBool:NO];
  }

  ma  = [NSMutableArray arrayWithCapacity:0];
  enu = [_filters objectEnumerator];
  while ((obj = [enu nextObject])) {
    if ([obj isKindOfClass:[NSDictionary class]]) {
      Filter *filter = nil;

      filter = [Filter filterWithDictionary:obj];

      if ([filter isNotNull])
        [ma addObject:filter];
    } else {
      NSLog(@"%s: filter is not a dictionary - ignored", __PRETTY_FUNCTION__);
    }
  }

  sm = [self sieveManager];
  [sm setFilters:ma];
  if ([sm saveFile])
    return [NSNumber numberWithBool:YES];

  return [NSNumber numberWithBool:NO];
}

- (NSNumber *)publishFiltersAction:(NSArray *)_filters {


  return [NSNumber numberWithBool:NO]; // error
}

// Gets a to, cc or bcc-line and extracts the plain email addresses.
// We need them as parameters for sendmail.

- (NSString *)extractMailAddresses:(NSString *)_str {
  NSString            *str = nil;
  NGMailAddressParser *map = nil;
  NSEnumerator        *enu = nil;
  NGMailAddress       *adr = nil;

  map = [NGMailAddressParser mailAddressParserWithString:_str];
  enu = [[map parseAddressList] objectEnumerator];

  str = @"";
  while ((adr = [enu nextObject])) {
    str = [NSString stringWithFormat:@"%@ %@", str, [adr address]];
  }

  return str;
}

// Method    : sendMessage
// Parameter : Empfänger (req) Array of Strings or Array of Recipients
//             Subject (req)
//             Content (req)
//             Attachments (opt)
//             Headers (opt)
// Result    : YES/NO

- (NSNumber *)sendMessageAction:(NSArray *)_recipients
                               :(NSString *)_subject
                               :(NSString *)_content
                               :(NSArray *)_attachments
                               :(NSDictionary *)_headers
{
  NGMimeMessage       *message  = nil;
  NSString            *content  = nil;
  NSString            *subject  = nil;
  NGMutableHashMap    *hdr      = nil;
  NGMimeType          *mimeType = nil;
  NSMutableArray      *targets  = nil;
  NSUserDefaults      *ud       = nil;

#if 1
  NSLog(@"recipients = %@", _recipients);
  NSLog(@"subject = %@", _subject);
  NSLog(@"content = %@", _content);
  NSLog(@"attachments = %@", _attachments);
  NSLog(@"headers = %@", _headers);
#endif

#if 0
  if ([_recipients isKindOfClass:[NSString class]]) {
    if (! [_recipients length]) {
      NSLog(@"%s: No recipients.", __PRETTY_FUNCTION__);
      return [NSNumber numberWithBool:NO];
    }
  }
#endif

  if ([_recipients isKindOfClass:[NSArray class]]) {
    if ([_recipients count] == 0) {
      NSLog(@"%s: No recipients.", __PRETTY_FUNCTION__);
      return [NSNumber numberWithBool:NO];
    }
  }

  if ([_subject length] == 0)
    subject = @"no subject";
  else
    subject = _subject;

  if ([_content length] == 0)
    NSLog(@"%s: No content.", __PRETTY_FUNCTION__);
  content = _content;

  ud = [NSUserDefaults standardUserDefaults];

  if (![ud isNotNull]) {
    NSLog(@"%s: Invalid user defaults.", __PRETTY_FUNCTION__);
    return [NSNumber numberWithBool:NO];
  }

  if (![[ud dictionaryRepresentation] count]) {
    NSLog(@"%s: Empty user defaults.", __PRETTY_FUNCTION__);
    return [NSNumber numberWithBool:NO];
  }

  // Wrap message.

  if ([ud boolForKey:@"skymaild.wrapmails"] == YES) {
    int length = 0;

    length = [ud integerForKey:@"skymaild.wraplength"];
    if (length == 0)
      length = 80;

    //content = __wrapString(self, content, length);
  }

  // Add signature.

  {
    NSString *signature = nil;

    signature = [ud objectForKey:@"skymaild.signature"];

    if ([signature isNotNull] && [content isNotNull]) {
      content = [[content stringByAppendingString:@"\n-- \n"]
                          stringByAppendingString:signature];
    }
  }

  // Parse targets.

  targets = [NSMutableArray arrayWithCapacity:1];
  hdr = [[NGMutableHashMap allocWithZone:[self zone]] initWithCapacity:16];

  mimeType = ([_attachments count] > 0)
    ? [NGMimeType mimeType:@"multipart/mixed"]
    : [NGMimeType mimeType:@"text/plain"];

  if ([_recipients isKindOfClass:[NSArray class]]) {
    NSEnumerator *enu = nil;
    NSString     *key = nil;
    NSString     *val = nil;
    id           obj;

    enu = [_recipients objectEnumerator];
    while ((obj = [enu nextObject])) {
      if ([obj isKindOfClass:[NSString class]]) {
        key = ([[hdr objectForKey:@"to"] isNotNull]) ? @"cc" : @"to";
        val = obj;
      }
      else if ([obj isKindOfClass:[NSDictionary class]]) {
        key = [(NSDictionary *)obj objectForKey:@"header"];
        val = [(NSDictionary *)obj objectForKey:@"email"];
      }

      if ( ([key isEqualToString:@"to"]) ||
           ([key isEqualToString:@"cc"]) ||
           ([key isEqualToString:@"bcc"]) ) {
        [hdr addObject:val forKey:key];

        val = [self extractMailAddresses:val];
        if ([val length])
          [targets addObject:val];
      }
    }
  }

  // Include optional headers.

  if ([_headers isNotNull]) {
    NSEnumerator *enu = [_headers keyEnumerator];
    id key;
    id val;

    while ((key = [enu nextObject])) {
      val = [_headers objectForKey:key];

      if ([val isNotNull])
        [hdr addObject:val forKey:key];
    }
  }

  // Headers.

  if (! [[hdr objectForKey:@"from"] isNotNull])
    [hdr setObject:[self fullFromAddress] forKey:@"from"];

  if (! [[hdr objectForKey:@"subject"] isNotNull])
    [hdr setObject:subject forKey:@"subject"];

  if (! [[hdr objectForKey:@"date"] isNotNull])
    [hdr setObject:[NSCalendarDate date] forKey:@"date"];

  if (! [[hdr objectForKey:@"MIME-Version"] isNotNull])
    [hdr setObject:@"1.0" forKey:@"MIME-Version"];

  if (! [[hdr objectForKey:@"X-Mailer"] isNotNull])
    [hdr setObject:@"SKYRiX Groupware Server" forKey:@"X-Mailer"];

  if (! [[hdr objectForKey:@"content-type"] isNotNull])
    [hdr setObject:mimeType forKey:@"content-type"];

  // Generate message.

  message = [NGMimeMessage messageWithHeader:hdr];

  if ([_attachments count] == 0) {
    [message setBody:content];
  }
  else {
    NGMimeBodyPart      *mbp = nil;
    NGMimeMultipartBody *mmb = nil;
    NGMutableHashMap    *map = nil;

    map = [[NGMutableHashMap alloc] init];
    [map addObject:[NGMimeType mimeType:@"text/plain"] forKey:@"content-type"];
    mmb = [[NGMimeMultipartBody alloc] initWithPart:message];
    mbp = [[NGMimeBodyPart alloc] initWithHeader:map];
    [mbp setBody:content];
    [mmb addBodyPart:mbp]; // 1. part: text or HTML body.

    RELEASE(map); map = nil;
    RELEASE(mbp); mbp = nil;

    // Add attachments.

    {
      NSEnumerator *enu = nil;
      id            att = nil;

      enu = [_attachments objectEnumerator];
      while ((att = [enu nextObject])) {
        NGMimeBodyPart                      *p           = nil;
        NGMutableHashMap                    *h           = nil;
        NSString                            *type        = nil;
        NGMimeContentDispositionHeaderField *d           = nil;
        NSString                            *disposition = nil;
        id                                  data         = nil;

        data = [att objectForKey:@"content"];
        if ([data isKindOfClass:[NSString class]])
          data = [[data dataUsingEncoding:NSASCIIStringEncoding]
                        dataByDecodingBase64];

        disposition = [NSString stringWithFormat:
                                @"inline; filename=\"%@\"",
                                [att objectForKey:@"fileName"]];
        d = [[NGMimeContentDispositionHeaderField alloc]
                                                  initWithString:disposition];
        h = [[NGMutableHashMap alloc] init];
        [h setObject:[NGMimeType mimeType:[att objectForKey:@"mimeType"]]
           forKey:@"content-type"];
        [h setObject:d forKey:@"content-disposition"];

        p = [[NGMimeBodyPart alloc] initWithHeader:h];

        type = [(NGMimeType *)[NGMimeType mimeType:[att objectForKey:
                                                        @"mimeType"]] type];
        //NSLog(@"%s type = %@", __PRETTY_FUNCTION__, type);

        if ([type isEqualToString:@"text"]) {
          NSString *tmpString = nil;

          if ([data isKindOfClass:[NSString class]])
            tmpString = [NSString stringWithString:(NSString *)data];
          else
            tmpString = [NSString stringWithCString:[data bytes]];

          [p setBody:tmpString];
        }
        else if ([type isEqualToString:@"message"]) {
          NGMimeMessageParser *parser;

          parser = [[NGMimeMessageParser alloc] init];
          [p setBody:[parser parsePartFromData:data]];
          RELEASE(parser); parser = nil;
        }
        else {
          [p setBody:data];
        }

        [mmb addBodyPart:p];

        RELEASE(h); h = nil;
        RELEASE(p); p = nil;
        RELEASE(d); d = nil;
      }
    }

    [message setBody:mmb];

    RELEASE(mmb); mmb = nil;
  }

  // Send mail.

  {
    NSMutableString        *sendmail = nil;
    NGMimeMessageGenerator *gen      = nil;
    NGMimeMessageParser    *parser   = nil;
    NSEnumerator           *enu      = nil;
    NSString               *str      = nil;
    id                      mimePart = nil;
    NSData                 *mimeData = nil;
    FILE                   *toMail   = NULL;

    sendmail = [NSMutableString stringWithString:[self sendMailPath]];
    gen      = [[NGMimeMessageGenerator allocWithZone:[self zone]] init];
    mimeData = [gen generateMimeFromPart:message];

    if (! [mimeData isNotNull])
      mimeData = [[NSData allocWithZone:[self zone]] init];

    RELEASE(gen); gen = nil;

    parser = [[NGMimeMessageParser allocWithZone:[self zone]] init];
    mimePart = [parser parsePartFromData:mimeData];
    RELEASE(parser); parser = nil;

    [sendmail appendString:@" -f "];
    [sendmail appendString:[self fromAddress]];
    [sendmail appendString:@" "];

    enu = [targets objectEnumerator];
    while ((str = [enu nextObject])) {
      [sendmail appendString:str];
      [sendmail appendString:@" "];
    }

    if ((toMail = popen([sendmail cString], "w")) != NULL) {
      if (fprintf(toMail, "%s", (char *)[mimeData bytes]) < 0) {
        [self logWithFormat:@"Couldn't write mail to sendmail!"];
        [self logWithFormat:@"message: %s", (char *)[mimeData bytes]];
        return [NSNumber numberWithBool:NO];
      }
      if (pclose(toMail) != 0) {
        [self logWithFormat:@"Couldn't write mail to sendmail!"];
        return [NSNumber numberWithBool:NO];
      }
    }
    else {
      [self logWithFormat:@"Couldn't open sendmail!"];
      return [NSNumber numberWithBool:NO];
    }
  }

  return [NSNumber numberWithBool:YES];
}

// Method    : getFolder
// Parameter : Verzeichnisname auf dem Mail-Server
// Result    : Array mit Mails als Strings.

- (NSArray *)getFolderAction:(NSString *)_folderName {
  return [[self imapFileManager] filesAtPath:_folderName];
}

// Method     : getMessage
// Parameters : Filename on the mail server
// Result     : The mail itself as dictionary

- (NSDictionary *)getMessageAction:(NSString *)_messagePath {
  NSMutableDictionary  *result = nil;
  NSArray              *got    = nil;
  NGImap4FileManager   *fm     = nil;
  NSString             *path   = nil;
  BOOL                 isDir;
  NGImap4DataSource    *ds     = nil;
  EOQualifier          *qual   = nil;
  EOFetchSpecification *fs     = nil;
  NSString             *uid    = nil;
  NGImap4Message       *imapMessage = nil;
  NGMimeMessage        *mimeMessage = nil;
  NSString             *str         = nil;
 
  result = [NSMutableDictionary dictionaryWithCapacity:1];
  fm = [self imapFileManager];
  path = _messagePath;

  if (! [fm fileExistsAtPath:path isDirectory:&isDir]) {
    NSLog(@"%s path = %@ doesn't exists", __PRETTY_FUNCTION__, path);
    return nil;
  }

  if (isDir) {
    NSLog(@"%s path = %@ is a directory", __PRETTY_FUNCTION__, path);
    return nil;
  }

  uid  = [path lastPathComponent];
  path = [path stringByDeletingLastPathComponent];

  ds   = (NGImap4DataSource *)[fm dataSourceAtPath:path];
  qual = [EOQualifier qualifierWithQualifierFormat:@"uid = %@", uid];
  fs   = [[EOFetchSpecification alloc] init];
  [fs setQualifier:qual];
  [ds setFetchSpecification:fs];

  AUTORELEASE(fs);

  got = [ds fetchObjects];

  if ([got count] != 1) {
    NSLog(@"%s: missing mail/got to much [%d]", __PRETTY_FUNCTION__,
          [got count]);
    return [NSDictionary dictionary];
  }

  imapMessage = [got lastObject];
  mimeMessage = [imapMessage message];

  // Build message dict.

  { // content-type
    id val = [[mimeMessage contentType] stringValue];

    [result setObject:val forKey:@"content-type"];
  }

  { // body
    id val = [mimeMessage body];

    if (![val isKindOfClass:[NSString class]] &&
        ![val isKindOfClass:[NSData class]])
      val = @"";

    [result setObject:val forKey:@"content"];
  }

  { // headers
    NSMutableDictionary *dict = nil;
    NSEnumerator        *enu  = nil;
    NSString            *key  = nil;
    id                  val   = nil;

    dict = [NSMutableDictionary dictionaryWithCapacity:10];
    enu  = [mimeMessage headerFieldNames];
    while ((key = [enu nextObject])) {
      val = [[mimeMessage valuesOfHeaderFieldWithName:key] nextObject];

      if ([val isNotNull]) {
        if ([val isKindOfClass:[NSString class]])
          [dict setObject:val forKey:key];
        else if ([val isKindOfClass:[NGMimeType class]])
          [dict setObject:[val stringValue] forKey:key];
        else
          NSLog(@"%s: headerfield \"%@\" ignored, unknown value mimetype",
                __PRETTY_FUNCTION__, key);
      }
    }

    [result setObject:dict forKey:@"headers"];
  }

  { // subject
    str = [[mimeMessage valuesOfHeaderFieldWithName:@"subject"] nextObject];
    if (![str length])
      str = @"";
    [result setObject:str forKey:@"subject"];
  }

  { // date
    id val = [[mimeMessage valuesOfHeaderFieldWithName:@"date"] nextObject];

    if ([val isNotNull])
      val = [val description];
    else
      val = @"";

    [result setObject:val forKey:@"date"];
  }

  { // from
    id val = [[mimeMessage valuesOfHeaderFieldWithName:@"from"] nextObject];

    if (! [val isNotNull])
      val = @"";

    [result setObject:val forKey:@"from"];
  }

  { // to
    id val = [[mimeMessage valuesOfHeaderFieldWithName:@"to"] nextObject];

    if (! [val isNotNull])
      val = @"";

    [result setObject:val forKey:@"to"];
  }

  { // cc
    id val = [[mimeMessage valuesOfHeaderFieldWithName:@"cc"] nextObject];

    if (! [val isNotNull])
      val = @"";

    [result setObject:val forKey:@"cc"];
  }

  { // bcc
    id val = [[mimeMessage valuesOfHeaderFieldWithName:@"bcc"] nextObject];

    if (! [val isNotNull])
      val = @"";

    [result setObject:val forKey:@"bcc"];
  }

  { // attachments
    NSMutableArray *attachments     = nil;
    NSMutableArray *messageParts    = nil;
    NGMimeMessage  *mainMessagePart = nil;
    NSString       *ct              = nil;

    attachments = [NSMutableArray arrayWithCapacity:0];

    ct = [[mimeMessage contentType] stringValue];

    { // set messageParts
      messageParts = [NSMutableArray arrayWithCapacity:1];

      if ([ct isEqualToString:@"multipart/mixed"] ||
          [ct isEqualToString:@"multipart/signed"])
      {
        NSEnumerator *enu = nil;
        id           part = nil;

        enu = [[[mimeMessage body] parts] objectEnumerator];
        while ((part = [enu nextObject])) {
          if ([part isKindOfClass:[NGMimeMessage class]])
            //[messageParts addObjectsFromArray:[part messageParts]];
            [messageParts addObject:part];
          else
            [messageParts addObject:part];
        }
      }
      else
        [messageParts addObject:mimeMessage];
    }

    { // set mainMessagePart
      mainMessagePart = [messageParts objectAtIndex:0];


    }

    { // create and set dictionary
      NSMutableDictionary *dict = nil;
      NSEnumerator        *enu  = nil;
      id                  part  = nil;
      id                  bo    = nil;
      NSString            *fn   = nil;
      NSString            *mt   = nil;

      enu  = [messageParts objectEnumerator];
      while ((part = [enu nextObject])) {
        dict = [NSMutableDictionary dictionaryWithCapacity:1];

        bo = [part body];
        mt = [(NGMimeType *)[part contentType] stringValue];

        {
          id x = [[part valuesOfHeaderFieldWithName:@"content-disposition"]
                        nextObject];
          if ([x isNotNull])
            fn = [x filename];
          else
            fn = @"";
        }

        [dict setObject:mt forKey:@"mimeType"];
        [dict setObject:bo forKey:@"content"];
        [dict setObject:fn forKey:@"fileName"];

        [attachments addObject:dict];
      }
    }

    [result setObject:attachments forKey:@"attachments"];
  }

  return AUTORELEASE([result copy]);
}

@end /* DirectAction(Mail) */
