/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess
  Copyright (C) 2025      Helge Hess

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

#include "OGoFileManagerFactory.h"
#include "common.h"

@implementation OGoFileManagerFactory

static id           sharedFactory = nil;
static NSArray      *projectBases = nil;
static NSDictionary *baseToClass  = nil;

+ (void)initialize {
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  unsigned i, count;
  id tmp;
  
  if (projectBases == nil) {
    tmp = [bm providedResourcesOfType:@"OGoProjectBases"];
    projectBases = [[tmp valueForKey:@"name"] copy];
    NSLog(@"OGoProject: available project bases: %@",
	  [projectBases componentsJoinedByString:@","]);
  }
  
  /* load base bundles and register filemanager classes */
  count = [projectBases count];
  tmp   = [NSMutableDictionary dictionaryWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString     *baseName;
    NSBundle     *bundle;
    NSDictionary *config;
    NSString     *fmClassName;
    Class        fmClass;
    
    baseName = [projectBases objectAtIndex:i];
    bundle   = [bm bundleProvidingResource:baseName ofType:@"OGoProjectBases"];
    NSLog(@"Note: load storage bundle: '%@'", 
	  [[bundle bundlePath] lastPathComponent]);
    if (![bundle load]) {
      NSLog(@"ERROR: could not load bundle for base '%@': %@", 
	    baseName, bundle);
      continue;
    }
    
    config = [bm configForResource:baseName ofType:@"OGoProjectBases"
		 providedByBundle:bundle];
    fmClassName = [config objectForKey:@"fileManagerClass"];
    fmClass     = NGClassFromString(fmClassName);
    if (fmClass == Nil) {
      NSLog(@"ERROR: did not find filemanager class for base '%@'.", baseName);
      continue;
    }

    [(NSMutableDictionary *)tmp setObject:fmClass forKey:baseName];
  }
  baseToClass = [tmp copy];
}

+ (id)sharedFileManagerFactory {
  if (sharedFactory == nil)
    sharedFactory = [[OGoFileManagerFactory alloc] init];
  return sharedFactory;
}

/* project bases */

- (NSArray *)availableProjectBases {
  return projectBases;
}

/* file managers */

- (id)fileManagerInContext:(id)_context forProjectGID:(EOGlobalID *)_gid {
  id project;

  if (_context == nil) {
    [self errorWithFormat:@"missing context argument!"];
    return nil;
  }
  if (![_gid isNotNull]) {
    [self warnWithFormat:@"no GID for filemanager construction!"];
    return nil;
  }

#if 0
#  warning TODO: REMOVE DEBUG ABORT
  if ([[[(EOKeyGlobalID *)_gid keyValues][0] stringValue] 
	isEqualToString:@"-1"])
    abort();
#endif
  
  project = [_context runCommand:@"project::get-by-globalid",
                 @"gid", _gid, nil];
  
  if ([project isKindOfClass:[NSArray class]]) {
    project = ([project count] > 0)
      ? [project lastObject]
      : nil;
  }
  
  if (project == nil) {
    [self errorWithFormat:@"%s; missing project for gid: %@",
            __PRETTY_FUNCTION__, _gid];
    abort();
    return nil;
  }
  return [self fileManagerInContext:_context forProject:project];
}

- (Class)fileManagerClassForScheme:(NSString *)_scheme {
  Class fmClass;
  
  if ([_scheme isEqualToString:@"file"]) {
    fmClass = NGClassFromString(@"SkyFSFileManager");

    if (fmClass == nil) { /* try to load bundle */
      [[[NGBundleManager defaultBundleManager]
                         bundleForClassNamed:@"SkyFSFileManager"] load];

      fmClass = NGClassFromString(@"SkyFSFileManager");
    }
  }
  else if ([_scheme isEqualToString:@"subversion"])
    fmClass = NGClassFromString(@"SkySvnFileManager");
  else if ([_scheme isEqualToString:@"skyrix"])
    fmClass = NGClassFromString(@"SkyProjectFileManager");
  else {
    [self warnWithFormat:@"%s: unknown filemanager scheme '%@', "
	  @"trying SkyProjectFileManager !",
	  __PRETTY_FUNCTION__, _scheme];
    fmClass = NGClassFromString(@"SkyProjectFileManager");
  }
  return fmClass;
}

- (id)fileManagerInContext:(id)_context forProject:(id)_project {
  NSURL    *url;
  NSString *urlString, *scheme;
  id       fm;
  Class    fmClass = Nil;

  if (_context == nil) {
    [self errorWithFormat:@"missing context argument!"];
    return nil;
  }
  if (_project == nil) {
    [self warnWithFormat:@"no EO for filemanager construction!"];
    return nil;
  }
  
  urlString = [_project valueForKey:@"url"];
  
  url = (![urlString isNotNull])
    ? [self skyrixBaseURL]
    : (NSURL *)[NSURL URLWithString:urlString];
  
  scheme = [url scheme];

  /* construct filemanager */
  
  if ((fmClass = [self fileManagerClassForScheme:scheme]) == Nil) {
    [self errorWithFormat:@"%s found no filemanager class for scheme %@: %@", 
	  __PRETTY_FUNCTION__, scheme, url];
    return nil;
  }
  
  fm = [[fmClass alloc] initWithContext:_context 
			projectGlobalID:[_project globalID]];
  
  return [fm autorelease];
}

- (NSURL *)skyrixBaseURL {
  static NSURL *SKYBase = nil;
  NSString *skyid;
  NSString *urlstr;

  if (SKYBase)
    return SKYBase;
    
  skyid = [[NSUserDefaults standardUserDefaults] stringForKey:@"skyrix_id"];
    
  if ([skyid length] == 0) {
    urlstr  = [NSString stringWithFormat:@"skyrix://%@/",
                          [[NSHost currentHost] name]];
  }
  else {
    urlstr  = [NSString stringWithFormat:@"skyrix://%@/%@/",
                          [[NSHost currentHost] name],
                          skyid];
  }
  SKYBase = [[NSURL alloc] initWithString:urlstr relativeToURL:nil];
  NSLog(@"OGo storage base URL: '%@'", SKYBase);
  return SKYBase;
}

- (NSURL *)subversionBaseURL {
  static NSURL *SVNBase = nil;
  NSString *svnPath;

  if (SVNBase)
    return SVNBase;
    
  svnPath = [[NSUserDefaults standardUserDefaults]
                             stringForKey:@"SkySvnRepositoryPath"];


    if ([svnPath length] == 0) {
      svnPath = [NSString stringWithFormat:@"subversion://%@/",
                         [[NSHost currentHost] name]];
    }
    else {
      svnPath = [NSString stringWithFormat:@"subversion://%@/%@/",
                          [[NSHost currentHost] name], svnPath];
    }
  SVNBase = [[NSURL alloc] initWithString:svnPath relativeToURL:nil];
  NSLog(@"SVN BaseURL: '%@'", SVNBase);
  return SVNBase;
}

- (NSURL *)fileSystemBaseURL {
  static NSURL *FSBase = nil;
  NSString *fsPath;

  if (FSBase)
    return FSBase;
    
  fsPath = [[NSUserDefaults standardUserDefaults]
                            stringForKey:@"SkyFSPath"];
  if (fsPath == nil) {
    NSFileManager *fm;
    BOOL          isDir;
      
    fsPath = [[[[NSProcessInfo processInfo] environment]
                               objectForKey:@"GNUSTEP_USER_ROOT"]
                               stringByAppendingPathComponent:
                               @"SkyFileSystem"];
    fm = [NSFileManager defaultManager];

      if (![fm fileExistsAtPath:fsPath isDirectory:&isDir]) {
        if (![fm createDirectoryAtPath:fsPath attributes:nil]) {
          [self errorWithFormat:
		  @"%s: Couldn`t create directory for skyrix filesystem "
                  @"at path %@", __PRETTY_FUNCTION__, fsPath];
          return nil;
        }
      }
      else {
        if (!isDir) {
          [self errorWithFormat:
		  @"%s: couldn`t create directory at path %@, file exist",
                __PRETTY_FUNCTION__, fsPath];
          return nil;
        }
      }
  }
  if (fsPath == nil) {
    [self errorWithFormat:@"Did not find SkyFSPath, the basis for FS projects.",
          __PRETTY_FUNCTION__];
    return nil;
  }
  
  fsPath = [NSString stringWithFormat:@"file://%@", fsPath];
  FSBase = [[NSURL alloc] initWithString:fsPath relativeToURL:nil];
  [self logWithFormat:@"FS BaseURL: '%@'", FSBase];
  return FSBase;
}

- (NSURL *)newFileSystemURLWithContext:(id)_ctx {
  NSURL         *baseURL;
  EOEntity      *project;
  NSDictionary  *keyRow;
  NSString      *path;
  NSFileManager *fm;
  
  project = [[_ctx valueForKey:LSDatabaseKey] entityNamed:@"Project"];
  if (project == nil) {
    [self errorWithFormat:@"missing 'Project' entity?!"];
    return nil;
  }
  
  keyRow = [[[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel]
                   primaryKeyForNewRowWithEntity:project];
  
  baseURL = [self fileSystemBaseURL];
  path = [[keyRow objectForKey:@"projectId"] stringValue];
  path = [[baseURL path] stringByAppendingPathComponent:path];

  fm = [NSFileManager defaultManager];

  if ([fm fileExistsAtPath:path isDirectory:NULL]) {
    [self errorWithFormat:@"%s: project path already exist: '%@'",
          __PRETTY_FUNCTION__, path];
    return nil;
  }
  if (![fm createDirectoryAtPath:path attributes:nil]) {
    [self errorWithFormat:
	    @"%s: could not create path for directory: '%@'",
            __PRETTY_FUNCTION__, path];
    return nil;
  }
  [self logWithFormat:@"Note: created new FS project base: '%@'", path];
  
  path = [@"file://" stringByAppendingString:path];
  return [NSURL URLWithString:path];
}

- (NSURL *)newURLForProjectBase:(NSString *)_base
  stringValue:(NSString *)url
  commandContext:(id)_ctx
{
  Class fmClass;
  
  if (![url isNotNull]) url = @"";
  
  if (_base == nil) _base = @"FileSystem";
  fmClass = [baseToClass objectForKey:_base];

  if ([fmClass respondsToSelector:_cmd]) {
    // Note: incorrect cast, is a filemanager class!
    return [(OGoFileManagerFactory *)fmClass newURLForProjectBase:_base 
		    stringValue:url
		    commandContext:_ctx];
  }
  
  /* old behaviour */
  
  if ([_base isEqualToString:@"Subversion"])
    return [self subversionBaseURL];
  
  if ([_base isEqualToString:@"FileSystem"]) {
    if (![url isNotNull])
      url = @"";
    
    if ([url length] > 0)
      return [NSURL URLWithString:url];
    
    return [self newFileSystemURLWithContext:_ctx];
  }
  
  return [self skyrixBaseURL];
}

/* DEPRECATED: only for compatibility */

+ (id)fileManagerInContext:(id)_context forProject:(id)_p {
  return [[self sharedFileManagerFactory] 
                fileManagerInContext:_context forProject:_p];
}
+ (id)fileManagerInContext:(id)_ctx forProjectGID:(EOGlobalID *)_gid {
  return [[self sharedFileManagerFactory] 
                fileManagerInContext:_ctx forProjectGID:_gid];
}

+ (NSURL *)skyrixBaseURL {
  return [[self sharedFileManagerFactory] skyrixBaseURL];
}
+ (NSURL *)subversionBaseURL {
  return [[self sharedFileManagerFactory] subversionBaseURL];
}
+ (NSURL *)fileSystemBaseURL {
  return [[self sharedFileManagerFactory] fileSystemBaseURL];
}

+ (NSURL *)newFileSystemURLWithContext:(id)_ctx {
  return [[self sharedFileManagerFactory] newFileSystemURLWithContext:_ctx];
}

@end /* OGoFileManagerFactory */
