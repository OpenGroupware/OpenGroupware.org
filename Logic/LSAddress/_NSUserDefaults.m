/* 
   _NSUserDefaults.m

   Copyright (C) 1995, 1996, 1997 Ovidiu Predescu and Mircea Oancea.
   

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
	   Ovidiu Predescu <ovidiu@net-community.com>

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

#include "_NSUserDefaults.h"
#include "common.h"

// TODO: remove this dependency

@implementation lfNSUserDefaults

/* Getting and Setting a Default */

- (NSArray *)arrayForKey:(NSString *)defaultName {
    id obj = [self objectForKey:defaultName];
    if ([obj isKindOfClass:[NSArray class]])
	return obj;
    return nil;
}
- (NSDictionary*)dictionaryForKey:(NSString*)defaultName {
    id obj = [self objectForKey:defaultName];
    if ([obj isKindOfClass:[NSDictionary class]])
	return obj;
    return nil;
}
- (NSData *)dataForKey:(NSString *)defaultName; {
    id obj = [self objectForKey:defaultName];
    if ([obj isKindOfClass:[NSData class]])
	return obj;
    return nil;
}

- (NSArray *)stringArrayForKey:(NSString *)defaultName {
    id obj = [self objectForKey:defaultName];
    if ([obj isKindOfClass:[NSArray class]]) {
	int n;
	Class strClass = [NSString class];
	
	for (n = [obj count]-1; n >= 0; n--)
	    if (![[obj objectAtIndex:n] isKindOfClass:strClass])
		return nil;

	return obj;
    }
    return nil;
}

- (NSString *)stringForKey:(NSString *)defaultName {
    id obj = [self objectForKey:defaultName];
    if ([obj isKindOfClass:[NSString class]])
	return obj;
    return nil;
}

- (BOOL)boolForKey:(NSString *)defaultName {
    id obj;

    if ((obj = [self objectForKey:defaultName])) {
      if ([obj isKindOfClass:[NSString class]]) {
	if ([obj compare:@"YES" options:NSCaseInsensitiveSearch] == 
            NSOrderedSame) {
          return YES;
        }
      }
      if ([obj respondsToSelector:@selector(intValue)])
          return [obj intValue] ? YES : NO;
    }
    return NO;
}

- (float)floatForKey:(NSString*)defaultName
{
    id obj = [self stringForKey:defaultName];
    if (obj) 
	return [obj floatValue];
    return 0;
}

- (int)integerForKey:(NSString*)defaultName
{
    id obj = [self stringForKey:defaultName];
    if (obj) 
	return [obj intValue];
    return 0;
}

- (void)setBool:(BOOL)value forKey:(NSString*)defaultName
{
    [self setObject:(value ? @"YES" : @"NO") 
	    forKey:defaultName];
}

- (void)setFloat:(float)value forKey:(NSString*)defaultName
{
    [self setObject:[NSString stringWithFormat:@"%f", value]
	    forKey:defaultName];
}

- (void)setInteger:(int)value forKey:(NSString*)defaultName
{
    [self setObject:[NSString stringWithFormat:@"%d", value] 
	    forKey:defaultName];
}

/* Accessing app domain defaults */

- (id)objectForKey:(NSString*)defaultName
{
    int i, n = [self->searchList count];
    
    for (i = 0; i < n; i++) {
	NSString*     name   = [self->searchList objectAtIndex:i];
	NSDictionary* domain = nil;
	id            obj;
	
	if ((domain = [self->volatileDomains objectForKey:name])) {
	    if (domain && (obj = [domain objectForKey:defaultName]))
		return obj;
        }
	if ((domain = [self->persistentDomains objectForKey:name])) {
	    if (domain && (obj = [domain objectForKey:defaultName]))
		return obj;
        }
    }
    return nil;
}

- (void)setObject:(id)value forKey:(NSString*)defaultName
{
    NSMutableDictionary *domain;
    
    domain = (NSMutableDictionary *)[self persistentDomainForName:appDomain];
    if (value == nil) {
        fprintf(stderr,
                "WARNING: attempt to set nil value for "
                "default %s in domain %s\n",
                [defaultName cString], [appDomain cString]);
    }
    [domain setObject:value forKey:defaultName];
    [self persistentDomainHasChanged:appDomain];
}

- (void)removeObjectForKey:(NSString *)defaultName {
  NSMutableDictionary *domain;
  
  domain = (id)[self persistentDomainForName:appDomain];
  [domain removeObjectForKey:defaultName];
  [self persistentDomainHasChanged:appDomain];
}

/* Returning the Search List */

- (void)setSearchList:(NSArray *)_searchList {
  id old = self->searchList;
  self->searchList = [_searchList mutableCopy];
  [old release];
}
- (NSArray *)searchList {
  return self->searchList;
}

/* Making Advanced Use of Defaults */

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict;
    int i, n;
    
    dict = AUTORELEASE([[NSMutableDictionary alloc] init]);
    n = [searchList count];
    
    for (i = n - 1; i >= 0; i--) {
	NSString     *name;
        NSDictionary *domain;
        
        name = [searchList objectAtIndex:i];
	
	if ((domain = [volatileDomains objectForKey:name]))
	    [dict addEntriesFromDictionary:domain];
	if ((domain = [persistentDomains objectForKey:name]))
	    [dict addEntriesFromDictionary:domain];
    }

    return dict;
}

- (void)registerDefaults:(NSDictionary *)dictionary
{
    NSMutableDictionary *regDomain;
    
    regDomain = (NSMutableDictionary *)
        [self volatileDomainForName:NSRegistrationDomain];
    
    if ([self->searchList indexOfObjectIdenticalTo:regDomain] == NSNotFound)
	[self->searchList addObject:NSRegistrationDomain];
    
    [regDomain addEntriesFromDictionary:dictionary];
}

/* Maintaining Volatile Domains */

- (void)removeVolatileDomainForName:(NSString*)domainName
{
    /* apparently in MacOSX-S the name isn't removed from the search list */
    [self->searchList removeObject:domainName];
    [self->volatileDomains removeObjectForKey:domainName];
}

- (void)setVolatileDomain:(NSDictionary *)domain  
  forName:(NSString *)domainName
{
  NSMutableDictionary *md;
  
  if ([volatileDomains objectForKey:domainName]) {
    [NSException raise:NSInvalidArgumentException
		 format:@"volatile domain %@ already exists", domainName];
  }
  
  md = [[NSMutableDictionary alloc] initWithDictionary:domain];
  [volatileDomains setObject:md forKey:domainName];
  [md release];
}

- (NSDictionary *)volatileDomainForName:(NSString *)domainName {
  return [volatileDomains objectForKey:domainName];
}

- (NSArray *)volatileDomainNames {
  return [volatileDomains allKeys];
}

/* Maintaining Persistent Domains */

- (NSDictionary *)loadPersistentDomainNamed:(NSString *)domainName {
  return nil;
}
- (BOOL)savePersistentDomainNamed:(NSString*)domainName {
  return NO;
}
- (void)removePersistentDomainForName:(NSString*)domainName {
}
- (NSDictionary *)persistentDomainForName:(NSString*)domainName {
  return nil;
}
- (void)setPersistentDomain:(NSDictionary*)domain forName:(NSString*)_name {
}
- (NSArray *)persistentDomainNames {
  return nil;
}

/* Creation of defaults */

/* Initializing the User Defaults */

- (id)init {
    self->persistentDomains = [[NSMutableDictionary alloc] init];
    self->volatileDomains   = [[NSMutableDictionary alloc] init];
    self->domainsToRemove   = [[NSMutableSet        alloc] init];
    self->dirtyDomains      = [[NSMutableSet        alloc] init];
    self->searchList        = [[NSMutableArray      alloc] init];
    self->appDomain         = [[[NSProcessInfo processInfo] processName] copy];
    
    return self;
}

- (void)dealloc
{
    RELEASE(self->directoryForSaving);
    RELEASE(self->appDomain);
    RELEASE(self->persistentDomains);
    RELEASE(self->volatileDomains);
    RELEASE(self->searchList);
    RELEASE(self->domainsToRemove);
    RELEASE(self->dirtyDomains);
    [super dealloc];
}

- (void)makeStandardDomainSearchList
{
    int i,n;
    NSArray *languages;
    
    /* make clear list */
    [searchList removeAllObjects];
    
    /* make argument domain */
    [searchList addObject:NSArgumentDomain];
    
    /* make app domain */
    [searchList addObject:appDomain];
    
    /* make global domain */
    [searchList addObject:NSGlobalDomain];
    
    /* add languages domains */
    languages = [[self persistentDomainForName:NSGlobalDomain] 
                       objectForKey:@"Languages"];
    if (!languages) {
	languages = [NSArray arrayWithObject:@"English"];
    }
    for (i = 0, n = [languages count]; i < n; i++) {
	NSString* lang = [languages objectAtIndex:i];
	/* check that the domain exists */
	if ([self persistentDomainForName:lang]) {
	    [searchList addObject:lang];
	}
    }

    /* add catch-all registration domain */
    [searchList addObject:NSRegistrationDomain];
}

- (BOOL)synchronize
{
    NSEnumerator *enumerator;
    NSString     *domainName;
    BOOL         allOk = YES;
    
    enumerator = [self->dirtyDomains objectEnumerator];
    while ((domainName = [enumerator nextObject]))
	allOk = allOk && [self savePersistentDomainNamed:domainName];
    
    enumerator = [self->domainsToRemove objectEnumerator];
    while ((domainName = [enumerator nextObject])) {
	NSString* path = [[self->directoryForSaving
			    stringByAppendingPathComponent:domainName]
			    stringByAppendingPathExtension:@"plist"];

	[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
    }
    return allOk;
}

- (void)persistentDomainHasChanged:(NSString*)domainName
{
    if (![self->dirtyDomains containsObject:domainName]) {
	[self->dirtyDomains addObject:domainName];
	[[NSNotificationCenter defaultCenter]
	    postNotificationName:NSUserDefaultsDidChangeNotification
	    object:self
	    userInfo:nil];
    }
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  [self setObject:_value forKey:_key];
}
- (id)valueForKey:(NSString *)_key {
  return [self objectForKey:_key];
}

@end /* lfNSUserDefaults */
