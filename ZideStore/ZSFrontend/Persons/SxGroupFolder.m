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
// $Id: SxGroupFolder.m 1 2004-08-20 11:17:52Z znek $

#include "SxGroupFolder.h"
#include "common.h"
#include <Backend/SxContactManager.h>

@interface NSObject(IsOverview)
- (void)setIsOverview:(BOOL)_flag;
@end /* NSObject(IsOverview) */

@implementation SxGroupFolder

static BOOL showGroupOverviewFolders = -1;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  showGroupOverviewFolders = [ud boolForKey:@"ZLShowGroupOverviewCalendars"];
  if (showGroupOverviewFolders) {
    [self logWithFormat:
            @"group overview folders are turned on, this may "
            @"affect your systems performance !"];
  }
}

- (NSString *)entity {
  return @"Person";
}

/* folders */

- (id)calendarFolder:(NSString *)_key inContext:(id)_ctx {
  id folder;
  folder = [[NSClassFromString(@"SxAppointmentFolder") alloc] 
	     initWithName:_key inContainer:self];
  [folder takeValue:[self nameInContainer] forKey:@"group"];
  return [folder autorelease];
}
- (id)overviewFolder:(NSString *)_key inContext:(id)_ctx {
  id folder;
  folder = [[NSClassFromString(@"SxAppointmentFolder") alloc] 
	     initWithName:_key inContainer:self];
  [folder takeValue:[self nameInContainer] forKey:@"group"];
  [folder setIsOverview:YES];
  return [folder autorelease];
}
- (id)taskFolder:(NSString *)_key inContext:(id)_ctx {
  id folder;
  folder = [[NSClassFromString(@"SxTaskFolder") alloc] 
	     initWithName:_key inContainer:self];
  [folder takeValue:[self nameInContainer] forKey:@"group"];
  return [folder autorelease];
}

/* lookup */

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  if ([_key isEqualToString:@"Calendar"])
    return [self calendarFolder:_key inContext:_ctx];
  if ([_key isEqualToString:@"Overview"])
    return [self overviewFolder:_key inContext:_ctx];
  if ([_key isEqualToString:@"Tasks"])
    return [self taskFolder:_key inContext:_ctx];
  
  return [super lookupName:_key inContext:_ctx acquire:_flag];
}

/* queries */

- (SxContactSetIdentifier *)contactSetID {
  return nil;
}
  
- (BOOL)davHasSubFolders { 
  return YES; 
}

- (NSEnumerator *)runListQueryWithContactManager:(SxContactManager *)_cm {
  // TODO: deliver subfolders
  [self logWithFormat:@"group-folder should deliver subfolders ..."];
  return [_cm listAccountsForGroup:[self nameInContainer]];
}

- (NSEnumerator *)runEvoQueryWithContactManager:(SxContactManager *)_cm 
  prefix:(NSString *)_prefix
{
  return [_cm evoAccountsForGroup:[self nameInContainer] prefix:_prefix];
}

- (BOOL)isPublicGroupFolder {
  return [[self nameInContainer] isEqualToString:@"all intranet"];
}

- (BOOL)canHaveOverviewSubfolder {
  return showGroupOverviewFolders && ![self isPublicGroupFolder];
}

- (id)performEvoSubFolderQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  // outlookFolderClass, unreadcount, davDisplayName, davHasSubFolders
  // TODO
  // this is fixed [BUT URL !], give back "Calendar", "Tasks"
  //static unsigned showGroupOverviewCalendar = -1;
  NSMutableArray *ma;
  NSString     *burl, *url;
  NSDictionary *entry;
  NSString *keys[8];
  id  vals[8];
  int p;

#if 0
  if (showGroupOverviewCalendar == -1) {
    NSUserDefaults *ud        = [NSUserDefaults standardUserDefaults];
    showGroupOverviewCalendar =
      [ud boolForKey:@"ZLShowGroupOverviewCalendars"];
  }
#endif

  burl = [self baseURLInContext:_ctx];
  ma = [NSMutableArray arrayWithCapacity:3];
  
  url = [burl stringByAppendingString:@"Calendar"];
  p = 0;
  keys[p] = @"{DAV:}href";         vals[p] = url; p++;
  keys[p] = @"outlookFolderClass"; vals[p] = @"IPF.Appointment"; p++;
  keys[p] = @"unreadcount";        vals[p] = @"0";        p++;
  keys[p] = @"davHasSubFolders";   vals[p] = @"0";        p++;
  //vals[p] = showGroupOverviewCalendar ? @"1" : @"0";      p++;
  keys[p] = @"cdoFolderTypeCode";  vals[p] = @"1";        p++;
  keys[p] = @"davDisplayName";     vals[p] = @"Calendar"; p++;
  entry = [[NSDictionary alloc] initWithObjects:vals forKeys:keys count:p];
  [ma addObject:entry];
  [entry release];

  if ([self canHaveOverviewSubfolder]) {
    url = [burl stringByAppendingString:@"Overview"];
    p = 0;
    keys[p] = @"{DAV:}href";         vals[p] = url; p++;
    keys[p] = @"outlookFolderClass"; vals[p] = @"IPF.Appointment"; p++;
    keys[p] = @"unreadcount";        vals[p] = @"0";        p++;
    keys[p] = @"davHasSubFolders";   vals[p] = @"0";        p++;
    keys[p] = @"cdoFolderTypeCode";  vals[p] = @"1";        p++;
    keys[p] = @"davDisplayName";     vals[p] = @"Overview"; p++;
    entry = [[NSDictionary alloc] initWithObjects:vals forKeys:keys count:p];
    [ma addObject:entry];
    [entry release];
  }
  
  url = [burl stringByAppendingString:@"Tasks"];
  p = 0;
  keys[p] = @"{DAV:}href";         vals[p] = url; p++;
  keys[p] = @"outlookFolderClass"; vals[p] = @"IPF.Task"; p++;
  keys[p] = @"unreadcount";        vals[p] = @"0";        p++;
  keys[p] = @"davHasSubFolders";   vals[p] = @"0";        p++;
  keys[p] = @"cdoFolderTypeCode";  vals[p] = @"1";        p++;
  keys[p] = @"davDisplayName";     vals[p] = @"Tasks";    p++;
  entry = [[NSDictionary alloc] initWithObjects:vals forKeys:keys count:p];
  [ma addObject:entry];
  [entry release];
  
  return [ma objectEnumerator];
}

- (id)performMsgInfoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* the second query by ZideLook, get basic message infos */
  /* davDisplayName,davResourceType,outlookMessageClass,cdoDisplayType */
  [self logWithFormat:
          @"ZL Group Messages Query [depth=%@]: %@",
          [[_ctx request] headerForKey:@"depth"],
          [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  return [NSArray array];
}

- (NSDictionary *)_newFolderDict:(NSString *)_name baseURL:(NSString *)_burl
  folderClass:(NSString *)_fclass
{
  NSString *url;
  NSString *keys[10];
  id  vals[10];
  id  access;
  int p;
  
  url    = [_burl stringByAppendingString:_name];
  access = [self cdoAccess]; // TODO: use flags of target ...
  p = 0;
  keys[p] = @"{DAV:}href";         vals[p] = url;           p++;
  keys[p] = @"davResourceType";    vals[p] = @"collection"; p++;
  keys[p] = @"outlookFolderClass"; vals[p] = _fclass;     p++;
  keys[p] = @"unreadcount";        vals[p] = @"0";        p++;
  keys[p] = @"davHasSubFolders";   vals[p] = @"0";        p++;
  keys[p] = @"davDisplayName";     vals[p] = _name;       p++;
  keys[p] = @"cdoFolderTypeCode";  vals[p] = @"1";        p++;
  keys[p] = @"cdoAccess";          vals[p] = access;      p++;
  return [[NSDictionary alloc] initWithObjects:vals forKeys:keys count:p];
}

- (id)performSubFolderQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* the third query by ZideLook, get all subfolder infos */
  /*
    davDisplayName,davResourceType,cdoDepth,cdoParentDisplay,cdoRowType,
    cdoAccess,cdoContainerClass,cdoContainerHierachy,cdoContainerContents,
    davDisplayName,cdoDisplayType,outlookFolderClass
  */
  NSMutableArray *ma;
  NSString     *burl;
  NSDictionary *entry;
  
  burl = [self baseURLInContext:_ctx];
  ma = [NSMutableArray arrayWithCapacity:3];
  
  entry = [self _newFolderDict:@"Calendar" baseURL:burl 
                folderClass:@"IPF.Appointment"];
  [ma addObject:entry];
  [entry release];
  
  if ([self canHaveOverviewSubfolder]) {
    entry = [self _newFolderDict:@"Overview" baseURL:burl 
                  folderClass:@"IPF.Appointment"];
    [ma addObject:entry];
    [entry release];
  }

  entry = [self _newFolderDict:@"Tasks" baseURL:burl 
                folderClass:@"IPF.Task"];
  [ma addObject:entry];
  [entry release];
  
  return [ma objectEnumerator];
}

- (NSArray *)davQueryOnSelf:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  // TODO: check whether group exists
  //       use a timed cache for keeping a black and white list of group
  //       names
  
  if ([self doExplainQueries]) {
    [self debugWithFormat:
            @"Deliver group, should check whether group '%@' exists: %@",
            [self nameInContainer],
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  }
  return [super davQueryOnSelf:_fs inContext:_ctx];
}

@end /* SxGroupFolder */
