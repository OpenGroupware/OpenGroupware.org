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

#ifndef __OGoMailViewers_LSWMimeBodyPartViewer_H__
#define __OGoMailViewers_LSWMimeBodyPartViewer_H__

#include "LSWMimePartViewer.h"

/*
  LSWMimeBodyPartViewer
  
  A bodypart is the actual body like an image or a text plus the header
  information associated with the part, like the content type or disposition.
  
  The body part viewer triggers the content viewer component for a body and
  shows some header information. For non composite types it also allows you to
  copy the content to a project.
  
  Note: the content copying is actually implemented in the superclass.
*/

@interface LSWMimeBodyPartViewer : LSWMimePartViewer
{
  BOOL showRfc822;
}

@end

#endif /* __OGoMailViewers_LSWMimeBodyPartViewer_H__ */
