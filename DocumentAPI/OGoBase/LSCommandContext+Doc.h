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

#ifndef __OGoBase_LSCommandContext_Doc_H__
#define __OGoBase_LSCommandContext_Doc_H__

/**
 * @file LSCommandContext+Doc.h
 * @brief Re-export of the LSCommandContext(Doc) category.
 *
 * This umbrella header re-exports the
 * LSCommandContext(Doc) category defined in
 * OGoDocuments, which extends LSCommandContext with
 * the SkyContext protocol and provides access to the
 * SkyDocumentManager. Including this header from OGoBase
 * makes the category available to higher-level modules
 * without a direct OGoDocuments import.
 *
 * @see LSCommandContext
 * @see SkyDocumentManager
 */

#include <OGoDocuments/LSCommandContext+Doc.h>

#endif /* __OGoBase_LSCommandContext_Doc_H__ */
