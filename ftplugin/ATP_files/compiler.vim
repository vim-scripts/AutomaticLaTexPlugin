" Author: 	Marcin Szamotulski	
" Note:		this file contain the main compiler function and related tools, to
" 		view the output, see error file.

" Some options (functions) should be set once:
let s:sourced	 		= exists("s:sourced") ? 1 : 0

if !exists("b:loaded_compiler")
	let b:loaded_compiler = 1
else
	let b:loaded_compiler += 1
endif

" Internal Variables
" {{{
" This limits how many consecutive runs there can be maximally.
let s:runlimit		= 5 

let s:texinteraction	= "nonstopmode"
compiler tex
"}}}
"
" This is the function to view output. It calls compiler if the output is a not
" readable file.
" {{{ ViewOutput
function! s:ViewOutput()
    call atplib#outdir()

    " Set the correct output extension (if nothing matches set the default '.pdf')
    let l:ext	= get(g:atp_CompilersDict, b:atp_TexCompiler, ".pdf") 

    let l:link=system("readlink " . shellescape(b:atp_MainFile))
    if l:link != ""
	let outfile=fnamemodify(l:link,":r") . l:ext
    else
	let outfile=fnamemodify(b:atp_MainFile,":r"). l:ext 
    endif

    if b:atp_Viewer == "xpdf"	
	let l:viewer=b:atp_Viewer . " -remote " . shellescape(b:atp_XpdfServer) . " " . b:atp_ViewerOptions 
    else
	let l:viewer=b:atp_Viewer  . " " . b:atp_ViewerOptions
    endif

    let l:view=l:viewer . " " . shellescape(outfile)  . " &"

    if filereadable(outfile)
	if b:atp_Viewer == "xpdf"	
	    call system(l:view)
	else
	    call system(l:view)
	    redraw!
	endif
    else
	echomsg "Output file do not exists. Calling " . b:atp_TexCompiler
	call s:Compiler( 0, 1, 1, 'silent' , "AU" , b:atp_MainFile)
    endif	
endfunction
command! -buffer ViewOutput		:call <SID>ViewOutput()
noremap <silent> <Plug>ATP_ViewOutput	:call <SID>ViewOutput()<CR>
"}}}

" This function gets the pid of the running compiler
" ToDo: review LatexBox has a better approach!
"{{{ Get PID Functions
function! s:getpid()
	let s:command="ps -ef | grep -v " . $SHELL  . " | grep " . b:atp_TexCompiler . " | grep -v grep | grep " . fnameescape(expand("%")) . " | awk 'BEGIN {ORS=\" \"} {print $2}'" 
	let s:var	= system(s:command)
	return s:var
endfunction
function! s:GetPID()
	let s:var=s:getpid()
	if s:var != ""
		echomsg b:atp_TexCompiler . " pid " . s:var 
	else
		echomsg b:atp_TexCompiler . " is not running"
	endif
endfunction
command! -buffer PID		:call <SID>GetPID()
"}}}

" To check if xpdf is running we use 'ps' unix program.
"{{{ s:xpdfpid
if !exists("*s:xpdfpid")
function! s:xpdfpid() 
    let s:checkxpdf="ps -ef | grep -v grep | grep xpdf | grep '-remote '" . shellescape(b:atp_XpdfServer) . " | awk '{print $2}'"
    return substitute(system(s:checkxpdf),'\D','','')
endfunction
endif
"}}}

" This function compares two files: file written on the disk a:file and the current
" buffer
"{{{ s:compare
" relevant variables:
" g:atp_compare_embedded_comments
" g:atp_compare_double_empty_lines
function! s:compare(file)
    let l:buffer=getbufline(bufname("%"),"1","$")

    " rewrite l:buffer to remove all commands 
    let l:buffer=filter(l:buffer, 'v:val !~ "^\s*%"')

    let l:i = 0
    if g:atp_compare_double_empty_lines == 0 || g:atp_compare_embedded_comments == 0
    while l:i < len(l:buffer)-1
	let l:rem=0
	" remove comment lines at the end of a line
	if g:atp_compare_embedded_comments == 0
	    let l:buffer[l:i] = substitute(l:buffer[l:i],'%.*$','','')
	endif

	" remove double empty lines (i.e. from two conecutive empty lines
	" the first one is deleted, the second remains), if the line was
	" removed we do not need to add 1 to l:i (this is the role of
	" l:rem).
	if g:atp_compare_double_empty_lines == 0 && l:i< len(l:buffer)-2
	    if l:buffer[l:i] =~ '^\s*$' && l:buffer[l:i+1] =~ '^\s*$'
		call remove(l:buffer,l:i)
		let l:rem=1
	    endif
	endif
	if l:rem == 0
	    let l:i+=1
	endif
    endwhile
    endif
 
    " do the same with a:file
    let l:file=filter(a:file, 'v:val !~ "^\s*%"')

    let l:i = 0
    if g:atp_compare_double_empty_lines == 0 || g:atp_compare_embedded_comments == 0
    while l:i < len(l:file)-1
	let l:rem=0
	" remove comment lines at the end of a line
	if g:atp_compare_embedded_comments == 0
	    let l:file[l:i] = substitute(a:file[l:i],'%.*$','','')
	endif
	
	" remove double empty lines (i.e. from two conecutive empty lines
	" the first one is deleted, the second remains), if the line was
	" removed we do not need to add 1 to l:i (this is the role of
	" l:rem).
	if g:atp_compare_double_empty_lines == 0 && l:i < len(l:file)-2
	    if l:file[l:i] =~ '^\s*$' && l:file[l:i+1] =~ '^\s*$'
		call remove(l:file,l:i)
		let l:rem=1
	    endif
	endif
	if l:rem == 0
	    let l:i+=1
	endif
    endwhile
    endif

    return l:file !=# l:buffer
endfunction
"}}}

" This function copies the file a:input to a:output
"{{{ s:copy
function! s:copy(input,output)
	call writefile(readfile(a:input),a:output)
endfunction
"}}}

" This is the CALL BACK mechanism 
" (with the help of David Munger - LatexBox) 
"{{{ call back
function! s:GetSid() "{{{
    return matchstr(expand('<sfile>'), '\zs<SNR>\d\+_\ze.*$')
endfunction 
let s:SID = s:GetSid() "}}}

let g:atp_sid={ fnamemodify(expand('<sfile>'),':t') : s:SID }

function! s:SidWrap(func) "{{{
    return s:SID . a:func
endfunction "}}}

" CatchStatus {{{
function! s:CatchStatus(status)
	let b:atp_TexStatus=a:status
endfunction
" }}}

" Callback {{{
" a:mode 	= a:verbose 	of s:compiler ( one of 'default', 'silent',
" 				'debug', 'verbose')
" a:commnad	= a:commmand 	of s:compiler 
"		 		( a:commnad = 'AU' if run from background)
"
" Uses b:atp_TexStatus which is equal to the value returned by tex
" compiler.
function! s:CallBack(mode)
    let b:mode=a:mode

	let b:atp_running-=1

	" Read the log file
	cg

	" If the log file is open re read it / it has 'autoread' opion set /
	checktime

	" redraw the status line /for the notification to appear as fast as
	" possible/ 
	if a:mode != 'verbose'
	    redrawstatus
	endif

	if b:atp_TexStatus && t:atp_DebugMode != "silent"
	    if b:atp_ReloadOnError
		echomsg b:atp_TexCompiler." exited with status " . b:atp_TexStatus
	    else
		echomsg b:atp_TexCompiler." exited with status " . b:atp_TexStatus . " output file not reloaded"
	    endif
	elseif !g:atp_status_notification || !g:atp_statusline
	    echomsg b:atp_TexCompiler." finished"
	endif

	" End the debug mode if there are no errors
	if b:atp_TexStatus == 0 && t:atp_DebugMode == "debug"
	    cclose
	    echomsg b:atp_TexCompiler." finished with status " . b:atp_TexStatus . " going out of debuging mode."
	    let t:atp_DebugMode == g:atp_DefaultDebugMode
	endif

	if t:atp_DebugMode == "debug" || a:mode == "debug"
	    if !t:atp_QuickFixOpen
		ShowErrors
	    endif
	    " In debug mode, go to first error. 
	    if t:atp_DebugMode == "debug"
		cc
	    endif
	endif
endfunction
"}}}
"}}}

" THE MAIN COMPILER FUNCTION
" {{{ s:Compiler 
" This is the MAIN FUNCTION which sets the command and calls it.
" NOTE: the <filename> argument is not escaped!
" make a:verbose= silent/verbose/debug
" 	debug 	-- switch to show errors after compilation.
" 	verbose -- show compiling procedure.
" 	silent 	-- compile silently (gives status information if fails)
function! s:Compiler(bibtex, start, runs, verbose, command, filename)

    if !has('gui') && a:verbose == 'verbose' && b:atp_running > 0
	redraw!
	echomsg "Please wait until compilation stops."
	return
    endif

    if has('clientserver') && !empty(v:servername) && g:atp_callback && a:verbose != 'verbose'
	let b:atp_running+=1
    endif
    call atplib#outdir()
    	" IF b:atp_TexCompiler is not compatible with the viewer
	" ToDo: (move this in a better place). (luatex can produce both pdf and dvi
	" files according to options so this is not the right approach.) 
	if t:atp_DebugMode != "silent" && b:atp_TexCompiler !~ "luatex" &&
		    \ (b:atp_TexCompiler =~ "^\s*\%(pdf\|xetex\)" && b:atp_Viewer == "xdvi" ? 1 :  
		    \ b:atp_TexCompiler !~ "^\s*pdf" && b:atp_TexCompiler !~ "xetex" &&  (b:atp_Viewer == "xpdf" || b:atp_Viewer == "epdfview" || b:atp_Viewer == "acroread" || b:atp_Viewer == "kpdf"))
	     
	    echohl WaningMsg | echomsg "Your ".b:atp_TexCompiler." and ".b:atp_Viewer." are not compatible:" 
	    echomsg "b:atp_TexCompiler=" . b:atp_TexCompiler	
	    echomsg "b:atp_Viewer=" . b:atp_Viewer	
	endif

	" there is no need to run more than s:runlimit (=5) consecutive runs
	" this prevents from running tex as many times as the current line
	" what can be done by a mistake using the range for the command.
	if a:runs > s:runlimit
	    let l:runs = s:runlimit
	else
	    let l:runs = a:runs
	endif

	let s:tmpdir=tempname()
	let s:tmpfile=atplib#append(s:tmpdir,"/") . fnamemodify(a:filename,":t:r")
	if exists("*mkdir")
	    call mkdir(s:tmpdir, "p", 0700)
	else
	    echoerr 'Your vim doesn't have mkdir function, there is a workaround this though. 
			\ Send an email to the author: mszamot@gmail.com '
	endif

	" SET THE NAME OF OUTPUT FILES
	" first set the extension pdf/dvi
	let l:ext	= get(g:atp_CompilersDict, b:atp_TexCompiler, '.pdf')

	" check if the file is a symbolic link, if it is then use the target
	" name.
	let l:link=system("readlink " . a:filename)
	if l:link != ""
	    let l:basename=fnamemodify(l:link,":r")
	else
	    let l:basename=a:filename
	endif

	" finally, set the output file names. 
	let outfile 	= b:atp_OutDir . fnamemodify(l:basename,":t:r") . l:ext
	let outaux  	= b:atp_OutDir . fnamemodify(l:basename,":t:r") . ".aux"
	let tmpaux  	= fnamemodify(s:tmpfile, ":r") . ".aux"
	let outlog  	= b:atp_OutDir . fnamemodify(l:basename,":t:r") . ".log"

"	COPY IMPORTANT FILES TO TEMP DIRECTORY WITH CORRECT NAME 
"	except log and aux files.
	let l:list=filter(copy(g:keep), 'v:val != "log" && v:val != "aux"')
	for l:i in l:list
	    let l:ftc=b:atp_OutDir . fnamemodify(l:basename,":t:r") . "." . l:i
	    if filereadable(l:ftc)
		call s:copy(l:ftc,s:tmpfile . "." . l:i)
	    endif
	endfor

" 	HANDLE XPDF RELOAD 
	if b:atp_Viewer == "xpdf"
	    if a:start == 1
		"if xpdf is not running and we want to run it.
		let s:xpdfreload = b:atp_Viewer . " -remote " . shellescape(b:atp_XpdfServer) . " " . shellescape(outfile) . " ; "
	    else
" TIME: this take 1/3 of time! 0.039
		if s:xpdfpid() != ""
		    "if xpdf is running (then we want to reload it).
		    "This is where I use 'ps' command to check if xpdf is
		    "running.
		    let s:xpdfreload = b:atp_Viewer . " -remote " . shellescape(b:atp_XpdfServer) . " -reload ; "
		else
		    "if xpdf is not running (but we do not want
		    "to run it).
		    let s:xpdfreload = " "
		endif
	    endif
	else
	    if a:start == 1
		" if b:atp_Viewer is not running and we want to open it.
		let s:xpdfreload = b:atp_Viewer . " " . shellescape(outfile) . " ; "
	    else
		" if b:atp_Viewer is not running then we do not want to
		" open it.
		let s:xpdfreload = " "
	    endif	
	endif

" 	IF OPENING NON EXISTING OUTPUT FILE
"	only xpdf needs to be run before (we are going to reload it)
	if a:start == 1 && b:atp_Viewer == "xpdf"
	    let s:start = b:atp_Viewer . " -remote " . shellescape(b:atp_XpdfServer) . " " . b:atp_ViewerOptions . " & "
	else
	    let s:start = ""	
	endif

"	SET THE COMMAND 
	let s:comp	= b:atp_TexCompiler . " " . b:atp_TexOptions . " -interaction " . s:texinteraction . " -output-directory " . shellescape(s:tmpdir) . " " . shellescape(a:filename)
	let s:vcomp	= b:atp_TexCompiler . " " . b:atp_TexOptions  . " -interaction errorstopmode -output-directory " . shellescape(s:tmpdir) .  " " . shellescape(a:filename)
	if a:verbose == 'verbose' 
	    let s:texcomp=s:vcomp
	else
	    let s:texcomp=s:comp
	endif
	if l:runs >= 2 && a:bibtex != 1
	    " how many times we want to call b:atp_TexCompiler
	    let l:i=1
	    while l:i < l:runs - 1
		let l:i+=1
		let s:texcomp=s:texcomp . " ; " . s:comp
	    endwhile
	    if a:verbose != 'verbose'
		let s:texcomp=s:texcomp . " ; " . s:comp
	    else
		let s:texcomp=s:texcomp . " ; " . s:vcomp
	    endif
	endif
	
	if a:bibtex == 1
	    " this should be decided using the log file as well.
	    if filereadable(outaux)
		call s:copy(outaux,s:tmpfile . ".aux")
		let s:texcomp="bibtex " . shellescape(s:tmpfile) . ".aux ; " . s:comp . "  1>/dev/null 2>&1 "
	    else
		let s:texcomp=s:comp . " ; clear ; bibtex " . shellescape(s:tmpfile) . ".aux ; " . s:comp . " 1>/dev/null 2>&1 "
	    endif
	    if a:verbose != 'verbose'
		let s:texcomp=s:texcomp . " ; " . s:comp
	    else
		let s:texcomp=s:texcomp . " ; " . s:vcomp
	    endif
	endif

	" catch the status
	if has('clientserver') && v:servername != "" && g:atp_callback == 1

	    let catchstatus = s:SidWrap('CatchStatus')
	    let catchstatus_cmd = 'vim ' . ' --servername ' . v:servername . ' --remote-expr ' . 
			\ shellescape(catchstatus)  . '\($?\) ; ' 

	else
	    let catchstatus_cmd = ''
	endif

	" copy output file (.pdf\|.ps\|.dvi)
	let s:cpoption="--remove-destination "
	let s:cpoutfile="cp " . s:cpoption . shellescape(atplib#append(s:tmpdir,"/")) . "*" . l:ext . " " . shellescape(atplib#append(b:atp_OutDir,"/")) . " ; "

	if a:start
	    let s:command="(" . s:texcomp . " ; (" . catchstatus_cmd . " " . s:cpoutfile . " " . s:xpdfreload . " ) || ( ". catchstatus_cmd . " " . s:cpoutfile . ") ; " 
	else
	    " 	Reload on Error:
	    " 	for xpdf it copies the out file but does not reload the xpdf
	    " 	server for other viewers it simply doesn't copy the out file.
	    if exists("b:atp_ReloadOnError") && b:atp_ReloadOnError
		let s:command="( (" . s:texcomp . " && cp --remove-destination " . shellescape(tmpaux) . " " . shellescape(b:atp_OutDir) . "  ) ; "  . catchstatus_cmd . " " . s:cpoutfile . " " . s:xpdfreload
	    else
		if b:atp_Viewer =~ '\<xpdf\>'
		    let s:command="( " . s:texcomp . " && (" . catchstatus_cmd . s:cpoutfile . " " . s:xpdfreload . " cp --remove-destination ". shellescape(tmpaux) . " " . shellescape(b:atp_OutDir) . " ) || (" . catchstatus_cmd . " " . s:cpoutfile . ") ; " 
		else
		    let s:command="(" . s:texcomp . " && (" . catchstatus_cmd . s:cpoutfile . " " . s:xpdfreload . " cp --remove-destination " . shellescape(tmpaux) . " " . shellescape(b:atp_OutDir) . " ) || (" . catchstatus_cmd . ") ; " 
		endif
	    endif
	endif

	" Preserve files with extension belonging to the g:keep list variable.
	let s:copy=""
	let l:j=1
	for l:i in filter(g:keep, 'v:val != "aux"') 
" ToDo: this can be done using internal vim functions.
	    let s:copycmd=" cp " . s:cpoption . " " . shellescape(atplib#append(s:tmpdir,"/")) . 
			\ "*." . l:i . " " . shellescape(atplib#append(b:atp_OutDir,"/"))  
	    if l:j == 1
		let s:copy=s:copycmd
	    else
		let s:copy=s:copy . " ; " . s:copycmd	  
	    endif
	    let l:j+=1
	endfor
	let s:command=s:command . " " . s:copy . " ; "

	if has('clientserver') && v:servername != "" && g:atp_callback == 1

	    let callback=s:SidWrap('CallBack')
	    let callback_cmd = ' vim ' . ' --servername ' . v:servername . ' --remote-expr ' . 
				    \ shellescape(callback).'\(\"'.a:verbose.'\"\)'. " ; "

	    let s:command = s:command . " " . callback_cmd

	endif

 	let s:rmtmp="rm -r " . shellescape(s:tmpdir)
	let s:command=s:command . " " . s:rmtmp . ")&"

	if a:start == 1 
	    let s:command=s:start . s:command
	endif


	" Take care about backup and writebackup options.
	let s:backup=&backup
	let s:writebackup=&writebackup
	if a:command == "AU"  
	    if &backup || &writebackup | setlocal nobackup | setlocal nowritebackup | endif
	endif
" This takes lots of time! 0.049s (more than 1/3)	
	silent! w
	if a:command == "AU"  
	    let &l:backup=s:backup 
	    let &l:writebackup=s:writebackup 
	endif

	if a:verbose != 'verbose'
	    call system(s:command)
	else
	    let s:command="!clear;" . s:texcomp . " " . s:cpoutfile . " " . s:copy 
	    exe s:command
	endif
	let b:texcommand=s:command
endfunction
"}}}

" AUTOMATIC TEX PROCESSING 
" {{{1 s:auTeX
" To Do: we can now check if the last environment is closed and run latex if it is, to
" not run latex if the 
" This function calles the compilers in the beckground. It Needs to be a global
" funnction (it is used in options.vim, there is a tric to put function into
" a dictionary ... )
function! s:auTeX()
    let mode 	= ( g:atp_DefaultDebugMode == 'verbose' ? 'debug' : g:atp_DefaultDebugMode )

    if !b:atp_autex
       return "autex is off"
    endif
    " if the file (or input file is modified) compile the document 
    if filereadable(expand("%"))
	if s:compare(readfile(expand("%")))
	    call s:Compiler(0,0,b:atp_auruns, mode, "AU",b:atp_MainFile)
	    redraw
	    return "compile" 
	endif
    " if compiling for the first time
    else
	call s:Compiler(0,0,b:atp_auruns, mode, "AU",b:atp_MainFile)
	w
	redraw
	return "compile for the first time"
    endif
    return "files does not differ"
endfunction

" This is set by s:setprojectname (options.vim) where it should not!
augroup ATP_auTeX
    au!
    au CursorHold *.tex call s:auTeX()
augroup END 
"}}}

" Related Functions
" {{{ TeX

" a:runs	= how many consecutive runs
" a:1		= one of 'default','silent', 'debug', 'verbose'
" 		  if not specified uses 'default' mode
" 		  (g:atp_DefaultDebugMode).
function! s:TeX(runs, ...)
let s:name=tempname()

    if a:0 >= 1
	let mode = ( a:1 != 'default' ? a:1 : g:atp_DefaultDebugMode )
    else
	let mode = g:atp_DefaultDebugMode
    endif

    if l:mode != 'silent'
	if a:runs > 2 && a:runs <= 5
	    echomsg b:atp_TexCompiler . " will run " . a:1 . " times."
	elseif a:runs == 2
	    echomsg b:atp_TexCompiler . " will run twice."
	elseif a:runs == 1
	    echomsg b:atp_TexCompiler . " will run once."
	elseif a:runs > 5
	    echomsg b:atp_TexCompiler . " will run " . s:runlimit . " times."
	endif
    endif
    call s:Compiler(0,0, a:runs, mode, "COM", b:atp_MainFile)
endfunction
command! -buffer -nargs=? -count=1 TEX		:call <SID>TeX(<count>, <f-args>)
noremap <silent> <Plug>ATP_TeXCurrent		:<C-U>call <SID>TeX(v:count1, t:atp_DebugMode)<CR>
noremap <silent> <Plug>ATP_TeXDefault		:<C-U>call <SID>TeX(v:count1, 'default')<CR>
noremap <silent> <Plug>ATP_TeXSilent		:<C-U>call <SID>TeX(v:count1, 'silent')<CR>
noremap <silent> <Plug>ATP_TeXDebug		:<C-U>call <SID>TeX(v:count1, 'debug')<CR>
noremap <silent> <Plug>ATP_TeXVerbose		:<C-U>call <SID>TeX(v:count1, 'verbose')<CR>
inoremap <silent> <Plug>iATP_TeXVerbose		<Esc>:<C-U>call <SID>TeX(v:count1, 'verbose')<CR>
"}}}
"{{{ Bibtex
function! s:SimpleBibtex()
    let bibcommand 	= "bibtex "
    let auxfile		= b:atp_OutDir . (fnamemodify(expand("%"),":t:r")) . ".aux"
    if filereadable(auxfile)
	let command	= bibcommand . shellescape(l:auxfile)
	echo system(command)
    else
	echomsg "No aux file in " . b:atp_OutDir
    endif
endfunction
command! -buffer SBibtex		:call <SID>SimpleBibtex()
nnoremap <silent> <Plug>SimpleBibtex	:call <SID>SimpleBibtex()<CR>

function! s:Bibtex(...)
    if a:0 >= 1
	let mode = ( a:1 != 'default' ? a:1 : g:atp_DefaultDebugMode )
    else
	let mode = g:atp_DefaultDebugMode
    endif

    call s:Compiler(1,0,0, mode,"COM",b:atp_MainFile)
endfunction
command! -buffer -nargs=? Bibtex	:call <SID>Bibtex(<f-args>)
nnoremap <silent> <Plug>BibtexDefault	:call <SID>Bibtex("")<CR>
nnoremap <silent> <Plug>BibtexSilent	:call <SID>Bibtex("silent")<CR>
nnoremap <silent> <Plug>BibtexDebug	:call <SID>Bibtex("debug")<CR>
nnoremap <silent> <Plug>BibtexVerbose	:call <SID>Bibtex("verbose")<CR>
"}}}

" Show Errors Function
" {{{ SHOW ERRORS
"
" this functions sets errorformat according to the flag given in the argument,
" possible flags:
" e	- errors (or empty flag)
" w	- all warning messages
" c	- citation warning messages
" r	- reference warning messages
" f	- font warning messages
" fi	- font warning and info messages
" F	- files
" p	- package info messages

" {{{ s:SetErrorFormat
" first argument is a word in flags 
" the default is a:1=e /show only error messages/
function! s:SetErrorFormat(...)
    if a:0 > 0
	let b:arg1=a:1
	if a:0 > 1
	    let b:arg1.=" ".a:2
	endif
    endif
    let &l:errorformat=""
    if a:0 == 0 || a:0 > 0 && a:1 =~ 'e'
	if &l:errorformat == ""
	    let &l:errorformat= "%E!\ LaTeX\ %trror:\ %m,\%E!\ %m"
	else
	    let &l:errorformat= &l:errorformat . ",%E!\ LaTeX\ %trror:\ %m,\%E!\ %m"
	endif
    endif
    if a:0>0 &&  a:1 =~ 'w'
	if &l:errorformat == ""
	    let &l:errorformat='%WLaTeX\ %tarning:\ %m\ on\ input\ line\ %l%.,
			\%WLaTeX\ %.%#Warning:\ %m,
	    		\%Z(Font) %m\ on\ input\ line\ %l%.,
			\%+W%.%#\ at\ lines\ %l--%*\\d'
	else
	    let &l:errorformat= &l:errorformat . ',%WLaTeX\ %tarning:\ %m\ on\ input\ line\ %l%.,
			\%WLaTeX\ %.%#Warning:\ %m,
	    		\%Z(Font) %m\ on\ input\ line\ %l%.,
			\%+W%.%#\ at\ lines\ %l--%*\\d'
" 	    let &l:errorformat= &l:errorformat . ',%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#,
" 			\%WLaTeX\ %.%#Warning:\ %m,
" 			\%+W%.%#\ at\ lines\ %l--%*\\d'
	endif
    endif
    if a:0>0 && a:1 =~ '\Cc'
" NOTE:
" I would like to include 'Reference/Citation' as an error message (into %m)
" but not include the 'LaTeX Warning:'. I don't see how to do that actually. 
" The only solution, that I'm aware of, is to include the whole line using
" '%+W' but then the error messages are long and thus not readable.
	if &l:errorformat == ""
	    let &l:errorformat = "%WLaTeX\ Warning:\ Citation\ %m\ on\ input\ line\ %l%.%#"
	else
	    let &l:errorformat = &l:errorformat . ",%WLaTeX\ Warning:\ Citation\ %m\ on\ input\ line\ %l%.%#"
	endif
    endif
    if a:0>0 && a:1 =~ '\Cr'
	if &l:errorformat == ""
	    let &l:errorformat = "%WLaTeX\ Warning:\ Reference %m on\ input\ line\ %l%.%#,%WLaTeX\ %.%#Warning:\ Reference %m,%C %m on input line %l%.%#"
	else
	    let &l:errorformat = &l:errorformat . ",%WLaTeX\ Warning:\ Reference %m on\ input\ line\ %l%.%#,%WLaTeX\ %.%#Warning:\ Reference %m,%C %m on input line %l%.%#"
	endif
    endif
    if a:0>0 && a:1 =~ '\Cf'
	if &l:errorformat == ""
	    let &l:errorformat = "%WLaTeX\ Font\ Warning:\ %m,%Z(Font) %m on input line %l%.%#"
	else
	    let &l:errorformat = &l:errorformat . ",%WLaTeX\ Font\ Warning:\ %m,%Z(Font) %m on input line %l%.%#"
	endif
    endif
    if a:0>0 && a:1 =~ '\Cfi'
	if &l:errorformat == ""
	    let &l:errorformat = '%ILatex\ Font\ Info:\ %m on input line %l%.%#,
			\%ILatex\ Font\ Info:\ %m,
			\%Z(Font) %m\ on input line %l%.%#,
			\%C\ %m on input line %l%.%#'
	else
	    let &l:errorformat = &l:errorformat . ',%ILatex\ Font\ Info:\ %m on input line %l%.%#,
			\%ILatex\ Font\ Info:\ %m,
			\%Z(Font) %m\ on input line %l%.%#,
			\%C\ %m on input line %l%.%#'
	endif
    endif
    if a:0>0 && a:1 =~ '\CF'
	if &l:errorformat == ""
	    let &l:errorformat = 'File: %m'
	else
	    let &l:errorformat = &l:errorformat . ',File: %m'
	endif
    endif
    if a:0>0 && a:1 =~ '\Cp'
	if &l:errorformat == ""
	    let &l:errorformat = 'Package: %m'
	else
	    let &l:errorformat = &l:errorformat . ',Package: %m'
	endif
    endif
    if &l:errorformat != ""

	let pm = ( g:atp_show_all_lines == 1 ? '+' : '-' )

	let l:dont_ignore = 0
	if a:0 >= 1 && a:1 =~ '\cALL'
	    let l:dont_ignore = 1
	    let pm = '+'
	endif
	let b:dont_ignore=l:dont_ignore.a:0

	let &l:errorformat = &l:errorformat.",
		    	    \%Cl.%l\ %m,
			    \%".pm."C\ \ %m%.%#,
			    \%".pm."C%.%#-%.%#,
			    \%".pm."C%.%#[]%.%#,
			    \%".pm."C[]%.%#,
			    \%".pm."C%.%#%[{}\\]%.%#,
			    \%".pm."C<%.%#>%.%#,
			    \%".pm."C%m,
			    \%".pm."GSee\ the\ LaTeX%m,
			    \%".pm."GType\ \ H\ <return>%m,
			    \%".pm."G%.%#\ (C)\ %.%#,
			    \%".pm."G(see\ the\ transcript%.%#),
			    \%-G\\s%#"
	if (g:atp_ignore_unmatched && !g:atp_show_all_lines)
	    exec 'setlocal efm+=%-G%.%#' 
	elseif l:dont_ignore
	    exec 'setlocal efm+=%-G%.%#' 
	endif
	let &l:errorformat = &l:errorformat.",
			    \%".pm."O(%*[^()])%r,
			    \%".pm."O%*[^()](%*[^()])%r,
			    \%".pm."P(%f%r,
			    \%".pm."P\ %\\=(%f%r,
			    \%".pm."P%*[^()](%f%r,
			    \%".pm."P[%\\d%[^()]%#(%f%r"
	if g:atp_ignore_unmatched && !g:atp_show_all_lines
	    exec 'setlocal efm+=%-P%*[^()]' 
	elseif l:dont_ignore
	    exec 'setlocal efm+=%-P%*[^()]' 
	endif
	let &l:errorformat = &l:errorformat.",
			    \%".pm."Q)%r,
			    \%".pm."Q%*[^()])%r,
			    \%".pm."Q[%\\d%*[^()])%r"
	if g:atp_ignore_unmatched && !g:atp_show_all_lines
	    let &l:errorformat = &l:errorformat.",%-Q%*[^()]"
	elseif l:dont_ignore
	    let &l:errorformat = &l:errorformat.",%-Q%*[^()]"
	endif

" 			    removed after GType
" 			    \%-G\ ...%.%#,
    endif
endfunction
command! -buffer -nargs=? 	SetErrorFormat 	:call <SID>SetErrorFormat(<f-args>)
"}}}
"{{{ s:ShowErrors
" each argument can be a word in flags as for s:SetErrorFormat (except the
" word 'whole') + two other flags: all (include all errors) and ALL (include
" all errors and don't ignore any line - this overrides the variables
" g:atp_ignore_unmatched and g:atp_show_all_lines.
function! s:ShowErrors(...)

    let errorfile	= &l:errorfile
    " read the log file and merge warning lines 
    " filereadable doesn't like shellescaped file names not fnameescaped. 
    " The same for readfile() and writefile()  built in functions.
    if !filereadable( errorfile)
	echohl WarningMsg
	echomsg "No error file: " . errorfile  
	echohl Normal
	return
    endif

    let l:log=readfile(errorfile)

    let l:nr=1
    for l:line in l:log
	if l:line =~ "LaTeX Warning:" && l:log[l:nr] !~ "^$" 
	    let l:newline=l:line . l:log[l:nr]
	    let l:log[l:nr-1]=l:newline
	    call remove(l:log,l:nr)
	endif
	let l:nr+=1
    endfor
    call writefile(l:log, errorfile)
    
    " set errorformat 
    let l:arg = ( a:0 > 0 ? a:1 : "e" )
    if l:arg =~ 'o'
	OpenLog
	return
    endif
    call s:SetErrorFormat(l:arg)

    let l:show_message = ( a:0 >= 2 ? a:2 : 1 )

    " read the log file
    cg

    " final stuff
    if len(getqflist()) == 0 
	if l:show_message
	    echomsg "no errors"
	endif
	return ":)"
    else
	cl
	return 1
    endif
endfunction
command! -buffer -nargs=? -complete=custom,ListErrorsFlags 	ShowErrors 	:call <SID>ShowErrors(<f-args>)
"}}}
if !exists("*ListErrorsFlags")
function! ListErrorsFlags(A,L,P)
	return "e\nw\nc\nr\ncr\nf\nfi\nall\nF"
endfunction
endif
"}}}

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
