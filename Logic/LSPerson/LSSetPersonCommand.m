/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/

#include "LSSetCompanyCommand.h"

@class NSData, NSString;

@interface LSSetPersonCommand : LSSetCompanyCommand
{
  NSData   *data;
  NSString *filePath;
}

@end

#include "common.h"

@implementation LSSetPersonCommand

- (void)dealloc {
  [self->data     release];
  [self->filePath release];
  [super dealloc];
}

- (NSArray *)accountAttributes {
  static NSArray *accountAttr = nil;
  if (accountAttr == nil) {
    accountAttr =
      [[NSArray alloc] initWithObjects:
               @"isAccount", @"isIntraAccount", @"isExtraAccount",
               @"isTemplateUser", @"isLocked",
               @"login", @"password",
               nil];
  }
  return accountAttr;
}

/* access check */

- (NSDictionary *)fetchOldAccountValues:(id)_context {
  EOAdaptorChannel *channel;
  EOEntity         *entity;
  NSMutableArray   *attributes;
  NSEnumerator     *e;
  EOSQLQualifier   *qual;
  NSNumber         *companyId;
  id   one;
  BOOL ok;
  
  channel = [[self databaseChannel] adaptorChannel];
  entity  = [[self databaseModel] entityNamed:@"Person"];
  
  if ((companyId = [self valueForKey:@"companyId"]) == nil) {
    id obj;
    
    obj = [self object];
    [self assert:[obj isNotNull] reason:@"Missing object for update!"];
    companyId = [obj valueForKey:@"companyId"];
  }
  
  [self assert:[companyId isNotNull] reason:@"Missing companyId for update!"];
  
  attributes = [NSMutableArray arrayWithCapacity:8];
  
  e = [[self accountAttributes] objectEnumerator];
  while ((one = [e nextObject]) != nil)
    [attributes addObject:[entity attributeNamed:one]];
  
  [attributes addObject:[entity attributeNamed:@"companyId"]];
  
  qual = [[EOSQLQualifier alloc] initWithEntity:entity
                                 qualifierFormat:@"%A = %@",
                                 @"companyId", companyId];
  ok = [channel selectAttributes:attributes
                describedByQualifier:qual
                fetchOrder:nil lock:NO];
  [self assert:ok reason:[sybaseMessages description]];
  one = [channel fetchAttributes:attributes withZone:NULL];
  if (one != nil)
    [channel cancelFetch]; 
  else
    [self assert:NO reason:@"failed to fetch old account data"]; 
  return one;
}

/* prepare */

- (void)_prepareForExecutionInContext:(id)_context {
  id old;
  
  if ((old = [self fetchOldAccountValues:_context]) != nil) {
    NSEnumerator *e;
    id one, oldValue, newValue;
    
    e = [[self accountAttributes] objectEnumerator];
    while ((one = [e nextObject]) != nil) {
      newValue = [self valueForKey:one];
      if (![newValue isNotNull])
	continue;

      oldValue = [old valueForKey:one];
      if ([newValue isEqual:oldValue])
	continue;

      // value changed
      [self logWithFormat:
	      @"WARNING[%s]: %@ tried to change account value '%@' "
              @"of %@ from %@ to %@",
              __PRETTY_FUNCTION__, [[_context valueForKey:LSAccountKey]
                                              valueForKey:@"login"],
              one, [old valueForKey:@"login"], oldValue, newValue];
      [self takeValue:oldValue forKey:one];
    }
  }
  [super _prepareForExecutionInContext:_context];  
}

- (NSString *)entityName {
  return @"Person";
}

- (void)addAttachmentInContext:(id)_context {
  /* code comes from LSSetAccountCommand */
  BOOL     isOk;
  NSString *path;
  NSString *fileName;
  
  if (!(self->data != nil && self->filePath != nil && [self->data length] > 0))
    return;
  
  path = [[_context userDefaults] stringForKey:@"LSAttachmentPath"];

  fileName = [[[[_context valueForKey:LSAccountKey]
                          valueForKey:@"companyId"] stringValue]
                          stringByAppendingPathExtension:@"html"];
  fileName = [path stringByAppendingPathComponent:fileName];
  
  isOk = [self->data writeToFile:fileName atomically:YES];
  [self assert:isOk reason:@"error during save of attachment"];
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];
  [self addAttachmentInContext:_context];
  
  if ([[self object] valueForKey:@"isAccount"]) {
    [[NSNotificationCenter defaultCenter]
                           postNotificationName:
                             @"SkyUpdatedAccountNotification"
                           object:[self object]];
  }
}

/* accessors */

- (void)setData:(NSData *)_data {
  ASSIGN(self->data, _data);
}
- (NSData *)data {
  return self->data;
}

- (void)setFilePath:(NSString *)_filePath {
  ASSIGNCOPY(self->filePath, _filePath);
}
- (NSString *)filePath {
  return self->filePath;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"data"]) {
    [self setData:_value];
    return;
  }
  else if ([_key isEqualToString:@"filePath"]) {
    [self setFilePath:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"data"])
    return [self data];
  else if ([_key isEqualToString:@"filePath"])
    return [self filePath];
  return [super valueForKey:_key];
}

@end /* LSSetPersonCommand */
