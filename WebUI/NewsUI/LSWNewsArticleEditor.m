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

#include "LSWNewsArticleEditor.h"
#include "common.h"
#include <OGoFoundation/LSWNotifications.h>
#include <NGExtensions/NSString+Ext.h>

@implementation LSWNewsArticleEditor

- (id)init {
  if ((self = [super init])) {    
    self->allArticles     = [[NSMutableArray alloc] initWithCapacity:16];
    self->relatedArticles = [[NSMutableArray alloc] initWithCapacity:4];
  }
  return self;
}

- (void)dealloc {
  [self->data            release];
  [self->filePath        release];
  [self->fileContent     release];
  [self->relatedArticles release];
  [self->allArticles     release];
  [self->newsArticle     release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForNewCommand:(NSString *)_command type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  NSArray *a = nil;

  [self->fileContent release];
  self->fileContent = [[NSMutableString alloc] init];

  a = [self runCommand:@"newsarticle::get",
            @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  [self->allArticles addObjectsFromArray:a];
  [self->allArticles removeObject:[self object]];
  return YES;
}

- (BOOL)prepareForEditCommand:(NSString *)_command type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id              obj;
  NSUserDefaults *defaults;
  NSString        *path;
  NSString        *fileName;
  NSArray         *relArt;
  NSArray         *a;
  
  obj      = [self object]; 
  defaults = [[self session] userDefaults];
  path     = [defaults stringForKey:@"LSAttachmentPath"];
  
  fileName = [NSString stringWithFormat:@"%@/%@.txt",
                       path, [obj valueForKey:@"newsArticleId"]];
  
  self->fileContent = [[NSString stringWithContentsOfFile:fileName] retain];

  relArt = [obj run:@"newsarticle::get-related-articles", nil];
  [self->relatedArticles addObjectsFromArray:relArt];
  
  a = [self runCommand:@"newsarticle::get",
            @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  [self->allArticles addObjectsFromArray:a];
  [self->allArticles removeObject:obj];
  return YES;
}

/* accessors */

- (void)setData:(id)_data { 
  ASSIGN(self->data, _data);
}
- (id)data {
  return self->data;
}

- (void)setFilePath:(id)_path { 
  ASSIGN(self->filePath, _path);
}
- (id)filePath {
  return self->filePath;
}

- (NSArray *)allArticles {
  return self->allArticles;
}

- (NSDictionary *)article {
  return [self snapshot];
}

- (void)setFileContent:(NSString *)_fileContent {
  ASSIGNCOPY(self->fileContent, _fileContent);
}
- (NSString *)fileContent {
  return self->fileContent;
}

- (void)setHasRelatedArticle:(BOOL)_value {
  if (_value) {
    if (![self->relatedArticles containsObject:self->newsArticle])
      [self->relatedArticles addObject:self->newsArticle];
  }
  else
    [self->relatedArticles removeObject:self->newsArticle];
}
- (BOOL)hasRelatedArticle {
  return [self->relatedArticles containsObject:self->newsArticle];
}

- (void)setNewsArticle:(NSMutableDictionary *)_newsArticle { 
  ASSIGN(self->newsArticle, _newsArticle);
}
- (NSDictionary *)newsArticle {
  return self->newsArticle;
}

- (void)setDeleteImage:(BOOL)_flag {
  self->deleteImage = _flag;
}
- (BOOL)deleteImage {
  return self->deleteImage;
}

- (BOOL)isDeleteDisabled {
  if ([self isInNewMode])
    return YES;

  return [[[self object] valueForKey:@"isIndexArticle"] boolValue];
}

/* notifications */

- (NSString *)updateNotificationName {
  return LSWUpdatedNewsArticleNotificationName;
}
- (NSString *)insertNotificationName {
  return LSWNewNewsArticleNotificationName;
}
- (NSString *)deleteNotificationName {
  return LSWDeletedNewsArticleNotificationName;
}

- (BOOL)checkConstraints {
  NSString *lname;

  lname = [[[self snapshot] valueForKey:@"name"] stringByTrimmingWhiteSpaces];
  if (![lname isNotNull])
    lname = nil;
  
  if ([lname length] == 0) {
    NSString *es;

    es = [[self labels] valueForKey:@"error_noArticleNameSet"];
    [self setErrorString:es];
    return YES;
  }
  else {
    [self setErrorString:nil];
    return NO;
  }
}

- (BOOL)checkConstraintsForSave {
  return ![self checkConstraints];
}

/* actions */

- (id)insertObject {
  id article;

  article = [self snapshot];
  
  if (self->fileContent == nil)
    self->fileContent = @"";

  [article takeValue:self->fileContent forKey:@"fileContent"];

  if (self->data != nil && self->filePath != nil) {    
    [article takeValue:self->data     forKey:@"data"];
    [article takeValue:self->filePath forKey:@"filePath"];
  }

  [article takeValue:self->relatedArticles forKey:@"relatedArticles"];
  
  return [self runCommand:@"newsArticle::new" arguments:article];
}

- (id)updateObject {
  id article;

  article = [self snapshot];
  
  if (self->fileContent == nil)
    self->fileContent = @"";

  [article takeValue:self->fileContent forKey:@"fileContent"];

  if (self->data != nil && self->filePath != nil) {    
    [article takeValue:self->data     forKey:@"data"];
    [article takeValue:self->filePath forKey:@"filePath"];
  }
  
  [(NSMutableDictionary *)article removeObjectForKey:@"relatedArticles"];
  [article takeValue:self->relatedArticles forKey:@"relatedArticles"];
  [article takeValue:[NSNumber numberWithBool:self->deleteImage]
           forKey:@"deleteImage"];
  
  return [self runCommand:@"newsArticle::set" arguments:article];
}

- (id)deleteObject {
  return [[self object] run:@"newsArticle::delete", 
                        @"reallyDelete", [NSNumber numberWithBool:YES],
                        nil];
}

@end /* LSWNewsArticleEditor */
