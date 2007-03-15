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

#include <OGoFoundation/LSWContentPage.h>

@class NSArray, NSString;
@class EOGlobalID;

@interface SkyNoteList : LSWContentPage
{
  BOOL       printMode;
  EOGlobalID *projectId;
  NSArray    *notes;
  NSArray    *projects;
  id         appointment;
  id         project;
  id         note;
  id         rootDocument;
  NSString   *title;
  NSString   *newNoteTitle;
  NSString   *newNoteBody;
  struct {
    int isProjectEnabled:1;
    int reserved:31;
  } snlFlags;
}

- (void)setNotes:(NSArray *)_notes;
- (NSArray *)notes;
- (void)setNote:(id)_note;
- (id)note;
- (void)setTitle:(NSString *)_title;
- (NSString *)title;
- (NSString *)noteContent;
- (id)project;
- (BOOL)printMode;
- (void)setPrintMode:(BOOL)_printMode;
- (id)printNotes;

@end
