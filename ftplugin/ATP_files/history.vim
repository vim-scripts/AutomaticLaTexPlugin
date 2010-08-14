" Author: M. Szamotulski
" Description: 	A vim script which stores values of variables in a history file.
" 		It is read, and updated, written (two last via autocommands).

" History File ftplugin/ATP_fiels/atp_history.vim
" 

" Variables {{{1
let s:file	= expand('<sfile>:p')
let s:hist_file	= substitute(s:file, 'history.vim$', 'atp_history.vim', '')

" This variable is set to 1 iff the history was loaded by s:LoadHistory()
" function.
let b:atp_histloaded = 0

" These local variables will be saved:
let g:atp_cached_local_variables = [ 'atp_MainFile', 'atp_LocalCommands', 'atp_LocalColors', 'atp_LocalEnvironments', 'TreeOfFiles', 'ListOfFiles', 'TypeDict', 'LevelDict' ]

" This function Loads the atp_history.vim file.
function! s:LoadHistory(bang) "{{{1
    if exists("g:atp_nohistory") && g:atp_nohistory
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

    for var in g:atp_cached_local_variables
	" Show what is loading from the history file:
" 	echomsg "Loading b:".string(var)
" 	try
" 	    echomsg string({"g:atp_history_".var}[expand("%:p")])
" 	catch /E716: Key not present in Dictionary/
" 	catch /E121: Undefined variable/
" 	endtry

"	Load if history variable is defined and has an antry for the files.
	if exists("g:atp_history_".var) && string(get(g:atp_history_{var}, expand("%:p"), 0)) != 0
	    try
		execute 'let b:'.var.'=g:atp_history_'.var.'[expand("%:p")]'
	    catch /E716: Key not present in Dictionary/
	    endtry
	endif
    endfor
endfunction
command! -buffer -bang LoadHistory		:call s:LoadHistory(<q-bang>)
" au VimEnter *.tex :call s:LoadHistory()
au BufEnter *.tex :call s:LoadHistory("")
" 
function! s:UpdateHistory(...) "{{{1
    if exists("g:atp_nohistory") && g:atp_nohistory
	return
    endif
    let bang = a:0 >= 1 ? a:1 : ""
    echo bang
    if bang == "" && expand("%:p") =~ 'texmf' 
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
endfunction
command! -buffer -bang UpdateHistory	:call s:UpdateHistory(<q-bang>)
augroup ATP_UpdateHistory
    au!
    au BufLeave *.tex	:call s:UpdateHistory("")
augroup END

function! s:WriteHistory() "{{{1
    if exists("g:atp_nohistory") && g:atp_nohistory
	return
    endif
    let hist_file 	= substitute(s:file, 'history.vim$', 'atp_history.vim' , '')
    let saved_swapchoice= v:swapchoice
    exe "edit +setl\\ noswapfile " . hist_file
    for var in g:atp_cached_local_variables
" 	try
	    exe ':%g/^\s*let\s\+g:atp_history_'.var.'/d'
" 	catch /E486: Pattern not found/
" 	endtry
	call append('$', 'let g:atp_history_'.var.'='.string(g:atp_history_{var}))
    endfor
    w
    bw!
"     let v:swapchoice	= saved_swapchoice
endfunction
command! -buffer WriteHistory		:call s:WriteHistory()
augroup ATP_WriteHistory 
    au!
    au VimLeave *.tex call s:UpdateHistory() | call s:WriteHistory()
augroup END

" Delete from history or delete whole history file.
function! s:DeleteHistory(bang) " {{{1
    let hist_file 	= substitute(s:file, 'history.vim$', 'atp_history.vim' , '')
    if a:bang == "!"
	call delete(hist_file)
	return
    endif

    " if no bang just remove entries from dictionaries.
    for var in g:atp_cached_local_variables
	call remove(g:atp_history_{var}, expand("%:p"))
    endfor
    call s:WriteHistory()
endfunction
command! -buffer -bang DeleteHistory 	:call s:DeleteHistory(<q-bang>)
