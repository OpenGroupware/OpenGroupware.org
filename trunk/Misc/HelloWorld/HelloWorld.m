
// include OGoContentPage
#include <OGoFoundation/OGoContentPage.h>

// all OGo page components inherit from OGoContentPage
@interface HelloWorld : OGoContentPage
{     
}
@end 

#import <Foundation/Foundation.h>
#include <OGoFoundation/OGoSession.h>

@implementation HelloWorld

// a sample accessors
- (NSString *)sayHello {
  return [NSString stringWithFormat:@"Hello %@!",
		   [(OGoSession *)[self session] activeLogin]];
}

@end /* HelloWorld */
