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
// $Id:

#ifndef __SkyAptCompundDataSource_H__
#define __SkyAptCompundDataSource_H__

#import <Foundation/Foundation.h>
#include <NGExtensions/EOCompoundDataSource.h>
#include <EOControl/EOFetchSpecification.h>
#include <LSFoundation/LSFoundation.h>

@interface SkyAptCompoundDataSource : EODataSource
{
  EOCompoundDataSource *source;
  //  LSCommandContext     *ctx;
  EOFetchSpecification *fetchSpec;
}

//- (id)initWithContext:(LSCommandContext *)_ctx;
- (void)addSource:(EODataSource *)_ds;
- (void)clear;

- (NSArray *)fetchObjects;
- (NSArray *)companies;
- (NSArray *)resources;

- (BOOL)isResCategorySelected;
- (void)setIsResCategorySelected:(BOOL)_flag;

- (NSTimeZone *)timeZone;
- (void)setTimeZone:(NSTimeZone *)_tz;
//- (NSCalendarDate *)startDate;
//- (NSCalendarDate *)endDate;

@end

#endif /* __SkyAptCompundDataSource_H__ */
