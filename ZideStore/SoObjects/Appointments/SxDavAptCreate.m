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
// $Id: SxDavAptCreate.m 1 2004-08-20 11:17:52Z znek $

#include "SxDavAptCreate.h"
#include "SxAppointment.h"
#include "common.h"

#include <Backend/NSString+rtf.h>
#include <Backend/SxAptManager.h>
#include <NGExtensions/NGBase64Coding.h>

#include <math.h>

#define TYPE_DAILY    1
#define TYPE_WEEKLY   2
#define TYPE_MONTHLY  3
#define TYPE_YEARLY   4

@implementation SxDavAptCreate

static NSNumber *yesNum = nil;

+ (void)initialize {
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
}

- (NSArray *)unusedKeys {
  static NSArray *unusedKeys = nil;
  if (unusedKeys == nil) {
    unusedKeys = [[NSArray alloc] initWithObjects:
                                    @"alternateRecipientAllowed",
                                    @"cdoAccess",
                                    @"cdoAccessLevel",
                                    @"cdoAction",
                                    @"cdoBody",
                                    @"cdoBusyStatus",
                                    @"cdoCreationTime",
                                    @"cdoDepth",
                                    @"cdoFlagDue",
                                    @"cdoFlagDueByNext",
                                    @"cdoMessageFlags",
                                    @"cdoMessageStatus",
                                    @"cdoPriority",
                                    @"cdoResponseStatus",
                                    @"cdoSearchKey",
                                    @"cdoStatus",
                                    @"clientSubmitTime",
                                    @"conversationIndex",
                                    @"deleteAfterSubmit",
                                    @"mapi0x3FDE_int",
                                    @"mapiTimeZoneInfo",
                                    @"messageDeliveryTime",
                                    @"messageSize",
                                    @"normalizedSubject",
                                    @"originatorDeliveryReportRequested",
                                    @"outlookVersion",
                                    @"readReceiptRequested",
                                    @"replyRequested",
                                    @"responseRequested",
                                    @"rtfCompressed",
                                    @"rtfInSync",
                                    @"rtfSyncBodyCRC",
                                    @"rtfSyncBodyCount",
                                    @"rtfSyncBodyTag",
                                    @"rtfSyncPrefixCount",
                                    @"rtfSyncTrailingCount",
                                    @"senderAddrType",
                                    @"senderEmailAddress",
                                    @"senderName",
                                    @"sentRepresentingAddrType",
                                    @"sentRepresentingEmailAddress",
                                    @"sentRepresentingName",
                                    @"zlGenerationCount",
                                  nil];
  }
  return unusedKeys;
}

- (void)decodeRecurrenceState:(NSString *)_base64String forType:(int)_type {
  NSData        *data;
  const char    *bytes;
  unsigned char c;
  int           pos = 0, days = 0, weekdays = 0, length = 0, weeks = 0;
  NSString      *type;

  if ([_base64String length] == 0)
    return;
  
  switch (_type) {
    case TYPE_DAILY:   type = @"daily"; break;
    case TYPE_WEEKLY:  type = @"weekly"; break;
    case TYPE_MONTHLY: type = @"monthly"; break;
    case TYPE_YEARLY:  type = @"yearly"; break;
    default: 
      [self logWithFormat:@"Invalid recurrence value"]; 
      break;
  }
  
  data   = [_base64String dataUsingEncoding:NSUTF8StringEncoding];
  data   = [data dataByDecodingBase64];
  length = [data length];
  bytes  = (const char *)[data bytes];

  while (length--) {
    c = *bytes;

    switch (pos) {
      case 14: weeks    = c;     break;
      case 15: days     = c;     break;
      case 16: days    += c*256; break;
      case 22: weekdays = c;     break;
      default: break;
    }
    bytes++; pos++;
  }

  // divide by the magical number 5.625 (found through testing)
  days = rint(days / 5.625);

  switch (days) {
    case 1:   type = @"daily";    break;
    case 7:   type = @"weekly";   break;
    case 14:  type = @"14_daily"; break;
    case 28:  type = @"4_weekly"; break;
    case 30:  type = @"monthly";  break;
    case 365: type = @"yearly";   break;
    default: {
      [self logWithFormat:@"unsupported recurrence day range: %i", days];
      type = nil;
      break;
    }
  }
  
  // weekdays are encoded in a bitmask -> SSFTWTM0
  //                                      00111110 -> 62
  if (_type == TYPE_DAILY && weekdays == 62) type = @"weekday";
  if (_type == TYPE_WEEKLY && weeks == 4)    type = @"4_weekly";
  
  if (type != nil)
    [self->changeSet setObject:type forKey:@"type"];
}

- (id)runInContext:(id)_ctx {
  NSException *error;
  id          tmp;

  [self removeUnusedKeys];
  
  if (![self checkMessageClass]) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"unexpected message class"];
  }
  
  if ((error = [self processTitleInContext:_ctx]))
    return error;
  if ((error = [self processAppointmentRangeInContext:_ctx]))
    return error;
  
  if ((tmp = [self->props objectForKey:@"location"])) {
    [self->changeSet setObject:tmp forKey:@"location"];
    [self->keys removeObject:@"location"];
  }
  
  tmp = [self->props objectForKey:@"cdoIsRecurring"];
  if (tmp) {
    NSString *state;
    int      rtype;
    
    state = [self->props objectForKey:@"cdoRecurrenceState"];
    rtype = [[self->props objectForKey:@"cdoRecurrenceType"] intValue];
    [self decodeRecurrenceState:state forType:rtype];
    [self->keys removeObject:@"cdoIsRecurring"];
    [self->keys removeObject:@"cdoRecurrenceState"];
    [self->keys removeObject:@"cdoRecurrenceType"];
  }

  /* Note: do not add lastModified, cdoCreationTime - done by command */
  
  if ((tmp = [self->props objectForKey:@"importance"])) {
    [self->changeSet setObject:tmp forKey:@"importance"];
    [self->keys removeObject:@"importance"];
  }
  
  if ((tmp = [self->props objectForKey:@"rtfCompressed"])) {
    if ([tmp length]) {
      NSString *s;

      s = [[tmp stringByDecodingBase64] plainTextStringByDecodingRTF];

      if (![s length]) {
        s = [@"ZideLook rich-text compressed comment: "
              stringByAppendingString:tmp];
      }
      [self->changeSet setObject:s forKey:@"comment"];
      [self->keys removeObject:@"rtfCompressed"];
    }
  }
  if ((tmp = [self->props objectForKey:@"sensitivity"])) {
    [self->changeSet setObject:tmp forKey:@"sensitivity"];
    [self->keys removeObject:@"sensitivity"];
  }
  
  if ((error = [self addParticipantsInContext:_ctx]))           return error;  
  if ((error = [self processReminderInContext:_ctx]))           return error;
  if ((error = [self processOnlineMeetingInContext:_ctx]))      return error;
  if ((error = [self processAssociatedContactsInContext:_ctx])) return error;
  if ((error = [self processKeywordsInContext:_ctx]))           return error;
  if ((error = [self processFBTypeInContext:_ctx]))             return error;

  if ((tmp = [[self appointment] pkeyOfGroupInContext:_ctx])) 
    [self->changeSet setObject:tmp forKey:@"accessTeamId"];
  
  /* ignore conflicts TODO: add conflict panel in ZideLook */
  [self->changeSet setObject:yesNum forKey:@"isWarningIgnored"];
  
  /* add log */
  [self logRemainingKeys];
  
  error = [[[self appointment]
                  aptManagerInContext:_ctx]
                  createWithEOAttributes:self->changeSet 
                  log:[self createdLogText]];
  if ([error isKindOfClass:[NSException class]]) {
    [self logWithFormat:@"appointment creation failed: %@", error];
    return error;
  }
  
  if ((tmp = [error valueForKey:@"dateId"])) {
    [self logWithFormat:@"deliver new date-id: %@", tmp];
    [_ctx setObject:tmp forKey:@"SxNewObjectID"];
  }
  else
    [self logWithFormat:@"ERROR: missing dateId !"];
  
  return nil; /* nil says, everything's OK */  
}

@end /* SxDavAptCreate */
