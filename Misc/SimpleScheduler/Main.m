
#import <WebObjects/WOComponent.h>

@class EOGlobalID, NSTimeZone;

@interface NSObject(Private)
- (EOGlobalID *)globalID;
@end

@interface Main : WOComponent
{
  id  dataSource;
  id  apt;

  NSTimeZone *tz;
  
  int year;
  int week;
}

@end

#import <WebObjects/WebObjects.h>
#import <Foundation/Foundation.h>
#import <LSFoundation/OGoContextManager.h>
#import <LSFoundation/OGoContextSession.h>
#import <LSFoundation/LSCommandKeys.h>
#import <OGoScheduler/SkyAptDataSource.h>
#import <OGoScheduler/SkyAppointmentQualifier.h>
#import <EOControl/EOControl.h>
#import <NGExtensions/NGExtensions.h>

@interface NSObject(Blah)
- (id)initWithContext:(id)_ctx;
- (id)skyrixSession;
@end

@implementation Main

- (id)init {
  if ((self = [super init])) {
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->dataSource);
  RELEASE(self->tz);
  RELEASE(self->apt);
  [super dealloc];
}

/* notifications */

- (void)awake {
  [super awake];
}

/* accessors */

- (void)setApt:(id)_apt {
  ASSIGN(self->apt,_apt);
}
- (id)apt {
  return self->apt;
}

- (void)setYear:(int)_y {
  self->year = _y;
}
- (int)year {
  return self->year;
}

- (void)setWeek:(int)_week {
  self->week = _week;
}
- (int)week {
  return self->week;
}

- (id)dataSource {
  return self->dataSource;
}

- (NSCalendarDate *)weekStart {
  return [NSCalendarDate mondayOfWeek:self->week
                         inYear:self->year
                         timeZone:self->tz];
}

- (NSString *)aptInfo {
  NSString *l;
  id ps, one;
  NSString *sd, *ed, *p, *t;
  
  sd = [[self->apt valueForKey:@"startDate"]
                   descriptionWithCalendarFormat:@"%H-%M"];
  ed = [[self->apt valueForKey:@"endDate"]
                   descriptionWithCalendarFormat:@"%H-%M"];
  ps = [self->apt valueForKey:@"participants"];
  ps = [ps objectEnumerator];
  p  = @"";
  while ((one = [ps nextObject])) {
    p  = [NSString stringWithFormat:@"%@%@, ", p, [one valueForKey:@"login"]];
  }
  t  = [self->apt valueForKey:@"title"];
  l  = [self->apt valueForKey:@"location"];
  
  l  = [NSString stringWithFormat:@"%@-%@ %@\n",
                 sd, ed, t];
  return l;
}

/* actions */

- (id)showApts {
  // reconfiguring dataSource
  SkyAppointmentQualifier *q     = nil;
  EOFetchSpecification    *fs    = nil;
  NSCalendarDate          *sd    = nil; // startDate
  NSCalendarDate          *ed    = nil; // endDate
  id                      aa     = nil; // active account
  NSArray                 *cs    = nil; // companies
  static NSArray          *attrs = nil; // attributes
  NSDictionary            *hs    = nil; // hints
  NSArray                 *so    = nil; // sortOrderings

  sd = [self weekStart];
  sd = [sd beginOfDay];
  ed = [sd dateByAddingYears:0 months:0 days:6
           hours:23 minutes:59 seconds:59];
  aa = [(id)[[self session] skyrixSession] valueForKey:LSAccountKey];
  cs = [NSArray arrayWithObject:[aa valueForKey:@"globalID"]];

  if (attrs == nil) {
    attrs =
      [[NSArray alloc] initWithObjects:
                       @"title",
                       @"location",
                       @"startDate",
                       @"endDate",
                       @"globalID",
                       @"ownerId",
                       @"accessTeamId",
                       @"permissions",
                       @"resourceNames",
                       @"participants.companyId",
                       @"participants.globalID",
                       @"participants.login",
                       @"participants.firstname",
                       @"participants.name",
                       @"participants.description",
                       @"participants.isTeam",
                       @"participants.isAccount",
                       nil];
  }
  hs = [NSDictionary dictionaryWithObjectsAndKeys:
                     attrs, @"attributeKeys", nil];
  so = [NSArray arrayWithObject:
                [EOSortOrdering sortOrderingWithKey:@"startDate"
                                selector:EOCompareAscending]];

  // building qualifier
  q = [[SkyAppointmentQualifier alloc] init];
  [q setStartDate:sd];
  [q setEndDate:ed];
  [q setTimeZone:self->tz];
  [q setCompanies:cs];
  [q setResources:[NSArray array]];
  AUTORELEASE(q);

  // building fetchSpecification
  fs = [EOFetchSpecification fetchSpecificationWithEntityName:@"date"
                             qualifier:q
                             sortOrderings:so];
  [fs setHints:hs];

  [self->dataSource setFetchSpecification:fs];
  [self->dataSource clear];

  return nil;
}

- (id)login {
  OGoContextManager *app;
  OGoContextSession *sn;
  NSString *user, *pwd;

  app  = [[self application] valueForKey:@"skyrix"];
  user = [self valueForKey:@"userName"];
  pwd  = [self valueForKey:@"password"];
  
  if (![app isLoginAuthorized:user password:pwd]) {
    [self takeValue:nil forKey:@"password"];
    return self;
  }
  
  if ((sn = [app login:user password:pwd]) == nil) {
    [self logWithFormat:@"couldn't login %@ into SKYRIX ..", user];
    [self takeValue:nil forKey:@"password"];
    return self;
  }
  
  [sn activate];
  [[self session] takeValue:[sn commandContext] forKey:@"skyrixSession"];

  {
    NSCalendarDate *now = [NSCalendarDate date];
    id ctx;

    ctx = [(id)[self session] skyrixSession];
    
    self->dataSource = (SkyAptDataSource *)[[SkyAptDataSource alloc] init];
    [self->dataSource setContext:ctx];
    
    self->tz = [[NSTimeZone localTimeZone] copy];
    
    [now setTimeZone:self->tz];
    self->year  = [now yearOfCommonEra];
    self->week  = [now weekOfYear];
  }

  return [self showApts];
}

@end /* Main */
