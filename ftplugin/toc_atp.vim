" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 Feb 4
" URL:		

function! s:getlinenr()
    let l:line=getline('.')
    let l:nr=substitute(matchstr(l:line,'^\s*\d*'),'^\s*','','')
    return l:nr
endfunction
if !exists("*GotoLine")
function! GotoLine(delbuffer)
    let l:nr=s:getlinenr()
    let l:cbufname=bufname('%')
    let l:bufname=substitute(l:cbufname,'\C\%(-TOC\|-LABELS\)$','','')
    let l:winnr=bufwinnr(l:bufname)
    echomsg "DEBUG " . l:bufname
    if a:delbuffer == 1
	bdelete
    else
    	exe l:winnr . " wincmd w"
    endif
    call setpos('.',[0,l:nr,1,0])
endfunction
endif
function! s:yank(arg)
    if exists("t:labels")
	let l:choice=get(t:labels,s:getlinenr())
    else
	let l:choice="nokey"
    endif
    if l:choice=="nokey"
	" in TOC, if there is a key we will give it back if not:
	echomsg "There is no key."
    else
	if a:arg =~ '@\a'
	    let l:letter=substitute(a:arg,'@','','g')
	    silent if l:letter == 'a'
		let @a=l:choice
	    elseif l:letter == 'b'
		let @b=l:choice
	    elseif l:letter == 'c'
		let @c=l:choice
	    elseif l:letter == 'd'
		let @d=l:choice
	    elseif l:letter == 'e'
		let @e=l:choice
	    elseif l:letter == 'f'
		let @f=l:choice
	    elseif l:letter == 'g'
		let @g=l:choice
	    elseif l:letter == 'h'
		let @h=l:choice
	    elseif l:letter == 'i'
		let @i=l:choice
	    elseif l:letter == 'j'
		let @j=l:choice
	    elseif l:letter == 'k'
		let @k=l:choice
	    elseif l:letter == 'l'
		let @l=l:choice
	    elseif l:letter == 'm'
		let @m=l:choice
	    elseif l:letter == 'n'
		let @n=l:choice
	    elseif l:letter == 'o'
		let @o=l:choice
	    elseif l:letter == 'p'
		let @p=l:choice
	    elseif l:letter == 'q'
		let @q=l:choice
	    elseif l:letter == 'r'
		let @r=l:choice
	    elseif l:letter == 's'
		let @s=l:choice
	    elseif l:letter == 't'
		let @t=l:choice
	    elseif l:letter == 'u'
		let @u=l:choice
	    elseif l:letter == 'v'
		let @v=l:choice
	    elseif l:letter == 'w'
		let @w=l:choice
	    elseif l:letter == 'x'
		let @x=l:choice
	    elseif l:letter == 'y'
		let @y=l:choice
	    elseif l:letter == 'z'
		let @z=l:choice
	    elseif l:letter == '*'
		let @-=l:choice
	    elseif l:letter == '+'
		let @+=l:choice
	    elseif l:letter == '-'
		let @@=l:choice
	    endif
	    echohl WarningMsg | echomsg "Choice yanked to the register '" . l:letter . "'" | echohl None
	elseif a:arg =='p'
	    bdelete
	    let l:line=getline('.')
	    let l:colpos=getpos('.')[2]
	    let l:bline=strpart(l:line,0,l:colpos)
	    let l:eline=strpart(l:line,l:colpos)
	    call setline('.',l:bline . l:choice . l:eline)
	    call setpos('.',[getpos('.')[0],getpos('.')[1],getpos('.')[2]+len(l:choice),getpos('.')[3]])
	endif
    endif
endfunction
command -buffer P :call Yank("p")
if !exists("*YankToReg")
function! YankToReg()
    let l:which=input("To which register? ")
    call s:yank("@" . l:which)
endfunction
endif
if !exists("*Paste")
function! Paste()
    call s:yank("p")
endfunction
endif
command -buffer -nargs=1 Y :call YankToReg(<f-arg>)
if !exists("*ShowLabelContext")
function! ShowLabelContext()
    let l:cbufname=bufname('%')
    let l:bufname=substitute(l:cbufname,'\C\%(-TOC\|-LABELS\)$','','')
    let l:bufnr=bufnr(l:bufname)
    let l:winnr=bufwinnr(l:bufname)
	echomsg "DEBUG bufname "l:bufname
    let l:line=s:getlinenr()
    if !exists("t:labels")
	let t:labels=UpdateLabels(l:bufname)
    endif
    exe l:winnr . " wincmd w"
    exe "12split "
    call setpos('.',[0,l:line,1,0])
endfunction
endif
if !exists("*EchoLabel")
function! EchoLabel()
    if !exists("t:labels")
	let t:labels=UpdateLabels(l:bufname)
    endif
    let l:cbufname=bufname('%')
    let l:bufname=substitute(l:cbufname,'\C\%(-TOC\|-LABELS\)$','','')
    let l:bufnr=bufnr(l:bufname)
    let l:line=s:getlinenr()
    echo getbufline(l:bufname,l:line)
endfunction
endif

" MAPPINGS
if !exists("no_plugin_maps") && !exists("no_atp_toc_maps")
    map <buffer> q 		:bdelete<CR>
    map <buffer> <CR> 	:call GotoLine('1')<CR>
    map <buffer> <space> 	:call GotoLine('0')<CR>
    map <buffer> c 		:call YankToReg()<CR>
    noremap <buffer> p 	:call Paste()<CR>
    noremap <buffer> s 	:call ShowLabelContext()<CR> 
    noremap <buffer> e 	:call EchoLabel()<CR>
endif
