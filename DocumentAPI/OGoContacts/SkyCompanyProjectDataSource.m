/*
  Copyright (C) 2000-2003 SKYRIX Software AG

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

#include "SkyCompanyProjectDataSource.h"
#include "common.h"
  
@implementation SkyCompanyProjectDataSource

static NSArray *invProjects = nil;

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if (invProjects == nil)
    invProjects = [[NSArray alloc] initWithObjects:@"00_invoiceProject", nil];
}

- (id)initWithContext:(id)_ctx companyId:(EOGlobalID *)_gid {
  NSAssert(_ctx, @"missing context for datasource !");
  NSAssert1(_gid, @"missing %@ gid for datasource !",
            [self nameOfCompanyEntity]);
  
  if ((self = [super init])) {
    self->context  = RETAIN(_ctx);
    self->companyId = RETAIN(_gid);
  }
  return self;
}
- (id)initWithContext:(id)_ctx {
  return [self initWithContext:_ctx companyId:nil];
}
- (id)init {
  return [self initWithContext:nil companyId:nil];
}

- (void)dealloc {
  [self->fetchSpecification release];
  [self->companyId release];
  [self->context   release];
  [super dealloc];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if ([self->fetchSpecification isEqual:_fSpec])
    return;

  ASSIGNCOPY(self->fetchSpecification, _fSpec);
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return [[self->fetchSpecification copy] autorelease];
}

- (id)context {
  return self->context;
}

/* commands */

- (NSString *)nameOfCompanyGetCommand {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfCompanyProjectCommand {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfCompanyEntity {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

/* fetching */

- (NSArray *)_withoutKinds {
  return invProjects;
}

- (NSArray *)fetchObjects {
  NSArray *projects;
  id      company;

  /* could introduce hint to set this dynamically .. */
  if (self->companyId == nil)
    return nil;
  
  NS_DURING {
    company =
      [[self->context runCommand:[self nameOfCompanyGetCommand],
            @"gid", self->companyId, nil] lastObject];
    NSAssert2(company, @"couldn't get %@ for gid %@",
                       [self nameOfCompanyEntity], self->companyId);
    
    projects =
      [self->context runCommand:[self nameOfCompanyProjectCommand],
              @"object",       company,
              @"withoutKinds", [self _withoutKinds],
              nil];
  }
  NS_HANDLER {
    *(&projects) = nil;
    ASSIGN(self->lastException, localException);
  }
  NS_ENDHANDLER;


  {
    NSArray     *sortOrderings = nil;
    EOQualifier *qualifier     = nil;

    if ((qualifier = [self->fetchSpecification qualifier]) != nil)
      projects = [projects filteredArrayUsingQualifier:qualifier];
    if ((sortOrderings = [self->fetchSpecification sortOrderings]) != nil)
      projects = [projects sortedArrayUsingKeyOrderArray:sortOrderings];
  }

  return projects;
}

/* operations */

- (id)createObject {
  /* should use SkyProjectDataSource to create a project and associate
     the companyId with the project */
  return nil;
}

- (void)insertObject:(id)_object {
  /*
    If the _object is a new document, this should use SkyProjectDataSource
    to create the project.
    If the object is an existing document, this should add the company as
    a one associated to the project
  */
  [self notImplemented:_cmd];
}
- (void)deleteObject:(id)_object {
  /*
    If the company is the last associated one with the project, the project
    should be deleted/archived using SkyProjectDataSource.
    
    If the object has more associated companys, this should remove the company
    from the associated ones.
  */
  [self notImplemented:_cmd];
}

- (void)updateObject:(id)_object {
  /* should use SkyProjectDataSource to update changes on Project Document */
  [self notImplemented:_cmd];
}

@end /* SkyCompanyProjectDataSource */
