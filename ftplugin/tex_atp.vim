" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 Jan 25
" URL:		
"
" GetLatestVimScripts: 2945 2 :AutoInstall: tex_atp.vim
"
" TODO Check against lilypond 
" NOTES
" s:tmpfile=temporary file value of tempname()
" s:texfile=readfile(bunfname("%")

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

setl keywordprg=texdoc\ -m

function! s:setoutdir()
if g:askfortheoutdir == 1 
    let b:outdir=input("Where to put output? ")
elseif get(getbufvar(bufname("%"),""),"outdir","optionnotset") == "optionnotset" && g:askfortheoutdir != 1 
     let b:outdir=fnameescape(fnamemodify(resolve(expand("%:p")),":h")) . "/"
"      	echomsg "DEBUG setting b:outdir to " . b:outdir
     echoh WarningMsg | echomsg "Output Directory "b:outdir | echoh None
endif	
endfunction

let s:optionsDict= { "texoptions" : "", "reloadonerror" : "0", "openviewer" : "1", "autex" : "1", "Viewer" : "xpdf", "XpdfOptions" : "", "XpdfServer" : fnamemodify(expand("%"),":t"), "outdir" : fnameescape(fnamemodify(resolve(expand("%:p")),":h")) . "/", "askfortheoutdir" : "0", "texcompiler" : "pdflatex"}
let s:ask={ "ask" : "0" }
let g:rmcommand="perltrash"
let g:texextensions=["aux", "log", "bbl", "blg", "spl", "snm", "nav", "thm", "brf", "out", "toc", "mpx", "idx", "maf", "blg", "glo", "mtc[0-9]", "mtc1[0-9]"]
let g:keep=["log","aux","toc","bbl"]
" let b:texinteraction='errorstopmode'
let g:printingoptions=''
let s:COM=''
" let b:outdir=substitute(fnameescape(resolve(expand("%:p"))),resolve(expand("%:r")) . "." . resolve(expand("%:e")) . "$","","")
" let b:outdir=substitute(fnameescape(resolve(expand("%:p"))),resolve(expand("%:r")) . "." . resolve(expand("%:e")) . "$","","")
function! s:setoptions()
let s:optionsKeys=keys(s:optionsDict)
let s:optionsinuseDict=getbufvar(bufname("%"),"")
for l:key in s:optionsKeys
    if get(s:optionsinuseDict,l:key,"optionnotset") == "optionnotset" && l:key != "outdir" && l:key != "askfortheoutdir"
"  	    echomsg "Setting " . l:key . "=" . s:optionsDict[l:key]
	call setbufvar(bufname("%"),l:key,s:optionsDict[l:key])
    elseif get(s:optionsinuseDict,l:key,"optionnotset") == "optionnotset" && l:key == "outdir"
	call s:setoutdir()
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
    echomsg ""
    highlight Chapter
    highlight Section
    highlight Subsection
    highlight Subsubsection
    highlight CurrentSection
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
    highlight Chapter
    highlight Section
    highlight Subsection
    highlight CurrentSection
    highlight Subsubsection
endif
endfunction
endif
command -buffer -nargs=? ShowOptions :call ShowOptions(<f-args>)

if !exists("*StatusR")
function! StatusR()
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
endif
let &statusline='%<%f %(%h%m%r %)%#ErrorMsg#%{StatusL()}%#None#%=%#Title#%{Tlist_Get_Tagname_By_Line_EM()}%* %{StatusR()}  %-9.15(%l,%c%V%)%P'
let b:texruns=0
let b:log=0	
let b:ftype=getftype(expand("%:p"))	
let s:texinteraction="nonstopmode"
let &l:errorfile=b:outdir . fnameescape(fnamemodify(expand("%"),":t:r")) . ".log"
setlocal errorformat=%E!\ LaTeX\ %trror:\ %m,
	\%E!\ %m,
	\%Cl.%l\ %m,
	\%+C\ \ %m.,
	\%+C%.%#-%.%#,
	\%+C%.%#[]%.%#,
	\%+C[]%.%#,
	\%+C%.%#%[{}\\]%.%#,
	\%+C<%.%#>%.%#,
	\%C\ \ %m,
	\%-GSee\ the\ LaTeX%m,
	\%-GType\ \ H\ <return>%m,
	\%-G\ ...%.%#,
	\%-G%.%#\ (C)\ %.%#,
	\%-G(see\ the\ transcript%.%#),
	\%-G\\s%#,
	\%+O(%*[^()])%r,
	\%+O%*[^()](%*[^()])%r,
	\%+P(%f%r,
	\%+P\ %\\=(%f%r,
	\%+P%*[^()](%f%r,
	\%+P[%\\d%[^()]%#(%f%r,
	\%+Q)%r,
	\%+Q%*[^()])%r,
	\%+Q[%\\d%*[^()])%r,
let s:lockef=1
au BufRead $l:errorfile setlocal autoread 
"--------- FUNCTIONs -----------------------------------------------------
"	
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
if !exists("*s:getpid")
function! s:getpid()
	let s:command="ps -ef | grep -v " . $SHELL  . " | grep " . b:texcompiler . " | grep -v grep | grep " . fnameescape(expand("%")) . " | awk '{print $2}'"
	let s:var=substitute(system(s:command),'\D',' ','')
	return s:var
endfunction
endif
if !exists("*Getpid")
function! Getpid()
	let s:var=s:getpid()
	if s:var != ""
		echomsg b:texcompiler"pid"s:var 
	else
		echomsg b:texcompiler"is not running"
	endif
endfunction
endif
command! -buffer GPID call Getpid()

if !exists("*s:xpdfpid")
function! s:xpdfpid() 
    let s:checkxpdf="ps -ef | grep -v grep | grep '-remote '" . shellescape(b:XpdfServer) . " | awk '{print $2}'"
    return substitute(system(s:checkxpdf),'\D','','')
endfunction
endif
command! -buffer CXPDF echo s:xpdfpid()
"-------------------------------------------------------------------------
if !exists("*s:compare")
function! s:compare(file,buffer)
    let l:buffer=getbufline(bufname("%"),"1","$")
    return a:file !=# l:buffer
endfunction
endif
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
	echomsg ""
	echohl None
" 	sleep 1
    endif
	" First argument name is a name usually it is always set 
	let s:tmpfile=tempname()
"  		echomsg "DEBUG tempfile="s:tmpfile 
	let s:dir=fnamemodify(s:tmpfile,":h")
	let s:job=fnamemodify(s:tmpfile,":t")
	if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex"
	    let l:ext = ".pdf"
	else
	    let l:ext = ".dvi"	
	endif
	let l:outfile=b:outdir . (fnamemodify(expand("%"),":t:r")) . l:ext
	let l:outaux=b:outdir . (fnamemodify(expand("%"),":t:r")) . ".aux"
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
" 				echomsg "DEBUG xpdfreload="s:xpdfreload
" 	IF OPENINIG NON EXISTENT OUTPUT FILE
"	only xpdf needs to be run before (above we are going to reload it!)
	if a:start == 1 && b:Viewer == "xpdf"
	    let s:start = b:Viewer . " -remote " . shellescape(b:XpdfServer) . " & "
	else
	    let s:start = ""	
	endif
"	SET THE COMMAND 
	let s:comp=b:texcompiler . " -interaction " . s:texinteraction . " -output-directory " . s:dir . " -jobname " . s:job . " " . shellescape(expand("%"))
	let s:vcomp=b:texcompiler . " -interaction errorstopmode -output-directory " . s:dir . " -jobname " . s:job . " " . shellescape(expand("%"))
	if a:verbose == 0 
	    let s:texcomp=s:comp
	elseif a:runs >= 1 && a:verbose != 0
	    let s:texcomp=s:comp
	elseif a:runs == 1 && a:verbose != 0
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
"  		echomsg "DEBUG runs s:texcomp="s:texcomp
	endif
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
" 		echomsg "DEBUG 2 copycmd"s:copycmd
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
"  	    echomsg "DEBUG compile s:command="s:command
	    return system(s:command)
	else
	    let s:command="!clear;" . s:texcomp . " ; " . s:cpoutfile . " ; " . s:copy
	    let b:texcommand=s:command
" 	    echomsg "DEBUG verbose compile s:command=" . s:command
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
    echomsg b:texcompiler . " will run " . a:1 . " times."
    call s:compiler(0,0,a:1,0,"COM")
elseif a:0 == 0
    call s:compiler(0,0,1,0,"COM")
endif
endfunction
endif
command! -buffer -nargs=? -count=1 TEX   :call TEX(<count>,<f-args>)
" command! -buffer -count=1 TEX	:call TEX(<count>)		 
if !exists("*ToggleAuTeX")
function! ToggleAuTeX()
  if b:autex != 1
    let b:autex=1	
    echo "automatic tex processing in ON"
  else
    let b:autex=0
    echo "automatic tex processing in OFF"
endif
endfunction
endif
if !exists("*VTEX")
function! VTEX(...)
    let s:name=tempname()
if a:0 >= 1
    echomsg b:texcompiler . " will run " . a:1 . " times."
    sleep 1
    call s:compiler(0,0,a:1,1,"COM")
else
    call s:compiler(0,0,1,1,"COM")
endif
endfunction
endif
command! -buffer -nargs=? -count=1 VTEX	:call  VTEX(<count>,<f-args>)
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
command! -buffer SBibtex :call SimpleBibtex()

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
command! -buffer -nargs=? Bibtex :call Bibtex(<f-args>)

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
		let l:rm=g:rmcommand . " " . b:outdir . "*." . l:ext . " 2>/dev/null && echo Removed ./*" . l:ext . " files"
	    endif
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
    let s:texfile=readfile(a:bufname)
    let s:i=0
    let s:bibline=[]
    for line in s:texfile
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
command -buffer FindBibFiles echo FindBibFiles(bufname('%'))
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
    for l:key in keys(b:bibentryline)
	let l:f=l:key . ".bib"
"s:bibdict[l:f])	CHECK EVERY STARTING LINE (we are going to read bibfile from starting
"	line till the last matching } 
 	let s:bibd={}
 	for l:linenr in b:bibentryline[l:key]
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
	    let l:i=s:count(get(l:bibdict[l:key],l:linenr-1),"{")-s:count(get(l:bibdict[l:key],l:linenr-1),"}")
	    let l:j=s:count(get(l:bibdict[l:key],l:linenr-1),"(")-s:count(get(l:bibdict[l:key],l:linenr-1),")") 
	    let s:lbibd={}
	    let s:lbibd["KEY"]=get(l:bibdict[l:key],l:linenr-1)
	    let l:x=1
" we go from the first line of bibentry, i.e. @article{ or @article(, until the { and (
" will close. In each line we count brackets.	    
            while l:i>0	|| l:j>0
		let l:tlnr=l:x+l:linenr
		let l:pos=s:count(get(l:bibdict[l:key],l:tlnr-1),"{")
		let l:neg=s:count(get(l:bibdict[l:key],l:tlnr-1),"}")
		let l:i+=l:pos-l:neg
		let l:pos=s:count(get(l:bibdict[l:key],l:tlnr-1),"(")
		let l:neg=s:count(get(l:bibdict[l:key],l:tlnr-1),")")
		let l:j+=l:pos-l:neg
		let l:lkey=tolower(matchstr(strpart(get(l:bibdict[l:key],l:tlnr-1),0,stridx(get(l:bibdict[l:key],l:tlnr-1),"=")),'\<\w*\>'))
		if l:lkey != ""
		    let s:lbibd[l:lkey]=get(l:bibdict[l:key],l:tlnr-1)
			let l:y=0
" IF THE LINE IS SPLIT ATTACH NEXT LINE									
			let l:lline=substitute(get(l:bibdict[l:key],l:tlnr+l:y-1),'\\"\|\\{\|\\}\|\\(\|\\)','','g')
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
				let l:pos=s:count(get(l:bibdict[l:key],l:tlnr+l:y),"{")
				let l:neg=s:count(get(l:bibdict[l:key],l:tlnr+l:y),"}")
				let l:m+=l:pos-l:neg
				let l:pos=s:count(get(l:bibdict[l:key],l:tlnr+l:y),"(")
				let l:neg=s:count(get(l:bibdict[l:key],l:tlnr+l:y),")")
				let l:n+=l:pos-l:neg
				let l:o+=s:count(get(l:bibdict[l:key],l:tlnr+l:y),"\"")
" Let us append the next line: 
				let s:lbibd[l:lkey]=substitute(s:lbibd[l:lkey],'\s*$','','') . " ". substitute(get(l:bibdict[l:key],l:tlnr+l:y),'^\s*','','')
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
	let l:bibresults[l:key]=s:bibd
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
		\ 'o' : ['organization', 'organization '], 'u' : ['url','url          '],
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
let g:vertical=1
function! s:showresults(bibresults,flags,pattern)
 
" FLAGS:
" All - all flags	
" L - last flag
" a - author
" e - editor
" t - title
" b - booktitle
" j - journal
" s -series
" y - year
" n - number
" v - volume
" p - pages
" P - publisher
" N - note
" S - school
" h - howpublished
" o - organization

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
				let l:bufnr=bufnr(a:pattern)
				if bufexists(bufname(a:pattern))
				    let l:bdelete=l:bufnr . "bdelete"
				    exe l:bdelete
				endif
				unlet l:bufnr
 				let l:openbuffer=" +set\\ buftype=nofile\\ filetype=bibsearch " . fnameescape(a:pattern)
				if g:vertical ==1
				    let l:openbuffer="vnew" . l:openbuffer
				    let l:skip=""
				else
				    let l:openbuffer="vnew" . l:openbuffer
				    let l:skip="       "
				endif
				exe l:openbuffer
" 				call setline(l:ln,"@Comment{BibSearch 2.0 flags " . join(l:flagslist,'') . join(l:kwflagslist,'') . "}")
" 				let l:ln+=1
" 				call setline(l:ln,"@Comment{flags " . join(l:flagslist,'') . join(l:kwflagslist,'') . "}")
" 				let l:ln+=1

    for l:bibfile in keys(a:bibresults)
	if a:bibresults[l:bibfile] != {}
" 	    echohl BibResultsFileNames | echomsg "Found in " . l:bibfile | echohl None
	    call setline(l:ln, "Found in " . l:bibfile )	
	    let l:ln+=1
	endif
	for l:linenr in copy(sort(keys(a:bibresults[l:bibfile]),"s:comparelist"))
" make a dictionary of clear values, which we will fill with found entries. 	    
" the default value if no<keyname>, which after all is matched and not showed
	    let l:values={}	
	    for l:key in s:bibflagslist 
		if l:key == 'key'
		    let l:values=extend(l:values,{'key' : 'nokey'}
		else
		    let l:values=extend(l:values,{ g:bibflagsdict[l:key][0] : 'no' . g:bibflagsdict[l:key][0] })
		endif
	    endfor
	    let b:values=l:values	" DEBUG
" fill l:values with a:bibrsults	    
	    unlet l:key
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
" 		echohl BibResultEntry | echomsg " " . s:z . " line " . l:linenumber . "  " . l:values["key"] 
 					call setline(l:ln,s:z . ". line " . l:linenumber . "  " . l:values["key"])
"  					call setline(l:ln,l:values["key"])
					let l:ln+=1
 					let l:c0=s:count(l:values["key"],'{')-s:count(l:values["key"],'(')
"  					call setline( l:ln,"@Comment{" . s:z . " line " . l:linenumber . "}")
" 					let l:ln+=1

	
		let b:values=l:values
" this goes over the entry flags:
		for l:lflag in l:flagslist
" we check if the entry was present in bib file:
		    if l:values[g:bibflagsdict[l:lflag][0]] != "no" . g:bibflagsdict[l:lflag][0]
			if l:values[g:bibflagsdict[l:lflag][0]] =~ a:pattern
" 			    echohl BibResultsMatch | echomsg "          " . g:bibflagsdict[l:lflag][1] . "   " . s:showvalue(l:values[g:bibflagsdict[l:lflag][0]])
 			    		call setline(l:ln, l:skip . g:bibflagsdict[l:lflag][1] . " =  " . s:showvalue(l:values[g:bibflagsdict[l:lflag][0]]))
					let l:ln+=1
			else
" 			    echohl BibResultsGeneral | echomsg "          " . g:bibflagsdict[l:lflag][1] . "   " . s:showvalue(l:values[g:bibflagsdict[l:lflag][0]])
					call setline(l:ln, l:skip . g:bibflagsdict[l:lflag][1] . " = " . s:showvalue(l:values[g:bibflagsdict[l:lflag][0]]))
					let l:ln+=1
			endif
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
command -buffer -nargs=* BibSearch	:call BibSearch(<f-args>)

"---------- TOC -----------------------------------------------------------
" g:sections, b:toc
let g:sections={
    \	'chapter' 	: [           '^\s*\(\\chapter.*\)',		'\\chapter*'	,'\\chapter.*[\(.*\)].*'],	
    \	'section' 	: [           '^\s*\(\\section.*\)',	'\\section*'	,'\\section.*[\(.*\)].*,'],
    \ 	'subsection' 	: [	   '^\s*\(\\subsection.*\)',	'\\subsection*'	,'\\subsection.*[\(.*\)].*'],
    \	'subsubsection' : [ 	'^\s*\(\\subsubsection.*\)',	'\\subsubsection*'	,'\\subsubsection.*[\(.*\)].*'],
    \	'bibliography' 	: ['^\s*\(\\begin.*{bibliography}.*\|\\bibliography\s*{.*\)'	     ,	'nopattern'		, 'nopattern'],
    \	'abstract' 	: ['^\s*\(\\begin\s*{abstract}.*\|\\abstract\s*{.*\)',	'nopattern'	, 'nopattern']}
" this works only for latex documents.
"----------- Make TOC -----------------------------
" make l:toc a dictionary with keys: line numbers, values 
" [ 'section-name', 'number', 'title']
" where section name is element of keys(g:sections), number is the total
" number, 'title=\1' where \1 is returned by the g:section['key'][0] pattern,
" for now it is just whole line. The number can be skipped, is not used, the
" pattern have to be written so that it returns the title, shorttitle and
" label value or better, writte a function which reads a line character by
" character and finds these values. For now \chapter*,  \section* are counted
" it can be fixed.
function! s:maketoc(bufname)
   let l:toc={}
    let s:texfile=readfile(a:bufname) 
    let l:true=1
    let l:i=0
    " remove the bart before \begin{document}
    while l:true == 1
	if s:texfile[0] =~ '\\begin\s*{document}'
		let l:true=0
	endif
	call remove(s:texfile,0)
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
    " filter s:texfile    
    let s:filtered=filter(deepcopy(s:texfile),'v:val =~ l:filter')
    let b:filtered=s:filtered
    let b:texfile=s:texfile
    for l:line in s:filtered
	for l:section in keys(g:sections)
	    if l:line =~ g:sections[l:section][0] 
		if l:line =~ '^\s*%'
		else
		    let l:title=substitute(l:line,g:sections[l:section][0],'\1','')
		    let l:i=index(s:texfile,l:line)
		    let l:tline=l:i+l:bline+1
		    let l:ind{l:section}+=1
		    call extend(l:toc, { l:tline : [ l:section, l:ind{l:section}, l:title] }) 
		endif
	    endif
	endfor
    endfor
    return l:toc
endfunction
"---------------------- Show TOC -----------------
function! s:showtoc(toc)
    " make a test if the section number must start from chapter number or not
    " (if there are no chapters)
    let l:chapon=0
    for l:line in keys(a:toc)
	if a:toc[l:line][0] == 'chapter'
	    let l:chapon=1
	    break
	endif
    endfor
    let l:cline=line(".")
    let l:chnr=0
    let l:secnr=0
    let l:ssecnr=0
    for l:sections in keys(g:sections)
	let l:nr{l:sections}=""
    endfor
    let l:sorted=sort(keys(a:toc),"s:comparelist")
    let l:len=len(l:sorted)
"     echomsg "LENGHT l:len=" l:len
    for l:line in l:sorted
	let l:lineidx=index(l:sorted,l:line)
" 	echomsg "line idx  " l:lineidx
	let l:nlineidx=l:lineidx+1
	if l:nlineidx< len(l:sorted)
	    let l:nline=l:sorted[l:nlineidx]
	else
	    let l:nline=line("$")
	endif
" 	    echomsg "l:line          " l:line
" 	    echomsg "Current line    " l:cline 
" 	    echomsg "NEXT LINE       " l:nline
	if a:toc[l:line][0] == 'abstract'
	    if l:cline >= l:line && l:cline < l:nline
		echohl CurrentSection
	    else
		if l:chapon
		    echohl Chapter 
		else
		    echohl Section
		endif
	    endif
	echomsg " " . a:toc[l:line][2] | echohl None
	elseif a:toc[l:line][0] =~ 'bibliography\|references'
	    if l:cline >= l:line && l:cline < l:nline
		echohl CurrentSection
	    else
		if l:chapon
		    echohl Chapter 
		else
		    echohl Section
		endif
	    endif
	echomsg " " . a:toc[l:line][2] | echohl None
	elseif a:toc[l:line][0] == 'chapter'
	    let l:chnr+=1
	    let l:secnr=0
	    let l:ssecnr=0
	    let l:sssecnr=0
	    let l:nr=l:chnr
	    if l:cline >= l:line && l:cline < l:nline
		echohl CurrentSection
	    else
		echohl Chapter 
	    endif
	echomsg l:nr . " " . a:toc[l:line][2] | echohl None
	elseif a:toc[l:line][0] == 'section'
	    let l:secnr+=1
	    let l:ssecnr=0
	    let l:sssecnr=0
	    if l:chapon
		let l:nr=l:chnr . "." . l:secnr  
	    else
		let l:nr=l:secnr 
	    endif
	    if l:cline >= l:line && l:cline < l:nline
		echohl CurrentSection
	    else
		echohl Section 
	    endif
	    echomsg "    " .l:nr . " " . a:toc[l:line][2] | echohl None
	elseif a:toc[l:line][0] == 'subsection'
	    let l:ssecnr+=1
	    let l:sssecnr=0
	    if l:chapon
		let l:nr=l:chnr . "." . l:secnr  . "." . l:ssecnr
	    else
		let l:nr=l:secnr  . "." . l:ssecnr
	    endif
	    if l:cline >= l:line && l:cline < l:nline
		echohl CurrentSection
	    else
		echohl Subsection 
	    endif
	    echomsg "        " . l:nr . " " . a:toc[l:line][2] | echohl None
	elseif a:toc[l:line][0] == 'subsection'
	    let l:sssecnr+=1
	    if l:chapon
		let l:nr=l:chnr . "." . l:secnr . "." . l:sssecnr  
	    else
		let l:nr=l:secnr  . "." . l:ssecnr
	    endif
	    if l:cline >= l:line && l:cline < l:nline
		echohl CurrentSection
	    else
		echohl Subsection 
	    endif
	    echomsg "        " .l:nr . " " . a:toc[l:line][2] | echohl None
	else
	    let l:nr=""
	endif
" 	echo l:line . " " . a:toc[l:line][0] . " " . a:toc[l:line][1] . " " . a:toc[l:line][2]
    endfor
endfunction
if !exists("*TOC")
function! TOC()
if b:texcompiler =~ 'latex'    
    let b:toc=s:maketoc(bufname("%"))
    call s:showtoc(b:toc)
else    
    echomsg "This function works only for latex documents."
endif
endfunction
endif
command -buffer TOC :call TOC()
"--------- MAPPINGS -------------------------------------------------------
" Add mappings, unless the user didn't want this.
if !exists("no_plugin_maps") && !exists("no_atp_maps")

noremap  <buffer> <LocalLeader>v		:call ViewOutput() <CR><CR>
noremap  <buffer> <F3>        			:call ViewOutput() <CR><CR>
inoremap <buffer> <F3> <Esc> 			:call ViewOutput() <CR><CR>
noremap  <buffer> <LocalLeader>g 		:call Getpid()<CR>
noremap  <buffer> <LocalLeader>l 		:call TEX() <CR>	
inoremap <buffer> <LocalLeader>l<Left><ESC> :call TEX() <CR>a
noremap  <buffer> <F5> 			:call VTEX() <CR>	
noremap  <buffer> <S-F5> 			:call ToggleAuTeX()<CR>
inoremap <buffer> <F5> <Left><ESC> 		:call VTEX() <CR>a
noremap  <buffer> <LocalLeader>sb		:call SimpleBibtex()<CR>
noremap  <buffer> <LocalLeader>b		:call Bibtex()<CR>
noremap  <buffer> <F6>d 			:call Delete() <CR>
inoremap <buffer> <silent> <F6>l 		:call OpenLog() <CR>
noremap  <buffer> <silent> <F6>l 		:call OpenLog() <CR>
noremap  <buffer> <LocalLeader>e 		:cf<CR> 
noremap  <buffer> <F6>w 			:call TexLog("-w")<CR>
inoremap <buffer> <F6>w 			:call TexLog("-w")<CR>
noremap  <buffer> <F6>r 			:call TexLog("-r")<CR>
inoremap <buffer> <F6>r 			:call TexLog("-r")<CR>
noremap  <buffer> <F6>f 			:call TexLog("-f")<CR>
inoremap <buffer> <F6>f 			:call TexLog("-f")<CR>
noremap  <buffer> <F6>g 			:call Pdffonts()<CR>
noremap  <buffer> <F1> 	   			:!clear;texdoc -m 
inoremap <buffer> <F1> <Esc> 			:!clear;texdoc -m  
noremap  <buffer> <LocalLeader>p 		:call Print(g:printeroptions)<CR>

" FONT COMMANDS
inoremap <buffer> ##rm \textrm{}<Left>
inoremap <buffer> ##it \textit{}<Left>
inoremap <buffer> ##sl \textsl{}<Left>
inoremap <buffer> ##sf \textsf{}<Left>
inoremap <buffer> ##bf \textbf{}<Left>
	
inoremap <buffer> ##mit \mathit{}<Left>
inoremap <buffer> ##mrm \mathrm{}<Left>
inoremap <buffer> ##msf \mathsf{}<Left>
inoremap <buffer> ##mbf \mathbf{}<Left>

" GREEK LETTERS
inoremap <buffer> #a \alpha
inoremap <buffer> #b \beta
inoremap <buffer> #c \chi
inoremap <buffer> #d \delta
inoremap <buffer> #e \epsilon
inoremap <buffer> #f \phi
inoremap <buffer> #y \psi
inoremap <buffer> #g \gamma
inoremap <buffer> #h \eta
inoremap <buffer> #k \kappa
inoremap <buffer> #l \lambda
inoremap <buffer> #i \iota
inoremap <buffer> #m \mu
inoremap <buffer> #n \nu
inoremap <buffer> #p \pi
inoremap <buffer> #o \theta
inoremap <buffer> #r \rho
inoremap <buffer> #s \sigma
inoremap <buffer> #t \tau
inoremap <buffer> #u \upsilon
inoremap <buffer> #vs \varsigma
inoremap <buffer> #vo \vartheta
inoremap <buffer> #w \omega
inoremap <buffer> #x \xi
inoremap <buffer> #z \zeta

inoremap <buffer> #D \Delta
inoremap <buffer> #Y \Psi
inoremap <buffer> #F \Phi
inoremap <buffer> #G \Gamma
inoremap <buffer> #L \Lambda
inoremap <buffer> #M \Mu
inoremap <buffer> #N \Nu
inoremap <buffer> #P \Pi
inoremap <buffer> #O \Theta
inoremap <buffer> #S \Sigma
inoremap <buffer> #T \Tau
inoremap <buffer> #U \Upsilon
inoremap <buffer> #V \Varsigma
inoremap <buffer> #W \Omega

inoremap <buffer> [b \begin{}<Left>
inoremap <buffer> [e \end{}<Left>
inoremap [s \begin{}<CR>\end{}<Up><Right>

inoremap <buffer> ]c \begin{center}<Cr>\end{center}<Esc>O
inoremap <buffer> [c \begin{corollary}<Cr>\end{corollary}<Esc>O
inoremap <buffer> [d \begin{definition}<Cr>\end{definition}<Esc>O
inoremap <buffer> ]e \begin{enumerate}<Cr>\end{enumerate}<Esc>O
inoremap <buffer> [q \begin{equation}<Cr>\end{equation}<Esc>O
inoremap <buffer> [a \begin{align}<Cr>\end{align}<Esc>O
inoremap <buffer> [x \begin{example}<Cr>\end{example}<Esc>O
inoremap <buffer> ]q \begin{equation}<Cr>\end{equation}<Esc>O
inoremap <buffer> ]l \begin{flushleft}<Cr>\end{flushleft}<Esc>O
inoremap <buffer> ]r \begin{flushright}<Cr>\end{flushright}<Esc>O
inoremap <buffer> [i \item  
inoremap <buffer> ]i \begin{itemize}<Cr>\end{itemize}<Esc>O
inoremap <buffer> [l \begin{lemma}<Cr>\end{lemma}<Esc>O
inoremap <buffer> [n \begin{note}<Cr>\end{note}<Esc>O
inoremap <buffer> [o \begin{observation}<Cr>\end{observation}<Esc>O
inoremap <buffer> ]p \begin{proof}<Cr>\end{proof}<Esc>O
inoremap <buffer> [p \begin{proposition}<Cr>\end{proposition}<Esc>O
inoremap <buffer> [r \begin{remark}<Cr>\end{remark}<Esc>O
inoremap <buffer> [t \begin{theorem}<Cr>\end{theorem}<Esc>O
inoremap <buffer> 	 ]t \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>

" inoremap {c \begin{corollary*}<Cr>\end{corollary*}<Esc>O
" inoremap {d \begin{definition*}<Cr>\end{definition*}<Esc>O
" inoremap {x \begin{example*}\normalfont<Cr>\end{example*}<Esc>O
" inoremap {l \begin{lemma*}<Cr>\end{lemma*}<Esc>O
" inoremap {n \begin{note*}<Cr>\end{note*}<Esc>O
" inoremap {o \begin{observation*}<Cr>\end{observation*}<Esc>O
" inoremap {p \begin{proposition*}<Cr>\end{proposition*}<Esc>O
" inoremap {r \begin{remark*}<Cr>\end{remark*}<Esc>O
" inoremap {t \begin{theorem*}<Cr>\end{theorem*}<Esc>O

inoremap <buffer> __ _{}<Left>
inoremap <buffer> ^^ ^{}<Left>
inoremap <buffer> [m \[\]<Left><Left>
endif


command! -buffer Texmf 	:tabe /home/texmf/tex
command! -buffer Arrows :tabe /home/texmf/tex/arrows.tex
" command! -buffer Bib 	:tabe ~/bibtex/
" command! -buffer BibM 	:tabe ~/bibtex/Mat.bib
" command! -buffer BibGT 	:tabe ~/bibtex/GameTheory.bib
command! -buffer Settings :tabe /home/texmf/tex/settings.tex

syn match texTikzCoord '\(|\)\?([A-Za-z0-9]\{1,3})\(|\)\?\|\(|\)\?(\d\d)|\(|\)\?'
