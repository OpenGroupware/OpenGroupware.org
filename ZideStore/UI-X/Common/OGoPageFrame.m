// $Id$

#include <NGObjWeb/SoComponent.h>

@interface OGoPageFrame : SoComponent
{
  NSString *title;
}

@end

#include "common.h"

@implementation OGoPageFrame

- (void)dealloc {
  [self->title release];
  [super dealloc];
}

/* accessors */

- (void)setTitle:(NSString *)_value {
  ASSIGN(self->title, _value);
}
- (NSString *)title {
  return self->title;
}

@end /* OGoPageFrame */
