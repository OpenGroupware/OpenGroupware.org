/*
  Copyright (C) 2004 Helge Hess

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

#ifndef __ZSContacts_ZSPersonListEntryRenderer_H__
#define __ZSContacts_ZSPersonListEntryRenderer_H__

#import <Foundation/NSObject.h>

/*
  ZSPersonListEntryRenderer

  Renders a person record of a list query into a WebDAV response record.
*/

@interface ZSPersonListEntryRenderer : NSObject
{
}

+ (id)sharedListEntryRenderer;

/* rendering */

- (id)renderEntry:(id)_entry representingSoObject:(id)_object;

@end

#endif /* __ZSContacts_ZSPersonListEntryRenderer_H__ */
