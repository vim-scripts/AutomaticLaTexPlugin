#!/usr/bin/python
# This file is a part of ATP plugin to vim.
# AUTHOR: Marcin Szamotulski

# SYNTAX:
# atp_RevSearch.py <file> <line_nr>

# DESRIPTION: 
# This is a python sctipt which implements reverse searching (okular->vim)
# it uses atplib#FindAndOpen() function which finds the vimserver which hosts
# the <file>, then opens it on the <line_nr>. 

# HOW TO CONFIGURE OKULAR to get Reverse Search
# Designed to put in okular: 
# 		Settings>Configure Okular>Editor
# Choose: Custom Text Edit
# In the command field type: atp_RevSearch.py '%p' '%l'
# If it is not in your $PATH put the full path of the script.

# DEBUG:
# debug file : /tmp/atp_RevSearch.debug

import subprocess, sys

output = subprocess.Popen(["vim", "--serverlist"], stdout=subprocess.PIPE)
servers = output.stdout.read()
server_list = str(servers).splitlines()
server = server_list[0]
cmd="vim --servername "+server+" --remote-expr \"atplib#FindAndOpen('"+sys.argv[1]+"','"+sys.argv[2]+"')\""
subprocess.call(cmd, shell=True) 

f = open('/tmp/atp_RevSearch.debug', 'w')
f.write(">>> file        "+sys.argv[1]+"\n>>> line        "+sys.argv[2]+"\n>>> server      "+server+"\n>>> server list "+str(server_list)+"\n>>> cmd         "+cmd+"\n")
f.close()
