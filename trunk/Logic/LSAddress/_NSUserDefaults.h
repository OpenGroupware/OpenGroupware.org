/* 
   _NSUserDefaults.h

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   This file is part of libFoundation.

   Permission to use, copy, modify, and distribute this software and its
   documentation for any purpose and without fee is hereby granted, provided
   that the above copyright notice appear in all copies and that both that
   copyright notice and this permission notice appear in supporting
   documentation.

   We disclaim all warranties with regard to this software, including all
   implied warranties of merchantability and fitness, in no event shall
   we be liable for any special, indirect or consequential damages or any
   damages whatsoever resulting from loss of use, data or profits, whether in
   an action of contract, negligence or other tortious action, arising out of
   or in connection with the use or performance of this software.
*/

#ifndef __SkyNSUserDefaults_h__
#define __SkyNSUserDefaults_h__

#import <Foundation/NSObject.h>

@class NSString, NSData;
@class NSArray, NSMutableArray;
@class NSDictionary, NSMutableDictionary;
@class NSMutableSet;

@interface lfNSUserDefaults : NSObject
{
    NSString            *directoryForSaving;
    NSString            *appDomain;
    NSMutableDictionary *persistentDomains;
    NSMutableDictionary *volatileDomains;
    NSMutableArray      *searchList;
    NSMutableSet        *domainsToRemove;
    NSMutableSet        *dirtyDomains;
}

/* Getting and Setting a Default */

- (NSArray *)arrayForKey:(NSString *)defaultName;
- (NSDictionary *)dictionaryForKey:(NSString *)defaultName;
- (NSData *)dataForKey:(NSString *)defaultName;
- (NSArray *)stringArrayForKey:(NSString *)defaultName;
- (NSString *)stringForKey:(NSString *)defaultName;
- (BOOL)boolForKey:(NSString *)defaultName;
- (float)floatForKey:(NSString *)defaultName;
- (int)integerForKey:(NSString *)defaultName;

- (id)objectForKey:(NSString *)defaultName;
- (void)removeObjectForKey:(NSString *)defaultName;

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
- (void)setFloat:(float)value forKey:(NSString *)defaultName;
- (void)setInteger:(int)value forKey:(NSString *)defaultName;
- (void)setObject:(id)value forKey:(NSString *)defaultName;

/* Initializing the User Defaults */

- (void)makeStandardDomainSearchList;

/* Returning the Search List */

- (void)setSearchList:(NSArray *)_array;
- (NSArray *)searchList;

/* Maintaining Persistent Domains */

- (NSDictionary *)persistentDomainForName:(NSString *)domainName;
- (NSArray *)persistentDomainNames;
- (void)removePersistentDomainForName:(NSString *)domainName;
- (void)setPersistentDomain:(NSDictionary *)domain
  forName:(NSString *)domainName;
- (BOOL)synchronize;
- (void)persistentDomainHasChanged:(NSString *)domainName;

/* Maintaining Volatile Domains */

- (void)removeVolatileDomainForName:(NSString *)domainName;
- (void)setVolatileDomain:(NSDictionary *)domain  
  forName:(NSString *)domainName;
- (NSDictionary *)volatileDomainForName:(NSString *)domainName;
- (NSArray *)volatileDomainNames;

/* Making Advanced Use of Defaults */

- (NSDictionary *)dictionaryRepresentation;
- (void)registerDefaults:(NSDictionary *)dictionary;

@end

#endif /* __SkyNSUserDefaults_h__ */
