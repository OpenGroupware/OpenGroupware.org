
#include "common.h"
#include "SkyLDAPExporter.h"

@implementation SkyLDAPExporter

- (void)dealloc {
  RELEASE(self->ldapBindDN);
  RELEASE(self->ldapPwd);
  RELEASE(self->ldapHost);
  RELEASE(self->connection);
  RELEASE(self->ldapBaseDN);
  [super dealloc];
}

- (NSString *)ldapBindDN {
  if (self->ldapBindDN == nil) {
    self->ldapBindDN = [[[NSUserDefaults standardUserDefaults]
                                        objectForKey:@"LDAPBindDN"]
                                        stringValue];
    [self->ldapBindDN retain];
  }
  return self->ldapBindDN;
}
- (NSString *)ldapBaseDN {
  if (self->ldapBaseDN == nil) {
    self->ldapBaseDN = [[[NSUserDefaults standardUserDefaults]
                                        objectForKey:@"LDAPBaseDN"]
                                        stringValue];
    [self->ldapBaseDN retain];
  }
  return self->ldapBaseDN;
}
- (NSString *)ldapPwd {
  if (self->ldapPwd == nil) {
    self->ldapPwd = [[[NSUserDefaults standardUserDefaults]
                                        objectForKey:@"LDAPPwd"]
                                        stringValue];
    [self->ldapPwd retain];
  }
  return self->ldapPwd;
}
- (NSString *)ldapHost {
  if (self->ldapHost == nil) {
    self->ldapHost = [[[NSUserDefaults standardUserDefaults]
                                        objectForKey:@"LDAPHost"]
                                        stringValue];
    if (self->ldapHost == nil)
      self->ldapHost = @"localhost";
    
    [self->ldapHost retain];
    
  }
  return self->ldapHost;
}
- (int)ldapPort {
  if (self->ldapPort == -1) {
    self->ldapPort = [[[NSUserDefaults standardUserDefaults]
                                        objectForKey:@"LDAPPort"]
                                        intValue];
    if (!self->ldapPort)
      self->ldapPort = 389;
  }
  return self->ldapPort;
}

- (BOOL)openConnection {
  BOOL result = YES;
  if (self->connection == nil) {
    NSString *bindDN, *pwd, *host;
    int      port;

    if (!(bindDN = [self ldapBindDN])) {
      NSLog(@"ERROR[%s]: missing ldap login (Default: LDAPBindDN)",
            __PRETTY_FUNCTION__);
      return NO;
    }
    pwd  = [self ldapPwd];
    host = [self ldapHost];
    port = [self ldapPort];
      

    NS_DURING {
      self->connection = [[NGLdapConnection alloc]
                                            initWithHostName:host port:port];
      result = [self->connection bindWithMethod:@"simple"
                    binddn:bindDN credentials:pwd];
    
    }
    NS_HANDLER {
      printf("%s: got exception %s\n",
            [NSStringFromSelector(_cmd) cString],
            [[localException description] cString]);
      result = NO;
      RELEASE(self->connection);
      self->connection = nil;
    }
    NS_ENDHANDLER;

    if (self->connection == nil) {
      NSLog(@"ERROR[%s]: missing ldap-connection (host:%@; port:%d)",
            __PRETTY_FUNCTION__, host, port);
      return NO;
    }
    [self->connection setUseCache:NO];
  }
  return result;
}

- (void)closeConnection {
  RELEASE(self->connection);
  self->connection = nil;
}

- (NSArray *)fetchAttributes {
  return [self subclassResponsibility:_cmd];
}

- (NSString *)searchBase {
  return [self ldapBaseDN];
}

- (BOOL)fetchDeep {
  [self subclassResponsibility:_cmd];
  return NO;
}

- (NSDictionary *)buildEntry:(NSDictionary *)_attrs {
  return [self subclassResponsibility:_cmd];
}
/*
  objectclass=doof
*/
   
- (EOQualifier *)searchQualifier {
  return [self subclassResponsibility:_cmd];
}

- (BOOL)exportEntries {
  if (![super exportEntries])
    return NO;

  if ([self openConnection]) {
    NSEnumerator         *e;
    NGLdapEntry          *entry;

    if ([self fetchDeep]) {
      e = [self->connection deepSearchAtBaseDN:[self searchBase]
               qualifier:[self searchQualifier]
               attributes:[self fetchAttributes]];
    }
    else {
      e = [self->connection flatSearchAtBaseDN:[self searchBase]
               qualifier:[self searchQualifier]
               attributes:[self fetchAttributes]];
    }
    while ((entry = [e nextObject])) {
      NSAutoreleasePool *pool;
      NSDictionary      *dict;
      NSEnumerator      *enumerator;
      id                obj;
      id                *objs, *keys;
      NSArray           *array;
      int               cnt;

      pool       = [[NSAutoreleasePool alloc] init];
      array      = [[entry attributes] allValues];
      enumerator = [array objectEnumerator];
      objs       = malloc(sizeof(id)*[array count]+1);
      keys       = malloc(sizeof(id)*[array count]+1);
      cnt        = 1;

      objs[0] = [entry dn];
      keys[0] = @"dn";
      
      while ((obj = [enumerator nextObject])) {
        NSArray *values;

        values = [obj allStringValues];

        if ([values count] == 0) {
          objs[cnt] = @"";
        }
        else if ([values count] == 1) {
          objs[cnt] = [values lastObject];
        }
        else {
          objs[cnt] = values;
        }

        keys[cnt] = [obj attributeName];
        cnt++;
      }
      dict = [[NSDictionary alloc] initWithObjects:objs forKeys:keys
                                   count:cnt];
      
      dict = [self buildEntry:dict];
      
      if (![self writeEntry:dict]) {
        NSLog(@"%s: couldn`t write entry %@", __PRETTY_FUNCTION__,
              dict);
      }
      [pool release];
    }
    return YES;
  }
  return NO;
}

@end /* SkyLDAPExporter */
