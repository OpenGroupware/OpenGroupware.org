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

#include "LSSetNewsArticleCommand.h"
#include "common.h"

@implementation LSSetNewsArticleCommand

- (void)dealloc {
  [self->fileContent     release];
  [self->data            release];
  [self->filePath        release];
  [self->relatedArticles release];
  [super dealloc];
}

/* run */

- (BOOL)_resetIndexArticles {
  NSString         *expr;
  EOAdaptorChannel *adChannel = nil;
  id obj;

  obj = [self object];

  adChannel = [[self databaseChannel] adaptorChannel];

  expr =[NSString stringWithFormat:
                  @"UPDATE news_article SET is_index_article = 0 where "
                  @"news_article_id <> %@",
                  [obj valueForKey:@"newsArticleId"]];
  
  return ([adChannel evaluateExpression:expr])  ? YES : NO;
}

- (BOOL)isRootId:(NSNumber *)_pkey inContext:(id)_ctx {
  return [_pkey intValue] == 10000 ? YES : NO;
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSEnumerator *teamEnum;
  id           account;
  id           team;
  BOOL         access = NO;
  
  account = [_context valueForKey:LSAccountKey];
  
  if ([self isRootId:[account valueForKey:@"companyId"] inContext:_context])
    access = YES;
  else {
    teamEnum =
      [LSRunCommandV(_context, @"account", @"teams",
                     @"account", account,
                     @"returnType", intObj(LSDBReturnType_ManyObjects),
                     nil) objectEnumerator];

    while ((team = [teamEnum nextObject]) != nil) {
      if ([[team valueForKey:@"login"] isEqualToString:@"newseditors"]) {
        access = YES;
        break;
      }
    }
  }
  [self assert:access reason:@"You have no permission for doing that!"];

  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  BOOL           isOk      = NO;
  NSString       *fileName = nil;
  NSString       *fName    = nil;
  id             obj;
  NSUserDefaults *defaults;
  NSString       *path;

  obj      = [self object];
  defaults = [_context userDefaults];
  path     = [defaults stringForKey:@"LSAttachmentPath"];
  
  if ([[obj valueForKey:@"isIndexArticle"] boolValue]) {
    [self _resetIndexArticles];
  }

  [super _executeInContext:_context];

  if (self->relatedArticles != nil) {
    LSRunCommandV(_context, @"newsArticle", @"set-related-Articles",
                  @"object", obj,
                  @"relatedArticles", self->relatedArticles, nil);
  }
  
  // save attachement

  if (self->fileContent != nil) {
    fileName = [NSString stringWithFormat:@"%@/%@.txt",
                         path, [obj valueForKey:@"newsArticleId"]];
    
    isOk = [self->fileContent writeToFile:fileName atomically:YES];

    [self assert:isOk reason:@"Error while saving news article attachment!"];
  }

  {
    NSFileManager *manager = [NSFileManager defaultManager];

    path     = [defaults stringForKey:@"LSNewsImagesPath"];
    fileName = [NSString stringWithFormat:@"%@/%@",
                         path, [obj valueForKey:@"newsArticleId"]];

    if ((self->data !=nil && [self->data length] > 0 && self->filePath != nil)
        || self->deleteImage) {
      fName = [fileName stringByAppendingPathExtension:@"jpg"];

      if ([manager fileExistsAtPath:fName]) {
        [manager removeFileAtPath:fName handler:nil];        
      }
      fName = [fileName stringByAppendingPathExtension:@"gif"];

      if ([manager fileExistsAtPath:fName]) {
        [manager removeFileAtPath:fName handler:nil];        
      }
    }

    if (self->data !=nil && self->filePath != nil && [self->data length] > 0) {
      fName = [fileName stringByAppendingPathExtension:
                        [self->filePath pathExtension]];
      isOk  = [self->data writeToFile:fName atomically:YES];

      [self assert:isOk reason:@"Error while saving news article picture!"];
    }
  }
}

/* accessors */

- (void)setData:(NSData *)_data {
  ASSIGN(self->data, _data);
}
- (NSData *)data {
  return self->data;
}

- (void)setFilePath:(NSString *)_filePath {
  ASSIGNCOPY(self->filePath, _filePath);
}
- (NSString *)filePath {
  return self->filePath;
}

- (void)setFileContent:(NSString *)_fileContent {
  ASSIGNCOPY(self->fileContent, _fileContent);
}
- (NSString *)fileContent {
  return self->fileContent;
}

- (void)setRelatedArticles:(NSArray *)_articles {
  ASSIGN(self->relatedArticles, _articles);
}
- (NSArray *)relatedArticles {
  return self->relatedArticles;
}

- (void)setDeleteImage:(BOOL)_flag {
  self->deleteImage = _flag;
}
- (BOOL)deleteImage {
  return self->deleteImage;
}

// initialize records

- (NSString *)entityName {
  return @"NewsArticle";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"data"])
    [self setData:_value];
  else if ([_key isEqualToString:@"filePath"])
    [self setFilePath:_value];
  else if ([_key isEqualToString:@"fileContent"])
    [self setFileContent:_value];
  else if ([_key isEqualToString:@"relatedArticles"])
    [self setRelatedArticles:_value];
  else if ([_key isEqualToString:@"deleteImage"])
    [self setDeleteImage:[_value boolValue]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"data"])
    return [self data];
  if ([_key isEqualToString:@"filePath"])
    return [self filePath];
  if ([_key isEqualToString:@"fileContent"])
    return [self fileContent];
  if ([_key isEqualToString:@"relatedArticles"])
    return [self relatedArticles];
  if ([_key isEqualToString:@"deleteImage"])
    return [NSNumber numberWithBool:[self deleteImage]];
  return [super valueForKey:_key];
}

@end /* LSSetNewsArticleCommand */
