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

#include "SkyGreetingCardAction.h"
#include "common.h"
#include "GDImage.h"
#include <XmlRpc/XmlRpcMethodCall.h>
#include <OGoIDL/NGXmlRpcAction+Introspection.h>
#include <LSFoundation/NSObject+Commands.h>

@interface SkyGreetingCardAction(PrivateMethods)
- (NSData *)_createNewImage:(NSString *)_template:(NSString *)_text;
@end /* SkyGreetingCardAction(PrivateMethods) */

@implementation SkyGreetingCardAction

+ (NSArray *)xmlrpcNamespaces {
  return [NSArray arrayWithObject:@"greeting"];
}

- (NSString *)xmlrpcComponentName {
  return @"greeting";
}

- (NSString *)cardsPath {
  return [[[NGBundle mainBundle] bundlePath]
                     stringByAppendingPathComponent:@"Cards"];
}

- (NSString *)sendmailPath {
  return @"/usr/sbin/sendmail ";
}

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx])) {
    NSString *path;
    NSBundle *bundle;

    bundle = [NSBundle bundleForClass:[self class]];

    path = [bundle pathForResource:@"INTERFACE" ofType:@"xml"];
    if (path != nil)
      [self registerInterfaceAtPath:path
            forComponentName:[self xmlrpcComponentName]];
    else
      [self logWithFormat:@"INTERFACE.xml not found in bundle path"];
  }
  return self;
}

- (NSArray *)listTemplatesAction {
  NSString *path;

  path = [self cardsPath];
  return [[NSFileManager defaultManager] directoryContentsAtPath:path];
}

- (NSNumber *)sendCardAction:(NSString *)_template
                            :(NSString *)_sender
                            :(NSArray  *)_recipients
                            :(NSString *)_text
{
  NSMutableString *sendmail = nil;
  FILE *toMail;
  
  sendmail = [NSMutableString stringWithCapacity:256];

  [sendmail appendString:[self sendmailPath]];

  if ([_recipients count] > 0) {
    NSString *rec;

    rec = [_recipients componentsJoinedByString:@" "];

    [sendmail appendString:rec];
    
    if((toMail = popen([sendmail cString],"w"))) {
      NSEnumerator *e = nil;
      id entry;
      NSData *picdata;

      e = [_recipients objectEnumerator];
      while ((entry = [e nextObject])) {
        fprintf(toMail,"To: %s\r\n",[[entry stringValue] cString]);
      }

      fprintf(toMail,"Organization: http://www.opengroupware.org\r\n");
      fprintf(toMail,"MIME-Version: 1.0\r\n");
      fprintf(toMail,"Subject: Greetings from %s\r\n",[_sender cString]);
      fprintf(toMail,"From: %s\r\n", [_sender cString]);
      fprintf(toMail,"Date: %s\r\n", [[[[NSDate date] 
                      dateWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %z"
                                              timeZone:nil] 
                      stringValue] cString]);
      fprintf(toMail,"Content-Type: image/jpeg; name=\"GreetingCard.jpg\"\r\n"
                   "Content-Transfer-Encoding: base64\r\n"
                   "Content-Disposition: inline; filename=\"GreetingCard.jpg\""
                   "\r\n\r\n");

      if ((picdata = [self _createNewImage:_template:_text]) != nil) {
        picdata = [picdata dataByEncodingBase64];
        NSLog(@"picdata is %@", picdata);
      }

      fwrite([picdata bytes], [picdata length],1,toMail); 
      fprintf(toMail,"\r\n");
      pclose(toMail);
    }
  }
  return [NSNumber numberWithBool:YES];
}

- (NSData *)_createNewImage:(NSString *)_template
                           :(NSString *)_text
{
  GDImage    *oim, *ostamp;
  NSString   *fontPath;
  NSString   *templatePath;
  NSBundle   *bundle = nil;

  NSString   *fontname = @"Verdana";
  unsigned short fontSize = 10.0;

  bundle = [NSBundle mainBundle];
  fontPath = [bundle pathForResource:fontname ofType:@"ttf"];

  templatePath = [[self cardsPath] stringByAppendingPathComponent:_template];
  oim = [[GDImage alloc] initWithContentsOfFile:templatePath];
  AUTORELEASE(oim);
  ostamp = [[GDImage alloc] initWithContentsOfFile:
                            [bundle pathForResource:@"Stamp"
                                    ofType:@"jpg"]];
  AUTORELEASE(ostamp);

  if (oim) {

    NSString *stringDate = nil;
    int brect[8];
    
    if (ostamp) {
     
      [ostamp copyRect:NSMakeRect(0, 0, [ostamp width], [ostamp height])
              to:NSMakePoint([oim width] - [ostamp width] - 4, 4)
              ofImage:oim];
    }

    stringDate = [[[NSDate date]
                           dateWithCalendarFormat:@"%d %b"
                           timeZone:nil]
                           stringValue];

    [oim writeStringFT:stringDate
            at:NSMakePoint([oim width] - 65,55)
            angle:0.0
            color:[oim resolveColor:0:0:0]
            fontList:fontPath size:6.0
            boundingRect:NULL];

    [oim writeStringFT:@"http://www.skyrix.com"
         at:NSMakePoint([oim width],[oim height]) angle:0.0
         color:[oim resolveColor:255:255:255]
         fontList:fontPath size:12.0
         boundingRect:brect];

    [oim writeStringFT:@"http://www.skyrix.com"
         at:NSMakePoint([oim width] - (brect[2] - brect[0] + 10),
                        [oim height] - (brect [3] - brect[5] - 5))
         angle:0.0
         color:[oim resolveColor:0:0:0]
         fontList:fontPath size:12.0
         boundingRect:NULL];
    
    [oim writeStringFT:_text
         at:NSMakePoint([oim width] - 200,100) angle:0.0
         color:[oim resolveColor:0:0:0]
         fontList:fontPath
         size:fontSize
         boundingRect:brect];
  }
  return [oim jpegData];
}

@end /* SkyGreetingCardAction */
