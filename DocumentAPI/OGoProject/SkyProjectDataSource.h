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

#ifndef __DocumentAPI_OGoProject_SkyProjectDataSource_H__
#define __DocumentAPI_OGoProject_SkyProjectDataSource_H__

#import <EOControl/EODataSource.h>

@class NSArray;
@class EOQualifier, EOFetchSpecification;

/**
 * @class SkyProjectDataSource
 * @brief EODataSource for fetching OGo projects.
 *
 * Fetches projects as SkyProject document objects from the
 * OGo database via the Logic command layer. Supports
 * qualifier-based filtering, sort orderings, and fetch
 * limits. Hidden project kinds (e.g. invoice, history,
 * EDC, account-log projects) are excluded by default
 * unless explicitly requested via a qualifier.
 *
 * Supported fetch specification hints:
 * - SearchAllProjects (BOOL) - also fetch special projects
 * - attributes - restrict returned keys
 * - fetchGlobalIDs (BOOL) - return global IDs only
 *
 * @see SkyProject
 */

@class LSCommandContext;

@interface SkyProjectDataSource : EODataSource
{
@protected
  LSCommandContext     *context;
  EOFetchSpecification *fetchSpecification;
  NSString             *timeZone;
}

- (id)initWithContext:(LSCommandContext *)_context;

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec;
- (EOFetchSpecification *)fetchSpecification;

- (id)context;

- (NSString *)timeZone;
- (void)setTimeZone:(NSString *)_tz;

@end

#include <OGoDocuments/SkyDocumentManager.h>

/**
 * @class SkyProjectDocumentGlobalIDResolver
 * @brief Resolves global IDs to SkyProject document objects.
 *
 * @see SkyProjectDataSource
 */
@interface SkyProjectDocumentGlobalIDResolver : NSObject
  <SkyDocumentGlobalIDResolver>
@end

#endif /* __DocumentAPI_OGoProject_SkyProjectDataSource_H__ */
