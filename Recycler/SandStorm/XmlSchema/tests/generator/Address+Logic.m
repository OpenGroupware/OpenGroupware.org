
#import <Foundation/Foundation.h>
#include <XmlSchema/XmlSchema.h>
#include "Address.h"

@implementation Address(Logic)

- (NSString *)description {
  return [NSString stringWithFormat:@"<Address: %@ name1=%@>",
                     [self addressId],
                     [self name1]];
}

@end /* Address(Logic) */
