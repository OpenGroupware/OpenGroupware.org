#!/usr/bin/env python

import xmlrpclib, time

url   = "http://localhost:10822/Task/xmlrpc"
login = "bjoern"
pwd   = "bjoern"

# call server

task = xmlrpclib.Server(url, login=login, password=pwd).com.skyrix.task

print "All available tasks : ",
tasks =  task.listAllTasks()
print tasks
print "Starting first task from the list above... ",
if task.start(tasks[0]).value == 1: 
  print "success"
else:
  print "failed"

print "Sleeping 5 seconds ..."
time.sleep(5)
print "All running tasks : ",
tasks =  task.listRunningTasks()
print "Stopping the previously started task... ",
if task.stop(tasks[0]).value == 1: 
  print "success"
else:
  print "failed"
