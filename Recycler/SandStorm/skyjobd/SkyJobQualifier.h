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

#ifndef __SkyJobDaemon_SkyJobQualifier_H__
#define __SkyJobDaemon_SkyJobQualifier_H__

#import <Foundation/NSObject.h>

@class NSString, NSDictionary;

@interface SkyJobQualifier : NSObject
{
  NSString *methodName;

  NSString *query;
  NSString *personURL;
  NSString *timeSelection;
  NSString *sortKey;
  NSString *teamId;
  
  BOOL     sortDescending;
  BOOL     showMyGroups;
  BOOL     isTeamSelected;
  BOOL     withCreator;
  BOOL     useListAttributes;
}

/* initialization */

+ (SkyJobQualifier *)qualifierForMethodName:(NSString *)_methodName
  arguments:(NSDictionary *)_arguments;

/* accessors */

- (NSString *)methodName;

- (NSString *)query;
- (void)setQuery:(NSString *)_query;

- (NSString *)personURL;
- (void)setPersonURL:(NSString *)_personURL;

- (NSString *)timeSelection;
- (void)setTimeSelection:(NSString *)_timeSelection;

- (NSString *)sortKey;
- (void)setSortKey:(NSString *)_sortKey;

- (NSString *)teamId;
- (void)setTeamId:(NSString *)_teamId;

- (BOOL)sortDescending;
- (void)setSortDescending:(BOOL)_sortDescending;

- (BOOL)showMyGroups;
- (void)setShowMyGroups:(BOOL)_showMyGroups;

- (BOOL)isTeamSelected;
- (void)setIsTeamSelected:(BOOL)_teamSelected;

- (BOOL)withCreator;
- (void)setWithCreator:(BOOL)_creator;

- (BOOL)useListAttributes;
- (void)setUseListAttributes:(BOOL)_listAttrs;

@end /* SkyJobQualifier */

#endif /* __SkyJobDaemon_SkyJobQualifier_H__ */
