" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 Feb 11
" URL:		
" GetLatestVimScripts: 2945 6 :AutoInstall: tex_atp.vim
" Copyright:    Copyright (C) 2010 Marcin Szamotulski Permission is hereby
"		granted to use and distribute this code, with or without
" 		modifications, provided that this copyright notice is copied
" 		with it. Like anything else that's free, Automatic TeX Plugin
" 		is provided *as is* and comes with no warranty of any kind,
" 		either expressed or implied. By using this plugin, you agree
" 		that in no event will the copyright holder be liable for any
" 		damages resulting from the use of this software. 
" 		This licence is valid for all files distributed with ATP
" 		plugin.
"
"
" TODO to make s:maketoc and s:generatelabels read all input files between
" \begin{document} and \end{document}, and make it recursive.
" now s:maketoc finds only labels of chapters/sections/...
" TODO make toc work with parts!
" TODO speed up ToC. The time consuming part is: vnew as shown by profiling.
"
" TODO we can add a pid file and test agianst it (if it exists) and run some
" commands when there is no pid file: this could be a useful way to run :cg,
" i.e. read the log file automatically. Getpid for Windows can return 0/1 and
" thus all the things should work on Windows.
"
" TODO write a function which reads log file whenever it was modified.
" 		solution 1: read (but when?) it to a variable and compare.	
" 			with an autocommand loaded by s:compiler and deleted
" 			when getpid returns an empty string.
" 		solution 2: read it as a buffer then hide it and use checktime
" 		to see if it was changed.
"
" TODO Check against lilypond 
" TODO b:changedtick "HOW MANY CHANGES WERE DONE! this could be useful.
" TODO make a function which updates Labels and ToC, and do not update ToC and
" Labels to often.
" TODO make a split version of EditInputFile
"
" NOTES
" s:tmpfile =	temporary file value of tempname()
" b:texfile =	readfile(bunfname("%")

" We need to know bufnumber and bufname in a tabpage.
let t:bufname=bufname("")
let t:bufnr=bufnr("")
let t:winnr=winnr()

" These autocommands are used to remember the last opened buffer number and its
" window numbers
au BufLeave *.tex let t:bufname=bufname("")
au BufLeave *.tex let t:bufnr=bufnr("")
au WinEnter *.tex let t:winnr=winnr("#")
au WinEnter __ToC__ let t:winnr=winnr("#")
au WinEnter __Labels__ let t:winnr=winnr("#")

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

" Options
setl keywordprg=texdoc\ -m
setl include=\\input\\>
setl includeexpr=substitute(v:fname,'\\%(.tex\\)\\?$','.tex','')
" TODO set define and work on the abve settings, these settings work with [i
" command but not with [d, [D and [+CTRL D (jump to first macro definition)

" let &l:errorfile=b:outdir . fnameescape(fnamemodify(expand("%"),":t:r")) . ".log"
if !exists("*SetErrorFile")
function! SetErrorFile()
    if !exists("b:outdir")
	call s:setoutdir(0)
    endif
    let l:ef=b:outdir . fnamemodify(expand("%"),":t:r") . ".log"
    let &l:errorfile=l:ef
    set errorfile?
endfunction
endif
" This options are set also when editing .cls files.
function! s:setoutdir(arg)
    if g:askfortheoutdir == 1 
	let b:outdir=input("Where to put output? do not escape white spaces ")
    endif
    if get(getbufvar(bufname("%"),""),"outdir","optionnotset") == "optionnotset" 
		\ && g:askfortheoutdir != 1 || b:outdir == "" && g:askfortheoutdir == 1
	 let b:outdir=fnamemodify(resolve(expand("%:p")),":h") . "/"
    "      	echomsg "DEBUG setting b:outdir to " . b:outdir
	 echoh WarningMsg | echomsg "Output Directory "b:outdir | echoh None
	 if bufname("") =~ ".tex$" && a:arg != 0
	     call SetErrorFile()
	 endif
    endif	
endfunction

" these are all buffer related variables:
let s:optionsDict= { 	"texoptions" 	: "", 		"reloadonerror" : "0", 
		\	"openviewer" 	: "1", 		"autex" 	: "1", 
		\	"Viewer" 	: "xpdf", 	"XpdfOptions" 	: "", 
		\	"XpdfServer" 	: fnamemodify(expand("%"),":t"), 
		\	"outdir" 	: fnameescape(fnamemodify(resolve(expand("%:p")),":h")) . "/",
		\	"texcompiler" 	: "pdflatex" }
let s:ask={ "ask" : "0" }
" TODO every option should be set like this: do it with s:setoptinos
if !exists("g:rmcommand") && executable("perltrash")
    let g:rmcommand="perltrash"
endif
if !exists("g:askfortheoutdir")
    let g:askfortheoutdir=0
endif
if !exists("g:texextensions")
    let g:texextensions=["aux", "log", "bbl", "blg", "spl", "snm", "nav", "thm", "brf", "out", "toc", "mpx", "idx", "maf", "blg", "glo", "mtc[0-9]", "mtc1[0-9]"]
endif
if !exists("g:keep")
    let g:keep=["log","aux","toc","bbl"]
endif
if !exists("g:printingoptions")
    let g:printingoptions=''
endif
" opens bibsearch results in vertically split window.
if !exists("g:vertical")
    let g:vertical=1
endif
"TODO: put toc_window_with and labels_window_width into DOC file
if !exists("t:toc_window_width")
    let t:toc_window_width=30
endif
if !exists("t:labels_window_width")
    let t:labels_window_width=30
endif
if !exists("g:texmf")
    let g:texmf=$HOME . "/texmf"
endif
"TODO: to make it possible to read the log file after compilation.
" if !exists("g:au_read_log_file")
"     let g:au_read_log_file = 1
" endif
let s:COM=''
" let b:outdir=substitute(fnameescape(resolve(expand("%:p"))),resolve(expand("%:r")) . "." . resolve(expand("%:e")) . "$","","")

" This function sets options (values of buffer related variables) which were
" not set by the user to their default values.
function! s:setoptions()
let s:optionsKeys=keys(s:optionsDict)
let s:optionsinuseDict=getbufvar(bufname("%"),"")
for l:key in s:optionsKeys
    if get(s:optionsinuseDict,l:key,"optionnotset") == "optionnotset" && l:key != "outdir" 
"  	    echomsg "Setting " . l:key . "=" . s:optionsDict[l:key]
	call setbufvar(bufname("%"),l:key,s:optionsDict[l:key])
    elseif get(s:optionsinuseDict,l:key,"optionnotset") == "optionnotset" && l:key == "outdir"
	" set b:outdir and the value of errorfile option
	call s:setoutdir(1)
	let s:ask["ask"] = 1
    endif
endfor
endfunction
call s:setoptions()

if !exists("*ShowOptions")
function! ShowOptions(...)
    let s:bibfiles=FindBibFiles(bufname("%"))
if a:0 == 0
    echomsg "variable=local value"  
    echohl BibResultsMatch
    echomsg "b:texcompiler=   " . b:texcompiler 
    echomsg "b:texoptions=    " . b:texoptions 
    echomsg "b:autex=         " . b:autex 
    echomsg "b:outdir=        " . b:outdir 
    echomsg "b:Viewer=        " . b:Viewer 
    echohl BibResultsGeneral
    if b:Viewer == "xpdf"
	echomsg "    b:XpdfOptions=   " . b:XpdfOptions 
	echomsg "    b:XpdfServer=    " . b:XpdfServer 
	echomsg "    b:reloadonerror= " . b:reloadonerror 
    endif
    echomsg "b:openviewer=    " . b:openviewer 
    echomsg "g:askfortheoutdir=" . g:askfortheoutdir 
    if !exists("g:atp_statusline_off")
	echomsg "status line set by atp"
    endif
    echohl BibResultsMatch
    echomsg "g:keep=          " . string(g:keep)  
    echomsg "g:texextensions= " . string(g:texextensions)
    echomsg "g:rmcommand=     " . g:rmcommand
    echohl BibResultsFileNames
    echomsg "g:defaultbibflags=     " . g:defaultbibflags
    echomsg "g:defaultallbibflags=  " . g:defaultallbibflags
    echomsg "Available Flags        " . string(keys(g:bibflagsdict))
    echomsg "Available KeyWordFlags " . string(keys(g:kwflagsdict))
    echohl BibResultsMatch
    if exists('b:lastbibflags')
	echomsg "b:lastbibflags=    " . b:lastbibflags
    endif
    echohl None
    echomsg "g:bibentries=    " . string(g:bibentries)
    echohl BibResultsFileNames
    if exists('b:bibfiles')
	echomsg "b:bibfiles=      " .  string(b:bibfiles)
    endif
    if exists('s:bibfiles')
	echomsg "s:bibfiles=      " .  string(s:bibfiles)	. " bibfiles used by atp."
    endif
    if exists('s:notreadablebibfiles')
	echomsg "s:notreadablebibfiles=" .  string(s:notreadablebibfiles)
    endif
    echohl None
elseif a:0>=1 
    echohl BibResultsMatch
    echomsg "b:texcompiler=   " . b:texcompiler . "  [" . s:optionsDict["texcompiler"] . "]" 
    echomsg "b:texoptions=    " . b:texoptions . "  [" . s:optionsDict["texoptions"] . "]" 
    echomsg "b:autex=         " . b:autex . "  [" . s:optionsDict["autex"] . "]" 
    echomsg "b:outdir=        " . b:outdir . "  [" . s:optionsDict["outdir"] . "]" 
    echomsg "b:Viewer=        " . b:Viewer . "  [" . s:optionsDict["Viewer"] . "]" 
    echohl None
    if b:Viewer == "xpdf"
	echomsg "    b:XpdfOptions=   " . b:XpdfOptions . "  [" . s:optionsDict["XpdfOptions"] . "]" 
	echomsg "    b:XpdfServer=    " . b:XpdfServer . "  [" . s:optionsDict["XpdfServer"] . "]" 
	echomsg "    b:reloadonerror= " . b:reloadonerror . "  [" . s:optionsDict["reloadonerror"] . "]" 
    endif
    echomsg "g:askfortheoutdir=" . g:askfortheoutdir . "  [" . s:optionsDict["askfortheoutdir"] . "]" 
    echomsg "b:openviewer=    " . b:openviewer . "  [" . s:optionsDict["openviewer"] . "]" 
    echo
    echohl BibResultsMatch
    echomsg "g:keep=          " . string(g:keep)  
    echomsg "g:texextensions= " . string(g:texextensions)
    echomsg "g:rmcommand=     " . g:rmcommand
    echohl None
    echohl BibResultsFileNames
    echomsg "g:defaultbibflags=     " . g:defaultbibflags
    echomsg "g:defaultallbibflags=  " . g:defaultallbibflags
    echomsg " "
    echomsg "Available Flags        "
    echomsg "   g:bibflagsdict=     " . string(items(g:bibflagsdict))
    echomsg " "
    echomsg "Available KeyWordFlags "
    echomsg "   g:kwflagsdict=      " . string(items(g:kwflagsdict))
    echomsg " "
    echohl BibResultsMatch
    if exists('b:lastbibflags')
	echomsg "b:lastbibflags=" . b:lastbibflags
    endif
    echohl BibResultsLabel
    echomsg "g:bibentries=" . string(g:bibentries) . "  ['article', 'book', 'booklet', 'conference', 'inbook', 'incollection', 'inproceedings', 'manual', 'mastertheosis', 'misc', 'phdthesis', 'proceedings', 'techreport', 'unpublished']"
    echohl BibResultsFileNames
    if exists('b:bibfiles')
	echomsg "b:bibfiles=  " .  string(b:bibfiles)
    endif
    if exists('s:bibfiles')
	echomsg "s:bibfiles=      " .  string(s:bibfiles)	. " bibfiles used by atp."
    endif
    if exists('s:notreadablebibfiles')
	echomsg "s:notreadablebibfiles=" .  string(s:notreadablebibfiles)
    endif
    echohl None
    echomsg ""
endif
endfunction
endif

function! ATPStatus()
let s:status=""
if exists("b:outdir")
    if b:outdir != "" 
	if b:outdir =~ "\.\s*$" || b:outdir =~ "\.\/\s*$"
	    let s:status= s:status . "Output dir: " . pathshorten(getcwd())
	else
	    let s:status= s:status . "Output dir: " . pathshorten(substitute(b:outdir,"\/\s*$","","")) 
	endif
    else
	let s:status= s:status . "Please set the Output directory, b:outdir"
    endif
endif	
    return s:status
endfunction

syntax match atp_statustitle 	/.*/ 
syntax match atp_statussection 	/.*/ 
syntax match atp_statusoutdir 	/.*/ 
hi link atp_statustitle Number
hi link atp_statussection Title
hi link atp_statusoutdir String
if !exists("*Setstatus")
function! Setstatus()
    echomsg "Statusline set by ATP." 
"     how to set highlight groups in ftplugin not using color file to make a
"     nice status line
"     let &statusline='%<%#atp_statustitle#%f %(%h%m%r %)  %#atp_statussection#%{CTOC()}%=%#atp_statusoutdir#%{ATPStatus()}  %#atp_statusline#%-14.16(%l,%c%V%)%P'
    let &statusline='%<%f %(%h%m%r %)  %{CTOC()}%=%{ATPStatus()}  %-14.16(%l,%c%V%)%P'
endfunction
endif
if (exists("g:atp_statusline") && g:atp_statusline == '1') || !exists("g:atp_statusline")
    au BufRead *.tex call Setstatus()
endif
let b:texruns=0
let b:log=0	
let b:ftype=getftype(expand("%:p"))	
let s:texinteraction="nonstopmode"
compiler tex
let s:lockef=1
au BufRead $l:errorfile setlocal autoread 

"--------- FUNCTIONs -----------------------------------------------------
function! s:outdir()
    if b:outdir !~ "\/$"
	let b:outdir=b:outdir . "/"
    endif
endfunction
if !exists("*ViewOutput")
function! ViewOutput()
    call s:outdir()
    if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex"
	let l:ext = ".pdf"
    else
	let l:ext = ".dvi"	
    endif
    let l:outfile=b:outdir . (fnamemodify(expand("%"),":t:r")) . l:ext
    if b:Viewer == "xpdf"	
	let l:viewer=b:Viewer . " -remote " . shellescape(b:XpdfServer) . " " . b:XpdfOptions 
"    		echomsg "DEBUG 1 l:view="l:viewer 
    else
	let l:viewer=b:Viewer 
"    		echomsg "DEBUG 2 l:view="l:viewer
    endif
    let l:view=l:viewer . " " . shellescape(l:outfile)  . " &"
		let b:outfile=l:outfile
" 		echomsg "DEBUG l:outfile="l:outfile
    if filereadable(l:outfile)
	if b:Viewer == "xpdf"	
	    let b:view=l:view
" 	    echomsg "DEBUG 3 l:view="l:view
	    call system(l:view)
	else
	    call system(l:view)
	    redraw!
	endif
    else
	    echomsg "Output file do not exists. Calling "b:texcompiler
	    call s:compiler(0,1,1,0,"AU")
    endif	
endfunction
endif
"-------------------------------------------------------------------------
function! s:getpid()
	let s:command="ps -ef | grep -v " . $SHELL  . " | grep " . b:texcompiler . " | grep -v grep | grep " . fnameescape(expand("%")) . " | awk '{print $2}'"
	let s:var=substitute(system(s:command),'\D',' ','')
	return s:var
endfunction

if !exists("*Getpid")
function! Getpid()
	let s:var=s:getpid()
	if s:var != ""
		echomsg b:texcompiler"pid"s:var 
	else
		echomsg b:texcompiler "is not running"
	endif
endfunction
endif

if !exists("*s:xpdfpid")
function! s:xpdfpid() 
    let s:checkxpdf="ps -ef | grep -v grep | grep '-remote '" . shellescape(b:XpdfServer) . " | awk '{print $2}'"
    return substitute(system(s:checkxpdf),'\D','','')
endfunction
endif
"-------------------------------------------------------------------------
function! s:compare(file,buffer)
    let l:buffer=getbufline(bufname("%"),"1","$")
    return a:file !=# l:buffer
endfunction
"-------------------------------------------------------------------------
function! s:copy(input,output)
	call writefile(readfile(a:input),a:output)
endfunction

function! s:compiler(bibtex,start,runs,verbose,command)
    call s:outdir()
    	" IF b:texcompiler is not compatible with the viewer
    if b:texcompiler =~ "^\s*pdf" && b:Viewer == "xdvi" ? 1 :  b:texcompiler !~ "^\s*pdf" && (b:Viewer == "xpdf" || b:Viewer == "epdfview" || b:Viewer == "acroread" || b:Viewer == "kpdf")
	 
    	echohl WaningMsg | echomsg "Your"b:texcompiler"and"b:Viewer"are not compatible:" 
	echomsg "b:texcompiler=" . b:texcompiler	
	echomsg "b:Viewer=" . b:Viewer	
    endif
	let s:tmpfile=tempname()
	let s:dir=fnamemodify(s:tmpfile,":h")
	let s:job=fnamemodify(s:tmpfile,":t")
	if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex"
	    let l:ext = ".pdf"
	else
	    let l:ext = ".dvi"	
	endif
	let l:outfile=b:outdir . (fnamemodify(expand("%"),":t:r")) . l:ext
	let l:outaux=b:outdir . (fnamemodify(expand("%"),":t:r")) . ".aux"
	let l:outlog=b:outdir . (fnamemodify(expand("%"),":t:r")) . ".log"
"	COPY IMPORTANT FILES TO TEMP DIRECTORY WITH CORRECT NAME 
	let l:list=filter(copy(g:keep),'v:val != "log"')
	for l:i in l:list
"   		echomsg "DEBUG extensions" l:i
	    let l:ftc=b:outdir . fnamemodify(expand("%"),":t:r") . "." . l:i
"  		echomsg "DEBUG file to copy"l:ftc
	    if filereadable(l:ftc)
		call s:copy(l:ftc,s:tmpfile . "." . l:i)
	    endif
	endfor
" 	let l:texoutputfiles=b:outdir . (fnamemodify(expand("%"),":t:r")) . ".*"
" 	HANDLE XPDF RELOAD 
	if b:Viewer == "xpdf"
	    if a:start == 1
		"if xpdf is not running and we want to run it.
		let s:xpdfreload = b:Viewer . " -remote " . shellescape(b:XpdfServer) . " " . shellescape(l:outfile)
	    else
		if s:xpdfpid() != ""
		    "if xpdf is running (then we want to reload).
		    "This is where I use ps command.
		    let s:xpdfreload = b:Viewer . " -remote " . shellescape(b:XpdfServer) . " -reload"	
		else
		    "if xpdf is not running (then we do not want
		    "to run it).
		    let s:xpdfreload = ""
		endif
	    endif
	else
	    if a:start == 1
		" if b:Viewer is not running and we want to open it.
		let s:xpdfreload = b:Viewer . " " . shellescape(l:outfile) 
	    else
		" if b:Viewer is not running then we do not want to
		" open it.
		let s:xpdfreload = ""
	    endif	
	endif
"  				echomsg "DEBUG xpdfreload="s:xpdfreload
" 	IF OPENINIG NON EXISTENT OUTPUT FILE
"	only xpdf needs to be run before (above we are going to reload it!)
	if a:start == 1 && b:Viewer == "xpdf"
	    let s:start = b:Viewer . " -remote " . shellescape(b:XpdfServer) . " & "
	else
	    let s:start = ""	
	endif
"	SET THE COMMAND 
	let s:comp=b:texcompiler . " " . b:texoptions . " -interaction " . s:texinteraction . " -output-directory " . s:dir . " -jobname " . s:job . " " . shellescape(expand("%"))
	let s:vcomp=b:texcompiler . " " . b:texoptions  . " -interaction errorstopmode -output-directory " . s:dir . " -jobname " . s:job . " " . shellescape(expand("%"))
	if a:verbose == 0 || a:runs > 1
	    let s:texcomp=s:comp
	else
	    let s:texcomp=s:vcomp
	endif
	if a:runs >= 2 && a:bibtex != 1
	    " how many times we wan to call b:texcompiler
	    let l:i=1
	    while l:i < a:runs - 1
		let l:i+=1
		let s:texcomp=s:texcomp . " ; " . s:comp
	    endwhile
	    if a:verbose == 0
		let s:texcomp=s:texcomp . " ; " . s:comp
	    else
		let s:texcomp=s:texcomp . " ; " . s:vcomp
	    endif
"   		echomsg "DEBUG runs s:texcomp="s:texcomp
	endif
"  	    	echomsg "DEBUG X command s:texcomp=" s:texcomp
	if a:bibtex == 1
	    if filereadable(l:outaux)
		call s:copy(l:outaux,s:tmpfile . ".aux")
		let s:texcomp="bibtex " . s:tmpfile . ".aux ; " . s:comp . "  1>/dev/null 2>&1 "
	    else
		let s:texcomp=s:comp . " ; clear ; bibtex " . s:tmpfile . ".aux ; " . s:comp . " 1>/dev/null 2>&1 "
	    endif
	    if a:verbose != 0
		let s:texcomp=s:texcomp . " ; " . s:vcomp
	    else
		let s:texcomp=s:texcomp . " ; " . s:comp
	    endif
	endif
	let s:cpoption="--remove-destination "
	let s:cpoutfile="cp " . s:cpoption . shellescape(s:tmpfile . l:ext) . " " . shellescape(l:outfile) 
	let s:command="(" . s:texcomp . " && (" . s:cpoutfile . " ; " . s:xpdfreload . ") || (" . s:cpoutfile . ")" 
	let s:copy=""
	let l:j=1
	for l:i in g:keep 
	    let s:copycmd="cp " . s:cpoption . " " . shellescape(s:tmpfile . "." . l:i) . " " . shellescape(b:outdir . (fnamemodify(expand("%"),":t:r")) . "." . l:i) 
"   		echomsg "DEBUG 2 copycmd"s:copycmd
	    if l:j == 1
		let s:copy=s:copycmd
	    else
		let s:copy=s:copy . " ; " . s:copycmd	  
	    endif
	    let l:j+=1
	endfor
	    let s:command=s:command . " ; " . s:copy
 	let s:rmtmp="rm " . s:tmpfile . "*" 
	let s:command=s:command . " ; " . s:rmtmp . ")&"
	if a:start == 1 
	    let s:command=s:start . s:command
	endif
	let b:texcommand=s:command
	let s:backup=&backup
	let s:writebackup=&writebackup
	if a:command == "AU"  
	    if &backup || &writebackup | setlocal nobackup | setlocal nowritebackup | endif
	endif
" 		echomsg "DEBUG writting backup=" . &backup . " writebackup=" . &writebackup
	silent! w
	if a:command == "AU"  
	    let &l:backup=s:backup 
	    let &l:writebackup=s:writebackup 
	endif
	if a:verbose == 0
" 		echomsg "DEBUG compile s:command="s:command
	    call system(s:command)
	else
	    let s:command="!clear;" . s:texcomp . " ; " . s:cpoutfile . " ; " . s:copy
	    let b:texcommand=s:command
" 		echomsg "DEBUG verbose compile s:command=" . s:command
	    exe s:command
	endif
endfunction
"-------------------------------------------------------------------------
function! s:auTeX()
   if b:autex	
    if s:compare(readfile(expand("%")),bufname("%"))
	call s:compiler(0,0,1,0,"AU")
" 	    echomsg "DEBUG compare: DIFFER"
	redraw
"   else
"  	    echomsg "DEBUG compare: THE SAME"
    endif
   endif
endfunction
au! CursorHold $HOME*.tex call s:auTeX()
"-------------------------------------------------------------------------
if !exists("*TEX")
function! TEX(...)
let s:name=tempname()
if a:0 >= 1
    if a:1 > 1
	echomsg b:texcompiler . " will run " . a:1 . " times."
    else
	echomsg b:texcompiler . " will run once."
    endif
    call s:compiler(0,0,a:1,0,"COM")
elseif a:0 == 0
    call s:compiler(0,0,1,0,"COM")
endif
endfunction
endif

" command! -buffer -count=1 TEX	:call TEX(<count>)		 
if !exists("*ToggleAuTeX")
function! ToggleAuTeX()
  if b:autex != 1
    let b:autex=1	
    echo "automatic tex processing is ON"
  else
    let b:autex=0
    echo "automatic tex processing is OFF"
endif
endfunction
endif
if !exists("*VTEX")
function! VTEX(...)
    let s:name=tempname()
if a:0 >= 1
    if a:1 > 1
	echomsg b:texcompiler . " will run " . a:1 . " times."
    else
	echomsg b:texcompiler . " will run once."
    endif
    sleep 1
    call s:compiler(0,0,a:1,1,"COM")
else
    call s:compiler(0,0,1,1,"COM")
endif
endfunction
endif
"-------------------------------------------------------------------------
if !exists("*SimpleBibtex")
function! SimpleBibtex()
    call s:outdir() 
    let l:bibcommand="bibtex "
    let l:auxfile=b:outdir . (fnamemodify(expand("%"),":t:r")) . ".aux"
    if filereadable(l:auxfile)
	let l:command=l:bibcommand . shellescape(l:auxfile)
	echo system(l:command)
    else
	echomsg "No aux file in " . b:outdir
    endif
"  	!clear;if [[ -h "%" ]];then realname=`readlink "%"`;realdir=`dirname "$realname"`;b_name=`basename "$realname" .tex`;else realdir="%:p:h";b_name="%:r";fi;bibtex "$realdir/$b_name".aux
endfunction
endif

if !exists("*Bibtex")
function! Bibtex(...)
    let s:bibname=tempname()
    let s:auxf=s:bibname . ".aux"
    if a:0 == 0
"  	    echomsg "DEBUG Bibtex"
	call s:compiler(1,0,0,0,"COM")
    else
"  	    echomsg "DEBUG Bibtex verbose"
	call s:compiler(1,0,0,1,"COM")
    endif
endfunction
endif

"-------------------------------------------------------------------------

" TeX LOG FILE
if &buftype == 'quickfix'
	setlocal modifiable
	setlocal autoread
endif	

"-------------------------------------------------------------------------
if !exists("*Delete")
function! Delete()
    call s:outdir()
    let s:error=0
    for l:ext in g:texextensions
	if executable(g:rmcommand)
	    if g:rmcommand =~ "^\s*rm\p*" || g:rmcommand =~ "^\s*perltrash\p*"
		let l:rm=g:rmcommand . " " . shellescape(b:outdir) . "*." . l:ext . " 2>/dev/null && echo Removed ./*" . l:ext . " files"
	    endif
" 	    echomsg "DEBUG " l:rm
	echo system(l:rm)
	else
	    let s:error=1
		let l:file=b:outdir . fnamemodify(expand("%"),":t:r") . "." . l:ext
		if delete(l:file) == 0
		    echo "Removed " . l:file 
	    endif
	endif
    endfor
" 	if s:error
" 		echo "Pleas set g:rmcommand to clear the working directory"
" 	endif
endfunction
endif

"-------------------------------------------------------------------------
if !exists("*OpenLog")
function! OpenLog()
    if filereadable(&l:errorfile)
	exe "tabe +set\\ nospell\\ ruler " . &l:errorfile
    else
	echo "No log file"
    endif
endfunction
endif

if !exists("*TexLog")
function! TexLog(options)
    if executable("texloganalyser")
       let s:command="texloganalyser " . a:options . " " . &l:errorfile
       echo system(s:command)
    else	
       echo "Please install texloganalyser to have this functionality. Perl program written by Thomas van Oudenhove."  
    endif
endfunction
endif

if !exists("*Pdffonts")
function! Pdffonts()
    if b:outdir !~ "\/$"
	b:outdir=b:outdir . "/"
    endif
    if executable("pdffonts")
	let s:command="pdffonts " . b:outdir . fnameescape(fnamemodify(expand("%"),":t:r")) . ".pdf"
	echo system(s:command)
    else
	echo "Please install pdffonts to have this functionality. In gentoo it is in the package app-text/poppler-utils."  
    endif
endfunction	
endif

" function! s:setprintexpr()
"     if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex"
" 	let s:ext = ".pdf"
"     else
" 	let s:ext = ".dvi"	
"     endif
"     let &printexpr="system('lpr' . (&printdevice == '' ? '' : ' -P' . &printdevice) . ' " . fnameescape(fnamemodify(expand("%"),":p:r")) . s:ext . "') . + v:shell_error"
" endfunction
" call s:setprintexpr()

if !exists("*Print")
function! Print(printeroptions)
    call s:outdir()
    if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex" 
	let l:ext = ".pdf"
    else
	let l:ext = ".dvi"	
    elseif b:texcompiler =~ "lua"
	if b:texoptions == "" || b:texoptions =~ "output-format=\s*pdf"
	    let l:ext = ".pdf"
	else
	    let l:ext = ".dvi"
	endif
    endif
    if a:printeroptions==''
	s:command="lpr " . b:outdir . fnameescape(fnamemodify(expand("%"),":t:r")) . l:ext
    else
	s:command="lpr " . a:printeroptions . " " . b:outdir . fnameescape(fnamemodify(expand("%"),":p:t:r")) . ".pdf"
    endif
    call system(s:command)
endfunction
endif

"---------------------- SEARCH IN BIB FILES ----------------------
" This function counts accurence of a:keyword in string a:line, 
function! s:count(line,keyword)
    let l:line=a:line
    let l:i=0  
    while stridx(l:line,a:keyword) != '-1'
	if stridx(l:line,a:keyword) !='-1' 
            let l:line=strpart(l:line,stridx(l:line,a:keyword)+1)
	endif
	let l:i+=1
    endwhile
    return l:i
endfunction
let g:bibentries=['article', 'book', 'booklet', 'conference', 'inbook', 'incollection', 'inproceedings', 'manual', 'mastertheosis', 'misc', 'phdthesis', 'proceedings', 'techreport', 'unpublished']

"--------------------- SEARCH ENGINE ------------------------------ 
if !exists("*FindBibFiles")
function! FindBibFiles(bufname)
    let b:texfile=readfile(a:bufname)
    let s:i=0
    let s:bibline=[]
    for line in b:texfile
	if line =~ "\\\\bibliography{"
	    let s:bibline=add(s:bibline,line) 
	    let s:i+=1
	endif
    endfor
    let l:nr=s:i
    let s:i=1
    let files=""
    for l:line in s:bibline
	if s:i==1
	    let files=substitute(l:line,"\\\\bibliography{\\(.*\\)}","\\1","") . ","
	else
	    let files=files . substitute(l:line,"\\\\bibliography{\\(.*\\)}","\\1","") . "," 
	endif
	let s:i+=1
    endfor
    unlet l:line
    let l:bibfs=[]
    while len(files) > 0
	let l:x=stridx(files,",")
	let l:f=strpart(files,0,l:x)
	let files=strpart(files,l:x+1)
	let l:bibfs=add(l:bibfs,l:f)
    endwhile
    unlet l:f
" this variable will store all found and user defined bibfiles:    
    let l:allbibfiles=[]
    for l:f in l:bibfs
	if l:f =~ "^\s*\/" 
	    call add(l:allbibfiles,l:f)
	else	
	    call add(l:allbibfiles,b:outdir . l:f)
	endif
    endfor
    unlet l:f
    if exists('b:bibfiles')
	call extend(l:allbibfiles,b:bibfiles)
    endif
" clear the list s:allbibfile from double entries 
    let l:callbibfiles=[]
    for l:f in l:allbibfiles
	if count(l:callbibfiles,l:f) == 0
	    call add(l:callbibfiles,l:f)
	endif
    endfor
    let l:allbibfiles=deepcopy(l:callbibfiles)
    unlet l:f
" this variable will store unreadable bibfiles:    
    let s:notreadablebibfiles=[]
" this variable will store the final result:   
    let s:bibfiles=[]
    for l:f in l:allbibfiles
	if filereadable(l:f . ".bib")
	    call add(s:bibfiles,l:f)
	else
	    echohl WarningMsg | echomsg "Bibfile " . l:f . ".bib is not readable." | echohl None
	    if count(s:notreadablebibfiles,l:f) == 0 
		call add(s:notreadablebibfiles,l:f)
	    endif
	endif
    endfor
    unlet l:f
    if s:notreadablebibfiles == l:allbibfiles
	echoerr "All bib files are not readable."
    endif
    return s:bibfiles
endfunction
endif
" let s:bibfiles=FindBibFiles(bufname('%'))
function! s:searchbib(pattern) 
" 	echomsg "DEBUG pattern" a:pattern
    call s:outdir()
    let s:bibfiles=FindBibFiles(bufname('%'))
"   Make a pattern which will match for the elements of the list g:bibentries
    let l:pattern = '^\s*@\(\%(\<article\>\)'
    for l:bibentry in g:bibentries
	if l:bibentry != 'article'
	let l:pattern=l:pattern . '\|\%(\<' . l:bibentry . '\>\)'
	endif
    endfor
    unlet l:bibentry
    let l:pattern=l:pattern . '\)'
    let b:bibentryline={} 
"   READ EACH BIBFILE IN TO DICTIONARY s:bibdict, WITH KEY NAME BEING THE bibfilename
    let s:bibdict={}
    let l:bibdict={}
    let b:bibdict={}				" DEBUG
    for l:f in s:bibfiles
	let s:bibdict[l:f]=[]
 	let s:bibdict[l:f]=readfile(l:f . ".bib")	
	let l:bibdict[l:f]=copy(s:bibdict[l:f])
" clear the s:bibdict values from lines which begin with %    
	let l:x=0
	for l:line in s:bibdict[l:f]
	    if l:line =~ '^\s*\%(%\|@\cstring\)' 
		call remove(l:bibdict[l:f],l:x)
	    else
		let l:x+=1
	    endif
	endfor
	unlet l:line
    endfor
    for l:f in s:bibfiles
	let l:list=[]
	let l:nr=1
	    let b:bibdict[l:f]=l:bibdict[l:f]		" DEBUG
	for l:line in l:bibdict[l:f]
	    if substitute(l:line,'{\|}','','g') =~ a:pattern
		let l:true=1
		let l:t=0
		while l:true == 1
		    let l:tnr=l:nr-l:t
		   if l:bibdict[l:f][l:tnr-1] =~ l:pattern && l:tnr >= 0
		       let l:true=0
		       let l:list=add(l:list,l:tnr)
		   elseif l:tnr <= 0
		       let l:true=0
		   endif
		   let l:t+=1
		endwhile
	    endif
	    let l:nr+=1
	endfor
" CLEAR THE l:list FROM ENTRIES WHICH APPEAR TWICE OR MORE --> l:clist
    let l:pentry="A"		" We want to ensure that l:entry (a number) and p:entry are different
    for l:entry in l:list
	if l:entry != l:pentry
	    if count(l:list,l:entry) > 1
		while count(l:list,l:entry) > 1
		    let l:eind=index(l:list,l:entry)
		    call remove(l:list,l:eind)
		endwhile
	    endif 
	    let l:pentry=l:entry
	endif
    endfor
    let b:bibentryline=extend(b:bibentryline,{ l:f : l:list })
    endfor
"   CHECK EACH BIBFILE
    let l:bibresults={}
    for l:bibfile in keys(b:bibentryline)
	let l:f=l:bibfile . ".bib"
"s:bibdict[l:f])	CHECK EVERY STARTING LINE (we are going to read bibfile from starting
"	line till the last matching } 
 	let s:bibd={}
 	for l:linenr in b:bibentryline[l:bibfile]
"
" 	new algorithm is on the way, using searchpair function
" 	    l:time=0
" 	    l:true=1
" 	    let b:pair1=searchpair('(','',')','b')
" 	    let b:pair2=searchpair('{','','}','b')
" 	    let l:true=b:pair1+b:pair2
" 	    while l:true == 0
" 		let b:pair1p=b:pair1	
" 		let b:pair1=searchpair('(','',')','b')
" 		let b:pair2p=b:pair2	
" 		let b:pair2=searchpair('{','','}','b')
" 		let l:time+=1
" 	    endwhile
" 	    let l:bfieldline=l:time
	    
	    let l:nr=l:linenr-1
	    let l:i=s:count(get(l:bibdict[l:bibfile],l:linenr-1),"{")-s:count(get(l:bibdict[l:bibfile],l:linenr-1),"}")
	    let l:j=s:count(get(l:bibdict[l:bibfile],l:linenr-1),"(")-s:count(get(l:bibdict[l:bibfile],l:linenr-1),")") 
	    let s:lbibd={}
	    let s:lbibd["KEY"]=get(l:bibdict[l:bibfile],l:linenr-1)
	    let l:x=1
" we go from the first line of bibentry, i.e. @article{ or @article(, until the { and (
" will close. In each line we count brackets.	    
            while l:i>0	|| l:j>0
		let l:tlnr=l:x+l:linenr
		let l:pos=s:count(get(l:bibdict[l:bibfile],l:tlnr-1),"{")
		let l:neg=s:count(get(l:bibdict[l:bibfile],l:tlnr-1),"}")
		let l:i+=l:pos-l:neg
		let l:pos=s:count(get(l:bibdict[l:bibfile],l:tlnr-1),"(")
		let l:neg=s:count(get(l:bibdict[l:bibfile],l:tlnr-1),")")
		let l:j+=l:pos-l:neg
		let l:lkey=tolower(matchstr(strpart(get(l:bibdict[l:bibfile],l:tlnr-1),0,stridx(get(l:bibdict[l:bibfile],l:tlnr-1),"=")),'\<\w*\>'))
		if l:lkey != ""
		    let s:lbibd[l:lkey]=get(l:bibdict[l:bibfile],l:tlnr-1)
			let l:y=0
" IF THE LINE IS SPLIT ATTACH NEXT LINE									
			let l:lline=substitute(get(l:bibdict[l:bibfile],l:tlnr+l:y-1),'\\"\|\\{\|\\}\|\\(\|\\)','','g')
			let l:pos=s:count(l:lline,"{")
			let l:neg=s:count(l:lline,"}")
			let l:m=l:pos-l:neg
			let l:pos=s:count(l:lline,"(")
			let l:neg=s:count(l:lline,")")
			let l:n=l:pos-l:neg
			let l:o=s:count(l:lline,"\"")
" this checks if bracets {}, and () and "" appear in pairs in the current line:  
			if l:m>0 || l:n>0 || l:o>l:o/2*2 
			    while l:m>0 || l:n>0 || l:o>l:o/2*2 
				let l:pos=s:count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"{")
				let l:neg=s:count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"}")
				let l:m+=l:pos-l:neg
				let l:pos=s:count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"(")
				let l:neg=s:count(get(l:bibdict[l:bibfile],l:tlnr+l:y),")")
				let l:n+=l:pos-l:neg
				let l:o+=s:count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"\"")
" Let us append the next line: 
				let s:lbibd[l:lkey]=substitute(s:lbibd[l:lkey],'\s*$','','') . " ". substitute(get(l:bibdict[l:bibfile],l:tlnr+l:y),'^\s*','','')
				let l:y+=1
				if l:y > 30
				    echoerr "ATP-Error /see :h atp-errors-bibsearch/, infinite in bibentry at line "  l:linenr " (check line " . l:tlnr . ") in " . l:f
				    break
				endif
			    endwhile
			endif
		endif
" we have to go line by line and we could skip l:y+1 lines, but we have to
" keep l:m, l:o values. It do not saves much.		
		let l:x+=1
		if l:x > 30
			echoerr "ATP-Error /see :h atp-errors-bibsearch/, infinite loop in bibentry at line "  l:linenr " in " . l:f
			break
	        endif
		let b:x=l:x
		unlet l:tlnr
	    endwhile
	    let s:bibd[l:linenr]=s:lbibd
	    unlet s:lbibd
	endfor
	let l:bibresults[l:bibfile]=s:bibd
    endfor
    let b:bibresults=l:bibresults
    return l:bibresults
    unlet l:bibresults
endfunction
"
"------------------------SHOW FOUND BIBFIELDS----------------------------
let g:bibmatchgroup='String'
let g:defaultbibflags='tabejsyu'
let g:defaultallbibflags='tabejfsvnyPNSohiuHcp'
let b:lastbibflags=g:defaultbibflags	" Set the lastflags variable to the default value on the startup.
" g:bibflagsdict={ 'flag' : ['name','what to print on the screen /13 letters/'] }
let g:bibflagsdict={ 't' : ['title', 'title        '] , 'a' : ['author', 'author       '], 
		\ 'b' : ['booktitle', 'booktitle    '], 'c' : ['mrclass', 'mrclass      '], 
		\ 'e' : ['editor', 'editor       '], 	'j' : ['journal', 'journal      '], 
		\ 'f' : ['fjournal', 'fjournal     '], 	'y' : ['year', 'year         '], 
		\ 'n' : ['number', 'number       '], 	'v' : ['volume', 'volume       '], 
		\ 's' : ['series', 'series       '], 	'p' : ['pages', 'pages        '], 
		\ 'P' : ['publisher', 'publisher    '], 'N' : ['note', 'note         '], 
		\ 'S' : ['school', 'school       '], 	'h' : ['howpublished', 'howpublished '], 
		\ 'o' : ['organization', 'organization '], 'I' : ['institution' , 'institution '],
		\ 'u' : ['url','url          '],
		\ 'H' : ['homepage', 'homepage     '], 	'i' : ['issn', 'issn         '] }
let s:bibflagslist=keys(g:bibflagsdict)
let s:bibflagsstring=join(s:bibflagslist,'')
let g:kwflagsdict={ 	  '@a' : '@article', 	'@b' : '@book\%(let\)\@<!', 
			\ '@B' : '@booklet', 	'@c' : '@in\%(collection\|book\)', 
			\ '@m' : '@misc', 	'@M' : '@manual', 
			\ '@p' : '@\%(conference\)\|\%(\%(in\)\?proceedings\)', 
			\ '@t' : '@\%(\%(master)\|\%(phd\)\)thesis', 
			\ '@T' : '@techreport', '@u' : '@unpublished'}    

highlight link BibResultsFileNames 		Title	
highlight link BibResultEntry		ModeMsg
highlight link BibResultsMatch		WarningMsg
highlight link BibResultsGeneral		Normal


highlight link Chapter 			Normal	
highlight link Section			Normal
highlight link Subsection		Normal
highlight link Subsubsection		Normal
highlight link CurrentSection		WarningMsg

function! s:comparelist(i1, i2)
   return str2nr(a:i1) == str2nr(a:i2) ? 0 : str2nr(a:i1) > str2nr(a:i2) ? 1 : -1
endfunction
"-------------------------s:showresults--------------------------------------
function! s:showresults(bibresults,flags,pattern)
 
" FLAGS:
" for currently supported flags see ':h atp_bibflags'
" All - all flags	
" L - last flag
" a - author
" e - editor
" t - title
" b - booktitle
" j - journal
" s - series
" y - year
" n - number
" v - volume
" p - pages
" P - publisher
" N - note
" S - school
" h - howpublished
" o - organization
" i - institution

    function! s:showvalue(value)
	return substitute(strpart(a:value,stridx(a:value,"=")+1),'^\s*','','')
    endfunction
    let s:z=1
    let l:ln=1
    let l:listofkeys={}
"--------------SET UP FLAGS--------------------------    
	    let l:allflagon=0
	    let l:flagslist=[]
	    let l:kwflagslist=[]
    " flags o and i are synonims: (but refer to different entry keys): 
	if a:flags =~ '\Ci' && a:flags !~ '\Co'
	    let a:flags=substitute(a:flags,'i','io','') 
	elseif a:flags !~ '\Ci' && a:flags =~ '\Co'
	    let a:flags=substitute(a:flags,'o','oi','')
	endif
	if a:flags !~ 'All'
	    if a:flags =~ 'L'
 		if strpart(a:flags,0,1) != '+'
 		    let l:flags=b:lastbibflags . substitute(strpart(a:flags,0),'\CL','','g')
 		else
 		    let l:flags=b:lastbibflags . substitute(a:flags,'\CL','','g')
 		endif
	    else
		if a:flags == "" 
		    let l:flags=g:defaultbibflags
		elseif strpart(a:flags,0,1) != '+' && a:flags !~ 'All' 
		    let l:flags=a:flags
		elseif strpart(a:flags,0,1) == '+' && a:flags !~ 'All'
		    let l:flags=g:defaultbibflags . strpart(a:flags,1)
		endif
	    endif
	    let b:lastbibflags=substitute(l:flags,'+\|L','','g')
		if l:flags != ""
		    let l:expr='\C[' . s:bibflagsstring . ']' 
		    while len(l:flags) >=1
			let l:oneflag=strpart(l:flags,0,1)
    " if we get a flag from the variable s:bibflagsstring we copy it to the list l:flagslist 
			if l:oneflag =~ l:expr
			    let l:flagslist=add(l:flagslist,l:oneflag)
			    let l:flags=strpart(l:flags,1)
    " if we get '@' we eat ;) two letters to the list l:kwflagslist			
			elseif l:oneflag == '@'
			    let l:oneflag=strpart(l:flags,0,2)
			    if index(keys(g:kwflagsdict),l:oneflag) != -1
				let l:kwflagslist=add(l:kwflagslist,l:oneflag)
			    endif
			    let l:flags=strpart(l:flags,2)
    " remove flags which are not defined
			elseif l:oneflag !~ l:expr && l:oneflag != '@'
			    let l:flags=strpart(l:flags,1)
			endif
		    endwhile
		endif
	else
    " if the flag 'All' was specified. 	    
	    let l:flagslist=split(g:defaultallbibflags, '\zs')
	    let l:af=substitute(a:flags,'All','','g')
	    for l:kwflag in keys(g:kwflagsdict)
		if a:flags =~ '\C' . l:kwflag	
		    call extend(l:kwflagslist,[l:kwflag])
		endif
	    endfor
	endif
	    let b:flagslist=l:flagslist				" debug
	    let b:kwflagslist=l:kwflagslist			" debug
" echohl BibResultEntry | echomsg "BibSearch 2.0" | echohl None	    
" echohl BibResultsMatch | echomsg "flags:" . join(l:flagslist,'') . join(l:kwflagslist,'') | echohl None
				let l:bufnr=bufnr("___" . a:pattern . "___"  )
				if l:bufnr != -1
				    let l:bdelete=l:bufnr . "bdelete"
				    exe l:bdelete
				endif
				unlet l:bufnr
 				let l:openbuffer=" +setl\\ buftype=nofile\\ filetype=bibsearch_atp " . fnameescape("___" . a:pattern . "___")
				if g:vertical ==1
				    let l:openbuffer="vnew " . l:openbuffer 
				    let l:skip=""
				else
				    let l:openbuffer="new " . l:openbuffer 
				    let l:skip="       "
				endif
				exe l:openbuffer
				call s:setwindow()
    for l:bibfile in keys(a:bibresults)
	if a:bibresults[l:bibfile] != {}
"  	    echohl BibResultsFileNames | echomsg "Found in " . l:bibfile | echohl None
	    call setline(l:ln, "Found in " . l:bibfile )	
	    let l:ln+=1
	endif
	for l:linenr in copy(sort(keys(a:bibresults[l:bibfile]),"s:comparelist"))
" make a dictionary of clear values, which we will fill with found entries. 	    
" the default value is no<keyname>, which after all is matched and not showed
	    let l:values={'key' : 'nokey'}	
	    for l:flag in s:bibflagslist 
		let l:values=extend(l:values,{ g:bibflagsdict[l:flag][0] : 'no' . g:bibflagsdict[l:flag][0] })
	    endfor
	    unlet l:flag
	    let b:values=l:values
" fill l:values with a:bibrsults	    
	    let l:values["key"]=a:bibresults[l:bibfile][l:linenr]["KEY"]
	    for l:key in keys(l:values)
		if l:key != 'key' && get(a:bibresults[l:bibfile][l:linenr],l:key,"no" . l:key) != "no" . l:key
		    let l:values[l:key]=a:bibresults[l:bibfile][l:linenr][l:key]
		endif
	    endfor
" ----------------------------- SHOW ENTRIES -------------------------
" first we check the keyword flags, @a,@b,... it passes if at least one flag
" is matched
	    let l:check=0
	    for l:lkwflag in l:kwflagslist
	        let l:kwflagpattern= '\C' . g:kwflagsdict[l:lkwflag]
		if l:values['key'] =~ l:kwflagpattern
		   let l:check=1
		endif
	    endfor
	    if l:check == 1 || len(l:kwflagslist) == 0
		let l:linenumber=index(s:bibdict[l:bibfile],l:values["key"])+1
 		call setline(l:ln,s:z . ". line " . l:linenumber . "  " . l:values["key"])
		let l:ln+=1
 		let l:c0=s:count(l:values["key"],'{')-s:count(l:values["key"],'(')

	
" this goes over the entry flags:
		for l:lflag in l:flagslist
" we check if the entry was present in bib file:
		    if l:values[g:bibflagsdict[l:lflag][0]] != "no" . g:bibflagsdict[l:lflag][0]
" 			if l:values[g:bibflagsdict[l:lflag][0]] =~ a:pattern
			    call setline(l:ln, l:skip . g:bibflagsdict[l:lflag][1] . " = " . s:showvalue(l:values[g:bibflagsdict[l:lflag][0]]))
			    let l:ln+=1
" 			else
" 			    call setline(l:ln, l:skip . g:bibflagsdict[l:lflag][1] . " = " . s:showvalue(l:values[g:bibflagsdict[l:lflag][0]]))
" 			    let l:ln+=1
" 			endif
		    endif
		endfor
		let l:lastline=getline(line('$'))
		let l:c1=s:count(l:lastline,'{')-s:count(l:lastline,'}')
		let l:c2=s:count(l:lastline,'(')-s:count(l:lastline,')')
		let l:c3=s:count(l:lastline,'\"')
" 		echomsg "last line " . line('$') . "     l:ln=" l:ln . "    l:c0=" . l:c0		"DEBUG
		if l:c0 == 1 && l:c1 == -1
		    call setline(line('$'),substitute(l:lastline,'}\s*$','',''))
		    call setline(l:ln,'}')
		    let l:ln+=1
		elseif l:c0 == 1 && l:c1 == 0	
		    call setline(l:ln,'}')
		    let l:ln+=1
		elseif l:c0 == -1 && l:c2 == -1
		    call setline(line('$'),substitute(l:lastline,')\s*$','','')
		    call setline(l:ln,')')
		    let l:ln+=1
		elseif l:c0 == -1 && l:c1 == 0	
		    call setline(l:ln,')')
		    let l:ln+=1
		endif
		let l:listofkeys[s:z]=l:values["key"]
		let s:z+=1
	    endif
	endfor
    endfor
    call matchadd("Search",a:pattern)
    return l:listofkeys
endfunction

if !exists("*BibSearch")
"  There are three arguments: {pattern}, [flags, [choose]]
function! BibSearch(...)
    if a:0 == 0
	let l:bibresults=s:searchbib('')
	let b:listofkeys=s:showresults(l:bibresults,'','')
    elseif a:0 == 1
	let l:bibresults=s:searchbib(a:1)
	let b:listofkeys=s:showresults(l:bibresults,'',a:1)
    else
	let l:bibresults=s:searchbib(a:1)
	let b:listofkeys=s:showresults(l:bibresults,a:2,a:1)
    endif
endfunction
endif

"---------- TOC -----------------------------------------------------------
" this function sets the options of BibSearch, ToC and Labels windows.
function! s:setwindow()
    " These options are set in the command line
" +setl\\ buftype=nofile\\ filetype=bibsearch_atp   
" +setl\\ buftype=nofile\\ filetype=toc_atp\\ nowrap
" +setl\\ buftype=nofile\\ filetype=toc_atp\\ syntax=labels_atp
	setlocal nonumber
 	setlocal winfixwidth
	setlocal noswapfile	
	setlocal window
	if &filetype == "bibsearch_atp"
	    setlocal winwidth=30
	elseif &filetype == "toc_atp"
	    setlocal winwidth=20
	endif
endfunction
let g:sections={
    \	'chapter' 	: [           '^\s*\(\\chapter.*\)',	'\\chapter\*'],	
    \	'section' 	: [           '^\s*\(\\section.*\)',	'\\section\*'],
    \ 	'subsection' 	: [	   '^\s*\(\\subsection.*\)',	'\\subsection\*'],
    \	'subsubsection' : [ 	'^\s*\(\\subsubsection.*\)',	'\\subsubsection\*'],
    \	'bibliography' 	: ['^\s*\(\\begin.*{bibliography}.*\|\\bibliography\s*{.*\)' , 'nopattern'],
    \	'abstract' 	: ['^\s*\(\\begin\s*{abstract}.*\|\\abstract\s*{.*\)',	'nopattern']}
" this works only for latex documents.
"----------- Make TOC -----------------------------
" make t:toc a dictionary (with keys: buffer number) of dictionaries which
" keys are: line numbers and values [ 'section-name', 'number', 'title'] where
" section name is element of keys(g:sections), number is the total number,
" 'title=\1' where \1 is returned by the g:section['key'][0] pattern.
function! s:maketoc(filename)

    " this will store information { 'linenumber' : ['chapter/section/..', 'sectionnumber', 'section title', '0/1=not starred/starred'] }
    let l:toc={}

    " if the dictinary with labels is not defined, define it
    if !exists("t:labels")
	let t:labels={}
    endif
    " TODO we could check if there are changes in the file and copy the buffer
    " to this variable only if there where changes.
    let l:texfile=[]
    " getbufline reads onlu loaded buffers, unloaded can be read from file.
    let l:bufname=fnamemodify(a:filename,":t")
    if bufloaded("^" . l:bufname . "$")
	let l:texfile=getbufline("^" . l:bufname . "$","1","$")
    else
	w
	let l:texfile=readfile(a:filename)
    endif
    let l:true=1
    let l:i=0
    " remove the part before \begin{document}
    while l:true == 1
	if l:texfile[0] =~ '\\begin\s*{document}'
		let l:true=0
	endif
	call remove(l:texfile,0)
	let l:i+=1
    endwhile
    let l:bline=l:i
    let l:i=1
    " set variables for chapter/section numbers
    for l:section in keys(g:sections)
	let l:ind{l:section}=0
    endfor
    " make a filter
    let l:j=0
    for l:section in keys(g:sections)
	if l:j == 0 
	    let l:filter=g:sections[l:section][0] . ''
	else
	    let l:filter=l:filter . '\|' . g:sections[l:section][0] 
	endif
	let l:j+=1
    endfor
    " filter l:texfile    
    let s:filtered=filter(deepcopy(l:texfile),'v:val =~ l:filter')
    let b:filtered=s:filtered
    let b:texfile=l:texfile
    for l:line in s:filtered
	for l:section in keys(g:sections)
	    if l:line =~ g:sections[l:section][0] 
		if l:line !~ '^\s*%'
		    " THIS DO NOT WORKS WITH \abstract{ --> empty set, but with
		    " \chapter{title} --> title, solution: the name of
		    " 'Abstract' will be plased, as we know what we have
		    " matched
		    let l:title=l:line
		    " test if it is a starred version.
		    let l:star=0
		    if g:sections[l:section][1] != 'nopattern' && l:line =~ g:sections[l:section][1] 
			let l:star=1 
		    else
			let l:star=0
		    endif
" 		    substitute(l:line,g:sections[l:section][0],'\1','')
		    let l:i=index(l:texfile,l:line)
		    let l:tline=l:i+l:bline+1
		    " if it is not starred version add one to section number
		    if l:star==0
			let l:ind{l:section}+=1
		    endif
		    let l:start=stridx(l:title,'{')+1
		    let l:title=strpart(l:title,l:start)
		    " we are looking for the maching '}' 
		    let l:count=1
		    let l:i=-1
		    while l:i<=len(l:title)
			let l:i+=1
			if strpart(l:title,l:i,1) == '{'	
			    let l:count+=1
			elseif strpart(l:title,l:i,1) == '}'
			    let l:count-=1
			endif
			if l:count==0
			    break
			endif
		    endwhile	
		    let l:title=strpart(l:title,0,l:i)
		    call extend(l:toc, { l:tline : [ l:section, l:ind{l:section}, l:title, l:star] }) 
		    " extend t:labels
		    let l:lname=matchstr(l:line,'\\label\s*{.*','')
		    let l:start=stridx(l:lname,'{')+1
		    let l:lname=strpart(l:lname,l:start)
		    let l:end=stridx(l:lname,'}')
		    let l:lname=strpart(l:lname,0,l:end)
		    let b:lname=l:lname
		    if	l:lname != ''
			" if there was no t:labels for a:filename make an entry in
			" t:labels
			if !has_key(t:labels,a:filename)
			    let t:labels[a:filename] = {}
			endif
			call extend(t:labels[a:filename],{ l:tline : l:lname },"force")
		    endif
		endif
	    endif
	endfor
    endfor
    if exists("t:toc")
	call extend(t:toc, { a:filename : l:toc },"force")
    else
	let t:toc={ a:filename : l:toc }
    endif
    return t:toc
endfunction
let t:texcompiler=b:texcompiler
"--------------------- Make a List of Buffers ----
if !exists("t:buflist")
    let t:buflist=[]
endif
function! s:buflist()
    if bufname("") =~ ".tex$"
	call add(t:buflist,fnamemodify(bufname(""),":p"))
    endif
endfunction
call s:buflist()
"---------------------- Show TOC -----------------
" Comments: this do not works when a buffer was deleted!  TOC calls
" s:generatelabels and this is not compatible yet. The function TOC takes time,
" it could be split into two functions show part and update part.

function! s:showtoc(toc)
    " this is a dictionary of line numbers where a new file begins.
    let l:cline=line(".")
"     " Open new window or jump to the existing one.
"     " Remember the place from which we are coming:
"     let t:bufname=bufname("")
"     let t:winnr=winnr()	 these are already set by TOC()
    let l:bname="__ToC__"
    let l:tocwinnr=bufwinnr("^" . l:bname . "$") 
"     echomsg "DEBUG a " . l:tocwinnr
    if l:tocwinnr != -1
	" Jump to the existing window.
	    exe l:tocwinnr . " wincmd w"
	    silent exe "%delete"
    else
	" Open new window if its width is defined (if it is not the code below
	" will put toc in the current buffer so it is better to return.
	if !exists("t:toc_window_width")
	    echoerr "t:toc_window_width not set"
	    return
	endif
	let l:openbuffer=t:toc_window_width . "vnew +setl\\ wiw=15\\ buftype=nofile\\ filetype=toc_atp\\ nowrap __ToC__"
	exe l:openbuffer
	" We are setting the address from which we have come.
	call s:setwindow()
    endif
"     let t:tocwinnr=bufwinnr("^" . t:tocbufname . "$")
"     echomsg "DEBUG T " . t:tocwinnr . " tocbufname " . t:tocbufname
    setlocal tabstop=4
    let l:number=1
    " this is the line number in toc.
    " l:number is a line number relative to the file listed in toc.
    " the current line number is l:linenumber+l:number
    " there are two loops: one over l:linenumber and the second over l:number.
    let l:numberdict={}
    " this variable will be used to set the cursor position in ToC.
    for l:openfile in keys(a:toc)
	call extend(l:numberdict,{ l:openfile : l:number })
	let l:chapon=0
	let l:chnr=0
	let l:secnr=0
	let l:ssecnr=0
	let l:sssecnr=0
	let l:path=fnamemodify(bufname(""),":p:h")
	for l:line in keys(a:toc[l:openfile])
	    if a:toc[l:openfile][l:line][0] == 'chapter'
		let l:chapon=1
		break
	    endif
	endfor
	" TODO: do I use this code?
" 	for l:sections in keys(g:sections)
" 	    let l:nr{l:sections}=""
" 	endfor
	let l:sorted=sort(keys(a:toc[l:openfile]),"s:comparelist")
	let l:len=len(l:sorted)
	call setline(l:number,fnamemodify(l:openfile,":t") . " (" . fnamemodify(l:openfile,":p:h") . ")")
	let l:number+=1
	for l:line in l:sorted
	    let l:lineidx=index(l:sorted,l:line)
" 	    echomsg "line idx  " l:lineidx
	    let l:nlineidx=l:lineidx+1
	    if l:nlineidx< len(l:sorted)
		let l:nline=l:sorted[l:nlineidx]
	    else
		let l:nline=line("$")
	    endif
	    let l:lenght=len(l:line) 	
	    if l:lenght == 0
		let l:showline="     "
	    elseif l:lenght == 1
		let l:showline="    " . l:line
	    elseif l:lenght == 2
		let l:showline="   " . l:line
	    elseif l:lenght == 3
		let l:showline="  " . l:line
	    elseif l:lenght == 4
		let l:showline=" " . l:line
	    elseif l:lenght>=5
		let l:showline=l:line
	    endif
	    " Print ToC lines.
	    if a:toc[l:openfile][l:line][0] == 'abstract'
		call setline(l:number, l:showline . "\t" . "  " . "Abstract" )
	    elseif a:toc[l:openfile][l:line][0] =~ 'bibliography\|references'
		call setline (l:number, l:showline . "\t" . "  " . a:toc[l:openfile][l:line][2])
	    elseif a:toc[l:openfile][l:line][0] == 'chapter'
		let l:chnr=a:toc[l:openfile][l:line][1]
		let l:nr=l:chnr
		if a:toc[l:openfile][l:line][3]
		    "if it is stared version" 
		    let l:nr=substitute(l:nr,'.',' ','')
		endif
		call setline (l:number, l:showline . "\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
	    elseif a:toc[l:openfile][l:line][0] == 'section'
		let l:secnr=a:toc[l:openfile][l:line][1]
		if l:chapon
		    let l:nr=l:chnr . "." . l:secnr  
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    call setline (l:number, l:showline . "\t\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		else
		    let l:nr=l:secnr 
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    call setline (l:number, l:showline . "\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		endif
	    elseif a:toc[l:openfile][l:line][0] == 'subsection'
		let l:ssecnr=a:toc[l:openfile][l:line][1]
		if l:chapon
		    let l:nr=l:chnr . "." . l:secnr  . "." . l:ssecnr
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    call setline (l:number, l:showline . "\t\t\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		else
		    let l:nr=l:secnr  . "." . l:ssecnr
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    call setline (l:number, l:showline . "\t\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		endif
	    elseif a:toc[l:openfile][l:line][0] == 'subsubsection'
		let l:sssecnr=a:toc[l:openfile][l:line][1]
		if l:chapon
		    let l:nr=l:chnr . "." . l:secnr . "." . l:sssecnr  
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    call setline(l:number, a:toc[l:openfile][l:line][0] . "\t\t\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		else
		    let l:nr=l:secnr  . "." . l:ssecnr . "." . l:sssecnr
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    call setline (l:number, l:showline . "\t\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		endif
	    else
		let l:nr=""
	    endif
    " 	echo l:line . " " . a:toc[l:openfile][l:line][0] . " " . a:toc[l:openfile][l:line][1] . " " . a:toc[l:openfile][l:line][2]
	    let l:number+=1
	endfor
    endfor
	" set the cursor position on the correct line number.
	" first get the line number of the begging of the ToC of t:bufname
	" (current buffer)
	let t:numberdict=l:numberdict	"DEBUG
	let l:number=l:numberdict[fnamemodify(t:bufname,":p")]
	let l:sorted=sort(keys(a:toc[fnamemodify(t:bufname,":p")]),"s:comparelist")
	let t:sorted=l:sorted
	for l:line in l:sorted
	    if l:cline>=l:line
		let l:number+=1
" 		call setpos('.',[bufnr(""),l:number+1,1,0])
" 	    elseif l:number == 1 && l:cline<l:line
" 		call setpos('.',[bufnr(""),l:number+1,1,0])
	    endif
" 	    let l:number+=1
	endfor
	call setpos('.',[bufnr(""),l:number,1,0])
"     call setpos('.',[l:bnumber,1,1,0])
endfunction
"------------------- TOC ---------------------------------------------
if !exists("*TOC")
function! TOC()
    if b:texcompiler !~ 'latex'    
	echoerr "This function works only for latex documents."
	return
    endif
    let t:bufname=bufname("")
    " for each buffer in t:buflist (set by s:buflist)
    for l:buffer in t:buflist 
	    let t:toc=s:maketoc(l:buffer)
    endfor
    call s:showtoc(t:toc)
endfunction
endif
"------------------- Current TOC -------------------------------------
function! CTOC()
    if t:texcompiler !~ 'latex'    
	echoerr "This function works only for latex documents."
	return
    endif
    let t:bufname=bufname("")
    let t:toc=s:maketoc(t:bufname)
    let l:cline=line('.')
    let l:sorted=sort(keys(t:toc[t:bufname]),"s:comparelist")
    let l:x=0
    while l:x<len(l:sorted) && l:sorted[l:x]<=l:cline
       let l:x+=1 
    endwhile
    if l:x>=1
	let l:oline=t:toc[t:bufname][l:sorted[l:x-1]][2]
    else
	let l:oline="Preambule"
    endif
    return l:oline
endfunction
"--------- LABELS --------------------------------------------------------
function! s:generatelabels(filename)
    let s:labels={}
    let l:bufname=fnamemodify(a:filename,":t")
    " getbufline reads onlu loaded buffers, unloaded can be read from file.
    if bufloaded("^" . l:bufname . "$")
	let l:texfile=getbufline("^" . l:bufname . "$","1","$")
    else
	w
	let l:texfile=readfile(a:filename)
    endif
"     echomsg "DEBUG X        " . fnamemodify(a:filename,":t")
    let l:true=1
    let l:i=0
    " remove the bart before \begin{document}
    while l:true == 1
	if l:texfile[0] =~ '\\begin\s*{document}'
		let l:true=0
	endif
	call remove(l:texfile,0)
	let l:i+=1
    endwhile
    let l:bline=l:i
    let l:i=0
    while l:i < len(l:texfile)
	if l:texfile[l:i] =~ '\\label\s*{'
	    let l:lname=matchstr(l:texfile[l:i],'\\label\s*{.*','')
	    let l:start=stridx(l:lname,'{')+1
	    let l:lname=strpart(l:lname,l:start)
	    let l:end=stridx(l:lname,'}')
	    let l:lname=strpart(l:lname,0,l:end)
	    let b:lname=l:lname
    "This can be extended to have also the whole environmet which
    "could be shown.
	    call extend(s:labels,{ l:i+l:bline+1 : l:lname })
	endif
	let l:i+=1 
    endwhile
    if exists("t:labels")
	call extend(t:labels,{ a:filename : s:labels },"force")
    else
	let t:labels={ a:filename : s:labels }
    endif
    return t:labels
endfunction

function! s:showlabels(labels)
    " the argument a:labels=t:labels[bufname("")] !
    let l:cline=line(".")
    let l:lines=sort(keys(a:labels),"s:comparelist")
    " Open new window or jump to the existing one.
    let l:bufname=bufname("")
    let l:bufpath=fnamemodify(bufname(""),":p:h")
    let l:bname="__Labels__"
    let l:labelswinnr=bufwinnr("^" . l:bname . "$")
"     let t:bufnr=bufnr("")				" CHECK
    let t:labelswinnr=winnr()
    let t:labelsbufnr=bufnr("^" . l:bname . "$") 
    let l:labelswinnr=bufwinnr(t:labelsbufnr)
    if l:labelswinnr != -1
	" Jump to the existing window.
	exe l:labelswinnr . " wincmd w"
	if l:labelswinnr != t:labelswinnr
	    silent exe "%delete"
	else
	    echoerr "ATP error in function s:showtoc, TOC/LABEL buffer 
		    \ and the tex file buffer agree."
	    return
	endif
   else
"     if buflisted("LABELS") != 0
" 	 exe "bdelete! " . l:bname
"     endif
"     if exists("t:labelsbufnr")
" 	let l:labelswinnr=bufwinnr(t:labelsbufnr)
"     	exe l:labelswinnr . " wincmd w"
" 	if t:labelsbufnr != t:bufnr
" 	    silent exe "%delete"
" 	else
" 	    echoerr "ATP error in function s:showtoc, TOC/LABEL buffer 
" 			\ and the tex file buffer agree."
" 	    return
" 	endif
"     else
	" Open new window if its width is defined (if it is not the code below
	" will put lab:cels in the current buffer so it is better to return.
	if !exists("t:labels_window_width")
	    echoerr "t:labels_window_width not set"
	    return
	endif
	let l:openbuffer=t:labels_window_width . "vnew +setl\\ buftype=nofile\\ filetype=toc_atp\\ syntax=labels_atp __Labels__"
	exe l:openbuffer
	call s:setwindow()
	let t:labelsbufnr=bufnr("")
    endif
    call setline(1,l:bufname . " (" . l:bufpath . ")")
    let l:ln=2
    for l:line in l:lines
	call setline(l:ln, l:line . "\t" . a:labels[l:line]) 
	let l:ln+=1
    endfor
    " set the cursor position on the correct line number.
    let l:number=1
    for l:line in l:lines
    if l:cline>=l:line
	call setpos('.',[bufnr(bufname('%')),l:number,1,0])
    elseif l:number == 1 && l:cline<l:line
	call setpos('.',[bufnr(bufname('%')),l:number,1,0])
    endif
    let l:number+=1
    endfor
endfunction
" -------------------- Labels -------------------
if !exists("*Labels")
function! Labels()
    let t:labels=s:generatelabels(fnamemodify(bufname(""),":p"))
    let t:bufname=fnamemodify(bufname(""),":p")
    call s:showlabels(t:labels[t:bufname])
endfunction
endif
" ----------------- ReadInputFiles ---------------
if !exists("*FindInputFiles") 
function! FindInputFiles(...)    

    if a:0==0
	let l:bufname=bufname("%")
    else
	let l:bufname=a:1
    endif

    let l:dir=fnamemodify(l:bufname,":p:h")
    let l:texfile=readfile(fnamemodify(l:bufname,":p"))
    let s:i=0
    let l:inputlines=[]
    for l:line in l:texfile
	if l:line =~ "\\\\\\(input\\|include\\|includeonly\\)\\s" && l:line !~ "^\s*%"
	    "add the line but cut it before first '%', thus we should get the
	    "file name.
	    let l:col=stridx(l:line,"%")
	    if l:col != -1
		let l:line=strpart(l:line,0,l:col)
	    endif
	    let l:inputlines=add(l:inputlines,l:line) 
" 	    echomsg "DEBUG inputline " l:line
	endif
    endfor
    let b:inputfiles=[]
    for l:line in l:inputlines
	    let l:inputfile=substitute(l:line,'\\\%(input\|include\|includeonly\)\s\+\(.*\)','\1','')
	    call add(b:inputfiles,l:inputfile)
" 	    echomsg "DEBUG inputfile " l:inputfile
    endfor
    if len(b:inputfiles) > 0 
	echohl WarningMsg | echomsg "Found input files:" 
    else
	echohl WarningMsg | echomsg "No input files found." | echohl None
	return []
    endif
    echohl texInput
    let l:nr=1
    for l:inputfile in b:inputfiles
	" before we echo the filename, we clear it from \"
	echomsg l:nr . ". " . substitute(l:inputfile,'^\s*\"\|\"\s*$','','g') 
	let l:nr+=1
    endfor
    echohl None
    return b:inputfiles
endfunction
endif

if !exists("*EditInputFile")
function! EditInputFile(...)

    if a:0==0
	let l:bufname=bufname("%")
    else
	let l:bufname=a:1
    endif

    let l:dir=fnamemodify(l:bufname,":p:h")

    let l:inputfiles=FindInputFiles(l:bufname)
    if ! len(l:inputfiles) > 0
	return 
    endif

    let l:which=input("Which file to edit? Press <Enter> for none ")

    if l:which == ""
	return
    else
	let l:which-=1
    endif

    let l:ifile=l:inputfiles[l:which]

    "g:texmf should end with a '/'
    if g:texmf !~ "\/$"
	let g:texmf=g:texmf . "/"
    endif

    
    " remove all '"' from the line (latex do not supports file names with '"')
    " this make the function work with lines like: '\\input "file name with spaces.tex"'
    let l:ifile=substitute(l:ifile,'^\s*\"\|\"\s*$','','g')
    " add .tex extension if it was not present
    let l:ifile=substitute(l:ifile,'\(.tex\)\?\s*$','.tex','')
    if filereadable(l:dir . l:ifile) 
	exe "edit " . fnameescape(b:outdir . l:ifile)
	let b:autex=0
    else
	let l:ifile=findfile(l:ifile,g:texmf . '**')
	exe "edit " . fnameescape(l:ifile)
	let b:autex=0
    endif
endfunction
endif
" TODO if the file was not found ask to make one.
"--------- MAPPINGS -------------------------------------------------------
" Add mappings, unless the user didn't want this.
if !exists("no_plugin_maps") && !exists("no_atp_maps")

map  <buffer> <LocalLeader>v		:call ViewOutput() <CR><CR>
map  <buffer> <F3>        			:call ViewOutput() <CR><CR>
imap <buffer> <F3> <Esc> 			:call ViewOutput() <CR><CR>
map  <buffer> <LocalLeader>g 		:call Getpid()<CR>
map  <buffer> T				:TOC<CR>
map  <buffer> <LocalLeader>L		:Labels<CR>
map  <buffer> <LocalLeader>UL		:call UpdateLabels(bufname('%'))<CR>
map  <buffer> <LocalLeader>l 		:TEX<CR>	
imap <buffer> <LocalLeader>l<Left><ESC> :TEX<CR>a
map  <buffer> <F5> 			:call VTEX() <CR>	
map  <buffer> <S-F5> 			:call ToggleAuTeX()<CR>
imap <buffer> <F5> <Left><ESC> 		:call VTEX() <CR>a
map  <buffer> <LocalLeader>sb		:call SimpleBibtex()<CR>
map  <buffer> <LocalLeader>b		:call Bibtex()<CR>
map  <buffer> <F6>d 			:call Delete() <CR>
imap <buffer> <silent> <F6>l 		:call OpenLog() <CR>
map  <buffer> <silent> <F6>l 		:call OpenLog() <CR>
map  <buffer> <LocalLeader>e 		:cf<CR> 
map  <buffer> <F6>w 			:call TexLog("-w")<CR>
imap <buffer> <F6>w 			:call TexLog("-w")<CR>
map  <buffer> <F6>r 			:call TexLog("-r")<CR>
imap <buffer> <F6>r 			:call TexLog("-r")<CR>
map  <buffer> <F6>f 			:call TexLog("-f")<CR>
imap <buffer> <F6>f 			:call TexLog("-f")<CR>
map  <buffer> <F6>g 			:call Pdffonts()<CR>
map  <buffer> <F1> 	   			:!clear;texdoc -m 
imap <buffer> <F1> <Esc> 			:!clear;texdoc -m  
map  <buffer> <LocalLeader>p 		:call Print(g:printeroptions)<CR>

" FONT MAPPINGS
imap <buffer> ##rm \textrm{}<Left>
imap <buffer> ##it \textit{}<Left>
imap <buffer> ##sl \textsl{}<Left>
imap <buffer> ##sf \textsf{}<Left>
imap <buffer> ##bf \textbf{}<Left>
	
imap <buffer> ##mit \mathit{}<Left>
imap <buffer> ##mrm \mathrm{}<Left>
imap <buffer> ##msf \mathsf{}<Left>
imap <buffer> ##mbf \mathbf{}<Left>

" GREEK LETTERS
imap <buffer> #a \alpha
imap <buffer> #b \beta
imap <buffer> #c \chi
imap <buffer> #d \delta
imap <buffer> #e \epsilon
imap <buffer> #f \phi
imap <buffer> #y \psi
imap <buffer> #g \gamma
imap <buffer> #h \eta
imap <buffer> #k \kappa
imap <buffer> #l \lambda
imap <buffer> #i \iota
imap <buffer> #m \mu
imap <buffer> #n \nu
imap <buffer> #p \pi
imap <buffer> #o \theta
imap <buffer> #r \rho
imap <buffer> #s \sigma
imap <buffer> #t \tau
imap <buffer> #u \upsilon
imap <buffer> #vs \varsigma
imap <buffer> #vo \vartheta
imap <buffer> #w \omega
imap <buffer> #x \xi
imap <buffer> #z \zeta

imap <buffer> #D \Delta
imap <buffer> #Y \Psi
imap <buffer> #F \Phi
imap <buffer> #G \Gamma
imap <buffer> #L \Lambda
imap <buffer> #M \Mu
imap <buffer> #N \Nu
imap <buffer> #P \Pi
imap <buffer> #O \Theta
imap <buffer> #S \Sigma
imap <buffer> #T \Tau
imap <buffer> #U \Upsilon
imap <buffer> #V \Varsigma
imap <buffer> #W \Omega

imap <buffer> [b \begin{}<Left>
imap <buffer> [e \end{}<Left>
imap [s \begin{}<CR>\end{}<Up><Right>

imap <buffer> ]c \begin{center}<Cr>\end{center}<Esc>O
imap <buffer> [c \begin{corollary}<Cr>\end{corollary}<Esc>O
imap <buffer> [d \begin{definition}<Cr>\end{definition}<Esc>O
imap <buffer> ]e \begin{enumerate}<Cr>\end{enumerate}<Esc>O
imap <buffer> [q \begin{equation}<Cr>\end{equation}<Esc>O
imap <buffer> [a \begin{align}<Cr>\end{align}<Esc>O
imap <buffer> [x \begin{example}<Cr>\end{example}<Esc>O
imap <buffer> ]q \begin{equation}<Cr>\end{equation}<Esc>O
imap <buffer> ]l \begin{flushleft}<Cr>\end{flushleft}<Esc>O
imap <buffer> ]r \begin{flushright}<Cr>\end{flushright}<Esc>O
imap <buffer> [i \item  
imap <buffer> ]i \begin{itemize}<Cr>\end{itemize}<Esc>O
imap <buffer> [l \begin{lemma}<Cr>\end{lemma}<Esc>O
imap <buffer> [n \begin{note}<Cr>\end{note}<Esc>O
imap <buffer> [o \begin{observation}<Cr>\end{observation}<Esc>O
imap <buffer> ]p \begin{proof}<Cr>\end{proof}<Esc>O
imap <buffer> [p \begin{proposition}<Cr>\end{proposition}<Esc>O
imap <buffer> [r \begin{remark}<Cr>\end{remark}<Esc>O
imap <buffer> [t \begin{theorem}<Cr>\end{theorem}<Esc>O
imap <buffer> 	 ]t \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>

" imap {c \begin{corollary*}<Cr>\end{corollary*}<Esc>O
" imap {d \begin{definition*}<Cr>\end{definition*}<Esc>O
" imap {x \begin{example*}\normalfont<Cr>\end{example*}<Esc>O
" imap {l \begin{lemma*}<Cr>\end{lemma*}<Esc>O
" imap {n \begin{note*}<Cr>\end{note*}<Esc>O
" imap {o \begin{observation*}<Cr>\end{observation*}<Esc>O
" imap {p \begin{proposition*}<Cr>\end{proposition*}<Esc>O
" imap {r \begin{remark*}<Cr>\end{remark*}<Esc>O
" imap {t \begin{theorem*}<Cr>\end{theorem*}<Esc>O

imap <buffer> __ _{}<Left>
imap <buffer> ^^ ^{}<Left>
imap <buffer> [m \[\]<Left><Left>
endif

" This is an additional syntax group for enironment provided by the TIKZ
" package, a very powerful tool to make beautiful diagrams, and all sort of
" pictures in latex.
syn match texTikzCoord '\(|\)\?([A-Za-z0-9]\{1,3})\(|\)\?\|\(|\)\?(\d\d)|\(|\)\?'

" COMMANDS
command! -buffer SetErrorFile :call SetErrorFile()
command! -buffer -nargs=? ShowOptions 	:call ShowOptions(<f-args>)
command! -buffer GPID 	:call Getpid()
command! -buffer CXPDF 	:echo s:xpdfpid()
command! -buffer -nargs=? -count=1 TEX  :call TEX(<count>,<f-args>)
command! -buffer -nargs=? -count=1 VTEX	:call  VTEX(<count>,<f-args>)
command! -buffer SBibtex :call SimpleBibtex()
command! -buffer -nargs=? Bibtex 	:call Bibtex(<f-args>)
command! -buffer -nargs=1 -complete=buffer FindBibFiles echo FindBibFiles(<f-args>)
command! -buffer -nargs=* BibSearch	:call BibSearch(<f-args>)
command! -buffer TOC 	:call TOC()
command! -buffer Labels	:call Labels() 
command! -buffer SetOutDir :call s:setoutdir(1)
" TODO to ToC:
command! -buffer -nargs=? -complete=buffer FindInputFiles :call FindInputFiles(<f-args>)
" command! -buffer EditInputFile :call EditInputFile(bufname("%"))
command! -buffer -nargs=? -complete=buffer EditInputFile :call EditInputFile(<f-args>)
