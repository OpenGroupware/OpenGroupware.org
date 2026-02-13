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

#ifndef __LSLogic_LSMail_LSMailDeliverCommand_H__
#define __LSLogic_LSMail_LSMailDeliverCommand_H__

#include <LSFoundation/LSBaseCommand.h>
#include <NGMime/NGPart.h>

/**
 * @class LSMailDeliverCommand
 *
 * Command for delivering outgoing email messages
 * via sendmail.
 *
 * Resolves recipient addresses, which may be OGo
 * account logins, team names, or external email
 * addresses, into actual email addresses. The
 * message body is provided as raw MIME data or an
 * NGMimePart object. Delivery is performed by
 * piping the message to the sendmail binary.
 * Mailing list recipients are handled via a
 * separate bulk-delivery tool
 * (sky_send_bulk_messages). Optionally copies the
 * sent message to the user's IMAP Sent folder.
 */

@class NSArray, NSMutableArray, NSData;

@interface LSMailDeliverCommand : LSBaseCommand
{
  NSArray        *addresses;
  NSMutableArray *logins;
  NSMutableArray *groups;
  NSMutableArray *externals;
  NSData         *mimeData;
  id<NGMimePart> mimePart;
  BOOL           copyToSentFolder;
  NSArray        *mailingLists;
  NSString       *messageTmpFile;
}

- (void)_prepareForExecutionInContext:(id)_context;
- (void)_executeInContext:(id)_context;

- (void)sendMailToAccounts:(NSArray *)_addrs inContext:(id)_context;
- (void)sendMailToExternals:(NSArray *)_externals inContext:(id)_context;

/* accessors */

- (void)setAddresses:(NSArray *)_addr;
- (NSArray *)addresses;
- (void)addAddress:(NSString *)_addr;

- (void)setMimeData:(NSData *)_data;
- (NSData *)mimeData;

- (void)setMimePart:(id)_part;
- (id<NGMimePart>)mimePart;

@end

#endif //__LSLogic_LSMail_LSMailDeliverCommand_H__
