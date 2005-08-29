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

#include "OGoConfigHandler.h"
#include "WOComponent+config.h"
#include "WOSession+LSO.h"
#include "common.h"
#include <math.h>

@interface OGoConfigHandler_DelayedLookup : NSObject
{
@public
  NSString *prefix;
  id handler;
}

@end

// TODO: do not use NSZoneAlloc etc

#if !LIB_FOUNDATION_LIBRARY
struct _NSMapNode {
    void *key;
    void *value;
    struct _NSMapNode *next;
};
#endif

@implementation OGoConfigHandler

+ (int)version {
  return 2;
}

/* final methods */

static __inline__ int _getHashSize(OGoConfigHandler *self);
static __inline__ struct _NSMapNode *_getNodeAt(OGoConfigHandler *self, int idx);
static BOOL is_prime(unsigned n);
static unsigned nextPrime(unsigned old_value);
static void chMapGrow(OGoConfigHandler *table, unsigned newSize);
static void chCheckMapTableFull(OGoConfigHandler *table);
static __inline__ void chInsert(OGoConfigHandler *table, id key, id value);
static __inline__ id chGet(OGoConfigHandler *table, id key);
static __inline__ void chRemove(OGoConfigHandler *table, id key);

/* initialization */

- (id)initWithComponent:(WOComponent *)_component {
  //  NSLog(@"Config<0x%08X>: component=%@", self, [_component name]);
  unsigned capacity;
  
  self->component = _component;

  capacity = 16 * 4 / 3;
  capacity = capacity ? capacity : 13;
  if (!is_prime(capacity))
    capacity = nextPrime(capacity);

  self->hashSize   = capacity;
  self->nodes      = NSZoneCalloc([self zone], capacity, sizeof(void *));
  self->itemsCount = 0;
  
  return self;
}
- (id)init {
  return [self initWithComponent:nil];
}

- (void)dealloc {
  if (self->itemsCount > 0) {
    NSZone *z = [self zone];
    unsigned i;
        
    for (i = 0; i < self->hashSize; i++) {
      struct _NSMapNode *next, *node;
            
      node = self->nodes[i];
      self->nodes[i] = NULL;		
      while (node) {
        [(id)node->key   release];
        [(id)node->value release];
        next = node->next;
        NSZoneFree(z, node);
        node = next;
      }
    }
    self->itemsCount = 0;
  }
    
  if (self->nodes)
    NSZoneFree([self zone], self->nodes);
  
  [super dealloc];
}

/* KVC */

- (BOOL)kvcIsPreferredInKeyPath {
  return YES;
}

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  // cannot set values, ignore ...
}

- (id)valueForKey:(NSString *)_key {
  id value = nil;
  
  /* check whether key is in cache */
  
  if (_key == nil)
    return nil;
  if ((value = chGet(self, _key)) != nil)
    return value;
  
  /* let the session determine the correct value */
  
  value = [[self->component session]
                            configValueForKey:_key
                            inComponent:self->component];
  
  if (value != nil) {
    /* register value in cache */
    chInsert(self, _key, value);
    return value;
  }
  
  return nil;
}

/* finals */

static __inline__ int _getHashSize(OGoConfigHandler *self)
{
    return self->hashSize;
}

static __inline__ struct _NSMapNode *
_getNodeAt(OGoConfigHandler *self, int idx)
{
    return self->nodes[idx];
}

static BOOL is_prime(unsigned n)
{
    int i, n2 = sqrt(n);

    for (i = 2; i <= n2; i++) {
        if (n % i == 0)
            return NO;
    }
    return YES;
}
static unsigned nextPrime(unsigned old_value)
{
    unsigned i, new_value = old_value | 1;

    for (i = new_value; i >= new_value; i += 2)
        if (is_prime(i))
            return i;
    return old_value;
}

static void chMapGrow(OGoConfigHandler *table, unsigned newSize) {
    unsigned i;
    struct _NSMapNode **newNodeTable;
    
    newNodeTable =
        NSZoneCalloc([table zone], newSize, sizeof(struct _NSMapNode*));
    
    for (i = 0; i < table->hashSize; i++) {
	struct _NSMapNode *next, *node;
	unsigned int h;
        
	node = table->nodes[i];
	while (node) {
	    next = node->next;
	    h = [(id)node->key hash] % newSize;
	    node->next = newNodeTable[h];
	    newNodeTable[h] = node;
	    node = next;
	}
    }
    NSZoneFree([table zone], table->nodes);
    table->nodes    = newNodeTable;
    table->hashSize = newSize;
}

static void chCheckMapTableFull(OGoConfigHandler *table) {
    if( ++(table->itemsCount) >= ((table->hashSize * 3) / 4)) {
	unsigned newSize;
        
        newSize = nextPrime((table->hashSize * 4) / 3);
	if(newSize != table->hashSize)
	    chMapGrow(table, newSize);
    }
}

static __inline__ void chInsert(OGoConfigHandler *table, id key, id value) {
    unsigned int h;
    struct _NSMapNode *node;
    
    h = [key hash] % table->hashSize;
    
    for (node = table->nodes[h]; node; node = node->next) {
        /* might cache the selector .. */
        if ([key isEqual:node->key])
            break;
    }
    
    /* Check if an entry for key exist in nodeTable. */
    if (node) {
        /* key exist. Set for it new value and return the old value of it. */
	if (key != node->key) {
            RETAIN(key);
            RELEASE((id)node->key);
	}
	if (value != node->value) {
            RETAIN(value);
            RELEASE((id)node->value);
	}
	node->key   = key;
	node->value = value;
        return;
    }
    
    /* key not found. Allocate a new bucket and initialize it. */
    node = NSZoneMalloc([table zone], sizeof(struct _NSMapNode));
    RETAIN(key);
    RETAIN(value);
    node->key   = (void*)key;
    node->value = (void*)value;
    node->next  = table->nodes[h];
    table->nodes[h] = node;
    
    chCheckMapTableFull(table);
}

static __inline__ id chGet(OGoConfigHandler *table, id key) {
    struct _NSMapNode *node;
    
    node = table->nodes[[key hash] % table->hashSize];
    for (; node; node = node->next) {
        /* could cache method .. */
        if ([key isEqual:node->key])
            return node->value;
    }
    return nil;
}

static __inline__ void chRemove(OGoConfigHandler *table, id key) {
    unsigned int h;
    struct _NSMapNode *node, *node1 = NULL;

    if (key == nil)
        return;

    h = [key hash] % table->hashSize;
    
    // node point to current bucket, and node1 to previous bucket or to NULL
    // if current node is the first node in the list 
    
    for (node = table->nodes[h]; node; node1 = node, node = node->next) {
        /* could cache method .. */
        if ([key isEqual:node->key]) {
            [(id)node->key   release];
            [(id)node->value release];
            
            if (!node1)
                table->nodes[h] = node->next;
            else
                node1->next = node->next;
	    NSZoneFree([table zone], node);
	    (table->itemsCount)--;
	    return;
        }
    }
}

@end /* OGoConfigHandler */

@implementation OGoConfigHandler_DelayedLookup

- (void)dealloc {
  [self->prefix  release];
  [self->handler release];
  [super dealloc];
}

/* KVC */

- (id)valueForKey:(NSString *)_key {
  if (self->prefix)
    _key = [self->prefix stringByAppendingString:_key];
  
  return [self->handler valueForKey:_key];
}

@end /* OGoConfigHandler_DelayedLookup */

#include "LSWConfigHandler.h"

@implementation LSWConfigHandler /* DEPRECATED */
@end /* LSWConfigHandler */
