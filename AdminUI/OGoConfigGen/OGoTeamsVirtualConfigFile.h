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

#ifndef __OGoTeamsVirtualConfigFile_H__
#define __OGoTeamsVirtualConfigFile_H__

#include "OGoVirtualConfigFile.h"

/*
  OGoTeamsVirtualConfigFile
  
  This is a dynamic configuration for generating Postfix virtual files for
  email addresses stored in the OGo team database. That is, it will generate
  the team address on the left side and all the team member addresses on the
  right (so that the all the team members get mail send to the team address).
*/

@interface OGoTeamsVirtualConfigFile : OGoVirtualConfigFile
{
  BOOL     ignoreExportFlag;
  BOOL     ignoreVirtualAddresses;
  
  BOOL     generateTeamEMail;
  BOOL     doNotGenerateAccountMails;

  NSString *rawPrefix;
  NSString *rawSuffix;
}

@end

#endif /* __OGoTeamsVirtualConfigFile_H__ */
