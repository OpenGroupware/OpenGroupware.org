/*
  Copyright (C) 2004 SKYRIX Software AG

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

#include "UIxComponent.h"
#include "common.h"
#include <NGObjWeb/SoHTTPAuthenticator.h>

@interface UIxComponent (PrivateAPI)
- (void)_parseQueryString:(NSString *)_s;
- (NSMutableDictionary *)_queryParameters;
@end

@implementation UIxComponent

static NSTimeZone *MET = nil;
static NSTimeZone *GMT = nil;

static NSMutableArray *dayLabelKeys       = nil;
static NSMutableArray *abbrDayLabelKeys   = nil;
static NSMutableArray *monthLabelKeys     = nil;
static NSMutableArray *abbrMonthLabelKeys = nil;

static BOOL uixDebugEnabled = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
  uixDebugEnabled = [ud boolForKey:@"SOGoUIxDebugEnabled"];

  if (MET == nil) {
    MET = [[NSTimeZone timeZoneWithAbbreviation:@"MET"] retain];
    GMT = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
  }
  if (dayLabelKeys == nil) {
    dayLabelKeys = [[NSMutableArray alloc] initWithCapacity:7];
    [dayLabelKeys addObject:@"Sunday"];
    [dayLabelKeys addObject:@"Monday"];
    [dayLabelKeys addObject:@"Tuesday"];
    [dayLabelKeys addObject:@"Wednesday"];
    [dayLabelKeys addObject:@"Thursday"];
    [dayLabelKeys addObject:@"Friday"];
    [dayLabelKeys addObject:@"Saturday"];

    abbrDayLabelKeys = [[NSMutableArray alloc] initWithCapacity:7];
    [abbrDayLabelKeys addObject:@"a2_Sunday"];
    [abbrDayLabelKeys addObject:@"a2_Monday"];
    [abbrDayLabelKeys addObject:@"a2_Tuesday"];
    [abbrDayLabelKeys addObject:@"a2_Wednesday"];
    [abbrDayLabelKeys addObject:@"a2_Thursday"];
    [abbrDayLabelKeys addObject:@"a2_Friday"];
    [abbrDayLabelKeys addObject:@"a2_Saturday"];

    monthLabelKeys = [[NSMutableArray alloc] initWithCapacity:12];
    [monthLabelKeys addObject:@"January"];
    [monthLabelKeys addObject:@"February"];
    [monthLabelKeys addObject:@"March"];
    [monthLabelKeys addObject:@"April"];
    [monthLabelKeys addObject:@"May"];
    [monthLabelKeys addObject:@"June"];
    [monthLabelKeys addObject:@"July"];
    [monthLabelKeys addObject:@"August"];
    [monthLabelKeys addObject:@"September"];
    [monthLabelKeys addObject:@"October"];
    [monthLabelKeys addObject:@"November"];
    [monthLabelKeys addObject:@"December"];

    abbrMonthLabelKeys = [[NSMutableArray alloc] initWithCapacity:12];
    [abbrMonthLabelKeys addObject:@"a3_January"];
    [abbrMonthLabelKeys addObject:@"a3_February"];
    [abbrMonthLabelKeys addObject:@"a3_March"];
    [abbrMonthLabelKeys addObject:@"a3_April"];
    [abbrMonthLabelKeys addObject:@"a3_May"];
    [abbrMonthLabelKeys addObject:@"a3_June"];
    [abbrMonthLabelKeys addObject:@"a3_July"];
    [abbrMonthLabelKeys addObject:@"a3_August"];
    [abbrMonthLabelKeys addObject:@"a3_September"];
    [abbrMonthLabelKeys addObject:@"a3_October"];
    [abbrMonthLabelKeys addObject:@"a3_November"];
    [abbrMonthLabelKeys addObject:@"a3_December"];
  }
}

- (void)dealloc {
  [self->queryParameters release];
  [super dealloc];
}

/* query parameters */

- (void)_parseQueryString:(NSString *)_s {
  NSEnumerator *e;
  NSString *part;
    
  e = [[_s componentsSeparatedByString:@"&"] objectEnumerator];
  while ((part = [e nextObject])) {
    NSRange  r;
    NSString *key, *value;
        
    r = [part rangeOfString:@"="];
    if (r.length == 0) {
      /* missing value of query parameter */
      key   = [part stringByUnescapingURL];
      value = @"1";
    }
    else {
      key   = [[part substringToIndex:r.location] stringByUnescapingURL];
      value = [[part substringFromIndex:(r.location + r.length)] 
                stringByUnescapingURL];
    }
    [self->queryParameters setObject:value forKey:key];
  }
}

- (NSString *)queryParameterForKey:(NSString *)_key {
  return [[self _queryParameters] objectForKey:_key];
}

- (void)setQueryParameter:(NSString *)_param forKey:(NSString *)_key {
  if(_key == nil)
    return;

  if(_param != nil)
    [[self _queryParameters] setObject:_param forKey:_key];
  else
    [[self _queryParameters] removeObjectForKey:_key];
}

- (NSMutableDictionary *)_queryParameters {
  if(!self->queryParameters) {
    WORequest *req;
    NSString  *uri;
    NSRange   r;
    
    self->queryParameters = [[NSMutableDictionary alloc] initWithCapacity:8];
    
    req = [[self context] request];
    uri = [req uri];
    r   = [uri rangeOfString:@"?" options:NSBackwardsSearch];
    if (r.length > 0) {
      NSString *qs;
      
      qs = [uri substringFromIndex:NSMaxRange(r)];
      [self _parseQueryString:qs];
    }    
  }
  return self->queryParameters;
}

- (NSDictionary *)queryParameters {
  return [self _queryParameters];
}

- (NSDictionary *)queryParametersBySettingSelectedDate:(NSCalendarDate *)_date{
  NSMutableDictionary *qp;
    
  qp = [[self queryParameters] mutableCopy];
  [self setSelectedDateQueryParameter:_date inDictionary:qp];
  return [qp autorelease];
}

- (void)setSelectedDateQueryParameter:(NSCalendarDate *)_newDate
			 inDictionary:(NSMutableDictionary *)_qp;
{
  if(_newDate != nil)
    [_qp setObject:[self dateStringForDate:_newDate] forKey:@"day"];
  else
    [_qp removeObjectForKey:@"day"];
}

- (NSString *)completeHrefForMethod:(NSString *)_method {
  NSDictionary *qp;
  NSString *qs;
    
  qp = [self queryParameters];
  if([qp count] == 0)
    return _method;
    
  qs = [[self context] queryStringFromDictionary:qp];
  return [_method stringByAppendingFormat:@"?%@", qs];
}

- (NSString *)ownMethodName {
  NSString *uri;
  NSRange  r;
    
  uri = [[[self context] request] uri];
    
  /* first: cut off query parameters */
    
  r = [uri rangeOfString:@"?" options:NSBackwardsSearch];
  if (r.length > 0)
    uri = [uri substringToIndex:r.location];
    
  /* next: strip trailing slash */
    
  if ([uri hasSuffix:@"/"]) uri = [uri substringToIndex:([uri length] - 1)];
  r = [uri rangeOfString:@"/" options:NSBackwardsSearch];
    
  /* then: cut of last path component */
    
  if (r.length == 0) // no slash? are we at root?
    return @"/";
    
  return [uri substringFromIndex:(r.location + 1)];
}

- (NSString *)userFolderPath {
  WOContext *ctx;
  NSArray   *traversalObjects;
  NSString  *url;
  
  ctx = [self context];
  traversalObjects = [ctx objectTraversalStack];
  url = [[traversalObjects objectAtIndex:1]
                           baseURLInContext:ctx];
  return [[NSURL URLWithString:url] path];
}

- (NSString *)ownPath {
  NSString *uri;
  NSRange  r;
  
  uri = [[[self context] request] uri];
  
  /* first: cut off query parameters */
  
  r = [uri rangeOfString:@"?" options:NSBackwardsSearch];
  if (r.length > 0)
    uri = [uri substringToIndex:r.location];
  return uri;
}

- (NSString *)relativePathToUserFolderSubPath:(NSString *)_sub {
  NSString *dst, *rel;

  dst = [[self userFolderPath] stringByAppendingPathComponent:_sub];
  rel = [dst urlPathRelativeToPath:[self ownPath]];
  return rel;
}
  
/* date */

- (NSTimeZone *)viewTimeZone {
  // Note: also in the folder, should be based on a cookie?
  return MET;
}

- (NSTimeZone *)backendTimeZone {
  return GMT;
}

- (NSCalendarDate *)selectedDate {
  NSString       *s;
  NSCalendarDate *cdate;

  s = [self queryParameterForKey:@"day"];
  cdate = ([s length] > 0)
    ? [self dateForDateString:s]
    : [NSCalendarDate date];
  [cdate setTimeZone:[self viewTimeZone]];
  s = [self queryParameterForKey:@"hm"];
  if([s length] == 4) {
    unsigned hour, minute;
      
    hour = [[s substringToIndex:2] unsignedIntValue];
    minute = [[s substringFromIndex:2] unsignedIntValue];
    cdate = [cdate hour:hour minute:minute];
  }
  else {
    cdate = [cdate hour:12 minute:0];
  }
  return cdate;
}

- (NSString *)dateStringForDate:(NSCalendarDate *)_date {
  [_date setTimeZone:[self viewTimeZone]];
  return [_date descriptionWithCalendarFormat:@"%Y%m%d"];
}

- (NSCalendarDate *)dateForDateString:(NSString *)_dateString {
  return [NSCalendarDate dateWithString:_dateString 
			 calendarFormat:@"%Y%m%d"];
}


/* SoUser */

- (SoUser *)user {
  WOContext *ctx;
  
  ctx = [self context];
  return [[[self clientObject] authenticatorInContext:ctx] userInContext:ctx];
}

- (NSString *)shortUserNameForDisplay {
  // TODO: better use a SoUser formatter?
  NSString *s;
  NSRange  r;

#warning TODO: USE USER MANAGER INSTEAD!

  s = [[self user] login];
  if ([s length] < 10)
    return s;
    
  // TODO: algorithm might be inappropriate, depends on the actual UID
    
  r = [s rangeOfString:@"."];
  if (r.length == 0)
    return s;
    
  return [s substringToIndex:r.location];
}

/* labels */

- (NSString *)labelForKey:(NSString *)_str {
  WOResourceManager *rm;
  NSArray           *languages;
  WOContext         *ctx;
  NSString          *label;
  NSString          *lKey, *lTable, *lVal;
  NSRange r;

  if ([_str length] == 0)
    return nil;
  
  /* lookup languages */
    
  ctx = [self context];
  languages = [ctx hasSession]
    ? [[ctx session] languages]
    : [[ctx request] browserLanguages];
    
  /* find resource manager */
    
  if ((rm = [self resourceManager]) == nil)
    rm = [[WOApplication application] resourceManager];
  if (rm == nil)
    [self warnWithFormat:@"missing resource manager!"];
    
  /* get parameters */
    
  r = [_str rangeOfString:@"/"];
  if (r.length > 0) {
    lTable = [_str substringToIndex:r.location];
    lKey   = [_str substringFromIndex:(r.location + r.length)];
  }
  else {
    lTable = nil;
    lKey   = _str;
  }
  lVal = lKey;

  if ([lKey hasPrefix:@"$"])
    lKey = [self valueForKeyPath:[lKey substringFromIndex:1]];
  
  if ([lTable hasPrefix:@"$"])
    lTable = [self valueForKeyPath:[lTable substringFromIndex:1]];
  
#if 0
  if ([lVal hasPrefix:@"$"])
    lVal = [self valueForKeyPath:[lVal substringFromIndex:1]];
  
#endif
  
  /* lookup string */
  
  label = [rm stringForKey:lKey inTableNamed:lTable withDefaultValue:lVal
	      languages:languages];
  return label;
}

- (NSString *)localizedNameForDayOfWeek:(unsigned)_dayOfWeek {
  NSString *key =  [dayLabelKeys objectAtIndex:_dayOfWeek % 7];
  return [self labelForKey:key];
}

- (NSString *)localizedAbbreviatedNameForDayOfWeek:(unsigned)_dayOfWeek {
  NSString *key =  [abbrDayLabelKeys objectAtIndex:_dayOfWeek % 7];
  return [self labelForKey:key];
}

- (NSString *)localizedNameForMonthOfYear:(unsigned)_monthOfYear {
  NSString *key =  [monthLabelKeys objectAtIndex:(_monthOfYear - 1) % 12];
  return [self labelForKey:key];
}

- (NSString *)localizedAbbreviatedNameForMonthOfYear:(unsigned)_monthOfYear {
  NSString *key =  [abbrMonthLabelKeys objectAtIndex:(_monthOfYear - 1) % 12];
  return [self labelForKey:key];
}

/* locale */

- (NSDictionary *)locale {
  /* we need no fallback here, as locale is guaranteed to be set by sogod */
  return [[self context] valueForKey:@"locale"];
}

/* debugging */

- (BOOL)isUIxDebugEnabled {
  return uixDebugEnabled;
}

@end /* UIxComponent */
