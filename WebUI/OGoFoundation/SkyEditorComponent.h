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

#ifndef __LSWebInterface_LSWFoundation_SkyEditorComponent_H__
#define __LSWebInterface_LSWFoundation_SkyEditorComponent_H__

#include <OGoFoundation/OGoComponent.h>

@class NSMutableDictionary, NSDictionary, NSString;
@class NGMimeType, SkyDocument;

@interface SkyEditorComponent : OGoComponent
{
@private
  SkyDocument *document;
  BOOL        didPrepareEditor;
}

- (void)prepareEditor;

/* accessors */

- (void)setDocument:(id)_docuement;
- (SkyDocument *)document;

/* constraints (return NO if contraints fail) */

- (BOOL)checkConstraintsForSave;
- (BOOL)checkConstraintsForDelete;
- (BOOL)checkConstraintsForCancel;

/* actions */

- (BOOL)save;   // update or insert record
- (BOOL)delete; // delete record (not applicable in new mode)
- (BOOL)cancel; // cancel editor

@end

#endif /* __LSWebInterface_LSWFoundation_SkyEditorComponent_H__ */
