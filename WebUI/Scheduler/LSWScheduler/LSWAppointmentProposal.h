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

#ifndef __LSWebInterface_LSWScheduler_LSWAppointmentProposal_H__
#define __LSWebInterface_LSWScheduler_LSWAppointmentProposal_H__

#include <OGoFoundation/LSWContentPage.h>

@class NSCalendarDate, NSNumber, NSMutableSet, NSArray, NSMutableArray;

@interface LSWAppointmentProposal : LSWContentPage
{
@private
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  int earliestStartTime;
  int latestFinishTime;
  
  id  appointment;
  id  item;
  id  dayItem;
  int idx;
  int itemIdx;
  int interval; /* in minutes */
  int duration; /* in minutes */

  NSArray *searchList;
  id      editor;

  NSMutableArray *minuteCaptionList;
  NSArray        *hourCaptionList;
  
  NSMutableArray *allDayHours;

  NSDictionary *sortedDates;

  NSDictionary *calculatedTable;
  id           calcItem;
  BOOL         hasSearched;

  NSMutableArray *resources;
  NSMutableSet   *addedResources;
  id             resource;
  int            resourceIndex;


  NSMutableArray *participants;
  NSMutableArray *selectedParticipants;
  
  NSMutableArray *resultList;
  NSMutableArray *removedParticipants;  
  NSMutableArray *enterprise;
  id             searchTeam;
  NSString       *searchText;
  NSMutableArray *addedParticipants;

  BOOL addedResourcesWasSet;
  BOOL showExtended;  
}
@end
#endif /* __LSWebInterface_LSWScheduler_LSWAppointmentProposal_H__ */
