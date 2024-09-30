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

#include "LSMail.h"
#include "common.h"

@implementation LSMail

+ (id)mail {
  return [[[LSMail alloc] init] autorelease];
}

+ (void)sendMessage:(NSString *)_string
  withSubject:(NSString *)_subject
  from:(NSString *)_from
  to:(NSString *)_to
{
  LSMail *mail = [LSMail mail];

  [mail setMailTo :_to      ? _to      : (NSString *)@""];
  [mail setMessage:_string  ? _string  : (NSString *)@""];
  [mail setSubject:_subject ? _subject : (NSString *)@""];
  [mail setFrom   :_from    ? _from    : (NSString *)@""];
  [mail sendMail];
}
+ (void)sendMessage:(NSString *)_string
  withSubject:(NSString *)_subject
  to:(NSString *)_to
{
  [LSMail sendMessage:_string withSubject:_subject from:nil to:_to];
}

- (id)init {
  if ((self = [super init])) {
    self->mailTool = @"/usr/lib/sendmail";
    self->mailTo   = @"";
    self->mailCC   = @"";
    self->message  = @"";
    self->from     = @"";
    self->subject  = @"";
  }
  return self;
}

- (void)dealloc {
  [self->mailTool release];
  [self->mailTo   release];
  [self->mailCC   release];
  [self->message  release];
  [self->from     release];
  [self->subject  release];
  [super dealloc];
}

/* accessors */

- (void)setSubject:(NSString *)_subject {
  ASSIGNCOPY(self->subject, _subject);
}

- (void)setMailTo:(NSString *)_to {
  ASSIGNCOPY(self->mailTo, _to);
}

- (void)setMailCC:(NSString *)_cc {
  ASSIGNCOPY(self->mailCC, _cc);
}

- (void)setMessage:(NSString *)_message {
  ASSIGNCOPY(self->message, _message);
}

- (void)setFrom:(NSString *)_from {
  ASSIGNCOPY(self->from, _from);
}

- (void)sendMail {
  FILE *f;
  NSString *command = [NSString stringWithFormat:@"%s %s %s",
                                [[mailTool stringValue] cString],
                                [[mailTo stringValue] cString],
                                [[mailCC stringValue] cString]];
  NSLog(@"Mail command  %@ \n", command);
  if ((f = popen([command cString], "w")) == NULL)
    return;
  
  NSLog(@"Mail From : %@ \n", from);
  fprintf(f,"From:%s\n",[[from stringValue] cString]);
  NSLog(@"Mail To : %@ \n", mailTo);  
  fprintf(f,"To:%s\n",[[mailTo stringValue] cString]);
  NSLog(@"Mail Cc : %@ \n", mailCC);  
  fprintf(f,"Cc:%s\n",[[mailCC stringValue] cString]);
  NSLog(@"Mail subject : %@ \n", subject);    
  fprintf(f,"Subject:%s\n\n",[[subject stringValue] cString]);
  NSLog(@"Mail message : %@ \n",message);    
  fprintf(f,"%s",[[message stringValue] cString]);
  fprintf(f,"\n\n");
  pclose(f);
}

@end /* LSMail */
