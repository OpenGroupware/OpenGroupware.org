// $Id$

// include OGoContentPage
#include <OGoFoundation/OGoContentPage.h>

// all OGo page components inherit from OGoContentPage
@interface HelloWorld : OGoContentPage
{     
}
@end 

#import <Foundation/Foundation.h>
#include <OGoFoundation/LSWSession.h>

@implementation HelloWorld

// a sample accessors
- (NSString *)sayHello {
  return [NSString stringWithFormat:@"Hello %@!",
		   [(LSWSession *)[self session] activeLogin]];
}

@end /* HelloWorld */
