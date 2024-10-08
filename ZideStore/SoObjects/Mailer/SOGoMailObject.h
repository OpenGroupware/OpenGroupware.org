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

#ifndef __Mailer_SOGoMailObject_H__
#define __Mailer_SOGoMailObject_H__

#include <SoObjects/Mailer/SOGoMailBaseObject.h>

/*
  SOGoMailObject
    Parent object: the SOGoMailFolder
    Child objects: SOGoMailBodyPart's
  
  Represents a single mail as retrieved using NGImap4. Since IMAP4 can parse
  MIME structures on the server side, which we map into child objects of the
  message.
  The child objects are accessed using integer IDs, eg:
    /INBOX/12345/1/2/3
  would address the MIME part 1.2.3 of the mail 12345 in the folder INBOX.
*/

@class NSData, NSString, NSArray, NSCalendarDate, NSException, NSDictionary;
@class NGImap4Envelope, NGImap4EnvelopeAddress;

@interface SOGoMailObject : SOGoMailBaseObject
{
  id coreInfos;
}

/* message */

- (id)fetchParts:(NSArray *)_parts; /* Note: 'parts' are fetch keys here */

/* core infos */

- (id)fetchCoreInfos; // TODO: what does it do?

- (NGImap4Envelope *)envelope;
- (NSString *)subject;
- (NSCalendarDate *)date;
- (NSArray *)fromEnvelopeAddresses;
- (NSArray *)toEnvelopeAddresses;
- (NSArray *)ccEnvelopeAddresses;

- (id)bodyStructure;
- (id)lookupInfoForBodyPart:(id)_path;

/* content */

- (NSData *)content;
- (NSString *)contentAsString;

/* bulk fetching of plain/text content */

- (NSArray *)plainTextContentFetchKeys;
- (NSDictionary *)fetchPlainTextParts:(NSArray *)_fetchKeys;
- (NSDictionary *)fetchPlainTextParts;
- (NSDictionary *)fetchPlainTextStrings:(NSArray *)_fetchKeys;

/* flags */

- (NSException *)addFlags:(id)_f;
- (NSException *)removeFlags:(id)_f;

@end

#endif /* __Mailer_SOGoMailObject_H__ */
