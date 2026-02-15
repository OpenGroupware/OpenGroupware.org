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

#ifndef __SkyDocumentType_H__
#define __SkyDocumentType_H__

#import <Foundation/NSObject.h>

/**
 * @class SkyDocumentType
 * @brief Describes the schema of an OGo document.
 *
 * Analogous to EOClassDescription, SkyDocumentType is
 * intended to describe the type and schema of a document.
 *
 * Note: This is largely a conceptual placeholder and is
 * not heavily used in practice.
 *
 * @see SkyDocument
 */
@interface SkyDocumentType : NSObject
@end

#endif /* __SkyDocumentType_H__ */
