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

#import "common.h"
#import "LSNewNewsArticleCommand.h"

@implementation LSNewNewsArticleCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->data);
  RELEASE(self->filePath);
  RELEASE(self->relatedArticles);
  RELEASE(self->fileContent);
  [super dealloc];
}
#endif

- (BOOL)_resetIndexArticles {
  NSString         *expr      = nil;
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

- (void)_executeInContext:(id)_context {
  BOOL           isOk      = NO;
  NSString       *fileName = nil;
  NSUserDefaults *defaults;
  NSString       *path;
  id             obj;

  defaults = [_context userDefaults];
  path     = [defaults stringForKey:@"LSAttachmentPath"];
  
  [super _executeInContext:_context];
  obj = [self object];

  if ([[obj valueForKey:@"isIndexArticle"] boolValue]) {
    [self _resetIndexArticles];
  }
  
  if (self->relatedArticles == nil || [self->relatedArticles count] == 0) {
    self->relatedArticles =
      LSRunCommandV(_context, @"newsArticle", @"get",
                    @"isIndexArticle", [NSNumber numberWithBool:YES],
                    nil);
    RETAIN(self->relatedArticles);
  }

  LSRunCommandV(_context, @"newsArticle", @"set-related-Articles",
                @"object", obj,
                @"relatedArticles", self->relatedArticles, nil);


  // save attachement

  if (self->fileContent != nil) {
    fileName = [NSString stringWithFormat:@"%@/%@.txt",
                         path, [obj valueForKey:@"newsArticleId"]];
    
    isOk = [self->fileContent writeToFile:fileName atomically:YES];

    [self assert:isOk reason:@"error during save of news article attachment"];
  }

  if (self->data !=nil && self->filePath != nil) {
    path     = [defaults stringForKey:@"LSNewsImagesPath"];
    fileName = [NSString stringWithFormat:@"%@/%@.%@",
                         path, [obj valueForKey:@"newsArticleId"],
                         [self->filePath pathExtension]];
    
    isOk = [self->data writeToFile:fileName atomically:YES];

    [self assert:isOk reason:@"error during save of news article picture"];
  }
}

// accessors

- (void)setFileContent:(NSString *)_content {
  ASSIGN(self->fileContent, _content);
}
- (id)fileContent {
  return self->fileContent;
}

- (void)setData:(NSData *)_data {
  ASSIGN(self->data, _data);
}
- (NSData *)data {
  return self->data;
}

- (void)setFilePath:(NSString *)_filePath {
  ASSIGN(self->filePath, _filePath);
}
- (NSString *)filePath {
  return self->filePath;
}

- (void)setRelatedArticles:(NSArray *)_articles {
  ASSIGN(self->relatedArticles, _articles);
}

- (NSArray *)relatedArticles {
  return self->relatedArticles;
}

// initialize records

- (NSString *)entityName {
  return @"NewsArticle";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"data"]) {
    [self setData:_value];
    return;
  }
  else if ([_key isEqualToString:@"filePath"]) {
    [self setFilePath:_value];
    return;
  }
  else if ([_key isEqualToString:@"fileContent"]) {
    [self setFileContent:_value];
    return;
  }
  else if ([_key isEqualToString:@"relatedArticles"]) {
    [self setRelatedArticles:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"data"])
    return [self data];
  else if ([_key isEqualToString:@"filePath"])
    return [self filePath];
  else if ([_key isEqualToString:@"fileContent"])
    return [self fileContent];
  else if ([_key isEqualToString:@"relatedArticles"])
    return [self relatedArticles];
  return [super valueForKey:_key];
}

@end
