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

#include <OGoFoundation/OGoContentPage.h>
#include <LSFoundation/LSCommandContext.h>
// TODO: this component s**** big time. We should have at least an object
//       representing the defaults to separate that from the controller
// TODO: split up in sections?!
// TODO: this is awkward in general and should be handled in a declarative way?

@class NSUserDefaults, NSString, NSArray, NSMutableArray, NSMutableDictionary;

@interface LSWSchedulerPreferences : OGoContentPage
{
  id             account;
  id             item;
  NSUserDefaults *defaults;
  NSString       *schedulerView;
  NSString       *appointmentView;
  NSString       *timeInputType;
  NSString       *aptTypeInputType;
//###ADDED BY AO###
  NSString       *rdvTypeInputType;
  NSString       *absenceMode;
  NSString       *noOfCols;
  int            startHour;
  int            endHour;
  int            columnsPerDayWeekView;
  int            columnsPerDayDayView;
  int            dayOverviewStartHour;
  int            dayOverviewEndHour;
  int            dayOverviewInterval;
  BOOL           isTemplateDateFormatEditable;
  BOOL           isMailTemplateEditable;
  BOOL           isAppointmentViewEditable;
  BOOL           isSchedulerViewEditable;
  BOOL           isStartHourEditable;
  BOOL           isEndHourEditable;
  BOOL           isColumnsPerDayWeekViewEditable;
  BOOL           isColumnsPerDayDayViewEditable;
  BOOL           isDayOverviewStartHourEditable;
  BOOL           isDayOverviewEndHourEditable;
  BOOL           isDayOverviewIntervalEditable;
  BOOL           isTimeInputTypeEditable;
  BOOL           isAptTypeInputTypeEditable;
  BOOL           isAbsenceModeEditable;
  BOOL           isNoOfColsEditable;
  BOOL           isRoot;
  BOOL           isSchedulerClassicEnabled;
  BOOL           shortInfo;
  BOOL           withResources;
  BOOL           hideIgnoreConflicts;
  NSString       *defaultCCForNotificationMails;
  BOOL           attachAppointments;

  NSMutableArray *participants;
  NSArray        *selectedParticipants;
  NSMutableArray *writeAccess;
  NSArray        *selectedWriteAccess;
  //######READ#####
//###ADDED BY AO###
  NSMutableArray *readAccess;
  NSArray        *selectedReadAccess;
  //#####DELEGATION#######
  NSMutableArray *delegRdvPriv;
  NSArray        *selectedDelegRdvPriv;
  NSMutableArray *delegRdvConf;
  NSArray        *selectedDelegRdvConf;
  NSMutableArray *delegRdvPubli;
  NSArray        *selectedDelegRdvPubli;
  NSMutableArray *delegRdvNorm;
  NSArray        *selectedDelegRdvNorm;
  
  //#####################
  NSArray        *resourceNames;
  NSArray        *minutes;
  NSDictionary   *labelsForMinutes;
  int            additionalPopupEntries;

  NSMutableDictionary *holidayGroups;
  NSArray             *holidayGroupsKeys;
  NSMutableDictionary *restHolidays;
  NSArray             *schoolHolidayKeys;
  NSArray             *restHolidaysKeys;
  NSString            *holiday;
  NSString            *customHolidays;
  NSString            *mailTemplate;
  NSString            *templateDateFormat;

  BOOL           isNotificationDevicesEditable;
  NSArray        *notificationDevices;
  NSArray        *availableNotificationDevices;
  
  NSString       *schedulerPageTab;
  NSString       *schedulerPageWeekView;
  NSString       *schedulerPageDayView;

  BOOL           showTodos;     // show todos in scheduler views
  BOOL           showPalmDates; // show palm dates
  BOOL           showFullNames;//try to show first and last name in date cells
}

- (void)setItem:(id)_item;
- (id)item;

@end

#include <OGoFoundation/LSWNotifications.h>
#include "common.h"

@interface NSObject(Private)
- (id)commandContext;
@end

#include <OGoScheduler/SkyHolidayCalculator.h>

@implementation LSWSchedulerPreferences

static BOOL     hasLSWSchedulerPage = NO;
static NSNumber *noNum = nil;

//###ADDED BY AO###
static NSArray  *personAttrNames = nil;
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  personAttrNames = [[ud arrayForKey:@"schedulerselect_personfetchkeys"] copy];
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];

  hasLSWSchedulerPage = [bm bundleProvidingResource:@"LSWSchedulerPage"
			    ofType:@"WOComponents"] ? YES : NO;

  if (noNum == nil) noNum = [[NSNumber numberWithBool:NO] retain];
}

- (id)init {
  if ((self = [super init])) {
    int                 cnt;
    NSMutableArray      *ma;
    NSMutableDictionary *md;
    
    self->isSchedulerClassicEnabled = hasLSWSchedulerPage;

    // TODO: maybe move to an own object?
    ma = [[NSMutableArray alloc] initWithCapacity:16];
    md = [[NSMutableDictionary alloc] initWithCapacity:24];
    for (cnt = 0; cnt < 1440; cnt+=60) {
      NSNumber *k;
      NSString *s;
      char buf[16];
	
      k = [NSNumber numberWithInt:cnt];
      [ma addObject:k];
      sprintf(buf, "%02i:%02i", (cnt / 60), (cnt % 60));
      s = [[NSString alloc] initWithCString:buf];
      [md setObject:s forKey:k];
      [s release];
    }
    ASSIGN(self->minutes,          ma);
    ASSIGN(self->labelsForMinutes, md);
    [ma release]; ma = nil;
    [md release]; md = nil;
    
    self->availableNotificationDevices = nil;
  }
  return self;
}

- (void)dealloc {
  [self->mailTemplate                  release];
  [self->templateDateFormat            release];
  [self->schedulerView                 release];
  [self->appointmentView               release];
  [self->absenceMode                   release];
  [self->noOfCols                      release];
  [self->timeInputType                 release];
  [self->aptTypeInputType              release];
  [self->item                          release];
  [self->account                       release];
  [self->defaults                      release];
  [self->defaultCCForNotificationMails release];
  [self->participants                  release];
  [self->selectedParticipants          release];
  [self->writeAccess                   release];
  [self->selectedWriteAccess           release];
//###ADDED BY AO###
  [self->readAccess		       release];
  [self->selectedReadAccess            release];
  [self->delegRdvPriv		       release];
  [self->selectedDelegRdvPriv          release];
  [self->delegRdvPubli		       release];
  [self->selectedDelegRdvPubli         release];
  [self->delegRdvConf		       release];
  [self->selectedDelegRdvConf          release];
  [self->delegRdvNorm		       release];
  [self->selectedDelegRdvNorm          release];
//###############
  [self->resourceNames                 release];
  [self->minutes                       release];
  [self->labelsForMinutes              release];
  [self->holidayGroups                 release];
  [self->holidayGroupsKeys             release];
  [self->restHolidays                  release];
  [self->restHolidaysKeys              release];
  [self->schoolHolidayKeys             release];
  [self->holiday                       release];
  [self->customHolidays                release];
  [self->notificationDevices           release];
  [self->availableNotificationDevices  release];
  [self->schedulerPageTab              release];
  [self->schedulerPageWeekView         release];
  [self->schedulerPageDayView          release];
  [super dealloc];
}

/* notifications */

- (void)awake {
  [super awake];
  self->isRoot = [[self session] activeAccountIsRoot];
}

- (void)sleep {
  [self setItem:nil];
  [[[self session] userDefaults] synchronize];
  [super sleep];
}

/* accessors */

- (BOOL)isEditorPage {
  return YES;
}

- (BOOL)_isEditable:(NSString *)_defName {
  id obj;

  _defName = [@"rootAccess" stringByAppendingString:_defName];
  obj = [self->defaults objectForKey:_defName];

  return obj ? [obj boolValue] : YES;
}

- (NSMutableArray *)_getGIDSforIds:(NSArray *)_ids 
  entityName:(NSString *)_entityName
{
  static NSArray *teamKeys = nil, *personKeys = nil;
  NSEnumerator *enumerator = nil;
  id           obj         = nil;
  NSArray      *tmp        = nil;
  EOEntity     *entity     = nil;
  id           *objs       = NULL;
  int          cnt         = 0;
  NSArray      *gids       = nil;
  NSString     *command;
  NSArray      *args       = nil;
  
  if (teamKeys == nil) {
    teamKeys = 
      [[NSArray alloc] initWithObjects:@"description", @"isTeam", nil];
  }
  if (personKeys == nil) {
    personKeys = [[NSArray alloc] initWithObjects:
				    @"name", @"firstname", @"isAccount",
				    @"login", nil];
  }

  command = [_entityName stringByAppendingString:@"::get-by-globalid"];
  
  if ([_entityName isEqualToString:@"Team"])
    args = teamKeys;
  else if ([_entityName isEqualToString:@"Person"])
    args = personKeys;
  else
    [self logWithFormat:@"ERROR: unknown entityName %@", _entityName];


  if (!((_ids != nil) && ([_ids count] > 0)))
    return [NSMutableArray arrayWithCapacity:1];
  
  entity = [[[(OGoSession *)[self session] commandContext]
	      valueForKey:LSDatabaseKey] entityNamed:_entityName];
  
  enumerator = [_ids objectEnumerator];
  objs       = calloc([_ids count] + 1, sizeof(id));
  while ((obj = [enumerator nextObject])) {
    static NSString *key = @"companyId";
    NSDictionary *pkeyRow;
    
    pkeyRow = [[NSDictionary alloc] initWithObjects:&obj forKeys:&key count:1];
    objs[cnt] = [entity globalIDForRow:pkeyRow];
    [pkeyRow release];
    cnt++;
  }
  gids = [[NSArray alloc] initWithObjects:objs count:cnt];
  tmp  = [[self runCommand:command,
                  @"gids", gids,
                  @"attributes", args,
                  @"groupBy", @"globalID", nil] allValues];
  [gids release];
  if (objs) free(objs);
  return [[tmp mutableCopy] autorelease];
}

- (NSArray *)_getGlobalIDsDefault:(NSString *)_key entityName:(NSString *)_e {
  NSArray *pkeys;
  
  if ((pkeys = [self->defaults arrayForKey:_key]) == nil)
    return nil;
  
  return [self _getGIDSforIds:pkeys entityName:@"Person"];
}

/* default setup */

- (void)_processHolidays {
    NSMutableDictionary *hGrps;
    NSMutableArray      *allHolidays;
    NSMutableDictionary *hRest;
    NSMutableDictionary *schoolHolidays;

    allHolidays =
      [NSMutableArray arrayWithArray:
        [self->defaults arrayForKey:@"scheduler_available_holidays"]];

    hGrps =
      [NSMutableDictionary dictionaryWithDictionary:
        [self->defaults dictionaryForKey:@"scheduler_holiday_groups"]];

    if ([hGrps count] > 0)
      self->holidayGroupsKeys = [[hGrps allKeys] mutableCopy];
    
    schoolHolidays = 
      [NSMutableDictionary dictionaryWithDictionary:
        [self->defaults dictionaryForKey:@"scheduler_school_holidays"]];

    if ([schoolHolidays count] > 0) {
      self->schoolHolidayKeys = [[schoolHolidays allKeys] mutableCopy];
      [hGrps addEntriesFromDictionary:schoolHolidays];
    }

    if ([hGrps count] > 0) {
      NSArray *allKeys;
      int     i, cnt;

      allKeys = [hGrps allKeys];
      
      for (i = 0, cnt = [allKeys count]; i < cnt; i++) {
        NSString *key;
        NSString *showKey;
        NSString *selectedKey;
        NSString *editableKey;
        NSNumber *grpSelected;
        NSNumber *grpEditable;

        key    = [allKeys objectAtIndex:i];

        showKey = @"scheduler_show_holiday_";
        showKey = [showKey stringByAppendingString:key];
        selectedKey = [key stringByAppendingString:@"_selected"];
        editableKey = [key stringByAppendingString:@"_editable"];

        grpSelected = [self->defaults objectForKey:showKey];
        grpSelected = (grpSelected == nil)
          ? noNum
          : grpSelected;
        grpEditable = [NSNumber numberWithBool:[self _isEditable:showKey]];
                
        [hGrps setObject:grpSelected forKey:selectedKey];
        [hGrps setObject:grpEditable forKey:editableKey];
      }
      ASSIGN(self->holidayGroups, hGrps);
    }
    if ([allHolidays count] > 0) {
      NSArray *allKeys;
      int      i, cnt;

      allKeys = [NSArray arrayWithArray:allHolidays];
      ASSIGN(self->restHolidaysKeys, allKeys);

      hRest = [NSMutableDictionary dictionaryWithCapacity:32];

      for (i = 0, cnt = [allKeys count]; i < cnt; i++) {
        NSString *key, *showKey, *selectedKey, *editableKey;
        NSNumber *grpSelected, *grpEditable;
	
        key    = [allKeys objectAtIndex:i];

        showKey     = @"scheduler_show_holiday_";
        showKey     = [showKey stringByAppendingString:key];
        selectedKey = [key stringByAppendingString:@"_selected"];
        editableKey = [key stringByAppendingString:@"_editable"];
	
        grpSelected = [self->defaults objectForKey:showKey];
        grpSelected = (grpSelected == nil)
          ? noNum
          : grpSelected;
        grpEditable = [NSNumber numberWithBool:[self _isEditable:showKey]];
                
        [hRest setObject:grpSelected forKey:selectedKey];
        [hRest setObject:grpEditable forKey:editableKey];
      }
      ASSIGN(self->restHolidays, hRest);
    }
}

- (void)_processCustomHolidays {
  NSDictionary    *customEveryYear;
  NSDictionary    *custom;
  NSMutableString *tfString = nil;
    
  custom = [self->defaults dictionaryForKey:@"scheduler_custom_holidays"];
  customEveryYear =
    [self->defaults dictionaryForKey:@"scheduler_custom_everyyear_holidays"];

  if (custom) {
    NSEnumerator *allYears;
    NSString *year;
      
    allYears = [[custom allKeys] objectEnumerator];
    while ((year = [allYears nextObject])) {
      NSDictionary *holidaysOfYear;
      NSEnumerator *holidays;
      NSString     *key;
	
      holidaysOfYear = [custom objectForKey:year];
      holidays       = [[holidaysOfYear allKeys] objectEnumerator];
	
      while ((key = [holidays nextObject])) {
	if (tfString)
	  [tfString appendString:@"\n"];
	else
	  tfString = [NSMutableString stringWithCapacity:16];
	
	[tfString appendFormat:@"%@-%@:%@",
		    year, key, [holidaysOfYear objectForKey:key]];
      }
    }
  }
  if (customEveryYear) {
    NSEnumerator *holidays;
    NSString     *key;

    holidays = [[customEveryYear allKeys] objectEnumerator];
    while ((key = [holidays nextObject])) {
      if (tfString)
	[tfString appendString:@"\n"];
      else
	tfString = [NSMutableString stringWithCapacity:16];
      
      [tfString appendFormat:@"%@:%@", key,[customEveryYear objectForKey:key]];
    }
  }
  self->customHolidays = [tfString copy];
}

- (void)_processPopUpResourceNames {
  NSEnumerator   *enumerator;
  NSMutableArray *r;
  NSString       *n, *s;
  NSArray        *tmp;
  
  s = [[self labels] valueForKey:@"resCategory"];
  if (s == nil) s = @"resCategory";
  
  r = [NSMutableArray arrayWithCapacity:8];
    
  tmp = [self->defaults arrayForKey:@"scheduler_popup_resourceNames"];
  enumerator = [tmp objectEnumerator];
    
  while ((n = [enumerator nextObject])) {
    if ([n hasSuffix:@"(resCategory)"]) {
      NSString *k;
	
      n = [[n  componentsSeparatedByString:@" ("] objectAtIndex:0];
      k = [[NSString alloc] initWithFormat:@"%@ (%@)", n, s];
      [r addObject:k];
      [k release];
    }
    else 
      [r addObject:n];
  }
  self->resourceNames = [r retain];
}

- (void)_processParticipants {
  self->participants = [[self _getGlobalIDsDefault:@"scheduler_popup_persons"
			      entityName:@"Person"] mutableCopy];
  [self->participants addObjectsFromArray:
	 [self _getGlobalIDsDefault:@"scheduler_popup_teams" 
	       entityName:@"Team"]];
  
  self->selectedParticipants =
    [[NSArray alloc] initWithArray:self->participants];
}

- (void)_processWriteAccess {
  self->writeAccess = [[self _getGlobalIDsDefault: @"scheduler_write_access_accounts"
			               entityName:@"Person"] mutableCopy];
  [self->writeAccess addObjectsFromArray : [self _getGlobalIDsDefault:@"scheduler_write_access_teams"
	                 				   entityName:@"Team"]];
  self->selectedWriteAccess = [[NSArray alloc] initWithArray:self->writeAccess];
}
//###ADDED BY AO###
//######READ#######
- (void)_processReadAccess {
  self->readAccess = [[self _getGlobalIDsDefault:@"scheduler_read_access_accounts"
			              entityName:@"Person"] 
				      mutableCopy];
  [self->readAccess addObjectsFromArray:
	     [self _getGlobalIDsDefault:@"scheduler_read_access_teams"
	                     entityName:@"Team"]];
  self->selectedReadAccess = [[NSArray alloc] initWithArray:self->readAccess];
}







//###############
//######DELEGATION#######
- (void)_processDelegRdvPriv 
{
   id resultDictionary;
   int i = 0;
   NSArray * arrayOfID = nil;
   
   resultDictionary = [self runCommand:@"appointment::get-delegation",nil];
   
   arrayOfID = [[resultDictionary valueForKey:@"idPrivate"] retain ];

   NSArray * objects  = [[self _getGIDSforIds:arrayOfID entityName:@"Person"] retain];
   // Pour g√rer les ID de Team : pas sure que ca marche !!!!!!
   // [objects addObjectsFromArray:[self _getGIDSforIds:arrayOfID entityName:@"Team"]];

   //[arrayOfID release];
   
   NSMutableArray * gids = [ NSMutableArray arrayWithCapacity:[objects count]];

   for(i = 0 ; i < [objects count]; i++)
   {
	   [gids addObject:[(NSDictionary *)[objects objectAtIndex:i] valueForKey:@"globalID"] ];
   }
   self->delegRdvPriv = [[self runCommand:@"person::get-by-globalid", @"gids" ,gids, @"attributes" ,personAttrNames, nil] mutableCopy];
//   [self->delegRdvPriv addObjectsFromArray: [self _getGlobalIDsDefault:@"scheduler_deleg_rdv_priv_teams" entityName:@"Team"]];
   self->selectedDelegRdvPriv = [[NSArray alloc] initWithArray:self->delegRdvPriv];
   [self logWithFormat:@"### selectedDelegPriv :%@",self->selectedDelegRdvPriv];

}







- (void)_processDelegRdvPubli 
{

   id resultDictionary;
   int i = 0;
   NSArray * arrayOfID = nil;
   
   resultDictionary = [self runCommand:@"appointment::get-delegation",nil];
   
   arrayOfID = [[resultDictionary valueForKey:@"idPublic"] retain ];

   NSArray * objects  = [[self _getGIDSforIds:arrayOfID entityName:@"Person"]retain];
   // Pour g√rer les ID de Team : pas sure que ca marche !!!!!!
   // [objects addObjectsFromArray:[self _getGIDSforIds:arrayOfID entityName:@"Team"]];

   //[arrayOfID release];

   NSMutableArray * gids = [ NSMutableArray arrayWithCapacity:[objects count]];

   for(i = 0 ; i < [objects count]; i++)
   {
	   [gids addObject:[(NSDictionary *)[objects objectAtIndex:i] valueForKey:@"globalID"] ];
   }
    
   self->delegRdvPubli = [[self runCommand:@"person::get-by-globalid", @"gids" ,gids, @"attributes" ,personAttrNames, nil] mutableCopy]; 
//   [self->delegRdvPubli addObjectsFromArray: [self _getGlobalIDsDefault:@"scheduler_deleg_rdv_publi_teams" entityName:@"Team"]];
   self->selectedDelegRdvPubli = [[NSArray alloc] initWithArray:self->delegRdvPubli];
   [self logWithFormat:@"### selectedDelegPubli :%@",self->selectedDelegRdvPubli];

}

/*
  self->delegRdvPubli = [[self _getGlobalIDsDefault:@"scheduler_deleg_rdv_publi_accounts"
			                entityName:@"Person"] 
			                mutableCopy];
  [self->delegRdvPubli addObjectsFromArray:
	     [self _getGlobalIDsDefault:@"scheduler_deleg_rdv_publi_teams"
	                     entityName:@"Team"]];
  self->selectedDelegRdvPubli = [[NSArray alloc] initWithArray:self->delegRdvPubli];

 }
*/

- (void)_processDelegRdvConf {
   id resultDictionary;
   int i = 0;
   NSArray * arrayOfID = nil;
   
   resultDictionary = [self runCommand:@"appointment::get-delegation",nil];
   
   arrayOfID = [[resultDictionary valueForKey:@"idConfidential"] retain ];

   NSArray * objects  = [[self _getGIDSforIds:arrayOfID entityName:@"Person"] retain];
   // Pour g√rer les ID de Team : pas sure que ca marche !!!!!!
   // [objects addObjectsFromArray:[self _getGIDSforIds:arrayOfID entityName:@"Team"]];

   //[arrayOfID release];

   NSMutableArray * gids = [ NSMutableArray arrayWithCapacity:[objects count]];

   for(i = 0 ; i < [objects count]; i++)
   {
	   [gids addObject:[(NSDictionary *)[objects objectAtIndex:i] valueForKey:@"globalID"] ];
   }
    
   self->delegRdvConf = [[self runCommand:@"person::get-by-globalid", @"gids" ,gids, @"attributes" ,personAttrNames, nil] mutableCopy];
  // [self->delegRdvConf addObjectsFromArray: [self _getGlobalIDsDefault:@"scheduler_deleg_rdv_conf_teams" entityName:@"Team"]];
   self->selectedDelegRdvConf = [[NSArray alloc] initWithArray:self->delegRdvConf];
   [self logWithFormat:@"### selectedDelegConf :%@",self->selectedDelegRdvConf];

}
  /*self->delegRdvConf = [[self _getGlobalIDsDefault:@"scheduler_deleg_rdv_conf_accounts"
			                entityName:@"Person"] 
			                mutableCopy];
  [self->delegRdvConf addObjectsFromArray:
	     [self _getGlobalIDsDefault:@"scheduler_deleg_rdv_conf_teams"
	                     entityName:@"Team"]];
  self->selectedDelegRdvConf = [[NSArray alloc] initWithArray:self->delegRdvConf];
}*/
- (void)_processDelegRdvNorm {
   id resultDictionary;
   int i = 0;
   NSArray * arrayOfID = nil;
   
   resultDictionary = [self runCommand:@"appointment::get-delegation",nil];
   
   arrayOfID = [[resultDictionary valueForKey:@"idNormal"] retain ];

   NSArray * objects  = [[self _getGIDSforIds:arrayOfID entityName:@"Person"]retain];
   // Pour g√rer les ID de Team : pas sure que ca marche !!!!!!
   // [objects addObjectsFromArray:[self _getGIDSforIds:arrayOfID entityName:@"Team"]];

   //[arrayOfID release];

   NSMutableArray * gids = [ NSMutableArray arrayWithCapacity:[objects count]];

   for(i = 0 ; i < [objects count]; i++)
   {
	   [gids addObject:[(NSDictionary *)[objects objectAtIndex:i] valueForKey:@"globalID"] ];
   }
   
   self->delegRdvNorm = [[self runCommand:@"person::get-by-globalid", @"gids" ,gids, @"attributes" ,personAttrNames, nil] mutableCopy];
  // [self->delegRdvNorm addObjectsFromArray: [self _getGlobalIDsDefault:@"scheduler_deleg_rdv_norm_teams" entityName:@"Team"]];
   self->selectedDelegRdvNorm = [[NSArray alloc] initWithArray:self->delegRdvNorm];
   [self logWithFormat:@"### selectedDelegNorm :%@",self->selectedDelegRdvNorm];

}
 /* self->delegRdvNorm = [[self _getGlobalIDsDefault:@"scheduler_deleg_rdv_norm_accounts"
			                entityName:@"Person"] 
			                mutableCopy];
  [self->delegRdvNorm addObjectsFromArray:
	     [self _getGlobalIDsDefault:@"scheduler_deleg_rdv_norm_teams"
	                     entityName:@"Team"]];
  self->selectedDelegRdvNorm = [[NSArray alloc] initWithArray:self->delegRdvNorm];
}*/
//###############

- (void)setAccount:(id)_account {
  // TODO: split up this huge method!
  NSUserDefaults *ud = nil;
  id             tmp = nil;

  RELEASE(self->mailTemplate);          self->mailTemplate    = nil;
  RELEASE(self->templateDateFormat);    self->templateDateFormat = nil;
  RELEASE(self->defaults);              self->defaults           = nil;
  RELEASE(self->schedulerView);         self->schedulerView      = nil;
  RELEASE(self->appointmentView);       self->appointmentView    = nil;
  RELEASE(self->timeInputType);         self->timeInputType      = nil;
  RELEASE(self->aptTypeInputType);      self->aptTypeInputType   = nil;
  RELEASE(self->rdvTypeInputType);      self->rdvTypeInputType   = nil;
  RELEASE(self->absenceMode);           self->absenceMode        = nil;
  RELEASE(self->noOfCols);              self->noOfCols           = nil;
  RELEASE(self->resourceNames);         self->resourceNames      = nil;
  RELEASE(self->participants);          self->participants       = nil;
  RELEASE(self->selectedParticipants);  self->selectedParticipants = nil;
  RELEASE(self->writeAccess);           self->writeAccess          = nil;
  RELEASE(self->selectedWriteAccess);   self->selectedWriteAccess  = nil;
//###ADDED BY AO###
  RELEASE(self->readAccess);            self->readAccess           = nil;
  RELEASE(self->selectedReadAccess);    self->selectedReadAccess   = nil;
  RELEASE(self->delegRdvPriv);          self->delegRdvPriv         = nil;
  RELEASE(self->selectedDelegRdvPriv);  self->selectedDelegRdvPriv = nil;
  RELEASE(self->delegRdvPubli);         self->delegRdvPubli         = nil;
  RELEASE(self->selectedDelegRdvPubli); self->selectedDelegRdvPubli = nil;
  RELEASE(self->delegRdvConf);          self->delegRdvConf         = nil;
  RELEASE(self->selectedDelegRdvConf);  self->selectedDelegRdvConf = nil;
  RELEASE(self->delegRdvNorm);          self->delegRdvNorm         = nil;
  RELEASE(self->selectedDelegRdvNorm);  self->selectedDelegRdvNorm = nil;
//################
  RELEASE(self->holidayGroups);         self->holidayGroups     = nil;
  RELEASE(self->holidayGroupsKeys);     self->holidayGroupsKeys = nil;
  RELEASE(self->restHolidays);          self->restHolidays      = nil;
  RELEASE(self->restHolidaysKeys);      self->restHolidaysKeys  = nil;
  RELEASE(self->schoolHolidayKeys);     self->schoolHolidayKeys = nil;
  RELEASE(self->holiday);               self->holiday           = nil;
  RELEASE(self->customHolidays);        self->customHolidays    = nil;
  RELEASE(self->item);                  self->item              = nil;
  RELEASE(self->schedulerPageTab);      self->schedulerPageTab  = nil;
  RELEASE(self->schedulerPageWeekView); self->schedulerPageWeekView = nil;
  RELEASE(self->schedulerPageDayView);  self->schedulerPageDayView  = nil;
  RELEASE(self->defaultCCForNotificationMails);
  self->defaultCCForNotificationMails = nil;
  RELEASE(self->notificationDevices);   self->notificationDevices = nil;
  
  ASSIGN(self->account, _account);
  
  ud = _account
    ? [self runCommand:@"userdefaults::get", @"user", _account, nil]
    : [self runCommand:@"userdefaults::get", nil];
  
  self->defaults = [ud retain];
  
  self->mailTemplate =
    [[self->defaults stringForKey:@"scheduler_mail_template"]
                     copy];
  self->templateDateFormat =
    [[self->defaults stringForKey:@"scheduler_mail_template_date_format"] copy];

  self->attachAppointments =
    [self->defaults boolForKey:@"scheduler_attach_apts_to_mails"];
  
  self->schedulerView =
    [[self->defaults stringForKey:@"scheduler_view"] copy];
  self->appointmentView =
    [[self->defaults stringForKey:@"scheduler_appointment_view"] copy];
  self->absenceMode = [[self->defaults stringForKey:@"absence_mode"] copy];
  self->timeInputType =
    [[self->defaults stringForKey:@"scheduler_time_input_type"] copy];
  self->aptTypeInputType =
    [[self->defaults stringForKey:@"scheduler_apttype_input_type"] copy];
  self->defaultCCForNotificationMails =
    [[self->defaults stringForKey:@"scheduler_ccForNotificationMails"] copy];

  tmp = [self->defaults objectForKey:@"scheduler_start_hour"];
  self->startHour = tmp ? [tmp intValue] : 9;
  tmp = [self->defaults objectForKey:@"scheduler_end_hour"];
  self->endHour = tmp ? [tmp intValue] : 20;
  tmp = [self->defaults objectForKey:@"scheduler_weekchart_columnsperday"];
  self->columnsPerDayWeekView = tmp ? [tmp intValue] : 24;
  tmp = [self->defaults objectForKey:@"scheduler_daychart_columnsperday"];
  self->columnsPerDayDayView = tmp ? [tmp intValue] : 60;

  tmp = [self->defaults objectForKey:@"scheduler_dayoverview_daystart"];
  self->dayOverviewStartHour = tmp ? [tmp intValue] : 480;
  tmp = [self->defaults objectForKey:@"scheduler_dayoverview_dayend"];
  self->dayOverviewEndHour = tmp ? [tmp intValue] : 1080;
  tmp = [self->defaults objectForKey:@"scheduler_dayoverview_timeinterval"];
  self->dayOverviewInterval = tmp ? [tmp intValue] : 3600;

  self->noOfCols = [self->defaults objectForKey:@"scheduler_no_of_cols"];
  RETAIN(self->noOfCols);

  self->isTemplateDateFormatEditable  =
    [self _isEditable:@"scheduler_mail_template_date_format"];
  self->isMailTemplateEditable  =
    [self _isEditable:@"scheduler_mail_template"];
  self->isNoOfColsEditable      = [self _isEditable:@"scheduler_no_of_cols"];
  self->isSchedulerViewEditable = [self _isEditable:@"scheduler_view"];
  self->isEndHourEditable       = [self _isEditable:@"scheduler_end_hour"];
  self->isStartHourEditable     = [self _isEditable:@"scheduler_start_hour"];
  self->isColumnsPerDayWeekViewEditable =
    [self _isEditable:@"scheduler_weekchart_columnsperday"];
  self->isColumnsPerDayDayViewEditable =
    [self _isEditable:@"scheduler_daychart_columnsperday"];
  
  self->isAbsenceModeEditable   = [self _isEditable:@"absence_mode"];
  
  self->isDayOverviewStartHourEditable =
    [self _isEditable:@"scheduler_dayoverview_daystart"];

  self->isDayOverviewEndHourEditable =
    [self _isEditable:@"scheduler_dayoverview_dayend"];

  self->isDayOverviewIntervalEditable =
    [self _isEditable:@"scheduler_dayoverview_timeinterval"];

  self->isTimeInputTypeEditable =
    [self _isEditable:@"scheduler_time_input_type"];
  self->isAptTypeInputTypeEditable =
    [self _isEditable:@"scheduler_apttype_input_type"];

  self->isAppointmentViewEditable =
    [self _isEditable:@"scheduler_appoinment_view"];

  self->additionalPopupEntries =
    [self->defaults integerForKey:@"scheduler_additional_popup_entries"];


  self->isNotificationDevicesEditable =
    [self _isEditable:@"SkyAptNotifyDevices"];
  self->notificationDevices =
    [self->defaults objectForKey:@"SkyAptNotifyDevices"];
  if ([self->notificationDevices count] == 0) // must be atleast one
    self->notificationDevices = [NSArray arrayWithObject:@"email"];
  RETAIN(self->notificationDevices);

  self->schedulerPageTab =
    [[self->defaults stringForKey:@"schedulerpage_tab"] copy];
  self->schedulerPageWeekView =
    [[self->defaults stringForKey:@"schedulerpage_weekview"] copy];
  self->schedulerPageDayView =
    [[self->defaults stringForKey:@"schedulerpage_dayview"] copy];

  self->showTodos     = [self->defaults boolForKey:@"scheduler_show_jobs"];
  self->showPalmDates =
    [self->defaults boolForKey:@"scheduler_show_palm_dates"];

  self->showFullNames =
    [self->defaults boolForKey:@"scheduler_overview_full_names"];
  
  [self _processPopUpResourceNames];
  [self _processParticipants];
  [self _processWriteAccess];
//###ADDED BY AO###
//  ######READ######
  [self _processReadAccess];
 //####DELEGATION#######
  [self _processDelegRdvPriv];
  [self _processDelegRdvConf];
  [self _processDelegRdvPubli];
  [self _processDelegRdvNorm];
  self->shortInfo =
    [[self->defaults objectForKey:@"scheduler_overview_short_info"] boolValue];

  self->withResources =
    [[self->defaults objectForKey:@"scheduler_overview_with_resources"]
                     boolValue];

  self->hideIgnoreConflicts =
    [[self->defaults objectForKey:@"scheduler_hide_ignore_conflicts"]
                     boolValue];
  
  [self _processHolidays];
  [self _processCustomHolidays];
}


- (id)account {
  return self->account;
}
- (id)accountId {
  return [[self account] valueForKey:@"companyId"];
}

- (NSString *)accountLabel {
  return [[self session] labelForObject:[self account]];
}

- (BOOL)isRoot {
  return self->isRoot;
}

- (void)setShortInfo:(BOOL)_flag {
  self->shortInfo = _flag;
}
- (BOOL)shortInfo {
  return self->shortInfo;
}

- (void)setWithResources:(BOOL)_flag {
  self->withResources = _flag;
}
- (BOOL)withResources {
  return self->withResources;
}

- (void)setHideIgnoreConflicts:(BOOL)_flag {
  self->hideIgnoreConflicts = _flag;
}
- (BOOL)hideIgnoreConflicts {
  return self->hideIgnoreConflicts;
}

- (BOOL)isSchedulerViewEditable {
  return self->isSchedulerViewEditable || self->isRoot;
}
- (BOOL)isSchedulerTimeInputTypeEditable {
  return self->isTimeInputTypeEditable || self->isRoot;
}
- (BOOL)isSchedulerAptTypeInputTypeEditable {
  return self->isAptTypeInputTypeEditable || self->isRoot;
}
- (BOOL)isSchedulerStartHourEditable {
  return self->isStartHourEditable || self->isRoot;
}
- (BOOL)isSchedulerEndHourEditable {
  return self->isEndHourEditable || self->isRoot;
}
- (BOOL)isWeekChartColumnsPerDayEditable {
  return self->isColumnsPerDayWeekViewEditable || self->isRoot;
}
- (BOOL)isDayChartColumnsPerDayEditable {
  return self->isColumnsPerDayDayViewEditable || self->isRoot;
}
- (BOOL)isDayOverviewStartHourEditable {
  return self->isDayOverviewStartHourEditable || self->isRoot;
}
- (BOOL)isDayOverviewEndHourEditable {
  return self->isDayOverviewEndHourEditable || self->isRoot;
}
- (BOOL)isDayOverviewIntervalEditable {
  return self->isDayOverviewIntervalEditable || self->isRoot;
}
- (BOOL)isNoOfColsEditable {
  return self->isNoOfColsEditable || self->isRoot;
}

- (BOOL)isAppointmentViewEditable {
   return self->isAppointmentViewEditable || self->isRoot;
}

- (void)setNoOfCols:(NSString *)_number {
  ASSIGN(self->noOfCols, _number);
}
- (NSString *)noOfCols {
  return self->noOfCols;
}
- (void)setIsNoOfColsEditable:(BOOL)_flag {
    if (self->isRoot)
    self->isNoOfColsEditable = _flag;
}

// scheduler page startup tab
- (void)setSchedulerPageTab:(NSString *)_tab {
  ASSIGN(self->schedulerPageTab,_tab);
}
- (NSString *)schedulerPageTab {
  if (self->schedulerPageTab == nil) {
    self->schedulerPageTab = @"weekoverview";
    RETAIN(self->schedulerPageTab);
  }
  return self->schedulerPageTab;
}
- (void)setSchedulerPageWeekView:(NSString *)_view {
  ASSIGN(self->schedulerPageWeekView,_view);
}
- (NSString *)schedulerPageWeekView {
  if (self->schedulerPageWeekView == nil) {
    self->schedulerPageWeekView = @"overview";
    RETAIN(self->schedulerPageWeekView);
  }
  return self->schedulerPageWeekView;
}
- (void)setSchedulerPageWeekViewPopUp:(NSString *)_view {
  [self setSchedulerPageWeekView:[_view substringFromIndex:5]];
}
- (NSString *)schedulerPageWeekViewPopUp {
  return [(NSString *)@"week_" stringByAppendingString:
                      [self schedulerPageWeekView]];
}
- (void)setSchedulerPageDayView:(NSString *)_view {
  ASSIGN(self->schedulerPageDayView,_view);
}
- (NSString *)schedulerPageDayView {
  if (self->schedulerPageDayView == nil) {
    self->schedulerPageDayView = @"overview";
    RETAIN(self->schedulerPageDayView);
  }
  return self->schedulerPageDayView;
}
- (void)setSchedulerPageDayViewPopUp:(NSString *)_view {
  [self setSchedulerPageDayView:[_view substringFromIndex:4]];
}
- (NSString *)schedulerPageDayViewPopUp {
  return [(NSString *)@"day_" stringByAppendingString:
                      [self schedulerPageDayView]];
}

- (void)setShowTodos:(BOOL)_flag {
  self->showTodos = _flag;
}
- (BOOL)showTodos {
  return self->showTodos;
}
- (void)setShowPalmDates:(BOOL)_flag {
  self->showPalmDates = _flag;
}
- (BOOL)showPalmDates {
  return self->showPalmDates;
}

- (void)setShowFullNames:(BOOL)_flag {
  self->showFullNames = _flag;
}
- (BOOL)showFullNames {
  return self->showFullNames;
}

// notification devices
- (void)setNotificationDevices:(NSArray *)_devs {
  // must be at least one
  if (![_devs count]) _devs = [NSArray arrayWithObject:@"email"];
  ASSIGN(self->notificationDevices,_devs);
}
- (NSArray *)notificationDevices {
  return self->notificationDevices;
}
- (void)setIsNotificationDevicesEditableRoot:(BOOL)_flag {
  if (self->isRoot) self->isNotificationDevicesEditable = _flag;
}
- (BOOL)isNotificationDevicesEditableRoot {
  return self->isNotificationDevicesEditable;
}
- (BOOL)isNotificationDevicesEditable {
  return self->isNotificationDevicesEditable || self->isRoot;
}
- (NSString *)notificationDeviceLabel {
  return [[self labels]
                valueForKey:
                [NSString stringWithFormat:@"notifydev_%@", self->item]];
}
- (NSArray *)availableNotificationDevices {
  NSMutableArray *available;
  
  if (self->availableNotificationDevices)
    return self->availableNotificationDevices;

  available = [NSMutableArray arrayWithCapacity:16];
    
  [available addObject:@"email"];
  if ([[[self session] userDefaults] boolForKey:@"AptNotifySendpageEnabled"])
    // this is only an extension
    [available addObject:@"sms"];
  self->availableNotificationDevices = [available copy];
  
  return self->availableNotificationDevices;
}
- (BOOL)showNotificationDevices {
  if (![self isNotificationDevicesEditable]) return NO;
  if ([[self availableNotificationDevices] count] < 2) return NO;
  return YES;
}
- (BOOL)showNotificationDevicesRoot {
  if ([[self availableNotificationDevices] count] < 2) return NO;
  return YES;
}

- (NSString*)absenceMode {
  return self->absenceMode;
}

- (void)setIsAbsenceModeEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isAbsenceModeEditable = _flag;
}

- (void)setAbsenceMode:(NSString*)_mode {
  ASSIGN(self->absenceMode,_mode);
}

- (void)setIsAppointmentViewEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isAppointmentViewEditable = _flag;
}

- (void)setIsSchedulerViewEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isSchedulerViewEditable = _flag;
}
- (BOOL)isSchedulerViewEditableRoot {
  return self->isSchedulerViewEditable;
}

- (void)setIsSchedulerTimeInputTypeEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isTimeInputTypeEditable = _flag;
}
- (BOOL)isSchedulerTimeInputTypeEditableRoot {
  return self->isTimeInputTypeEditable;
}
- (void)setIsSchedulerAptTypeInputTypeEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isAptTypeInputTypeEditable = _flag;
}
- (BOOL)isSchedulerAptTypeInputTypeEditableRoot {
  return self->isAptTypeInputTypeEditable;
}

- (void)setIsSchedulerStartHourEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isStartHourEditable = _flag;
}
- (BOOL)isSchedulerStartHourEditableRoot {
  return self->isStartHourEditable;
}

- (void)setIsSchedulerEndHourEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isEndHourEditable = _flag;
}
- (BOOL)isSchedulerEndHourEditableRoot {
  return self->isEndHourEditable;
}

- (void)setIsWeekChartColumnsPerDayEditable:(BOOL)_flag {
  if (self->isRoot)
    self->isColumnsPerDayWeekViewEditable = _flag;
}
- (BOOL)isColumnsPerDayWeekViewEditableRoot {
  return self->isColumnsPerDayWeekViewEditable;
}

- (void)setIsDayChartColumnsPerDayEditable:(BOOL)_flag {
  if (self->isRoot)
    self->isColumnsPerDayDayViewEditable = _flag;
}
- (BOOL)isColumnsPerDayDayViewEditableRoot {
  return self->isColumnsPerDayDayViewEditable;
}

- (void)setIsDayOverviewStartHourEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isDayOverviewStartHourEditable = _flag;
}
- (BOOL)isDayOverviewStartHourEditableRoot {
  return self->isDayOverviewStartHourEditable;
}

- (void)setIsDayOverviewEndHourEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isDayOverviewEndHourEditable = _flag;
}
- (BOOL)isDayOverviewEndHourEditableRoot {
  return self->isDayOverviewEndHourEditable;
}

- (void)setIsDayOverviewIntervalEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isDayOverviewIntervalEditable = _flag;
}
- (BOOL)isDayOverviewIntervalEditableRoot {
  return self->isDayOverviewIntervalEditable;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)defaultCCForNotificationMails {
  return self->defaultCCForNotificationMails;
}
- (void)setDefaultCCForNotificationMails:(NSString *)_str {
  ASSIGN(self->defaultCCForNotificationMails, _str);
}

- (void)setIsAbsenceModeEditable:(BOOL)_flag {
    self->isAbsenceModeEditable = _flag;
}

- (BOOL)isAbsenceModeEditable {
  return self->isAbsenceModeEditable;
}

- (void)setSchedulerView:(NSString *)_value {
  ASSIGN(self->schedulerView, _value);
}
- (NSString *)schedulerView {
  return self->schedulerView;
}

- (void)setSchedulerTimeInputType:(NSString *)_value {
  ASSIGN(self->timeInputType, _value);
}
- (NSString *)schedulerTimeInputType {
  return self->timeInputType;
}

- (void)setSchedulerAptTypeInputType:(NSString *)_value {
  ASSIGN(self->aptTypeInputType, _value);
}
- (NSString *)schedulerAptTypeInputType {
  return self->aptTypeInputType;
}
- (void)setSchedulerRdvTypeInputType:(NSString *)_value {
  ASSIGN(self->rdvTypeInputType, _value);
}
- (NSString *)schedulerRdvTypeInputType {
  return self->rdvTypeInputType;
} 

- (void)setAppointmentView:(NSString *)_view {
  ASSIGN(self->appointmentView,_view);
}

- (NSString *)appointmentView {
  return self->appointmentView;
}

- (void)setStartHour:(NSString *)_hour {
  self->startHour = [_hour intValue];
}
- (NSString *)startHour {
  unsigned char buf[8];
  sprintf(buf, "%02i", self->startHour);
  return [NSString stringWithCString:buf];
}

- (void)setEndHour:(NSString *)_hour {
  self->endHour = [_hour intValue];
}
- (NSString *)endHour {
  unsigned char buf[8];
  sprintf(buf, "%02i", self->endHour);
  return [NSString stringWithCString:buf];
}

- (void)setColumnsPerDayWeekView:(NSString *)_columns {
  self->columnsPerDayWeekView = [_columns intValue];
}
- (NSString *)columnsPerDayWeekView {
  unsigned char buf[8];
  sprintf(buf, "%i", self->columnsPerDayWeekView);
  return [NSString stringWithCString:buf];
}

- (void)setColumnsPerDayDayView:(NSString *)_columns {
  self->columnsPerDayDayView = [_columns intValue];
}
- (NSString *)columnsPerDayDayView {
  unsigned char buf[8];
  sprintf(buf, "%i", self->columnsPerDayDayView);
  return [NSString stringWithCString:buf];
}

- (void)setDayOverviewStartHour:(NSNumber *)_hour {
  self->dayOverviewStartHour = [_hour intValue];
}
- (NSNumber *)dayOverviewStartHour {
  return [NSNumber numberWithInt:self->dayOverviewStartHour];
}

- (void)setDayOverviewEndHour:(NSNumber *)_hour {
  self->dayOverviewEndHour = [_hour intValue];
}
- (NSNumber *)dayOverviewEndHour {
  return [NSNumber numberWithInt:self->dayOverviewEndHour];
}

- (void)setDayOverviewInterval:(NSNumber *)_hour {
  self->dayOverviewInterval = [_hour intValue];
}
- (NSNumber *)dayOverviewInterval {
  return [NSNumber numberWithInt:self->dayOverviewInterval];
}

- (NSString *)itemLabel {
  return [[self labels] valueForKey:[self item]];
}
- (NSString *)holidayLabel {
  id l = nil;

  l = [[self labels] valueForKey:self->holiday];
  return (l == nil) ? self->holiday : l;
}

- (NSString *)schedulerViewLabel {
  return [[self labels] valueForKey:[self schedulerView]];
}
- (NSString *)schedulerTimeInputTypeLabel {
  return [[self labels] valueForKey:[self schedulerTimeInputType]];
}
- (NSString *)startHourLabel {
  return [[self labels] valueForKey:[self startHour]];
}
- (NSString *)endHourLabel {
  return [[self labels] valueForKey:[self endHour]];
}

- (NSArray *)resourceNames {
  return self->resourceNames;
}
- (void)setResourceNames:(NSArray *)_names {
  ASSIGN(self->resourceNames, _names);
}

- (NSArray *)participants {
  return self->participants;
}
- (void)setParticipants:(NSArray *)_p {
  ASSIGN(self->participants, _p);
}

- (NSArray *)selectedParticipants {
  return self->selectedParticipants;
}
- (void)setSelectedParticipants:(NSArray *)_s {
  ASSIGN(self->selectedParticipants, _s);
}

- (NSArray *)writeAccess {
  return self->writeAccess;
}
- (void)setWriteAccess:(NSArray *)_p {
  ASSIGN(self->writeAccess, _p);
}

- (NSArray *)selectedWriteAccess {
  return self->selectedWriteAccess;
}
- (void)setSelectedWriteAccess:(NSArray *)_s {
  ASSIGN(self->selectedWriteAccess, _s);
}
//###ADDED BY AO###
//#####READ####
- (NSArray *)readAccess {
  return self->readAccess;
}
- (void)setReadAccess:(NSArray *)_p {
  ASSIGN(self->readAccess, _p);
}

- (NSArray *)selectedReadAccess {
  return self->selectedReadAccess;
}
- (void)setSelectedReadAccess:(NSArray *)_s {
  ASSIGN(self->selectedReadAccess, _s);
}
//################
//#####DELEGATION####
- (NSArray *)delegRdvPriv {
  return self->delegRdvPriv;
}
- (void)setDelegRdvPriv:(NSArray *)_p {
  ASSIGN(self->delegRdvPriv, _p);
}

- (NSArray *)selectedDelegRdvPriv {
  return self->selectedDelegRdvPriv;
}
- (void)setSelectedDelegRdvPriv:(NSArray *)_s {
  ASSIGN(self->selectedDelegRdvPriv, _s);
}
//#####NORMAL###
- (NSArray *)delegRdvNorm {
  return self->delegRdvNorm;
}
- (void)setDelegRdvNorm:(NSArray *)_p {
  ASSIGN(self->delegRdvNorm, _p);
}

- (NSArray *)selectedDelegRdvNorm {
  return self->selectedDelegRdvNorm;
}
- (void)setSelectedDelegRdvNorm:(NSArray *)_s {
  ASSIGN(self->selectedDelegRdvNorm, _s);
}
//######PUBLIC####
- (NSArray *)delegRdvPubli {
  return self->delegRdvPubli;
}
- (void)setDelegRdvPubli:(NSArray *)_p {
  ASSIGN(self->delegRdvPubli, _p);
}

- (NSArray *)selectedDelegRdvPubli {
  return self->selectedDelegRdvPubli;
}
- (void)setSelectedDelegRdvPubli:(NSArray *)_s {
  ASSIGN(self->selectedDelegRdvPubli, _s);
}
//######CONFIDENTIEL#####
- (NSArray *)delegRdvConf {
  return self->delegRdvConf;
}
- (void)setDelegRdvConf:(NSArray *)_p {
  ASSIGN(self->delegRdvConf, _p);
}

- (NSArray *)selectedDelegRdvConf{
  return self->selectedDelegRdvConf;
}
- (void)setSelectedDelegRdvConf:(NSArray *)_s {
  ASSIGN(self->selectedDelegRdvConf, _s);
}
//##############
- (NSString *)additionalPopupEntries {
  return [NSString stringWithFormat:@"%d", self->additionalPopupEntries];
}
- (void)setAdditionalPopupEntries:(NSString *)_str {
  self->additionalPopupEntries = [_str intValue];
}

- (BOOL)isSchedulerClassicEnabled {
  return self->isSchedulerClassicEnabled;
}

- (void)setMinutes:(NSArray *)_mins {
  ASSIGN(self->minutes,_mins);
}
- (NSArray *)minutes {
  return self->minutes;
}

- (void)setLabelsForMinutes:(NSDictionary *)_labels {
  ASSIGN(self->labelsForMinutes,_labels);
}
- (NSDictionary *)labelsForMinutes {
  return self->labelsForMinutes;
}

- (void)setHolidayGroups:(NSMutableDictionary *)_hg {
  ASSIGN(self->holidayGroups,_hg);
}
- (NSMutableDictionary *)holidayGroups {
  return self->holidayGroups;
}

- (void)setHolidayGroupsKeys:(NSArray *)_keys {
  ASSIGN(self->holidayGroupsKeys,_keys);
}
- (NSArray *)holidayGroupsKeys {
  return self->holidayGroupsKeys;
}

- (void)setRestHolidays:(NSMutableDictionary *)_rest {
  ASSIGN(self->restHolidays,_rest);
}
- (NSMutableDictionary *)restHolidays {
  return self->restHolidays;
}

- (void)setRestHolidaysKeys:(NSArray *)_keys {
  ASSIGN (self->restHolidaysKeys,_keys);
}
- (NSArray *)restHolidaysKeys {
  return self->restHolidaysKeys;
}

- (void)setSchoolHolidayKeys:(NSArray *)_keys {
  ASSIGN (self->schoolHolidayKeys, _keys);
}
- (NSArray *)schoolHolidayKeys {
  return self->schoolHolidayKeys;
}

- (void)setHoliday:(NSString *)_h {
  ASSIGN(self->holiday, _h);
}
- (NSString *)holiday {
  return self->holiday;
}

- (void)setCustomHolidays:(NSString *)_custom {
  ASSIGN(self->customHolidays,_custom);
}
- (NSString *)customHolidays {
  return self->customHolidays;
}

- (void)setMailTemplate:(NSString *)_str {
  ASSIGN(self->mailTemplate,_str);
}
- (NSString *)mailTemplate {
  return self->mailTemplate;
}

- (void)setIsMailTemplateEditable:(BOOL)_bool {
  self->isMailTemplateEditable = _bool;
}
- (BOOL)isMailTemplateEditable {
  return self->isMailTemplateEditable;
}

- (void)setTemplateDateFormat:(NSString *)_str {
  ASSIGN(self->templateDateFormat,_str);
}
- (NSString *)templateDateFormat {
  return self->templateDateFormat;
}

- (void)setIsTemplateDateFormatEditable:(BOOL)_bool {
  self->isTemplateDateFormatEditable = _bool;
}
- (BOOL)isTemplateDateFormatEditable {
  return self->isTemplateDateFormatEditable;
}

- (void)setAttachAppointments:(BOOL)_flag {
  self->attachAppointments = _flag;
}
- (BOOL)attachAppointments {
  return self->attachAppointments;
}

/* holiday stuff */

- (void)setIsHolidayEditableRoot:(BOOL)_flag {
  NSString *editableKey;
  NSNumber *flag;

  editableKey = [self->holiday stringByAppendingString:@"_editable"];
  flag = [NSNumber numberWithBool:_flag];

  if ([self->holidayGroupsKeys containsObject:self->holiday])
    [self->holidayGroups setObject:flag forKey:editableKey];
  
  if ([self->restHolidaysKeys containsObject:self->holiday])
    [self->restHolidays setObject:flag forKey:editableKey];

  if ([self->schoolHolidayKeys containsObject:self->holiday])
    [self->holidayGroups setObject:flag forKey:editableKey];
}
- (BOOL)isHolidayEditableRoot {
  NSString *editableKey;
  NSNumber *flag;

  editableKey = [self->holiday stringByAppendingString:@"_editable"];
  
  if ((flag = [self->holidayGroups objectForKey:editableKey]) != nil) 
    return [flag boolValue];

  if ((flag = [self->restHolidays objectForKey:editableKey]) != nil)
    return [flag boolValue];
  
  return NO;
}

- (BOOL)isHolidayEditable {
  return ([self isHolidayEditableRoot] || self->isRoot) ? YES : NO;
}

- (void)setHolidaySelected:(BOOL)_flag {
  NSString *selectedKey;
  NSNumber *flag;

  selectedKey = [self->holiday stringByAppendingString:@"_selected"];
  flag = [NSNumber numberWithBool:_flag];

  if ([self->holidayGroupsKeys containsObject:self->holiday])
    [self->holidayGroups setObject:flag forKey:selectedKey];

  if ([self->schoolHolidayKeys containsObject:self->holiday])
    [self->holidayGroups setObject:flag forKey:selectedKey];
  
  if ([self->restHolidaysKeys containsObject:self->holiday])
    [self->restHolidays setObject:flag forKey:selectedKey];
}
- (BOOL)holidaySelected {
  NSString *selectedKey;
  NSNumber *flag;

  selectedKey = [self->holiday stringByAppendingString:@"_selected"];
  
  if ((flag = [self->holidayGroups objectForKey:selectedKey]) != nil)
    return [flag boolValue];
  
  if ((flag = [self->restHolidays objectForKey:selectedKey]) != nil)
    return [flag boolValue];
  
  return NO;
}

- (BOOL)makeBR {
  int idx;
  if ([self->holidayGroupsKeys containsObject:self->holiday])
    idx = [self->holidayGroupsKeys indexOfObject:self->holiday];
  else if ([self->restHolidaysKeys containsObject:self->holiday]) 
    idx = [self->restHolidaysKeys indexOfObject:self->holiday];
  else
    idx = [self->schoolHolidayKeys indexOfObject:self->holiday];

  return (idx > 0)
    ? (idx % 4 == 3) ? YES : NO
    : NO;
}

/* actions */

- (id)cancel {
  [self leavePage];
  return nil;
}

- (void)_writeDefault:(NSString *)_key value:(id)_value ifTrue:(BOOL)_flag {
  NSNumber *uid;

  if (!_flag) return;
  
  uid = [self accountId];
  [self runCommand:@"userdefaults::write",
	  @"key",      _key,
	  @"value",    _value,
          @"defaults", self->defaults,
          @"userId",   uid,
	nil];
}

//######READ#####
- (void)_readDefault:(NSString *)_key value:(id)_value ifTrue:(BOOL)_flag {
  NSNumber *uid;

  if (!_flag) return;
  
  uid = [self accountId];
  [self runCommand:@"userdefaults::read",
	  @"key",      _key,
	  @"value",    _value,
          @"defaults", self->defaults,
          @"userId",   uid,
	nil];
}
//##############
//#########DELEGATION#####
//PRIVE
- (void)_delegRdvPrivDefault:(NSString *)_key value:(id)_value ifTrue:(BOOL)_flag {
  NSNumber *uid;

  if (!_flag) return;
  
  uid = [self accountId];
  [self runCommand:@"userdefaults::delegRdvPriv",
	  @"key",      _key,
	  @"value",    _value,
          @"defaults", self->defaults,
          @"userId",   uid,
	nil];
  //[self runCommand:@"appointment::get-delegation",nil];
}

//CONFIDENTIEL
- (void)_delegRdvConfDefault:(NSString *)_key value:(id)_value ifTrue:(BOOL)_flag {
  NSNumber *uid;

  if (!_flag) return;
  
  uid = [self accountId];
  [self runCommand:@"userdefaults::delegRdvConf",
	  @"key",      _key,
	  @"value",    _value,
          @"defaults", self->defaults,
          @"userId",   uid,
	nil];
}

//NORMAL
- (void)_delegRdvNormDefault:(NSString *)_key value:(id)_value ifTrue:(BOOL)_flag {
  NSNumber *uid;

  if (!_flag) return;
  
  uid = [self accountId];
  [self runCommand:@"userdefaults::delegRdvNorm",
	  @"key",      _key,
	  @"value",    _value,
          @"defaults", self->defaults,
          @"userId",   uid,
	nil];
}

//PUBLIC
- (void)_delegRdvPubliDefault:(NSString *)_key value:(id)_value ifTrue:(BOOL)_flag {
  NSNumber *uid;

  if (!_flag) return;
  
  uid = [self accountId];
  [self runCommand:@"userdefaults::delegRdvPubli",
	  @"key",      _key,
	  @"value",    _value,
          @"defaults", self->defaults,
          @"userId",   uid,
	nil];
}
/*################### COMMENTS BY TD ########################################
** AJout des Id de la delegation dans la table schedulerDelegation
** recupere la valeur du formulaire et le met dans un tableau 

- (void) DelegDansTableau {
      id pref;
      pref = [self snapshot];
      //idNormal = [[NSArray] alloc initWithObject :@"delegate_companyId"];
      [self logWithFormat:@"###snapshot avec les prÈfÈrences :%@",pref];
      [pref  takeValue:self->delegRdvNorm forKey:@"idNormal"];
      [pref  takeValue:self->delegRdvPriv forKey:@"idPrivate"];
      [pref  takeValue:self->delegRdvPubli forKey:@"idPublic"];
      [pref  takeValue:self->delegRdvConf forKey:@"idConfidential"];
}
################### COMMENTS BY TD ########################################*/

- (void) saveDelegation
{
	//id anObject = nil;
	id aValue = nil;

	NSMutableArray    * result   = [[NSMutableArray alloc]initWithCapacity:16];
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSMutableDictionary   * dico = [[NSMutableDictionary alloc] init];
	NSMutableArray * idPrivate = [[NSMutableArray alloc] initWithCapacity:[self->selectedDelegRdvPriv count]];
	NSMutableArray * idConfidential = [[NSMutableArray alloc] initWithCapacity:[self->selectedDelegRdvConf count]];
	NSMutableArray * idNormal = [[NSMutableArray alloc] initWithCapacity:[self->selectedDelegRdvNorm count]];
	NSMutableArray * idPublic = [[NSMutableArray alloc] initWithCapacity:[self->selectedDelegRdvPubli count]];

	[self logWithFormat:@"########### sauvegarde des delegations (DEBUT) #################"];

	//**********************
	// process Private array
	//**********************
	
	NSEnumerator * enumerator = [self->selectedDelegRdvPriv objectEnumerator];

	while( (aValue = [enumerator nextObject]) )
	{
		[self logWithFormat:@"### PRIVATE : aValue = %@",aValue];
		if (aValue !=nil)
		    [idPrivate addObject:[aValue valueForKey:@"companyId"]];
	        
	}

	[dico setObject:idPrivate     forKey:@"idPrivate"];
	// never do this things with the OGo libFoundation !!!!!!
	// [enumerator release];

	//**********************
	// process Confidential array
	//**********************
	
	enumerator = [selectedDelegRdvConf objectEnumerator];

	while( (aValue = [enumerator nextObject]) )
	{
		[self logWithFormat:@"### CONFIDENTIAL : aValue = %@",aValue];
		if (aValue !=nil)
		    [idConfidential addObject:[aValue valueForKey:@"companyId"]];
		
	}

	[dico setObject:idConfidential forKey:@"idConfidential"];

	//**********************
	// process Normal array
	//**********************
	
	enumerator = [selectedDelegRdvNorm objectEnumerator];

	while( (aValue = [enumerator nextObject]) )
	{
		[self logWithFormat:@"### NORMAL : aValue = %@",aValue];
		if (aValue !=nil)
		    [idNormal addObject:[aValue valueForKey:@"companyId"]];
	
		
	}

	[dico setObject:idNormal forKey:@"idNormal"];

	//**********************
	// process Public array
	//**********************
	
	enumerator = [selectedDelegRdvPubli objectEnumerator];

	while( (aValue = [enumerator nextObject]) )
	{
		[self logWithFormat:@"### PUBLIC : aValue = %@",aValue];
		if (aValue !=nil)
		    [idPublic addObject:[aValue valueForKey:@"companyId"]];
		
	}


	[dico setObject:idPublic forKey:@"idPublic"];
	
	[self logWithFormat:@"###dico pour la delegation: %@",dico];
	result = [self runCommand:@"appointment::set-delegation",@"dictDelegation",dico,nil];

	[idPrivate release];
	[idConfidential release];
	[idNormal release];
	[idPublic release];

	idPrivate 	 =nil;
	idConfidential   =nil;
	idNormal 	 =nil;
	idPublic 	 =nil;
	[pool release];

	[self logWithFormat:@"########### sauvegarde des delegations (FIN) #################"];
}

- (void) getIdDelegation
{
	NSMutableArray  *result;
	NSEnumerator 	*enumerator;	
	NSMutableString *descriptionIdNormal = nil;
	id  		personDeleg 	     = nil; 
	id 		attribut	     = nil;
        NSDictionary   *dico;
	result   = [[NSMutableArray alloc]initWithCapacity:16];
        	
	[self logWithFormat:@"########### getId dans LSWPreferences des delegations (DEBUT) #################"];
	
	//RÈcuparation les valeurs du et on stock les donnÈes dans un tableau 
	result = [self runCommand:@"appointment::get-delegation",nil];
	enumerator = [result objectEnumerator];
	
	if (result !=nil){
		//traitement des donnÈes afin d'obtenir la description  du compte grace au companyId
		while ((personDeleg = [enumerator nextObject])){
		        attribut = [personDeleg valueForKey:@"idNormal"];
			attribut = [self runCommand:@"person::get",@"companyId",descriptionIdNormal,nil];				
			attribut = [attribut valueForKey:@"description"];
			[self logWithFormat:@"dans LSWSchedulerPreferences description de la personne :%@",descriptionIdNormal];
		}
	}
	[self logWithFormat:@"########### getId dans LSWPreferences des delegations (FIN) #################"];
	
	//RÈcuparation les valeurs du et on stock les donnÈes dans un tableau
        dico= [[NSMutableDictionary alloc]init];
	dico= [self runCommand:@"appointment::get-delegation",nil];
	//result = [self runCommand:@"appointment::set-delegation",@"dictDelegation",dico,nil];
	
	//enumerator = [result objectEnumerator];
	
	/*if (result !=nil){
		//traitement des donnÈes afin d'obtenir la description  du compte grace au companyId
		while ((personDeleg = [enumerator nextObject])){
		        attribut = [personDeleg valueForKey:@"idNormal"];
			attribut = [self runCommand:@"person::get",@"companyId",descriptionIdNormal,nil];				
			attribut = [attribut valueForKey:@"description"];
			[self logWithFormat:@"dans LSWSchedulerPreferences description de la personne :%@",descriptionIdNormal];
		}
	}*/
	[self logWithFormat:@"########### setId dans LSWPreferences des delegations (FIN) #################"];
}

//#############

- (void)addIDsOfObjects:(NSArray *)_objects 
  toPersonIdArray:(NSMutableArray *)pIds
  andTeamIdArray:(NSMutableArray *)tIds
{
  NSEnumerator *enumerator;
  id obj;

  enumerator = [_objects objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    EOKeyGlobalID *gid;
    
    gid = [obj valueForKey:@"globalID"];
    if ([[gid entityName] isEqualToString:@"Person"])
      [pIds addObject:[obj valueForKey:@"companyId"]];
    else if ([[gid entityName] isEqualToString:@"Team"])
      [tIds addObject:[obj valueForKey:@"companyId"]];        
    else
      [self logWithFormat:@"ERROR: got unexpected obj: %@", obj];
  }
}

- (void)writeParticipants:(NSArray *)_objects 
  toPersonsDefault:(NSString *)_pdef andTeamsDefault:(NSString *)_tdef
{
  NSMutableArray *pIds;
  NSMutableArray *tIds;
  NSNumber       *uid;

  pIds = [[NSMutableArray alloc] init];
  tIds = [[NSMutableArray alloc] init];
  
  [self addIDsOfObjects:_objects toPersonIdArray:pIds andTeamIdArray:tIds];
  
  uid = [self accountId];
  [self runCommand:@"userdefaults::write",
	@"key",          _pdef,
	@"value",        pIds,
	@"userdefaults", self->defaults,
	@"userId",       uid, nil];
  [self runCommand:@"userdefaults::write",
	@"key",          _tdef,
	@"value",        tIds,
	@"userdefaults", self->defaults,
	@"userId",       uid, nil];
  [pIds release]; pIds = nil;
  [tIds release]; tIds = nil;
}

//#######READ######
- (void)readParticipants:(NSArray *)_objects 
  toPersonsDefault:(NSString *)_pdef andTeamsDefault:(NSString *)_tdef
{
  NSMutableArray *personIds;
  NSMutableArray *teamIds;
  NSNumber       *uid;

  personIds = [[NSMutableArray alloc] init];
  teamIds = [[NSMutableArray alloc] init];
  
  [self addIDsOfObjects:_objects toPersonIdArray:personIds andTeamIdArray:teamIds];
  
  uid = [self accountId];
  [self runCommand:@"userdefaults::read",
	@"key",          _pdef,
	@"value",        personIds,
	@"userdefaults", self->defaults,
	@"userId",       uid, nil];
  [self runCommand:@"userdefaults::read",
	@"key",          _tdef,
	@"value",        teamIds,
	@"userdefaults", self->defaults,
	@"userId",       uid, nil];
  [personIds release]; personIds = nil;
  [teamIds release]; teamIds = nil;
}
//##################
//#######DELEGATION######
- (void)delegRdvPrivParticipants:(NSArray *)_objects 
  toPersonsDefault:(NSString *)_pdef andTeamsDefault:(NSString *)_tdef
{
  NSMutableArray *personIds;
  NSMutableArray *teamIds;
  NSNumber       *uid;

  personIds = [[NSMutableArray alloc] init];
  teamIds = [[NSMutableArray alloc] init];
  
  [self addIDsOfObjects:_objects toPersonIdArray:personIds andTeamIdArray:teamIds];
  
  uid = [self accountId];
  [self runCommand:@"userdefaults::delegRdvPriv",
	@"key",          _pdef,
	@"value",        personIds,
	@"userdefaults", self->defaults,
	@"userId",       uid, nil];
  [self runCommand:@"userdefaults::delegRdvPriv",
	@"key",          _tdef,
	@"value",        teamIds,
	@"userdefaults", self->defaults,
	@"userId",       uid, nil];
  [personIds release]; personIds = nil;
  [teamIds release]; teamIds = nil;
}
//##################
//
- (void)_saveRootDefaults {
  NSNumber *uid;
  
  if (!self->isRoot) 
    return;
  
  uid = [self accountId];
  [self runCommand:@"userdefaults::write",
            @"key", @"rootAccessscheduler_view",
            @"value", [NSNumber numberWithBool:self->isSchedulerViewEditable],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  [self runCommand:@"userdefaults::write",
            @"key", @"rootAccessscheduler_start_hour",
            @"value", [NSNumber numberWithBool:self->isStartHourEditable],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  [self runCommand:@"userdefaults::write",
            @"key", @"rootAccessscheduler_end_hour",
            @"value", [NSNumber numberWithBool:self->isEndHourEditable],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  [self runCommand:@"userdefaults::write",
            @"key", @"rootAccessscheduler_time_input_type",
            @"value", [NSNumber numberWithBool:self->isTimeInputTypeEditable],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  [self runCommand:@"userdefaults::write",
            @"key", @"rootAccessscheduler_apttype_input_type",
            @"value", [NSNumber numberWithBool:
                                self->isAptTypeInputTypeEditable],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  [self runCommand:@"userdefaults::write",
          @"key", @"rootAccessSkyAptNotifyDevices",
          @"value",
          [NSNumber numberWithBool:self->isNotificationDevicesEditable],
          @"defaults", self->defaults,
          @"userId",   uid,
          nil];
}

- (void)_saveHolidayDefaults {
  NSArray  *groupKeys;
  int      i, cnt;
  NSNumber *uid;

  uid       = [self accountId];
  groupKeys = [self->holidayGroups allKeys];

  for (i = 0, cnt = [groupKeys count]; i < cnt; i++) {
    NSString *key, *gKey, *showKey, *editableKey, *selectedKey;
    NSNumber *flag;
    BOOL     editable;

    key  = [groupKeys objectAtIndex:i];
    gKey = key;

    editableKey = [key stringByAppendingString:@"_editable"];
    editable    = [[self->holidayGroups objectForKey:editableKey] boolValue];

    if (!editable)
      continue;
    
    selectedKey = [key stringByAppendingString:@"_selected"];
    flag        = [self->holidayGroups objectForKey:selectedKey];
    showKey     = @"scheduler_show_holiday_";
    showKey     = [showKey stringByAppendingString:key];

    [self runCommand:@"userdefaults::write",
              @"key",      showKey,
              @"value",    flag,
              @"defaults", self->defaults,
              @"userId",   uid,
	  nil];
  }
   
  for (i = 0, cnt = [self->restHolidaysKeys count]; i < cnt; i++) {
    NSString *key, *showKey, *editableKey, *selectedKey;
    
    key         = [self->restHolidaysKeys objectAtIndex:i];
    editableKey = [key stringByAppendingString:@"_editable"];
    
    if (![[self->restHolidays objectForKey:editableKey] boolValue])
      continue;
    
    showKey     = @"scheduler_show_holiday_";
    showKey     = [showKey stringByAppendingString:key];
    selectedKey = [key stringByAppendingString:@"_selected"];
    
    [self runCommand:@"userdefaults::write",
	    @"key",      showKey,
	    @"value",    [self->restHolidays objectForKey:selectedKey],
            @"defaults", self->defaults,
            @"userId",   uid,
	  nil];
  }
}

- (void)_saveCustomHolidayLine:(NSString *)line
  toCustomHolidays:(NSMutableDictionary *)custom
  toCustomEveryYear:(NSMutableDictionary *)customEveryYear
{
  id       parts;
  NSString *dateKey, *label;
  
  parts = [line componentsSeparatedByString:@":"];
  if ([parts count] < 2)
    // TODO: print a warning: invalid input
    return;
    
  dateKey = [parts objectAtIndex:0];
  if ([parts count] > 2) {
    parts = [parts mutableCopy];
    [parts removeObjectAtIndex:0];
    label = [parts componentsJoinedByString:@""];
    [parts release];
  }
  else 
    label = [parts objectAtIndex:1];

  if ([label hasSuffix:@"\r"])
    label = [label substringToIndex:[label length]-1];

  if (dateKey == nil)
    return;

  parts = [dateKey componentsSeparatedByString:@"-"];
  if ([parts count] == 2) {
    // must be everyyear holiday
    id val;
    
    val = [customEveryYear objectForKey:dateKey];
    val = (val)
      ? [val stringByAppendingFormat:@", %@", label]
      : label;
    [customEveryYear setObject:val forKey:dateKey];
  }
  else if ([parts count] == 3) {
    // must be no everyyear holiday
    NSString            *year;
    NSMutableDictionary *days;
    id val;

    year = [parts objectAtIndex:0];
    days = [custom objectForKey:year];

    days = (days)
      ? [days mutableCopy]
      : [[NSMutableDictionary alloc] init];
    parts = [parts mutableCopy];

    [parts removeObjectAtIndex:0];
    dateKey = [parts componentsJoinedByString:@"-"];
    
    val = [days objectForKey:dateKey];
    val = (val)
      ? [val stringByAppendingFormat:@", %@", label]
      : label;
    [days setObject:val forKey:dateKey];
    [custom setObject:days forKey:year];
	
    [parts release];
    [days  release];
  }
}
- (void)_saveCustomHolidayDefaults {
  NSEnumerator *lines;
  NSString     *line;
  NSMutableDictionary *custom;
  NSMutableDictionary *customEveryYear;
  
  custom          = [NSMutableDictionary dictionaryWithCapacity:16];
  customEveryYear = [NSMutableDictionary dictionaryWithCapacity:16];
  
  lines = [[self->customHolidays componentsSeparatedByString:@"\n"]
	                         objectEnumerator];
  while ((line = [lines nextObject])) {
    [self _saveCustomHolidayLine:line
	  toCustomHolidays:custom
	  toCustomEveryYear:customEveryYear];
  }
  
  [self _writeDefault:@"scheduler_custom_holidays"
	value:custom
	ifTrue:[self _isEditable:@"scheduler_custom_holidays"]];
  [self _writeDefault:@"scheduler_custom_everyyear_holidays"
	value:customEveryYear
	ifTrue:[self _isEditable:@"scheduler_custom_everyyear_holidays"]];
}

- (void)_savePopUpResourceNames {
  NSEnumerator   *enumerator;
  NSMutableArray *r;
  NSString       *n, *s;
  NSNumber       *uid;

  uid = [self accountId];

  s = [[self labels] valueForKey:@"resCategory"];
  if (s == nil) s = @"resCategory";
    
  s = [NSString stringWithFormat:@"(%@)", s];
  r = [NSMutableArray arrayWithCapacity:8];
    
  enumerator = [self->resourceNames objectEnumerator];
  while ((n = [enumerator nextObject])) {
    if ([n hasSuffix:s]) {
      n = [[n  componentsSeparatedByString:@" ("] objectAtIndex:0];
      [r addObject:[NSString stringWithFormat:@"%@ (resCategory)", n]];
    }
    else 
      [r addObject:n];
  }
  
  [self runCommand:@"userdefaults::write",
          @"key",          @"scheduler_popup_resourceNames",
          @"value",        r,
          @"userdefaults", self->defaults,
          @"userId",       uid, nil];
}

- (id)save {
  // TODO: split up this huge method! this is a catastrophe!
  NSNumber *uid;

  uid = [self accountId];

  if ((self->defaultCCForNotificationMails == nil) ||
      (![self->defaultCCForNotificationMails isNotNull])) {
    [self runCommand:@"userdefaults::delete",
          @"key",      @"scheduler_ccForNotificationMails",
          @"defaults", self->defaults,
          @"userId",   uid,
          nil];
  }
  else {
    [self runCommand:@"userdefaults::write",
          @"key",      @"scheduler_ccForNotificationMails",
          @"value",    [self defaultCCForNotificationMails],
          @"defaults", self->defaults,
          @"userId",   uid,
          nil];
  } 

  [self _writeDefault:@"scheduler_view" value:[self schedulerView]
	ifTrue:[self isSchedulerViewEditable]];
  [self _writeDefault:@"absence_mode" value:[self absenceMode]
	ifTrue:[self isAbsenceModeEditable]];

  [self _writeDefault:@"scheduler_mail_template" value:[self mailTemplate]
	ifTrue:[self isMailTemplateEditable]];
  
  [self _writeDefault:@"scheduler_mail_template_date_format"
	value:[self templateDateFormat]
	ifTrue:[self isTemplateDateFormatEditable]];
  
  [self runCommand:@"userdefaults::write",
        @"key",      @"scheduler_attach_apts_to_mails",
        @"value",    [NSNumber numberWithBool:[self attachAppointments]],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];

  [self _writeDefault:@"scheduler_appointment_view" 
	value:[self appointmentView]
	ifTrue:[self isAppointmentViewEditable]];

  [self _writeDefault:@"scheduler_start_hour" value:[self startHour]
	ifTrue:[self isSchedulerStartHourEditable]];
  [self _writeDefault:@"scheduler_end_hour"   value:[self endHour]
	ifTrue:[self isSchedulerStartHourEditable]];

  [self _writeDefault:@"scheduler_weekchart_columnsperday"
	value:[self columnsPerDayWeekView]
	ifTrue:[self isWeekChartColumnsPerDayEditable]];

  [self _writeDefault:@"scheduler_daychart_columnsperday"
	value:[self columnsPerDayDayView]
	ifTrue:[self isDayChartColumnsPerDayEditable]];
  
  [self _writeDefault:@"scheduler_dayoverview_daystart"
	value:[self dayOverviewStartHour]
	ifTrue:[self isDayOverviewStartHourEditable]];

  [self _writeDefault:@"scheduler_dayoverview_dayend"
	value:[self dayOverviewEndHour]
	ifTrue:[self isDayOverviewEndHourEditable]];

  [self _writeDefault:@"scheduler_dayoverview_timeinterval"
	value:[self dayOverviewInterval]
	ifTrue:[self isDayOverviewIntervalEditable]];

  [self _writeDefault:@"scheduler_time_input_type"
	value:[self schedulerTimeInputType]
	ifTrue:[self isSchedulerTimeInputTypeEditable]];

  [self _writeDefault:@"scheduler_apttype_input_type"
	value:[self schedulerAptTypeInputType]
	ifTrue:[self isSchedulerAptTypeInputTypeEditable]];

  [self _writeDefault:@"scheduler_no_of_cols" value:[self noOfCols]
	ifTrue:[self isNoOfColsEditable]];
  
  [self runCommand:@"userdefaults::write",
        @"key",      @"scheduler_additional_popup_entries",
        @"value",    [NSNumber numberWithInt:self->additionalPopupEntries],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];

  [self runCommand:@"userdefaults::write",
        @"key",      @"scheduler_overview_short_info",
        @"value",    [NSNumber numberWithBool:[self shortInfo]],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];

  [self runCommand:@"userdefaults::write",
        @"key",      @"scheduler_overview_with_resources",
        @"value",    [NSNumber numberWithBool:[self withResources]],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];

  [self runCommand:@"userdefaults::write",
        @"key",      @"scheduler_hide_ignore_conflicts",
        @"value",    [NSNumber numberWithBool:[self hideIgnoreConflicts]],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];

  [self runCommand:@"userdefaults::write",
        @"key",      @"schedulerpage_tab",
        @"value",    [self schedulerPageTab],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];
  [self runCommand:@"userdefaults::write",
        @"key",      @"schedulerpage_weekview",
        @"value",    [self schedulerPageWeekView],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];
  [self runCommand:@"userdefaults::write",
        @"key",      @"schedulerpage_dayview",
        @"value",    [self schedulerPageDayView],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];

  [self runCommand:@"userdefaults::write",
        @"key",      @"scheduler_show_jobs",
        @"value",    [NSNumber numberWithBool:[self showTodos]],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];
  [self runCommand:@"userdefaults::write",
        @"key",      @"scheduler_show_palm_dates",
        @"value",    [NSNumber numberWithBool:[self showPalmDates]],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];
  [self runCommand:@"userdefaults::write",
        @"key",      @"scheduler_overview_full_names",
        @"value",    [NSNumber numberWithBool:[self showFullNames]],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];

  if ([self isNotificationDevicesEditable]) {
    [self runCommand:@"userdefaults::write",
          @"key",      @"SkyAptNotifyDevices",
          @"value",    [self notificationDevices],
          @"defaults", self->defaults,
          @"userId",   uid,
          nil];
  }
  
  [self _savePopUpResourceNames];
  
  [self writeParticipants:self->selectedParticipants
	toPersonsDefault:@"scheduler_popup_persons"
	andTeamsDefault:@"scheduler_popup_teams"];

  [self writeParticipants:self->selectedWriteAccess
	toPersonsDefault:@"scheduler_write_access_accounts"
	andTeamsDefault:@"scheduler_write_access_teams"];
//###ADDED BY AO###
 //####ajout dans le fichier user.default##### 
  [self writeParticipants:self->selectedReadAccess
	toPersonsDefault:@"scheduler_read_access_accounts"
	andTeamsDefault:@"scheduler_read_access_teams"];
  
  [self writeParticipants:self->selectedDelegRdvPriv
	toPersonsDefault:@"scheduler_deleg_rdv_priv_accounts"
	andTeamsDefault:@"scheduler_deleg_rdv_priv_teams"];
  
  [self writeParticipants:self->selectedDelegRdvPubli
	toPersonsDefault:@"scheduler_deleg_rdv_publi_accounts"
	andTeamsDefault:@"scheduler_deleg_rdv_publi_teams"];
  
  [self writeParticipants:self->selectedDelegRdvConf
	toPersonsDefault:@"scheduler_deleg_rdv_conf_accounts"
	andTeamsDefault:@"scheduler_deleg_rdv_conf_teams"];
  
  [self writeParticipants:self->selectedDelegRdvNorm
	toPersonsDefault:@"scheduler_deleg_rdv_norm_accounts"
	andTeamsDefault:@"scheduler_deleg_rdv_norm_teams"];
  
  
  if (self->isRoot) [self _saveRootDefaults];
  
  /* holiday stuff */
  [self _saveHolidayDefaults];
  
  /* custom holidays */
  [self _saveCustomHolidayDefaults];

  [self postChange:LSWUpdatedAccountNotificationName onObject:[self account]];

  //Ajout de la delegation
  [self getIdDelegation];
  [self saveDelegation];
  
  return [self leavePage];
}

- (NSString *)bindingLabel {
  NSString *l;
  
  l = [[self labels] valueForKey:[self valueForKey:@"binding"]];
  return l ? l : [self valueForKey:@"binding"];
}

- (NSArray *)bindingValues {
  return [[(id)[self session] userDefaults]
                 arrayForKey:@"scheduler_mail_binding_values"];
}

@end /* LSWSchedulerPreferences */
