
#ifndef __ZideStoreUI_OGoCalView_H__
#define __ZideStoreUI_OGoCalView_H__

#include <NGObjWeb/SoComponent.h>

@class NSArray, NSCalendarDate;
@class SxAptManager, SxAptSetIdentifier;

@interface OGoCalView : SoComponent
{
  NSArray *appointments;
  id      appointment;
}

/* accessors */

- (NSArray *)appointments;
- (id)appointment;

/* URLs */

- (NSString *)appointmentViewURL;
- (NSString *)ownMethodName;
- (NSString *)dateNavigationURLWithNewStartDate:(NSCalendarDate *)_newDate;

/* backend */

- (SxAptManager *)aptManager;
- (SxAptSetIdentifier *)aptSetID;

/* fetching */

- (NSCalendarDate *)startDate;
- (NSCalendarDate *)endDate;
- (NSArray *)fetchGIDs;
- (NSArray *)fetchCoreInfos;

/* date selection */
- (NSString *)dateStringForDate:(NSCalendarDate *)_date;
- (NSCalendarDate *)dateForDateString:(NSString *)_dateString;

@end

#endif /* __ZideStoreUI_OGoCalView_H__ */
