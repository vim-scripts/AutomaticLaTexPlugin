" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 Jan 25
" URL:		

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

if !exists("*ShowATPO")
function! ShowATPO(...)
if a:0 == 0
    echomsg "variable=local value [default value]"  
    echomsg "b:texcompiler=" . b:texcompiler 
    echomsg "b:texoptions=" . b:texoptions 
    echomsg "b:autex=" . b:autex 
    echomsg "b:outdir=" . b:outdir 
    echomsg "b:Viewer=" . b:Viewer 
    if b:Viewer == "xpdf"
	echomsg "b:XpdfOptions=" . b:XpdfOptions 
	echomsg "b:XpdfServer=" . b:XpdfServer 
	echomsg "b:reloadonerror=" . b:reloadonerror 
    endif
    echomsg "g:askfortheoutdir=" . g:askfortheoutdir 
    echomsg "b:openviewer=" . b:openviewer 
    echomsg "g:keep=" . g:keep  
    echomsg "g:texextensions=" . g:texextensions
    echomsg "g:rmcommand=" . g:rmcommand
elseif a:0>=1 
    echomsg "b:texcompiler=" . b:texcompiler . "  [" . s:optionsDict["texcompiler"] . "]" 
    echomsg "b:texoptions=" . b:texoptions . "  [" . s:optionsDict["texoptions"] . "]" 
    echomsg "b:autex=" . b:autex . "  [" . s:optionsDict["autex"] . "]" 
    echomsg "b:outdir=" . b:outdir . "  [" . s:optionsDict["outdir"] . "]" 
    echomsg "b:Viewer=" . b:Viewer . "  [" . s:optionsDict["Viewer"] . "]" 
    if b:Viewer == "xpdf"
	echomsg "b:XpdfOptions=" . b:XpdfOptions . "  [" . s:optionsDict["XpdfOptions"] . "]" 
	echomsg "b:XpdfServer=" . b:XpdfServer . "  [" . s:optionsDict["XpdfServer"] . "]" 
	echomsg "b:reloadonerror=" . b:reloadonerror . "  [" . s:optionsDict["reloadonerror"] . "]" 
    endif
    echomsg "g:askfortheoutdir=" . g:askfortheoutdir . "  [" . s:optionsDict["askfortheoutdir"] . "]" 
    echomsg "b:openviewer=" . b:openviewer . "  [" . s:optionsDict["openviewer"] . "]" 
    echomsg "g:keep=" . g:keep  
    echomsg "g:texextensions=" . g:texextensions
    echomsg "g:rmcommand=" . g:rmcommand
endif
endfunction
endif
command -buffer -nargs=? ShowATPO :call ShowATPO(<args>)

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
if !exists("*ViewOutput")
function! ViewOutput()
if b:outdir !~ "\/$"
    b:outdir=b:outdir . "/"
endif
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
    if b:outdir !~ "\/$"
	let b:outdir=b:outdir . "/"
    endif
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
	let s:file=tempname()
"  		echomsg "DEBUG tempfile="s:file 
	let s:dir=fnamemodify(s:file,":h")
	let s:job=fnamemodify(s:file,":t")
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
		call s:copy(l:ftc,s:file . "." . l:i)
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
		call s:copy(l:outaux,s:file . ".aux")
		let s:texcomp="bibtex " . s:file . ".aux ; " . s:comp . "  1>/dev/null 2>&1 "
	    else
		let s:texcomp=s:comp . " ; clear ; bibtex " . s:file . ".aux ; " . s:comp . " 1>/dev/null 2>&1 "
	    endif
	    if a:verbose != 0
		let s:texcomp=s:texcomp . " ; " . s:vcomp
	    else
		let s:texcomp=s:texcomp . " ; " . s:comp
	    endif
	endif
	let s:cpoption="--remove-destination "
	let s:cpoutfile="cp " . s:cpoption . shellescape(s:file . l:ext) . " " . shellescape(l:outfile) 
	let s:command="(" . s:texcomp . " && (" . s:cpoutfile . " ; " . s:xpdfreload . ") || (" . s:cpoutfile . ")" 
	let s:copy=""
	let l:j=1
	for l:i in g:keep 
	    let s:copycmd="cp " . s:cpoption . " " . shellescape(s:file . "." . l:i) . " " . shellescape(b:outdir . (fnamemodify(expand("%"),":t:r")) . "." . l:i) 
" 		echomsg "DEBUG 2 copycmd"s:copycmd
	    if l:j == 1
		let s:copy=s:copycmd
	    else
		let s:copy=s:copy . " ; " . s:copycmd	  
	    endif
	    let l:j+=1
	endfor
	    let s:command=s:command . " ; " . s:copy
 	let s:rmtmp="rm " . s:file . "*" 
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
	w
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
" 		echomsg "DEBUG tempname"s:name
if a:0 >= 1
    echomsg b:texcompiler" will run "a:1"times."
    call s:compiler(0,0,a:1,0,"COM")
else
    call s:compiler(0,0,1,0,"COM")
endif
endfunction
endif
command! -buffer -nargs=? TEX   :call  TEX(<args>)
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
    echomsg b:texcompiler" will run "a:1"times."
    call s:compiler(0,0,a:1,1,"COM")
else
    call s:compiler(0,0,1,1,"COM")
endif
endfunction
endif
command! -buffer -nargs=? VTEX	:call  VTEX(<args>)
"-------------------------------------------------------------------------
if !exists("*SimpleBibtex")
function! SimpleBibtex()
	if b:outdir !~ "\/$"
	    b:outdir=b:outdir . "/"
	endif
  	let l:bibcommand="bibtex "
 	let l:auxfile=b:outdir . (fnamemodify(expand("%"),":t:r")) . ".aux"
	if filereadable(l:auxfile)
	    let l:command=l:bibcommand . shellescape(l:auxfile)
	    echo system(l:command)
	else
	    echomsg "No aux file in " . b:outdir
	endif
endfunction
endif
command! -buffer SBibtex :call SimpleBibtex()

if !exists("*Bibtex")
function! Bibtex(...)
	let s:bibname=tempname()
	let s:auxf=s:bibname . ".aux"
	if a:0 == 0
" 	    echomsg "DEBUG Bibtex"
	    call s:compiler(1,0,0,0,"COM")
	else
" 	    echomsg "DEBUG Bibtex verbose"
	    call s:compiler(1,0,0,1,"COM")
	endif
endfunction
endif
command! -buffer -nargs=? Bibtex :call Bibtex(<args>)
command! -buffer VBibtex :call Bibtex(1)

"-------------------------------------------------------------------------
" TeX LOG FILE
if &buftype == 'quickfix'
	setlocal modifiable
	setlocal autoread
endif	

"-------------------------------------------------------------------------
if !exists("*Delete")
function! Delete()
	if b:outdir !~ "\/$"
	    b:outdir=b:outdir . "/"
	endif
	let s:error=0
	for l:ext in g:texextensions
		if executable(g:rmcommand)
			if g:rmcommand =~ "^\s*rm\p*" || g:rmcommand =~ "^\s*perltrash\p*"
				let l:rm=g:rmcommand . " " . b:outdir . "*." . l:ext . " 2>/dev/null && echo Removed ./*" . l:ext . " files"
			endif
		echo system(l:rm)
		else
			let s:error=1
			let s:file=b:outdir . fnamemodify(expand("%"),":t:r") . "." . l:ext
 			if delete(s:file) == 0
				echo "Removed " . s:file 
			endif
		endif
	endfor
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
else
    echoerr "The function TexLog() is already defined, the function TexLog() from Automatic TeX Plugin is disabled." 
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

if !exists("*Print")
function! Print(printeroptions)
    if b:outdir !~ "\/$"
	b:outdir=b:outdir . "/"
    endif
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

"--------- MAPPINGS -------------------------------------------------------
" Add mappings, unless the user didn't want this.
if !exists("no_plugin_maps") && !exists("no_atp_maps")

noremap  <buffer> <LocalLeader>v		:call ViewOutput() <CR><CR>
noremap  <buffer> <F3>        		:call ViewOutput() <CR><CR>
inoremap <buffer> <F3> <Esc> 		:call ViewOutput() <CR><CR>
noremap  <buffer> <LocalLeader>g 		:call Getpid()<CR>
noremap  <buffer> <LocalLeader>l 		:call TEX() <CR>	
inoremap <buffer> <LocalLeader>l<Left><ESC> :call TEX() <CR>a
noremap  <buffer> <F5> 			:call VTEX() <CR>	
noremap  <buffer> <S-F5> 			:call ToggleAuTeX()<CR>
inoremap <buffer> <F5> <Left><ESC> 		:call VTEX() <CR>a
noremap  <buffer> <LocalLeader>sb		:call SimpleBibtex()<CR>
noremap  <buffer> <LocalLeader>b		:call Bibtex()<CR>
noremap  <buffer> <LocalLeader>t		:tabe /home/texmf/tex<CR>
noremap  <buffer> <LocalLeader>d 		:call Dict()<CR><CR>
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
noremap  <buffer> <F1> 	   		:!clear;texdoc -m 
inoremap <buffer> <F1> <Esc> 		:!clear;texdoc -m  
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

inoremap <buffer> __ _{}<Left>
inoremap <buffer> ^^ ^{}<Left>
inoremap <buffer> [m \[\]<Left><Left>
endif


command! -buffer Texmf 	:tabe /home/texmf/tex
command! -buffer Arrows :tabe /home/texmf/tex/arrows.tex
command! -buffer Bib 	:tabe ~/bibtex/
command! -buffer BibM 	:tabe ~/bibtex/Mat.bib
command! -buffer BibGT 	:tabe ~/bibtex/GameTheory.bib
command! -buffer Settings :tabe /home/texmf/tex/settings.tex
