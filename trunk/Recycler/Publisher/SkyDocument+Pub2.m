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

#include "SkyDocument+Pub.h"
#include "PubKeyValueCoding.h"
#include <OGoDocuments/SkyDocumentFileManager.h>
#include "common.h"

@implementation SkyDocument(Pub2)

- (NSString *)npsDocumentType {
  NSString *mimeType;

  if ([[self valueForKey:NSFileType] isEqual:NSFileTypeDirectory])
    return @"publication";
  
  if ([[[self pubPath] pathExtension] isEqualToString:@"xtmpl"])
    return @"template";
  
  if ((mimeType = [self valueForKey:@"NSFileMimeType"]) == nil)
    return @"gendoc";
  
  if ([mimeType hasPrefix:@"image/"])
    return @"image";
  
  if ([mimeType hasPrefix:@"text/xhtml"])
    return @"document";
  if ([mimeType hasPrefix:@"text/html"])
    return @"document";
  
  if ([mimeType hasPrefix:@"text/xtmpl"])
    return @"template";
  
  return @"";
}

- (NSString *)npsDocumentClassName {
  return [self npsDocumentType];
}

- (id)npsFolderValueForKey:(NSString *)_simplename inContext:(id)_ctx {
  NSString *path;
  SkyDocument *idx;
  
  path = [self valueForKey:@"NSFilePath"];
  
  if ([_simplename isEqualToString:@"name"])
    return [path lastPathComponent];
  if ([_simplename isEqualToString:@"path"])
    return path;
  
  if ([_simplename isEqualToString:@"objClass"])
    return [self npsDocumentClassName];
  if ([_simplename isEqualToString:@"objType"])
    return [self npsDocumentType];
  
  if ([_simplename isEqualToString:@"prefixPath"]) {
    if (![path hasSuffix:@"/"])
      path = [path stringByAppendingString:@"/"];
    return path;
  }
  
  if ([_simplename isEqualToString:@"parent"])
    return [self parentDocument];
  if ([_simplename isEqualToString:@"next"])
    return [self nextDocument];
  if ([_simplename isEqualToString:@"previous"])
    return [self previousDocument];
  
  if ([_simplename isEqualToString:@"index"])
    return [self pubIndexDocument];
  
  if ([_simplename isEqualToString:@"isRoot"]) {
    //NSLog(@"%@ isRoot ??? (path=%@)", self, path);
    return [NSNumber numberWithBool:[path isEqualToString:@"/"]];
  }

  /* lists */
  
  if ([_simplename isEqualToString:@"all"])
    return [self pubAllDocuments];

  if ([_simplename isEqualToString:@"toclist"])
    return [self pubTocListDocuments];
  
  if ([_simplename isEqualToString:@"children"])
    return [self pubChildListDocuments];
  
  if ([_simplename isEqualToString:@"relatedLinks"])
    return [self pubRelatedLinkDocuments];
  
  if ([_simplename isEqualToString:@"objectsToRoot"])
    return [self pubFolderDocumentsToRoot];
  
  if ([_simplename isEqualToString:@"persons"])
    return [self pubAllPersons];
  if ([_simplename isEqualToString:@"enterprises"])
    return [self pubAllEnterprises];
  if ([_simplename isEqualToString:@"accounts"])
    return [self pubAllAccounts];
  if ([_simplename isEqualToString:@"teams"])
    return [self pubAllTeams];
  if ([_simplename isEqualToString:@"jobs"])
    return [self pubAllJobs];
  if ([_simplename isEqualToString:@"appointments"])
    return [self pubAllAppointments];
  if ([_simplename isEqualToString:@"projects"])
    return [self pubAllProjects];
  
  /* direct path list, eg /de/ */
  if ([_simplename hasPrefix:@"/"]) {
    /* special list containing content of folder _simplename */
    id<NSObject,SkyDocumentFileManager> fm = nil;
    EODataSource *ds = nil;
    NSRange      r;
    NSString     *path;
    BOOL         deep = NO;
    EOQualifier  *qualifier = nil;
    
    if ((fm = [self pubFileManager]) == nil)
      return nil;
    
    r = [_simplename rangeOfString:@";"];
    if (r.length > 0) {
      id opts;
      NSString *opt;
      
      path = [_simplename substringToIndex:r.location];
      opts = [_simplename substringFromIndex:(r.location + r.length)];
      
      if ([opts length] > 0)
        opts = [[opts componentsSeparatedByString:@","] objectEnumerator];
      else
        opts = nil;

      while ((opt = [opts nextObject])) {
        if ([opt isEqualToString:@"deep"]) {
          deep = YES;
        }
        else if ([opt hasPrefix:@"query"]) {
	  r = [opt rangeOfString:@"="];
          if (r.length > 0) {
            opt = [opt substringFromIndex:(r.location + r.length)];
            qualifier = [EOQualifier qualifierWithQualifierFormat:opt];
          }
          else {
            NSLog(@"WARNING(%s): invalid query option '%@'", 
		  __PRETTY_FUNCTION__, opt);
          }
        }
        else {
          NSLog(@"WARNING(%s): unknown list option '%@'",
                __PRETTY_FUNCTION__, opt);
        }
      }
    }
    else {
      path = _simplename;
    }
    
    if ([fm supportsFeature:NGFileManagerFeature_DataSources atPath:path])
      ds = [(id<NGFileManagerDataSources>)fm dataSourceAtPath:path];
    
    if (deep || (qualifier != nil) ) {
      EOFetchSpecification *fs;
      NSMutableDictionary  *hints;
      
      fs = [ds fetchSpecification];
      if (fs == nil) {
        fs = [EOFetchSpecification fetchSpecificationWithEntityName:path
                                   qualifier:qualifier
                                   sortOrderings:nil];
      }
      else if (qualifier != nil) {
        [fs setQualifier:qualifier];
      }
      
      hints = [[[fs hints] mutableCopy] autorelease];
      if (hints == nil) hints = [NSMutableDictionary dictionaryWithCapacity:4];
      
      [hints setObject:[NSNumber numberWithBool:deep] forKey:@"fetchDeep"];
      
      [fs setHints:hints];
      [ds setFetchSpecification:fs];
    }
    
    return [ds fetchObjects];
  }
  
  /* forward to index document if this exists */
  if ((idx = [self pubIndexDocument]))
    return [idx npsValueForKey:_simplename inContext:_ctx];
  
  /* use key-value coding ... */
  return [self valueForKey:_simplename];
}

- (id)npsValueForKey:(NSString *)_simplename inContext:(id)_ctx {
  NSString *path;
  
  if ([[self valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [self npsFolderValueForKey:_simplename inContext:_ctx];
  
  if ([_simplename isEqualToString:@"body"]) {
    NSLog(@"%s: invalid use of body key ...", __PRETTY_FUNCTION__);
    return [(id)self contentAsString];
  }
  
  if ([_simplename isEqualToString:@"self"])
    return self;
  
  path = [self pubPath];
  
  /* process special SKY keys .. */
  
  if ([_simplename isEqualToString:@"contentType"])
    return [self valueForKey:@"NSFileMimeType"];
  
  if ([_simplename isEqualToString:@"lastChanged"])
    return [self valueForKey:NSFileModificationDate];
  
  if ([_simplename isEqualToString:@"hasSuperLinks"])
    return [NSNumber numberWithBool:NO];
  
  if ([_simplename isEqualToString:@"id"])
    return [self globalID];
  
  if ([_simplename isEqualToString:@"isRoot"]) {
    //NSLog(@"%@ isRoot ??? (path=%@)", self, path);
    return [NSNumber numberWithBool:[path isEqualToString:@"/"]];
  }
  
  if ([_simplename isEqualToString:@"name"])
    return [path lastPathComponent];
  if ([_simplename isEqualToString:@"path"])
    return path;
  
  if ([_simplename isEqualToString:@"objClass"])
    return [self npsDocumentClassName];
  
  if ([_simplename isEqualToString:@"objType"])
    return [self npsDocumentType];
  
  if ([_simplename isEqualToString:@"prefixPath"])
    return path;
  
  if ([_simplename isEqualToString:@"title"])
    return [self valueForKey:@"NSFileSubject"];
  
  if ([_simplename isEqualToString:@"version"])
    return [self valueForKey:@"SkyVersionName"];
  
  if ([_simplename isEqualToString:@"visibleName"])
    return [path lastPathComponent];
  if ([_simplename isEqualToString:@"visiblePath"])
    return path;
  
  if ([_simplename isEqualToString:@"parent"])
    return [self parentDocument];
  if ([_simplename isEqualToString:@"next"])
    return [self nextDocument];
  if ([_simplename isEqualToString:@"previous"])
    return [self previousDocument];
  if ([_simplename isEqualToString:@"index"])
    return [self pubIndexDocument];
  
  /* lists */
  
  if ([_simplename isEqualToString:@"all"])
    return [[self parentDocument] pubAllDocuments];
  
  if ([_simplename isEqualToString:@"toclist"])
    return [[self parentDocument] pubTocListDocuments];
  
  if ([_simplename isEqualToString:@"children"])
    return [[self parentDocument] pubChildListDocuments];
  
  if ([_simplename isEqualToString:@"relatedLinks"])
    return [[self parentDocument] pubRelatedLinkDocuments];
  
  if ([_simplename isEqualToString:@"objectsToRoot"])
    return [[self parentDocument] pubFolderDocumentsToRoot];
  
  if ([_simplename isEqualToString:@"persons"])
    return [[self parentDocument] pubAllPersons];
  if ([_simplename isEqualToString:@"enterprises"])
    return [[self parentDocument] pubAllEnterprises];
  if ([_simplename isEqualToString:@"accounts"])
    return [[self parentDocument] pubAllAccounts];
  if ([_simplename isEqualToString:@"teams"])
    return [[self parentDocument] pubAllTeams];
  if ([_simplename isEqualToString:@"jobs"])
    return [[self parentDocument] pubAllJobs];
  if ([_simplename isEqualToString:@"appointments"])
    return [[self parentDocument] pubAllAppointments];
  if ([_simplename isEqualToString:@"projects"])
    return [[self parentDocument] pubAllProjects];
  
  if ([_simplename hasPrefix:@"/"]) {
    /* special list containing content of folder _simplename */
    id<NSObject,SkyDocumentFileManager> fm = nil;
    EODataSource *ds = nil;
    
    if ((fm = [self pubFileManager]) == nil)
      return nil;
    
    if ([fm supportsFeature:NGFileManagerFeature_DataSources atPath:_simplename])
      ds = [(id<NGFileManagerDataSources>)fm dataSourceAtPath:_simplename];
    
    return [ds fetchObjects];
  }
  
  /* process extended attributes .. */
  return [self valueForKey:_simplename];
}

@end /* SkyDocument(Pub2) */
