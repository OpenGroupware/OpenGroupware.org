/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#ifndef __OGo_SkyWizard_SkyWizard_H__
#define __OGo_SkyWizard_SkyWizard_H__

#import <Foundation/NSObject.h>

@class NSString, NSArray, NSMutableArray;

@interface SkyWizard : NSObject
{
  id             startPage; // not retained
  id             session;   // not retained
  id             objectParent;
  id             labels;
  SkyWizard      *parent;   // not retained
  NSMutableArray *objects;
  int            step;
  NSString       *choosenPageName;
  NSMutableArray *pageCache;
  BOOL           stepForward;
}

+ (id)wizardWithSession:(id)_session;

- (id)initWithSession:(id)_session;

/* actions */

- (id)forward;
- (id)back;
- (id)cancel;
- (id)finish;
- (id)save;
- (id)saveWithObject:(id)_obj;
- (id)start;

- (BOOL)isForward;
- (BOOL)isBack;

- (id)goToPage:(id)_page;
- (id)cachedPage;
- (NSArray *)objects;
- (void)addSnapshot:(id)_obj page:(id)_page;

/* hooks for subclasses */

- (int)maxSteps;
- (NSString *)wizardName;
- (BOOL)isFinish;

- (NSString *)labelPage;
- (id)labels;

/* accessors */

- (void)setParent:(id)_parent;
- (id)parent;

- (void)setObjectParent:(id)_parent;
- (id)objectParent;

- (void)setStartPage:(id)_startPage;
- (id)startPage;

- (void)setChoosenPageName:(id)_name;
- (id)choosenPageName;

@end

#endif /* __OGo_SkyWizard_SkyWizard_H__ */
