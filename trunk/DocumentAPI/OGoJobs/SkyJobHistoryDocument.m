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

#include "SkyJobHistoryDocument.h"
#include "common.h"

@interface SkyJobHistoryDocument(PrivateMethodes)
- (void)_registerForGID;
@end /* SkyJobHistoryDocument(PrivateMethodes) */

@implementation SkyJobHistoryDocument

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

// designated initializer
- (id)initWithJobHistory:(id)_job
                globalID:(EOGlobalID *)_gid
              dataSource:(EODataSource *)_ds
{
  if ((self = [super init])) {
    ASSIGN(self->dataSource, _ds);
    ASSIGN(self->globalID, _gid);

    [self setComment:
          [[_job valueForKey:@"toJobHistoryInfo"] valueForKey:@"comment"]];

    self->status.isComplete  = YES;
    self->status.isValid     = YES;
    self->status.isEdited    = NO;

    [self _registerForGID];
  }
  return self;
}

- (id)initWithEO:(id)_eo dataSource:(EODataSource *)_ds {
  return [self initWithJobHistory:_eo
               globalID:[_eo valueForKey:@"globalID"]
               dataSource:_ds];
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->dataSource);
  RELEASE(self->globalID);

  RELEASE(self->comment);
  
  [super dealloc];
}
#endif

- (BOOL)isComplete {
  if ([self isValid] == NO)
    return NO;

  return self->status.isComplete;
}

- (EOGlobalID *)globalID {
  return self->globalID;
}

- (NSArray *)attributesForNamespace:(NSString *)_namespace {
  if (_namespace == nil)
    return nil;

  return nil;
}

- (id)context {
  if (self->dataSource)
    return [(id)self->dataSource context];
  
#if DEBUG
  NSLog(@"WARNING(%s): document %@ has no datasource/context !!",
        __PRETTY_FUNCTION__, self);
#endif
  return nil;
}

/* accessors */

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY_IFNOT_EQUAL(self->comment, _comment, self->status.isEdited);
}
- (NSString *)comment {
  return self->comment;
}

// ---------------------------------------------------------------------

- (BOOL)isNew {
  return (self->globalID == nil) ? YES : NO;
}

- (BOOL)isValid {
  return self->status.isValid;
}

- (void)invalidate {
  [self reload]; /* clear all attrs */
  RELEASE(self->globalID); self->globalID = nil;
  self->status.isValid = NO;
}

- (BOOL)isEdited {
  return (self->globalID == nil || self->status.isEdited) ? YES : NO;
}

/* equality */

- (BOOL)isEqual:(id)_other {
  if (_other == self)
    return YES;
  
  if (![_other isKindOfClass:[self class]])
    return NO;
  
  if (![[_other globalID] isEqual:[self globalID]])
    return NO;

  /* docs have same global-id, but could be in different editing state .. */
  
  if (![_other isEdited] && ![self isEdited])
    return YES;
  
  return NO;
}

/* actions */

- (void)logException:(NSException *)_exception {
  NSLog(@"%s: catched exception: %@", __PRETTY_FUNCTION__, _exception);
}

- (BOOL)save {
  BOOL result = YES;
  
  NS_DURING
    [self->dataSource updateObject:self];
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)delete {
  BOOL result = YES;
  
  NS_DURING
    [self->dataSource deleteObject:self];
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)reload {
  if ([self isValid] == NO)
    return NO;

  return YES;
}

@end /* SkyJobHistoryDocument */


@implementation SkyJobHistoryDocument(Private)

- (void)_registerForGID {
  
  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"DebugDocumentRegistration"]) {
    NSLog(@"++++++++++++++++++ Warning: register Document"
          @" in NotificationCenter(%s)",
          __PRETTY_FUNCTION__);
  }
  
  if (self->globalID) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(invalidate)
                                          name:SkyGlobalIDWasDeleted
                                          object:self->globalID];
  }
}

@end /* SkyJobHistoryDocument(Private) */


@implementation SkyJobHistoryDocument(EOGenericRecord)

/* compatibility with EOGenericRecord (is deprecated!!!)*/

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  NSAssert1((_key != nil), @"%s: key is nil", __PRETTY_FUNCTION__);
  if (_value == nil)
    return;
  
  if (![self isValid]) {
    [NSException raise:@"invalid person document"
                 format:@"cannot takeValue:forKey:%@, document %@ is invalid",
                 _key, self];
    return;
  }
  if (![self isComplete]) {
    [NSException raise:@"person document is not complete, use reload"
               format:@"cannot takeValue:forKey:%@, document %@ is incomplete",
                   _key, self];
    return;
  }
}

- (id)valueForKey:(NSString *)_key {
  if ([self respondsToSelector:NSSelectorFromString(_key)])
    return [self performSelector:NSSelectorFromString(_key)];
  else if ([_key isEqualToString:@"globalID"])
    return self->globalID;

  return nil;
}

@end /* SkyJobHistoryDocument(EOGenericRecord) */
