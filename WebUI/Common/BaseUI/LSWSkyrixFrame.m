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
// $Id: LSWSkyrixFrame.m 1 2004-08-20 11:17:52Z znek $

#include <OGoFoundation/OGoComponent.h>

@class NSArray, NSMutableArray;

@interface LSWSkyrixFrame : OGoComponent
{
  BOOL isRoot;
@private
  int idx;
  id  item; // non-retained

  /* dock stuff */
  NSArray *dockedPages;

  /* tmp */
  NSMutableArray *dndSelection;
}

- (BOOL)isInternetExplorer;

@end /* LSWSkyrixFrame */

#include <WEExtensions/WEClientCapabilities.h>
#include <OGoFoundation/LSWEditorPage.h>
#include "common.h"

#define LSWSkyrixFrame_CtxKey @"__LSWSkyrixFrame"

@interface WORequest(UsedPrivates)
- (NSCalendarDate *)startDate;
@end

@implementation LSWSkyrixFrame

static NSNumber *yesNum = nil;
static int  Timeout          = -1;
static int  editTimeOut      = -1;
static BOOL showTimings      = NO;
static BOOL debugDnD         = NO;
static BOOL debugPageRefresh = NO;

+ (int)version {
  return 2;
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  if (didInit) return;
  didInit = YES;
  
  showTimings      = [ud boolForKey:@"SkyShowPageTimings"];
  debugDnD         = [ud boolForKey:@"OGoDebugDnD"];
  debugPageRefresh = [ud boolForKey:@"OGoDebugPageRefresh"];
  
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  
  Timeout = [[ud objectForKey:@"SkyPageRefreshTimeout"] intValue];
  if (Timeout <= 0) {
    Timeout = [[WOApplication sessionTimeOut] intValue];
    Timeout = (Timeout < 300) ? 300 : (Timeout - 300);
  }
  
  editTimeOut = [[ud objectForKey:@"SkyEditorPageTimeOut"] intValue];
  if (editTimeOut <= 0) {
    editTimeOut = Timeout;
    if (editTimeOut < 3600)
      editTimeOut = 3600; /* at least one hour */
  }
  
  if (debugPageRefresh)
    NSLog(@"OGoDebugPageRefresh: timeout=%is edit=%is", Timeout, editTimeOut);
}

- (void)dealloc {
  [self->dockedPages release];
  
  /* tmp */ // hh: what does the comment say ??
  [self->dndSelection release];
  [super dealloc];
}

/* notifications */

- (void)awake {
  [super awake];
  self->isRoot = [[self session] activeAccountIsRoot];
}

- (void)sleep {
  self->item = nil;
  [super sleep];
}

/* error strings */

- (BOOL)pageHasErrorToShow {
  return [[[[self context] page] valueForKey:@"hasErrorString"] boolValue];
}
- (BOOL)showErrorBar {
  return [self pageHasErrorToShow];
}

- (BOOL)shouldEscapePanelErrorString {
  /*
    For Mozilla we cannot escape the parameter of the JavaScript popup, it
    will show the HTML entities.
    TODO: find out what is correct here and whether other browsers show
          the same behaviour.
  */
  WEClientCapabilities *ccaps;
  
  if ((ccaps = [[[self context] request] clientCapabilities]) == nil)
    return YES;

  if ([ccaps isMozilla])
    return NO;
  
  return YES;
}
- (NSString *)panelErrorString {
  NSString *errorString;
  
  errorString = [[[self context] page] valueForKey:@"errorString"];
  if ([errorString length] == 0) return nil;

  if ([errorString rangeOfString:@"\n"].length > 0) {
    errorString = [[errorString componentsSeparatedByString:@"\n"]
                                componentsJoinedByString:@"\\n"];
  }
  if ([errorString rangeOfString:@"\""].length > 0) {
    errorString = [[errorString componentsSeparatedByString:@"\""]
                                componentsJoinedByString:@"'"];
  }
  return errorString;
}

/* confirm strings */

- (BOOL)pageHasConfirmToShow {
  return ([[[self context] page] valueForKey:@"confirmString"] != nil);
}
- (BOOL)showConfirmBar {
  return [self pageHasConfirmToShow];
}

- (NSString *)panelConfirmString {
  NSString *confirmString;

  confirmString = [[[self context] page] valueForKey:@"confirmString"];
  if ([confirmString length] == 0) return nil;

  if ([confirmString rangeOfString:@"\n"].length > 0) {
    confirmString = [[confirmString componentsSeparatedByString:@"\n"]
                                    componentsJoinedByString:@"\\n"];
  }
  if ([confirmString rangeOfString:@"\""].length > 0) {
    confirmString = [[confirmString componentsSeparatedByString:@"\""]
                                    componentsJoinedByString:@"'"];
  }
  return confirmString;
}

- (id)confirmAction {
  id       page       = [[self context] page];
  NSString *actionStr = [page valueForKey:@"confirmAction"];

  if ([actionStr length] == 0)
    return nil;
  else if ([page respondsToSelector:NSSelectorFromString(actionStr)])
    return [page performSelector:NSSelectorFromString(actionStr)];
  else
    return nil;
}


/* URLs */

- (NSString *)urlForResourceNamed:(NSString *)_name {
  WOResourceManager *rm;
  NSString *url;
  NSArray  *langs;

  langs = [self hasSession]
    ? [[self session] languages]
    : [[[self context] request] browserLanguages];
  
  rm = [[self application] resourceManager];
  url = [rm urlForResourceNamed:_name inFramework:nil
	    languages:langs request:[[self context] request]];
  return url;
}

- (NSString *)shortcutLink {
  return [NSString stringWithFormat:
                     @"<link rel=\"shortcut icon\" href=\"%@\" />",
                     [self urlForResourceNamed:@"favicon.ico"]];
}
- (NSString *)stylesheetURL {
  return [self urlForResourceNamed:@"OGo.css"];
}

- (NSString *)coloredScrollBars {
  // TODO: uses "config" mechanism
  // TODO: use a references stylesheet ?
  id cfg;
  
  cfg = [self valueForKey:@"config"];
  return [NSString stringWithFormat:
                   @"<style type=\"text/css\">\n"
                   @"<!--\n"
                   @"BODY {\n"
                   @"scrollbar-face-color:%@;\n"
                   @"scrollbar-arrow-color:%@;\n"
                   @"scrollbar-track-color:%@;\n"
                   @"scrollbar-3dlight-color:%@;\n"
                   @"scrollbar-darkshadow-color:%@;\n"
                   @"}\n"
                   @"-->\n"
                   @"</style>",
                   [cfg valueForKey:@"colors_headerCell"],
                   [cfg valueForKey:@"colors_textColor"],
                   [cfg valueForKey:@"colors_bgColor"],
                   @"#ffffff",
                   @"#000000"];
}

/* expiration */

- (id)expirePage {
  /* keeps the session alive */
  // TODO: this should be done using a direct action !
  id page;
  
  if (![self hasSession]) {
    [self debugWithFormat:@"expirePage called, but no session active ?"];
    return nil;
  }
  
  if (debugPageRefresh) [self logWithFormat:@"expire page called ..."];
  page = [[[self session] navigation] activePage];
  if (debugPageRefresh) [self logWithFormat:@"  page: %@", page];
  return page;
}
- (int)pageExpireTimeout {
  return Timeout;
}

- (BOOL)pageIsExpirable {
  return [[[self context] page] isEditorPage] ? NO : YES;
}

- (NSTimeInterval)activeSessionTimeOut {
  return [self pageIsExpirable]
    ? [[WOApplication sessionTimeOut] intValue]
    : editTimeOut;
}

- (NSString *)sessionExpireInfo {
  static int showAMPM = -1;
  NSCalendarDate *d;
  NSTimeZone     *tz;

  if (showAMPM == -1) {
    id ud = [[self session] userDefaults];
    showAMPM = [ud boolForKey:@"scheduler_AMPM_dates"] ? 1 : 0;
  }
  
  tz = [[self session] timeZone];
  d  = [NSCalendarDate dateWithTimeIntervalSinceNow:
                         [self activeSessionTimeOut]];
  [d setTimeZone:tz];
  if (showAMPM) {
    int  hour;
    BOOL am = YES;
    hour = [d hourOfDay];
    if (hour > 11) am = NO;
    hour = hour % 12;
    if (!hour) hour = 12;
    return [NSString stringWithFormat:@"%02i:%02i %@ %@",
                   hour, [d minuteOfHour], am ? @"AM" : @"PM",
                     [tz abbreviation]];
  }
  return [NSString stringWithFormat:@"%02i:%02i %@",
                   [d hourOfDay], [d minuteOfHour], [tz abbreviation]];
}

/* actions */

- (id)logout {
  NSUserDefaults *ud;
  BOOL logLogout;
  
  ud = [[self session] userDefaults];
  logLogout = [[ud objectForKey:@"LSSessionAccountLogEnabled"] boolValue];
  if (logLogout) {
    id account = [[self session] activeAccount];
    [[self session] runCommand:@"sessionlog::add",
                    @"account", account,
                    @"action",  @"logout", nil];
  }
  [[self session] terminate];
  return [[self application] pageWithName:@"OGoLogoutPage"];
}

- (id)clearErrorString {
  [[[self context] page] takeValue:nil forKey:@"errorString"];
  return nil;
}

- (id)newFavoriteDropped {
  static Class EOGenericRecordClass = Nil;
  id object;

  object = [self valueForKey:@"newFavoriteObject"];
  if (debugDnD)
    [self logWithFormat:@"dropped object %@", object];
  
  if (EOGenericRecordClass == Nil)
    EOGenericRecordClass = [EOGenericRecord class];
  
  if (![object isKindOfClass:EOGenericRecordClass])
    //object = [object valueForKey:@"globalID"];
    ;
  
  if (object == nil)
    return nil;
  
  [[self session] addFavorite:object];
  return nil;
}

- (id)deleteDroppedObject {
  id obj;

  obj = [self valueForKey:@"droppedObject"];
  if ([obj isKindOfClass:[NSDictionary class]]) {
    id tmp;

    tmp = [obj valueForKey:@"globalID"];
    obj = ([tmp isNotNull]) ? tmp : obj;
  }
  
  return [self activateObject:obj withVerb:@"delete"];
}

- (BOOL)showTrash {
  WEClientCapabilities *ccaps;
  
  if ((ccaps = [[[self context] request] clientCapabilities]) == nil)
    return NO;

  return [ccaps doesSupportDHTMLDragAndDrop];
}

- (int)colspanDependingOnTrash {
  return (![self showTrash]) ? 2 : 1;
}

/* common accessors */

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (void)setIndex:(int)_idx {
  self->idx = _idx;
}
- (int)index {
  return self->idx;
}

- (BOOL)isRoot {
  return self->isRoot;
}

- (BOOL)smallFont {
  WEClientCapabilities *ccaps;
  
  if ((ccaps = [[[self context] request] clientCapabilities]) == nil)
    return NO;

  if ([ccaps isX11Browser]) {
    if ([ccaps isNetscape])
      return NO;
    if ([ccaps isMozilla])
      return NO;
  }
  return YES;
}

/* navigation */

- (BOOL)isNavLinkClickable {
  int count;
  count = [[[(OGoSession *)[self session] navigation] pageStack] count];
  return (self->idx == (count - 1)) ? NO : YES;
}

- (id)navigate { // a navigation link was clicked
  id            newPage;
  NSArray       *pageStack;
  OGoNavigation *navigation;
  
  navigation = [(OGoSession *)[self session] navigation];
  pageStack  = [navigation pageStack];
  newPage    = [pageStack objectAtIndex:idx];

  [navigation enterPage:newPage];

  return newPage;
}

/* responder */

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  
  if ([_ctx objectForKey:LSWSkyrixFrame_CtxKey])
    return;
  
  [_ctx setObject:yesNum forKey:LSWSkyrixFrame_CtxKey];
  if ([_ctx hasSession])
    [[_ctx session] setTimeOut:[self activeSessionTimeOut]];
  
  [super appendToResponse:_r inContext:_ctx];
}

/* tmp */

- (void)setDndSelection:(NSMutableArray *)_ma {
  ASSIGN(self->dndSelection,_ma);
}
- (NSMutableArray *)dndSelection {
  return self->dndSelection;
}

- (id)init {
  if ((self = [super init])) {
    self->dndSelection = [[NSMutableArray alloc] init];
  }
  return self;
}

- (BOOL)doesSupportDHTMLDragAndDrop {
  return [[[[self context] request]
                  clientCapabilities]
                  doesSupportDHTMLDragAndDrop];
}
- (BOOL)isInternetExplorer {
  // DEPRECATED, TODO: fix in templates ...
  return [self doesSupportDHTMLDragAndDrop];
}

/* timings */

- (NSString *)timingsString {
  NSTimeInterval duration;
  NSDate         *rStartDate;
  NSDate         *now;
  unsigned char  buf[16];
  
  if (!showTimings)
    return @"";
  
  if ((rStartDate = [[[self context] request] startDate]) == nil)
    return @"";
  
  now      = [NSDate date];
  duration = [now timeIntervalSinceDate:rStartDate];
  sprintf(buf, " (%.3fs)", duration);
  return [NSString stringWithCString:buf];
}

@end /* LSWSkyrixFrame */
