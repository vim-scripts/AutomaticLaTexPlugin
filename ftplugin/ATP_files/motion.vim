" Author:	Marcin Szamotulski
" This file contains motion and highlight functions of ATP.

" Load once variable
let s:loaded	= !exists("s:loaded") ? 1 : 2

" All table  of contents stuff: variables, functions and commands. 
" {{{ Table Of Contents
" {{{2 Variabels
let g:atp_sections={
    \	'chapter' 	: [           '\m^\s*\(\\chapter\*\?\s*{\)',	'\m\\chapter\*'],	
    \	'section' 	: [           '\m^\s*\(\\section\*\?\s*{\)',	'\m\\section\*'],
    \ 	'subsection' 	: [	   '\m^\s*\(\\subsection\*\?\s*{\)',	'\m\\subsection\*'],
    \	'subsubsection' : [ 	'\m^\s*\(\\subsubsection\*\?\s*{\)',	'\m\\subsubsection\*'],
    \	'bibliography' 	: ['\m^\s*\(\\begin\s*{\s*thebibliography\s*}\|\\bibliography\s*{\)' , 'nopattern'],
    \	'abstract' 	: ['\m^\s*\(\\begin\s*{abstract}\|\\abstract\s*{\)',	'nopattern'],
    \   'part'		: [ 		 '\m^\s*\(\\part\*\?\s*{\)',	'\m\\part\*']}

"--Make TOC -----------------------------
" This makes sense only for latex documents.
"
" Notes: Makeing toc from aux file:
" 	+ is fast
" 	+ one gets correct numbers
" 	- one doesn't get line numbers
" 		/ the title might be modified thus one can not make a pattern
" 		    which works in all situations, while this is important for 
" 		    :DeleteSection command /
"
" {{{2 s:find_toc_lines
function! s:find_toc_lines()
    let toc_lines_nr=[]
    let toc_lines=[]
    let b:toc_lines_nr=toc_lines_nr

    let pos_saved=getpos(".")
    let pos=[0,1,1,0]
    keepjumps call setpos(".",pos)

    " Pattern:
    let j=0
    for section in keys(g:atp_sections)
	if j == 0 
	    let filter=g:atp_sections[section][0] . ''
	else
	    let filter=filter . '\|' . g:atp_sections[section][0] 
	endif
	let j+=1
    endfor
"     let b:filter=filter

    " Searching Loop:
    let line=search(filter,'W')
    while line
	call add(toc_lines_nr,line)
	let line=search(filter,'W')
    endwhile
    keepjumps call setpos(".",pos_saved)
    for line in toc_lines_nr
	call add(toc_lines,getline(line))
    endfor
    return toc_lines
endfunction
" {{{2 s:maketoc 
" this will store information: 
" { 'linenumber' : ['chapter/section/..', 'sectionnumber', 'section title', '0/1=not starred/starred'] }
function! s:maketoc(filename)
    let toc={}

    " if the dictinary with labels is not defined, define it
    if !exists("t:atp_labels")
	let t:atp_labels = {}
    endif

    let texfile		= []
    " getbufline reads only loaded buffers, unloaded can be read from file.
    let bufname		= fnamemodify(a:filename,":t")
    let texfile 	= ( bufloaded(bufname)  ? getbufline("^" . bufname . "$","1","$") : readfile(a:filename) )
    let texfile_copy	= deepcopy(texfile)

    let true	= 1
    let i	= 0
    " remove the part before \begin{document}
    while true == 1 && len(texfile)>0
	let true = ( texfile[0] =~ '\\begin\s*{document}' ? 0 : 1 )
	call remove(texfile,0)
	let i+=1
    endwhile
    let bline		= i
    let i		= 1
    " set variables for chapter/section numbers
    for section in keys(g:atp_sections)
	let ind{section} = 0
    endfor
    " make a filter
    let j = 0
    for section in keys(g:atp_sections)
	let filter = ( j == 0 ? g:atp_sections[section][0] . '' : filter . '\|' . g:atp_sections[section][0] )
	let j+=1
    endfor
    " ToDo: HOW TO MAKE THIS FAST?
    let s:filtered	= filter(deepcopy(texfile), 'v:val =~ filter')

    for line in s:filtered
	for section in keys(g:atp_sections)
	    if line =~ g:atp_sections[section][0] 
		if line !~ '^\s*%'
		    " THIS DO NOT WORKS WITH \abstract{ --> empty set, but with
		    " \chapter{title} --> title, solution: the name of
		    " 'Abstract' will be plased, as we know what we have
		    " matched
		    let title	= line

		    " test if it is a starred version.
		    let star=0
		    if g:atp_sections[section][1] != 'nopattern' && line =~ g:atp_sections[section][1] 
			let star=1 
		    else
			let star=0
		    endif

		    " Problem: If there are two sections with the same title, this
		    " does 't work:
		    let idx	= index(texfile,line)
		    call remove(texfile, idx)
		    let i	= idx
		    let tline	= i+bline+1
		    let bline	+=1

		    " Find Title:
		    let start	= stridx(title,'{')+1
		    let title	= strpart(title,start)
		    " we are looking for the maching '}' 
		    let l:count	= 1
		    let i=-1
		    while i<=len(title)
			let i+=1
			if strpart(title,i,1) == '{'	
			    let l:count+=1
			elseif strpart(title,i,1) == '}'
			    let l:count-=1
			endif
			if l:count == 0
			    break
			endif
		    endwhile	
		    let title = strpart(title,0,i)

		    " Section Number:
		    " if it is not starred version add one to the section number
		    " or it is not an abstract 
		    if star == 0  
			if !(section == 'chapter' && title =~ '^\cabstract$')
			    let ind{section}+=1
			endif
		    endif

		    if section == 'part'
			let indchapter		= 0
			let indsection		= 0
			let indsubsection	= 0
			let indsubsubsection	= 0
		    elseif section ==  'chapter'
			let indsection		= 0
			let indsubsection	= 0
			let indsubsubsection	= 0
		    elseif section ==  'section'
			let indsubsection	= 0
			let indsubsubsection	= 0
		    elseif section ==  'subsection'
			let indsubsubsection	= 0
		    endif

		    " Find Short Title:
		    let shorttitle=line
		    let start=stridx(shorttitle,'[')+1
		    if start == 0
			let shorttitle=''
		    else
			let shorttitle=strpart(shorttitle,start)
			" we are looking for the maching ']' 
			let l:count=1
			let i=-1
			while i<=len(shorttitle)
			    let i+=1
			    if strpart(shorttitle,i,1) == '['	
				let l:count+=1
			    elseif strpart(shorttitle,i,1) == ']'
				let l:count-=1
			    endif
			    if l:count==0
				break
			    endif
			endwhile	
			let shorttitle = strpart(shorttitle,0,i)
		    endif

		    "ToDo: if section is bibliography (using bib) then find the first
		    " empty line:
		    if section == "bibliography" && line !~ '\\begin\s*{\s*thebibliography\s*}'
			let idx	= tline-1
			while texfile_copy[idx] !~ '^\s*$'
			    let idx-= 1
			endwhile
" 			" We add 1 as we want the first non blank line, and one more
" 			" 1 as we want to know the line number not the list index
" 			" number:
			let tline=idx+1
		    endif

		    " Add results to the dictionary:
		    call extend(toc, { tline : [ section, ind{section}, title, star, shorttitle] }) 

		endif
	    endif
	endfor
    endfor
    if exists("t:atp_toc")
	call extend(t:atp_toc, { a:filename : toc }, "force")
    else
	let t:atp_toc = { a:filename : toc }
    endif
    return t:atp_toc
endfunction
" {{{2 s:buflist
if !exists("t:buflist")
    let t:buflist=[]
endif
function! s:buflist()
    " this names are used in TOC and passed to s:maketoc, which
    " makes a dictionary whose keys are the values of name defined
    " just below:
    let name=resolve(fnamemodify(bufname("%"),":p"))
    " add an entry to the list t:buflist if it is not there.
    if bufname("") =~ ".tex" && index(t:buflist,name) == -1
	call add(t:buflist,name)
    endif
    return t:buflist
endfunction
call s:buflist()
" {{{2 RemoveFromBufList
if !exists("*RemoveFromBufList")
    function RemoveFromBufList()
	let i=1
	for f in t:buflist
	    echo "(" . i . ") " . f
	    let i+=1
	endfor
	let which=input("Which file to remove (press <Enter> for none)")
	if which != "" && which =~ '\d\+'
	    call remove(t:buflist,f-1)
	endif
    endfunction
endif
" {{{2 s:showtoc
function! s:showtoc(toc,...)
    let new=0
    if a:0 == 1
	let new=a:1
    endif
    " this is a dictionary of line numbers where a new file begins.
    let cline=line(".")
"     " Open new window or jump to the existing one.
"     " Remember the place from which we are coming:
"     let t:atp_bufname=bufname("")
"     let t:atp_winnr=winnr()	 these are already set by TOC()
    let bname="__ToC__"
    let tocwinnr=bufwinnr("^" . bname . "$") 
"     echomsg "DEBUG a " . tocwinnr
    if tocwinnr != -1
	" Jump to the existing window.
	    exe tocwinnr . " wincmd w"
	    silent exe "%delete"
    else
	" Open new window if its width is defined (if it is not the code below
	" will put toc in the current buffer so it is better to return.
	if !exists("t:toc_window_width")
	    echoerr "t:toc_window_width not set"
	    return
	endif
	let openbuffer=t:toc_window_width . "vsplit +setl\\ wiw=15\\ buftype=nofile\\ tabstop=1\\ filetype=toc_atp\\ nowrap __ToC__"
	silent exe openbuffer
	" We are setting the address from which we have come.
	silent call atplib#setwindow()
    endif
    let number=1
    " this is the line number in ToC.
    " number is a line number relative to the file listed in ToC.
    " the current line number is linenumber+number
    " there are two loops: one over linenumber and the second over number.
    let numberdict={}
    " this variable will be used to set the cursor position in ToC.
    for openfile in keys(a:toc)
	call extend(numberdict,{ openfile : number })
	let part_on=0
	let chap_on=0
	let chnr=0
	let secnr=0
	let ssecnr=0
	let sssecnr=0
	let path=fnamemodify(bufname(""),":p:h")
	for line in keys(a:toc[openfile])
	    if a:toc[openfile][line][0] == 'chapter'
		let chap_on=1
		break
	    elseif a:toc[openfile][line][0] == 'part'
		let part_on=1
	    endif
	endfor
	let sorted	= sort(keys(a:toc[openfile]),"atplib#CompareNumbers")
	let len		= len(sorted)
	" write the file name in ToC (with a full path in paranthesis)
	call setline(number,fnamemodify(openfile,":t") . " (" . fnamemodify(openfile,":p:h") . ")")
	let number+=1
	for line in sorted
	    let lineidx=index(sorted,line)
	    let nlineidx=lineidx+1
	    if nlineidx< len(sorted)
		let nline=sorted[nlineidx]
	    else
		let nline=line("$")
	    endif
	    let lenght=len(line) 	
	    if lenght == 0
		let showline="     "
	    elseif lenght == 1
		let showline="    " . line
	    elseif lenght == 2
		let showline="   " . line
	    elseif lenght == 3
		let showline="  " . line
	    elseif lenght == 4
		let showline=" " . line
	    elseif lenght>=5
		let showline=line
	    endif
	    " Print ToC lines.
	    if a:toc[openfile][line][0] == 'abstract' || a:toc[openfile][line][2] =~ '^\cabstract$'
		call setline(number, showline . "\t" . "  " . "Abstract" )
	    elseif a:toc[openfile][line][0] =~ 'bibliography\|references'
		call setline (number, showline . "\t" . "  " . a:toc[openfile][line][2])
	    elseif a:toc[openfile][line][0] == 'part'
		let partnr=a:toc[openfile][line][1]
		let nr=partnr
		if a:toc[openfile][line][3]
		    "if it is stared version
		    let nr=substitute(nr,'.',' ','')
		endif
		if a:toc[openfile][line][4] != ''
" 		    call setline (number, showline . "\t" . nr . " " . a:toc[openfile][line][4])
		    call setline (number, showline . "\t" . " " . a:toc[openfile][line][4])
		else
" 		    call setline (number, showline . "\t" . nr . " " . a:toc[openfile][line][2])
		    call setline (number, showline . "\t" . " " . a:toc[openfile][line][2])
		endif
	    elseif a:toc[openfile][line][0] == 'chapter'
		let chnr=a:toc[openfile][line][1]
		let nr=chnr
		if a:toc[openfile][line][3]
		    "if it is stared version
		    let nr=substitute(nr,'.',' ','')
		endif
		if a:toc[openfile][line][4] != ''
		    call setline (number, showline . "\t" . nr . " " . a:toc[openfile][line][4])
		else
		    call setline (number, showline . "\t" . nr . " " . a:toc[openfile][line][2])
		endif
	    elseif a:toc[openfile][line][0] == 'section'
		let secnr=a:toc[openfile][line][1]
		if chap_on
		    let nr=chnr . "." . secnr  
		    if a:toc[openfile][line][3]
			"if it is stared version
			let nr=substitute(nr,'.',' ','g')
		    endif
		    if a:toc[openfile][line][4] != ''
			call setline (number, showline . "\t\t" . nr . " " . a:toc[openfile][line][4])
		    else
			call setline (number, showline . "\t\t" . nr . " " . a:toc[openfile][line][2])
		    endif
		else
		    let nr=secnr 
		    if a:toc[openfile][line][3]
			"if it is stared version
			let nr=substitute(nr,'.',' ','g')
		    endif
		    if a:toc[openfile][line][4] != ''
			call setline (number, showline . "\t" . nr . " " . a:toc[openfile][line][4])
		    else
			call setline (number, showline . "\t" . nr . " " . a:toc[openfile][line][2])
		    endif
		endif
	    elseif a:toc[openfile][line][0] == 'subsection'
		let ssecnr=a:toc[openfile][line][1]
		if chap_on
		    let nr=chnr . "." . secnr  . "." . ssecnr
		    if a:toc[openfile][line][3]
			"if it is stared version 
			let nr=substitute(nr,'.',' ','g')
		    endif
		    if a:toc[openfile][line][4] != ''
			call setline (number, showline . "\t\t\t" . nr . " " . a:toc[openfile][line][4])
		    else
			call setline (number, showline . "\t\t\t" . nr . " " . a:toc[openfile][line][2])
		    endif
		else
		    let nr=secnr  . "." . ssecnr
		    if a:toc[openfile][line][3]
			"if it is stared version 
			let nr=substitute(nr,'.',' ','g')
		    endif
		    if a:toc[openfile][line][4] != ''
			call setline (number, showline . "\t\t" . nr . " " . a:toc[openfile][line][4])
		    else
			call setline (number, showline . "\t\t" . nr . " " . a:toc[openfile][line][2])
		    endif
		endif
	    elseif a:toc[openfile][line][0] == 'subsubsection'
		let sssecnr=a:toc[openfile][line][1]
		if chap_on
		    let nr=chnr . "." . secnr . "." . sssecnr  
		    if a:toc[openfile][line][3]
			"if it is stared version
			let nr=substitute(nr,'.',' ','g')
		    endif
		    if a:toc[openfile][line][4] != ''
			call setline(number, a:toc[openfile][line][0] . "\t\t\t" . nr . " " . a:toc[openfile][line][4])
		    else
			call setline(number, a:toc[openfile][line][0] . "\t\t\t" . nr . " " . a:toc[openfile][line][2])
		    endif
		else
		    let nr=secnr  . "." . ssecnr . "." . sssecnr
		    if a:toc[openfile][line][3]
			"if it is stared version 
			let nr=substitute(nr,'.',' ','g')
		    endif
		    if a:toc[openfile][line][4] != ''
			call setline (number, showline . "\t\t" . nr . " " . a:toc[openfile][line][4])
		    else
			call setline (number, showline . "\t\t" . nr . " " . a:toc[openfile][line][2])
		    endif
		endif
	    else
		let nr=""
	    endif
	    let number+=1
	endfor
    endfor
    " set the cursor position on the correct line number.
    " first get the line number of the begging of the ToC of t:atp_bufname
    " (current buffer)
" 	let t:numberdict=numberdict	"DEBUG
" 	t:atp_bufname is the full path to the current buffer.
    let num		= numberdict[t:atp_bufname]
    let sorted		= sort(keys(a:toc[t:atp_bufname]), "atplib#CompareNumbers")
    let t:sorted	= sorted
    for line in sorted
	if cline>=line
	    let num+=1
	endif
    keepjumps call setpos('.',[bufnr(""),num,1,0])
    endfor
   
    " Help Lines:
    if search('<Enter> jump and close', 'nW') == 0
	call append('$', [ '', 			
		\ '<Space> jump', 
		\ '<Enter> jump and close', 	
		\ 's       jump and split', 
		\ 'y or c  yank label', 	
		\ 'p       paste label', 
		\ 'q       close', 		
		\ ':DeleteSection', 
		\ ':PasteSection', 		
		\ ':SectionStack', 
		\ ':Undo' ])
    endif
endfunction
"}}}2

" This is the User Front End Function 
"{{{2 TOC
function! s:TOC(...)
    " skip generating t:atp_toc list if it exists and if a:0 != 0
    let skip = 0
    if a:0 >= 1 && a:1 == 1
	let skip = 1
    endif
    let new=0
    if a:0 >= 1
	let new=1
    endif
    if &l:filetype != 'tex'    
	echoerr "Wrong 'filetype'. This function works only for latex documents."
	return
    endif
    " for each buffer in t:buflist (set by s:buflist)
    if skip == 0 || ( skip == 1 && !exists("t:atp_toc") )
	for buffer in t:buflist 
    " 	    let t:atp_toc=s:make_toc(buffer)
		let t:atp_toc=s:maketoc(buffer)
	endfor
    endif
    call s:showtoc(t:atp_toc,new)
endfunction
command! -buffer -nargs=? TOC	:call <SID>TOC(<f-args>)
nnoremap <Plug>ATP_TOC		:call <SID>TOC(1)<CR>

" }}}2

" This finds the name of currently eddited section/chapter units. 
" {{{2 Current TOC
" ToDo: make this faster!
" {{{3 s:nearestsection
" This function finds the section name of the current section unit with
" respect to the dictionary a:section={ 'line number' : 'section name', ... }
" it returns the [ section_name, section line, next section line ]
function! s:nearestsection(section)
    let cline=line('.')

    let sorted=sort(keys(a:section), "atplib#CompareNumbers")
    let x=0
    while x<len(sorted) && sorted[x]<=cline
       let x+=1 
    endwhile
    if x>=1 && x < len(sorted)
	let section_name=a:section[sorted[x-1]]
	return [section_name, sorted[x-1], sorted[x]]
    elseif x>=1 && x >= len(sorted)
	let section_name=a:section[sorted[x-1]]
	return [section_name,sorted[x-1], line('$')]
    elseif x<1 && x < len(sorted)
	" if we are before the first section return the empty string
	return ['','0', sorted[x]]
    elseif x<1 && x >= len(sorted)
	return ['','0', line('$')]
    endif
endfunction
" }}}3
" {{{3 s:ctoc
function! s:ctoc()
    if &l:filetype != 'tex' 
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

    " l:count where the preambule ends
    let buffer=getbufline(bufname("%"),"1","$")
    let i=0
    let line=buffer[0]
    while line !~ '\\begin\s*{document}' && i < len(buffer)
	let line=buffer[i]
	if line !~ '\\begin\s*{document}' 
	    let i+=1
	endif
    endwhile
	
    " if we are before the '\\begin{document}' line: 
    if line(".") <= i
	let return=['Preambule']
	return return
    endif

    let chapter={}
    let section={}
    let subsection={}

    for key in keys(t:atp_toc[t:atp_bufname])
	if t:atp_toc[t:atp_bufname][key][0] == 'chapter'
	    " return the short title if it is provided
	    if t:atp_toc[t:atp_bufname][key][4] != ''
		call extend(chapter, {key : t:atp_toc[t:atp_bufname][key][4]},'force')
	    else
		call extend(chapter, {key : t:atp_toc[t:atp_bufname][key][2]},'force')
	    endif
	elseif t:atp_toc[t:atp_bufname][key][0] == 'section'
	    " return the short title if it is provided
	    if t:atp_toc[t:atp_bufname][key][4] != ''
		call extend(section, {key : t:atp_toc[t:atp_bufname][key][4]},'force')
	    else
		call extend(section, {key : t:atp_toc[t:atp_bufname][key][2]},'force')
	    endif
	elseif t:atp_toc[t:atp_bufname][key][0] == 'subsection'
	    " return the short title if it is provided
	    if t:atp_toc[t:atp_bufname][key][4] != ''
		call extend(subsection, {key : t:atp_toc[t:atp_bufname][key][4]},'force')
	    else
		call extend(subsection, {key : t:atp_toc[t:atp_bufname][key][2]},'force')
	    endif
	endif
    endfor

    " Remove $ from chapter/section/subsection names to save the space.
    let chapter_name=substitute(s:nearestsection(chapter)[0],'\$','','g')
    let chapter_line=s:nearestsection(chapter)[1]
    let chapter_nline=s:nearestsection(chapter)[2]

    let section_name=substitute(s:nearestsection(section)[0],'\$','','g')
    let section_line=s:nearestsection(section)[1]
    let section_nline=s:nearestsection(section)[2]
"     let b:section=s:nearestsection(section)		" DEBUG

    let subsection_name=substitute(s:nearestsection(subsection)[0],'\$','','g')
    let subsection_line=s:nearestsection(subsection)[1]
    let subsection_nline=s:nearestsection(subsection)[2]
"     let b:ssection=s:nearestsection(subsection)		" DEBUG

    let names	= [ chapter_name ]
    if (section_line+0 >= chapter_line+0 && section_line+0 <= chapter_nline+0) || chapter_name == '' 
	call add(names, section_name) 
    elseif subsection_line+0 >= section_line+0 && subsection_line+0 <= section_nline+0
	call add(names, subsection_name)
    endif
    return names
endfunction
" }}}3
" {{{3 CTOC
function! CTOC(...)
    " if there is any argument given, then the function returns the value
    " (used by ATPStatus()), otherwise it echoes the section/subsection
    " title. It returns only the first b:atp_TruncateStatusSection
    " characters of the the whole titles.
    let names=s:ctoc()
    let b:names=names
" 	echo " DEBUG CTOC " . join(names)
    let chapter_name=get(names,0,'')
    let section_name=get(names,1,'')
    let subsection_name=get(names,2,'')

    if chapter_name == "" && section_name == "" && subsection_name == ""

    if a:0 == '0'
	echo "" 
    else
	return ""
    endif
	
    elseif chapter_name != ""
	if section_name != ""
" 		if a:0 == '0'
" 		    echo "XXX" . chapter_name . "/" . section_name 
" 		else
	    if a:0 != 0
		return substitute(strpart(chapter_name,0,b:atp_TruncateStatusSection/2), '\_s*$', '','') . "/" . substitute(strpart(section_name,0,b:atp_TruncateStatusSection/2), '\_s*$', '','')
	    endif
	else
" 		if a:0 == '0'
" 		    echo "XXX" . chapter_name
" 		else
	    if a:0 != 0
		return substitute(strpart(chapter_name,0,b:atp_TruncateStatusSection), '\_s*$', '','')
	    endif
	endif

    elseif chapter_name == "" && section_name != ""
	if subsection_name != ""
" 		if a:0 == '0'
" 		    echo "XXX" . section_name . "/" . subsection_name 
" 		else
	    if a:0 != 0
		return substitute(strpart(section_name,0,b:atp_TruncateStatusSection/2), '\_s*$', '','') . "/" . substitute(strpart(subsection_name,0,b:atp_TruncateStatusSection/2), '\_s*$', '','')
	    endif
	else
" 		if a:0 == '0'
" 		    echo "XXX" . section_name
" 		else
	    if a:0 != 0
		return substitute(strpart(section_name,0,b:atp_TruncateStatusSection), '\_s*$', '','')
	    endif
	endif

    elseif chapter_name == "" && section_name == "" && subsection_name != ""
" 	    if a:0 == '0'
" 		echo "XXX" . subsection_name
" 	    else
	if a:0 != 0
	    return substitute(strpart(subsection_name,0,b:atp_TruncateStatusSection), '\_s*$', '','')
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
    let bufname=resolve(fnamemodify(t:atp_bufname,":p"))
    " Generate the dictionary with labels
    let t:atp_labels=atplib#generatelabels(bufname)
    " Show the labels in seprate window
    call atplib#showlabels(t:atp_labels[bufname])
endfunction
nnoremap <Plug>ATP_Labels	:call <SID>Labels()<CR>
command! -buffer Labels		:call <SID>Labels()
" }}}

" Edit Input Files
" This functoin is used to open input files, it also sets up correctly some variables
" which are important for project files.
" {{{1 Edit Input Files 
if s:loaded == 1
function! EditInputFile(...)

    let mainfile=b:atp_MainFile

    if a:0 == 0
	let inputfile	= ""
	let bufname	= b:atp_MainFile
	let opencom	= "edit"
    elseif a:0 == 1
	let inputfile	= a:1
	let bufname	= b:atp_MainFile
	let opencom	= "edit"
    else
	let inputfile	= a:1
	let opencom	= a:2

	" the last argument is the bufername in which search for the input files 
	if a:0 > 2
	    let bufname = a:3
	else
	    let bufname	= b:atp_MainFile
	endif
    endif

    let dir	= fnamemodify(b:atp_MainFile,":p:h")

    if a:0 == 0
	let inputfiles=FindInputFiles(bufname)
    else
	let inputfiles=FindInputFiles(bufname,0)
    endif

    if !len(inputfiles) > 0
	return 
    endif

    if index(keys(inputfiles),inputfile) == '-1'
	let which=input("Which file to edit? <enter> for none ","","customlist,EI_compl")
	if which == ""
	    return
	endif
    else
	let which=inputfile
    endif

    if which =~ '^\s*\d\+\s*$'
	let ifile=keys(inputfiles)[which-1]
    else
	let ifile=which
    endif

    "if the choosen file is the main file put the whole path.
"     if ifile == fnamemodify(b:atp_MainFile,":t")
" 	let ifile=b:atp_MainFile
"     endif

    "g:texmf should end with a '/', if not add it.
    if g:texmf !~ "\/$"
	let g:texmf=g:texmf . "/"
    endif

    " remove all '"' from the line (latex do not supports file names with '"')
    " this make the function work with lines like: '\\input "file name with spaces.tex"'
    let ifile=substitute(ifile,'^\s*\"\|\"\s*$','','g')
    " add .tex extension if it was not present
    if inputfiles[ifile][0] == 'input' || inputfiles[ifile][0] == 'include'
	let ifilename=atplib#append(ifile,'.tex')
    elseif inputfiles[ifile][0] == 'bib'
	let ifilename=atplib#append(ifile,'.bib')
    elseif  inputfiles[ifile][0] == 'main file'
	let ifilename=b:atp_MainFile
    endif
    if ifile !~ '\s*\/'
	if filereadable(dir . "/" . ifilename) 
	    let s:ft=&l:filetype
	    exe "edit " . fnameescape(b:atp_OutDir . ifilename)
	    let &l:filetype=s:ft
	else
	    if inputfiles[ifile][0] == 'input' || inputfiles[ifile][0] == 'include'
		let ifilename=findfile(ifile,g:texmf . '**')
		let s:ft=&l:filetype
		exe opencom . " " . fnameescape(ifilename)
		let &l:filetype=s:ft
		let b:atp_MainFile=mainfile
	    elseif inputfiles[ifile][0] == 'bib' 
		let s:ft=&l:filetype
		exe opencom . " " . inputfiles[ifile][2]
		let &l:filetype=s:ft
		let b:atp_MainFile=mainfile
	    elseif  inputfiles[ifile][0] == 'main file' 
		exe opencom . " " . b:atp_MainFile
		let b:atp_MainFile=mainfile
	    endif
	endif
    else
	exe opencom . " " . fnameescape(ifilename)
	let b:atp_MainFile=mainfile
    endif
    let b:atp_autex	= 1
endfunction
endif
command! -buffer -nargs=* -complete=customlist,EI_compl		EditInputFile 	:call EditInputFile(<f-args>)
nnoremap <silent> <buffer> <Plug>EditInputFile			:call EditInputFile(<f-args>)<CR>


fun! EI_compl(A,P,L)
"     let inputfiles=FindInputFiles(bufname("%"),1)

    let inputfiles=filter(FindInputFiles(b:atp_MainFile,1), 'v:key !~ fnamemodify(bufname("%"),":t:r")')
    " rewrite the keys of FindInputFiles the order: input files, bibfiles
    let oif=[]
    for key in keys(inputfiles)
	if inputfiles[key][0] == 'main file'
	    call add(oif,fnamemodify(key,":t"))
	endif
    endfor
    for key in keys(inputfiles)
	if inputfiles[key][0] == 'input'
	    call add(oif,key)
	endif
    endfor
    for key in keys(inputfiles)
	if inputfiles[key][0] == 'include'
	    call add(oif,key)
	endif
    endfor
    for key in keys(inputfiles)
	if inputfiles[key][0] == 'bib'
	    call add(oif,key)
	endif
    endfor

    " check what is already written, if it matches something return only the
    " matching strings
    let return_oif=[]
    for i in oif
	if i =~ '^' . a:A 
	    call add(return_oif,i)
	endif
    endfor
    return return_oif
endfun
" }}}1

" Motion functions through environments and sections. 
" {{{ Motion functions
" Move to next environment which name is given as the argument. Do not wrap
" around the end of the file.
function! s:GoToEnvironment(flag,...)
    let env_name 	= ( a:0 >= 1 ? a:1 	: '[^}]*' )
    let flag		= a:flag
    if env_name == 'math'
	let pattern = '\m\%(%.*\)\@<!\%(\%(\\begin\s*{\s*\%(\(dispalyed\)\?math\|\%(fl\)\?align\|eqnarray\|equation\|gather\|multline\|subequations\|xalignat\|xxalignat\)\s*}\)\|\\\[\|\\(\|\\\@!\$\$\?\)'
	silent call search(pattern, flag) 
	call histadd("search", pattern)
	let @/ 	 = pattern
	if getline(".")[col(".")-1] == '$' && col(".") > 1 && 
		    \ ( count(map(synstack(line("."),col(".")-1), 'synIDattr(v:val, "name")'), 'texMathZoneX') == 0 ||
		    \ 	count(map(synstack(line("."),col(".")-1), 'synIDattr(v:val, "name")'), 'texMathZoneY') == 0 )
	    silent call search(pattern, flag) 
	endif
    else
	let pattern = '\m\%(%.*\)\@<!\\begin\s*{\s*' . env_name . '.*}'
	silent call search(pattern, flag)
	call histadd("search", pattern)
	let @/	= pattern
    endif
endfunction
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NEnv		:call <SID>GoToEnvironment('W', <f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PEnv		:call <SID>GoToEnvironment('bW', <f-args>)
nnoremap <silent> <Plug>GoToNextEnvironment					:call <SID>GoToEnvironment('[^}]*', 'W')<CR>
nnoremap <silent> <Plug>GoToPreviousEnvironment					:call <SID>GoToEnvironment('[^}]*', 'bW')<CR>

" Move to next section, the extra argument is a pattern to match for the
" section title. The first, obsolete argument stands for:
" part,chapter,section,subsection,etc.
" This commands wrap around the end of the file.
function! s:NextSection(secname,...)
    let section_title_pattern 	= ( a:0 >= 1 ? '\s*{.*' . a:1	: ''  )
    let mode			= ( a:0 >= 2 ?  a:2		: 'n' )
    " This is not working ?:/
    if mode == 'v' | call cursor(getpos("'<")[1], getpos("'<")[2]) | endif
    if mode == 'v' && visualmode() ==# 'V'
	normal! V
    elseif mode == 'v' 
	normal! v
    endif
    silent call searchpos('\\' . a:secname . '\>' . section_title_pattern ,'w')

    " In visual mode end move the cursor to the end of the section
    if mode == 'v'
	normal b
    endif
    call histadd("search", '\\' . a:secname . '\>' . section_title_pattern)
    let @/	= '\\' . a:secname . '\>' . section_title_pattern
endfunction
nnoremap <silent> <Plug>GoToNextSection		:call <SID>NextSection('section')<CR>
onoremap <silent> <Plug>GoToNextSection		:call <SID>NextSection('section')<CR>
vnoremap <silent> <Plug>GoToNextSection		:call <SID>NextSection('section', '', 'v')<CR>
nnoremap <silent> <Plug>GoToNextChapter		:call <SID>NextSection('chapter')<CR>
onoremap <silent> <Plug>GoToNextChapter		:call <SID>NextSection('chapter')<CR>
vnoremap <silent> <Plug>GoToNextChapter		:call <SID>NextSection('chapter', '', 'v')<CR>
nnoremap <silent> <Plug>GoToNextPart		:call <SID>NextSection('part')<CR>
onoremap <silent> <Plug>GoToNextPart		:call <SID>NextSection('part')<CR>
vnoremap <silent> <Plug>GoToNextPart		:call <SID>NextSection('part', '', 'v')<CR>
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NSec		:call <SID>NextSection('section',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NChap		:call <SID>NextSection('chapter',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NPart		:call <SID>NextSection('part',<f-args>)

function! s:PreviousSection(secname,...)
    let section_title_pattern = ( a:0 == 0 ? '' : '\s*{.*' . a:1 )
    let mode			= ( a:0 >= 2 ?  a:2		: 'n' )
    " This is not working ?:/
    if mode == 'v' | call cursor(getpos("'>")[1], getpos("'>")[2]) | endif
    if mode == 'v' && visualmode() ==# 'V'
	normal! V
    elseif mode == 'v' 
	normal! v
    endif
    let pattern = '\\' . a:secname . '\>' . section_title_pattern
    silent call search(pattern,'bw')
    call histadd(pattern)
    let @/	= pattern
endfunction
nnoremap <silent> <Plug>GoToPreviousSection		:call <SID>PreviousSection('section')<CR>
onoremap <silent> <Plug>GoToPreviousSection		:call <SID>PreviousSection('section')<CR>
vnoremap <silent> <Plug>GoToPreviousSection		:call <SID>PreviousSection('section', '', 'v')<CR>
nnoremap <silent> <Plug>GoToPreviousChapter		:call <SID>PreviousSection('chapter')<CR>
onoremap <silent> <Plug>GoToPreviousChapter		:call <SID>PreviousSection('chapter')<CR>
vnoremap <silent> <Plug>GoToPreviousChapter		:call <SID>PreviousSection('chapter', '', 'v')<CR>
nnoremap <silent> <Plug>GoToPreviousPart		:call <SID>PreviousSection('part')<CR>
onoremap <silent> <Plug>GoToPreviousPart		:call <SID>PreviousSection('part')<CR>
vnoremap <silent> <Plug>GoToPreviousPart		:call <SID>PreviousSection('part', '', 'v')<CR>
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PSec		:call <SID>PreviousSection('section',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PChap		:call <SID>PreviousSection('chapter',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PPart		:call <SID>PreviousSection('part',<f-args>)

function! Env_compl(A,P,L)
    let envlist=sort(['abstract', 'definition', 'equation', 'proposition', 
		\ 'theorem', 'lemma', 'array', 'tikzpicture', 
		\ 'tabular', 'table', 'align\*\?', 'alignat\*\?', 'proof', 
		\ 'corollary', 'enumerate', 'examples\?', 'itemize', 'remark', 
		\ 'notation', 'center', 'quotation', 'quote', 'tabbing', 
		\ 'picture', 'math', 'displaymath', 'minipage', 'list', 'flushright', 'flushleft', 
		\ 'figure', 'eqnarray', 'thebibliography', 'titlepage', 
		\ 'verbatim', 'verse' ])
    let returnlist=[]
    for env in envlist
	if env =~ '^' . a:A 
	    call add(returnlist,env)
	endif
    endfor
    return returnlist
endfunction
" }}}

" Enter over input files
" {{{1
function! Enter()
    let synstack=map(synstack(line("."),col(".")), 'synIDattr(v:val, "name")')
    if count(synstack, 'texInputFile')
	let filename	= atplib#append(matchstr(getline(line(".")), '\\input\s*{\zs[^}]*\ze}'), '.tex')
	if filereadable(fnamemodify(filename, ":p"))
	    silent! execute "edit " . fnamemodify(filename, ":p")
	elseif strpart(getline("."), 0,col(".")-1) =~ '\\usepackage\s*\%(\[[^]]*]\)\=\s*{' && exists("g:atp_developer")
	    let bcol	= searchpos('{\|,', 'bn')[1]
	    let ecol	= searchpos('}\|,', 'n')[1]
	    let packagename 	= strpart(getline("."), bcol, ecol-bcol-1)
	    let g:packagename	= packagename
	    let file	= filter(atplib#FindFiles('tex', 'sty', ':p'), "v:val =~ packagename .'.sty$'")[0]
	    if filereadable(file)
		silent! execute "edit " . file
	    else
		execute "normal j"
	    endif
	else
	    execute "normal j"
	endif
    elseif count(synstack, 'texInput')
	let filename	= atplib#append(matchstr(getline(line(".")), '\\input\s*\zs\S*\ze'), '.tex')
	let g:filename	= filename
	let filepath	= filter(atplib#FindFiles('tex', 'tex', ':p'), "v:val =~ filename .'$'")
	let g:filepath	= copy(filepath)
	let file	= filepath[0]
	if filereadable(file)
	    silent! execute "edit " . file
	else
	    execute "normal j"
	endif
    elseif strpart(getline("."), 0,col(".")-1) =~ '\\documentclass\s*\%(\[[^]]*]\)\=\s*{' && exists("g:atp_developer")
	let bcol	= searchpos('{\|,', 'bn')[1]
	let ecol	= searchpos('}\|,', 'n')[1]
	let classname 	= strpart(getline("."), bcol, ecol-bcol-1)
	let g:classname	= classname
	let file	= filter(atplib#FindFiles('tex', 'cls', ':p'), "v:val =~ classname .'.cls$'")[0]
	if filereadable(file)
	    silent! execute "edit " . file
	else
	    execute "normal j"
	endif
    else
	execute "normal j"
    endif
endfunction
nmap <CR>	:silent call Enter()<CR>
" }}}1

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
