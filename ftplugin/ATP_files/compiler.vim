" Author: 	Marcin Szamotulski	
" Note:		this file contain the main compiler function and related tools, to
" 		view the output, see error file.
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" URL:		https://launchpad.net/automatictexplugin
" Language:	tex
" Last Change:

" Some options (functions) should be set once:
let s:sourced	 	= exists("s:sourced") ? 1 : 0

" Functions: (source once)
if !s:sourced || g:atp_reload_functions  "{{{
" Internal Variables
" {{{
" This limits how many consecutive runs there can be maximally.
" Note: compile.py script has hardcoded the same value.
let s:runlimit		= 9

try
    compiler tex
catch E666:
endtry
" }}}

" This is the function to view output. It calls compiler if the output is a not
" readable file.
" {{{ ViewOutput
" a:1 == "RevSearch" 	if run from RevSearch() function and the output file doesn't
" exsists call compiler and RevSearch().
function! <SID>ViewOutput(...)

    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)

    let fwd_search	= ( a:0 == 1 && a:1 =~? 'sync' ? 1 : 0 )

    call atplib#outdir()

    " Set the correct output extension (if nothing matches set the default '.pdf')
    let ext		= get(g:atp_CompilersDict, matchstr(b:atp_TexCompiler, '^\s*\zs\S\+\ze'), ".pdf") 

    " Read the global options from g:atp_{b:atp_Viewer}Options variables
    let global_options 	= exists("g:atp_".matchstr(b:atp_Viewer, '^\s*\zs\S\+\ze')."Options") ? g:atp_{matchstr(b:atp_Viewer, '^\s*\zs\S\+\ze')}Options : ""
    let local_options 	= getbufvar(bufnr("%"), "atp_".matchstr(b:atp_Viewer, '^\s*\zs\S\+\ze')."Options")

"     let g:options	= global_options ." ". local_options

    " Follow the symbolic link
    let link=resolve(atp_MainFile)
    if link != ""
	let outfile	= fnamemodify(link,":r") . ext
    else
	let outfile	= fnamemodify(atp_MainFile,":r"). ext 
    endif

    if b:atp_Viewer == "xpdf"	
	let viewer	= b:atp_Viewer . " -remote " . shellescape(b:atp_XpdfServer)
    else
	let viewer	= b:atp_Viewer
    endif


    let sync_args 	= ( fwd_search ?  <SID>SyncTex(0,1) : "" )
    let g:global_options = global_options
    let g:local_options = local_options
    let g:sync_args	= sync_args
    let g:viewer	= viewer
    if b:atp_Viewer =~ '\<okular\>' && fwd_search
	let view_cmd	= "(".viewer." ".global_options." ".local_options." ".sync_args.")&"
    elseif b:atp_Viewer =~ '^\s*xdvi\>'
	let view_cmd	= "(".viewer." ".global_options." ".local_options." ".sync_args." ".shellescape(outfile).")&"
    else
" I couldn't get it work with okular.	
" 	let SyncTex	= s:SidWrap('SyncTex')
" 	let sync_cmd 	= (fwd_search ? "vim "." --servername ".v:servername." --remote-expr "."'".SyncTex."()';" : "" ) 
" 	let g:sync_cmd=sync_cmd
	let view_cmd	= viewer." ".global_options." ".local_options." ".shellescape(outfile)."&"
    endif

    if g:atp_debugV
	let g:view_cmd	= view_cmd
    endif

    if filereadable(outfile)
	if b:atp_Viewer == "xpdf"	
	    call system(view_cmd)
	else
	    call system(view_cmd)
	    redraw!
	endif
    else
	echomsg "[ATP:] output file do not exists. Calling " . b:atp_TexCompiler
	if fwd_search
	    if g:atp_Compiler == 'python'
		call <SID>PythonCompiler( 0, 2, 1, 'silent' , "AU" , atp_MainFile, "")
	    else
		call <SID>Compiler( 0, 2, 1, 'silent' , "AU" , atp_MainFile, "")
	    endif
	else
	    if g:atp_Compiler == 'python'
		call <SID>PythonCompiler( 0, 1, 1, 'silent' , "AU" , atp_MainFile, "")
	    else
		call <SID>Compiler( 0, 1, 1, 'silent' , "AU" , atp_MainFile, "")
	    endif
	endif
    endif	
endfunction
noremap <silent> 		<Plug>ATP_ViewOutput	:call <SID>ViewOutput()<CR>
"}}}

" Forward Search
" {{{ GetSyncData
function! <SID>GetSyncData(line, col)

     	if !filereadable(fnamemodify(atplib#FullPath(b:atp_MainFile), ":r").'.synctex.gz') 
	    redraw!
	    echomsg "[SyncTex:] calling ".get(g:CompilerMsg_Dict, b:atp_TexCompiler, b:atp_TexCompiler)." to generate synctex data. Wait a moment..."
	    let cmd=b:atp_TexCompiler . " -synctex=1 " . shellescape(atplib#FullPath(b:atp_MainFile))
 	    call system(cmd) 
 	endif
	" Note: synctex view -i line:col:tex_file -o output_file
	" tex_file must be full path.
	let synctex_cmd="synctex view -i ".a:line.":".a:col.":'".fnamemodify(b:atp_MainFile, ":p"). "' -o '".fnamemodify(b:atp_MainFile, ":p:r").".pdf'"

	" SyncTex is fragile for the file name: if it is file name or full path, it
	" must agree literally with what is written in .synctex.gz file
	" first we try with full path then with file name without path.
	let synctex_output=split(system(synctex_cmd), "\n")
	if get(synctex_output, 1, '') =~ '^SyncTex Warning: No tag for'
	    " Write better test (above)
	    let synctex_cmd="synctex view -i ".a:line.":".a:col.":'".b:atp_MainFile. "' -o '".fnamemodify(b:atp_MainFile, ":r").".pdf'"
	    let synctex_output=split(system(synctex_cmd), "\n")
	    call add(g:debug,get(synctex_output, 1, ''))
	    if get(synctex_output, 1, '') =~ '^SyncTex Warning:'
		return [ "no_sync", get(synctex_output, 1, ''), 0 ]
	    endif
	endif

	if g:atp_debugSync
	    let g:synctex_cmd=synctex_cmd
	    let g:synctex_output=copy(synctex_output)
	endif

	let page_list=copy(synctex_output)
	call filter(page_list, "v:val =~ '^\\cpage:\\d\\+'")
	let page=get(page_list, 0, "no_sync") 

	let y_coord_list=copy(synctex_output) 
	call filter(y_coord_list, "v:val =~ '^\\cy:\\d\\+'")
	let y_coord=get(y_coord_list, 0, "no sync data")
	let y_coord= ( y_coord != "no sync data" ? matchstr(y_coord, 'y:\zs[0-9.]*') : y_coord )

	let x_coord_list=copy(synctex_output) 
	call filter(x_coord_list, "v:val =~ '^\\cx:\\d\\+'")
	let x_coord=get(x_coord_list, 0, "no sync data")
	let x_coord= ( x_coord != "no sync data" ? matchstr(x_coord, 'x:\zs[0-9.]*') : x_coord )

	if g:atp_debugSync
	    let g:page=page
	    let g:y_coord=y_coord
	    let g:x_coord=x_coord
	endif

	if page == "no_sync"
	    return [ "no_sync", "No SyncTex Data: try on another line (or recompile the document).", 0 ]
	endif
	let page_nr=matchstr(page, '^\cPage:\zs\d\+') 
	let [ b:atp_synctex_pagenr, b:atp_synctex_ycoord, b:atp_synctex_xcoord ] = [ page_nr, y_coord, x_coord ]
	return [ page_nr, y_coord, x_coord ]
endfunction
function! <SID>SyncShow( page_nr, y_coord)
    if a:y_coord < 300
	let height="top"
    elseif a:y_coord < 500
	let height="middle"
    else
	let height="bottom"
    endif
    if a:page_nr != "no_sync"
	echomsg "[SyncTex:] ".height." of page ".a:page_nr
    else
	echohl WarningMsg
	echomsg "[SyncTex:] ".a:y_coord
" 	echomsg "       You cannot forward search on comment lines, if this is not the case try one or two lines above/below"
	echohl Normal
    endif
endfunction "}}}
function! <SID>SyncTex(mouse, ...) "{{{
"     let g:debug 	= (exists("g:debug")?g:debug+1:1)
    let output_check 	= ( a:0 >= 1 && a:1 == 0 ? 0 : 1 )
    let dryrun 		= ( a:0 >= 2 && a:2 == 1 ? 1 : 0 )
    " Mouse click <S-LeftMouse> is mapped to <LeftMouse>... => thus it first changes
    " the cursor position.
    let [ line, col ] 	= [ line("."), col(".") ]
"     let [ g:line, g:col ] 	= [ line, col ]
    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)
    let ext		= get(g:atp_CompilersDict, matchstr(b:atp_TexCompiler, '^\s*\zs\S\+\ze'), ".pdf")
    let output_file	= fnamemodify(atp_MainFile,":p:r") . ext
    if !filereadable(output_file) && output_check
       ViewOutput sync
       return 2
    endif
    if b:atp_Viewer == "xpdf"
	let [ page_nr, y_coord, x_coord ] = <SID>GetSyncData(line, col)
	let sync_cmd_page = "xpdf -remote " . shellescape(b:atp_XpdfServer) . " -exec 'gotoPage(".page_nr.")'"
	let sync_cmd_y 	= "xpdf -remote " . shellescape(b:atp_XpdfServer) . " -exec 'scrollDown(".y_coord.")'"
        let sync_cmd_x 	= "xpdf -remote " . shellescape(b:atp_XpdfServer) . " -exec 'scrollRight(".x_coord.")'"
	"There is a bug in xpdf. We need to sleep between sending commands to it.:
	let sleep    = ( g:atp_XpdfSleepTime ? 'sleep '.string(g:atp_XpdfSleepTime).'s;' : '' )
	let sync_cmd = "(".sync_cmd_page.";".sleep.sync_cmd_y.";".sleep.sync_cmd_x.")&"
" 	let sync_cmd = sync_cmd_page.";".sync_cmd_y.";".sync_cmd_x
	if !dryrun
	    call system(sync_cmd)
" 	    redraw!
	    call <SID>SyncShow(page_nr, y_coord)
	endif
" 	let g:sync_cmd_page 	= sync_cmd_page
" 	let g:sync_cmd_y 	= sync_cmd_y
"         let g:sync_cmd_x 	= sync_cmd_x
" 	let g:sync_cmd = sync_cmd
    elseif b:atp_Viewer == "okular"
	let [ page_nr, y_coord, x_coord ] = <SID>GetSyncData(line, col)
	" This will not work in project files. (so where it is mostly needed.) 
	let sync_cmd = "okular --unique ".shellescape(expand("%:p:r")).".pdf\\#src:".line.shellescape(expand("%:p"))." &"
	let sync_args = " ".shellescape(expand("%:p:r")).".pdf\\#src:".line.shellescape(expand("%:p"))." "
	if !dryrun
	    call system(sync_cmd)
" 	    redraw!
	    call <SID>SyncShow(page_nr, y_coord)
	endif
" 	let g:sync_cmd = sync_cmd
"     elseif b:atp_Viewer == "evince"
" 	let rev_searchcmd="synctex view -i ".line(".").":".col(".").":".fnameescape(b:atp_MainFile). " -o ".fnameescape(fnamemodify(b:atp_MainFile, ":p:r").".pdf") . " -x 'evince %{output} -i %{page}'"
"     endif
    elseif b:atp_Viewer =~ '^\s*xdvi\>'
	let options = (exists("g:atp_xdviOptions") ? g:atp_xdviOptions : "" ) . getbufvar(bufnr(""), "atp_xdviOptions")
	let sync_cmd = "xdvi ".options.
		\ " -editor '".v:progname." --servername ".v:servername.
		\ " --remote-wait +%l %f' -sourceposition ". 
		\ line.":".col.shellescape(fnameescape(fnamemodify(expand("%"),":p"))). 
		\ " ".fnameescape(output_file)." &"
	let sync_args = " -sourceposition ".line.":".col.shellescape(fnameescape(fnamemodify(expand("%"),":p")))." "
	if !dryrun
	    call system(sync_cmd)
	endif
" 	let g:sync_cmd = sync_cmd
    else
	let sync_cmd=""
" 	let g:sync_cmd = sync_cmd
    endif
    return
endfunction 
nmap <buffer> <Plug>SyncTexKeyStroke		:call <SID>SyncTex(0)<CR>
nmap <buffer> <Plug>SyncTexMouse		:call <SID>SyncTex(1)<CR>
"}}}
"
" This function gets the pid of the running compiler
" ToDo: review LatexBox has a better approach!
"{{{ Get PID Functions
function! <SID>getpid()
	let s:command="ps -ef | grep -v " . $SHELL  . " | grep " . b:atp_TexCompiler . " | grep -v grep | grep " . fnameescape(expand("%")) . " | awk 'BEGIN {ORS=\" \"} {print $2}'" 
	let s:var	= system(s:command)
	return s:var
endfunction
" The same but using python (it is not used)
" TODO: end this.
function! <SID>PythonGetPID() 
python << EOF
import psutil
latex = vim.eval("b:atp_TexCompiler")
# Make dictionary: xpdf_servername : file
# to test if the server host file use:
# basename(xpdf_server_file_dict().get(server, ['_no_file_'])[0]) == basename(file)
ps_list=psutil.get_pid_list()
latex_running	= False
for pr in ps_list:
	try:
		name=psutil.Process(pr).name
		cmdline=psutil.Process(pr).cmdline
		if name == latex: 
			latex_pid=pr
			latex_running=True
			break
	except psutil.NoSuchProcess:
		pass

if latex_running:
	vim.command("let s:var="+str(latex_pid))
else:
	vim.command("let s:var=''") 
EOF
endfunction
function! <SID>GetPID()
    if g:atp_Compiler == "bash"
	let s:var=s:getpid()
	if s:var != ""
	    echomsg "[ATP:] ".b:atp_TexCompiler . " pid(s): " . s:var 
	else
	    let b:atp_running	= 0
	    echomsg "[ATP:] ".b:atp_TexCompiler . " is not running"
	endif
    else
	call atplib#LatexRunning()
	if len(b:atp_LatexPIDs) > 0
	    echomsg "[ATP:] ".b:atp_TexCompiler . " pid(s): " . join(b:atp_LatexPIDs, ", ") 
	else
	    let b:atp_LastLatexPID = 0
	    echomsg "[ATP:] ".b:atp_TexCompiler . " is not running"
	endif
    endif
endfunction
"}}}


" This function compares two files: file written on the disk a:file and the current
" buffer
"{{{ s:compare
" relevant variables:
" g:atp_compare_embedded_comments
" g:atp_compare_double_empty_lines
" Problems:
" This function is too slow it takes 0.35 sec on file with 2500 lines.
	" Ideas:
	" Maybe just compare current line!
	" 		(search for the current line in the written
	" 		file with vimgrep)
function! <SID>compare(file)
    let l:buffer=getbufline(bufname("%"),"1","$")

    " rewrite l:buffer to remove all comments 
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

"     This is the way to make it not sensitive on new line signs.
"     let file_j		= join(l:file)
"     let buffer_j	= join(l:buffer)
"     return file_j !=# buffer_j

    return l:file !=# l:buffer
endfunction
" function! s:sompare(file) 
"     return Compare(a:file)
" endfunction
" This is very fast (0.002 sec on file with 2500 lines) 
" but the proble is that vimgrep greps the buffer rather than the file! 
" so it will not indicate any differences.
function! <SID>NewCompare()
    let line 		= getline(".")
    let lineNr		= line(".")
    let saved_loclist 	= getloclist(0)
    try
	exe "lvimgrep /^". escape(line, '\^$') . "$/j " . fnameescape(expand("%:p"))
    catch /E480:/ 
    endtry
"     call setloclist(0, saved_loclist)
    let loclist		= getloclist(0)
    call map(loclist, "v:val['lnum']")
    return !(index(loclist, lineNr)+1)
endfunction

"}}}

" This function copies the file a:input to a:output
"{{{ s:copy
function! <SID>copy(input,output)
	call writefile(readfile(a:input),a:output)
endfunction
"}}}

"{{{ GetSid, SidWrap
function! <SID>GetSid() "{{{
    return matchstr(expand('<sfile>'), '\zs<SNR>\d\+_\ze.*$')
endfunction 
let s:compiler_SID = s:GetSid() "}}}

" Make the SID visible outside the script:
" /used in LatexBox_complete.vim file/
let g:atp_compiler_SID	= { fnamemodify(expand('<sfile>'),':t') : s:compiler_SID }

function! <SID>SidWrap(func) "{{{
    return s:compiler_SID . a:func
endfunction "}}}
" }}}

" This function is called to run TeX compiler and friends as many times as necessary.
" Makes references and bibliographies (supports bibtex), indexes.  
"{{{ MakeLatex
" a:texfile		full path to the tex file
" a:index		0/1
" 			0 - do not check for making index in this run
" 			1 - the opposite
" a:0 == 0 || a:1 == 0 (i.e. the default) not run latex before /this might change in
" 			the future/
" a:1 != 0		run latex first, regardless of the state of log/aux files.			
" 
" 
" The arguments are path to logfile and auxfile.
" To Do: add support for TOC !
" To Do: when I will add proper check if bibtex should be done (by checking bbl file
" or changes in bibliographies in input files), the bang will be used to update/or
" not the aux|log|... files.
" Function Arguments:
" a:texfile		= main tex file to use
" a:did_bibtex		= the number of times bibtex was already done MINUS 1 (should be 0 on start up)
" a:did_index		= 0/1 1 - did index 
" 				/ to make an index it is enough to call: 
" 					latex ; makeindex ; latex	/
" a:time		= []  - it will give time message (only if has("reltime"))
" 			  [0] - no time message.
" a:did_firstrun	= did the first run? (see a:1 below)
" a:run			= should be 1 on invocation: the number of the run
" force			= '!'/'' (see :h bang)
" 				This only makes a difference with bibtex:
" 				    if removed citation to get the right Bibliography you need to use 
" 				    'Force' option in all other cases 'NoForce' is enough (and faster).
" 					
" a:1			= do the first run (by default: NO) - to obtain/update log|aux|idx|toc|... files.
" 				/this is a weak NO: if one of the needed files not
" 				readable it is used/
"
" Some explanation notes:
" 	references		= referes to the bibliography
" 					the pattern to match in log is based on the
" 					phrase: 'Citation .* undefined'
" 	cross_references 	= referes to the internal labels
" 					phrase to check in the log file:
" 					'Label(s) may have changed. Rerun to get cross references right.'
" 	table of contents	= 'No file \f*\.toc' 				

" needs reltime feature (used already in the command)

	" DEBUG:
    	" errorfile /tmp/mk_log
	

function! <SID>MakeLatex(texfile, did_bibtex, did_index, time, did_firstrun, run, force, ...)

    if a:time == [] && has("reltime") && len(a:time) != 1 
	let time = reltime()
    else
	let time = a:time
    endif

    if &filetype == "plaintex"
	echohl WarningMsg
	echo "plaintex is not supported"
	echohl None
	return "plaintex is not supported."
    endif

    " Prevent from infinite loops
    if a:run >= s:runlimit
	echoerr "ATP Error: MakeLatex in infinite loop."
	return "infinte loop."
    endif

    let b:atp_running= a:run == 1 ? b:atp_running+1 : 0
    let runtex_before	= a:0 == 0 || a:1 == 0 ? 0 : 1
    let runtex_before	= runtex_before

	if g:atp_debugML
	    if a:run == 1
		redir! > /tmp/mk_log
	    else
		redir! >> /tmp/mk_log
	    endif
	endif

    for cmd in keys(g:CompilerMsg_Dict) 
	if b:atp_TexCompiler =~ '^\s*' . cmd . '\s*$'
	    let Compiler = g:CompilerMsg_Dict[cmd]
	    break
	else
	    let Compiler = b:atp_TexCompiler
	endif
    endfor

    let compiler_SID 	= s:compiler_SID
    let g:ml_debug 	= ""

    let mode 		= ( g:atp_DefaultDebugMode == 'verbose' ? 'debug' : g:atp_DefaultDebugMode )
    let tex_options	= " -interaction=nonstopmode -output-directory=" . fnameescape(b:atp_OutDir) . " " . substitute(b:atp_TexOptions, ',', ' ', 'g') . " "

    " This supports b:atp_OutDir
    let saved_cwd	= getcwd()
    exe "lcd " . fnameescape(b:atp_OutDir)
    let texfile		= fnamemodify(a:texfile, ":t")
    let logfile		= fnamemodify(texfile, ":r") . ".log"
    let auxfile		= fnamemodify(texfile, ":r") . ".aux"
    let bibfile		= fnamemodify(texfile, ":r") . ".bbl"
    let idxfile		= fnamemodify(texfile, ":r") . ".idx"
    let indfile		= fnamemodify(texfile, ":r") . ".ind"
    let tocfile		= fnamemodify(texfile, ":r") . ".toc"
    let loffile		= fnamemodify(texfile, ":r") . ".lof"
    let lotfile		= fnamemodify(texfile, ":r") . ".lot"
    let thmfile		= fnamemodify(texfile, ":r") . ".thm"

    if b:atp_TexCompiler =~ '^\%(pdflatex\|pdftex\|xetex\|context\|luatex\)$'
	let ext		= ".pdf"
    else
	let ext		= ".dvi"
    endif
    let outfile		= fnamemodify(texfile, ":r") . ext

	if g:atp_debugML
	silent echo a:run . " BEGIN " . strftime("%c")
	silent echo "TEXFILE: ".texfile
	silent echo a:run . " logfile=" . logfile . " " . filereadable(logfile) . " auxfile=" . auxfile . " " . filereadable(auxfile). " runtex_before=" . runtex_before . " a:force=" . a:force
	endif

    let saved_pos	= getpos(".")
    keepjumps call setpos(".", [0,1,1,0])
    keepjumps let stop_line=search('\m\\begin\s*{document}','nW')
    let makeidx		= search('\m^[^%]*\\makeindex', 'n', stop_line)
    keepjumps call setpos(".", saved_pos)
	
    " We use location list which should be restored.
    let saved_loclist	= copy(getloclist(0))

    " grep in aux file for 
    " 'Citation .* undefined\|Rerun to get cross-references right\|Writing index file'
    let saved_llist	= getloclist(0)
"     execute "silent! lvimgrep /Citation\\_s\\_.*\\_sundefined\\|Label(s)\\_smay\\_shave\\_schanged.\\|Writing\\_sindex\\_sfile/j " . fnameescape(logfile)
    try
	execute "silent! lvimgrep /C\\n\\=i\\n\\=t\\n\\=a\\n\\=t\\n\\=i\\n\\=o\\n\\=n\\_s\\_.*\\_su\\n\\=n\\n\\=d\\n\\=e\\n\\=f\\n\\=i\\n\\=n\\n\\=e\\n\\=d\\|L\\n\\=a\\n\\=b\\n\\=e\\n\\=l\\n\\=(\\n\\=s\\n\\=)\\_sm\\n\\=a\\n\\=y\\_sh\\n\\=a\\n\\=v\\n\\=e\\_sc\\n\\=h\\n\\=a\\n\\=n\\n\\=g\\n\\=e\\n\\=d\\n\\=.\\|W\\n\\=r\\n\\=i\\n\\=t\\n\\=i\\n\\=n\\n\\=g\\_si\\n\\=n\\n\\=d\\n\\=e\\n\\=x\\_sf\\n\\=i\\n\\=l\\n\\=e/j ".fnameescape(logfile)
	let location_list	= copy(getloclist(0))
    catch E480:
	let location_list	= []
    endtry
    call setloclist(0, saved_llist)

    " Check references:
	if g:atp_debugML
	silent echo a:run . " location_list=" . string(len(location_list))
	silent echo a:run . " references_list=" . string(len(filter(copy(location_list), 'v:val["text"] =~ "Citation"')))
	endif
    let references	= len(filter(copy(location_list), 'v:val["text"] =~ "Citation"')) == 0 ? 0 : 1 

    " Check what to use to make the 'Bibliography':
    let saved_llist	= getloclist(0)
    try
	execute 'silent! lvimgrep /\\bibdata\s*{/j ' . fnameescape(auxfile)
    catch E480:
    endtry
    " Note: if the auxfile is not there it returns 0 but this is the best method for
    " looking if we have to use 'bibtex' as the bibliography might be not written in
    " the main file.
    let bibtex		= len(getloclist(0)) == 0 ? 0 : 1
    if !bibtex
	let bibtex	= atplib#SearchPackage('biblatex')
    endif
    call setloclist(0, saved_llist)

	if g:atp_debugML
	silent echo a:run . " references=" . references . " bibtex=" . bibtex . " a:did_bibtex=" . a:did_bibtex
	endif

    " Check cross-references:
    let cross_references = len(filter(copy(location_list), 'v:val["text"]=~"Rerun"'))==0?0:1

	if g:atp_debugML
	silent echo a:run . " cross_references=" . cross_references
	endif

    " Check index:
    let idx_cmd	= "" 
    if makeidx

	" The index file is written iff
	" 	1) package makeidx is declared
	" 	2) the preambule contains \makeindex command, then log has a line: "Writing index file"
	" the 'index' variable is equal 1 iff the two conditions are met.
	
	let index	 	= len(filter(copy(location_list), 'v:val["text"] =~ "Writing index file"')) == 0 ? 0 : 1
	if index
	    let idx_cmd		= " makeindex " . idxfile . " ; "
	endif
    else
	let index			= 0
    endif

	if g:atp_debugML
	silent echo a:run . " index=" . index . " makeidx=" . makeidx . " idx_cdm=" . idx_cmd . " a:did_index=" . a:did_index 
	endif

    " Check table of contents:
    let saved_llist	= getloclist(0)
    execute "silent! lvimgrep /\\\\openout\\d\\+/j " . fnameescape(logfile)

    let open_out = map(getloclist(0), "v:val['text']")
    call setloclist(0, saved_llist)

    if filereadable(logfile) && a:force == ""
	let toc		= ( len(filter(deepcopy(open_out), "v:val =~ \"toc\'\"")) ? 1 : 0 )
	let lof		= ( len(filter(deepcopy(open_out), "v:val =~ \"lof\'\"")) ? 1 : 0 )
	let lot		= ( len(filter(deepcopy(open_out), "v:val =~ \"lot\'\"")) ? 1 : 0 )
	let thm		= ( len(filter(deepcopy(open_out), "v:val =~ \"thm\'\"")) ? 1 : 0 )
    else
	" This is not an efficient way and it is not good for long files with input
	" lines and lists in not common position.
	let save_pos	= getpos(".")
	call cursor(1,1)
	let toc		= search('\\tableofcontents', 'nw')
	call cursor(line('$'), 1)
	call cursor(line('.'), col('$'))
	let lof		= search('\\listoffigures', 'nbw') 
	let lot		= search('\\listoffigures', 'nbw') 
	if atplib#SearchPackage('ntheorem')
	    let thm	= search('\\listheorems', 'nbw') 
	else
	    let thm	= 0
	endif
	keepjumps call setpos(".", save_pos)
    endif


	if g:atp_debugML
	silent echo a:run." toc=".toc." lof=".lof." lot=".lot." open_out=".string(open_out)
	endif

    " Run tex compiler for the first time:
    let logfile_readable	= filereadable(logfile)
    let auxfile_readable	= filereadable(auxfile)
    let idxfile_readable	= filereadable(idxfile)
    let tocfile_readable	= filereadable(tocfile)
    let loffile_readable	= filereadable(loffile)
    let lotfile_readable	= filereadable(lotfile)
    let thmfile_readable	= filereadable(thmfile)

    let condition = !logfile_readable || !auxfile_readable || !thmfile_readable && thm ||
		\ ( makeidx && !idxfile_readable ) || 
		\ !tocfile_readable && toc || !loffile_readable && lof || !lotfile_readable && lot || 
		\ runtex_before

	if g:atp_debugML
	silent echo a:run . " log_rea=" . logfile_readable . " aux_rea=" . auxfile_readable . " idx_rea&&mke=" . ( makeidx && idxfile_readable ) . " runtex_before=" . runtex_before 
	silent echo a:run . " Run First " . condition
	endif

    if condition
	if runtex_before
	    " Do not write project script file while saving the file.
	    let atp_ProjectScript	= ( exists("g:atp_ProjectScript") ? g:atp_ProjectScript : -1 )
	    let g:atp_ProjectScript	= 0

	    " disable WriteProjectScript
	    let eventignore = &l:eventignore
	    setl eventignore+=BufWrite
	    w
	    let &l:eventignore = eventignore

	    if atp_ProjectScript == -1
		unlet g:atp_ProjectScript
	    else
		let g:atp_ProjectScript	= atp_ProjectScript
	    endif
	endif
	let did_bibtex	= 0
	let did_index	= 0
	let callback_cmd = v:progname . " --servername " . v:servername . " --remote-expr \"" . compiler_SID . 
		\ "MakeLatex\(\'".fnameescape(texfile)."\', ".did_bibtex.", ".did_index.", [".time[0].",".time[1]."], ".
		\ a:did_firstrun.", ".(a:run+1).", \'".a:force."\'\)\""

	" COMPILATION
	let cmd	= b:atp_TexCompilerVariable . " " . b:atp_TexCompiler . tex_options . fnameescape(atplib#FullPath(texfile)) . " ; " . callback_cmd

	redraw
	echomsg "[MakeLatex:] Updating files [".Compiler."]."
	if g:atp_Compiler == 'python'
	    let p_force= (a:force == "!" ? " --force" : " " )
	    let python_cmd1=g:atp_Python." ".shellescape(globpath(&rtp, "ftplugin/ATP_files/compile_ml.py")). 
			\ " --cmd ".shellescape(b:atp_TexCompiler).
			\ " --bibcmd " . shellescape(b:atp_BibCompiler).
			\ " --file ".shellescape(atplib#FullPath(texfile)).
			\ " --outdir ".shellescape(b:atp_OutDir).
			\ " --run ".a:run." ".p_force.
			\ " --progname ".shellescape(v:progname).
			\ " --servername ".shellescape(v:servername).
			\ " --sid ".shellescape(compiler_SID).
			\ " --time_0 ".shellescape(string(time[0])).
			\ " --time_1 ".shellescape(string(time[1])).
			\ " --nobibtex ".
			\ " --noindex ".
			\ " &"
	    if g:atp_debugML
	    silent echo a:run . " PYTHON_CMD1=".python_cmd1
	    redir END
	    endif

	    call system(python_cmd1)
	else
	" WINDOWS NOT COMPATIBLE
	    if g:atp_debugML
	    silent echo a:run . " BASH_CMD1=".cmd
	    redir END
	    endif

	    call system("(" . cmd . " )&")
	endif
	exe "lcd " . fnameescape(saved_cwd)
	return "Making log file or aux file"
    endif

    " Run tex compiler:
    if a:did_firstrun && !bibtex && a:run == 2
	"Note: in this place we should now correctly if bibtex is in use or not,
	"if not and we did first run we can count it. /the a:did_bibtex variable will
	"not be updated/
	let did_bibtex = a:did_bibtex + 1
    else
	let did_bibtex = a:did_bibtex
    endif
    let bib_condition_force 	= ( (references && !bibtex) || bibtex ) && did_bibtex <= 1  
    let bib_condition_noforce	= ( references 	&& did_bibtex <= 1 )
    let condition_force 	= bib_condition_force 	|| cross_references || index && !a:did_index || 
		\ ( ( toc || lof || lot || thm ) && a:run < 2 )
    let condition_noforce 	= bib_condition_noforce || cross_references || index && !a:did_index || 
		\ ( ( toc || lof || lot || thm ) && a:run < 2 )

	if g:atp_debugML
	silent echo a:run . " Run Second NoForce:" . ( condition_noforce && a:force == "" ) . " Force:" . ( condition_force && a:force == "!" )
	silent echo a:run . " BIBTEX: did_bibtex[updated]=" . did_bibtex . " references=" . references . " CROSSREF:" . cross_references . " INDEX:" . (index  && !a:did_index)
	endif

    if ( condition_force && a:force == "!" ) || ( condition_noforce && a:force == "" )
	  let cmd	= ''
	  let bib_cmd 	= b:atp_BibCompiler.' '.fnameescape(auxfile) . ' ; '
	  let idx_cmd 	= 'makeindex '.fnameescape(idxfile) . ' ; '
	  let message	=   "Making:"
	  if ( bib_condition_force && a:force == "!" ) || ( bib_condition_noforce && a:force == "" )
	      let bib_msg	 = ( bibtex  ? ( did_bibtex == 0 ? " [".b:atp_BibCompiler.",".Compiler."]" : " [".Compiler."]" ) : " [".Compiler."]" )
	      let message	.= " references".bib_msg."," 
	  endif
	  if toc && a:run <= 2
	      let message	.= " toc,"
	  endif
	  if lof && a:run <= 2
	      let message	.= " lof,"
	  endif
	  if lot && a:run <= 2
	      let message	.= " lot,"
	  endif
	  if thm && a:run <= 2
	      let message	.= " theorem list,"
	  endif
	  if cross_references
	      let message	.= " cross-references," 
	  endif
	  if !a:did_index && index && idxfile_readable
	      let message	.= " index [makeindex]." 
	  endif
	  let message	= substitute(message, ',\s*$', '.', '') 
	  let make_bibtex	= " "
	  if !did_bibtex && auxfile_readable && bibtex
	      let cmd		.= bib_cmd . " "
	      let did_bibtex 	+= 1  
	      let make_bibtex	= " --bibtex "
	  else
	      let did_bibtex	+= 1
	  else
	  endif
	  " If index was done:
	  let make_index	= " "
	  if a:did_index
	      let did_index	= 1
	  " If not and should be and the idx_file is readable
	  elseif index && idxfile_readable
	      let cmd		.= idx_cmd . " "
	      let did_index 	= 1
	      let make_index	= " --index "
	  " If index should be done, wasn't but the idx_file is not readable (we need
	  " to make it first)
	  elseif index
	      let did_index	= 0
	  " If the index should not be done:
	  else
	      let did_index	= 1
	  endif
	  let callback_cmd = v:progname . " --servername " . v:servername . " --remote-expr \"" . compiler_SID .
		      \ "MakeLatex\(\'".fnameescape(texfile)."\', ".did_bibtex." , ".did_index.", [".time[0].",".time[1]."], ".
		      \ a:did_firstrun.", ".(a:run+1).", \'".a:force."\'\)\""

	  " COMPILATION
	  let cmd	.= b:atp_TexCompilerVariable . " " . b:atp_TexCompiler . tex_options . fnameescape(atplib#FullPath(texfile)) . " ; " . callback_cmd

	  echomsg "[MakeLatex:] " . message
	  if g:atp_Compiler == 'python'
	      let p_force= (a:force == "!" ? " --force" : " " )
	      let python_cmd2=g:atp_Python." ".shellescape(globpath(&rtp, "ftplugin/ATP_files/compile_ml.py")).
			  \ " --cmd ".shellescape(b:atp_TexCompiler).
			  \ " --bibcmd " . shellescape(b:atp_BibCompiler).
			  \ " --file ".shellescape(atplib#FullPath(texfile)).
			  \ " --outdir ".shellescape(b:atp_OutDir).
			  \ " --run ".a:run.
			  \ " ".p_force.
			  \ " --progname ".shellescape(v:progname).
			  \ " --servername ".shellescape(v:servername).
			  \ " --sid ".shellescape(compiler_SID).
			  \ " --time_0 ".shellescape(string(time[0])).
			  \ " --time_1 ".shellescape(string(time[1])).
			  \ " --did_bibtex ".did_bibtex.
			  \ " --did_index " .did_index." ".
			  \ make_bibtex.
			  \ make_index.
			  \ " &"

	      if g:atp_debugML
	      silent echo a:run . " a:did_bibtex="a:did_bibtex . " did_bibtex=" . did_bibtex
	      silent echo a:run . " make_bib=".make_bib. " make_index=" . make_index
	      silent echo a:run . " PYTHON_CMD2=".python_cmd2
	      redir END
	      endif

	      call system(python_cmd2)

	  else
	      if g:atp_debugML
	      silent echo a:run . " a:did_bibtex="a:did_bibtex . " did_bibtex=" . did_bibtex
	      silent echo a:run . " BASH_CMD2=" . cmd
	      redir END
	      endif

	      call system("(" . cmd . ")&")
	  endif
	  exe "lcd " . fnameescape(saved_cwd)
	  return "Making references|cross-references|index."
    endif

    " Post compeltion works:
	if g:atp_debugML
	silent echo a:run . " END"
	redir END
	endif

    if time != [] && len(time) == 2
	let show_time	= matchstr(reltimestr(reltime(time)), '\d\+\.\d\d')
    endif

    redraw
    if max([(a:run-1), 0]) == 1
	echomsg "[MakeLatex:] " . max([(a:run-1), 0]) . " time in " . show_time . "sec."
    else
	echomsg "[MakeLatex:] " . max([(a:run-1), 0]) . " times in " . show_time . "sec."
    endif

    if b:atp_running >= 1
	let b:atp_running	=  b:atp_running - 1
    endif

    " THIS is a right place to call the viewer to reload the file 
    " and the callback mechanism /debugging stuff/.
    if b:atp_Viewer	== 'xpdf' && s:xpdfpid() != ""
	let pdffile		= fnamemodify(a:texfile, ":r") . ".pdf"
	let Reload_Viewer 	= b:atp_Viewer." -remote ".shellescape(b:atp_XpdfServer)." -reload &"
	call system(Reload_Viewer)
    endif
    exe "lcd " . fnameescape(saved_cwd)
    return "Proper end"
endfunction
"}}}

" This function kills all running latex processes.
" a slightly better approach would be to kill compile.py scripts
"{{{ s:KillAll
" the argument is a list of pids
" a:1 if present supresses a message.
function! <SID>KillAll(pids,...)
    if g:atp_Compiler != 'python'  
	echohl WarningMsg
	echomsg "[ATP:] This works only with python compiler (see :help atp-compile.py)" 
	echohl Normal
	return
    endif
    if len(a:pids) == 0 && a:0 == 0
	echo "[ATP:] No instance of ".get(g:CompilerMsg_Dict,b:atp_TexCompiler,'TeX')." is running."
    endif
python << END
import os, signal
from signal import SIGTERM
pids=vim.eval("a:pids")
for pid in pids:
    try:
	os.kill(int(pid),SIGTERM)
    except OSError, e:
	if e.errno == 3:
            # No such process error.
            pass
	else:
            raise
END
endfunction "}}}

function! <SID>SetBiberSettings()
    if b:atp_BibCompiler !~# '^\s*biber\>'
	return
    elseif !exists("s:biber_keep_done")
	let s:biber_keep_done = 1
	if index(g:keep, "run.xml") == -1
	    g:keep += [ "run.xml" ]
	endif
	if index(g:keep, "bcf") == -1
	    g:keep += [ "bcf" ]
	endif
    endif
endfunction

" THE MAIN COMPILER FUNCTIONs:
" {{{ s:PythonCompiler
function! <SID>PythonCompiler(bibtex, start, runs, verbose, command, filename, bang)

    " Set biber setting on the fly
    call <SID>SetBiberSettings()

    if !has('gui') && a:verbose == 'verbose' && len(b:atp_LatexPIDs) > 0
	redraw!
	echomsg "[ATP:] please wait until compilation stops."
	return

	" This is not working: (I should kill compile.py scripts)
	echomsg "[ATP:] killing all instances of ".get(g:CompilerMsg_Dict,b:atp_TexCompiler,'TeX')
	call <SID>KillAll(b:atp_LatexPIDs,1)
	sleep 1
	PID
    endif

    " Debug varibles
    " On Unix the output of compile.py run by this function is available at
    " /tmp/atp_pc.debug
    if g:atp_debugPythonCompiler
	let g:debugPC_bibtex	=a:bibtex
	let g:debugPC_start	=a:start
	let g:debugPC_runs	=a:runs
	let g:debugPC_verbose	=a:verbose
	let g:debugPC_command	=a:command
	let g:debugPC_filename	=a:filename
	let g:debugPC_bang	=a:bang
    endif

    if t:atp_DebugMode != 'verbose' && a:verbose != 'verbose'
	let b:atp_LastLatexPID = -1
    endif
    
    if t:atp_DebugMode != "silent" && b:atp_TexCompiler !~ "luatex" &&
		\ (b:atp_TexCompiler =~ "^\s*\%(pdf\|xetex\)" && b:atp_Viewer == "xdvi" ? 1 :  
		\ b:atp_TexCompiler !~ "^\s*pdf" && b:atp_TexCompiler !~ "xetex" &&  (b:atp_Viewer == "xpdf" || b:atp_Viewer == "epdfview" || b:atp_Viewer == "acroread" || b:atp_Viewer == "kpdf"))
	 
	echohl WaningMsg | echomsg "[ATP:] your ".b:atp_TexCompiler." and ".b:atp_Viewer." are not compatible:" 
	echomsg "       b:atp_TexCompiler=" . b:atp_TexCompiler	
	echomsg "       b:atp_Viewer=" . b:atp_Viewer	
    endif
    if !has('clientserver')
	if has("win16") || has("win32") || has("win64") || has("win95")
	    echohl WarningMsg
	    echomsg "[ATP:] ATP needs +clientserver vim compilation option."
	    echohl Normal
	else
	    echohl WarningMsg
	    echomsg "[ATP:] python compiler needs +clientserver vim compilation option."
	    echomsg "       falling back to g:atp_Compiler=\"bash\""
	    echohl Normal
	    let g:atp_Compiler = "bash"
	    return
	endif
    endif


    " Set options for compile.py
    let interaction 		= ( a:verbose=="verbose" ? b:atp_VerboseLatexInteractionMode : 'nonstopmode' )
    let tex_options		= shellescape(b:atp_TexOptions.',-interaction='.interaction)
"     let g:tex_options=tex_options
    let ext			= get(g:atp_CompilersDict, matchstr(b:atp_TexCompiler, '^\s*\zs\S\+\ze'), ".pdf") 
    let ext			= substitute(ext, '\.', '', '')

    let global_options 		= exists("g:atp_".matchstr(b:atp_Viewer, '^\s*\zs\S\+\ze')."Options") ? g:atp_{matchstr(b:atp_Viewer, '^\s*\zs\S\+\ze')}Options : ""
    let local_options 		= getbufvar(bufnr("%"), "atp_".matchstr(b:atp_Viewer, '^\s*\zs\S\+\ze')."Options")
    if global_options !=  "" 
	let viewer_options  	= global_options.",".local_options
    else
	let viewer_options  	= local_options
    endif
    let bang 			= ( a:bang == '!' ? ' --bang ' : '' ) 
    let bibtex 			= ( a:bibtex ? ' --bibtex ' : '' )
    let reload_on_error 	= ( b:atp_ReloadOnError ? ' --reload-on-error ' : '' )
    let gui_running 		= ( has("gui_running") ? ' --gui-running ' : '' )
    let reload_viewer 		= ( index(g:atp_ReloadViewers, b:atp_Viewer)+1  ? ' --reload-viewer ' : '' )
    let aucommand 		= ( a:command == "AU" ? ' --aucommand ' : '' )
    let progress_bar 		= ( g:atp_ProgressBar ? '' : ' --no-progress-bar ' )
    let bibliographies 		= join(keys(filter(copy(b:TypeDict), "v:val == 'bib'")), ',')

    " Set the command
    let cmd=g:atp_Python." ".g:atp_PythonCompilerPath." --command ".b:atp_TexCompiler
		\ ." --tex-options ".tex_options
		\ ." --verbose ".a:verbose
		\ ." --file ".shellescape(atplib#FullPath(a:filename))
		\ ." --output-format ".ext
		\ ." --runs ".a:runs
		\ ." --servername ".v:servername
		\ ." --view ".a:start 
		\ ." --viewer ".b:atp_Viewer
		\ ." --xpdf-server ".b:atp_XpdfServer
		\ ." --viewer-options ".shellescape(viewer_options) 
		\ ." --keep ". shellescape(join(g:keep, ','))
		\ ." --progname ".v:progname
		\ ." --bibcommand ".b:atp_BibCompiler
		\ ." --bibliographies ".shellescape(bibliographies)
		\ .(t:atp_DebugMode=='verbose'||a:verbose=='verbose'?' --env ""': " --env ".shellescape(b:atp_TexCompilerVariable))
		\ . bang . bibtex . reload_viewer . reload_on_error . gui_running . aucommand . progress_bar

    " Write file
    let backup=&backup
    let writebackup=&writebackup
    if a:command == "AU"  
	if &backup | setlocal nobackup | endif
	if &writebackup | setlocal nowritebackup | endif
    endif

    " Disable WriteProjectScript
    let eventignore 		= &l:eventignore
    setl eventignore+=BufWrite
    silent! w
    let &l:eventignore 		= eventignore
    if a:command == "AU"  
	let &l:backup		= backup 
	let &l:writebackup 	= writebackup 
    endif
    unlockvar g:atp_TexCommand
    let g:atp_TexCommand	= cmd
    lockvar g:atp_TexCommand

    " Call compile.py
    let b:atp_running += ( a:verbose != "verbose" ?  1 : 0 )
    if a:verbose == "verbose"
	exe ":!".cmd
    elseif g:atp_debugPythonCompiler && has("unix") 
	call system(cmd." 2>/tmp/atp_pc.debug &")
    elseif has("win16") || has("win32") || has("win64")
	call system(cmd)
    else
	call system(cmd." &")
    endif
endfunction
" }}}
" {{{ s:Compiler 
" This is the MAIN FUNCTION which sets the command and calls it.
" NOTE: the <filename> argument is not escaped!
" a:verbose	= silent/verbose/debug
" 	debug 	-- switch to show errors after compilation.
" 	verbose -- show compiling procedure.
" 	silent 	-- compile silently (gives status information if fails)
" a:start	= 0/1/2
" 		1 start viewer
" 		2 start viewer and make reverse search
"
function! <SID>Compiler(bibtex, start, runs, verbose, command, filename, bang)
    
    " Set biber setting on the fly
    call <SID>SetBiberSettings()

    if !has('gui') && a:verbose == 'verbose' && b:atp_running > 0
	redraw!
	echomsg "[ATP:] please wait until compilation stops."
	return
    endif

    if g:atp_debugCompiler
	redir! >> /tmp/ATP_CompilerLog
	silent echomsg "________ATP_COMPILER_LOG_________"
	silent echomsg "changedtick=" . b:changedtick . " atp_changedtick=" . b:atp_changedtick
	silent echomsg "a:bibtex=" . a:bibtex . " a:start=" . a:start . " a:runs=" . a:runs . " a:verbose=" . a:verbose . " a:command=" . a:command . " a:filename=" . a:filename . " a:bang=" . a:bang
	silent echomsg "1 b:changedtick=" . b:changedtick . " b:atp_changedtick" . b:atp_changedtick . " b:atp_running=" .  b:atp_running
    endif

    if has('clientserver') && !empty(v:servername) && g:atp_callback && a:verbose != 'verbose'
	let b:atp_running+=1
    endif
    call atplib#outdir()
    	" IF b:atp_TexCompiler is not compatible with the viewer
	" ToDo: (move this in a better place). (luatex can produce both pdf and dvi
	" files according to options so this is not the right approach.) 
	if t:atp_DebugMode !=? "silent" && b:atp_TexCompiler !~? "luatex" &&
		    \ (b:atp_TexCompiler =~ "^\s*\%(pdf\|xetex\)" && b:atp_Viewer == "xdvi" ? 1 :  
		    \ b:atp_TexCompiler !~ "^\s*pdf" && b:atp_TexCompiler !~ "xetex" &&  (b:atp_Viewer == "xpdf" || b:atp_Viewer == "epdfview" || b:atp_Viewer == "acroread" || b:atp_Viewer == "kpdf"))
	     
	    echohl WaningMsg | echomsg "[ATP:] your ".b:atp_TexCompiler." and ".b:atp_Viewer." are not compatible:" 
	    echomsg "       b:atp_TexCompiler=" . b:atp_TexCompiler	
	    echomsg "       b:atp_Viewer=" . b:atp_Viewer	
	endif

	" there is no need to run more than s:runlimit (=5) consecutive runs
	" this prevents from running tex as many times as the current line
	" what can be done by a mistake using the range for the command.
	if a:runs > s:runlimit
	    let runs = s:runlimit
	else
	    let runs = a:runs
	endif

	let tmpdir=b:atp_TmpDir . matchstr(tempname(), '\/\w\+\/\d\+')
	let tmpfile=atplib#append(tmpdir, "/") . fnamemodify(a:filename,":t:r")
	if exists("*mkdir")
	    call mkdir(tmpdir, "p", 0700)
	else
	    echoerr "Your vim doesn't have mkdir function"
	endif

	" SET THE NAME OF OUTPUT FILES
	" first set the extension pdf/dvi
	let ext	= get(g:atp_CompilersDict, matchstr(b:atp_TexCompiler, '^\s*\zs\S\+\ze'), ".pdf") 

	" check if the file is a symbolic link, if it is then use the target
	" name.
	let link=system("readlink " . a:filename)
	if link != ""
	    let basename=fnamemodify(link,":r")
	else
	    let basename=a:filename
	endif

	" finally, set the output file names. 
	let outfile 	= b:atp_OutDir . fnamemodify(basename,":t:r") . ext
	let outaux  	= b:atp_OutDir . fnamemodify(basename,":t:r") . ".aux"
	let outbbl  	= b:atp_OutDir . fnamemodify(basename,":t:r") . ".bbl"
	let tmpaux  	= fnamemodify(tmpfile, ":r") . ".aux"
	let tmpbbl  	= fnamemodify(tmpfile, ":r") . ".bbl"
	let tmptex  	= fnamemodify(tmpfile, ":r") . ".tex"
	let outlog  	= b:atp_OutDir . fnamemodify(basename,":t:r") . ".log"
	let syncgzfile 	= b:atp_OutDir . fnamemodify(basename,":t:r") . ".synctex.gz"
	let syncfile 	= b:atp_OutDir . fnamemodify(basename,":t:r") . ".synctex"

"	COPY IMPORTANT FILES TO TEMP DIRECTORY WITH CORRECT NAME 
"	except log and aux files.
	let list	= copy(g:keep)
	call filter(list, 'v:val != "log"')
	for i in list
	    let ftc	= b:atp_OutDir . fnamemodify(basename,":t:r") . "." . i
	    if filereadable(ftc)
		call s:copy(ftc,tmpfile . "." . i)
	    endif
	endfor

" 	HANDLE XPDF RELOAD 
	let reload_viewer = ( index(g:atp_ReloadViewers, b:atp_Viewer) == '-1' ? ' --reload-viewer ' : '' )
	if b:atp_Viewer =~ '^\s*xpdf\>' && reload_viewer
	    if a:start
		"if xpdf is not running and we want to run it.
		let Reload_Viewer = b:atp_Viewer . " -remote " . shellescape(b:atp_XpdfServer) . " " . shellescape(outfile) . " ; "
	    else
" TIME: this take 1/3 of time! 0.039
		call <SID>xpdfpid()
		" I could use here <SID>XpdPid(), the reason to not use it is that
		" then there is a way to run ATP without python.
		if s:xpdfpid != ""
		    "if xpdf is running (then we want to reload it).
		    "This is where I use 'ps' command to check if xpdf is
		    "running.
		    let Reload_Viewer = b:atp_Viewer . " -remote " . shellescape(b:atp_XpdfServer) . " -reload ; "
		else
		    "if xpdf is not running (but we do not want
		    "to run it).
		    let Reload_Viewer = " "
		endif
	    endif
	else
	    if a:start
		" if b:atp_Viewer is not running and we want to open it.
		" the name of this variable is not missleading ...
		let Reload_Viewer = b:atp_Viewer . " " . shellescape(outfile) . " ; "
		" If run through RevSearch command use source specials rather than
		" just reload:
		if str2nr(a:start) == 2
		    let synctex		= s:SidWrap('SyncTex')
		    let callback_rs_cmd = v:progname . " --servername " . v:servername . " --remote-expr " . "'".synctex."()' ; "
		    let Reload_Viewer	= callback_rs_cmd
		endif
	    else
		" If b:atp_Viewer is not running then we do not want to
		" open it.
		let Reload_Viewer = " "
	    endif	
	endif
	if g:atp_debugCompiler
	    let g:Reload_Viewer = Reload_Viewer
	endif

" 	IF OPENING NON EXISTING OUTPUT FILE
"	only xpdf needs to be run before (we are going to reload it)
	if a:start && b:atp_Viewer == "xpdf"
	    let xpdf_options	= ( exists("g:atp_xpdfOptions")  ? g:atp_xpdfOptions : "" )." ".getbufvar(0, "atp_xpdfOptions")
	    let start 	= b:atp_Viewer . " -remote " . shellescape(b:atp_XpdfServer) . " " . xpdf_options . " & "
	else
	    let start = ""	
	endif

"	SET THE COMMAND 
	let interaction = ( a:verbose=="verbose" ? b:atp_VerboseLatexInteractionMode : 'nonstopmode' )
	let variable	= ( a:verbose!="verbose" ? substitute(b:atp_TexCompilerVariable, ';', ' ', 'g') : '' ) 
	let comp	= variable . " " . b:atp_TexCompiler . " " . substitute(b:atp_TexOptions, ',', ' ','g') . " -interaction=" . interaction . " -output-directory=" . shellescape(tmpdir) . " " . shellescape(a:filename)
	let vcomp	= variable . " " . b:atp_TexCompiler . " " . substitute(b:atp_TexOptions, ',', ' ','g')  . " -interaction=". interaction . " -output-directory=" . shellescape(tmpdir) .  " " . shellescape(a:filename)
	
	" make function:
" 	let make	= "vim --servername " . v:servername . " --remote-expr 'MakeLatex\(\"".tmptex."\",1,0\)'"

	if a:verbose == 'verbose' 
	    let texcomp=vcomp
	else
	    let texcomp=comp
	endif
	if runs >= 2 && a:bibtex != 1
	    " how many times we want to call b:atp_TexCompiler
	    let i=1
	    while i < runs - 1
		let i+=1
		let texcomp=texcomp . " ; " . comp
	    endwhile
	    if a:verbose != 'verbose'
		let texcomp=texcomp . " ; " . comp
	    else
		let texcomp=texcomp . " ; " . vcomp
	    endif
	endif
	
	if a:bibtex == 1
	    " this should be decided using the log file as well.
	    if filereadable(outaux)
" 		call s:copy(outaux,tmpfile . ".aux")
		let texcomp="bibtex " . shellescape(fnamemodify(outaux, ":t")) . "; ".g:atp_cpcmd." ".shellescape(outbbl)." ".shellescape(tmpbbl).";" . comp . "  1>/dev/null 2>&1 "
	    else
		let texcomp=comp.";clear;".g:atp_cpcmd." ".shellescape(tmpaux)." ".shellescape(outaux)."; bibtex ".shellescape(fnamemodify(outaux, ":t")).";".g:atp_cpcmd." ".shellescape(outbbl)." ".shellescape(tmpbbl)."; ".comp." 1>/dev/null 2>&1 "
	    endif
	    if a:verbose != 'verbose'
		let texcomp=texcomp . " ; " . comp
	    else
		let texcomp=texcomp . " ; " . vcomp
	    endif
	endif

	" catch the status
	if has('clientserver') && v:servername != "" && g:atp_callback == 1

	    let catchstatus_cmd = v:progname . ' --servername ' . v:servername . ' --remote-expr ' . 
			\ shellescape('atplib#TexReturnCode')  . '\($?\) ; ' 
	else
	    let catchstatus_cmd = ''
	endif

	" copy output file (.pdf\|.ps\|.dvi)
	let cpoptions	= "--remove-destination"
	let cpoutfile	= g:atp_cpcmd." ".cpoptions." ".shellescape(atplib#append(tmpdir,"/"))."*".ext." ".shellescape(atplib#append(b:atp_OutDir,"/"))." ; "

	if a:start
	    let command	= "(" . texcomp . " ; (" . catchstatus_cmd . " " . cpoutfile . " " . Reload_Viewer . " ) || ( ". catchstatus_cmd . " " . cpoutfile . ") ; " 
	else
	    " 	Reload on Error:
	    " 	for xpdf it copies the out file but does not reload the xpdf
	    " 	server for other viewers it simply doesn't copy the out file.
	    if b:atp_ReloadOnError || a:bang == "!"
		if a:bang == "!"
		    let command="( ".texcomp." ; ".catchstatus_cmd." ".g:atp_cpcmd." ".cpoptions." ".shellescape(tmpaux)." ".shellescape(b:atp_OutDir)." ; ".cpoutfile." ".Reload_Viewer 
		else
		    let command="( (".texcomp." && ".g:atp_cpcmd." ".cpoptions." ".shellescape(tmpaux)." ".shellescape(b:atp_OutDir)." ) ; ".catchstatus_cmd." ".cpoutfile." ".Reload_Viewer 
		endif
	    else
		if b:atp_Viewer =~ '\<xpdf\>'
		    let command="( ".texcomp." && (".catchstatus_cmd.cpoutfile." ".Reload_Viewer." ".g:atp_cpcmd." ".cpoptions." ".shellescape(tmpaux)." ".shellescape(b:atp_OutDir)." ) || (".catchstatus_cmd." ".cpoutfile.") ; " 
		else
		    let command="(".texcomp." && (".catchstatus_cmd.cpoutfile." ".Reload_Viewer." ".g:atp_cpcmd." ".cpoptions." ".shellescape(tmpaux)." ".shellescape(b:atp_OutDir)." ) || (".catchstatus_cmd.") ; " 
		endif
	    endif
	endif

    if g:atp_debugCompiler
	silent echomsg "Reload_Viewer=" . Reload_Viewer
	let g:Reload_Viewer 	= Reload_Viewer
	let g:command		= command
    elseif g:atp_debugCompiler >= 2 
	silent echomsg "command=" . command
    endif

	" Preserve files with extension belonging to the g:keep list variable.
	let copy_cmd=""
	let j=1
	for i in filter(copy(g:keep), 'v:val != "aux"') 
" ToDo: this can be done using internal vim functions.
	    let copycmd=g:atp_cpcmd." ".cpoptions." ".shellescape(atplib#append(tmpdir,"/")).
			\ "*.".i." ".shellescape(atplib#append(b:atp_OutDir,"/")) 
	    if j == 1
		let copy_cmd=copycmd
	    else
		let copy_cmd=copy_cmd . " ; " . copycmd	  
	    endif
	    let j+=1
	endfor
	if g:atp_debugCompiler
	    let g:copy_cmd = copy_cmd
	endif
	let command=command . " " . copy_cmd . " ; " 

	" Callback:
	if has('clientserver') && v:servername != "" && g:atp_callback == 1

" 	    let callback	= s:SidWrap('CallBack')
	    let callback_cmd 	= v:progname . ' --servername ' . v:servername . ' --remote-expr ' . 
				    \ shellescape('atplib#CallBack').'\(\"'.a:verbose.'\",\"'.a:command.'\",\"'.a:bibtex.'\"\)'. " ; "

	    let command = command . " " . callback_cmd

	endif

    if g:atp_debugCompiler
	silent echomsg "callback_cmd=" . callback_cmd
    endif

 	let rmtmp="rm -rf " . shellescape(tmpdir) . "; "
	let command=command . " " . rmtmp . ") &"

	if str2nr(a:start) != 0 
	    let command=start . command
	endif

	" Take care about backup and writebackup options.
	let backup=&backup
	let writebackup=&writebackup
	if a:command == "AU"  
	    if &backup || &writebackup | setlocal nobackup | setlocal nowritebackup | endif
	endif
" This takes lots of time! 0.049s (more than 1/3)	
    if g:atp_debugCompiler
	silent echomsg "BEFORE WRITING: b:changedtick=" . b:changedtick . " b:atp_changedtick=" . b:atp_changedtick . " b:atp_running=" .  b:atp_running
    endif

	" disable WriteProjectScript
	let eventignore = &l:eventignore
	setl eventignore+=BufWrite
	silent! w
	let &l:eventignore = eventignore
" 	let b:atp_changedtick += 1
    if g:atp_debugCompiler
	silent echomsg "AFTER WRITING: b:changedtick=" . b:changedtick . " b:atp_changedtick=" . b:atp_changedtick . " b:atp_running=" .  b:atp_running
    endif

	if a:command == "AU"  
	    let &l:backup=backup 
	    let &l:writebackup=writebackup 
	endif

	if a:verbose != 'verbose'
" "cd ".shellescape(tmpdir).";".
	    let g:atp_TexOutput=system(command)
	else
	    let command="!clear;" . texcomp . " " . cpoutfile . " " . copy_cmd
	    exe command
	endif

	unlockvar g:atp_TexCommand
	let g:atp_TexCommand=command
	lockvar g:atp_TexCommand

    if g:atp_debugCompiler
	silent echomsg "command=" . command
	redir END
    endif
endfunction
"}}}

" AUTOMATIC TEX PROCESSING:
" {{{ s:auTeX
" This function calls the compilers in the background. It Needs to be a global
" function (it is used in options.vim, there is a trick to put function into
" a dictionary ... )
augroup ATP_changedtick
    au!
    au BufEnter 	*.tex 	:let b:atp_changedtick = b:changedtick
    au BufWritePost 	*.tex 	:let b:atp_changedtick = b:changedtick
augroup END 

function! <SID>auTeX()


    " Using vcscommand plugin the diff window ends with .tex thus the autocommand
    " applies but the filetype is 'diff' thus we can switch tex processing by:
    if &l:filetype !~ "tex$"
	return "wrong file type"
    endif

    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)

    let mode 	= ( g:atp_DefaultDebugMode == 'verbose' ? 'debug' : g:atp_DefaultDebugMode )

    if !b:atp_autex
       return "autex is off"
    endif

    " if the file (or input file is modified) compile the document 
    if filereadable(expand("%"))
	if g:atp_Compare == "changedtick"
	    let cond = ( b:changedtick != b:atp_changedtick )
	else
	    let cond = ( s:compare(readfile(expand("%"))) )
	endif
	if cond
	    " This is for changedtick only
	    let b:atp_changedtick = b:changedtick + 1
	    " +1 because s:Compiler saves the file what increases b:changedtick by 1.
	    " this is still needed as I use not nesting BufWritePost autocommand to set
	    " b:atp_changedtick (by default autocommands do not nest). Alternate solution is to
	    " run s:AuTeX() with nested autocommand (|autocmd-nested|). But this seems
	    " to be less user friendly, nested autocommands allows only 10 levels of
	    " nesting (which seems to be high enough).
	    
"
" 	if <SID>NewCompare()
	    if g:atp_Compiler == 'python'
		call <SID>PythonCompiler(0, 0, b:atp_auruns, mode, "AU", atp_MainFile, "")
	    else
		call <SID>Compiler(0, 0, b:atp_auruns, mode, "AU", atp_MainFile, "")
	    endif
	    redraw
	    return "compile" 
	endif
    " if compiling for the first time
    else
	try 
	    " Do not write project script file while saving the file.
	    let atp_ProjectScript	= ( exists("g:atp_ProjectScript") ? g:atp_ProjectScript : -1 )
	    let g:atp_ProjectScript	= 0
	    w
	    if atp_ProjectScript == -1
		unlet g:atp_ProjectScript
	    else
		let g:atp_ProjectScript	= atp_ProjectScript
	    endif
	catch /E212:/
	    echohl ErrorMsg
	    echomsg expand("%") . "E212: Cannon open file for writing"
	    echohl Normal
	    return " E212"
	catch /E382:/
	    " This option can be set by VCSCommand plugin using VCSVimDiff command
	    return " E382"
	endtry
	if g:atp_Compiler == 'python'
	    call <SID>PythonCompiler(0, 0, b:atp_auruns, mode, "AU", atp_MainFile, "")
	else
	    call <SID>Compiler(0, 0, b:atp_auruns, mode, "AU", atp_MainFile, "")
	endif
	redraw
	return "compile for the first time"
    endif
    return "files does not differ"
endfunction

" This is set by SetProjectName (options.vim) where it should not!
augroup ATP_auTeX
    au!
    au CursorHold 	*.tex call s:auTeX()
    if g:atp_updatetime_insert
	au CursorHoldI 	*.tex call s:auTeX()
    endif
augroup END 
"}}}

" Related Functions
" {{{ TeX

" a:runs	= how many consecutive runs
" a:1		= one of 'default','silent', 'debug', 'verbose'
" 		  if not specified uses 'default' mode
" 		  (g:atp_DefaultDebugMode).
function! <SID>TeX(runs, bang, ...)

    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)

"     echomsg "TEX_1 CHANGEDTICK=" . b:changedtick . " " . b:atp_running

    if a:0 >= 1
	let mode = ( a:1 != 'default' ? a:1 : t:atp_DebugMode )
    else
	let mode = t:atp_DebugMode
    endif

    if mode =~# '^s\%[ilent]$'
	let mode = 'silent'
    elseif mode =~# '^d\%[ebug]$'
	let mode = 'debug'
    elseif mode =~# 'D\%[ebug]$'
	let mode = 'Debug'
    elseif mode =~#  '^v\%[erbose]$'
	let mode = 'verbose'
    else
	let mode = t:atp_DebugMode
    endif

    for cmd in keys(g:CompilerMsg_Dict) 
	if b:atp_TexCompiler =~ '^\s*' . cmd . '\s*$'
	    let Compiler = g:CompilerMsg_Dict[cmd]
	    break
	else
	    let Compiler = b:atp_TexCompiler
	endif
    endfor

"     echomsg "TEX_2 CHANGEDTICK=" . b:changedtick . " " . b:atp_running

    if l:mode != 'silent'
	if a:runs > 2 && a:runs <= 5
	    echo "[ATP:] ".Compiler . " will run " . a:1 . " times."
	elseif a:runs == 2
	    echo "[ATP:] ".Compiler . " will run twice."
	elseif a:runs == 1
	    echo "[ATP:] ".Compiler . " will run once."
	elseif a:runs > 5
	    echo "[ATP:] ".Compiler . " will run " . s:runlimit . " times."
	endif
    endif
    if g:atp_Compiler == 'python'
	call <SID>PythonCompiler(0,0, a:runs, mode, "COM", atp_MainFile, a:bang)
    else
	call <SID>Compiler(0,0, a:runs, mode, "COM", atp_MainFile, a:bang)
    endif
endfunction
" command! -buffer -count=1	VTEX		:call <SID>TeX(<count>, 'verbose') 
noremap <silent> <Plug>ATP_TeXCurrent		:<C-U>call <SID>TeX(v:count1, "", t:atp_DebugMode)<CR>
noremap <silent> <Plug>ATP_TeXDefault		:<C-U>call <SID>TeX(v:count1, "", 'default')<CR>
noremap <silent> <Plug>ATP_TeXSilent		:<C-U>call <SID>TeX(v:count1, "", 'silent')<CR>
noremap <silent> <Plug>ATP_TeXDebug		:<C-U>call <SID>TeX(v:count1, "", 'Debug')<CR>
noremap <silent> <Plug>ATP_TeXdebug		:<C-U>call <SID>TeX(v:count1, "", 'debug')<CR>
noremap <silent> <Plug>ATP_TeXVerbose		:<C-U>call <SID>TeX(v:count1, "", 'verbose')<CR>
inoremap <silent> <Plug>iATP_TeXVerbose		<Esc>:<C-U>call <SID>TeX(v:count1, "", 'verbose')<CR>
"}}}
"{{{ Bibtex
function! <SID>SimpleBibtex()
    let bibcommand 	= b:atp_BibCompiler." "
    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)
    if b:atp_BibCompiler =~ '^\s*biber\>'
	let file	= fnamemodify(resolve(atp_MainFile),":t:r")
    else
	let file	= fnamemodify(resolve(atp_MainFile),":t:r") . ".aux"
    endif
    let auxfile	= fnamemodify(resolve(atp_MainFile),":t:r") . ".aux"
    " When oupen_out = p (in texmf.cnf) bibtex can only open files in the working
    " directory and they should no be given with full path:
    "  		p (paranoid)   : as `r' and disallow going to parent directories, and
    "                  		 restrict absolute paths to be under $TEXMFOUTPUT.
    let saved_cwd	= getcwd()
    exe "lcd " . fnameescape(b:atp_OutDir)
    let g:cwd = getcwd()
    if filereadable(auxfile)
	let command	= bibcommand . shellescape(file)
	let b:atp_BibtexOutput=system(command)
	let b:atp_BibtexReturnCode=v:shell_error
	echo b:atp_BibtexOutput
    else
	echo "[ATP:] aux file " . auxfile . " not readable."
    endif
    exe "lcd " . fnameescape(saved_cwd)
endfunction
nnoremap <silent> <Plug>SimpleBibtex	:call <SID>SimpleBibtex()<CR>

function! <SID>Bibtex(bang, ...)
    if a:0 >= 1 && a:1 =~# '^o\%[utput]$'
	redraw!
	if exists("b:atp_BibtexReturnCode")
	    echo "[Bib:] BibTeX returned with exit code " . b:atp_BibtexReturnCode
	endif
	if exists("b:atp_BibtexOutput")
	    echo substitute(b:atp_BibtexOutput, '\(^\zs\|\n\)', '\1       ', "g")
	else
	    echo "No BibiTeX output."
	endif
	return
    elseif a:bang == ""
	call <SID>SimpleBibtex()
	return
    endif

    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)
    let g:a=a:0

    if a:0 >= 1
	let mode = ( a:1 != 'default' ? a:1 : t:atp_DebugMode )
    else
	let mode = t:atp_DebugMode
    endif

    if mode =~# '^s\%[ilent]$'
	let mode = 'silent'
    elseif mode =~# '^d\%[ebug]$'
	let mode = 'debug'
    elseif mode =~# 'D\%[ebug]$'
	let mode = 'Debug'
    elseif mode =~#  '^v\%[erbose]$'
	let mode = 'verbose'
    else
	let mode = t:atp_DebugMode
    endif

    if g:atp_Compiler == 'python'
	call <SID>PythonCompiler(1, 0, 0, mode, "COM", atp_MainFile, "")
    else
	call <SID>Compiler(1, 0, 0, mode, "COM", atp_MainFile, "")
    endif
endfunction
function! BibtexComp(A,L,P)
	return "silent\ndebug\nDebug\nverbose\noutput"
endfunction
nnoremap <silent> <Plug>SimpleBibtex	:call <SID>Bibtex("")<CR>
nnoremap <silent> <Plug>BibtexDefault	:call <SID>Bibtex("!", "default")<CR>
nnoremap <silent> <Plug>BibtexSilent	:call <SID>Bibtex("!", "silent")<CR>
nnoremap <silent> <Plug>Bibtexdebug	:call <SID>Bibtex("!", "debug")<CR>
nnoremap <silent> <Plug>BibtexDebug	:call <SID>Bibtex("!", "Debug")<CR>
nnoremap <silent> <Plug>BibtexVerbose	:call <SID>Bibtex("!", "verbose")<CR>
"}}}

" Show Errors Function
" (some error tools are in various.vim: ':ShowErrors o')
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
function! <SID>SetErrorFormat(...)

    let l:cgetfile = ( a:0 >=2 ? a:2 : 0 )
    " This l:cgetfile == 1 only if run by the command :ErrorFormat 
    if l:cgetfile  == 1 && a:1 == ''	
	echo "[ATP:] current error format: ".b:atp_ErrorFormat 
	return
    endif

    let carg = ( a:0 == 0 ? g:atp_DefaultErrorFormat : a:1 )
    let b:atp_ErrorFormat = carg
    let g:carg = carg." a:1=".a:1

    let &l:errorformat=""
    if ( carg =~ 'e' || carg =~# 'all' ) 
	if &l:errorformat == ""
	    let &l:errorformat= "%E!\ LaTeX\ %trror:\ %m,\%E!\ %m,%E!pdfTeX %trror:\ %m"
	else
	    let &l:errorformat= &l:errorformat . ",%E!\ LaTeX\ %trror:\ %m,\%E!\ %m,%E!pdfTeX %trror:\ %m"
	endif
    endif
    if ( carg =~ 'w' || carg =~# 'all' )
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
    if ( carg =~ '\Cc' || carg =~# 'all' )
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
    if ( carg =~ '\Cr' || carg =~# 'all' )
	if &l:errorformat == ""
	    let &l:errorformat = "%WLaTeX\ Warning:\ Reference %m on\ input\ line\ %l%.%#,%WLaTeX\ %.%#Warning:\ Reference %m,%C %m on input line %l%.%#"
	else
	    let &l:errorformat = &l:errorformat . ",%WLaTeX\ Warning:\ Reference %m on\ input\ line\ %l%.%#,%WLaTeX\ %.%#Warning:\ Reference %m,%C %m on input line %l%.%#"
	endif
    endif
    if carg =~ '\Cf'
	if &l:errorformat == ""
	    let &l:errorformat = "%WLaTeX\ Font\ Warning:\ %m,%Z(Font) %m on input line %l%.%#"
	else
	    let &l:errorformat = &l:errorformat . ",%WLaTeX\ Font\ Warning:\ %m,%Z(Font) %m on input line %l%.%#"
	endif
    endif
    if carg =~ '\Cfi'
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
    if carg =~ '\CF'
	if &l:errorformat == ""
	    let &l:errorformat = 'File: %m'
	else
	    let &l:errorformat = &l:errorformat . ',File: %m'
	endif
    endif
    if carg =~ '\Cp'
	if &l:errorformat == ""
	    let &l:errorformat = 'Package: %m'
	else
	    let &l:errorformat = &l:errorformat . ',Package: %m'
	endif
    endif
    if &l:errorformat != ""

	let pm = ( g:atp_show_all_lines == 1 ? '+' : '-' )

	let l:dont_ignore = 0
	if carg =~ '\CA\cll'
	    let l:dont_ignore = 1
	    let pm = '+'
	endif

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
    if l:cgetfile
	try
	    cgetfile
	catch E40:
	endtry
    endif
endfunction
"}}}
"{{{ ShowErrors
" each argument can be a word in flags as for s:SetErrorFormat (except the
" word 'whole') + two other flags: all (include all errors) and ALL (include
" all errors and don't ignore any line - this overrides the variables
" g:atp_ignore_unmatched and g:atp_show_all_lines.
function! ShowErrors(...)
    " It is not <SID> because it is run from atplib#CallBack()

    let errorfile	= &l:errorfile
    " read the log file and merge warning lines 
    " filereadable doesn't like shellescaped file names not fnameescaped. 
    " The same for readfile() and writefile()  built in functions.
    if !filereadable(errorfile)
	echohl WarningMsg
	echo "[ATP:] no error file: " . errorfile  
	echohl Normal
	return
    endif

    let log=readfile(errorfile)

    let nr=1
    for line in log
	if line =~ "LaTeX Warning:" && log[nr] !~ "^$" 
	    let newline=line . log[nr]
	    let log[nr-1]=newline
	    call remove(log,nr)
	endif
	let nr+=1
    endfor
    call writefile(log, errorfile)
    
    " set errorformat 
    let l:arg = ( a:0 >= 1 ? a:1 : b:atp_ErrorFormat )

    if l:arg =~ 'o'
	OpenLog
	return
    elseif l:arg =~ 'b'
	echo b:atp_BibtexOutput
	return
    endif
    call s:SetErrorFormat(l:arg)
    let show_message = ( a:0 >= 2 ? a:2 : 1 )

    " read the log file
    cg

    " final stuff
    if len(getqflist()) == 0 
	if show_message
	    echo "[ATP:] no errors :)"
	endif
	return ":)"
    else
	cl
	return 1
    endif
endfunction
"}}}
if !exists("*ListErrorsFlags")
function! ListErrorsFlags(A,L,P)
    return "all\nAll\nc\ne\nF\nf\nfi\no\nr\nw\nb"
endfunction
endif
if !exists("*ListErrorsFlags_A")
function! ListErrorsFlags_A(A,L,P)
    " This has no o flag.
    return "all\nAll\nc\ne\nF\nf\nfi\nr\nw\nb"
endfunction
endif
"}}}
" function! <SID>SetErrorFormat(efm)
" 
"     if a:efm == ""
" 	return
"     endif
" 
"     unlockvar b:atp_ErrorFormat
"     let b:atp_ErrorFormat = a:efm
"     cgetfile
" 
" endfunction

endif "}}}

" Commands: 
" {{{
command! -buffer 		KillAll			:call <SID>KillAll(b:atp_LatexPIDs)
command! -buffer -nargs=? 	ViewOutput		:call <SID>ViewOutput(<f-args>)
command! -buffer 		SyncTex			:call <SID>SyncTex(0)
command! -buffer 		PID			:call <SID>GetPID()
command! -buffer -bang 		MakeLatex		:call <SID>SetBiberSettings() | call <SID>MakeLatex(( g:atp_RelativePath ? globpath(b:atp_ProjectDir, fnamemodify(b:atp_MainFile, ":t")) : b:atp_MainFile ), 0,0, [],1,1,<q-bang>,1)
command! -buffer -nargs=? -bang -count=1 -complete=custom,DebugComp TEX	:call <SID>TeX(<count>, <q-bang>, <f-args>)
command! -buffer -count=1	DTEX			:call <SID>TeX(<count>, <q-bang>, 'debug') 
command! -buffer -bang -nargs=? -complete=custom,BibtexComp Bibtex		:call <SID>Bibtex(<q-bang>, <f-args>)
command! -buffer -nargs=? -complete=custom,ListErrorsFlags_A SetErrorFormat 	:call <SID>SetErrorFormat(<f-args>,1)
augroup ATP_QuickFixCmds_1
    au!
    au FileType qf command! -buffer -nargs=? -complete=custom,ListErrorsFlags_A SetErrorFormat :call <SID>SetErrorFormat(<q-args>,1) | cg
    au FileType qf command! -buffer -nargs=? -complete=custom,ListErrorsFlags_A ErrorFormat :call <SID>SetErrorFormat(<q-args>,1) | cg
    au FileType qf command! -buffer -nargs=? -complete=custom,ListErrorsFlags_A ShowErrors :call <SID>SetErrorFormat(<f-args>) | cg
augroup END
command! -buffer -nargs=? -complete=custom,ListErrorsFlags_A 	ErrorFormat 	:call <SID>SetErrorFormat(<q-args>,1)
exe "SetErrorFormat ".g:atp_DefaultErrorFormat
command! -buffer -nargs=? -complete=custom,ListErrorsFlags 	ShowErrors 	:call ShowErrors(<f-args>)
" }}}
" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
