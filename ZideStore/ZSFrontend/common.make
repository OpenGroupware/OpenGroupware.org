# GNUstep makefile

OGoROOT=../../..

-include $(OGoROOT)/config.make
include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_INCLUDE_DIRS += -I. -I.. -I../..
ADDITIONAL_INCLUDE_DIRS += -I$(OGoROOT)/Logic
