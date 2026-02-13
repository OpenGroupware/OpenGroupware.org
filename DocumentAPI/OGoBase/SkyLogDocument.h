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

#ifndef __SkyLogDocument_H__
#define __SkyLogDocument_H__

#include <OGoDocuments/SkyDocument.h>

/**
 * @class SkyLogDocument
 * @brief Document representing a single object log entry.
 *
 * SkyLogDocument wraps a log record that is associated with
 * an OGo database object. Each log entry stores a textual
 * message, an action identifier, the creating account, and
 * a creation timestamp.
 *
 * Log documents are insert-only: once saved they become
 * immutable. The -save method inserts the document through
 * its owning SkyLogDataSource; updates are not supported.
 * The -account / -actor accessors lazily resolve the
 * accountId to the corresponding person document via the
 * document manager.
 *
 * @see SkyLogDataSource
 * @see SkyDocument
 */

@class SkyLogDataSource;
@class NSNumber, NSCalendarDate, NSDictionary;

@interface SkyLogDocument : SkyDocument
{
  NSNumber       *objectId;
  NSCalendarDate *creationDate;
  NSString       *logText;
  NSNumber       *accountId;
  NSString       *action;

  SkyLogDataSource *dataSource;
  EOGlobalID       *globalID;
  
  id             account;

  struct {
    BOOL isNew;
  } status;
}

- (id)initWithValues:(id)_values
          dataSource:(SkyLogDataSource *)_dataSource;

- (NSNumber *)objectId;
- (NSCalendarDate *)creationDate;

- (void)setLogText:(NSString *)_text;
- (NSString *)logText;

- (void)setAction:(NSString *)_action;
- (NSString *)action;

- (NSNumber *)accountId;
- (id)account;  // same as actor
- (id)actor;

- (BOOL)isSaved; // is saved or not

@end /* SkyDocument */

#endif /* __SkyLogDocument_H__ */
