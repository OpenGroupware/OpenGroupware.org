/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#ifndef __tool_OGoAccountsVirtualConfigFile_H__
#define __tool_OGoAccountsVirtualConfigFile_H__

#include "OGoVirtualConfigFile.h"

@class NSArray;

@interface OGoAccountsVirtualConfigFile : OGoVirtualConfigFile
{
  BOOL     ignoreExportFlag;
  BOOL     ignoreVirtualAddresses;
  
  BOOL     ignoreLocalDomains;
  NSArray  *localDomainPatterns;
  
  BOOL     generateEmail1;
  BOOL     generateEmail2;
  BOOL     generateEmail3;

  NSString *rawPrefix;
  NSString *rawSuffix;
}

@end

#endif /* __tool_OGoAccountsVirtualConfigFile_H__ */
