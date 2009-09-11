/*
  Copyright (C) 2009 Whitemice Consulting

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


#include "zOGITaskNotification.h"

@implementation zOGITaskNotification

-(id)initWithContext:(LSCommandContext *)_ctx
{
  self = [super initWithContext:_ctx];
  return self;
}


- (NSString *)projectName:(id)_task 
{
  id        pkey;
  NSString *label;

  label = @"N/A";
  pkey = [_task valueForKey:@"projectId"];
  if ([pkey isNotNull])
  {
    id           project;
    EOGlobalID  *gid;

    gid = [[[self ctx] typeManager] globalIDForPrimaryKey:pkey];
    project = [[self ctx] runCommand:@"project::get-by-globalid",
                                     @"gid", gid,
                                     nil];
    if ([project isNotNull])
      label = [project valueForKey:@"name"];
  }
  return label;
} /* end projectName */

- (NSString *)creatorName:(id)_task;
{
  NSString   *label;
  id          pkey;
  id          account;
  EOGlobalID *gid;

  label = @"N/A";
  pkey = [_task valueForKey:@"creatorId"];
  gid = [[[self ctx] typeManager] globalIDForPrimaryKey:pkey];
  account = [[[self ctx] runCommand:@"person::get-by-globalid",
                                    @"gid", gid,
                                    @"returnType", intObj(LSDBReturnType_OneObject),
                                    nil] lastObject];
  if ([account isNotNull])
  {
    if ([[account valueForKey:@"email1"] isNotNull])
    {
      label = [NSString stringWithFormat:@"%@, %@ <%@>",
                          [account valueForKey:@"name"],
                          [account valueForKey:@"firstname"],
                          [account valueForKey:@"email1"]];
    } else label = [account valueForKey:@"login"];
  }
  return label;
}

- (NSString *)ownerName:(id)_task;
{
  NSString   *label;
  id          pkey;
  id          account;
  EOGlobalID *gid;

  label = @"N/A";
  pkey = [_task valueForKey:@"ownerId"];
  gid = [[[self ctx] typeManager] globalIDForPrimaryKey:pkey];
  account = [[[self ctx] runCommand:@"person::get-by-globalid",
                                    @"gid", gid,
                                    @"returnType", intObj(LSDBReturnType_OneObject),
                                    nil] lastObject];
  if ([account isNotNull])
  {
    if ([[account valueForKey:@"email1"] isNotNull])
    {
      label = [NSString stringWithFormat:@"%@, %@ <%@>",
                          [account valueForKey:@"name"],
                          [account valueForKey:@"firstname"],
                          [account valueForKey:@"email1"]];
    } else label = [account valueForKey:@"login"];
  }
  return label;
}

- (NSString *)executorName:(id)_task;
{
  id           pkey;
  id           tmp;
  EOGlobalID  *gid;
  NSString    *label;

  label = @"N/A";
  pkey = [_task valueForKey:@"executantId"];
  gid = [[[self ctx] typeManager] globalIDForPrimaryKey:pkey];
  if ([gid isNotNull])
  {
    if ([[gid entityName] isEqualToString:@"Person"])
    {
      tmp = [[[self ctx] runCommand:@"person::get-by-globalid",
                                    @"gid", gid,
                                    nil] lastObject];
      if ([[tmp valueForKey:@"email1"] isNotNull])
      {
        label = [NSString stringWithFormat:@"%@, %@ <%@>",
                            [tmp valueForKey:@"name"],
                            [tmp valueForKey:@"firstname"],
                            [tmp valueForKey:@"email1"]];
      } else label = [tmp valueForKey:@"login"];
    } else if ([[gid entityName] isEqualToString:@"Team"])
      {
        tmp = [[[self ctx] runCommand:@"team::get-by-globalid",
                                      @"gid", gid,
                                      nil] lastObject];
        if ([tmp isNotNull])
          label = [tmp valueForKey:@"description"];
      } else [self warnWithFormat:@"Task#%@ with unusual executor type of %@",
                                  [_task valueForKey:@"jobId"],
                                  [gid entityName]];
  }
  return label;
}

@end /* zOGITaskNotification */
