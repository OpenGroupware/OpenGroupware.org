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

#ifndef __Skyrix_SkyrixApps_Libraries_SkyProject_SkyProjectTeamDataSource_H__
#define __Skyrix_SkyrixApps_Libraries_SkyProject_SkyProjectTeamDataSource_H__

#include <OGoAccounts/SkyTeamDataSource.h>

@class SkyProject;

@interface SkyProjectTeamDataSource : EODataSource
{
  SkyProject *project;
  id         context;
}

- (id)initWithProject:(SkyProject *)_project context:(id)_context;

@end /* SkyProjectTeamDataSource */

#endif /* __Skyrix_SkyrixApps_Libraries_SkyProject_SkyProjectTeamDataSource_H__ */
