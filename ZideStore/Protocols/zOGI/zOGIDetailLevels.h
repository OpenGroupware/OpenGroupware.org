/*
  Copyright (C) 2006-2007 Whitemice Consulting

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

#ifndef __zOGI_DetailLevels_H__
#define __zOGI_DetailLevels_H__

#define zOGI_INCLUDE_NONE              0
#define zOGI_INCLUDE_NOTATIONS         1
#define zOGI_INCLUDE_OBJLINKS          2
#define zOGI_INCLUDE_PARTICIPANTS      4
#define zOGI_INCLUDE_COMPANYVALUES     8
#define zOGI_INCLUDE_PROPERTIES       16
#define zOGI_INCLUDE_LOGS             32
#define zOGI_INCLUDE_CONFLICTS        64
#define zOGI_INCLUDE_MEMBERSHIP      128
#define zOGI_INCLUDE_CONTACTS        256
#define zOGI_INCLUDE_ENTERPRISES     512
#define zOGI_INCLUDE_PROJECTS       1024
#define zOGI_INCLUDE_COMMENT        2048
#define zOGI_INCLUDE_TASKS          4096
#define zOGI_INCLUDE_PLUGINS        8192
#define zOGI_INCLUDE_CONTENTS      16384
#define zOGI_INCLUDE_ACLS          32768

#define zOGI_INCLUDE_EVERYTHING    65535

#endif /* zOGI_DetailLevels_H__ */
