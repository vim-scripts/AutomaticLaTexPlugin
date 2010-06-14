" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 May 31
" URL:		

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

function! ATP_TOC_StatusLine()
    if expand("%") == "__ToC__"
	return "Table of Contents"
    elseif expand("%") == "__Labels__"
	return "List of Labels"
    endif
endfunction
setlocal statusline=%{ATP_TOC_StatusLine()}

function! s:getlinenr(...)
    if a:0 == 0
	let l:line=getline('.')
    else
	let l:line=getline(a:1)
    endif
    let l:nr=substitute(matchstr(l:line,'^\s*\d\+'),'^\s*','','')
    return l:nr
endfunction

" Get the file name and its path from the LABELS/ToC list.
function! s:file()
    let l:true=1
    let l:linenr=line('.')
    while l:true == 1
	let l:line=s:getlinenr(l:linenr)
	if l:line != ""
	    let l:linenr-=1
	else
	    let l:true=0
	    " NOTE THAT FILE NAME SHOULD NOT INCLUDE '(' and ')' and SHOULD
	    " NOT BEGIN WITH A NUMBER.
	    let l:line=getline(l:linenr)
	    let l:bufname=strpart(l:line,0,stridx(l:line,'(')-1)
	    let l:path=substitute(strpart(l:line,stridx(l:line,'(')+1),')\s*$','','')
" 	    echomsg "BUFNAME " . l:bufname
" 	    echomsg "PATH " . l:path
	endif
    endwhile
    return [ l:path, l:bufname ]
endfunction
command! File	:echo s:file()
 
"---------------------------------------------------------------------
" Notes:
" 		(1) choose window with matching buffer name
" 		(2) choose among those choose the one which we eddited last
" Solution:
"        			       --N-> choose this window
"			 	       |
"			     --N-> ----|
"			     | 	       --Y-> choose that window		
" --go from where you come-->|         Does there exists another open window 
"  			     |	       with the right buffer name?
"			     |	
"  			     --Y-> use this window
"			   Does the window has
"			   a correct name?
"
" This function returns the window number to which we will eventually go.
function! s:gotowinnr()
    " This is the line number to which we will go.
    let l:nr=s:getlinenr()
    " t:bufname
    " t:winnr		were set by TOC(), they should also be set by
    " 			autocommands
    let l:buf=s:file()
    let l:bufname=l:buf[0] . "/" . l:buf[1]

    if t:bufname == l:bufname
	" if t:bufname agree with that found in ToC
	" if the t:winnr is still open
	if bufwinnr(t:bufname) != -1
	    let l:gotowinnr=t:winnr
" 	    echomsg "DEBUG A"
	else
	    let l:gotowinnr=-1
" 	    echomsg "DEBUG B"
	endif
" 	echomsg "DEBUG C " . l:gotowinnr
    else
 	if bufwinnr("^" . l:bufname . "$") != 0
	    " if not but there is a window with buffer l:bufname
	    let l:gotowinnr=bufwinnr("^" . l:bufname . "$")
 	else
	    " if not and there is no window with buffer l:bufname
 	    let l:gotowinnr=t:winnr
 	endif
    endif
    return l:gotowinnr
endif
endfunction

function! GotoLine(closebuffer)
    
    " if under help lines do nothing:
    let l:toc=getbufline("%",1,"$")
    let l:h_line=index(reverse(copy(l:toc)),'')+1
    let b:h_line=l:h_line
    if line(".") > len(l:toc)-l:h_line
	return ''
    endif

    let l:buf=s:file()

    " remember the ToC window number
    let l:tocbufnr=bufnr("")

    " line to go to
    let l:nr=s:getlinenr()

    " window to go to
    let l:gotowinnr=s:gotowinnr()

    if l:gotowinnr != -1
 	exe l:gotowinnr . " wincmd w"
    else
 	exe l:gotowinnr . " wincmd w"
	exe "e " . fnameescape(l:buf[0] . "/" . l:buf[1])
    endif
	
    "if we were asked to close the window
    if a:closebuffer == 1
	exe "bdelete " . l:tocbufnr
    endif

    "finally, set the position
    call setpos('.',[0,l:nr,1,0])
    exe "normal zt"
    
endfunction
" endif

function! s:yank(arg)

    let l:toc=getbufline("%",1,"$")
    let l:h_line=index(reverse(copy(l:toc)),'')+1
    let b:h_line=l:h_line
    if line(".") > len(l:toc)-l:h_line
	return ''
    endif

    let l:cbufnr=bufnr("")
    let l:buf=s:file()
    let l:bufname=l:buf[1]
    let l:filename=l:buf[0] . "/" . l:buf[1]
    let b:fn=l:filename

    if exists("t:labels") || get(t:labels,l:filename,"nofile") != "nofile"
	let l:choice=get(get(t:labels,l:filename),s:getlinenr())
    else
	let l:choice="nokey"
    endif

    if l:choice=="nokey"
	" in TOC, if there is a key we will give it back if not:
	au! CursorHold __ToC__
	echomsg "There is no key."
	sleep 759m
	au CursorHold __ToC__ :call EchoLine()
	return ""
    else
	if a:arg == '@'
	    let l:letter=input("To which register? <reg name><Enter> or empty for none ")
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

	    let l:gotowinnr=s:gotowinnr()
	    exe l:gotowinnr . " wincmd w"

	    " delete the buffer
	    exe "bdelete " . l:cbufnr

	    " set the line
	    let l:line=getline('.')
	    let l:colpos=getpos('.')[2]
	    let l:bline=strpart(l:line,0,l:colpos)
	    let l:eline=strpart(l:line,l:colpos)
	    call setline('.',l:bline . l:choice . l:eline)
	    call setpos('.',[getpos('.')[0],getpos('.')[1],getpos('.')[2]+len(l:choice),getpos('.')[3]])
	endif
    endif
endfunction

command! -buffer P :call Yank("p")

if !exists("*YankToReg")
function! YankToReg()
    call s:yank("@")
endfunction
endif

if !exists("*Paste")
function! Paste()
    call s:yank("p")
endfunction
endif
command! -buffer -nargs=1 Y :call YankToReg(<f-arg>)

if !exists("*ShowLabelContext")
function! ShowLabelContext()

    let l:toc=getbufline("%",1,"$")
    let l:h_line=index(reverse(copy(l:toc)),'')+1
    let b:h_line=l:h_line
    if line(".") > len(l:toc)-l:h_line
	return ''
    endif

    let l:cbufname=bufname('%')
    let l:bufname=s:file()[1]
    let l:bufnr=bufnr("^" . l:bufname . "$")
    let l:winnr=bufwinnr(l:bufname)
" 	echomsg "DEBUG bufname " . l:bufname
    let l:line=s:getlinenr()
    if !exists("t:labels")
	let t:labels=UpdateLabels(l:bufname)
    endif
    exe l:winnr . " wincmd w"
	if l:winnr == -1
	    exe "e #" . l:bufnr
	endif
    exe "12split "
    call setpos('.',[0,l:line,1,0])
endfunction
endif

if !exists("*EchoLine")
function! EchoLine()

    let l:toc=getbufline("%",1,"$")
    let l:h_line=index(reverse(copy(l:toc)),'')+1
    let b:h_line=l:h_line
    if line(".") > len(l:toc)-l:h_line
	return ''
    endif

    let l:bufname=s:file()[1]
    let l:bufnr=bufnr("^" . l:bufname . "$")
    if !exists("t:labels")
	let t:labels[l:bufname]=UpdateLabels(l:bufname)[l:bufname]
    endif
    let l:line=s:getlinenr()
    let l:sec_line=join(getbufline(l:bufname,l:line))
    let l:sec_type=""
    if l:sec_line =~ '\\subparagraph[^\*]'
	let l:sec_type="subparagraph"
    elseif l:sec_line =~ '\\subparagraph\*'
	let l:sec_type="subparagraph*"
    elseif l:sec_line =~ '\\paragraph[^\*]'
	let l:sec_type="paragraph"
    elseif l:sec_line =~ '\\paragraph\*'
	let l:sec_type="paragraph*"
    elseif l:sec_line =~ '\\subsubsection[^\*]'
	let l:sec_type="subsubsection"
    elseif l:sec_line =~ '\\subsubsection\*'
	let l:sec_type="subsubsection*"
    elseif l:sec_line =~ '\\subsection[^\*]'
	let l:sec_type="subsection"
    elseif l:sec_line =~ '\\subsection\*'
	let l:sec_type="subsection*"
    elseif l:sec_line =~ '\\section[^\*]'
	let l:sec_type="section"
    elseif l:sec_line =~ '\\section\*'
	let l:sec_type="section*"
    elseif l:sec_line =~ '\\chapter[^\*]'
	let l:sec_type="chapter"
    elseif l:sec_line =~ '\\chapter\*'
	let l:sec_type="chapter*"
    elseif l:sec_line =~ '\\part[^\*]'
	let l:sec_type="part"
    elseif l:sec_line =~ '\\part\*'
	let l:sec_type="part*"
    elseif l:sec_line =~ '\\bibliography'
	let l:sec_type="bibliography"
    elseif l:sec_line =~ '\\abstract'
	let l:sec_type="abstract"
    endif

    let l:label=matchstr(l:sec_line,'\\label\s*{\zs[^}]*\ze}')
    let g:sec_line=l:sec_line
    let g:label=l:label
    if l:label != ""
	echo l:sec_type . " : '" . strpart(l:sec_line,stridx(l:sec_line,'{')+1,stridx(l:sec_line,'}')-stridx(l:sec_line,'{')-1) . "'\t label : " . l:label
    else
	echo l:sec_type . " : '" . strpart(l:sec_line,stridx(l:sec_line,'{')+1,stridx(l:sec_line,'}')-stridx(l:sec_line,'{')-1) . "'"
    endif
    return 0
endfunction
endif

" function! s:bdelete()
"     call s:deletevariables()
"     bdelete
" endfunction
" command -buffer Bdelete 	:call s:bdelete()

" TODO:
" function! Update()
"     l:cbufname=bufname("")
"     let l:bufname=substitute(l:cbufname,'\C\%(-TOC\|-LABELS\)$','','')
"     let l:bufnr=bufnr("^" . l:bufname . "$")
"     let t:labels[l:bufname]=UpdateLabels(l:bufname)[l:bufname]
"     if l:cbufname =~ "-TOC$"
" 	" TODO
"     elseif l:cbufname =~ "-LABELS$"
" 	" TODO
"     endif
" endfunction

" To DoC
function! Help()
    echo "Available Mappings:"
    echo "q 		close ToC window"
    echo "<CR>  		go to and close"
    echo "<space>		go to"
    echo "c or y		yank the label to a register"
    echo "p		yank and paste the label (in the source file)"
    echo "e		echo the title to command line"
    echo "h		this help message"
endfunction

" MAPPINGS
if !exists("no_plugin_maps") && !exists("no_atp_toc_maps")
    map <silent> <buffer> q 		:bdelete<CR>
    map <silent> <buffer> <CR> 		:call GotoLine(1)<CR>
    map <silent> <buffer> <space> 	:call GotoLine(0)<CR>
" This does not work: 
"   noremap <silent> <buffer> <LeftMouse> :call GotoLine(0)<CR>
"   when the cursor is in another buffer (and the option mousefocuse is not
"   set) it calles the command instead of the function, I could add a check if
"   mouse is over the right buffer. With mousefocuse it also do not works very
"   well.
    map <buffer> c 			:call YankToReg()<CR>
    map <buffer> y 			:call YankToReg()<CR>
    noremap <silent> <buffer> p 	:call Paste()<CR>
    noremap <silent> <buffer> s 	:call ShowLabelContext()<CR> 
    noremap <silent> <buffer> e 	:call EchoLine()<CR>
    noremap <silent> <buffer> <F1>	:call Help()<CR>
endif
setl updatetime=200 
au CursorHold __ToC__ :call EchoLine()
