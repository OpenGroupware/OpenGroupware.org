#!/usr/bin/env python

import sys, Foundation
from Foundation import *

modelPath = sys.argv[1]

model = NSDictionary(contentsOfFile=modelPath)

defaultWidths = { 't_string':        255,
                  't_smallstring':   100,
                  't_tinystring':    50,
                  't_tinieststring': 10 }

header = """#!/usr/bin/env python
# generated from file %s

table       = \"@table\"
className   = \"@class\"
column      = \"@columnName\"
coltype     = \"@externalType\"
valueClass  = \"@valueClassName\"
valueType   = \"@valueType\"
allowsNull  = \"@allowsNull\"
width       = \"@width\"
destination = \"@destination\"
flags       = \"@flags\"
yes         = 1
no          = 0
lock        = \"@lock\"
property    = \"@property\"
primaryKey  = \"@primaryKey\"
isToMany    = \"@isToMany\"
source      = \"@sourceAttribute\"
destination = \"@destinationAttribute\"

fb          = \"FrontBase\"

userTypes = {
  fb:     { },
}

""" % \
modelPath

footer = ""
old = """
# show defined entities

import string

for entityName in dir():
    if entityName[:1] in string.uppercase:
        print entityName
"""

# entity formats

entityHeader = """%(name)s = {
    table:     \"%(externalName)s\",
    className: '%(className)s',"""

entityFooter = "} # entity %(name)s\n"

# property formats

attributeHeader = """    \"%(name)s\": {
      column:     \"%(columnName)s\",
      coltype:    '%(externalType)s',
      valueClass: '%(valueClassName)s',"""

relshipHeader = """    \"%(name)s\": {"""
#      destination: '%(destination)s',"""

# generating attribute entries

def printAttribute(entity, attribute):
    print attributeHeader % attribute
    
    if attribute['valueType'] is not None:
        print "      valueType:  '%(valueType)s'," % attribute
    
    if attribute['width'] is not None:
        print "      width:      %(width)i," % attribute
    else:
        try:
            width = defaultWidths[attribute['externalType']]
            print "      width:      %i," % width
        except Exception: pass
    
    # flags
    
    print "      flags:      [",
    
    if attribute['name'] in entity['primaryKeyAttributes']:
        print "primaryKey,",
    
    if attribute['name'] in entity['attributesUsedForLocking']:
        print "lock,",
    
    if attribute['name'] in entity['classProperties']:
        print "property,",
    
    if attribute['allowsNull'] is not None:
        if attribute['allowsNull'] == "Y":
            print "allowsNull,",
    else:
        print "allowsNull,",
    
    print "],"

    # footer
    
    print "    },"

# generating relationship entries

def printRelationship(entity, relship):
    print relshipHeader % relship
    destination = relship['destination']
    isToMany    = relship['isToMany'] == "Y"
    join        = relship['joins'][0]
    
    print "      flags:       [",
    if relship['name'] in entity['classProperties']:
        print "property,",
    if isToMany:
        print "isToMany,",
    print "],"
    
    if isToMany:
        print "      source:     ",
        print "\"%s.%s\","      % ( destination, join['sourceAttribute'] )
        print "      destination:",
        print "\"%(destinationAttribute)s\"," % join
    else:
        print "      source:     ",
        print "\"%(sourceAttribute)s\","      % join
        print "      destination:",
        print "\"%s.%s\","      % ( destination, join['destinationAttribute'] )
    
    print "    },"

# start generation

print header

for entity in model['entities']:
    print entityHeader % entity
    
    if len(entity['attributes']) > 0:
        print "    \n    # attributes\n    "
    
        for attribute in entity['attributes']:
            printAttribute(entity, attribute)
    
    if len(entity['relationships']) > 0:
        print "    \n    # relationships\n    "
    
        for relship in entity['relationships']:
            printRelationship(entity, relship)
    
    print entityFooter % entity

print footer
