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
// $Id$

#ifndef __OGoWebMail_LSWImapMailEditor_H__
#define __OGoWebMail_LSWImapMailEditor_H__

#import <OGoFoundation/LSWContentPage.h>
#import <OGoFoundation/LSWMailEditorComponent.h>
#import <NGMime/NGMime.h>

@class NSMutableArray, NSDictionary, NSString, NSArray, NSData;
@class NSMutableDictionary;
@class NGMimeMessage, NGImap4Context;
@class SkyImapMailRestrictions;

@interface LSWImapMailEditor : LSWContentPage < LSWMailEditorComponent >
{
  NSMutableArray *addresses;
  NSMutableArray *mimeParts;
  NSDictionary   *addressEntry;
  NSString       *searchString;
  NSArray        *addressKeys;
  NSString       *mailText;
  NSString       *mailSubject;  
  unsigned       count;
  id             item;
  NSMutableArray      *attachments;
  NSMutableDictionary *attachment;
  int            attachmentIdx;
  id             addressEntryPopupItem;
  struct {
    int sendPlainText:1;
    int returnReceipt:1;
    int isExtendedSearch:1;
    int isReply:1;
    int isForward:1;
    int isAppointmentNotification:1;
    int spare:26;
  } flags;
  
  NGImap4Context *imapContext;

  NSString *login;
  NSString *host;
  NSString *pwd;
  BOOL     savePasswd;
  
  SkyImapMailRestrictions *mailRestrictions;
  
  NSMutableArray      *uploadArray; /* contains NSMutableDictionary objects */
  NSMutableDictionary *uploadItem;  /* keys: data, fileName */
  int                 uploadArrayIdx;

  NSString *selectedFrom;

  enum {
    Warning_Send,
    Warning_Save
  } warningKind;
}

/* actions */

- (id)addAddress;
- (id)send;
- (id)cancel;

/* accessors */

- (void)setSubject:(NSString *)_subject;
- (void)setContent:(NSString *)_content;
- (void)setImapContext:(NGImap4Context *)_context;

- (void)setIsAppointmentNotification:(BOOL)_value;
- (BOOL)isAppointmentNotification;

- (void)setIsExtendedSearch:(BOOL)_flag;
- (BOOL)isExtendedSearch;

/* addresses */

- (void)addReceiver:(id)_person type:(NSString *)_rcvType;
- (void)addReceiver:(id)_person; // type == "to"

- (void)addAddressRecord:(NSDictionary *)_record;

/* attachments */

- (void)addMimePart:(id)_obj type:(NGMimeType *)_type
  name:(NSString *)_name;
- (void)addAttachment:(id)_object type:(NGMimeType *)_type;
- (void)addAttachment:(id)_object; // type=[_obj mimeType]

- (void)addMimePart:(id)_part;

/* other */

- (id)buildMessageAndSend:(BOOL)_send save:(BOOL)_save;
- (id)buildMessageAndSend:(BOOL)_send save:(BOOL)_save
  checkAddress:(BOOL)_checkAddr;

@end

#endif /* __OGoWebMail_LSWImapMailEditor_H__ */
