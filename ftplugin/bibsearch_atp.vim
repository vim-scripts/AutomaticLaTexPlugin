" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Change: Tue Sep 27, 2011 at 14:52:01  +0100
" Note:		This file is a part of Automatic Tex Plugin for Vim.

"
" {{{ Load Once
if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1
" }}}

" Status Line:
function! ATPBibStatus() "{{{
    return substitute(expand("%"),"___","","g")
endfunction
setlocal statusline=%{ATPBibStatus()}
" }}}

" Maps:
" {{{ MAPS AND COMMANDS 
if !exists("no_plugin_maps") && !exists("no_atp_bibsearch_maps")
    map <buffer> <silent> c :<C-U>call <SID>BibYank()<CR>
    map <buffer> <silent> y :<C-U>call <SID>BibYank(v:count)<CR>
    map <buffer> <silent> p :<C-U>call <SID>BibPaste('p',v:count)<CR>
    map <buffer> <silent> P :<C-U>call <SID>BibPaste('P',v:count)<CR>
    map <buffer> <silent> q :hide<CR>
    command! -buffer -nargs=* Yank 	:call <SID>BibYank(<f-args>)
    command! -buffer -nargs=* Paste 	:call <SID>BibPaste('p', <f-args>)
endif
" }}}

" Functions:
function! <SID>BibYank(...)" {{{
    " Yank selection to register
    let g:a = a:0
    if a:0 == 0 || a:0 == 1 && a:1 == 0
	let which	= input("Which entry? ( {Number}[register]<Enter>, or <Enter> for none ) ")
	redraw
    else
	let which	= a:1
    endif
    if which == ""
	return
    endif
    if which =~ '^\d*$' 
	let start	= stridx(b:ListOfBibKeys[which],'{')+1
	let choice	= substitute(strpart(b:ListOfBibKeys[which], start), ',\s*$', '', '')
	let @"		= choice
    elseif which =~ '^\d*\(\a\|+\|"\| . "*" .\)$'
	let letter=substitute(which,'\d','','g')
	let which=substitute(which,'\a\|+\|"\|' . "*",'','g')
	let start=stridx(b:ListOfBibKeys[which],'{')+1
	let choice=substitute(strpart(b:ListOfBibKeys[which], start), ',', '', '')
	if letter == 'a'
	    let @a=choice
	elseif letter == 'b'
	    let @b=choice
	elseif letter == 'c'
	    let @c=choice
	elseif letter == 'd'
	    let @d=choice
	elseif letter == 'e'
	    let @e=choice
	elseif letter == 'f'
	    let @f=choice
	elseif letter == 'g'
	    let @g=choice
	elseif letter == 'h'
	    let @h=choice
	elseif letter == 'i'
	    let @i=choice
	elseif letter == 'j'
	    let @j=choice
	elseif letter == 'k'
	    let @k=choice
	elseif letter == 'l'
	    let @l=choice
	elseif letter == 'm'
	    let @m=choice
	elseif letter == 'n'
	    let @n=choice
	elseif letter == 'o'
	    let @o=choice
	elseif letter == 'p'
	    let @p=choice
	elseif letter == 'q'
	    let @q=choice
	elseif letter == 'r'
	    let @r=choice
	elseif letter == 's'
	    let @s=choice
	elseif letter == 't'
	    let @t=choice
	elseif letter == 'u'
	    let @u=choice
	elseif letter == 'v'
	    let @v=choice
	elseif letter == 'w'
	    let @w=choice
	elseif letter == 'x'
	    let @x=choice
	elseif letter == 'y'
	    let @y=choice
	elseif letter == 'z'
	    let @z=choice
	elseif letter == '*'
	    let @-=choice
	elseif letter == '+'
	    let @+=choice
	elseif letter == '-'
	    let @@=choice
	elseif letter == '"'
	    let @"=choice
	endif
	echohl WarningMsg | echomsg "[ATP:] choice yaneked to the register '" . letter . "'" | echohl None
    endif
endfunction "}}}
function! <SID>BibPaste(command,...) "{{{
    if a:0 == 0 || a:0 == 1 && a:1 == 0
	let which	= input("Which entry? ( {Number}<Enter>, or <Enter> for none ) ")
	redraw
    else
	let which	= a:1
    endif
    if which == ""
	return
    endif
    let start	= stridx(b:ListOfBibKeys[which],'{')+1
    let choice	= substitute(strpart(b:ListOfBibKeys[which], start), ',\s*$', '', '')
    let @"	= choice

    " Goto right buffer
    let winbufnr = bufwinnr(b:BufNr)
    if winbufnr != -1
	exe "normal ".winbufnr."w"
    else
	if bufexist(b:BufNr)
	    exe "normal buffer ".winbufnr
	else
	    echohl WarningMsg 
	    echo "Buffer was deleted"
	    echohl None
	    return
	endif
    endif

    let LineNr 	= line(".")
    let ColNr 	= col(".") 
    if a:command ==# 'P'
	let ColNr -= 1
    endif
    call setline(LineNr, strpart(getline(LineNr), 0, ColNr) . choice . strpart(getline(LineNr), ColNr))
    call cursor(LineNr, len(strpart(getline(LineNr), 0, ColNr) . choice)+1)
    return
endfunction "}}}
" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
