/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#import <Foundation/NSObject.h>

/*
  OGoAptMailOpener

  This class is used to organize the process of opening a mail editor
  containing a notification mail for appointments.
*/

@class NSString, NSArray, NSUserDefaults;
@class LSCommandContext;
@class OGoComponent, OGoContentPage;

@interface OGoAptMailOpener : NSObject
{
  NSString         *action;
  id               object;
  
  NSUserDefaults   *defaults;
  id               labels;
  OGoComponent     *page;
  LSCommandContext *cmdctx;

  NSString *comment;
  NSArray  *participants;
}

+ (id)mailEditorForObject:(id)_object action:(NSString *)_action
  page:(OGoComponent *)_component;

/* object specific */

+ (id)mailOpenerForObject:(id)_object action:(NSString *)_action
  page:(OGoComponent *)_component;

- (id)initWithObject:(id)_object action:(NSString *)_action
  page:(OGoComponent *)_component;

+ (BOOL)isMailEnabled;


- (NSString *)mailContent;
- (OGoContentPage *)mailEditor;

@end
