" Author: M. Szamotulski
" Description: 	A vim script which stores values of variables in a history file.
" 		It is read, updated and written (two last via autocommands,
" 		first on sturup).

" History File ftplugin/ATP_fiels/atp_history.vim
 
" History Related Variables:
" Variables {{{1

let s:file	= expand('<sfile>:p')

" This gives some debug info: which history files are loaded, loading time,
" which history files are written.
" Debug File: /tmp/ATP_HistoryDebug.vim  / only for s:WriteHistory() /
" let g:atp_debugHistory = 1
" Also can be set in vimrc file or atprc file! (tested)
" The default value (0) is set in options.vim

" Windows version:
let s:windows	= has("win16") || has("win32") || has("win64") || has("win95")

" This variable is set if the history was loaded by s:LoadHistory()
" function.
" s:history_Load = { type : 0/1 }

if !exists("s:history_Load")
    " Load once in s:LoadHistory() function
    let s:history_Load	= {}
    let g:history_Load	= s:history_Load
endif
" if !exists("s:history_Write")
"     let s:history_Write	= {}
" endif
if !exists("g:atp_history_dir")
    let g:atp_history_dir	= s:windows ? expand('<sfile>:p:h') . '\' . 'history' : expand('<sfile>:p:h') . '/' . 'history'
endif
if !isdirectory(g:atp_history_dir)
    " Make history dir if it doesn't exist (and all intermediate directories).
    call mkdir(g:atp_history_dir, "p")
endif

" Mimic names of vim view files
let s:history_fname 	= substitute(expand("%:p"), '\s\|\\\|\/', '=\+', 'g') . "=.vim"
"     let g:history_fname = s:history_fname
let s:history_file 	= s:windows ? g:atp_history_dir  . '\' . s:history_fname : g:atp_history_dir . '/' . s:history_fname
let s:common_history_file	= s:windows ? g:atp_history_dir  . '\common_var.vim' : g:atp_history_dir . '/common_var.vim' 

" These local variables will be saved:
let g:atp_cached_local_variables = [ 'atp_MainFile', 'atp_History', 'atp_LocalCommands', 'atp_LocalColors', 'atp_LocalEnvironments', 'TreeOfFiles', 'ListOfFiles', 'TypeDict', 'LevelDict']
" b:atp_PackageList is another variable that could be put into history file.

" This are common variable to all tex files.
let g:atp_cached_common_variables = ['atp_latexpackages', 'atp_latexclasses', 'atp_Library']
" }}}1

" Load History:
 "{{{1 s:LoadHistory(), :LoadHistory, autocommads
" s:LoadHistory({bang}, {history_file}, {type}, {load_variables}, [silent], [ch_load])
"
" a:bang == "!" ignore texmf tree and ignore b:atp_History, g:atp_History
" variables
" a:history_file	file to source 
" a:type = 'local'/'global'
" a:load_variabels	load variables after loading history	
" 			can be used on startup to load variables which depend
" 			on things set in history file.
" a:1 = 'silent'/'' 	echo messages
" a:2 = ch_load		check if history was already loaded
" a:3 = ignore		ignore b:atp_History and g:atp_History variables
" 				used by commands
function! <SID>LoadHistory(bang, history_file, type, load_variables, ...)

    if g:atp_debugHistory
	redir! >> /tmp/ATP_HistoryDebug.vim
	let hist_time	= reltime()
	echomsg "\n"
	echomsg "ATP_History: LoadHistory " . a:type
    endif

    let silent	= a:0 >= 1 ? a:1 : "0"
    let silent 	= silent || silent == "silent" ? "silent" : ""
    let ch_load = a:0 >= 2 ? a:2 : 0 
    let ignore	= a:0 >= 3 ? a:3 : 0

    " Is history on/off
    " The local variable overrides the global ones!
    if !ignore && ( exists("b:atp_History") && !b:atp_History || exists("g:atp_History") && ( !g:atp_History && (!exists("b:atp_History") || exists("b:atp_History") && !b:atp_History )) )
	exe silent . ' echomsg "ATP LoadHistory: not loading history file."'
	silent echomsg "b:atp_History=" . ( exists("b:atp_History") ? b:atp_History : -1 ) . " g:atp_History=" . ( exists("g:atp_History") ? g:atp_History : -1 ) . "\n"

	if g:atp_debugHistory
	    redir END
	endif
	return
    endif

    " Load once feature (if ch_load)	- this is used on starup
    if ch_load && get(get(s:history_Load, expand("%:p"), []), a:type, 0) >= 1
	echomsg "History " . a:type . " already loaded for this buffer."
	if g:atp_debugHistory
	    redir END
	endif
	return
    endif

    let cond_A	= get(s:history_Load, expand("%:p"), 0)
    let cond_B	= get(get(s:history_Load, expand("%:p"), []), a:type, 0)
    if cond_B
	let s:history_Load[expand("%:p")][a:type][0] += 1 
    elseif cond_A
	let s:history_Load[expand("%:p")] =  { a:type : 1 }
    else
	let s:hisotory_Load= { expand("%:p") : { a:type : 1 } }
    endif

    if a:bang == "" && expand("%:p") =~ 'texmf' 
	if g:atp_debugHistory
	    redir END
	endif
	return
    endif

    let b:atp_histloaded=1
    if a:type == "local"
	let save_loclist = getloclist(0)
	try
	    silent exe 'lvimgrep /\Clet\s\+b:atp_History\s*=/j ' . a:history_file
	catch /E480: No match:/
	endtry
	let loclist = getloclist(0)
	call setloclist(0, save_loclist)
	execute get(get(loclist, 0, {}), 'text', "")
	if exists("b:atp_History") && !b:atp_History
	    if g:atp_debugHistory
		silent echomsg "ATP_History: b:atp_History == 0 in the history file."
		redir END
	    endif
	    return
	endif
    endif

    " Load first b:atp_History variable
    try
	if filereadble(a:history_file)
	    execute " source " . a:history_file
	endif

	if g:atp_debugHistory
	    echomsg "ATP_History: sourcing " . a:history_file
	endif
    catch /E484: Cannot open file/
    endtry

    if g:atp_debugHistory
	echomsg "ATP_History: sourcing time: " . reltimestr(reltime(hist_time))
	redir! END
    endif

    if a:load_variables
	if !exists("b:atp_project")
	    if exists("b:LevelDict") && max(values(filter(deepcopy(b:LevelDict), "get(b:TypeDict, v:key, '')=='input'"))) >= 1
		let b:atp_project	= 1
	    else
		let b:atp_project 	= 0
	    endif
	endif
    endif
endfunction
command! -buffer -bang LoadHistory		:call s:LoadHistory(<q-bang>,s:history_file, 'local', 0, '', 0, 1)
command! -buffer -bang LoadCommonHistory	:call s:LoadHistory(<q-bang>,s:common_history_file, 'global', 0, '', 1)
" au VimEnter *.tex :call s:LoadHistory()
augroup ATP_LoadHistory "{{{2
    au BufEnter *.tex :call s:LoadHistory("", s:history_file, 'local', 1, 'silent', 1)
    au BufEnter *.tex :call s:LoadHistory("", s:common_history_file, 'global', 0, 'silent',1)
augroup END
"}}}1
" Write History:
"{{{1 s:WriteHistory(), :WriteHistory, autocommands
function! <SID>WriteHistory(bang, history_file, cached_variables, type)
    let prefix = ( a:type == 'global' ? 'g:' : 'b:' )

    if g:atp_debugHistory
	echomsg "\n"
	redir! >> /tmp/ATP_HistoryDebug.vim
	echomsg "ATP_History: WriteHistory " . a:type
	let time = reltime()
    endif

    " If none of the variables exists -> return
    let exists=max(map(deepcopy(a:cached_variables), "exists(prefix . v:val)")) 
    if !exists
	if g:atp_debugHistory
	    echomsg "no variable exists"
	endif
	return
    endif

    if a:bang == "" && expand("%:p") =~ 'texmf'
	if g:atp_debugHistory
	    echomsg "texmf return"
	endif
	return
    endif

    " a:bang == '!' then force to write history even if it is turned off
    " localy or globaly.
    " The local variable overrides the global one!
    let cond = exists("b:atp_History") && !b:atp_History || exists("g:atp_History") && ( !g:atp_History && (!exists("b:atp_History") || exists("b:atp_History") && !b:atp_History )) || !exists("g:atp_History") && !exists("b:atp_History")
    if  a:bang == "" && cond
	echomsg "ATP WriteHistory: History is turned off."
	if g:atp_debugHistory
	    redir END
	endif
	return
    endif

    " Check if global variables where changed.
    " (1) copy global variable to l:variables
    " (2) source the history file and compare the results
    " (3) if they differ copy l:variables to global ones and write the
    " history.
    if a:type == "global"
	for var in g:atp_cached_common_variables 
	    if g:atp_debugHistory >= 2
		echomsg "g:" . var . " EXISTS " . exists("g:" . var)
	    endif
	    " step (1) copy variables
	    if exists("g:" . var)
		let {"l:" . var} = {"g:" . var}
		execute "unlet g:" . var
	    endif
	endfor
	" step (2a) source history file
	execute "source " . a:history_file 
	let cond = 0
	for var in g:atp_cached_common_variables
	    if g:atp_debugHistory
		echo "g:" . var . " exists " . exists("g:" . var)
		echo "l:" . var . " exists " . exists("l:" . var)
	    endif
	    " step (2b) check if variables have changed
	    if exists("g:" . var) && exists("l:" . var)
		let cond_A = ({"l:" . var} != {"g:" . var})
		let cond += cond_A
		if cond_A
		    let {"l:" . var} = {"g:" . var}
		endif
	    elseif !exists("g:" . var) && exists("l:" . var)
		let {"g:" . var} = {"l:" . var}
		let cond += 1
	    elseif exists("g:" . var) && !exists("l:" . var)
		unlet {"g:" . var}
		let cond += 1
	    endif
	endfor
	if cond == 0
	    if g:atp_debugHistory
		silent echomsg "history not changed " . "\n"
		silent echo "time = " . reltimestr(reltime(time)) . "\n"
	    endif
	    return
	else
	    " step (3a) copy variables from local ones and go further
	    " to write the history file.
	    for var in g:atp_cached_common_variables
		if exists("l:" . var)
		    let {"g:" . var} = {"l:" . var}
		endif
	    endfor
	endif
    endif

"     let saved_swapchoice= v:swapchoice
    let deleted_variables	= []
    for var in a:cached_variables
	if exists(prefix . var)
	    let l:{var} = {prefix . var}
	    if g:atp_debugHistory
		let g:hist_{var} = l:{var}
	    endif
	else
	    call add(deleted_variables, prefix . var)
	endif
    endfor
    try
	silent! exe "edit +setl\\ noswapfile " . a:history_file
    catch /.*/
	echoerr v:errmsg
	echoerr "WriteHistory catched error while opening " . a:history_file . " History not written."
	return 
    endtry

    " Delete the variables which where unlet:
    for var in deleted_variables
	silent! exe ':%g/^\s*let\s\+' . var . '\>/d'
    endfor

    " Write new variables:
    for var in a:cached_variables
	if exists("l:" . var)
	    silent! exe ':%g/^\s*let\s\+' . prefix . var . '/d'
	    call append('$', 'let ' . prefix . var . ' = ' . string({ 'l:' . var }))
	endif
    endfor
    silent w
    silent bw!
	if g:atp_debugHistory
	    silent echo "time = " . reltimestr(reltime(time))
	    redir END
	endif
"     let v:swapchoice	= saved_swapchoice
endfunction
command! -buffer -bang WriteHistory		:call s:WriteHistory(<q-bang>, s:history_file, g:atp_cached_local_variables, 'local')
command! -buffer -bang WriteTexDistroHistory	:call s:WriteHistory(<q-bang>, s:common_history_file, g:atp_cached_common_variables, 'global')
"{{{2 WriteHistory autocommands
augroup ATP_WriteHistory 
    au!
    au VimLeave *.tex call s:WriteHistory("", s:history_file, g:atp_cached_local_variables, 'local')
    au VimLeave *.tex call s:WriteHistory("", s:common_history_file, g:atp_cached_common_variables, 'global')
augroup END "}}}1
" Set History: on/off
" {{{1 :History
function! <SID>History(arg)
    if a:arg == ""
	let b:atp_History=!b:atp_History
    elseif a:arg == "on"
	let b:atp_History=1
	:WriteHistory!
    elseif a:arg == "off"
	let b:atp_History=0
	:WriteHistory!
    endif
    if b:atp_History
	echomsg "History is set on."
    else
	echomsg "History is set off."
    endif
    return b:atp_History
endfunction
command! -buffer -nargs=1 -complete=customlist,HistComp History 	:call s:History(<f-args>)
function! HistComp(ArgLead, CmdLine, CursorPos)
    return filter(['on', 'off'], 'v:val =~ a:ArgLead')
endfunction "}}}1
" Delete History:
" s:DeleteHistory {{{1
" 	It has one argument a:1 == "local" or " a:0 == 0 " delete the s:history_file
" otherwise delete s:common_history_file.  With bang it forces to delete the
" s:common_history_file" 
" 	It also unlets the variables stored in s:common_history_file.
function! <SID>DeleteHistory(bang,...) 
    let type	= ( a:0 >= 1 ? a:1 : "local" )

    if type == "local"
	let file = s:history_file
    else
	let file = s:common_history_file
    endif

    call delete(file)
    echo "History file " . file . " deleted."
    if type == "local" && a:bang == "!"
	let file = s:common_history_file
	call delete(file)
	echo "History file " . file . " deleted."
    endif
    if file == s:common_history_file
	for var in g:atp_cached_common_variables
	    exe "unlet g:" . var
	endfor
    endif
endfunction
command! -buffer -bang -complete=customlist,DelHist -nargs=? DeleteHistory 	:call s:DeleteHistory(<q-bang>, <f-args>)
function! DelHist(CmdArg, CmdLine, CursorPos)
    let comp	= [ "local", "common" ]  
    call filter(comp, "v:val =~ '^' . a:CmdArg")
    return comp
endfunction
" Show History:
" function! <SID>ShowHistory(bang)
" 
"     let history_file
" endfunction
