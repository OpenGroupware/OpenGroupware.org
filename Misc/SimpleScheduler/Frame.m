// $Id$

#import <WebObjects/WOComponent.h>

@interface Frame : WOComponent
@end

#import <WebObjects/WebObjects.h>

@implementation Frame

- (id)logout {
  [[self application] terminate];
  return [self pageWithName:@"Main"];
}

@end /* Frame */
