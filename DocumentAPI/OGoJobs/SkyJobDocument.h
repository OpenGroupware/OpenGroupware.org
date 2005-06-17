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

#ifndef __OGoJobs_SkyJobDocument_H_
#define __OGoJobs_SkyJobDocument_H_

#include <OGoDocuments/SkyDocument.h>

@class NSArray, NSNumber, NSString, NSDictionary, NSCalendarDate;
@class EODataSource, EOGlobalID;

@interface SkyJobDocument : SkyDocument
{
  EODataSource      *dataSource;
  EOGlobalID        *globalID;

  NSString          *name;
  NSCalendarDate    *startDate;
  NSCalendarDate    *endDate;
  NSString          *keywords;
  NSString          *category;
  NSString          *jobStatus;
  NSNumber          *priority;
  NSString          *type;

  NSNumber          *sensitivity;
  NSString          *comment;
  NSCalendarDate    *completionDate;
  NSNumber          *percentComplete;

  NSString          *accountingInfo;
  NSString          *associatedCompanies;
  NSString          *associatedContacts;
  
  NSNumber          *actualWork;
  NSNumber          *totalWork;
  NSNumber          *kilometers;
  
  NSString          *createComment;
  // only valid if job isn't saved yet
  // the comment when creating the job

  NSNumber          *objectVersion;
  NSArray           *supportedAttributes;
  BOOL              isTeamJob;
  
  SkyDocument *creator;  // creatorId   // toCreator
  SkyDocument *executor; // executantId // toExecutant

  struct {
    BOOL isEdited;
    BOOL isValid;
    BOOL isComplete;
  } status;
}

- (id)initWithEO:(id)_job dataSource:(EODataSource *)_ds;
- (id)initWithJob:(id)_job
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds;

- (void)invalidate;
- (BOOL)isValid;

/* attributes */

- (BOOL)isNew;
- (BOOL)isEdited;
- (BOOL)isComplete;

/* operations */

- (BOOL)save;
- (BOOL)delete;
- (BOOL)reload;

/* --------- */

- (id)context;

/* attributes */

- (NSString *)name;
- (void)setName:(NSString *)_name;

- (void)setStartDate:(NSCalendarDate *)_startDate;
- (NSCalendarDate *)startDate;

- (void)setEndDate:(NSCalendarDate *)_endDate;
- (NSCalendarDate *)endDate;

- (void)setKeywords:(NSString *)_keywords;
- (NSString *)keywords;

- (void)setCategory:(NSString *)_category;
- (NSString *)category;

- (void)setStatus:(NSString *)_status; // jobStatus
- (NSString *)status;

- (void)setPriority:(NSNumber *)_priority;
- (NSNumber *)priority;

/* OL: 0-normal/undef, 1-personal, 2-private, 3-confidential */
- (void)setSensitivity:(NSNumber *)_sensitivity;
- (NSNumber *)sensitivity;

- (void)setComment:(NSString *)_comment;
- (NSString *)comment;

- (void)setCompletionDate:(NSCalendarDate *)_completionDate;
- (NSCalendarDate *)completionDate;

- (void)setPercentComplete:(NSNumber *)_percentComplete;
- (NSNumber *)percentComplete;

- (void)setAccountingInfo:(NSString *)_accountingInfo;
- (NSString *)accountingInfo;

- (void)setAssociatedCompanies:(NSString *)_associatedCompanies;
- (NSString *)associatedCompanies;

- (void)setAssociatedContacts:(NSString *)_associatedContacts;
- (NSString *)associatedContacts;

- (void)setActualWork:(NSNumber *)_actualWork;
- (NSNumber *)actualWork;

- (void)setTotalWork:(NSNumber *)_totalWork;
- (NSNumber *)totalWork;

- (void)setKilometers:(NSNumber *)_kilometers;
- (NSNumber *)kilometers;




- (NSString *)type;
- (void)setType:(NSString *)_type;

- (NSNumber *)objectVersion;

- (void)setCreator:(SkyDocument *)_creator;
- (SkyDocument *)creator;  // creatorId   // toCreator

- (void)setExecutor:(SkyDocument *)_executor;
- (SkyDocument *)executor; // executantId // toExecutant

// only valid if job not yet saved
- (void)setCreateComment:(NSString *)_comment;
- (NSString *)createComment;

- (EODataSource *)historyDataSource;

- (NSDictionary *)asDict;

- (EODataSource *)dataSource;

/* restricting the support of attributes:
   
  Actually all *common* attributes are supported in any time,
  but you can forbid some types of attributes. Valid attribute types are:
      "creator",
      "executor"

*/

- (void)setSupportedAttributes:(NSArray *)_attrs;
- (NSArray *)supportedAttributes;
- (BOOL)isAttributeSupported:(NSString *)_attr;


/*
   "jobId": {
    "parentJobId": {
    "projectId": {
    "notify": {
    "isControlJob": {
    "isTeamJob": {
    "kind": {
    "dbStatus": {
    "objectVersion": {
    
    "toProject": {
    "toParentJob": {
    "toJob": {
    "toJobHistory": {
    "toResourceAssignment": {
    "toChildJobAssignment": {
    "toParentJobAssignment": {
*/
@end

#endif /* __OGoJobs_SkyJobDocument_H_ */
