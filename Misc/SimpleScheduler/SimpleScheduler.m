// $Id$

#import <Foundation/Foundation.h>
#import <WebObjects/WebObjects.h>

@interface Application : WOApplication
{
  id lso;
}
@end

#include <LSFoundation/OGoContextManager.h>

@implementation Application

- (id)init {
  if ((self = [super init])) {
    WORequestHandler *rh;
    
    rh = [[NSClassFromString(@"OWViewRequestHandler") alloc] init];
    [self setDefaultRequestHandler:rh];
    [self registerRequestHandler:rh
          forKey:[WOApplication componentRequestHandlerKey]];
    [rh release]; rh = nil;
    
    if ((self->lso = [OGoContextManager defaultManager]) == nil)
      NSLog(@"Couldn't setup LSOffice3 (probably not yet configured) !");
    
    [self->lso retain];
  }
  return self;
}

- (void)dealloc {
  [self->lso release];
  [super dealloc];
}

- (id)skyrix {
  return self->lso;
}

- (WOResponse *)handleException:(NSException *)_exc inContext:(id)_ctx {
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CoreOnException"] == NO)
    return [super handleException:_exc inContext:_ctx];
  
  NSLog(@"%@", _exc);
  abort();
  return nil;
}

@end /* Application */

@interface Session : WOSession
{
  id lso;
}

@end

@implementation Session

- (void)dealloc {
  RELEASE(self->lso);
  [super dealloc];
}

- (void)setSkyrixSession:(id)_lso {
  ASSIGN(self->lso, _lso);
}
- (id)skyrixSession {
  return self->lso;
}

- (BOOL)isLoggedIn {
  return self->lso ? YES : NO;
}

@end /* Session */

int main(int argc, char **argv) {
  return WOApplicationMain(@"Application", argc, (void*)argv);
}
