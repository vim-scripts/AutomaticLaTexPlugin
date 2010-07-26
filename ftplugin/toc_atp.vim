" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 May 31
" URL:		

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

function! ATP_TOC_StatusLine()
    let l:return = ( expand("%") == "__ToC__" 	? "Table of Contents" 	: 0 )
    let l:return = ( expand("%") == "__Labels__" 	? "List of Labels" 	: l:return )
    return l:return
endfunction
setlocal statusline=%{ATP_TOC_StatusLine()}

" a:1 	line number to get, if not given the current line
" a:2	0/1 	0 (default) return linenr as for toc/labels
function! s:getlinenr(...)
    let line 	=  a:0 >= 1 ? getline(a:1) : getline('.')
    let labels 	=  a:0 >= 2 ? a:2	   : 0

    if labels == 0
	return matchstr(line,'^\s*\zs\d\+')
    else
	return matchstr(line,'(\zs\d\+\ze)') 
    endif
endfunction

function! s:getsectionnr(...)
    let line =  a:0 == 0 ? getline('.') : getline(a:1)
    return matchstr(l:line,'^\s*\d\+\s\+\zs\%(\d\|\.\)\+\ze\D')
endfunction

" Get the file name and its path from the LABELS/ToC list.
function! s:file()
    let labels		= expand("%") == "__Labels__" ? 1 : 0

    let true		= 1
    let linenr		= line('.')
    while true == 1
	let line	= s:getlinenr(linenr, labels)
	if line != ""
	    let linenr	-=1
	else
	    let true	= 0
	    " NOTE THAT FILE NAME SHOULD NOT INCLUDE '(' and ')' and SHOULD
	    " NOT BEGIN WITH A NUMBER.
	    let line	= getline(linenr)
	    let bufname	= strpart(line,0,stridx(line,'(')-1)
	    let path	= substitute(strpart(line,stridx(line,'(')+1),')\s*$','','')
	endif
    endwhile
    return [ path, bufname ]
endfunction
command! File	:echo s:file()
 
"---------------------------------------------------------------------
" Notes:
" 		(1) choose window with matching buffer name
" 		(2) choose among those which were edited last
" Solution:
"        			       --N-> choose this window
"			 	       |
"			     --N-> ----|
"			     | 	       --Y-> choose that window		
" --go from where you come-->|         Does there exist another open window 
"  			     |	       with the right buffer name?
"			     |	
"  			     --Y-> use this window
"			   Does the window have
"			   a correct name?
"
" This function returns the window number to which we will eventually go.
function! s:gotowinnr()
    let labels_window	= expand("%") == "__Labels__" ? 1 : 0

    " This is the line number to which we will go.
    let l:nr=s:getlinenr(line("."), labels_window)
    " t:atp_bufname
    " t:atp_winnr		were set by TOC(), they should also be set by
    " 			autocommands
    let l:buf=s:file()
    let l:bufname=l:buf[0] . "/" . l:buf[1]

    if t:atp_bufname == l:bufname
	" if t:atp_bufname agree with that found in ToC
	" if the t:atp_winnr is still open
	if bufwinnr(t:atp_bufname) != -1
	    let l:gotowinnr=t:atp_winnr
	else
	    let l:gotowinnr=-1
	endif
    else
 	if bufwinnr("^" . l:bufname . "$") != 0
	    " if not but there is a window with buffer l:bufname
	    let l:gotowinnr=bufwinnr("^" . l:bufname . "$")
 	else
	    " if not and there is no window with buffer l:bufname
 	    let l:gotowinnr=t:atp_winnr
 	endif
    endif
    return l:gotowinnr
endif
endfunction

function! GotoLine(closebuffer)
    let labels_window	= expand("%") == "__Labels__" ? 1 : 0
    
    " if under help lines do nothing:
    let toc		= getbufline("%",1,"$")
    let h_line		= index(reverse(copy(toc)),'')+1
    if line(".") > len(toc)-h_line
	return ''
    endif

    let buf	= s:file()

    " remember the ToC window number
    let tocbufnr= bufnr("")

    " line to go to
    let nr	= s:getlinenr(line("."), labels_window)

    " window to go to
    let gotowinnr= s:gotowinnr()

    if gotowinnr != -1
 	exe gotowinnr . " wincmd w"
    else
 	exe gotowinnr . " wincmd w"
	exe "e " . fnameescape(buf[0] . "/" . buf[1])
    endif
	
    "if we were asked to close the window
    if a:closebuffer == 1
	exe "bdelete " . tocbufnr
    endif

    "finally, set the position
    call setpos('.',[0,nr,1,0])
    exe "normal zt"
    
endfunction
" endif

function! s:yank(arg)
    let labels_window	= expand("%") == "__Labels__" ? 1 : 0

    let l:toc=getbufline("%",1,"$")
    let l:h_line=index(reverse(copy(l:toc)),'')+1
    if line(".") > len(l:toc)-l:h_line
	return ''
    endif

    let l:cbufnr=bufnr("")
    let l:buf=s:file()
    let l:bufname=l:buf[1]
    let l:filename=l:buf[0] . "/" . l:buf[1]

    if !labels_window
	if exists("t:atp_labels") || get(t:atp_labels, l:filename, "nofile") != "nofile"
	    let l:choice	= get(get(deepcopy(t:atp_labels), l:filename), s:getlinenr(line("."), labels_window))
	else
	    let l:choice	= "nokey"
	endif
    else
	if exists("t:atp_labels") || get(t:atp_labels, l:filename, "nofile") != "nofile"
	    let line_nr		= s:getlinenr(line("."), labels_window)
	    let choice_list	= filter(get(deepcopy(t:atp_labels), l:filename), "v:val[0] == line_nr" )
	    " There should be just one element in the choice list
	    " unless there are two labels in the same line.
	    let l:choice	= choice_list[0][1]
	else
	    let l:choice	= "nokey"
	endif
    endif

    if l:choice	== "nokey"
	" in TOC, if there is a key we will give it back if not:
	au! CursorHold __ToC__
	echomsg "There is no key."
	sleep 750m
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
    let labels_window	= expand("%") == "__Labels__" ? 1 : 0

    let l:toc=getbufline("%",1,"$")
    let l:h_line=index(reverse(copy(l:toc)),'')+1
    if line(".") > len(l:toc)-l:h_line
	return ''
    endif

    let l:cbufname=bufname('%')
    let l:bufname=s:file()[1]
    let l:bufnr=bufnr("^" . l:bufname . "$")
    let l:winnr=bufwinnr(l:bufname)
    let l:line=s:getlinenr(line("."), labels_window)
    if !exists("t:atp_labels")
	let t:atp_labels=UpdateLabels(l:bufname)
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
    let labels_window	= expand("%") == "__Labels__" ? 1 : 0

    let l:toc		= getbufline("%",1,"$")
    let l:h_line	= index(reverse(copy(l:toc)),'')+1
    if line(".") > len(l:toc)-l:h_line
	return ''
    endif

    let l:bufname	= s:file()[1]
    let l:bufnr		= bufnr("^" . l:bufname . "$")
    if !exists("t:atp_labels")
	let t:atp_labels[l:bufname]	= UpdateLabels(l:bufname)[l:bufname]
    endif
    let l:line		= s:getlinenr(line("."), labels_window)
    let l:sec_line	= join(getbufline(l:bufname,l:line))
    let l:sec_type	= ""

    let b:bufname	= l:bufname
    let b:line		= l:line

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

    let l:label		= matchstr(l:sec_line,'\\label\s*{\zs[^}]*\ze}')
    let g:sec_line	= l:sec_line
    let g:label		= l:label
    if l:label != ""
	echo l:sec_type . " : '" . strpart(l:sec_line,stridx(l:sec_line,'{')+1,stridx(l:sec_line,'}')-stridx(l:sec_line,'{')-1) . "'\t label : " . l:label
    else
	echo l:sec_type . " : '" . strpart(l:sec_line,stridx(l:sec_line,'{')+1,stridx(l:sec_line,'}')-stridx(l:sec_line,'{')-1) . "'"
    endif
    return 0
endfunction
endif

function! s:CompareNumbers(i1, i2)
    return str2nr(a:i1) == str2nr(a:i2) ? 0 : str2nr(a:i1) > str2nr(a:i2) ? 1 : -1
endfunction


" Stack of sections that were removed but not yet paste
" each entry is a list [ section title , list of deleted lines, section_nr ]
" where the section title is the one from t:atp_toc[filename][2]
" section_nr is the section number before deletion
" the recent positions are put in the front of the list
if expand("%") == "__ToC__"
    if !exists("t:atp_SectionStack")
	let t:atp_SectionStack 	= []
    endif
    function! s:DeleteSection()

	" if under help lines do nothing:
	let toc_line	= getbufline("%",1,"$")
	let h_line		= index(reverse(copy(toc_line)),'')+1
	if line(".") > len(toc_line)-h_line
	    return ''
	endif

	let s:deleted_section = toc_line

	" Get the name and path of the file
	" to operato on
	let buffer		= s:file()
	let file_name	= buffer[0] . "/" . buffer[1]

	let begin_line	= s:getlinenr()
	let section_nr	= s:getsectionnr()
	let toc		= deepcopy(t:atp_toc[file_name]) 
	let type		= toc[begin_line][0]

	" Only some types are supported:
	if count(['bibliography', 'subsubsection', 'subsection', 'section', 'chapter', 'part'], type) == 0
	    echo type . " is not supported"
	    sleep 750m
	    return
	endif

	" Find the end of the section:
	" part 		is ended by part
	" chapter		is ended by part or chapter
	" section		is ended by part or chapter or section
	" and so on,
	" bibliography 	is ended by like subsubsection.
	if type == 'part'
	    let type_pattern = 'part\|bibliography'
	elseif type == 'chapter'
	    let type_pattern = 'chapter\|part\|bibliography'
	elseif type == 'section'
	    let type_pattern = '\%(sub\)\@<!section\|chapter\|part\|bibliography'
	elseif type == 'subsection'
	    let type_pattern = '\%(sub\)\@<!\%(sub\)\=section\|chapter\|part\|bibliography'
	elseif type == 'subsubsection' || type == 'bibliography'
	    let type_pattern = '\%(sub\)*section\|chapter\|part\|bibliography'
	endif
	let title		= toc[begin_line][2]
	call filter(toc, 'str2nr(v:key) > str2nr(begin_line)')
	let end_line 	= -1
	let bibliography	=  0

	for line in sort(keys(toc), "s:CompareNumbers")
	    if toc[line][0] =~ type_pattern
		let end_line = line-1
		if toc[line][0] =~ 'bibliography'
		    let bibliography = 1
		endif
		break
	    endif
	endfor

	if end_line == -1 && &l:filetype == "plaintex"
	    echomsg "ATP can not delete last section in plain tex files :/"
	    sleep 750m
	    return
	endif

	" Window to go to
	let gotowinnr	= s:gotowinnr()

	if gotowinnr != -1
	    exe gotowinnr . " wincmd w"
	else
	    exe gotowinnr . " wincmd w"
	    exe "e " . fnameescape(buffer[0] . "/" . buffer[1])
	endif
	    
	"finally, set the position
	call setpos('.',[0,begin_line,1,0])
	normal! V
	if end_line != -1 && !bibliography
	    call setpos('.',[0, end_line, 1, 0])
	elseif bibliography
	    call setpos('.',[0, end_line, 1, 0])
	    let end_line 	= search('^\s*$', 'cbnW')-1
	elseif end_line == -1
	    let end_line 	= search('\ze\\end\s*{\s*document\s*}')
	    normal! ge
	endif
	" and delete
	normal d
	let deleted_section	= split(@*, '\n')
	if deleted_section[0] !~ '^\s*$' 
	    call extend(deleted_section, [' '], 0)  
	endif

	" Update the Table of Contents
	call remove(t:atp_toc[file_name], begin_line)
	let new_toc={}
	for line in keys(t:atp_toc[file_name])
	    if str2nr(line) < str2nr(begin_line)
		call extend(new_toc, { line : t:atp_toc[file_name][line] })
	    else
		call extend(new_toc, { line-len(deleted_section) : t:atp_toc[file_name][line] })
	    endif
	endfor
	let t:atp_toc[file_name]	= new_toc
	" Being still in the tex file make backup:
	if exists("g:atp_SectionBackup")
	    call extend(g:atp_SectionBackup, [[title, type, deleted_section, section_nr, expand("%:p")]], 0)
	else
	    let g:atp_SectionBackup	= [[title, type, deleted_section, section_nr, expand("%:p")]]
	endif
	" return to toc 
	TOC 0

	" Update the stack of deleted sections
	call extend(t:atp_SectionStack, [[title, type, deleted_section, section_nr]],0)
    endfunction
    command! DeleteSection		:call <SID>DeleteSection()
    " nnoremap dd			:call <SID>DeleteSection()<CR>

    " Paste the section from the stack
    " just before where the next section starts.
    " a:1	- the number of the section in the stack (from 1,...)
    " 	- by default it is the last one.
    function! s:PasteSection(...)

	let stack_number = a:0 >= 1 ? a:1-1 : 0 

	if !len(t:atp_SectionStack)
	    sleep 750m
	    echomsg "The stack of deleted sections is empty"
	    return
	endif

	let buffer		= s:file()

    "     if a:after 
	    let begin_line	= s:getlinenr(line(".")+1)
    "     else
    " 	let begin_line	= s:getlinenr()
    "     endif

	" Window to go to
	let gotowinnr	= s:gotowinnr()

	if gotowinnr != -1
	    exe gotowinnr . " wincmd w"
	else
	    exe gotowinnr . " wincmd w"
	    exe "e " . fnameescape(buffer[0] . "/" . buffer[1])
	endif

	if begin_line != ""
	    call setpos(".", begin_line-1)
	elseif &l:filetype != 'plaintex'
	    keepjumps let begin_line	= search('\\end\s*{\s*document\s*}', 'nw')
	else
	    echo "Pasting at the end is not supported for plain tex documents"
	    return
	endif
	let number	= len(t:atp_SectionStack)-1
	" Append the section
	call append(begin_line-1, t:atp_SectionStack[stack_number][2])
	" Set the cursor position to the begining of moved section and add it to
	" the jump list
	call setpos(".", [0, begin_line, 1, 0])

	" Regenerate the Table of Contents:
	TOC

	" Update the stack
	call remove(t:atp_SectionStack, stack_number)
    endfunction
    command! -buffer -nargs=? PasteSection	:call <SID>PasteSection(<f-args>)

    " Lists title of sections in the t:atp_SectionStack
    function! s:SectionStack()
	if len(t:atp_SectionStack) == 0
	    echomsg "Section stack is empty"
	    sleep 750m
	    return
	endif
	let i	= 1
	echo "Stack Number/Type/Title"
	for section in t:atp_SectionStack
	    echo i . "/" .  section[1] . " " . section[3] . "/" . section[0]
	    let i+=1
	endfor
    endfunction
    command! -buffer SectionStack	:call <SID>SectionStack()
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
"     let t:atp_labels[l:bufname]=UpdateLabels(l:bufname)[l:bufname]
"     if l:cbufname =~ "-TOC$"
" 	" TODO
"     elseif l:cbufname =~ "-LABELS$"
" 	" TODO
"     endif
" endfunction

" Undo in the winnr under the cursor.
" a:1 is one off u or U, default is u.
function! s:Undo(...)
    let cmd	= ( a:0 >= 1 && a:1 =~ '\cu\|g\%(-\|+\)' ? a:1 : 'u' )
    let winnr	= s:gotowinnr()
    exe winnr . " wincmd w"
    exe "normal! " . cmd
    TOC
endfunction
command! -buffer -nargs=? Undo 	:call <SID>Undo(<f-args>) 
nnoremap <buffer> u		:call <SID>Undo('u')<CR>
nnoremap <buffer> U		:call <SID>Undo('U')<CR>
nnoremap <buffer> g-		:call <SID>Undo('g-')<CR>
nnoremap <buffer> g+		:call <SID>Undo('g+')<CR>

" To DoC
function! Help()
    " Note: here they are not well indented, but in the output they are :)
    echo "Available Mappings:"
    echo "q 			close ToC window"
    echo "<CR>  			go to and close"
    echo "<space>			go to"
    echo "c or y			yank the label to a register"
    echo "p			yank and paste the label (in the source file)"
    echo "e			echo the title to command line"
    echo ":DeleteSection		Delete section under the cursor"
    echo ":PasteSection [<arg>] 	Paste section from section stack"
    echo ":SectionStack		Show section stack"
    echo "h			this help message"
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
augroup ATP_TOC
    au CursorHold __ToC__ :call EchoLine()
augroup END
