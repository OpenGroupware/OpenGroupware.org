// $Id$

#if GNU_RUNTIME
#  include <objc/sarray.h>
#endif

#include <NGObjWeb/WOApplication.h>

@interface Application : WOApplication
{
  WORequestHandler *projectHandler;
}

@end
#include "common.h"
#include "SkyProjectRequestHandler.h"

@implementation Application

+ (void)initialize {
  static BOOL isInitialized = NO;
  NSString     *p;
  NSDictionary *d;

  if (isInitialized)
    return;
  
  isInitialized = YES;

  NSAssert1([super version] == 6,
            @"invalid superclass (WOApplication) version %i !",
            [super version]);
    
  p = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
  if (p) {
    if ((d = [NSDictionary dictionaryWithContentsOfFile:p]))
      [[NSUserDefaults standardUserDefaults] registerDefaults:d];
  }
}

- (void)dealloc {
  [self->projectHandler release];
  [super dealloc];
}

- (id)init {
  if ((self = [super init])) {
    [self setMinimumActiveSessionsCount:1];
  }
  return self;
}


- (WOResponse *)dispatchRequest:(WORequest *)_request {
  if (self->projectHandler == nil) {
    self->projectHandler = [[SkyProjectRequestHandler alloc] init];
  }
  {
    WOResponse *r;
    
    if ((r = [self->projectHandler handleRequest:_request])) {
      [r setHeader:@"close" forKey:@"connection"];

#if 0
      [[r content] writeToFile:@"/tmp/.skyproject.lastresponse"
                   atomically:YES];
#endif
    }
    
    return r;
  }
}

@end /* Application */
