/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#ifndef __OGoFoundation_OGoContentPage_H__
#define __OGoFoundation_OGoContentPage_H__

#include <OGoFoundation/LSWComponent.h>

/*
  TODO: explain the following!
  
  KVC:
    confirmString: --> confirm message
    confirmAction: --> confirm action
*/

@class NSString;
@class NGHashMap;
@class WOContext;
@class OGoNavigation;

@protocol OGoContentPage < NSObject >
- (NSString *)label;
- (BOOL)rollbackForPage:(id<OGoContentPage>)_page;
@end

/* for compatibility, to be removed */
@protocol LSWContentPage < OGoContentPage >
@end

/* should inherit from OGoComponent in the long run ..*/
@interface OGoContentPage : LSWComponent < LSWContentPage >
{
@private
  NSString *warningOkAction;
  NSString *warningPhrase;
  BOOL     isInWarningMode;
  NSString *errorString;
}

- (OGoNavigation *)navigation;

- (void)setIsInWarningMode:(BOOL)_isInWarningMode;
- (BOOL)isInWarningMode;
- (void)setWarningPhrase:(NSString *)_phrase;
- (NSString *)warningPhrase;
- (void)setWarningOkAction:(NSString *)_warningOkAction;
- (NSString *)warningOkAction;

/* notifications */

- (void)noteChange:(NSString *)_changeName onObject:(id)_object;
- (void)postChange:(NSString *)_changeName onObject:(id)_object;
- (void)postChange:(NSString *)_changeName;

- (void)registerForNotificationNamed:(NSString *)_notificationName
  object:(id)_object;
- (void)registerForNotificationNamed:(NSString *)_notificationName;
- (void)unregisterAsObserver;

/* component activation */

- (BOOL)executePasteboardCommand:(NSString *)_command;

/* errors */

- (void)setErrorString:(NSString *)_error;
- (void)setErrorCString:(const char *)_error;
- (NSString *)errorString;
- (void)resetErrorString;
- (BOOL)hasErrorString;

@end

@class NGMimeType;

@interface WOComponent(OGoActivationComponent)

- (BOOL)prepareForActivationCommand:(NSString *)_name
  type:(NGMimeType *)_type;
- (BOOL)prepareForActivationCommand:(NSString *)_name
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_config;
- (BOOL)prepareForActivationCommand:(NSString *)_name
  type:(NGMimeType *)_type
  object:(id)_object;

@end

@interface NSObject(ContentPageTyping)
- (BOOL)isContentPage;
@end

#include <OGoFoundation/WOComponent+Navigation.h>

/* for compatibility, to be removed */
@interface LSWContentPage : OGoContentPage
@end

#endif /* __OGoFoundation_OGoContentPage_H__ */
