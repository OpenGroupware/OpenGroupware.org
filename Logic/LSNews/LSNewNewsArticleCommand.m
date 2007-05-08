/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include "LSNewNewsArticleCommand.h"
#include "common.h"

@implementation LSNewNewsArticleCommand

static NSString *LSAttachmentPath = nil;
static NSString *LSNewsImagesPath = nil;

- (void)dealloc {
  [self->data            release];
  [self->filePath        release];
  [self->relatedArticles release];
  [self->fileContent     release];
  [super dealloc];
}

/* run */

- (BOOL)_resetIndexArticles {
  NSString         *expr;
  EOAdaptorChannel *adChannel;
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
  id obj;
  
  /* setup some globals */
  
  if (LSAttachmentPath == nil) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    LSAttachmentPath = [[ud stringForKey:@"LSAttachmentPath"] copy];
    LSNewsImagesPath = [[ud stringForKey:@"LSNewsImagesPath"] copy];
    
    if (![LSAttachmentPath isNotEmpty])
      [self errorWithFormat:@"LSAttachmentPath is not set!"];
    if (![LSNewsImagesPath isNotEmpty])
      [self errorWithFormat:@"LSNewsImagesPath is not set!"];
  }
  
  /* super will create the record which we then retrieve using -object */
  
  [super _executeInContext:_context];
  obj = [self object];
  
  /* continue */

  if ([[obj valueForKey:@"isIndexArticle"] boolValue])
    [self _resetIndexArticles];
  
  if (self->relatedArticles == nil || [self->relatedArticles count] == 0) {
    self->relatedArticles =
      [LSRunCommandV(_context, @"newsArticle", @"get",
		     @"isIndexArticle", [NSNumber numberWithBool:YES],
		     nil) retain];
  }
  
  LSRunCommandV(_context, @"newsArticle", @"set-related-Articles",
                @"object", obj,
                @"relatedArticles", self->relatedArticles, nil);


  /* save attachement */

  if ([self->fileContent isNotNull]) {
    NSString *fileName;

    fileName = [[obj valueForKey:@"newsArticleId"] stringValue];
    fileName = [fileName stringByAppendingPathExtension:@"txt"];

    fileName = [LSAttachmentPath stringByAppendingPathComponent:fileName];
    
    if (fileName == nil ||
	![self->fileContent writeToFile:fileName atomically:YES]) {
      [self errorWithFormat:
	      @"could not write news article content (size=%d) to: %@",
	      [self->fileContent length], fileName];
      
      [self assert:NO reason:@"Could not save news article content!"];
    }
  }
  
  if ([self->data isNotNull] && [self->filePath isNotNull]) {
    NSString *fileName;
    
    fileName = [[obj valueForKey:@"newsArticleId"] stringValue];
    fileName = [fileName stringByAppendingPathExtension:
			   [self->filePath pathExtension]];
    
    fileName = [LSNewsImagesPath stringByAppendingPathComponent:fileName];

    
    if (fileName == nil ||
	![self->fileContent writeToFile:fileName atomically:YES]) {
      [self errorWithFormat:
	      @"could not write news article image (size=%d) to: %@",
	      [self->data length], fileName];
      
      [self assert:NO reason:@"Could not save news article image!"];
    }
  }
}

/* accessors */

- (void)setFileContent:(NSString *)_content {
  ASSIGNCOPY(self->fileContent, _content);
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
  ASSIGNCOPY(self->filePath, _filePath);
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

/* initialize records */

- (NSString *)entityName {
  return @"NewsArticle";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
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

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"data"])
    return [self data];
  if ([_key isEqualToString:@"filePath"])
    return [self filePath];
  if ([_key isEqualToString:@"fileContent"])
    return [self fileContent];
  if ([_key isEqualToString:@"relatedArticles"])
    return [self relatedArticles];
  return [super valueForKey:_key];
}

@end /* LSNewNewsArticleCommand */
