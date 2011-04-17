#!/usr/bin/python
# Author: Marcin Szamotulski <mszamot[@]gmail[.]com>
# This file is a part of Automatic TeX Plugin for Vim.

import sys, os.path, shutil, subprocess, psutil, re, tempfile, optparse, glob

from os import chdir, mkdir, putenv
from optparse import OptionParser
from collections import deque

# readlink is not available on Windows.
readlink=True
try:
    from os import readlink
except ImportError:
    readlink=False

####################################
#
#       Parse Options:   
#
####################################

usage   = "usage: %prog [options]"
parser  = OptionParser(usage=usage)

parser.add_option("-c", "--command",    dest="command",         default="pdflatex",     help="tex compiler")
parser.add_option("--progname",         dest="progname",        default="gvim",         help="vim v:progname")
parser.add_option("-a", "--aucommand",  dest="aucommand",       default=False, action="store_true", help="if the command was called from an autocommand (background compilation - this sets different option for call back.) ")
parser.add_option("--tex-options",      dest="tex_options",     default="-synctex=1,-interaction=nonstopmode", help="comma separeted list of tex options")
parser.add_option("--verbose",          dest="verbose",         default="silent", help="atp verbose mode: silent/debug/verbose")
parser.add_option("-f", "--file",       dest="mainfile",                        help="full path to file to compile")
parser.add_option("-o", "--output-format", dest="output_format", default="pdf", help="format od the output file: dvi or pdf (it is not checked consistency with --command")
parser.add_option("-r", "--runs",       dest="runs", help="how many times run tex consecutively", type="int", default=1 )
parser.add_option("--servername",       dest="servername", help="vim server to communicate with")
parser.add_option("-v", "--view", "--start", dest="start",      default=0, type="int", help="start viewer: values 0,1,2")
parser.add_option("--viewer",           dest="viewer",          default="xpdf", help="output viewer to use")
parser.add_option("--xpdf-server",      dest="xpdf_server", help="xpdf_server")
parser.add_option("--viewer-options",   dest="viewer_opt",      default="", help="comma separated list of viewer options")
parser.add_option("-k", "--keep",       dest="keep", help="comma separated list of extensions (see :help g:keep in vim)", default="aux,toc,bbl,ind,pdfsync,synctex.gz")
parser.add_option("--env",              dest="env", default="default", help="a comma separated list environment variables and its values: var1=val1,var2=val2")
# Boolean switches:
parser.add_option("--reload-viewer",    action="store_true",    default=False,  dest="reload_viewer")
parser.add_option("-b", "--bibtex",     action="store_true",    default=False,  dest="bibtex", help="run bibtex")
parser.add_option("--reload-on-error",  action="store_true",    default=False,  dest="reload_on_error", help="reload Xpdf if compilation had errors")
parser.add_option("--bang",             action="store_false",   default=False,  dest="bang", help="force reloading on error (Xpdf only)")
parser.add_option("--gui-running", "-g", action="store_true",   default=False,  dest="gui_running", help="if vim gui is running (has('gui_running'))")
parser.add_option("--no-progress-bar",  action="store_false",   default=True,   dest="progress_bar", help="send progress info back to gvim")
parser.add_option("--bibliographies",                           default="",     dest="bibliographies", help="command separated list of bibliographies")

(options, args) = parser.parse_args()

# Debug file should be changed for sth platform independent
# There should be a switch to get debug info.
debug_file      = open("/tmp/atp_compile.py.debug", 'w')

command         = options.command
progname        = options.progname
aucommand_bool  = options.aucommand
if aucommand_bool:
    aucommand="AU"
else:
    aucommand="COM"
command_opt     = options.tex_options.split(',')
mainfile_fp     = options.mainfile
output_format   = options.output_format
if output_format == "pdf":
    extension = ".pdf"
else:
    extension = ".dvi"
runs            = options.runs
servername      = options.servername
start           = options.start
viewer          = options.viewer
XpdfServer      = options.xpdf_server
viewer_rawopt   = options.viewer_opt.split(',')
def nonempty(string):
    if str(string) == '':
        return False
    else:
        return True
viewer_it       =filter(nonempty,viewer_rawopt)
viewer_opt      =[]
for opt in viewer_it:
    viewer_opt.append(opt)
viewer_rawopt   = viewer_opt
if viewer == "xpdf" and XpdfServer != None:
    viewer_opt.extend(["-remote", XpdfServer])
verbose         = options.verbose
keep            = options.keep.split(',')
keep            = filter(nonempty, keep)

def keep_filter_aux(string):
    if string == 'aux':
        return False
    else:
        return True

def keep_filter_log(string):
    if string == 'log':
        return False
    else:
        return True

def mysplit(string):
        return re.split('\s*=\s*', string)

env             = map(mysplit, filter(nonempty, re.split('\s*;\s*',options.env)))

# Boolean options
reload_viewer   = options.reload_viewer
bibtex          = options.bibtex
bibliographies  = options.bibliographies.split(",")
bibliographies  = filter(nonempty, bibliographies)
bang            = options.bang
reload_on_error = options.reload_on_error
gui_running     = options.gui_running
progress_bar    = options.progress_bar

debug_file.write("COMMAND "+command+"\n")
debug_file.write("AUCOMMAND "+aucommand+"\n")
debug_file.write("PROGNAME "+progname+"\n")
debug_file.write("COMMAND_OPT "+str(command_opt)+"\n")
debug_file.write("MAINFILE_FP "+str(mainfile_fp)+"\n")
debug_file.write("OUTPUT FORMAT "+str(output_format)+"\n")
debug_file.write("EXT "+extension+"\n")
debug_file.write("RUNS "+str(runs)+"\n")
debug_file.write("VIM_SERVERNAME "+str(servername)+"\n")
debug_file.write("START "+str(start)+"\n")
debug_file.write("VIEWER "+str(viewer)+"\n")
debug_file.write("XPDF_SERVER "+str(XpdfServer)+"\n")
debug_file.write("VIEWER_OPT "+str(viewer_opt)+"\n")
debug_file.write("DEBUG MODE (verbose) "+str(verbose)+"\n")
debug_file.write("KEEP "+str(keep)+"\n")
debug_file.write("BIBLIOGRAPHIES "+str(bibliographies)+"\n")
debug_file.write("ENV OPTION "+str(options.env)+"\n")
debug_file.write("ENV "+str(env)+"\n")
debug_file.write("*BIBTEX "+str(bibtex)+"\n")
debug_file.write("*BANG "+str(bang)+"\n")
debug_file.write("*RELOAD_VIEWER "+str(reload_viewer)+"\n")
debug_file.write("*RELOAD_ON_ERROR "+str(reload_on_error)+"\n")
debug_file.write("*GUI_RUNNING "+str(gui_running)+"\n")
debug_file.write("*PROGRESS_BAR "+str(progress_bar)+"\n")

####################################
#
#       Functions:   
#
####################################

def latex_progress_bar(cmd):
# Run latex and send data for progress bar,

    child = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    pid   = child.pid
    vim_remote_expr(servername, "atplib#LatexPID("+str(pid)+")")
    debug_file.write("latex pid "+str(pid)+"\n")
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

def xpdf_server_file_dict():
# Make dictionary of the type { xpdf_servername : [ file, xpdf_pid ] },

# to test if the server host file use:
# basename(xpdf_server_file_dict().get(server, ['_no_file_'])[0]) == basename(file)
# this dictionary always contains the full path (Linux).
# TODO: this is not working as I want to:
#    when the xpdf was opened first without a file it is not visible in the command line
#    I can use 'xpdf -remote <server> -exec "run('echo %f')"'
#    where get_filename is a simple program which returns the filename. 
#    Then if the file matches I can just reload, if not I can use:
#          xpdf -remote <server> -exec "openFile(file)"
    ps_list=psutil.get_pid_list()
    server_file_dict={}
    for pr in ps_list:
        try:
            name=psutil.Process(pr).name
            cmdline=psutil.Process(pr).cmdline
            if name == 'xpdf':
                try:
                    ind=cmdline.index('-remote')
                except:
                    ind=0
                if ind != 0 and len(cmdline) >= 1:
                    server_file_dict[cmdline[ind+1]]=[cmdline[len(cmdline)-1], pr]
        except psutil.NoSuchProcess:
            pass
    return server_file_dict


def vim_remote_send(servername, keys):
# Send <keys> to vim server,

    cmd=[progname, '--servername', servername, '--remote-send', keys]
    subprocess.Popen(cmd, stdout=debug_file, stderr=debug_file).wait()


def vim_echo(servername, message, command="echo", highlight="Normal"):
# Send message to vim server,

    cmd=[progname, '--servername', servername, '--remote-send', '<ESC>:echohl '+highlight+'|'+command+' '+message+'|echohl Normal<CR>' ]
    debug_file.write("VIM ECHO "+str(cmd))
    subprocess.Popen(cmd, stdout=debug_file, stderr=debug_file).wait()


def vim_remote_expr(servername, expr):
# Send <expr> to vim server,

# expr must be well quoted:
#       vim_remote_expr('GVIM', "atplib#TexReturnCode()")
# (this is the only way it works)
    cmd=[progname, '--servername', servername, '--remote-expr', expr]
    subprocess.Popen(cmd, stdout=debug_file, stderr=debug_file).wait()

####################################
#
#       Arguments:   
#
####################################

# If mainfile_fp is not a full path make it. 
glob=glob.glob(os.path.join(os.getcwd(),mainfile_fp))
if len(glob) != 0:
    mainfile_fp = glob[0]
mainfile        = os.path.basename(mainfile_fp)
mainfile_dir    = os.path.dirname(mainfile_fp)
if mainfile_dir == "":
    mainfile_fp = os.path.join(os.getcwd(), mainfile)
    mainfile    = os.path.basename(mainfile_fp)
    mainfile_dir= os.path.dirname(mainfile_fp)
if os.path.islink(mainfile_fp):
    if readlink:
        mainfile_fp = os.readlink(mainfile_fp)
    # The above line works if the symlink was created with full path. 
    mainfile    = os.path.basename(mainfile_fp)
    mainfile_dir= os.path.dirname(mainfile_fp)

mainfile_dir    = os.path.normcase(mainfile_dir+os.sep)
[basename, ext] = os.path.splitext(mainfile)
output_fp       = os.path.splitext(mainfile_fp)[0]+extension

####################################
#
#       Make temporary directory,
#       Copy files and Set Environment:
#
####################################
cwd     = os.getcwd()
if not os.path.exists(str(mainfile_dir)+".tmp"+os.sep):
        # This is the main tmp dir (./.tmp) 
        # it will not be deleted by this script
        # as another instance might be using it.
        # it is removed by Vim on exit.
    os.mkdir(str(mainfile_dir)+".tmp"+os.sep)
tmpdir  = tempfile.mkdtemp(prefix=str(mainfile_dir)+".tmp"+os.sep)
debug_file.write("TMPDIR: "+tmpdir+"\n")
tmpaux  = os.path.join(tmpdir,basename+".aux")

command_opt.append('-output-directory='+tmpdir)
latex_cmd      = [command]+command_opt+[mainfile_fp]
debug_file.write("COMMAND "+str(latex_cmd)+"\n")
debug_file.write("COMMAND "+" ".join(latex_cmd)+"\n")

# Copy important files to output directory:
# /except the log file/
os.chdir(mainfile_dir)
debug_file.write('COPY BEG '+os.getcwd()+"\n")
for ext in filter(keep_filter_log,keep):
    file_cp=basename+"."+ext
    if os.path.exists(file_cp):
        debug_file.write(file_cp+' ')
        shutil.copy(file_cp, tmpdir)

tempdir_list = os.listdir(tmpdir)
debug_file.write("ls tmpdir "+str(tempdir_list)+"\n")

# Set environment
for var in env:
    debug_file.write("ENV "+var[0]+"="+var[1]+"\n")
    os.putenv(var[0], var[1])

# Link local bibliographies:
for bib in bibliographies:
    if os.path.exists(os.path.join(mainfile_dir,os.path.basename(bib))):
        os.symlink(os.path.join(mainfile_dir,os.path.basename(bib)),os.path.join(tmpdir,os.path.basename(bib)))

####################################
#
#       Compile:   
#
####################################
# Start Xpdf (this can be done before compelation, because we can load file
# into afterwards) in this way Xpdf starts faster (it is already running when
# file compiles). 
# TODO: this might cause problems when the tex file is very simple and short.
# Can we test if xpdf started properly?  okular doesn't behave nicely even with
# --unique switch.

# Latex might not run this might happedn with bibtex (?)
latex_returncode=0
if bibtex and os.path.exists(tmpaux):
    debug_file.write("\nBIBTEX1"+str(['bibtex', basename+".aux"])+"\n")
    os.chdir(tmpdir)
    bibtex_popen=subprocess.Popen(['bibtex', basename+".aux"], stdout=subprocess.PIPE)
    bibtex_popen.wait()
    os.chdir(mainfile_dir)
    bibtex_returncode=bibtex_popen.returncode
    bibtex_output=re.sub('"', '\\"', bibtex_popen.stdout.read())
    debug_file.write("BIBTEX RET CODE "+str(bibtex_returncode)+"\nBIBTEX OUTPUT\n"+bibtex_output+"\n")
    if verbose != 'verbose':
        vim_remote_expr(servername, "atplib#BibtexReturnCode('"+str(bibtex_returncode)+"',\""+str(bibtex_output)+"\")")
    else:
        print(bibtex_output)
    # We need run latex at least 2 times
    bibtex=False
    runs=max([runs, 2])
# If bibtex contained errros we stop:
#     if not bibtex_returncode:
#         runs=max([runs, 2])
#     else:
#         runs=1
elif bibtex:
    # we need run latex at least 3 times
    runs=max([runs, 3])

debug_file.write("\nRANGE="+str(range(1,int(runs+1)))+"\n")
debug_file.write("RUNS="+str(runs)+"\n")
for i in range(1, int(runs+1)):
    if verbose == "verbose" and i == 1 and bibtex:
        print(command+" is running to make aux file ..." )
    elif verbose == "verbose" and ( i == 2 and options.bibtex or i == 1 and options.bibtex and not bibtex ):
        print(command+" is running to make bbl file ..." )
    debug_file.write("RUN="+str(i)+"\n")
    debug_file.write("DIR="+str(os.getcwd())+"\n")
    tempdir_list = os.listdir(tmpdir)
    debug_file.write("ls tmpdir "+str(tempdir_list)+"\n")
    debug_file.write("BIBTEX="+str(bibtex)+"\n")

    if verbose == 'verbose' and i == runs:
#       <SIS>compiler() contains here ( and not bibtex )
        debug_file.write("VERBOSE"+"\n")
        latex=subprocess.Popen(latex_cmd)
        pid=latex.pid
        debug_file.write("latex pid "+str(pid)+"\n")
        latex.wait()
        latex_returncode=latex.returncode
        debug_file.write("latex ret code "+str(latex_returncode)+"\n")
    else:
        if progress_bar and verbose != 'verbose':
            latex=latex_progress_bar(latex_cmd)
        else:
            latex = subprocess.Popen(latex_cmd, stdout=subprocess.PIPE)
            pid   = latex.pid
            if verbose != "verbose":
                vim_remote_expr(servername, "atplib#LatexPID("+str(pid)+")")
            debug_file.write("latex pid "+str(pid)+"\n")
            latex.wait()
            vim_remote_expr(servername, "atplib#LatexRunning()")
        latex_returncode=latex.returncode
        debug_file.write("latex return code "+str(latex_returncode)+"\n")
        tempdir_list = os.listdir(tmpdir)
        debug_file.write("JUST AFTER LATEX ls tmpdir "+str(tempdir_list)+"\n")
    # Return code of compilation:
    if verbose != "verbose":
        vim_remote_expr(servername, "atplib#TexReturnCode('"+str(latex_returncode)+"')")
    if bibtex and i == 1:
        debug_file.write("BIBTEX2 "+str(['bibtex', basename+".aux"])+"\n")
        debug_file.write(os.getcwd()+"\n")
        tempdir_list = os.listdir(tmpdir)
        debug_file.write("ls tmpdir "+str(tempdir_list)+"\n")
        os.chdir(tmpdir)
        bibtex_popen=subprocess.Popen(['bibtex', basename+".aux"], stdout=subprocess.PIPE)
        bibtex_popen.wait()
        os.chdir(mainfile_dir)
        bibtex_returncode=bibtex_popen.returncode
        bibtex_output=re.sub('"', '\\"', bibtex_popen.stdout.read())
        debug_file.write("BIBTEX2 RET CODE"+str(bibtex_returncode)+"\n")
        if verbose != 'verbose':
            vim_remote_expr(servername, "atplib#BibtexReturnCode('"+str(bibtex_returncode)+"',\""+str(bibtex_output)+"\")")
        else:
            print(bibtex_output)
# If bibtex had errors we stop, 
# at this point tex file was compiled at least once.
#         if bibtex_returncode:
#             debug_file.write("BIBTEX BREAKE "+str(bibtex_returncode)+"\n")
#             break

####################################
#
#       Copy Files:
#
####################################

# Copy files:
os.chdir(tmpdir)
for ext in filter(keep_filter_aux,keep)+[output_format]:
    file_cp=basename+"."+ext
    if os.path.exists(file_cp):
        debug_file.write(file_cp+' ')
        shutil.copy(file_cp, mainfile_dir)

# Copy aux file if there were no compilation errors or if it doesn't exists in mainfile_dir.
if latex_returncode == 0 or not os.path.exists(os.path.join(mainfile_dir, basename+".aux")):
    file_cp=basename+".aux"
    if os.path.exists(file_cp):
        shutil.copy(file_cp, mainfile_dir)
os.chdir(cwd)

####################################
#
#       Call Back Communication:   
#
####################################
if verbose != "verbose":
    debug_file.write("CALL BACK "+"atplib#CallBack('"+str(verbose)+"','"+aucommand+"','"+str(options.bibtex)+"')"+"\n")
    vim_remote_expr(servername, "atplib#CallBack('"+str(verbose)+"','"+aucommand+"','"+str(options.bibtex)+"')")
    # return code of compelation is returned before (after each compilation).


####################################
#
#       Reload/Start Viewer:   
#
####################################
if re.search(viewer, '^\s*xpdf\e') and reload_viewer:
    # The condition tests if the server XpdfServer is running
    xpdf_server_dict=xpdf_server_file_dict()
    cond = xpdf_server_dict.get(XpdfServer, ['_no_file_']) != ['_no_file_']
    debug_file.write("XPDF SERVER DICT="+str(xpdf_server_dict)+"\n")
    debug_file.write("COND="+str(cond)+":"+str(reload_on_error)+":"+str(bang)+"\n")
    debug_file.write("COND="+str( not reload_on_error or bang )+"\n")
    debug_file.write(str(xpdf_server_dict)+"\n")
    if start == 1:
        run=['xpdf']
        run.extend(viewer_opt)
        run.append(output_fp)
        debug_file.write("D1: "+str(run)+"\n")
        subprocess.Popen(run)
    elif cond and ( reload_on_error or latex_returncode == 0 or bang ): 
        run=['xpdf', '-remote', XpdfServer, '-reload']
        subprocess.Popen(run, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        debug_file.write("D2: "+str(['xpdf',  '-remote', XpdfServer, '-reload'])+"\n")
else:
    if start >= 1:
        run=[viewer]
        run.extend(viewer_opt)
        run.append(output_fp)
        debug_file.write("RUN "+str(run)+"\n")
        subprocess.Popen(run, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if start == 2:
        vim_remote_expr(servername, "atplib#SyncTex()")

####################################
#
#       Clean:
#
####################################
debug_file.close()
shutil.rmtree(tmpdir)
