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

#ifndef __OGoWebMail_OGoMailAddressSearch_H__
#define __OGoWebMail_OGoMailAddressSearch_H__

#import <Foundation/NSObject.h>

/*
  OGoMailAddressSearch
  
  This object is to search for email addresses which are going to be added
  as a mail-editor popup. Eg this searches in the accounts database as well
  as in mailing lists etc.
  
  Maybe this should become a command in the long run (input: a string,
  output: a list of dictionaries describing the found entries).
  
  TODO: maybe we can easily support LDAP for mailaddress searches by modifying
        this object?
*/

@class NSString, NSArray, NSDictionary, NSMutableArray;
@class LSCommandContext;
@class SkyImapMailRestrictions;
@class OGoMailAddressRecord, OGoMailAddressRecordResult;

@interface OGoMailAddressSearch : NSObject
{
  LSCommandContext        *cmdctx;
  SkyImapMailRestrictions *mailRestrictions;
  unsigned int maxSearchCount;
  unsigned int currentMailCount;
  unsigned int currentFetchCount;
  
  id labels; // TODO: move out of this 'processing' object!
}

- (id)initWithCommandContext:(LSCommandContext *)_ctx;

/* accessors */

- (void)setMailRestrictions:(SkyImapMailRestrictions *)_restrictions;
- (SkyImapMailRestrictions *)mailRestrictions;

- (void)setLabels:(id)_labels;
- (id)labels;

/* caches */

- (void)reset;

/* processing */

- (NSArray *)findEmailAddressesForSearchStrings:(NSArray *)_searchStrings
  addFirstFoundAsTo:(BOOL)_addFirstFoundAsTo
  prohibited:(NSArray **)prohibited_;

- (NSDictionary *)findEmailAddressesForSearchString:(NSString *)_searchString 
  addFirstFoundAsTo:(BOOL)_addFirstFoundAsTo
  prohibited:(NSArray **)prohibited_;


/* low level fetch API (used by subclasses) */

- (BOOL)canFetchMoreMailEntries;
- (NSMutableArray *)_fetchAllCompanyEOsMatchingString:(NSString *)_search;
- (void)_processCompany:(id)_company andAddRecordsToArray:(NSMutableArray *)_a;
- (id)_emailSearchRecord:(NSString *)_key value:(NSString *)_value;
- (NSArray *)fetchPersonsMatchingSearchRecord:(id)_record;
- (NSArray *)fetchPersonsMatchingAllSearchRecords:(NSArray *)_recs;
- (NSArray *)fetchTeamsWithDescription:(NSString *)_search;
- (NSArray *)fetchEnterprisesMatchingSearchRecord:(id)_record;
- (NSArray *)fetchEnterprisesMatchingAllSearchRecords:(NSArray *)_recs;

- (void)_searchMailingListsForString:(NSString *)_searchString 
  andAddRecordsToArray:(NSMutableArray *)emails;

- (NSString *)label_prohibited;

- (OGoMailAddressRecord *)recordForEmail:(NSString *)_email 
  label:(NSString *)_label;
- (OGoMailAddressRecord *)_emptyEntry;
- (OGoMailAddressRecord *)_restrictedSearchEntry:(NSString *)_s;

- (OGoMailAddressRecordResult *)resultSetForMails:(NSArray *)_emails
  addFirstFoundAsTo:(BOOL)_addFirstFoundAsTo;

@end

@interface OGoSimpleMailAddressSearch : OGoMailAddressSearch
@end

@interface OGoComplexMailAddressSearch : OGoMailAddressSearch
@end

#endif /* __OGoWebMail_OGoMailAddressSearch_H__ */
