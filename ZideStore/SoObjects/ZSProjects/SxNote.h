/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#ifndef __Projects_SxNote_H__
#define __Projects_SxNote_H__

#include <ZSFrontend/SxObject.h>

/*
  SxNote
  
    parent-folder: SxProjectNotesFolder | SxAppointmentNotesFolder
    subjects:      none
*/

@class NSString;
@class EOGlobalID;
@class SxProjectFolder;

@interface SxNote : SxObject
{
  id noteEO; // TODO: the superclass already has an 'eo' ivar?
}

- (id)initWithName:(NSString *)_key inContainer:(id)_folder;

/* accessors */

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx;
- (SxProjectFolder *)projectFolder;

@end

#endif /* __Projects_SxNote_H__ */
