# $Id$

#
# Global Makefile
#
# This makefile should build and install the whole OGo sources,
# EXCEPT for the thirdparty things like gnustep-make, js or libxml2.
#

# Why not use a gstep-make aggregate.make? Because some packages must be 
# installed before others can be built and aggregate.make only supports
# self-contained compilation (of course it would be nice if the whole
# OGo could be built self-contained, without installing anything ...)
#
# Probably some makefile expert could clean up the individual rules with
# some general ruleset.

all :: \
	SOPE-all		\
	webui-all		\
	tools-all		\
	zidestore-all		\
	xmlrpc-all		\
	publisher-all		\
	pda-install

install :: \
	SOPE-install		\
	webui-install		\
	tools-install		\
	zidestore-install	\
	xmlrpc-install		\
	publisher-install	\
	pda-install

clean :: \
	SOPE-clean		\
	logic-clean		\
	model-clean		\
	docapi-clean		\
	webui-clean		\
	tools-clean		\
	zidestore-clean		\
	xmlrpc-clean		\
	publisher-clean		\
	pda-clean

distclean :: \
	SOPE-distclean		\
	logic-distclean		\
	model-distclean		\
	docapi-distclean	\
	webui-distclean		\
	tools-distclean		\
	zidestore-distclean	\
	xmlrpc-distclean	\
	publisher-distclean	\
	pda-distclean

# SOPE

SOPEDIR=SOPE
include $(SOPEDIR)/rules.mk

# gnustep-db

GSTEPDBDIR=ThirdParty/gnustep-db

gstepdb-all : skyrixcore-install
	(cd $(GSTEPDBDIR) && $(MAKE) all)

gstepdb-install : skyrixcore-install
	(cd $(GSTEPDBDIR) && $(MAKE) install)

gstepdb-clean :
	(cd $(GSTEPDBDIR) && $(MAKE) clean)

gstepdb-distclean :
	(cd $(GSTEPDBDIR) && $(MAKE) distclean)

# Logic

LOGICDIR=Logic

logic-all : gstepdb-install
	(cd $(LOGICDIR) && $(MAKE) all)

logic-install : gstepdb-install
	(cd $(LOGICDIR) && $(MAKE) install)

logic-clean :
	(cd $(LOGICDIR) && $(MAKE) clean)

logic-distclean :
	(cd $(LOGICDIR) && $(MAKE) distclean)

# Database

DBDIR=Database

model-all : gstepdb-install logic-install
	(cd $(DBDIR) && $(MAKE) all)

model-install : gstepdb-install logic-install
	(cd $(DBDIR) && $(MAKE) install)

model-clean :
	(cd $(DBDIR) && $(MAKE) clean)

model-distclean :
	(cd $(DBDIR) && $(MAKE) distclean)

# DocumentAPI

DOCAPIDIR=DocumentAPI

docapi-all : logic-install model-install
	(cd $(DOCAPIDIR) && $(MAKE) all)

docapi-install : logic-install model-install
	(cd $(DOCAPIDIR) && $(MAKE) install)

docapi-clean :
	(cd $(DOCAPIDIR) && $(MAKE) clean)

docapi-distclean :
	(cd $(DOCAPIDIR) && $(MAKE) distclean)

# WebUI

WEBUIDIR=WebUI

webui-all : logic-install docapi-install model-install
	(cd $(WEBUIDIR) && $(MAKE) all)

webui-install : logic-install docapi-install model-install
	(cd $(WEBUIDIR) && $(MAKE) install)

webui-clean :
	(cd $(WEBUIDIR) && $(MAKE) clean)

webui-distclean :
	(cd $(WEBUIDIR) && $(MAKE) distclean)

# Tools

TOOLSDIR=Tools

tools-all : logic-install docapi-install model-install
	(cd $(TOOLSDIR) && $(MAKE) all)

tools-install : logic-install docapi-install model-install
	(cd $(TOOLSDIR) && $(MAKE) install)

tools-clean :
	(cd $(TOOLSDIR) && $(MAKE) clean)

tools-distclean :
	(cd $(TOOLSDIR) && $(MAKE) distclean)

# ZideStore

ZSDIR=ZideStore

zidestore-all : SOPE-install logic-install model-install
	(cd $(ZSDIR) && $(MAKE) all)

zidestore-install : SOPE-install logic-install model-install
	(cd $(ZSDIR) && $(MAKE) install)

zidestore-clean :
	(cd $(ZSDIR) && $(MAKE) clean)

zidestore-distclean :
	(cd $(ZSDIR) && $(MAKE) distclean)

# XML-RPC API

XMLRPCDIR=XmlRpcAPI

xmlrpc-all : SOPE-install logic-install docapi-install model-install
	(cd $(XMLRPCDIR) && $(MAKE) all)

xmlrpc-install : SOPE-install logic-install docapi-install model-install
	(cd $(XMLRPCDIR) && $(MAKE) install)

xmlrpc-clean :
	(cd $(XMLRPCDIR) && $(MAKE) clean)

xmlrpc-distclean :
	(cd $(XMLRPCDIR) && $(MAKE) distclean)

# Publisher

PUBDIR=Publisher

publisher-all : webui-install
	(cd $(PUBDIR) && $(MAKE) all)

publisher-install : webui-install
	(cd $(PUBDIR) && $(MAKE) install)

publisher-clean :
	(cd $(PUBDIR) && $(MAKE) clean)

publisher-distclean :
	(cd $(PUBDIR) && $(MAKE) distclean)

# PDA

PDADIR=PDA

pda-all : webui-install
	(cd $(PDADIR) && $(MAKE) all)

pda-install : webui-install
	(cd $(PDADIR) && $(MAKE) install)

pda-clean :
	(cd $(PDADIR) && $(MAKE) clean)

pda-distclean :
	(cd $(PDADIR) && $(MAKE) distclean)
