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
// $Id: SxDavAptAction.m 1 2004-08-20 11:17:52Z znek $

#include "SxDavAptAction.h"
#include "SxAppointment.h"
#include "common.h"
#include <Frontend/NSString+csv.h>
#include <Frontend/NSObject+ExValues.h>
#include <Backend/NSString+rtf.h>

@implementation SxDavAptAction

static int createGroupAptsInGroupFolder = -1;

+ (void)initialize {
  NSUserDefaults *ud;
 
  ud = [NSUserDefaults standardUserDefaults];

  createGroupAptsInGroupFolder =
    [ud boolForKey:@"ZLCreateGroupAppointmentsInGroupFolders"];
}

- (id)initWithName:(NSString *)_name properties:(NSDictionary *)_props
  forAppointment:(SxAppointment *)_apt
{
  return [self initWithName:_name properties:_props forObject:_apt];
}

/* accessors */

- (NSString *)expectedMessageClass {
  return @"IPM.Appointment";
}
- (SxAppointment *)appointment {
  return (SxAppointment *)self->object;
}

- (id)fbTypeForBusyStatus:(NSNumber *)_busy {
  unsigned busy = [_busy intValue];

  if (busy == 1) return @"BUSY-TENTATIVE";
  if (busy == 2) return @"BUSY";
  if (busy == 3) return @"BUSY-UNAVAILABLE";
  
  return @"FREE";
}


/* process */

- (NSString *)accessClassForDavProp:(id)_sens {
  /*
   * 0 - Normal       (PUBLIC)   
   * 1 - Personal
   * 2 - Privat       (PRIVATE)
   * 3 - Confidentail (CONFIDENTIAL)
   */
  int val = [_sens intValue];
  if (val == 2)
    return @"PRIVATE";
  else if (val == 3)
    return @"CONFIDENTIAL";
  return @"PUBLIC";
}

- (NSString *)roleStringForValue:(id)_val {
  unsigned val = [_val intValue];

  if (val == 0) return @"";
  if (val == 1) return @"REQ-PARTICIPANT";
  if (val == 2) return @"OPT-PARTICIPANT";

  [self logWithFormat:@"[roleStringForValue] unknown role: %@", _val];

  return @"";
}

- (NSString *)stateStringForValue:(id)_val {
  unsigned val = [_val intValue];

  if (val == 0) return @"NEEDS-ACTION";
  if (val == 2) return @"TENTATIVE";
  if (val == 3) return @"ACCEPTED";
  if (val == 4) return @"DECLINED";

  [self logWithFormat:@"[stateStringForValue] unknown state: %@", _val];

  return @"NEEDS-ACTION";
}

/* common processors */

- (NSArray *)parseRecipientsCSV:(NSString *)_csv {
  /*
   * format:
   *  'display','SMTP','email','role-value','???? some hash stuff'
   *
   */
  static NSArray *columnTitles = nil;  
  
  NSArray      *lines;
  NSEnumerator *e;
  id           tmp;
  NSArray      *columns;
  unsigned     i, max;
  NSString     *key;
  
  NSMutableArray      *recipients;
  NSMutableDictionary *recipient;

  if (columnTitles == nil)
    columnTitles =
      [[NSArray alloc] initWithObjects:
                       @"cn",
                       @"emailType",
                       @"email",
                       @"role",
                       @"emailStruct",
                       @"flags",
                       @"partStat",
                       nil];
  
  lines = [_csv parsedCSV];

  if (!(max = [lines count])) {
    return [NSArray array];
  }
  
  recipients = [NSMutableArray arrayWithCapacity:max];
  e          = [lines objectEnumerator];
  
  while ((columns = [e nextObject])) {
    if ((max = [columns count])) {
      if (max > 7) {
        [self logWithFormat:@"error parsing recipients-csv: "
              @"too much columns: %@", columns];
        max = 7;
      }
      recipient = [NSMutableDictionary dictionaryWithCapacity:7];
      for (i = 0; i < max; i++) {
        tmp = [columns objectAtIndex:i];
        key = [columnTitles objectAtIndex:i];
        
        if ([key isEqualToString:@"role"]) {
          tmp = [self roleStringForValue:tmp];
        }
        
        else if ([key isEqualToString:@"email"]) {
          if (![[recipient objectForKey:@"emailType"] isEqualToString:@"SMTP"])
            // only accept email addresses
            tmp = nil;
        }
        
        else if ([key isEqualToString:@"cn"]) {
          if ([tmp hasSuffix:@" (E-Mail)"])
            tmp = [tmp substringToIndex:[tmp length]-9];
          else if ([tmp hasSuffix:@" (E-Mail)"])
            tmp = [tmp substringToIndex:[tmp length]-8];
        }

        else if ([key isEqualToString:@"partStat"]) {
          tmp = [self stateStringForValue:tmp];
        }

        if ((tmp) && ([tmp length]))
          [recipient setObject:tmp forKey:key];
      }
      if ([recipient count])
        [recipients addObject:recipient];
    }
  }

  return recipients;
}

- (NSException *)addParticipantsInContext:(id)_ctx {
  NSMutableArray *parts;
  id             tmp;
  id             cmdctx;
  
  if ((cmdctx = [[self appointment] commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: did not find command context ..."];
    return [NSException exceptionWithHTTPStatus:500];
  }

  parts = [NSMutableArray array];

  tmp =
    [self parseRecipientsCSV:[self->props objectForKey:@"zlRecipientsCSV"]];

  tmp = [[self appointment] fetchParticipantsForPersons:tmp
                            inContext:_ctx];

  if ([tmp count])
    [parts addObjectsFromArray:tmp];

  [[self appointment] reloadObjectInContext:_ctx];

  // in overview folders add current team / account
  if ([[self appointment] isInOverviewFolder]) {
    NSArray *cIds;    
    id team;
    cIds = [parts valueForKey:@"companyId"];
    if ((team = [[self appointment] groupInContext:_ctx])) {
      if (![cIds containsObject:[team valueForKey:@"companyId"]])
        [parts addObject:team];
    }
    else {
      id account;
      account = [cmdctx valueForKey:LSAccountKey];
      if (![cIds containsObject:[account valueForKey:@"companyId"]])
        [parts addObject:account];
    }
  }

  if (![[self appointment] isNew]) {
    NSArray *oldParts;

    oldParts = [[[self appointment] objectInContext:_ctx]
                       valueForKey:@"participants"];
    parts    = (NSMutableArray *)[[self appointment]
                                        checkChangedParticipants:parts
                                        forOldParticipants:oldParts
                                        inContext:_ctx];
  }
  else if ([parts count] == 0) {
    id team, loginId;
    
    if ((createGroupAptsInGroupFolder) &&
        ((team = [[self appointment] groupInContext:_ctx]))) {
      parts = [NSArray arrayWithObject:team];
    }
    else if ((loginId = [cmdctx valueForKey:LSAccountKey]) != nil) {
      parts = [[[NSArray alloc] initWithObjects:&loginId count:1] autorelease];
    }
    else {
      [self logWithFormat:@"ERROR did not find login in command context: %@",
            cmdctx];
      return [NSException exceptionWithHTTPStatus:403 /* forbidden */
                          reason:@"user is not logged in"];
    }
  }

  if (parts) {
    [self->changeSet setObject:parts forKey:@"participants"];
  }

  [self->keys removeObject:@"zlRecipientsCSV"];
  
  return nil /* nil says OK */;
}

- (NSException *)processReminderInContext:(id)_ctx {
  /*
   * outlook transmittes
   * cdoReminderMinutes and cdoReminderSet
   *
   * reminder is set when cdoReminderSet == 1
   *
   * save as csv in column olReminder
   * format:
   * reminderSet,minutes,soundSet,playSound,'soundFile'
   *
   */


  // TODO: handle additional info, like reminder audio file
  id       reminderSet;
  id       reminderMin;
  id       soundSet;
  NSString *csv;
  NSString *soundFile;
  id       playSound;

  reminderMin = [self->props objectForKey:@"cdoReminderMinutes"];
  reminderSet = [self->props objectForKey:@"cdoReminderSet"];
  soundSet    = [self->props objectForKey:@"cdoReminderSoundSet"];
  soundFile   = [self->props objectForKey:@"cdoReminderSoundfile"];
  playSound   = [self->props objectForKey:@"cdoReminderPlaySound"];

  if (reminderSet == nil)      reminderSet = @"0";
  if (![reminderSet intValue]) reminderMin = [NSNumber numberWithInt:0];
  if (soundSet  == nil)        soundSet    = @"0";
  if (soundFile == nil)        soundFile   = @"";
  if (playSound == nil)        playSound   = @"0";

  csv = [[NSArray arrayWithObjects:
                  reminderSet,
                  reminderMin,
                  soundSet,
                  playSound,
                  soundFile,
                  nil] csvString];

  [self->changeSet setObject:csv forKey:@"olReminder"];

  [self->keys removeObject:@"cdoReminderSet"];
  [self->keys removeObject:@"cdoReminderMinutes"];
  [self->keys removeObject:@"cdoReminderSoundSet"];
  [self->keys removeObject:@"cdoReminderSoundfile"];
  [self->keys removeObject:@"cdoReminderPlaySound"];

  return nil; /* nil says OK */
}

- (NSException *)processOnlineMeetingInContext:(id)_ctx {
  /*
   * save outlook online meeting values as csv:
   * format:
   *
   * meetingSet,meetingType,netMeetingServer,netMeetingEmail, \
   * meetingReminder,netMeetingFile,netShowAddress
   *
   *
   */
  id meetingSet;
  id meetingType;
  id netMeetingServer;
  id netMeetingEmail;
  id meetingReminder;
  id netMeetingFile;
  id netShowAddress;

  NSString *csv;

  meetingSet  = [self->props objectForKey:@"onlineMeetingSet"];
  meetingType = [self->props objectForKey:@"onlineMeetingType"];
  netMeetingServer = [self->props objectForKey:@"netMeetingDirectoryServer"];
  netMeetingEmail  = [self->props objectForKey:@"netMeetingEmailPlanning"];
  meetingReminder  = [self->props objectForKey:@"onlineMeetingReminder"];
  netMeetingFile   = [self->props objectForKey:@"netMeetingOfficeFile"];
  netShowAddress   = [self->props objectForKey:@"netShowAddress"];

  if (meetingSet == nil)       meetingSet  = @"0"; // not selected
  if (meetingType == nil)      meetingType = @"0"; // netMeeting
  if (netMeetingServer == nil) netMeetingServer = @"";
  if (netMeetingEmail  == nil) netMeetingEmail  = @"";
  if (meetingReminder  == nil) meetingReminder  = @"0"; // no reminder
  if (netMeetingFile   == nil) netMeetingFile   = @"";
  if (netShowAddress   == nil) netShowAddress   = @"";

  csv = [[NSArray arrayWithObjects:
                  meetingSet,
                  meetingType,
                  netMeetingServer,
                  netMeetingEmail,
                  meetingReminder,
                  netMeetingFile,
                  netShowAddress,
                  nil] csvString];

  [self->changeSet setObject:csv forKey:@"onlineMeeting"];
  
  [self->keys removeObject:@"onlineMeetingSet"];
  [self->keys removeObject:@"onlineMeetingType"];
  [self->keys removeObject:@"netMeetingDirectoryServer"];
  [self->keys removeObject:@"netMeetingEmailPlanning"];
  [self->keys removeObject:@"onlineMeetingReminder"];
  [self->keys removeObject:@"netMeetingOfficeFile"];
  [self->keys removeObject:@"netShowAddress"];

  return nil; /* nil says OK */
}

- (NSException *)processTitleInContext:(id)_ctx {
  /* 
     ZideLook transmits the UID in the display name !, eg
       55E8174C-5C143947-AA16EDAA-6912D031 
     so we use plain old subject.

     processes: davDisplayName, subject, subjectPrefix, threadTopic
  */
  NSString *s, *sp, *tt;
  
  s  = [self->props objectForKey:@"subject"];
  sp = [self->props objectForKey:@"subjectPrefix"];
  tt = [self->props objectForKey:@"threadTopic"];
  
  if ([s hasPrefix:tt]) tt = nil;
  if ([tt length] == 0) tt = nil;
  
  if ([sp length] > 0) 
    s = s ? [sp stringByAppendingString:s] : sp;

  if (s == nil) {
    s = tt;
    tt = nil;
  }
  
  if (tt) {
    [self logWithFormat:
            @"threadTopic is different from subject ? '%@' vs '%@'",
            s, tt];
  }
  if (s == nil) {
    [self logWithFormat:@"WARNING: got no appointment title !"];
    s = @"Appointment";
  }
  
  [self->changeSet setObject:s forKey:@"title"];
  
  [self->keys removeObject:@"davDisplayName"];
  [self->keys removeObject:@"subject"];
  [self->keys removeObject:@"subjectPrefix"];
  [self->keys removeObject:@"threadTopic"];
  
  return nil /* nil says OK */;
}

- (NSException *)processAppointmentRangeInContext:(id)_ctx {
  /* processes: startDate, endDate, duration, startDate2, endDate2 */
  NSCalendarDate *startDate = nil, *endDate = nil, *cycleEndDate = nil;
  NSString       *start, *end, *cycle;
  int            duration;
  
  start    = [self->props objectForKey:@"startDate"];
  end      = [self->props objectForKey:@"endDate"];
  cycle    = [self->props objectForKey:@"endDate2"];
  duration = [[self->props objectForKey:@"duration"] intValue];
  
  if ([start length] == 0) start = [self->props objectForKey:@"startDate2"];
  if ([end   length] == 0) end   = [self->props objectForKey:@"endDate2"];
  if (duration == 0) 
    duration = [[self->props objectForKey:@"cdoDuration"] intValue];

  if ([start length] > 0) {
    if ((startDate = [NSDate dateWithExDavString:start]) == nil) {
      [self logWithFormat:@"could not parse start date '%@'!", start];
      return [NSException exceptionWithHTTPStatus:400 /* bad request */
                          reason:@"could not parse start date of appointment"];
      
    }
    if ((endDate = [NSDate dateWithExDavString:end]) == nil) {
      if (duration == 0) {
        [self logWithFormat:@"WARNING: missing duration or start-date?"];
        duration = 1;
      }
      endDate = [startDate dateByAddingYears:0 months:0 days:0
                           hours:0 minutes:duration seconds:0];
    }
  }
  else if ([end length] > 0) {
    if ((endDate = [NSDate dateWithExDavString:end]) == nil) {
      [self logWithFormat:@"ERROR: could not parse end date '%@'!", end];
      return [NSException exceptionWithHTTPStatus:400 /* bad request */
                          reason:@"could not parse end date of appointment"];
      
    }
    if (duration == 0) {
      [self logWithFormat:@"WARNING: missing duration or start-date?"];
      duration = 1;
    }
    startDate = [endDate dateByAddingYears:0 months:0 days:0
                         hours:0 minutes:(-duration) seconds:0];
  }
  else {
    [self logWithFormat:@"no appointment time info available !"];
    return [NSException exceptionWithHTTPStatus:400 /* bad request */
                        reason:@"missing time attributes of appointment"];
  }

  if ([cycle length] > 0) {
    int cycleEndYear;

    cycleEndYear = [[cycle substringWithRange:NSMakeRange(0,4)] intValue];

    if (cycleEndYear > 2300) {
      NSLog(@"Invalid cycle end year detected!");
      cycleEndDate = [[[NSCalendarDate alloc] initWithYear:2037 month:12 day:31
                                      hour:18 minute:0 second:0
                                      timeZone:
                                      [NSTimeZone timeZoneWithAbbreviation:
                                                 @"GMT"]] autorelease];
    }
    else {
      if ((cycleEndDate = [NSDate dateWithExDavString:cycle]) == nil) {
        [self logWithFormat:@"ERROR: could not parse cycle date '%@' !", 
                cycle];
        return [NSException exceptionWithHTTPStatus:400 /* bad request */
                            reason:
                            @"could not parse cycle end date of appointment"];
      }
    }
  }
  
#if 1
  if ([[self->props objectForKey:@"cdoAllDayEvent"] boolValue]) {
    // set enddate to 23:59:59
    endDate = [endDate dateByAddingYears:0 months:0 days:0
                       hours:0 minutes:0 seconds:-1];
  }
#endif
  
  if (startDate) [self->changeSet setObject:startDate forKey:@"startDate"];
  if (endDate)   [self->changeSet setObject:endDate   forKey:@"endDate"];
  if (cycleEndDate) [self->changeSet setObject:cycleEndDate
                         forKey:@"cycleEndDate"];
  
  [self logWithFormat:@"apt range: %@ to %@ (%i)", 
          startDate, endDate, duration];
  
  [self->keys removeObject:@"startDate"];
  [self->keys removeObject:@"startDate2"];
  [self->keys removeObject:@"endDate"];
  [self->keys removeObject:@"endDate2"];
  [self->keys removeObject:@"duration"];
  [self->keys removeObject:@"cdoDuration"];
  [self->keys removeObject:@"cdoAllDayEvent"];
  return nil;
}

- (NSException *)processAssociatedContactsInContext:(id)_ctx {
  id contacts;

  contacts = [self->props valueForKey:@"associatedContacts"];
  if (contacts)
    [self->changeSet setObject:contacts forKey:@"associatedContacts"];

  [self->keys removeObject:@"associatedContacts"];
  [self->keys removeObject:@"associatedContacts1"];
  
  return nil;
}

- (NSException *)processKeywordsInContext:(id)_ctx {
  id keywords;

  keywords = [self->props valueForKey:@"Keywords"];
  if (keywords)
    [self->changeSet setObject:keywords forKey:@"keywords"];

  [self->keys removeObject:@"Keywords"];
  
  return nil;
}

- (NSException *)processFBTypeInContext:(id)_ctx {
  id fb;

  fb = [self->props valueForKey:@"cdoBusyStatus"];
  if (fb) {
    [self->changeSet setObject:fb forKey:@"busyType"];
    [self->changeSet setObject:[self fbTypeForBusyStatus:fb]
         forKey:@"fbtype"];
  }

  [self->keys removeObject:@"cdoBusyStatus"];
  
  return nil;
}

@end /* SxDavAptAction */
