// $Id$

#import <Foundation/Foundation.h>
#include <XmlSchema/XmlSchema.h>
#include "Person.h"

@implementation Person(Logic)

- (NSString *)description {
  return [NSString stringWithFormat:@"<Person: %@ name=%@ addresses=%@>",
                     [self companyId],
                     [self name],
                     [self addresses]];
}

@end /* Person(Logic) */
