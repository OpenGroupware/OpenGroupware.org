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

#include "SxDavAptChange.h"
#include "SxAppointment.h"
#include "common.h"

#include <Backend/SxAptManager.h>

// TODO: title change does not work yet (duplicate dav-ids !)

/*
  Those keys are sent if a comment was entered:
  rtfSyncPrefixCount,
  rtfSyncTrailingCount,
  rtfSyncBodyCRC,
  rtfCompressed,
  rtfSyncBodyCount,
  rtfSyncBodyTag
*/

@implementation SxDavAptChange

static NSNumber *yesNum = nil;
static NSArray  *unusedKeys = nil;
static BOOL     logAppChange = NO;

+ (void)initialize {
  static BOOL didInit = NO;
  NSString     *p;
  NSDictionary *plist;
  if (didInit) return;
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];

  p = [[NSBundle mainBundle] pathForResource:@"DavAptChangeSets" 
                             ofType:@"plist"];
  if ((plist = [NSDictionary dictionaryWithContentsOfFile:p]) == nil)
    [self logWithFormat:@"could not load apt-change-sets: %@", p];
  
  unusedKeys = [[plist objectForKey:@"unused"] copy];
  logAppChange = [[NSUserDefaults standardUserDefaults]
                                  boolForKey:@"ZLAptLogChanges"];
  
  didInit = YES;
}

- (void)dealloc {
  [self->eo release];
  [super dealloc];
}

- (NSArray *)unusedKeys {
  return unusedKeys;
}

- (NSException *)runInContext:(id)_ctx {
  NSException *error;
  NSString    *log;
  id          tmp;
  
  [self->eo release];
  if ((self->eo = [[[self appointment] objectInContext:_ctx] retain]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* not found */
                        reason:@"did not find appointment for update"];
  }

  if (logAppChange)
    NSLog(@"%s: got properties: %@", __PRETTY_FUNCTION__, self->props);
  
  [self removeUnusedKeys];
  
  if (![self checkMessageClass]) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"unexpected message class"];
  }
  
  if ((error = [self processTitleInContext:_ctx]))
    return error;
  if ((error = [self processAppointmentRangeInContext:_ctx]))
    return error;
  
  if ((tmp = [self->props objectForKey:@"rtfCompressed"])) {
    if ([tmp length] > 0) {
#if 0
      [self->changeSet setObject:[@"ZideLook rich-text compressed comment: "
                                   stringByAppendingString:tmp]
           forKey:@"comment"];
#else
      NSString *s;

      s = [[tmp stringByDecodingBase64] plainTextStringByDecodingRTF];

      if (![s length]) {
        s = [@"ZideLook rich-text compressed comment: "
              stringByAppendingString:tmp];
      }
      [self->changeSet setObject:s forKey:@"comment"];
#endif
      [self->keys removeObject:@"rtfCompressed"];
    }
  }
  
  if ((tmp = [self->props objectForKey:@"location"])) {
    [self->changeSet setObject:tmp forKey:@"location"];
    [self->keys removeObject:@"location"];
  }

  /* Note: do not add lastModified, cdoCreationTime - done by command */
  
  if ((tmp = [self->props objectForKey:@"importance"])) {
    [self->changeSet setObject:tmp forKey:@"importance"];
    [self->keys removeObject:@"importance"];
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

  // reload eo object
  [self->eo release];
  self->eo = [[[self appointment] objectInContext:_ctx] retain];

  if ((tmp = [[self appointment] pkeyOfGroupInContext:_ctx]))
    [self->changeSet setObject:tmp forKey:@"accessTeamId"];
  
  /* ignore conflicts TODO: add conflict panel in ZideLook */
  [self->changeSet setObject:yesNum forKey:@"isWarningIgnored"];
  
  /* add log */
  [self logRemainingKeys];
  
  /* perform add */
  
  log = [NSString stringWithFormat:
                    @"changed by ZideStore (changed=%@,lost=%@)",
		    [[self->changeSet allKeys] componentsJoinedByString:@","],
		    [self->keys componentsJoinedByString:@","]];

  error = [[[self appointment]
                  aptManagerInContext:_ctx]
                  updateRecordWithPrimaryKey:[[self appointment] primaryKey]
                  withEOChanges:changeSet
                  log:log];
  
  if ([error isKindOfClass:[NSException class]]) {
    [self logWithFormat:@"appointment change failed: %@", error];
    return error;
  }
  
  return nil; /* nil says, everything's OK */  
}

@end /* SxDavAptChange */
