
#include "OGoAppointmentView.h"
#include "common.h"
#include <ZSBackend/SxAptManager.h>

@interface NSObject(UsedPrivates)
- (SxAptManager *)aptManagerInContext:(id)_ctx;
@end

@implementation OGoAppointmentView

- (void)dealloc {
  [super dealloc];
}

/* backend */

- (SxAptManager *)aptManager {
  return [[self clientObject] aptManagerInContext:[self context]];
}

@end /* OGoAppointmentView */
