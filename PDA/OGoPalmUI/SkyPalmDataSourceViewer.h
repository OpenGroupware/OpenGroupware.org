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

#ifndef __LSWebInterface_SkyPalm_SkyPalmDataSourceViewer_H__
#define __LSWebInterface_SkyPalm_SkyPalmDataSourceViewer_H__

/*
  superclass of all multiple record viewer for palm_records

  supported bindings

    < $itemKey   // current record
                 // $itemKey depends on subclass
                 // binding key is not "itemKey" !!
    > action     // String; action for viewing a single record (optional)
                 // for default directAction is used
    > dataSource // dataSource (optional)
    > state      // SkyPalmDataSourceViewerState for fetchSpecification
   <> insertForm // insert a form-tag
 */

#include <OGoFoundation/LSWContentPage.h>

@class SkyPalmDataSourceViewerState, SkyPalmDocument;

@interface SkyPalmDataSourceViewer : LSWContentPage
{
@protected
  id              dataSource;   // datasource including palm-records
  SkyPalmDocument *record;       // record iteration
  id              state;        // viewer state

  BOOL            isCached;   // is CacheDataSource
  BOOL            insertForm;
}

/*
 * overwrite these methods in used subclasses:
 * - (NSString *)palmDb;
 * - (NSString *)itemKey;  // address | date | memo | job
 * - (NSString *)updateNotificationName;
 * - (NSString *)deleteNotificationName;
 * - (NSString *)newNotificationName;
 *
 */

- (SkyPalmDocument *)record;
- (id)recordIdentifier;
- (BOOL)hasNoAction;
- (id)dataSource;
- (SkyPalmDataSourceViewerState *)state;
- (void)setState:(SkyPalmDataSourceViewerState *)_state;

// record accessors
- (NSString *)syncState;

// actions
- (id)refresh;    // clears dataSource
- (id)viewAction; // perform parent action from binding

@end


#endif /* __LSWebInterface_SkyPalm_SkyPalmDataSourceViewer_H__ */
