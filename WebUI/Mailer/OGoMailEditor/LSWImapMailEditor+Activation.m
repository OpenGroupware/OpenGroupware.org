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
#include "NGMimeType+Mailer.h"
#include "NSString+MailEditor.h"
#include "common.h"

// TODO: the commands should be implemented by separate objects which trigger
//       the editor

@interface LSWImapMailEditor(UsedPrivates)

- (NSDictionary *)_emptyEntry;
- (SkyImapMailRestrictions *)mailRestrictions;

- (void)setMailSubject:(NSString *)_value;

- (void)_setBodyForReply:(id)_obj   from:(NSString *)_from part:(id)_part;
- (void)_setBodyForForward:(id)_obj from:(NSString *)_from;

- (void)_buildEditAsNewForText:(id<NGMimePart>)_part type:(NGMimeType *)_type;
- (id)_buildMultipartAlternativePart:(NGMimeMessage *)_msg;

@end

@implementation LSWImapMailEditor(Activation)

static NSArray *ReplyAllArray = nil;

/* supporting methods */

- (NSString *)_processReplyMailSubject:(NSString *)_s {
  return [_s stringByAddingMailReplyPrefix];
}

- (NSDictionary *)_newReplyAddressRecordWithHeader:(NSString *)_h
  email:(NSString *)_email label:(NSString *)_label
  emptyEntry:(NSDictionary *)_empty
{
  NSDictionary        *record;
  NSArray             *emails;
  NSMutableDictionary *rep;
  
  rep = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       _email, @"email", 
                                       _label, @"label", nil];
  emails = [[NSArray alloc] initWithObjects:rep, _empty, nil];
  
  record = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                          _h,     @"header",
                                          emails, @"emails",
                                          rep,    @"email",
                                        nil];
  [rep    release]; rep    = nil;
  [emails release]; emails = nil;
  return record;
}

- (void)_buildReplyHeader:(NGImap4Message *)_msg toOne:(NSString *)_to 
  h:(NSString *)_h 
  emptyEntry:(NSDictionary *)_empty
{
  NSDictionary        *dict;
  NSEnumerator        *addrEnum;
  NGMailAddressParser *parser;
  NGMailAddress       *addr;
  
  // TODO: shouldn't the decoding be done in NGImap4Message?
  parser   = [NGMailAddressParser mailAddressParserWithString:
				    [_to stringByDecodingQuotedPrintable]];
  addrEnum = [[parser parseAddressList] objectEnumerator];

  if (addrEnum == nil) {
    NSString *l;
    
    l = _to;
      
    if (![[self mailRestrictions] emailAddressAllowed:_to]) {
      l = [l stringByAppendingFormat:@" (%@)",
	     [[self labels] valueForKey:@"label_prohibited"]];
      _to = @"";
    }
    
    dict = [self _newReplyAddressRecordWithHeader:_h email:_to label:l
                 emptyEntry:_empty];
    [self addAddressRecord:dict];
    [dict release]; dict = nil;
  } 
  else {
    while ((addr = [addrEnum nextObject])) {
      NSString *eAddr, *l;
      
      l = eAddr = [addr address];
	
      if (![[self mailRestrictions] emailAddressAllowed:eAddr]) {
	l = [l stringByAppendingFormat:@" (%@)",
	       [[self labels] valueForKey:@"label_prohibited"]];
	eAddr = @"";
      }

      dict = [self _newReplyAddressRecordWithHeader:_h email:eAddr label:l 
                   emptyEntry:_empty];
      [self addAddressRecord:dict];
      [dict release]; dict = nil;
    }
  }
}

- (void)_buildReplyHeader:(NGImap4Message *)_msg to:(NSArray *)_to 
  h:(NSString *)_h 
{
  // TODO: improve selector name
  NSDictionary *empty;  
  NSEnumerator *toEnum;
  id           to;
  NSString     *s;
  
  if (_h == nil)
    _h = @"to";
  else if ([_h isEqualToString:@"from"] || [_h isEqualToString:@"sender"])
    _h = @"to";
  
  empty = [self _emptyEntry];
  
  toEnum = [_to objectEnumerator];
  while ((to = [toEnum nextObject]))
    [self _buildReplyHeader:_msg toOne:to h:_h emptyEntry:empty];
  
  if ((s = [_msg valueForKey:@"subject"]))
    [self setMailSubject:[self _processReplyMailSubject:s]];
}

/* activation */

- (void)_prepareForReplyAll {
  id             obj, o, part;
  NSEnumerator   *fields;
  NSMutableArray *addr;
  NSString       *from;

  if (ReplyAllArray == nil) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    ReplyAllArray=[[ud arrayForKey:@"mail_editor_replyall_headernames"] copy];
  }
  
  addr = nil;
  self->flags.isReply = 1;
  fields = [ReplyAllArray objectEnumerator];
  obj    = [[self session] getTransferObject];
  part   = [obj message];

  while ((o = [fields nextObject])) {
    NSEnumerator *values;
    id           value;
    
    addr = [NSMutableArray arrayWithCapacity:64];
      
    values = [part valuesOfHeaderFieldWithName:o];
    while ((value = [values nextObject]))
      [addr addObject:value];
    
    [self _buildReplyHeader:obj to:addr h:o];
  }

  if ((from = [obj valueForKey:@"reply-to"]) == nil)
    from = [obj valueForKey:@"sender"];
  
  [self _setBodyForReply:obj from:from part:part];
}

- (void)_prepareForReply {
  NSString       *from;
  NGImap4Message *obj;
  
  self->flags.isReply = 1;
  
  /* obj apparently is an NGImap4Message */
  obj = [[self session] getTransferObject];
  
  if ((from = [[obj valueForKey:@"reply-to"] stringValue]) == nil)
    from = [obj valueForKey:@"sender"];
  
  [self _buildReplyHeader:obj to:(from ? [NSArray arrayWithObject:from] : nil) 
        h:nil];
  [self _setBodyForReply:obj from:from part:nil];
}

- (void)_prepareForForward {
  NSString *from;
  NSString *s = nil;
  id obj;

  self->flags.isForward = 1;
  obj  = [[self session] getTransferObject];
  from = [obj valueForKey:@"sender"];
  
  if ((s = [[obj valueForKey:@"subject"] stringValue]))
    [self setMailSubject:[@"Fwd: " stringByAppendingString:s]];
  
  [self _setBodyForForward:obj from:from];
}

- (void)_prepareForEditAsNew {
  id            tmp, obj;
  NSEnumerator  *enumerator;
  NGMimeMessage *message;
  NSString *ty;
    
  obj     = [[self session] getTransferObject];
  message = (NGMimeMessage *)[obj message];

  if ((tmp = [obj valueForKey:@"subject"]))
    [self setMailSubject:tmp];

  enumerator = [message valuesOfHeaderFieldWithName:@"to"];
  while ((tmp = [enumerator nextObject])) {
    NSEnumerator        *addrs;
    NGMailAddressParser *parser;
    NGMailAddress       *addr;

    parser = [NGMailAddressParser mailAddressParserWithString:
                                    [tmp stringByDecodingQuotedPrintable]];
    addrs  = [[parser parseAddressList] objectEnumerator];

    while ((addr = [addrs nextObject]))
      [self addReceiver:[addr address] type:@"to"];
  }
  enumerator = [message valuesOfHeaderFieldWithName:@"cc"];
  while ((tmp = [enumerator nextObject])) {
    NSEnumerator        *addrs;
    NGMailAddressParser *parser;
    NGMailAddress       *addr;

    parser = [NGMailAddressParser mailAddressParserWithString:
                                    [tmp stringByDecodingQuotedPrintable]];
    addrs  = [[parser parseAddressList] objectEnumerator];

    while ((addr = [addrs nextObject]))
      [self addReceiver:[addr address] type:@"cc"];
  }

  if ((tmp = [message contentType]) == nil)
    return;
  
  ty = [(NGMimeContentDispositionHeaderField *)tmp type];
      
  if ([ty isEqualToString:@"text"]) {
    [self _buildEditAsNewForText:message type:tmp];
    return;
  }
  
  if ([ty isEqualToString:@"multipart"]) {
    BOOL hasBody;
    id   p;

    enumerator = [[[message body] parts] objectEnumerator];
    hasBody    = NO;
        
    while ((p = [enumerator nextObject])) {
      NGMimeType *t = nil;

      if ((t = [p contentType]) == nil)
	continue;
	
      if (!hasBody && [t isTextPlainType]) {
	[self _buildEditAsNewForText:p type:t];
	hasBody = YES;
      }
      else
	[self addMimePart:p];
    }
  }
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  self->flags.isReply   = 0;
  self->flags.isForward = 0;
  
  if ([_command hasPrefix:@"reply-all"])
    [self _prepareForReplyAll];
  else if ([_command hasPrefix:@"reply"])
    [self _prepareForReply];
  else if ([_command hasPrefix:@"forward"])
    [self _prepareForForward];
  else if ([_command hasPrefix:@"edit-as-new"]) {
    [self _prepareForEditAsNew];
    return YES;
  }
  
  [self setContentWithoutSign:self->mailText];
  return YES;
}

@end /* LSWImapMailEditor(Activation) */
