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
let g:atp_DebugHistory = 0

" Windows version:
let s:windows	= has("win16") || has("win32") || has("win64") || has("win95")

" This variable is set to 1 iff the history was loaded by s:LoadHistory()
" function.
let b:atp_histloaded = 0

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
let s:history_file 	= s:windows ? g:atp_history_dir  . '\' . s:history_fname : g:atp_history_dir . '/' . s:history_fname
let s:common_history_file	= s:windows ? g:atp_history_dir  . '\common_var.vim' : g:atp_history_dir . '/common_var.vim' 

" These local variables will be saved:
let g:atp_cached_local_variables = [ 'atp_MainFile', 'atp_History', 'atp_LocalCommands', 'atp_LocalColors', 'atp_LocalEnvironments', 'TreeOfFiles', 'ListOfFiles', 'TypeDict', 'LevelDict']
" b:atp_PackageList is another variable that could be put into history file.

" This are common variable to all tex files.
let g:atp_cached_common_variables = ['atp_texpackages', 'atp_texclasses']
" }}}1

" Load History:
 "{{{1 s:LoadHistory(), :LoadHistory, autocommads
" type = local/global/tex
function! s:LoadHistory(bang, history_file, type,...)

    if g:atp_DebugHistory
	echomsg "\n"
	echomsg "ATP_History: LoadHistory " . a:type
	let hist_time	= reltime()
    endif

    let silent	= a:0 >= 1 ? a:1 : 0
    let silent 	= silent || silent == "silent" ? "silent" : ""
    let ch_load = a:0 >= 2 ? a:2 : 0 

    " Is hitstory on/off
    " The local variable overrides the global ones!
    if exists("b:atp_History") && !b:atp_History || exists("g:atp_History") && ( !g:atp_History && (!exists("b:atp_History") || exists("b:atp_History") && !b:atp_History )) || !exists("g:atp_History") && !exists("b:atp_History")
	exe silent . ' echomsg "ATP LoadHistory: not loading history file."'
	return
    endif

"     s:history_Load = { expand("%:p") : { type : number }  }

    " Load once feature (if ch_load)	- this is used on starup
    if ch_load && get(get(s:history_Load, expand("%:p"), []), a:type, 0) >= 1
	echomsg "History " . a:type . " already loaded for this buffer."
	return
    endif

    let cond_A	= get(s:history_Load, expand("%:p"), 0)
    let cond_B = get(get(s:history_Load, expand("%:p"), []), a:type, 0)
    if cond_B
	let s:history_Load[expand("%:p")][a:type][0] += 1 
    elseif cond_A
	let s:history_Load[expand("%:p")] =  { a:type : 1 }
    else
	let s:hisotory_Load= { expand("%:p") : { a:type : 1 } }
    endif

    if a:bang == "" && expand("%:p") =~ 'texmf' 
	return
    endif

    let b:atp_histloaded=1

    try
	execute " source " . a:history_file
	if g:atp_DebugHistory
	    echomsg "ATP_History: sourcing " . a:history_file
	endif
    catch /E484: Cannot open file/
    endtry

    if g:atp_DebugHistory
	echomsg "ATP_History: sourcing time: " . reltimestr(reltime(hist_time))
    endif
endfunction
command! -buffer -bang LoadHistory		:call s:LoadHistory(<q-bang>,s:history_file, 'local')
" au VimEnter *.tex :call s:LoadHistory()
augroup ATP_LoadHistory "{{{2
    au BufEnter *.tex :call s:LoadHistory("", s:history_file, 'local', 'silent', 1)
    au BufEnter *.tex :call s:LoadHistory("", s:common_history_file, 'texdist' , 'silent',1)
augroup END
command! LoadTexDistHistory	:call s:LoadHistory("", s:common_history_file, 'silent', 'texdist', 0)
"}}}1
" Write History:
"{{{1 s:WriteHistory(), :WriteHistory, autocommands
function! s:WriteHistory(bang, history_file, cached_variables, ...)
    let prefix = ( a:0 == 0 ? 'b:' : a:1 )

    if g:atp_DebugHistory
	echomsg "\n"
	redir! >> /tmp/ATP_HistoryDebug.vim
	echomsg "ATP_History: WriteHistory"
    endif

    " If none of the variables exists -> return
    let exists=max(map(deepcopy(a:cached_variables), "exists(prefix . v:val)")) 
    if !exists
	return
    endif

    if a:bang == "" && expand("%:p") =~ 'texmf'
	return
    endif

    " a:bang == '!' then force to write history even if it is turned off
    " localy or globlay.
    " The local variable overrides the global one!
    let cond = exists("b:atp_History") && !b:atp_History || exists("g:atp_History") && ( !g:atp_History && (!exists("b:atp_History") || exists("b:atp_History") && !b:atp_History )) || !exists("g:atp_History") && !exists("b:atp_History")
    if  a:bang == "" && cond
	echomsg "ATP WriteHistory: History is turned off."
	if g:atp_DebugHistory
	    redir END
	endif
	return
    endif
"     let saved_swapchoice= v:swapchoice
    for var in a:cached_variables
	if exists(prefix . var)
	    let l:{var} = {prefix . var}
	    if g:atp_DebugHistory
		let g:hist_{var} = l:{var}
	    endif
	endif
    endfor
    try
	silent! exe "edit +setl\\ noswapfile " . a:history_file
    catch /.*/
	echoerr v:errmsg
	echoerr "WriteHistory catched error while opening " . a:history_file . " History not written."
	if g:atp_DebugHistory
	    redir END
	endif
	return 
    endtry

    for var in a:cached_variables
	if exists("l:" . var)
	    silent! exe ':%g/^\s*let\s\+' . prefix . var . '/d'
	    call append('$', 'let ' . prefix . var . ' = ' . string({ 'l:' . var }))
	endif
    endfor

    silent w
    silent bw!
"     let v:swapchoice	= saved_swapchoice
endfunction
command! -buffer -bang WriteHistory		:call s:WriteHistory(<q-bang>, s:history_file, g:atp_cached_local_variables)
command! -buffer -bang WriteTexDistroHistory	:call s:WriteHistory(<q-bang>, s:common_history_file, g:atp_cached_common_variables, 'g:')
"{{{2 WriteHistory autocommands
augroup ATP_WriteHistory 
    au!
    au VimLeave *.tex call s:WriteHistory("", s:history_file, g:atp_cached_local_variables)
    au VimLeave *.tex call s:WriteHistory("", s:common_history_file, g:atp_cached_common_variables, 'g:')
augroup END "}}}1
" Set History: on/off
" {{{1 :History
function! s:History(arg)
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
function! s:DeleteHistory(bang,...) 
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
