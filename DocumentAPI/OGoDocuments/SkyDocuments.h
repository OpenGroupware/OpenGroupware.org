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

#ifndef __SkyDocuments_H__
#define __SkyDocuments_H__

/**
 * @file SkyDocuments.h
 * @brief Umbrella header for the OGoDocuments framework.
 *
 * Imports all public headers of the OGoDocuments framework,
 * including the document model, file manager protocols, and
 * the local filesystem-based implementations.
 */

#include <OGoDocuments/SkyDocument.h>
#include <OGoDocuments/SkyDocumentFileManager.h>
#include <OGoDocuments/SkyDocumentType.h>
#include <OGoDocuments/NGLocalFileManager.h>
#include <OGoDocuments/NGLocalFileDocument.h>
#include <OGoDocuments/NGLocalFileDataSource.h>
#include <OGoDocuments/NGLocalFileGlobalID.h>

#endif /* __SkyDocuments_H__ */
