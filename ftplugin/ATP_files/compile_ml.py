#!/usr/bin/python
# Author: Marcin Szamotulski <mszamot[@]gmail[.]com>
# This file is a part of Automatic TeX Plugin for Vim.

import sys, os.path, subprocess, re, optparse 
from collections import deque
from optparse import OptionParser

usage   = "usage: %prog [options]"

# ARGUMENTS
parser  = OptionParser(usage=usage)

debug_file=open("/tmp/atp_mlp", "w+")

parser.add_option("--cmd",              dest="cmd")
parser.add_option("--bibcmd",           dest="bibcmd")
parser.add_option("--file",             dest="file_fp")
parser.add_option("--did_bibtex",       dest="did_bibtex",                              default=0)
parser.add_option("--nobibtex",         dest="bibtex",        action="store_false",     default=False)
parser.add_option("--bibtex",           dest="bibtex",        action="store_true",      default=False)
parser.add_option("--did_index",        dest="did_index",                               default=0)
parser.add_option("--noindex",          dest="index",         action="store_false",     default=False)
parser.add_option("--index",            dest="index",         action="store_true",      default=False)
parser.add_option("--run",              dest="run")
parser.add_option("--tex-options",      dest="tex_options",                             default="")
parser.add_option("--outdir",           dest="outdir")
parser.add_option("--progname",         dest="progname",                                default="gvim")
parser.add_option("--servername",       dest="servername")
parser.add_option("--sid",              dest="sid")
parser.add_option("--time_0",           dest="time_0")
parser.add_option("--time_1",           dest="time_1")
parser.add_option("--force",            dest="force",           action="store_true",    default=False)
parser.add_option("--firstrun",         dest="firstrun",        action="store_true",    default=False)

(options, args) = parser.parse_args()

# VARIABLES
file_fp 	= options.file_fp
debug_file.write("FILE_FP="+str(file_fp)+"\n")
[basename, ext] = os.path.splitext(file_fp)

bibtex 	        = options.bibtex
did_bibtex      = options.did_bibtex
index 	        = options.index
did_index       = options.did_index
print("DID_INDEX="+str(did_index)+"\n")

run		= int(options.run)
cmd		= options.cmd
bibcmd		= options.bibcmd
tex_options	= options.tex_options
outdir		= options.outdir
progname	= options.progname
debug_file.write("PROGNAME="+str(progname)+"\n")
servername	= options.servername
debug_file.write("SERVERNAME="+str(servername)+"\n")
sid		= options.sid
debug_file.write("SID="+str(sid)+"\n")
time		= [ options.time_0, options.time_1 ]
print("TIME="+str(time))
force		= options.force
if force:
    bang="!"
else:
    bang=""
debug_file.write("FORCE="+str(force)+"\n")
firstrun	= options.firstrun
if firstrun:
    did_firstrun=1
else:
    did_firstrun=1

# FUNCTIONS
def filter_empty(str):
	if re.match('\s*$', str):
            return False
	else:
            return True

def vim_remote_expr(servername, expr):
# Send <expr> to vim server,

# expr must be well quoted:
#       vim_remote_expr('GVIM', "atplib#CatchStatus()")
# (this is the only way it works)
    cmd=[progname, '--servername', servername, '--remote-expr', expr]
    debug_file.write(str(cmd)+"\n")
    subprocess.Popen(cmd, stdout=debug_file, stderr=debug_file)

def latex_progress_bar(cmd):
# Run latex and send data for progress bar,

    child = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    pid   = child.pid
    debug_file.write("CMD="+str(cmd)+"\n")
    debug_file.write("PID="+str(pid)+"\n")

    vim_remote_expr(servername, "atplib#LatexPID("+str(pid)+")")
#     debug_file.write("latex pid "+str(pid)+"\n")
    stack = deque([])
    while True:
        out = child.stdout.read(1)
        if out == '' and child.poll() != None:
            break
        if out != '':
            stack.append(out)

            if len(stack)>10:
                stack.popleft()
            match = re.match('\[(\n?\d(\n|\d)*)({|\])',''.join(stack))
            if match:
                vim_remote_expr(servername, "atplib#ProgressBar("+match.group(1)[match.start():match.end()]+","+str(pid)+")")
    child.wait()
    vim_remote_expr(servername, "atplib#ProgressBar('end',"+str(pid)+")")
    vim_remote_expr(servername, "atplib#LatexRunning()")
    return child

cwd=os.getcwd()
os.chdir(outdir)
debug_file.write("DIR="+os.getcwd()+"\n")

# MAKE BIBTEX
if bibtex:
    did_bibtex  = 1
    if re.search(bibcmd, '^\s*biber'):
        auxfile = os.path.basename(basename)
    else:
        auxfile = os.path.basename(basename)+".aux"
    bibtex=subprocess.Popen([bibcmd, auxfile], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    bibtex.wait()
    bibtex_returncode=bibtex.returncode
    vim_remote_expr(servername, "atplib#Bibtex('"+str(bibtex_returncode)+"')")

# MAKE INDEX
if index:
    idxfile     = basename+".idx"
    did_index   = 1
    index=subprocess.Popen(['makeindex', idxfile])
    index.wait()
    index_returncode=index.returncode


if re.match('\s*$', tex_options):
    tex_options_list=[]
else:
    if re.search('\s', tex_options):
	tex_options_list=' '.split(tex_options)
	tex_options_list=filter(filter_empty,tex_options_list)
    else:
	tex_options_list=[tex_options]

# COMPILE
os.putenv("max_print_line", "2000")
latex=latex_progress_bar([cmd, '-interaction=nonstopmode', '-output-directory='+outdir]+tex_options_list+[file_fp])
latex.wait()
latex_return_code=latex.returncode
vim_remote_expr(servername, "atplib#CatchStatus('"+str(latex_return_code)+"')")
debug_file.write("LATEX RETURN CODE="+str(latex_return_code)+"\n")

run+=1
# CALL BACK
callback_cmd=str(sid)+"MakeLatex('"+file_fp+"',"+str(did_bibtex)+","+str(did_index)+",["+str(time[0])+","+str(time[1])+"],"+str(did_firstrun)+","+str(run)+",'"+str(bang)+"')"
debug_file.write("CALLBACK="+str(callback_cmd)+"\n")
vim_remote_expr(servername, callback_cmd)

# FINAL STUFF
os.chdir(cwd)
debug_file.close()
