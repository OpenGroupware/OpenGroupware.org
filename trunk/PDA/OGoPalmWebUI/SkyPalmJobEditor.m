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

#include <OGoPalmUI/SkyPalmEntryEditor.h>

@interface SkyPalmJobEditor : SkyPalmEntryEditor
{
@private
  NSString *duedate;
  BOOL     hasDuedate;
}

- (void)setDuedate:(NSString *)_date;
- (id)job;

@end

#include "common.h"
#include <OGoPalm/SkyPalmJobDocument.h>

@interface NSObject(SkyPalmJobEditorMethods)
- (id)resourceManager;
@end

@implementation SkyPalmJobEditor

- (void)dealloc {
  [self->duedate release];
  [super dealloc];
}

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id obj;

  obj = [self snapshot];
  self->hasDuedate = ([obj duedate] == nil) ? NO : YES;

  if (self->hasDuedate)
    [self setDuedate:[[obj duedate]
                           descriptionWithCalendarFormat:@"%Y-%m-%d"]];
  return YES;
}

/* accessors */

- (id)job {
  return [self snapshot];
}

- (void)setHasDuedate:(BOOL)_flag {
  self->hasDuedate = _flag;
}
- (BOOL)hasDuedate {
  return self->hasDuedate;
}

- (void)setDuedate:(NSString *)_date {
  ASSIGN(self->duedate,_date);
}
- (NSString *)duedate {
  if (!self->hasDuedate)
    return [[NSCalendarDate date] descriptionWithCalendarFormat:@"%Y-%m-%d"];
  if (self->duedate == nil) {
    NSCalendarDate *ddate = [NSCalendarDate date];
    ddate = [ddate tomorrow];
    // setting tomorrow as duedate
    [self setDuedate:[ddate descriptionWithCalendarFormat:@"%Y-%m-%d"]];
  }
  return self->duedate;
}

// calendar support
- (NSString *)calendarPageURL {
  WOResourceManager *rm;
  NSString *url;
  
  rm = [(id)[WOApplication application] resourceManager];
  
  url = [rm urlForResourceNamed:@"calendar.html"
            inFramework:nil
            languages:[[self session] languages]
            request:[[self context] request]];
  
  if (url == nil) {
    [self debugWithFormat:@"couldn't locate calendar page"];
    url = @"/Skyrix.woa/WebServerResources/English.lproj/calendar.html";
  }

  return url;
}
- (NSString *)duedateOnClickEvent {
  return
    [NSString stringWithFormat:
              @"setDateField(document.editform.duedate);"
              @"top.newWin=window.open('%@','cal','WIDTH=208,HEIGHT=230')",
              [self calendarPageURL]];
}


// popup support

- (NSString *)priorityLabelKey {
  return [SkyPalmJobDocument priorityStringForPriority:[self->item intValue]];
}

// action support

- (BOOL)checkData {
  // check duedate
  if (self->hasDuedate) {
    NSCalendarDate *date;
    date = [NSCalendarDate dateWithString:self->duedate
                           calendarFormat:@"%Y-%m-%d"];
    if (date)
      date = [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                             month:[date monthOfYear]
                             day:[date dayOfMonth]
                             hour:12 minute:0 second:0
                             timeZone:
                             [NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [(SkyPalmJobDocument *)[self job] setDuedate:date];
  } else {
    [(SkyPalmJobDocument *)[self job] setDuedate:nil];
  }
  // check note
  [self checkStringForKey:@"description"];
  [self checkStringForKey:@"note"];

  {
    NSString *desc = [[self snapshot] valueForKey:@"description"];
    if ((desc == nil) || ([desc length] == 0)) {
      [self setErrorString:@"please fill description field"];
      return NO;
    }
  }
  
  return YES;
}

// actions
- (id)save {
  if (![self checkData])
    return nil;
  return [super save];
}

// overwriting
- (NSString *)palmDb {
  return @"ToDoDB";
}

@end
