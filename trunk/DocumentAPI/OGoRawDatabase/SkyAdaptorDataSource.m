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

#include "SkyAdaptorDataSource.h"
#import "common.h"
//#import "LSCommandContext.h"

/* TODO: uses non-protocolized stuff of SkyContext ... (to be fixed by hh) */
#define LSDatabaseChannelKey     @"channel"
#define LSUserDefaultsKey        @"userDefaults"
@interface NSObject(SkyContextStuff)
- (BOOL)begin;
- (BOOL)commit;
- (BOOL)rollback;
- (BOOL)isTransactionInProgress;
@end

@implementation SkyAdaptorDataSource

+ (int)version {
  return [super version] + 0; /* v2 */
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

+ (EOAdaptor *)adaptorForContext:(id)_ctx {
  return  [[[[_ctx valueForKey:LSDatabaseChannelKey]
                   adaptorChannel]
                   adaptorContext]
                   adaptor];
}
+ (NSUserDefaults *)defaultsForContext:(id)_ctx {
  return [_ctx valueForKey:LSUserDefaultsKey];
}

- (id)initWithContext:(id)_ctx {
  if ((self = [super initWithAdaptorChannel:nil])) {
    ASSIGN(self->context, _ctx);
  }
  return self;
}

- (id)initWithContext:(id)_ctx
  adaptorName:(NSString *)_adaptor
  connectionDictionary:(NSDictionary *)_condict
  primaryKeyGenerationDictionary:(NSDictionary *)_pkeydict
{
  EOAdaptor *adaptor;

  if ((adaptor = [[self class] adaptorForContext:_ctx]) != nil)
    _adaptor = [adaptor name];
  
  if (_condict == nil)
    _condict = [adaptor connectionDictionary];

  if (_pkeydict == nil) {
    if ([[adaptor name] isEqualToString:_adaptor])
      _pkeydict = [adaptor pkeyGeneratorDictionary];
  }
  
  self = [super initWithAdaptorName:_adaptor
                connectionDictionary:_condict
                primaryKeyGenerationDictionary:_pkeydict];
  return self;
}

/* timezone handling */

- (NSString *)_defaultTimeZoneName {
  NSString *tzname;
  
  tzname = [[[self class] defaultsForContext:self->context]
                   stringForKey:@"timezone"];
  if ([tzname length] == 0) tzname = @"GMT";
  return tzname;
}

- (NSTimeZone *)_defaultTimeZone {
  return [NSTimeZone timeZoneWithAbbreviation:[self _defaultTimeZoneName]];
}

- (void)_setTimeZone:(NSTimeZone *)_tz 
  inFetchSpecification:(EOFetchSpecification *)_fSpec
{
  NSMutableDictionary *dict;
    
  dict = [[_fSpec hints] mutableCopy];
  [dict setObject:_tz forKey:EOFetchResultTimeZone];
  [_fSpec setHints:dict];
  [dict release];
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  NSTimeZone *tz;
  
  tz = [self _defaultTimeZone];
  if (tz != nil && ![_fSpec isEqual:[self fetchSpecification]])
    [self _setTimeZone:tz inFetchSpecification:_fSpec];
  
  [super setFetchSpecification:_fSpec];
}

/* managing transactions */

- (EOAdaptorChannel *)beginTransaction {
  if (self->context == nil)
    return [super beginTransaction];

  if (![self->context isTransactionInProgress]) {
    self->commitTransaction = YES;
    [self->context begin];
  }
  else
    self->commitTransaction = NO;
  
  return [[self->context valueForKey:LSDatabaseChannelKey] adaptorChannel];
}

- (void)commitTransaction {
  if (self->context == nil) {
    [super commitTransaction];
    return;
  }
  
  if (self->commitTransaction) {
    self->commitTransaction = NO;
    [self->context commit];
  }
}

- (void)rollbackTransaction {
  if (self->context == nil)
    [super rollbackTransaction];
  else {
    [self->context rollback];
    self->commitTransaction = NO;
  }
}

@end /* SkyAdaptorDataSource */
