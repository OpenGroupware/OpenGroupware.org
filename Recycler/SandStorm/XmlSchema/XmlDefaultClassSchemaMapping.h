
#ifndef __XmlSchema_XmlDefaultClassSchemaMapping_H__
#define __XmlSchema_XmlDefaultClassSchemaMapping_H__

#include "XmlSchemaMapping.h"

@interface XmlDefaultClassSchemaMapping : XmlSchemaMapping
{
  NSString *classPrefix;
}

- (void)setClassPrefix:(NSString *)_classPrefix;
- (NSString *)classPrefix;

@end /* XmlDefaultClassSchemaMapping */

#endif /* __XmlSchema_XmlDefaultClassSchemaMapping_H__ */
