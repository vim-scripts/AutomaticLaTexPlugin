" Author: M. Szamotulski
" Description: 	A vim script which stores values of variables in a history file.
" 		It is read, updated and written (two last via autocommands,
" 		first on sturup).

" History File ftplugin/ATP_fiels/atp_history.vim
 
" Variables {{{1
let s:file	= expand('<sfile>:p')
let s:hist_file	= substitute(s:file, 'history.vim$', 'atp_history.vim', '')
let g:atp_DebugHistory = 0

" When the history is longer than this value, echo message, 0 disable. 
let g:atp_histlenMax  = 200

" time in miliseconds, when it takes longer a watning message is shown, 0 for
" no message (should be less than 1000 (i.e. 1s) if greater the message will
" be echoed any way if the time reaches 1s).
let g:atp_histtimeMax = 50
let s:atp_histtimeMax = g:atp_histtimeMax*1000

" This variable is set to 1 iff the history was loaded by s:LoadHistory()
" function.
let b:atp_histloaded = 0

if !exists("s:history_Load")
    let s:history_Load	= {}
    let g:history_Load	= s:history_Load
endif
if !exists("s:history_Update")
    let s:history_Update	= {}
endif
if !exists("s:history_Write")
    let s:history_Write	= {}
endif

" These local variables will be saved:
" let g:atp_cached_local_variables = [ 'atp_MainFile', 'atp_History', 'atp_LocalCommands', 'atp_LocalColors', 'atp_LocalEnvironments', 'TreeOfFiles', 'ListOfFiles', 'TypeDict', 'LevelDict' ]
let g:atp_cached_local_variables = [ 'atp_MainFile', 'atp_History' ]

" This function Loads the atp_history.vim file.

function! s:LoadHistory(bang,...) "{{{1
    if g:atp_DebugHistory
	echomsg "\n"
	echomsg "LoadHistory"
	sleep 300m
    endif
    let time	= reltime()
    let silent	= a:0 >= 1 ? a:1 : 0
    let silent 	= silent || silent == "silent" ? "silent" : ""
    let ch_load = a:0 >= 2 ? a:2 : 0 

    if ch_load && get(s:history_Load, expand("%:p"), 0) >= 1
" 	echomsg "History already loaded for this buffer."
	return
    endif
    let loads	= get(s:history_Load, expand("%:p"), 0)
    if loads
	let s:history_Load[expand("%:p")] += 1 
    else
	let s:history_Load[expand("%:p")] = 1 
    endif

    " The local variable overrides the global one!
    if exists("b:atp_History") && !b:atp_History || exists("g:atp_History") && ( !g:atp_History && (!exists("b:atp_History") || exists("b:atp_History") && !b:atp_History )) || !exists("g:atp_History") && !exists("b:atp_History")
	exe silent . ' echomsg "ATP LoadHistory: not loading history file."'
	return
    endif
    if a:bang == "" && expand("%:p") =~ 'texmf' 
	return
    endif
    let b:atp_histloaded=1
    try
	execute " source " . s:hist_file
    catch /E484: Cannot open file/
    endtry

    " Load b:atp_History first
    if count(g:atp_cached_local_variables, 'atp_History')
	if exists("g:atp_history_atp_History") 
	    try
		exe silent . ' echomsg "ATP LoadHistory: loading b:atp_History variable."'
		let b:atp_History	= get(g:atp_history_atp_History, expand("%:p"), exists("g:atp_History") ? g:atp_History : 1)
	    catch /E121: Undefined variable: g:atp_history_atp_History /
		if !exists("b:atp_History")
		    echomsg "ATP LoadHistory: setting b:atp_History variable."
		    let b:atp_History	= exists("g:atp_History") ? g:atp_History : 1
		endif
	    endtry
	endif
    endif

    if !b:atp_History
	return
    endif

    for var in filter(copy(g:atp_cached_local_variables), "v:val != 'atp_History'") 
	" Show what is loading from the history file:
" 	echomsg "Loading b:".string(var)
" 	try
" 	    echomsg string({"g:atp_history_".var}[expand("%:p")])
" 	catch /E716: Key not present in Dictionary/
" 	catch /E121: Undefined variable/
" 	endtry

"	Load if history variable is defined and has an antry for the files.
" echomsg "Var: g:atp_history_".var
" echomsg string(get(g:atp_history_{var}, expand("%:p"), 0)) == 0
	if exists("g:atp_history_".var) 
" 	    && string(get(g:atp_history_{var}, expand("%:p"), 0)) != 0
	    try
" 		echomsg 'let b:'.var.'=g:atp_history_'.var.'[expand("%:p")]'
		execute 'let b:'.var.'=g:atp_history_'.var.'[expand("%:p")]'
	    catch /E716: Key not present in Dictionary/
	    endtry
	endif
    endfor

    let hist_time	= reltime(time)
    let g:atp_histtime	= reltimestr(hist_time)
    let g:atp_histlen	= exists("g:atp_history_atp_MainFile") ? len(keys(g:atp_history_atp_MainFile)) : 0
    if  ( 	g:atp_histtimeMax 	&& ( hist_time[1] >= s:atp_histtimeMax || hist_time[0] >= 1 ) ) || 
	\ ( 	g:atp_histlenMax 	&& g:atp_histlen > g:atp_histlenMax )
	    echohl WarningMsg
	    echomsg "Your history file " . s:hist_file . " became big."
	    echohl None
	    echomsg "Loading time:" . g:atp_histtime . " Number of entries " . g:atp_histlen
	    echomsg "You might want to use DeleteHistory or DeleteHistory!"
    endif
endfunction
command! -buffer -bang LoadHistory		:call s:LoadHistory(<q-bang>)
" au VimEnter *.tex :call s:LoadHistory()
au BufEnter *.tex :call s:LoadHistory("", 'silent', 1) "{{{1
function! s:UpdateHistory(bang, ...) "{{{1
"     let loads	= get(s:history_Update, expand("%:p"), 0)
"     if loads
" 	let s:history_Update[expand("%:p")] += 1 
"     else
" 	let s:history_Update[expand("%:p")] = 1 
"     endif
    if g:atp_DebugHistory
	echomsg "\n"
	echomsg "UpdateHistory"
	sleep 300m
    endif
    let force = ( a:0 >= 1 ? a:1 : 0 )
    let force = ( force == "force" || force ? 1 : 0 )
    let ch_load = a:0 >= 2 ? a:2 : 0 

"     if ch_load && s:history_Update[expand("%:p")] > 1
" " 	echomsg "History already loaded for this buffer."
" 	return
"     endif
" 
    " The local variable overrides the global one (unless force is used).
    let cond = exists("b:atp_History") && !b:atp_History || exists("g:atp_History") && ( !g:atp_History && (!exists("b:atp_History") || exists("b:atp_History") && !b:atp_History )) || !exists("g:atp_History") && !exists("b:atp_History")
    if !force && cond
	echo "ATP UpdateHistory: History is turned off."
	return
    endif
    if a:bang == "" && expand("%:p") =~ 'texmf' 
	return
    endif
    let file	= expand("%:p") 
    if expand("%:e") != "tex"  
	return
    endif
    for var in  g:atp_cached_local_variables
	if !exists("g:atp_history_".var)
	    let g:atp_history_{var} = {}
	endif
	if exists("b:".var) && len("b:".var) != 0
	    " Force new value
	    call extend(g:atp_history_{var}, { file : b:{var} }, 'force')
	endif
    endfor
    "     This cause an error (and history is appended to the current buffer!
"     call s:WriteHistory(a:bang)
endfunction
command! -buffer -bang UpdateHistory	:call s:UpdateHistory(<q-bang>)

augroup ATP_UpdateHistory "{{{1
    au!
    au BufLeave 	*.tex	:call s:UpdateHistory("")
    au BufHidden 	*.tex	:call s:UpdateHistory("")
augroup END

function! s:WriteHistory(bang) "{{{1
    if g:atp_DebugHistory
	echomsg "\n"
	echomsg "WriteHistory"
	sleep 300m
    endif
    " a:bang == '!' then force to write history even if it is turned off
    " localy or globlay.
    " The local variable overrides the global one!
    let cond = exists("b:atp_History") && !b:atp_History || exists("g:atp_History") && ( !g:atp_History && (!exists("b:atp_History") || exists("b:atp_History") && !b:atp_History )) || !exists("g:atp_History") && !exists("b:atp_History")
    if  a:bang == "" && cond
	echomsg "ATP WriteHistory: History is turned off."
	return
    endif
    let hist_file 	= substitute(s:file, 'history.vim$', 'atp_history.vim' , '')
    let saved_swapchoice= v:swapchoice
    exe "edit +setl\\ noswapfile " . hist_file
    for var in g:atp_cached_local_variables
	silent! exe ':%g/^\s*let\s\+g:atp_history_'.var.'/d'
	call append('$', 'let g:atp_history_'.var.'='.string(g:atp_history_{var}))
    endfor
    w
    bw!
"     let v:swapchoice	= saved_swapchoice
endfunction
command! -buffer -bang WriteHistory		:call s:WriteHistory(<q-bang>)
augroup ATP_WriteHistory 
    au!
    au VimLeave *.tex call s:UpdateHistory("") | call s:WriteHistory("")
augroup END

    function! s:History(arg) "{{{1
	if a:arg == ""
	    let b:atp_History=!b:atp_History
	elseif a:arg == "on"
	    let b:atp_History=1
	    :call s:UpdateHistory("", "force")
	    :WriteHistory!
	elseif a:arg == "off"
	    let b:atp_History=0
	    :call s:UpdateHistory("", "force")
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
    endfunction

" Delete from history or delete whole history file.
function! s:DeleteHistory(bang,...) " {{{1
    if a:bang == "!"
	for var in g:atp_cached_local_variables
	    try
		unlet g:atp_history_{var}
	    catch /E716: Key not present in Dictionary/
	    endtry
	endfor
	call delete(s:hist_file)
	echomsg s:hist_file . " deleted."
	return
    endif
    let file	= a:0 >= 1 ? fnamemodify(a:1, ":p") : expand("%:p")
    let g:file 	= file 

    " if no bang just remove entries from dictionaries.
    for var in g:atp_cached_local_variables
	try
	    call remove(g:atp_history_{var}, file)
	catch /E716: Key not present in Dictionary/
	endtry
    endfor
    call s:WriteHistory("!")
endfunction
command! -buffer -bang -complete=customlist,DelHistCompl -nargs=? DeleteHistory 	:call s:DeleteHistory(<q-bang>, <f-args>)
function! DelHistCompl(ArgLead, CmdLine, CursorPos)
    if !exists("g:atp_history_atp_MainFile")	
	return []
    endif
    return filter(keys(g:atp_history_atp_MainFile),  'fnamemodify(v:val, ":t") =~ a:ArgLead')
endfunction

function! s:HistoryStats(bang) 
    echo "Files in history: ". g:atp_histlen 		. " max:"  . g:atp_histlenMax
    echo "Last source time: ". string(str2float(g:atp_histtime)*1000)." max:"  . g:atp_histtimeMax . " (msec)"
    if a:bang == "!" && exists("g:atp_history_atp_MainFile") 
	for file in keys(g:atp_history_atp_MainFile)
	    echo "file " . fnamemodify(file, ":t") . " : atp_MainFile : " . fnamemodify(g:atp_history_atp_MainFile[file], ":t")
	endfor
    endif
endfunction
command! -buffer -bang HistoryStats :call <SID>HistoryStats(<q-bang>)
