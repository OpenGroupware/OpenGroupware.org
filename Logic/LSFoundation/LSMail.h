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

#ifndef __LSLogic_LSFoundation_LSMail_H__
#define __LSLogic_LSFoundation_LSMail_H__

#import <Foundation/NSObject.h>

/**
 * @class LSMail
 * @brief Simple mail sending utility using sendmail.
 *
 * Provides both class methods for one-shot message sending
 * and an instance-based API for constructing and sending
 * emails. Messages are delivered by piping RFC 822 formatted
 * output to the sendmail binary (default /usr/lib/sendmail).
 *
 * Supports To, CC, From, Subject, and a plain text body.
 */
@interface LSMail : NSObject
{
@protected
  NSString *subject;
  NSString *mailTo;
  NSString *mailCC;
  NSString *mailTool;
  NSString *message;
  NSString *from;
}

+ (void)sendMessage:(NSString *)_string
  withSubject:(NSString *)_subject
  from:(NSString *)_from
  to:(NSString *)_to;

+ (void)sendMessage:(NSString *)_string
  withSubject:(NSString *)_subject
  to:(NSString *)_to;

- (void)setSubject:(NSString *)_subject;
- (void)setMailTo:(NSString *)_to;
- (void)setMailCC:(NSString *)_cc;
- (void)setMessage:(NSString *)_message;
- (void)setFrom:(NSString *)_from;
- (void)sendMail;

@end

#endif /* __LSLogic_LSFoundation_LSMail_H__ */
