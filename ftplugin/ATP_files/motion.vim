" Author:	Marcin Szamotulski
" This file contains motion and highlight functions of ATP.

" All table  of contents stuff: variables, functions and commands. 
" {{{ Table Of Contents
let g:atp_sections={
    \	'chapter' 	: [           '^\s*\(\\chapter\*\?\s*{\)',	'\\chapter\*'],	
    \	'section' 	: [           '^\s*\(\\section\*\?\s*{\)',	'\\section\*'],
    \ 	'subsection' 	: [	   '^\s*\(\\subsection\*\?\s*{\)',	'\\subsection\*'],
    \	'subsubsection' : [ 	'^\s*\(\\subsubsection\*\?\s*{\)',	'\\subsubsection\*'],
    \	'bibliography' 	: ['^\s*\(\\begin\s*{bibliography}\|\\bibliography\s*{\)' , 'nopattern'],
    \	'abstract' 	: ['^\s*\(\\begin\s*{abstract}\|\\abstract\s*{\)',	'nopattern']}

"     \   'part'		: [ 		 '^\s*\(\\part.*\)',	'\\part\*'],

"--Make TOC -----------------------------
" This makes sense only for latex documents.
"
" It makes the t:atp_toc - a dictionary (with keys: full path of the buffer name)
" which values are dictionaries which keys are: line numbers and values lists:
" [ 'section-name', 'number', 'title'] where section name is element of
" keys(g:atp_sections), number is the total number, 'title=\1' where \1 is
" returned by the g:section['key'][0] pattern.
" {{{ maketoc_fromaux
" function! s:maketoc_fromaux(filename)
"     let l:toc={}
"     " if the dictinary with labels is not defined, define it
"     if !exists("t:atp_labels")
" 	let t:atp_labels={}
"     endif
"     " TODO we could check if there are changes in the file and copy the buffer
"     " to this variable only if there where changes.
"     let l:auxfile=[]
"     " getbufline reads only loaded buffers, unloaded can be read from file.
"     let l:auxfname=fnamemodify(a:filename,":r").'.aux'
"     if filereadable(l:auxfname)
" 	let l:auxfile=readfile(l:auxfname)
"     else
" 	echohl WarningMsg
" 	echomsg "No aux file, run ".b:atp_TexCompiler."."
" 	echohl Normal
"     endif
"     call filter(l:auxfile,' v:val =~ "\\\\@writefile{toc}"') 
" "     while l:line in l:auxfile
"     for l:line in l:auxfile
" 	let l:sec_unit=matchstr(l:line,'\\contentsline\s*{\zs[^}]*\ze}')
" 	let l:sec_number=matchstr(l:line,'\\numberline\s*{\zs[^}]*\ze}')
" " 	echomsg l:sec_number
" 	" To Do: how to match the long_title
" 	let l:long_title=matchstr(l:line,'\\contentsline\s*{[^}]*}{\%(\\numberline\s*{[^}]*}\)\?\s*\zs.*') 
" 	if l:long_title =~ '\\GenericError'
" 	    let l:long_title=substitute(l:long_title,'\\GenericError\s*{[^}]*}{[^}]*}{[^}]*}{[^}]*}','','g')
" 	endif
" 	if l:long_title =~ '\\relax\s'
" 	    let l:long_title=substitute(l:long_title,'\\relax\s','','g')
" 	endif	   
" 	if l:long_title =~ '\\unhbox '
" 	    let l:long_title=substitute(l:long_title,'\\unhbox\s','','g')
" 	endif	   
" 	if l:long_title =~ '\\nobreakspace'
" 	    let l:long_title=substitute(l:long_title,'\\nobreakspace\s*{}',' ','g')
" 	endif	   
" 	let l:i=0
" 	let l:braces=0
" 	while l:braces >= 0 && l:i < len(l:long_title)
" 	    if l:long_title[l:i] == '{'
" 		let l:braces+=1
" 	    elseif l:long_title[l:i] == '}'
" 		let l:braces-=1
" 	    endif
" 	    let l:i+=1
" 	endwhile
" " 	echo "len " len(l:long_title) . " l:i" . l:i
" 	let l:long_title=strpart(l:long_title,0,l:i-1)
" 
" " 	let l:star_c=matchstr(l:line,'\\contentsline\s*{[^}]*}{\%(\\numberline\s*{[^}]*}\)\?\s*\%([^}]*\|{[^}]*}\)*}{\zs[^}]*\ze}')
" 	let l:star_version= l:line =~ l:sec_unit.'\*'
" 
" 	" find line number in the current tex file (this is not the best!) we
" 	" should check if we are in mainfile.
" 	let l:line_nr=search('\\'.l:sec_unit.'.*'.l:long_title,'n')
" 	let l:tex_line=getline(l:line_nr)
" " 	echomsg "tex_line=".l:tex_line."sec_unit=".l:sec_unit." sec_number=".l:sec_number." l:long_title=".l:long_title." star=".l:star_version 
" 	" find short title
" 	let l:short_title=l:line
" 	let l:start=stridx(l:short_title,'[')+1
" 	if l:start == 0
" 	    let l:short_title=''
" 	else
" 	    let l:short_title=strpart(l:short_title,l:start)
" 	    " we are looking for the maching ']' 
" 	    let l:count=1
" 	    let l:i=-1
" 	    while l:i<=len(l:short_title)
" 		let l:i+=1
" 		if strpart(l:short_title,l:i,1) == '['	
" 		    let l:count+=1
" 		elseif strpart(l:short_title,l:i,1) == ']'
" 		    let l:count-=1
" 		endif
" 		if l:count==0
" 		    break
" 		endif
" 	    endwhile	
" 	    let l:short_title=strpart(l:short_title,0,l:i)
" 	endif
" 	call extend(l:toc, { l:line_nr : [l:sec_unit, l:sec_number, l:long_title, l:star_version, l:short_title] }) 
"     endfor
"     let t:atp_toc_new={ a:filename : l:toc }
"     return t:atp_toc_new
" endfunction
" }}}2
" {{{2 s:find_toc_lines
function! s:find_toc_lines()
    let l:toc_lines_nr=[]
    let l:toc_lines=[]
    let b:toc_lines_nr=l:toc_lines_nr

    let l:pos_saved=getpos(".")
    let l:pos=[0,1,1,0]
    keepjumps call setpos(".",l:pos)

    " Pattern:
    let l:j=0
    for l:section in keys(g:atp_sections)
	if l:j == 0 
	    let l:filter=g:atp_sections[l:section][0] . ''
	else
	    let l:filter=l:filter . '\|' . g:atp_sections[l:section][0] 
	endif
	let l:j+=1
    endfor
"     let b:filter=l:filter

    " Searching Loop:
    let l:line=search(l:filter,'W')
    while l:line
	call add(l:toc_lines_nr,l:line)
	let l:line=search(l:filter,'W')
    endwhile
    keepjumps call setpos(".",l:pos_saved)
    for l:line in l:toc_lines_nr
	call add(l:toc_lines,getline(l:line))
    endfor
    return l:toc_lines
endfunction
" }}}2
" {{{2 s:maketoc 
function! s:maketoc(filename)
    
    " this will store information { 'linenumber' : ['chapter/section/..', 'sectionnumber', 'section title', '0/1=not starred/starred'] }
    let l:toc={}

    " if the dictinary with labels is not defined, define it
    if !exists("t:atp_labels")
	let t:atp_labels={}
    endif
    " TODO we could check if there are changes in the file and copy the buffer
    " to this variable only if there where changes.
    let l:texfile=[]
    " getbufline reads only loaded buffers, unloaded can be read from file.
    let l:bufname=fnamemodify(a:filename,":t")
    let b:bufname=l:bufname
    if bufloaded(l:bufname)
	let l:texfile=getbufline("^" . l:bufname . "$","1","$")
    else
" 	w
	let l:texfile=readfile(a:filename)
    endif
    let l:true=1
    let l:i=0
    " remove the part before \begin{document}
    while l:true == 1 && len(l:texfile)>0
	if l:texfile[0] =~ '\\begin\s*{document}'
		let l:true=0
	endif
	call remove(l:texfile,0)
	let l:i+=1
    endwhile
    let l:bline=l:i
    let l:i=1
    " set variables for chapter/section numbers
    for l:section in keys(g:atp_sections)
	let l:ind{l:section}=0
    endfor
    " make a filter
    let l:j=0
    for l:section in keys(g:atp_sections)
	if l:j == 0 
	    let l:filter=g:atp_sections[l:section][0] . ''
	else
	    let l:filter=l:filter . '\|' . g:atp_sections[l:section][0] 
	endif
	let l:j+=1
    endfor
    let b:filter=l:filter " DEBUG
    " ToDo: HOW TO MAKE THIS FAST?
    let s:filtered=filter(deepcopy(l:texfile),'v:val =~ l:filter')
    let b:filtered=s:filtered
    let b:texfile=l:texfile
" this works but only for one file:
"     let s:filtered=s:find_toc_lines()
    for l:line in s:filtered
	for l:section in keys(g:atp_sections)
	    if l:line =~ g:atp_sections[l:section][0] 
		if l:line !~ '^\s*%'
		    " THIS DO NOT WORKS WITH \abstract{ --> empty set, but with
		    " \chapter{title} --> title, solution: the name of
		    " 'Abstract' will be plased, as we know what we have
		    " matched
		    let l:title=l:line

		    " test if it is a starred version.
		    let l:star=0
		    if g:atp_sections[l:section][1] != 'nopattern' && l:line =~ g:atp_sections[l:section][1] 
			let l:star=1 
		    else
			let l:star=0
		    endif
		    let l:i=index(l:texfile,l:line)
		    let l:tline=l:i+l:bline+1

		    " Find Title:
		    let l:start=stridx(l:title,'{')+1
		    let l:title=strpart(l:title,l:start)
		    " we are looking for the maching '}' 
		    let l:count=1
		    let l:i=-1
		    while l:i<=len(l:title)
			let l:i+=1
			if strpart(l:title,l:i,1) == '{'	
			    let l:count+=1
			elseif strpart(l:title,l:i,1) == '}'
			    let l:count-=1
			endif
			if l:count==0
			    break
			endif
		    endwhile	
		    let l:title=strpart(l:title,0,l:i)

		    " Section Number:
		    " if it is not starred version add one to the section number
		    " or it is not an abstract 
		    if l:star == 0  
			if !(l:section == 'chapter' && l:title =~ '^\cabstract$')
			    let l:ind{l:section}+=1
" 			else
" 			    echomsg "XXXXXXXXX" l:section . " " . l:title . "  " . l:ind{l:section}
			endif
		    endif

		    if l:section == 'part'
			let l:indchapter=0
			let l:indsection=0
			let l:indsubsection=0
			let l:indsubsubsection=0
		    elseif l:section ==  'chapter'
			let l:indsection=0
			let l:indsubsection=0
			let l:indsubsubsection=0
		    elseif l:section ==  'section'
			let l:indsubsection=0
			let l:indsubsubsection=0
		    elseif l:section ==  'subsection'
			let l:indsubsubsection=0
		    endif

		    " Find Short Title:
		    let l:shorttitle=l:line
		    let l:start=stridx(l:shorttitle,'[')+1
		    if l:start == 0
			let l:shorttitle=''
		    else
			let l:shorttitle=strpart(l:shorttitle,l:start)
			" we are looking for the maching ']' 
			let l:count=1
			let l:i=-1
			while l:i<=len(l:shorttitle)
			    let l:i+=1
			    if strpart(l:shorttitle,l:i,1) == '['	
				let l:count+=1
			    elseif strpart(l:shorttitle,l:i,1) == ']'
				let l:count-=1
			    endif
			    if l:count==0
				break
			    endif
			endwhile	
			let l:shorttitle=strpart(l:shorttitle,0,l:i)
		    endif
		    call extend(l:toc, { l:tline : [ l:section, l:ind{l:section}, l:title, l:star, l:shorttitle] }) 

		    " Extend t:atp_labels
		    let l:lname=matchstr(l:line,'\\label\s*{.*','')
		    let l:start=stridx(l:lname,'{')+1
		    let l:lname=strpart(l:lname,l:start)
		    let l:end=stridx(l:lname,'}')
		    let l:lname=strpart(l:lname,0,l:end)
" 		    let b:lname=l:lname
		    if	l:lname != ''
			" if there was no t:atp_labels for a:filename make an entry in
			" t:atp_labels
			if !has_key(t:atp_labels,a:filename)
			    let t:atp_labels[a:filename] = {}
			endif
			call extend(t:atp_labels[a:filename],{ l:tline : l:lname },"force")
		    endif
		endif
	    endif
	endfor
    endfor
    if exists("t:atp_toc")
	call extend(t:atp_toc, { a:filename : l:toc },"force")
    else
	let t:atp_toc={ a:filename : l:toc }
    endif
    return t:atp_toc
endfunction
" }}}2
" {{{2 Make a List of Buffers
if !exists("t:buflist")
    let t:buflist=[]
endif
function! s:buflist()
    " this names are used in TOC and passed to s:maketoc, which
    " makes a dictionary whose keys are the values of l:name defined
    " just below:
    let l:name=resolve(fnamemodify(bufname("%"),":p"))
    " add an entry to the list t:buflist if it is not there.
    if bufname("") =~ ".tex" && index(t:buflist,l:name) == -1
	call add(t:buflist,l:name)
    endif
    return t:buflist
endfunction
call s:buflist()
" }}}2
" {{{2 RemoveFromBufList
if !exists("*RemoveFromBufList")
    function RemoveFromBufList()
	let l:i=1
	for l:f in t:buflist
	    echo "(" . l:i . ") " . l:f
	    let l:i+=1
	endfor
	let l:which=input("Which file to remove (press <Enter> for none)")
	if l:which != "" && l:which =~ '\d\+'
	    call remove(t:buflist,l:f-1)
	endif
    endfunction
endif
" }}}2
" {{{2 s:showtoc
function! s:showtoc(toc,...)
    let l:new=0
    if a:0 == 1
	let l:new=a:1
    endif
    " this is a dictionary of line numbers where a new file begins.
    let l:cline=line(".")
"     " Open new window or jump to the existing one.
"     " Remember the place from which we are coming:
"     let t:atp_bufname=bufname("")
"     let t:atp_winnr=winnr()	 these are already set by TOC()
    let l:bname="__ToC__"
    let l:tocwinnr=bufwinnr("^" . l:bname . "$") 
"     echomsg "DEBUG a " . l:tocwinnr
    if l:tocwinnr != -1
	" Jump to the existing window.
	    exe l:tocwinnr . " wincmd w"
	    silent exe "%delete"
    else
	" Open new window if its width is defined (if it is not the code below
	" will put toc in the current buffer so it is better to return.
	if !exists("t:toc_window_width")
	    echoerr "t:toc_window_width not set"
	    return
	endif
	let l:openbuffer=t:toc_window_width . "vsplit +setl\\ wiw=15\\ buftype=nofile\\ filetype=toc_atp\\ nowrap __ToC__"
	silent exe l:openbuffer
	" We are setting the address from which we have come.
	silent call atplib#setwindow()
    endif
    setlocal tabstop=4
    let l:number=1
    " this is the line number in ToC.
    " l:number is a line number relative to the file listed in ToC.
    " the current line number is l:linenumber+l:number
    " there are two loops: one over l:linenumber and the second over l:number.
    let l:numberdict={}
    " this variable will be used to set the cursor position in ToC.
    for l:openfile in keys(a:toc)
	call extend(l:numberdict,{ l:openfile : l:number })
	let l:part_on=0
	let l:chap_on=0
	let l:chnr=0
	let l:secnr=0
	let l:ssecnr=0
	let l:sssecnr=0
	let l:path=fnamemodify(bufname(""),":p:h")
	for l:line in keys(a:toc[l:openfile])
	    if a:toc[l:openfile][l:line][0] == 'chapter'
		let l:chap_on=1
		break
	    elseif a:toc[l:openfile][l:line][0] == 'part'
		let l:part_on=1
	    endif
	endfor
	let l:sorted=sort(keys(a:toc[l:openfile]),"atplib#CompareList")
	let l:len=len(l:sorted)
	" write the file name in ToC (with a full path in paranthesis)
	call setline(l:number,fnamemodify(l:openfile,":t") . " (" . fnamemodify(l:openfile,":p:h") . ")")
	let l:number+=1
	for l:line in l:sorted
	    let l:lineidx=index(l:sorted,l:line)
	    let l:nlineidx=l:lineidx+1
	    if l:nlineidx< len(l:sorted)
		let l:nline=l:sorted[l:nlineidx]
	    else
		let l:nline=line("$")
	    endif
	    let l:lenght=len(l:line) 	
	    if l:lenght == 0
		let l:showline="     "
	    elseif l:lenght == 1
		let l:showline="    " . l:line
	    elseif l:lenght == 2
		let l:showline="   " . l:line
	    elseif l:lenght == 3
		let l:showline="  " . l:line
	    elseif l:lenght == 4
		let l:showline=" " . l:line
	    elseif l:lenght>=5
		let l:showline=l:line
	    endif
	    " Print ToC lines.
	    if a:toc[l:openfile][l:line][0] == 'abstract' || a:toc[l:openfile][l:line][2] =~ '^\cabstract$'
		call setline(l:number, l:showline . "\t" . "  " . "Abstract" )
	    elseif a:toc[l:openfile][l:line][0] =~ 'bibliography\|references'
		call setline (l:number, l:showline . "\t" . "  " . a:toc[l:openfile][l:line][2])
	    elseif a:toc[l:openfile][l:line][0] == 'chapter'
		let l:chnr=a:toc[l:openfile][l:line][1]
		let l:nr=l:chnr
" 		if l:new
" 		    let l:nr=a:toc[l:openfile][l:line][1]
" 		endif
		if a:toc[l:openfile][l:line][3]
		    "if it is stared version" 
		    let l:nr=substitute(l:nr,'.',' ','')
		endif
		if a:toc[l:openfile][l:line][4] != ''
		    call setline (l:number, l:showline . "\t" . l:nr . " " . a:toc[l:openfile][l:line][4])
		else
		    call setline (l:number, l:showline . "\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		endif
	    elseif a:toc[l:openfile][l:line][0] == 'section'
		let l:secnr=a:toc[l:openfile][l:line][1]
		if l:chap_on
		    let l:nr=l:chnr . "." . l:secnr  
" 		    if l:new
" 			let l:nr=a:toc[l:openfile][l:line][1]
" 		    endif
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    if a:toc[l:openfile][l:line][4] != ''
			call setline (l:number, l:showline . "\t\t" . l:nr . " " . a:toc[l:openfile][l:line][4])
		    else
			call setline (l:number, l:showline . "\t\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		    endif
		else
		    let l:nr=l:secnr 
" 		    if l:new
" 			let l:nr=a:toc[l:openfile][l:line][1]
" 		    endif
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    if a:toc[l:openfile][l:line][4] != ''
			call setline (l:number, l:showline . "\t" . l:nr . " " . a:toc[l:openfile][l:line][4])
		    else
			call setline (l:number, l:showline . "\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		    endif
		endif
	    elseif a:toc[l:openfile][l:line][0] == 'subsection'
		let l:ssecnr=a:toc[l:openfile][l:line][1]
		if l:chap_on
		    let l:nr=l:chnr . "." . l:secnr  . "." . l:ssecnr
" 		    if l:new
" 			let l:nr=a:toc[l:openfile][l:line][1]
" 		    endif
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    if a:toc[l:openfile][l:line][4] != ''
			call setline (l:number, l:showline . "\t\t\t" . l:nr . " " . a:toc[l:openfile][l:line][4])
		    else
			call setline (l:number, l:showline . "\t\t\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		    endif
		else
		    let l:nr=l:secnr  . "." . l:ssecnr
" 		    if l:new
" 			let l:nr=a:toc[l:openfile][l:line][1]
" 		    endif
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    if a:toc[l:openfile][l:line][4] != ''
			call setline (l:number, l:showline . "\t\t" . l:nr . " " . a:toc[l:openfile][l:line][4])
		    else
			call setline (l:number, l:showline . "\t\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		    endif
		endif
	    elseif a:toc[l:openfile][l:line][0] == 'subsubsection'
		let l:sssecnr=a:toc[l:openfile][l:line][1]
		if l:chap_on
		    let l:nr=l:chnr . "." . l:secnr . "." . l:sssecnr  
" 		    if l:new
" 			let l:nr=a:toc[l:openfile][l:line][1]
" 		    endif
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    if a:toc[l:openfile][l:line][4] != ''
			call setline(l:number, a:toc[l:openfile][l:line][0] . "\t\t\t" . l:nr . " " . a:toc[l:openfile][l:line][4])
		    else
			call setline(l:number, a:toc[l:openfile][l:line][0] . "\t\t\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		    endif
		else
		    let l:nr=l:secnr  . "." . l:ssecnr . "." . l:sssecnr
" 		    if l:new
" 			let l:nr=a:toc[l:openfile][l:line][1]
" 		    endif
		    if a:toc[l:openfile][l:line][3]
			"if it is stared version" 
			let l:nr=substitute(l:nr,'.',' ','g')
		    endif
		    if a:toc[l:openfile][l:line][4] != ''
			call setline (l:number, l:showline . "\t\t" . l:nr . " " . a:toc[l:openfile][l:line][4])
		    else
			call setline (l:number, l:showline . "\t\t" . l:nr . " " . a:toc[l:openfile][l:line][2])
		    endif
		endif
	    else
		let l:nr=""
	    endif
	    let l:number+=1
	endfor
    endfor
    " set the cursor position on the correct line number.
    " first get the line number of the begging of the ToC of t:atp_bufname
    " (current buffer)
" 	let t:numberdict=l:numberdict	"DEBUG
" 	t:atp_bufname is the full path to the current buffer.
    let l:num=l:numberdict[t:atp_bufname]
    let l:sorted=sort(keys(a:toc[t:atp_bufname]),"atplib#CompareList")
    let t:sorted=l:sorted
    for l:line in l:sorted
	if l:cline>=l:line
	    let l:num+=1
	endif
    keepjumps call setpos('.',[bufnr(""),l:num,1,0])
    endfor
   
    " Help Lines:
    let l:number=len(getbufline("%",1,"$"))
    call setline(l:number+1,"") 
    call setline(l:number+2,"<Space> jump") 
    call setline(l:number+3,"<Enter> jump and close") 
    call setline(l:number+4,"s       jump and split") 
    call setline(l:number+5,"y or c  yank label") 
    call setline(l:number+6,"p       paste label") 
    call setline(l:number+7,"q       close") 
endfunction
"}}}2

" This is the User Front End Function 
"{{{2 TOC
function! s:TOC(...)
    " skip generating t:atp_toc list if it exists and if a:0 != 0
    let l:skip = 0
    if a:0 >= 1 && a:1 == 1
	let l:skip = 1
    endif
    let l:new=0
    if a:0 >= 1
	let l:new=1
    endif
    if &filetype != 'tex'    
	echoerr "Wrong 'filetype'. This function works only for latex documents."
	return
    endif
    " for each buffer in t:buflist (set by s:buflist)
    if l:skip == 0 || ( l:skip == 1 && !exists("t:atp_toc") )
	for l:buffer in t:buflist 
    " 	    let t:atp_toc=s:make_toc(l:buffer)
		let t:atp_toc=s:maketoc(l:buffer)
	endfor
    endif
    call s:showtoc(t:atp_toc,l:new)
endfunction
nnoremap <Plug>ATP_TOC	:call <SID>TOC(1)
command! -buffer TOC	:call <SID>TOC()

" }}}2

" This finds the name of currently eddited section/chapter units. 
" {{{2 Current TOC
" ToDo: make this faster!
" {{{3 s:nearestsection
" This function finds the section name of the current section unit with
" respect to the dictionary a:section={ 'line number' : 'section name', ... }
" it returns the [ section_name, section line, next section line ]
function! s:nearestsection(section)
    let l:cline=line('.')

    let l:sorted=sort(keys(a:section),"atplib#CompareList")
    let l:x=0
    while l:x<len(l:sorted) && l:sorted[l:x]<=l:cline
       let l:x+=1 
    endwhile
    if l:x>=1 && l:x < len(l:sorted)
	let l:section_name=a:section[l:sorted[l:x-1]]
	return [l:section_name, l:sorted[l:x-1], l:sorted[l:x]]
    elseif l:x>=1 && l:x >= len(l:sorted)
	let l:section_name=a:section[l:sorted[l:x-1]]
	return [l:section_name,l:sorted[l:x-1], line('$')]
    elseif l:x<1 && l:x < len(l:sorted)
	" if we are before the first section return the empty string
	return ['','0', l:sorted[l:x]]
    elseif l:x<1 && l:x >= len(l:sorted)
	return ['','0', line('$')]
    endif
endfunction
" }}}3
" {{{3 s:ctoc
function! s:ctoc()
    if &filetype != 'tex' 
" TO DO:
" 	if  exists(g:tex_flavor)
" 	    if g:tex_flavor != "latex"
" 		echomsg "CTOC: Wrong 'filetype'. This function works only for latex documents."
" 	    endif
" 	endif
	" Set the status line once more, to remove the CTOC() function.
	call ATPStatus()
	return []
    endif
    " resolve the full path:
    let t:atp_bufname=resolve(fnamemodify(bufname("%"),":p"))
    
    " if t:atp_toc(t:atp_bufname) exists use it otherwise make it 
    if !exists("t:atp_toc") || !has_key(t:atp_toc,t:atp_bufname) 
	silent let t:atp_toc=s:maketoc(t:atp_bufname)
    endif

    " count where the preambule ends
    let l:buffer=getbufline(bufname("%"),"1","$")
    let l:i=0
    let l:line=l:buffer[0]
    while l:line !~ '\\begin\s*{document}' && l:i < len(l:buffer)
	let l:line=l:buffer[l:i]
	if l:line !~ '\\begin\s*{document}' 
	    let l:i+=1
	endif
    endwhile
	
    " if we are before the '\\begin{document}' line: 
    if line(".") <= l:i
	let l:return=['Preambule']
	return l:return
    endif

    let l:chapter={}
    let l:section={}
    let l:subsection={}

    for l:key in keys(t:atp_toc[t:atp_bufname])
	if t:atp_toc[t:atp_bufname][l:key][0] == 'chapter'
	    " return the short title if it is provided
	    if t:atp_toc[t:atp_bufname][l:key][4] != ''
		call extend(l:chapter, {l:key : t:atp_toc[t:atp_bufname][l:key][4]},'force')
	    else
		call extend(l:chapter, {l:key : t:atp_toc[t:atp_bufname][l:key][2]},'force')
	    endif
	elseif t:atp_toc[t:atp_bufname][l:key][0] == 'section'
	    " return the short title if it is provided
	    if t:atp_toc[t:atp_bufname][l:key][4] != ''
		call extend(l:section, {l:key : t:atp_toc[t:atp_bufname][l:key][4]},'force')
	    else
		call extend(l:section, {l:key : t:atp_toc[t:atp_bufname][l:key][2]},'force')
	    endif
	elseif t:atp_toc[t:atp_bufname][l:key][0] == 'subsection'
	    " return the short title if it is provided
	    if t:atp_toc[t:atp_bufname][l:key][4] != ''
		call extend(l:subsection, {l:key : t:atp_toc[t:atp_bufname][l:key][4]},'force')
	    else
		call extend(l:subsection, {l:key : t:atp_toc[t:atp_bufname][l:key][2]},'force')
	    endif
	endif
    endfor

    " Remove $ from chapter/section/subsection names to save the space.
    let l:chapter_name=substitute(s:nearestsection(l:chapter)[0],'\$','','g')
    let l:chapter_line=s:nearestsection(l:chapter)[1]
    let l:chapter_nline=s:nearestsection(l:chapter)[2]

    let l:section_name=substitute(s:nearestsection(l:section)[0],'\$','','g')
    let l:section_line=s:nearestsection(l:section)[1]
    let l:section_nline=s:nearestsection(l:section)[2]
"     let b:section=s:nearestsection(l:section)		" DEBUG

    let l:subsection_name=substitute(s:nearestsection(l:subsection)[0],'\$','','g')
    let l:subsection_line=s:nearestsection(l:subsection)[1]
    let l:subsection_nline=s:nearestsection(l:subsection)[2]
"     let b:ssection=s:nearestsection(l:subsection)		" DEBUG

    let l:names	= [ l:chapter_name ]
    if (l:section_line+0 >= l:chapter_line+0 && l:section_line+0 <= l:chapter_nline+0) || l:chapter_name == '' 
	call add(l:names, l:section_name) 
    elseif l:subsection_line+0 >= l:section_line+0 && l:subsection_line+0 <= l:section_nline+0
	call add(l:names, l:subsection_name)
    endif
    return l:names
endfunction
" }}}3
" {{{3 CTOC
function! CTOC(...)
    " if there is any argument given, then the function returns the value
    " (used by ATPStatus()), otherwise it echoes the section/subsection
    " title. It returns only the first b:atp_TruncateStatusSection
    " characters of the the whole titles.
    let l:names=s:ctoc()
    let b:names=l:names
" 	echo " DEBUG CTOC " . join(l:names)
    let l:chapter_name=get(l:names,0,'')
    let l:section_name=get(l:names,1,'')
    let l:subsection_name=get(l:names,2,'')

    if l:chapter_name == "" && l:section_name == "" && l:subsection_name == ""

    if a:0 == '0'
	echo "" 
    else
	return ""
    endif
	
    elseif l:chapter_name != ""
	if l:section_name != ""
" 		if a:0 == '0'
" 		    echo "XXX" . l:chapter_name . "/" . l:section_name 
" 		else
	    if a:0 != 0
		return substitute(strpart(l:chapter_name,0,b:atp_TruncateStatusSection/2), '\_s*$', '','') . "/" . substitute(strpart(l:section_name,0,b:atp_TruncateStatusSection/2), '\_s*$', '','')
	    endif
	else
" 		if a:0 == '0'
" 		    echo "XXX" . l:chapter_name
" 		else
	    if a:0 != 0
		return substitute(strpart(l:chapter_name,0,b:atp_TruncateStatusSection), '\_s*$', '','')
	    endif
	endif

    elseif l:chapter_name == "" && l:section_name != ""
	if l:subsection_name != ""
" 		if a:0 == '0'
" 		    echo "XXX" . l:section_name . "/" . l:subsection_name 
" 		else
	    if a:0 != 0
		return substitute(strpart(l:section_name,0,b:atp_TruncateStatusSection/2), '\_s*$', '','') . "/" . substitute(strpart(l:subsection_name,0,b:atp_TruncateStatusSection/2), '\_s*$', '','')
	    endif
	else
" 		if a:0 == '0'
" 		    echo "XXX" . l:section_name
" 		else
	    if a:0 != 0
		return substitute(strpart(l:section_name,0,b:atp_TruncateStatusSection), '\_s*$', '','')
	    endif
	endif

    elseif l:chapter_name == "" && l:section_name == "" && l:subsection_name != ""
" 	    if a:0 == '0'
" 		echo "XXX" . l:subsection_name
" 	    else
	if a:0 != 0
	    return substitute(strpart(l:subsection_name,0,b:atp_TruncateStatusSection), '\_s*$', '','')
	endif
    endif
endfunction
command! -buffer CTOC		:call CTOC()
" }}}3
" }}}2
" }}}

" Labels Front End Finction. The search engine/show function are in autoload/atplib.vim script
" library.
" {{{ Labels
function! s:Labels()
    let t:atp_bufname=bufname("%")
    let l:bufname=resolve(fnamemodify(t:atp_bufname,":p"))
    " Generate the dictionary with labels
    let t:atp_labels=atplib#generatelabels(l:bufname)
    " Show the labels in seprate window
    call atplib#showlabels(t:atp_labels[l:bufname])
endfunction
nnoremap <Plug>ATP_Labels	:call <SID>Labels()
command! -buffer Labels		:call <SID>Labels()
" }}}

" Edit Input Files
" {{{1 Edit Input Files 
function! EditInputFile(...)

    let l:mainfile=b:atp_MainFile

    if a:0 == 0
	let l:inputfile=""
	let l:bufname=b:atp_MainFile
	let l:opencom="edit"
    elseif a:0 == 1
	let l:inputfile=a:1
	let l:bufname=b:atp_MainFile
	let l:opencom="edit"
    else
	let l:inputfile=a:1
	let l:opencom=a:2

	" the last argument is the bufername in which search for the input files 
	if a:0 > 2
	    let l:bufname=a:3
	else
	    let l:bufname=b:atp_MainFile
	endif
    endif

    let l:dir=fnamemodify(b:atp_MainFile,":p:h")

    if a:0 == 0
	let l:inputfiles=FindInputFiles(l:bufname)
    else
	let l:inputfiles=FindInputFiles(l:bufname,0)
    endif

    if !len(l:inputfiles) > 0
	return 
    endif

    if index(keys(l:inputfiles),l:inputfile) == '-1'
	let l:which=input("Which file to edit? <enter> for none ","","customlist,EI_compl")
	if l:which == ""
	    return
	endif
    else
	let l:which=l:inputfile
    endif

    if l:which =~ '^\s*\d\+\s*$'
	let l:ifile=keys(l:inputfiles)[l:which-1]
    else
	let l:ifile=l:which
    endif

    "if the choosen file is the main file put the whole path.
"     if l:ifile == fnamemodify(b:atp_MainFile,":t")
" 	let l:ifile=b:atp_MainFile
"     endif

    "g:texmf should end with a '/', if not add it.
    if g:texmf !~ "\/$"
	let g:texmf=g:texmf . "/"
    endif

    " remove all '"' from the line (latex do not supports file names with '"')
    " this make the function work with lines like: '\\input "file name with spaces.tex"'
    let l:ifile=substitute(l:ifile,'^\s*\"\|\"\s*$','','g')
    " add .tex extension if it was not present
    if l:inputfiles[l:ifile][0] == 'input' || l:inputfiles[l:ifile][0] == 'include'
	let l:ifilename=atplib#append(l:ifile,'.tex')
    elseif l:inputfiles[l:ifile][0] == 'bib'
	let l:ifilename=atplib#append(l:ifile,'.bib')
    elseif  l:inputfiles[l:ifile][0] == 'main file'
	let l:ifilename=b:atp_MainFile
    endif
    if l:ifile !~ '\s*\/'
	if filereadable(l:dir . "/" . l:ifilename) 
	    let s:ft=&filetype
	    exe "edit " . fnameescape(b:atp_OutDir . l:ifilename)
	    let &l:filetype=s:ft
	else
	    if l:inputfiles[l:ifile][0] == 'input' || l:inputfiles[l:ifile][0] == 'include'
		let l:ifilename=findfile(l:ifile,g:texmf . '**')
		let s:ft=&filetype
		exe l:opencom . " " . fnameescape(l:ifilename)
		let &l:filetype=s:ft
		let b:atp_MainFile=l:mainfile
	    elseif l:inputfiles[l:ifile][0] == 'bib' 
		let s:ft=&filetype
		exe l:opencom . " " . l:inputfiles[l:ifile][2]
		let &l:filetype=s:ft
		let b:atp_MainFile=l:mainfile
	    elseif  l:inputfiles[l:ifile][0] == 'main file' 
		exe l:opencom . " " . b:atp_MainFile
		let b:atp_MainFile=l:mainfile
	    endif
	endif
    else
	exe l:opencom . " " . fnameescape(l:ifilename)
	let b:atp_MainFile=l:mainfile
    endif
endfunction
command! -buffer -nargs=* -complete=customlist,<SID>EI_compl	EditInputFile 	:call <SID>EditInputFile(<f-args>)
nnoremap <silent> <buffer> <Plug>EditInputFile			:call <SID>EditInputFile(<f-args>)<CR>


fun! s:EI_compl(A,P,L)
"     let l:inputfiles=FindInputFiles(bufname("%"),1)

    let l:inputfiles=filter(FindInputFiles(b:atp_MainFile,1), 'v:key !~ fnamemodify(bufname("%"),":t:r")')
    " rewrite the keys of FindInputFiles the order: input files, bibfiles
    let l:oif=[]
    for l:key in keys(l:inputfiles)
	if l:inputfiles[l:key][0] == 'main file'
	    call add(l:oif,fnamemodify(l:key,":t"))
	endif
    endfor
    for l:key in keys(l:inputfiles)
	if l:inputfiles[l:key][0] == 'input'
	    call add(l:oif,l:key)
	endif
    endfor
    for l:key in keys(l:inputfiles)
	if l:inputfiles[l:key][0] == 'include'
	    call add(l:oif,l:key)
	endif
    endfor
    for l:key in keys(l:inputfiles)
	if l:inputfiles[l:key][0] == 'bib'
	    call add(l:oif,l:key)
	endif
    endfor

    " check what is already written, if it matches something return only the
    " matching strings
    let l:return_oif=[]
    for l:i in l:oif
	if l:i =~ '^' . a:A 
	    call add(l:return_oif,l:i)
	endif
    endfor
    return l:return_oif
endfun
" }}}1

" Motion functions through environments and sections. 
" {{{ Motion functions
" Move to next environment which name is given as the argument. Do not wrap
" around the end of the file.
function! s:NextEnv(...)
    let env_name = ( a:0 == 0 ? '[^}]*' : a:1 )
    call search('\%(%.*\)\@<!\\begin{' . env_name . '.*}', 'W')
    let @/='\%(%.*\)\@<!\\begin{' . env_name . '.*}'
endfunction
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NEnv		:call <SID>NextEnv(<f-args>)
nnoremap <silent> <Plug>NextEnv		:call <SID>NextEnv('[^}]*')

function! s:PrevEnv(...)
    let env_name = a:0 == 0 ? '[^}]*' : a:1
    call search('\%(%.*\)\@<!\\begin{' . env_name . '.*}', 'bW')
    let @/='\%(%.*\)\@<!\\begin{' . env_name . '.*}'
endfunction
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PEnv		:call <SID>PrevEnv(<f-args>)
nnoremap <silent> <Plug>PreviousEnv	:call <SID>PrevEnv('[^}]*')

" Move to next section, the extra argument is a pattern to match for the
" section title. The first, obsolete argument stands for:
" part,chapter,section,subsection,etc.
" This commands wrap around the end of the file.
function! s:NextSection(secname,...)
    let section_title_pattern = ( a:0 == 0 ? '' : '\s*{.*' . a:1 )
    call search('\\' . a:secname . '\>' . section_title_pattern ,'w')
    let @/='\\' . a:secname . '\>' . section_title_pattern
endfunction
nnoremap <silent> <Plug>GoToNextSection		:call <SID>NextSection('section')
nnoremap <silent> <Plug>GoToNextChapter		:call <SID>NextSection('chapter')
nnoremap <silent> <Plug>GoToNextPart		:call <SID>NextSection('part')
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NSec		:call <SID>NextSection('section',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NChap		:call <SID>NextSection('chapter',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NPart		:call <SID>NextSection('part',<f-args>)

function! s:PreviousSection(secname,...)
    let section_title_pattern = ( a:0 == 0 ? '' : '\s*{.*' . a:1 )
    call search('\\' . a:secname . '\>' . section_title_pattern ,'bw')
    let @/='\\' . a:secname . '\>' . section_title_pattern
endfunction
nnoremap <silent> <Plug>GoToPreviousSection		:call <SID>PreviousSection('section')
nnoremap <silent> <Plug>GoToPreviousChapter		:call <SID>PreviousSection('chapter')
nnoremap <silent> <Plug>GoToPreviousPart		:call <SID>PreviousSection('part')
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PSec		:call <SID>PreviousSection('section',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PChap		:call <SID>PreviousSection('chapter',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PPart		:call <SID>PreviousSection('part',<f-args>)

function! Env_compl(A,P,L)
    let l:envlist=sort(['abstract', 'definition', 'equation', 'proposition', 
		\ 'theorem', 'lemma', 'array', 'tikzpicture', 
		\ 'tabular', 'table', 'align\*\?', 'alignat\*\?', 'proof', 
		\ 'corollary', 'enumerate', 'examples\?', 'itemize', 'remark', 
		\ 'notation', 'center', 'quotation', 'quote', 'tabbing', 
		\ 'picture', 'minipage', 'list', 'flushright', 'flushleft', 
		\ 'figure', 'eqnarray', 'thebibliography', 'titlepage', 
		\ 'verbatim', 'verse' ])
    let l:returnlist=[]
    for l:env in l:envlist
	if l:env =~ '^' . a:A 
	    call add(l:returnlist,l:env)
	endif
    endfor
    return l:returnlist
endfunction
" }}}

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
