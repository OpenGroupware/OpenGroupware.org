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

#ifndef __SkyPalmDateDocumentCopy_H__
#define __SkyPalmDateDocumentCopy_H__

#include <OGoPalm/SkyPalmDateDocument.h>

@interface SkyPalmDateDocumentCopy : SkyPalmDateDocument
{
  SkyPalmDateDocument *origin;
  unsigned            idx;
  id                  gid;
}
+ (SkyPalmDateDocument *)documentWithDocument:(SkyPalmDateDocument *)_src
                                   dataSource:(SkyPalmDocumentDataSource *)_ds
                                    startdate:(NSCalendarDate *)_start
                                      enddate:(NSCalendarDate *)_end
                                        index:(unsigned)_repetitionIndex;

- (id)initAsCopyWithDictionary:(NSDictionary *)_src
                         index:(unsigned)_repetitionIndex
                        origin:(SkyPalmDateDocument *)_doc
                fromDataSource:(SkyPalmDocumentDataSource *)_ds;

- (SkyPalmDateDocument *)origin;
- (unsigned)repetitionIndex;
- (id)detachFromOrigin;

@end

#endif /* __SkyPalmDateDocumentCopy_H__ */
