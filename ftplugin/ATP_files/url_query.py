#!/usr/bin/python
import sys, urllib2, tempfile

url  = sys.argv[1]
tmpf = sys.argv[2]

f    = open(tmpf, "w")
data = urllib2.urlopen(url)
f.write(data.read())
