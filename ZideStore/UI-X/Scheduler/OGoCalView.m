
#include "OGoCalView.h"
#include "common.h"
#include <ZSBackend/SxAptManager.h>

@interface NSObject(UsedPrivates)
- (SxAptManager *)aptManagerInContext:(id)_ctx;
@end

@implementation OGoCalView

- (void)dealloc {
  [self->appointment  release];
  [self->appointments release];
  [super dealloc];
}

/* accessors */

- (void)setAppointments:(NSArray *)_apts {
  ASSIGN(self->appointments, _apts);
}
- (NSArray *)appointments {
  return self->appointments;
}

- (void)setAppointment:(id)_apt {
  ASSIGN(self->appointment, _apt);
}
- (id)appointment {
  return self->appointment;
}

/* URLs */

- (NSString *)appointmentViewURL {
  id pkey;
  
  if ((pkey = [[self appointment] valueForKey:@"dateId"]) == nil)
    return nil;
  
  return [NSString stringWithFormat:@"%@/view", pkey];
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

- (NSString *)dateNavigationURLWithNewStartDate:(NSCalendarDate *)_newDate {
  return [NSString stringWithFormat:@"%@?startDate=%@",
		     [self ownMethodName], 
		     [self dateStringForDate:_newDate]];
}

/* backend */

- (SxAptManager *)aptManager {
  return [[self clientObject] aptManagerInContext:[self context]];
}
- (SxAptSetIdentifier *)aptSetID {
  return [[self clientObject] aptSetID];
}

/* resource URLs (TODO?) */

- (NSString *)resourcePath {
  return @"/ZideStore.woa/WebServerResources/";
}

- (NSString *)favIconPath {
  return [[self resourcePath] stringByAppendingPathComponent:@"favicon.ico"];
}
- (NSString *)cssPath {
  NSString *path;
  
  // TODO: there should be reusable functionality for that!
  path = @"ControlPanel/Products/ZideStoreUI/Resources/zidestoreui.css";
  return [[self context] urlWithRequestHandlerKey:@"so"
			 path:path
			 queryString:nil];
}

- (NSString *)calCSSPath {
  NSString *path;
  
  // TODO: there should be reusable functionality for that!
  path = @"ControlPanel/Products/ZideStoreUI/Resources/calendar.css";
  return [[self context] urlWithRequestHandlerKey:@"so"
			 path:path
			 queryString:nil];
}

/* fetching */

- (NSCalendarDate *)startDate {
  return [NSCalendarDate date];
}
- (NSCalendarDate *)endDate {
  return [[NSCalendarDate date] tomorrow];
}

- (NSArray *)fetchGIDs {
  return [[self aptManager] gidsOfAppointmentSet:[self aptSetID]
                            from:[self startDate] to:[self endDate]];
}

- (NSArray *)fetchCoreInfos {
  NSArray *gids;
  
  if (self->appointments)
    return self->appointments;
  
  [self logWithFormat:@"fetching (%@ => %@) ...", 
	  [self startDate], [self endDate]];
  gids = [self fetchGIDs];
  [self logWithFormat:@"  %i GIDs ...", [gids count]];
  
  self->appointments = 
    [[[self aptManager] coreInfoOfAppointmentsWithGIDs:gids
                        inSet:[self aptSetID]] retain];
  
  [self logWithFormat:@"fetched %i records.", [self->appointments count]];
  return self->appointments;
}

- (NSString *)dateStringForDate:(NSCalendarDate *)_date {
  return [_date descriptionWithCalendarFormat:@"%Y%m%d"];
}

- (NSCalendarDate *)dateForDateString:(NSString *)_dateString {
  return [NSCalendarDate dateWithString:_dateString calendarFormat:@"%Y%m%d"];
}
  
@end /* OGoCalView */
