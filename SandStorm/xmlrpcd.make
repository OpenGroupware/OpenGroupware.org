# $Id$

BUNDLE_EXTENSION = .rpcd
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/Skyrix42/XmlRpcServers

ifeq ($(FOUNDATION_LIB),nx)
ADDITIONAL_TOOL_LIBS += -lFoundationExt
ADDITIONAL_LDFLAGS += -framework Foundation
endif

include $(GNUSTEP_MAKEFILES)/bundle.make

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
