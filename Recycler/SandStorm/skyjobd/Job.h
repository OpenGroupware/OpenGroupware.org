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
// $id$

#ifndef __SkyJobDaemon_Job_H__
#define __SkyJobDaemon_Job_H__

#import <Foundation/NSObject.h>

@class NSString, NSDictionary;
@class EOGenericRecord, SkyJobQualifier;

@interface Job : NSObject
{
  EOGenericRecord *record;
  NSString *jobId;
  id context;
}
  
- (id)initWithEOGenericRecord:(id)_record context:(id)_ctx;

+ (Job *)jobWithContext:(id)_ctx attributes:(NSDictionary *)_attributes;
+ (Job *)jobWithContext:(id)_ctx record:(EOGenericRecord *)_record;

/* accessors */

- (void)setRecord:(id)_record;
- (id)record;
- (void)setJobId:(NSString *)_jobId;
- (NSString *)jobId;
- (id)commandContext;

- (NSDictionary *)dictionaryForQualifier:(SkyJobQualifier *)_qual;

/* actions */

- (BOOL)updateWithAttributes:(NSDictionary *)_attributes;
- (BOOL)delete;
- (NSArray *)getJobHistory;
- (BOOL)setJobStatus:(NSString *)_status withComment:(NSString *)_comment;

@end /* Job */

#endif /* __SkyJobDaemon_Job_H__ */
