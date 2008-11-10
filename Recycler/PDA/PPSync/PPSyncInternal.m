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

#import <Python/Python.h>
#import <NGPython/NGPython.h>

PyMethodDef PPSyncInternal_methods[] = {
  { NULL, NULL } /* sentinel */
};

static char module_doc[] =
"This modules handles internals of the PPSync module,\n"
"like setup of and access to global variables.";

void initPPSyncInternal(void) {
  extern PyObject *NGPythonBridge_GetPyObjectForId(id _object);
  extern void __objc_resolve_class_links();
  PyObject *module    = NULL;
  PyObject *nameSpace = NULL;
  
  module = Py_InitModule3("PPSyncInternal",
                          PPSyncInternal_methods,
                          module_doc);
  nameSpace = PyModule_GetDict(module);

  __objc_resolve_class_links();  
}
