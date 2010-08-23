" Vim library for atp filetype plugin
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Email:	mszamot [AT] gmail [DOT] com

" Outdir: append to '/' to b:atp_OutDir if it is not present. 
"{{{ atplib#outdir
function! atplib#outdir()
    if b:atp_OutDir !~ "\/$"
	let b:atp_OutDir=b:atp_OutDir . "/"
    endif
endfunction
"}}}

" Find Vim Server: find server 'hosting' a file and move to the line.
" {{{1 atplib#FindAndOpen
" Can be used to sync gvim with okular.
" just set in okular:
" 	settings>okular settings>Editor
" 		Editor		Custom Text Editor
" 		Command		gvim --servername GVIM --remote-expr "atplib#FindAndOpen('%f','%l')"
" You can also use this with vim but you should start vim with
" 		vim --servername VIM
" and use servername VIM in the Command above.		
function! atplib#FindAndOpen(file, line)
    let file		= fnamemodify(a:file, ":p:r") . ".tex"
    let server_list	= split(serverlist(), "\n")
    for server in server_list
	if remote_expr(server, "bufexists('".file."')")
	    let use_server	= server
	    break
	else
	    let use_server	= "GVIM"
	endif
    endfor
    call system("gvim --servername " . use_server . " --remote-wait +" . a:line . " " . file . " &")
    return "File:".file." line:".line. " server name:".use_server." Hitch-hiking server:".v:servername 
endfunction
"}}}1

" Labels Tools: GrepAuxFile, SrotLabels, generatelabels and showlabes.
" {{{1 LABELS
" the argument should be: resolved full path to the file:
" resove(fnamemodify(bufname("%"),":p"))

" {{{2 --------------- atplib#GrepAuxFile
function! atplib#GrepAuxFile(...)
    " Aux file to read:
    let aux_filename	= a:0 == 0 ? fnamemodify(b:atp_MainFile, ":r") . ".aux" : a:1 

    if !filereadable(aux_filename)
	" We should worn the user that there is no aux file
	" /this is not visible ! only after using the command 'mes'/
	echohl WarningMsg
	echomsg "There is no aux file. Run ".b:atp_TexCompiler." first."
	echohl Normal
	return []
	" CALL BACK is not working
	" I can not get output of: vim --servername v:servername --remote-expr v:servername
	" for v:servername
	" Here we should run latex to produce auxfile
" 	echomsg "Running " . b:atp_TexCompiler . " to get aux file."
" 	let labels 	= system(b:atp_TexCompiler . " -interaction nonstopmode " . b:atp_MainFile . " 1&>/dev/null  2>1 ; " . " vim --servername ".v:servername." --remote-expr 'atplib#GrepAuxFile()'")
" 	return labels
    endif
"     let aux_file	= readfile(aux_filename)

    let saved_llist	= getloclist(0)
    try
	silent execute 'lvimgrep /\\newlabel\s*{/j ' . fnameescape(aux_filename)
    catch /E480: No match:/
    endtry
    let loc_list	= getloclist(0)
    call setloclist(0, saved_llist)
    call map(loc_list, ' v:val["text"]')

    let labels		= []
"     for line in aux_file
    for line in loc_list
" 	if line =~ '^\\newlabel' 
	    " line is of the form:
	    " \newlabel{<label>}{<rest>}
	    " where <rest> = {<label_number}{<title>}{<counter_name>.<counter_number>}
	    " <counter_number> is usually equal to <label_number>.
	    "
	    " Document classes: article, book, amsart, amsbook, review:
	    " NEW DISCOVERY {\zs\%({[^}]*}\|[^}]\)*\ze} matches for inner part of 
	    " 	{ ... { ... } ... }	/ only one level of being recursive / 
	    " 	The order inside the main \%( \| \) is important.
	    "This is in the case that the author put in the title a command,
	    "for example \mbox{...}, but not something more difficult :)
	    if line =~ '^\\newlabel{[^}]*}{{[^}]*}{[^}]*}{\%({[^}]*}\|[^}]\)*}{[^}]*}'
		let label	= matchstr(line, '^\\newlabel\s*{\zs[^}]*\ze}')
		let rest	= matchstr(line, '^\\newlabel\s*{[^}]*}\s*{\s*{\zs.*\ze}\s*$')
		let l:count = 1
		let i	= 0
		while l:count != 0 
		    let l:count = rest[i] == '{' ? l:count+1 : rest[i] == '}' ? l:count-1 : l:count 
		    let i+= 1
		endwhile
		let number	= substitute(strpart(rest,0,i-1), '{\|}', '', 'g')  
		let rest	= strpart(rest,i)
		let rest	= substitute(rest, '^{[^}]*}{', '', '')
		let l:count = 1
		let i	= 0
		while l:count != 0 
		    let l:count = rest[i] == '{' ? l:count+1 : rest[i] == '}' ? l:count-1 : l:count 
		    let i+= 1
		endwhile
		let counter	= substitute(strpart(rest,i-1), '{\|}', '', 'g')  
		let counter	= strpart(counter, 0, stridx(counter, '.')) 

	    " Document classes: article, book, amsart, amsbook, review
	    " (sometimes the format is a little bit different)
	    elseif line =~ '\\newlabel{[^}]*}{{\d\%(\d\|\.\)*{\d\%(\d\|\.\)*}}{\d*}{\%({[^}]*}\|[^}]\)*}{[^}]*}'
		let list = matchlist(line, 
		    \ '\\newlabel{\([^}]*\)}{{\(\d\%(\d\|\.\)*{\d\%(\d\|\.\)*\)}}{\d*}{\%({[^}]*}\|[^}]\)*}{\([^}]*\)}')
	    	let label	= list[1]
		let number	= list[2]
		let counter	= list[3]
		let number	= substitute(number, '{\|}', '', 'g')
		let counter	= matchstr(counter, '^\w\+')

	    " Document class: article
	    elseif line =~ '\\newlabel{[^}]*}{{\d\%(\d\|\.\)*}{\d\+}}'
		let list = matchlist(line, '\\newlabel{\([^}]*\)}{{\(\d\%(\d\|\.\)*\)}{\d\+}}')
		let label	= list[1]
		let number	= list[2]
		let counter	= ""

	    " Memoir document class uses '\M@TitleReference' command
	    " which doesn't specify the counter number.
	    elseif line =~ '\\M@TitleReference' 
		let label	= matchstr(line, '^\\newlabel\s*{\zs[^}]*\ze}')
		let number	= matchstr(line, '\\M@TitleReference\s*{\zs[^}]*\ze}') 
		let counter	= ""

	    " aamas2010 class
	    elseif line =~ '\\newlabel{[^}]*}{{\d\%(\d\|.\)*{\d\%(\d\|.\)*}{[^}]*}}'
		let label 	= matchstr(line, '\\newlabel{\zs[^}]*\ze}{{\d\%(\d\|.\)*{\d\%(\d\|.\)*}{[^}]*}}')
		let number 	= matchstr(line, '\\newlabel{\zs[^}]*\ze}{{\zs\d\%(\d\|.\)*{\d\%(\d\|.\)*\ze}{[^}]*}}')
		let number	= substitute(number, '{\|}', '', 'g')
		let counter	= ""

	    " AMSBook uses \newlabel for tocindent
	    " which we filter out here.
	    else
		let label	= "nolabel"
	    endif
	    if label != 'nolabel'
		call add(labels, [ label, number, counter])
	    endif
" 	endif
    endfor

    return labels
endfunction
" }}}2
" Sorting function used to sort labels.
" {{{2 --------------- atplib#SortLabels
" It compares the first component of lists (which is line number)
" This should also use the bufnr.
function! atplib#SortLabels(list1, list2)
    if a:list1[0] == a:list2[0]
	return 0
    elseif str2nr(a:list1[0]) > str2nr(a:list2[0])
	return 1
    else
	return -1
    endif
endfunction
" }}}2
" Function which find all labels and related info (label number, lable line
" number, {bufnr} <= TODO )
" {{{2 --------------- atplib#generatelabels
" This function runs in two steps:
" 	(1) read lables from aux files using GrepAuxFile()
" 	(2) search all input files (TreeOfFiles()) for labels to get the line
" 		number 
" 	   [ this is done using :vimgrep which is fast, when the buffer are not loaded ]
function! atplib#generatelabels(filename, ...)
    let s:labels	= {}
    let bufname		= fnamemodify(a:filename,":t")
    let auxname		= fnamemodify(a:filename,":p:r") . ".aux"
    let return_ListOfFiles	= a:0 >= 1 ? a:1 : 1

    let true=1
    let i=0

    let aux_labels	= atplib#GrepAuxFile(auxname)

    let saved_pos	= getpos(".")
    call cursor(1,1)

    let [ TreeofFiles, ListOfFiles, DictOfFiles, LevelDict ] 		= TreeOfFiles(a:filename, '\\\(input\|include\)\s*{')
    if count(ListOfFiles, a:filename) == 0
	call add(ListOfFiles, a:filename)
    endif
    let saved_llist	= getloclist(0)
    call setloclist(0, [])

    " Look for labels in all input files.
    for file in ListOfFiles
	silent! execute "lvimgrepadd /\\label\s*{/j " . fnameescape(file)
    endfor
    let loc_list	= getloclist(0)
"     call setloclist(0, saved_llist)
    call map(loc_list, '[ v:val["lnum"], v:val["text"], v:val["bufnr"] ]')

    let labels = {}

    for label in aux_labels
	let dict		= filter(copy(loc_list), "v:val[1] =~ '\\label\s*{\s*'.escape(label[0], '*\/$.') .'\s*}'")
	let line		= get(get(dict, 0, []), 0, "") 
	let bufnr		= get(get(dict, 0, []), 2, "")
	let bufname		= fnamemodify(bufname(bufnr), ":p")
	if get(labels, bufname, []) == []
	    let labels[bufname] = [ [line, label[0], label[1], label[2], bufnr ] ]
	else
	    call add(labels[bufname], [line, label[0], label[1], label[2], bufnr ]) 
	endif
    endfor

    for bufname in keys(labels)
	call sort(labels[bufname], "atplib#SortLabels")
    endfor

"     let i=0
"     while i < len(texfile)
" 	if texfile[i] =~ '\\label\s*{'
" 	    let lname 	= matchstr(texfile[i], '\\label\s*{.*', '')
" 	    let start 	= stridx(lname, '{')+1
" 	    let lname 	= strpart(lname, start)
" 	    let end	= stridx(lname, '}')
" 	    let lname	= strpart(lname, 0, end)
"     "This can be extended to have also the whole environment which
"     "could be shown.
" 	    call extend(s:labels, { i+1 : lname })
" 	endif
" 	let i+=1 
"     endwhile

    if exists("t:atp_labels")
	call extend(t:atp_labels, labels, "force")
    else
	let t:atp_labels	= labels
    endif
    keepjumps call setpos(".", saved_pos)
    if return_ListOfFiles
	return [ t:atp_labels, ListOfFiles ]
    else
	return t:atp_labels
    endif
endfunction
" }}}2
" This function opens a new window and puts the results there.
" {{{2 --------------- atplib#showlabels
" the argument is [ t:atp_labels, ListOfFiles ] 
" 	where ListOfFiles is the list returne by TreeOfFiles() 
function! atplib#showlabels(labels)

    " the argument a:labels=t:atp_labels[bufname("")] !
    let l:cline=line(".")

    let saved_pos	= getpos(".")

    " Open new window or jump to the existing one.
    let l:bufname	= bufname("")
    let l:bufpath	= fnamemodify(resolve(fnamemodify(bufname("%"),":p")),":h")
    let BufFullName	= fnamemodify(l:bufname, ":p") 

    let l:bname="__Labels__"

    let l:labelswinnr=bufwinnr("^" . l:bname . "$")
    let t:atp_labelswinnr=winnr()
    let t:atp_labelsbufnr=bufnr("^" . l:bname . "$") 
    let l:labelswinnr=bufwinnr(t:atp_labelsbufnr)

    let tabstop	= 0
    for file in a:labels[1]
	let dict	= get(a:labels[0], file, [])
	let tabstop	= max([tabstop, max(map(copy(dict), "len(v:val[2])")) + 1])
	unlet dict
    endfor
    let g:tabstop	= tabstop " DEBUG
    let g:labelswinnr	= l:labelswinnr
    let saved_view	= winsaveview()

    if l:labelswinnr != -1
	" Jump to the existing window.
	exe l:labelswinnr . " wincmd w"
	if l:labelswinnr != t:atp_labelswinnr
	    silent exe "%delete"
	else
	    echoerr "ATP error in function s:showtoc, TOC/LABEL buffer 
		    \ and the tex file buffer agree."
	    return
	endif
    else

    " Open new window if its width is defined (if it is not the code below
    " will put lab:cels in the current buffer so it is better to return.
	if !exists("t:atp_labels_window_width")
	    echoerr "t:atp_labels_window_width not set"
	    return
	endif

	" tabstop option is set to be the longest counter number + 1
	let l:openbuffer= t:atp_labels_window_width . "vsplit +setl\\ tabstop=" . tabstop . "\\ nowrap\\ buftype=nofile\\ filetype=toc_atp\\ syntax=labels_atp __Labels__"
	keepalt silent exe l:openbuffer
	silent call atplib#setwindow()
	let t:atp_labelsbufnr=bufnr("")
    endif
    unlockvar b:atp_Labels
    let b:atp_Labels	= {}

    let line_nr	= 2
    for file in a:labels[1]
    call setline("$", fnamemodify(file, ":t") . " (" . fnamemodify(file, ":h")  . ")")
    call extend(b:atp_Labels, { 1 : [ file, 0 ]})
    for label in get(a:labels[0], file, [])
	    " Set line in the format:
	    " /<label_numberr> \t[<counter>] <label_name> (<label_line_nr>)/
	    " if the <counter> was given in aux file (see the 'counter' variable in atplib#GrepAuxFile())
	    " print it.
	    " /it is more complecated because I want to make it as tight as
	    " possible and as nice as possible :)
	    " the first if checks if there are counters, then counter type is
	    " printed, then the tabs are set./
    " 	let slen	= winwidth(0)-tabstop-5-5
    " 	let space_len 	= max([1, slen-len(label[1])])
	    if tabstop+(len(label[3][0])+3)+len(label[1])+(len(label[0])+2) < winwidth(0)
		let space_len	= winwidth(0)-(tabstop+(len(label[3][0])+3)+len(label[1])+(len(label[0])+2))
	    else
		let space_len  	= 1
	    endif
	    let space	= join(map(range(space_len), '" "'), "")
	    let set_line 	= label[2] . "\t[" . label[3][0] . "] " . label[1] . space . "(" . label[0] . ")"
	    call setline(line_nr, set_line ) 
	    cal extend(b:atp_Labels, { line_nr : [ file, label[0] ]}) 
	    let line_nr+=1
	endfor
    endfor
    lockvar 3 b:atp_Labels

    " set the cursor position on the correct line number.
    call search(l:bufname, 'w')
"     normal j
    let l:number=1
    for label  in get(a:labels[0], BufFullName, [])
	if l:cline >= label[0]
" 	    echo "1 " . label[0]
	    keepjumps call cursor(line(".")+1, col("."))
	elseif l:number == 1 && l:cline < label[0]
" 	    echo "2 " . label[0]
	    keepjumps call cursor(line(".")+1, col("."))
	endif
	let l:number+=1
    endfor
endfunction
" }}}2
" }}}1

" Various Comparing Functions:
"{{{1 atplib#CompareNumbers
function! atplib#CompareNumbers(i1, i2)
   return str2nr(a:i1) == str2nr(a:i2) ? 0 : str2nr(a:i1) > str2nr(a:i2) ? 1 : -1
endfunction
"}}}1
" {{{1 atplib#CompareCoordinates
" Each list is an argument with two values:
" listA=[ line_nrA, col_nrA] usually given by searchpos() function
" listB=[ line_nrB, col_nrB]
" returns 1 iff A is smaller than B
fun! atplib#CompareCoordinates(listA,listB)
    if a:listA[0] < a:listB[0] || 
	\ a:listA[0] == a:listB[0] && a:listA[1] < a:listB[1] ||
	\ a:listA == [0,0]
	" the meaning of the last is that if the searchpos() has not found the
	" beginning (a:listA) then it should return 1 : the env is not started.
	return 1
    else
	return 0
    endif
endfun
"}}}1
" {{{1 atplib#CompareCoordinates_leq
" Each list is an argument with two values!
" listA=[ line_nrA, col_nrA] usually given by searchpos() function
" listB=[ line_nrB, col_nrB]
" returns 1 iff A is smaller or equal to B
fun! atplib#CompareCoordinates_leq(listA,listB)
    if a:listA[0] < a:listB[0] || 
	\ a:listA[0] == a:listB[0] && a:listA[1] <= a:listB[1] ||
	\ a:listA == [0,0]
	" the meaning of the last is that if the searchpos() has not found the
	" beginning (a:listA) then it should return 1 : the env is not started.
	return 1
    else
	return 0
    endif
endfun
"}}}1
" ReadInputFile function reads finds a file in tex style and returns the list
" of its lines. 
" {{{1 atplib#ReadInputFile
" this function looks for an input file: in the list of buffers, under a path if
" it is given, then in the b:atp_OutDir.
" directory. The last argument if equal to 1, then look also
" under g:texmf.
function! atplib#ReadInputFile(ifile,check_texmf)

    let l:input_file = []

    " read the buffer or read file if the buffer is not listed.
    if buflisted(fnamemodify(a:ifile,":t"))
	let l:input_file=getbufline(fnamemodify(a:ifile,":t"),1,'$')
    " if the ifile is given with a path it should be tried to read from there
    elseif filereadable(a:ifile)
	let l:input_file=readfile(a:ifile)
    " if not then try to read it from b:atp_OutDir
    elseif filereadable(b:atp_OutDir . fnamemodify(a:ifile,":t"))
	let l:input_file=readfile(filereadable(b:atp_OutDir . fnamemodify(a:ifile,":t")))
    " the last chance is to look for it in the g:texmf directory
    elseif a:check_texmf && filereadable(findfile(a:ifile,g:texmf . '**'))
	let l:input_file=readfile(findfile(a:ifile,g:texmf . '**'))
    endif

    return l:input_file
endfunction
"}}}1

" Bib Search:
" These are all bibsearch realted variables and functions.
"{{{ BIBSEARCH
"{{{ atplib#variables
let atplib#bibflagsdict={ 't' : ['title', 'title        '] , 'a' : ['author', 'author       '], 
		\ 'b' : ['booktitle', 'booktitle    '], 'c' : ['mrclass', 'mrclass      '], 
		\ 'e' : ['editor', 'editor       '], 	'j' : ['journal', 'journal      '], 
		\ 'f' : ['fjournal', 'fjournal     '], 	'y' : ['year', 'year         '], 
		\ 'n' : ['number', 'number       '], 	'v' : ['volume', 'volume       '], 
		\ 's' : ['series', 'series       '], 	'p' : ['pages', 'pages        '], 
		\ 'P' : ['publisher', 'publisher    '], 'N' : ['note', 'note         '], 
		\ 'S' : ['school', 'school       '], 	'h' : ['howpublished', 'howpublished '], 
		\ 'o' : ['organization', 'organization '], 'I' : ['institution' , 'institution '],
		\ 'u' : ['url', 'url          '],
		\ 'H' : ['homepage', 'homepage     '], 	'i' : ['issn', 'issn         '],
		\ 'k' : ['key', 'key          ']}
" they do not work in the library script :(
" using g:bibflags... .
" let atplib#bibflagslist=keys(atplib#bibflagsdict)
" let atplib#bibflagsstring=join(atplib#bibflagslist,'')
"}}}
" This functions finds bibfiles defined in the tex source file. 
"{{{ atplib#searchbib
" ToDo should not search in comment lines.

" To make it work after kpsewhich is searching for bib path.
" let s:bibfiles=FindBibFiles(bufname('%'))
function! atplib#searchbib(pattern, ...) 

    call atplib#outdir()
    " for tex files this should be a flat search.
    let flat 	= &filetype == "plaintex" ? 1 : 0
    let bang	= a:0 >=1 ? a:1 : ""

    " Caching bibfiles saves 0.27sec.
    if !exists("b:bibfiles") || bang == "!"
	let s:bibfiles	= []
	let [ TreeOfFiles, ListOfFiles, TypeDict, LevelDict ] = TreeOfFiles(b:atp_MainFile, '^[^%]*\\bibliography\s*{', flat)
	for f in ListOfFiles
	    if TypeDict[f] == 'bib' 
		call add(s:bibfiles, f)
	    endif
	endfor
	let b:bibfiles	= deepcopy(s:bibfiles)
    else
	let s:bibfiles	= deepcopy(b:bibfiles)
    endif

    let g:bibfiles	= copy(s:bibfiles)
    
    " Make a pattern which will match for the elements of the list g:bibentries
    let pattern = '^\s*@\%(\<'.g:bibentries[0].'\>'
    for bibentry in g:bibentries['1':len(g:bibentries)]
	let pattern	= pattern . '\|\<' . bibentry . '\>'
    endfor
    let pattern	= pattern . '\)'
" This pattern matches all entry lines: author = \| title = \| ... 
    let pattern_b = '^\s*\%('
    for bibentry in keys(g:bibflagsdict)
	let pattern_b	= pattern_b . '\|\<' . g:bibflagsdict[bibentry][0] . '\>'
    endfor
    let pattern_b.='\)\s*='

    unlet bibentry
    let b:bibentryline={} 
    
    " READ EACH BIBFILE IN TO DICTIONARY s:bibdict, WITH KEY NAME BEING THE bibfilename
    let s:bibdict={}
    let l:bibdict={}
    for l:f in s:bibfiles
	let s:bibdict[l:f]=[]

	" read the bibfile if it is in b:atp_OutDir or in g:atp_raw_bibinputs directory
	" ToDo: change this to look in directories under g:atp_raw_bibinputs. 
	" (see also ToDo in FindBibFiles 284)
" 	for l:path in split(g:atp_raw_bibinputs, ',') 
" 	    " it might be problem when there are multiple libraries with the
" 	    " same name under different locations (only the last one will
" 	    " survive)
" 	    let s:bibdict[l:f]=readfile(fnameescape(findfile(atplib#append(l:f,'.bib'), atplib#append(l:path,"/") . "**")))
" 	endfor
	let s:bibdict[l:f]=readfile(l:f)
	let l:bibdict[l:f]=copy(s:bibdict[l:f])
	" clear the s:bibdict values from lines which begin with %    
	call filter(l:bibdict[l:f], ' v:val !~ "^\\s*\\%(%\\|@\\cstring\\)"')
    endfor

    if a:pattern != ""
	for l:f in s:bibfiles
	    let l:list=[]
	    let l:nr=1
	    for l:line in l:bibdict[l:f]
		" Match Pattern:
		" if the line matches find the beginning of this bib field and add its
		" line number to the list l:list
		" remove ligatures and brackets {,} from the line
		let line_without_ligatures = substitute(substitute(l:line,'\C{\|}\|\\\%("\|`\|\^\|=\|\.\|c\|\~\|v\|u\|d\|b\|H\|t\)\s*','','g'), "\\\\'\\s*", '', 'g')
		let line_withouf_ligatures = substitute(line_without_ligatures, '\C\\oe', 'oe', 'g')
		let line_withouf_ligatures = substitute(line_without_ligatures, '\C\\OE', 'OE', 'g')
		let line_withouf_ligatures = substitute(line_without_ligatures, '\C\\ae', 'ae', 'g')
		let line_withouf_ligatures = substitute(line_without_ligatures, '\C\\AE', 'AE', 'g')
		let line_withouf_ligatures = substitute(line_without_ligatures, '\C\\o', 'o', 'g')
		let line_withouf_ligatures = substitute(line_without_ligatures, '\C\\O', 'O', 'g')
		let line_withouf_ligatures = substitute(line_without_ligatures, '\C\\i', 'i', 'g')
		let line_withouf_ligatures = substitute(line_without_ligatures, '\C\\j', 'j', 'g')
		let line_withouf_ligatures = substitute(line_without_ligatures, '\C\\l', 'l', 'g')
		let line_withouf_ligatures = substitute(line_without_ligatures, '\C\\L', 'L', 'g')

		if line_without_ligatures =~ a:pattern
		    let l:true=1
		    let l:t=0
		    while l:true == 1
			let l:tnr=l:nr-l:t
			" go back until the line will match pattern (which
			" should be the beginning of the bib field.
		       if l:bibdict[l:f][l:tnr-1] =~ pattern && l:tnr >= 0
			   let l:true=0
			   let l:list=add(l:list,l:tnr)
		       elseif l:tnr <= 0
			   let l:true=0
		       endif
		       let l:t+=1
		    endwhile
		endif
		let l:nr+=1
	    endfor
    " CLEAR THE l:list FROM ENTRIES WHICH APPEAR TWICE OR MORE --> l:clist
	    let l:pentry="A"		" We want to ensure that l:entry (a number) and l:pentry are different
	    for l:entry in l:list
		if l:entry != l:pentry
		    if count(l:list,l:entry) > 1
			while count(l:list,l:entry) > 1
			    let l:eind=index(l:list,l:entry)
			    call remove(l:list,l:eind)
			endwhile
		    endif 
		    let l:pentry=l:entry
		endif
	    endfor
	    let b:bibentryline=extend(b:bibentryline,{ l:f : l:list })
	endfor
    endif
"   CHECK EACH BIBFILE
    let l:bibresults={}
"     if the pattern was empty make it faster. 
    if a:pattern == ""
	for l:bibfile in keys(l:bibdict)
	    let l:bibfile_len=len(l:bibdict[l:bibfile])
	    let s:bibd={}
		let l:nr=0
		while l:nr < l:bibfile_len
		    let l:line=l:bibdict[l:bibfile][l:nr]
		    if l:line =~ pattern
			let s:lbibd={}
			let s:lbibd["bibfield_key"]=l:line
			let l:beg_line=l:nr+1
			let l:nr+=1
			let l:line=l:bibdict[l:bibfile][l:nr]
			let l:y=1
			while l:line !~ pattern && l:nr < l:bibfile_len
			    let l:line=l:bibdict[l:bibfile][l:nr]
			    let l:lkey=tolower(
					\ matchstr(
					    \ strpart(l:line,0,
						\ stridx(l:line,"=")
					    \ ),'\<\w*\>'
					\ ))
	" CONCATENATE LINES IF IT IS NOT ENDED
			    let l:y=1
			    if l:lkey != ""
				let s:lbibd[l:lkey]=l:line
	" IF THE LINE IS SPLIT ATTACH NEXT LINE									
" 				echomsg "l:nr=".l:nr. "       line=".l:line 
				let l:nline=get(l:bibdict[l:bibfile],l:nr+l:y)
				while l:nline !~ '=' && 
					    \ l:nline !~ pattern &&
					    \ (l:nr+l:y) < l:bibfile_len
				    let s:lbibd[l:lkey]=substitute(s:lbibd[l:lkey],'\s*$','','') . " ". substitute(get(l:bibdict[l:bibfile],l:nr+l:y),'^\s*','','')
				    let l:line=get(l:bibdict[l:bibfile],l:nr+l:y)
" 				    echomsg "l:nr=".l:nr. " l:y=".l:y." line=".l:line 
				    let l:y+=1
				    let l:nline=get(l:bibdict[l:bibfile],l:nr+l:y)
				    if l:y > 30
					echoerr "ATP-Error /see :h atp-errors-bibsearch/, missing '}', ')' or '\"' in bibentry (check line " . l:nr . ") in " . l:f . " line=".l:line
					break
				    endif
				endwhile
				if l:nline =~ pattern 
" 				    echomsg "BREAK l:nr=".l:nr. " l:y=".l:y." nline=".l:nline 
				    let l:y=1
				endif
			    endif
			    let l:nr+=l:y
			    unlet l:y
			endwhile
			let l:nr-=1
			call extend(s:bibd, { l:beg_line : s:lbibd })
		    else
			let l:nr+=1
		    endif
		endwhile
	    let l:bibresults[l:bibfile]=s:bibd
	    let g:bibresults=l:bibresults
	endfor
	let g:bbibresults=l:bibresults
	return l:bibresults
    endif
    " END OF NEW CODE: (up)

    for l:bibfile in keys(b:bibentryline)
	let l:f=l:bibfile . ".bib"
"s:bibdict[l:f])	CHECK EVERY STARTING LINE (we are going to read bibfile from starting
"	line till the last matching } 
 	let s:bibd={}
 	for l:linenr in b:bibentryline[l:bibfile]
"
" 	new algorithm is on the way, using searchpair function
" 	    l:time=0
" 	    l:true=1
" 	    let b:pair1=searchpair('(','',')','b')
" 	    let b:pair2=searchpair('{','','}','b')
" 	    let l:true=b:pair1+b:pair2
" 	    while l:true == 0
" 		let b:pair1p=b:pair1	
" 		let b:pair1=searchpair('(','',')','b')
" 		let b:pair2p=b:pair2	
" 		let b:pair2=searchpair('{','','}','b')
" 		let l:time+=1
" 	    endwhile
" 	    let l:bfieldline=l:time

	    let l:nr=l:linenr-1
	    let l:i=atplib#count(get(l:bibdict[l:bibfile],l:linenr-1),"{")-atplib#count(get(l:bibdict[l:bibfile],l:linenr-1),"}")
	    let l:j=atplib#count(get(l:bibdict[l:bibfile],l:linenr-1),"(")-atplib#count(get(l:bibdict[l:bibfile],l:linenr-1),")") 
	    let s:lbibd={}
	    let s:lbibd["bibfield_key"]=get(l:bibdict[l:bibfile],l:linenr-1)
	    let l:x=1
" we go from the first line of bibentry, i.e. @article{ or @article(, until the { and (
" will close. In each line we count brackets.	    
            while l:i>0	|| l:j>0
		let l:tlnr=l:x+l:linenr
		let l:pos=atplib#count(get(l:bibdict[l:bibfile],l:tlnr-1),"{")
		let l:neg=atplib#count(get(l:bibdict[l:bibfile],l:tlnr-1),"}")
		let l:i+=l:pos-l:neg
		let l:pos=atplib#count(get(l:bibdict[l:bibfile],l:tlnr-1),"(")
		let l:neg=atplib#count(get(l:bibdict[l:bibfile],l:tlnr-1),")")
		let l:j+=l:pos-l:neg
		let l:lkey=tolower(
			    \ matchstr(
				\ strpart(get(l:bibdict[l:bibfile],l:tlnr-1),0,
				    \ stridx(get(l:bibdict[l:bibfile],l:tlnr-1),"=")
				\ ),'\<\w*\>'
			    \ ))
		if l:lkey != ""
		    let s:lbibd[l:lkey]=get(l:bibdict[l:bibfile],l:tlnr-1)
			let l:y=0
" IF THE LINE IS SPLIT ATTACH NEXT LINE									
			if get(l:bibdict[l:bibfile],l:tlnr-1) !~ '\%()\|}\|"\)\s*,\s*\%(%.*\)\?$'
" 				    \ get(l:bibdict[l:bibfile],l:tlnr) !~ pattern_b
			    let l:lline=substitute(get(l:bibdict[l:bibfile],l:tlnr+l:y-1),'\\"\|\\{\|\\}\|\\(\|\\)','','g')
			    let l:pos=atplib#count(l:lline,"{")
			    let l:neg=atplib#count(l:lline,"}")
			    let l:m=l:pos-l:neg
			    let l:pos=atplib#count(l:lline,"(")
			    let l:neg=atplib#count(l:lline,")")
			    let l:n=l:pos-l:neg
			    let l:o=atplib#count(l:lline,"\"")
    " this checks if bracets {}, and () and "" appear in pairs in the current line:  
			    if l:m>0 || l:n>0 || l:o>l:o/2*2 
				while l:m>0 || l:n>0 || l:o>l:o/2*2 
				    let l:pos=atplib#count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"{")
				    let l:neg=atplib#count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"}")
				    let l:m+=l:pos-l:neg
				    let l:pos=atplib#count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"(")
				    let l:neg=atplib#count(get(l:bibdict[l:bibfile],l:tlnr+l:y),")")
				    let l:n+=l:pos-l:neg
				    let l:o+=atplib#count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"\"")
    " Let's append the next line: 
				    let s:lbibd[l:lkey]=substitute(s:lbibd[l:lkey],'\s*$','','') . " ". substitute(get(l:bibdict[l:bibfile],l:tlnr+l:y),'^\s*','','')
				    let l:y+=1
				    if l:y > 30
					echoerr "ATP-Error /see :h atp-errors-bibsearch/, missing '}', ')' or '\"' in bibentry at line " . l:linenr . " (check line " . l:tlnr . ") in " . l:f
					break
				    endif
				endwhile
			    endif
			endif
		endif
" we have to go line by line and we could skip l:y+1 lines, but we have to
" keep l:m, l:o values. It do not saves much.		
		let l:x+=1
		if l:x > 30
			echoerr "ATP-Error /see :h atp-errors-bibsearch/, missing '}', ')' or '\"' in bibentry at line " . l:linenr . " in " . l:f
			break
	        endif
		let b:x=l:x
		unlet l:tlnr
	    endwhile
	    
	    let s:bibd[l:linenr]=s:lbibd
	    unlet s:lbibd
	endfor
	let l:bibresults[l:bibfile]=s:bibd
    endfor
    let g:bibresults=l:bibresults
    return l:bibresults
endfunction
"}}}
" This is the main search engine.
" {{{ atplib#SearchBibItems
" the argument should be b:atp_MainFile but in any case it is made in this way.
" it specifies in which file to search for include files.
function! atplib#SearchBibItems(name)

    " we are going to make a dictionary { citekey : label } (see :h \bibitem) 
    let l:citekey_label_dict={}

    " make a list of include files.
    let l:inputfile_dict=FindInputFiles(a:name,0)
    let l:includefile_list=[]
    for l:key in keys(l:inputfile_dict)
	if l:inputfile_dict[l:key][0] =~ '^\%(include\|input\|includeonly\)$'
	    call add(l:includefile_list,atplib#append(l:key,'.tex'))
	endif
    endfor
    call add(l:includefile_list,b:atp_MainFile) 
"     let b:ifl=l:includefile_list

    " search for bibitems in all include files.
    for l:ifile in l:includefile_list

	let l:input_file = atplib#ReadInputFile(l:ifile,0)

	    " search for bibitems and make a dictionary of labels and citekeys
	    for l:line in l:input_file
		if l:line =~ '\\bibitem'
		    let l:label=matchstr(l:line,'\\bibitem\s*\[\zs[^]]*\ze\]')
		    let l:key=matchstr(l:line,'\\bibitem\s*\%(\[[^]]*\]\)\?\s*{\zs[^}]*\ze}') 
" 		    if l:label =~ 'bibitem'
" 			let l:label=''
" 		    endif
		    if l:key != ""
			call extend(l:citekey_label_dict, { l:key : l:label }, 'error') 
		    endif
		endif
	    endfor
    endfor
	
    return l:citekey_label_dict
endfunction
" }}}
" Showing results 
"{{{ atplib#showresults
" FLAGS:
" for currently supported flags see ':h atp_bibflags'
" All - all flags	
" L - last flag
" a - author
" e - editor
" t - title
" b - booktitle
" j - journal
" s - series
" y - year
" n - number
" v - volume
" p - pages
" P - publisher
" N - note
" S - school
" h - howpublished
" o - organization
" i - institution

function! atplib#showresults(bibresults, flags, pattern)
 
    "if nothing was found inform the user and return:
    if len(a:bibresults) == count(a:bibresults,{})
	echo "BibSearch: no bib fields matched."
	return 0
    endif


    function! s:showvalue(value)
	return substitute(strpart(a:value,stridx(a:value,"=")+1),'^\s*','','')
    endfunction

    let s:z=1
    let l:ln=1
    let l:listofkeys={}
"--------------SET UP FLAGS--------------------------    
	    let l:allflagon=0
	    let l:flagslist=[]
	    let l:kwflagslist=[]
    " flags o and i are synonims: (but refer to different entry keys): 
	if a:flags =~ '\Ci' && a:flags !~ '\Co'
	    let l:flags=substitute(a:flags,'i','io','') 
	elseif a:flags !~ '\Ci' && a:flags =~ '\Co'
	    let l:flags=substitute(a:flags,'o','oi','')
	endif
	if a:flags !~ 'All'
	    if a:flags =~ 'L'
 		if strpart(a:flags,0,1) != '+'
 		    let l:flags=b:atp_LastBibFlags . substitute(strpart(a:flags,0),'\CL','','g')
 		else
 		    let l:flags=b:atp_LastBibFlags . substitute(a:flags,'\CL','','g')
 		endif
	    else
		if a:flags == "" 
		    let l:flags=g:defaultbibflags
		elseif strpart(a:flags,0,1) != '+' && a:flags !~ 'All' 
		    let l:flags=a:flags
		elseif strpart(a:flags,0,1) == '+' && a:flags !~ 'All'
		    let l:flags=g:defaultbibflags . strpart(a:flags,1)
		endif
	    endif
	    let b:atp_LastBibFlags=substitute(l:flags,'+\|L','','g')
		if l:flags != ""
		    let l:expr='\C[' . g:bibflagsstring . ']' 
		    while len(l:flags) >=1
			let l:oneflag=strpart(l:flags,0,1)
    " if we get a flag from the variable g:bibflagsstring we copy it to the list l:flagslist 
			if l:oneflag =~ l:expr
			    let l:flagslist=add(l:flagslist,l:oneflag)
			    let l:flags=strpart(l:flags,1)
    " if we get '@' we eat ;) two letters to the list l:kwflagslist			
			elseif l:oneflag == '@'
			    let l:oneflag=strpart(l:flags,0,2)
			    if index(keys(g:kwflagsdict),l:oneflag) != -1
				let l:kwflagslist=add(l:kwflagslist,l:oneflag)
			    endif
			    let l:flags=strpart(l:flags,2)
    " remove flags which are not defined
			elseif l:oneflag !~ l:expr && l:oneflag != '@'
			    let l:flags=strpart(l:flags,1)
			endif
		    endwhile
		endif
	else
    " if the flag 'All' was specified. 	    
	    let l:flagslist=split(g:defaultallbibflags, '\zs')
	    let l:af=substitute(a:flags,'All','','g')
	    for l:kwflag in keys(g:kwflagsdict)
		if a:flags =~ '\C' . l:kwflag	
		    call extend(l:kwflagslist,[l:kwflag])
		endif
	    endfor
	endif

	"NEW: if there are only keyword flags append default flags
	if len(l:kwflagslist) > 0 && len(l:flagslist) == 0 
	    let l:flagslist=split(g:defaultbibflags,'\zs')
	endif

"   Open a new window.
    let l:bufnr=bufnr("___" . a:pattern . "___"  )
    if l:bufnr != -1
	let l:bdelete=l:bufnr . "bwipeout"
	exe l:bdelete
    endif
    unlet l:bufnr
    let l:openbuffer=" +setl\\ buftype=nofile\\ filetype=bibsearch_atp " . fnameescape("___" . a:pattern . "___")
    if g:vertical ==1
	let l:openbuffer="vsplit " . l:openbuffer 
	let l:skip=""
    else
	let l:openbuffer="split " . l:openbuffer 
	let l:skip="       "
    endif

    let BufNr	= bufnr("%")
    let LineNr	= line(".")
    let ColNr	= col(".")
    silent exe l:openbuffer

"     set the window options
    silent call atplib#setwindow()
" make a dictionary of clear values, which we will fill with found entries. 	    
" the default value is no<keyname>, which after all is matched and not showed
" SPEED UP:
    let l:values={'bibfield_key' : 'nokey'}	
    for l:flag in g:bibflagslist
	let l:values_clear=extend(l:values,{ g:bibflagsdict[l:flag][0] : 'no' . g:bibflagsdict[l:flag][0] })
    endfor

" SPEED UP: 
    let l:kwflag_pattern="\\C"	
    let l:len_kwflgslist=len(l:kwflagslist)
    let l:kwflagslist_rev=reverse(deepcopy(l:kwflagslist))
    for l:lkwflag in l:kwflagslist
	if index(l:kwflagslist_rev,l:lkwflag) == 0 
	    let l:kwflag_pattern.=g:kwflagsdict[l:lkwflag]
	else
	    let l:kwflag_pattern.=g:kwflagsdict[l:lkwflag].'\|'
	endif
    endfor
"     let b:kwflag_pattern=l:kwflag_pattern

    for l:bibfile in keys(a:bibresults)
	if a:bibresults[l:bibfile] != {}
	    call setline(l:ln, "Found in " . l:bibfile )	
	    let l:ln+=1
	endif
	for l:linenr in copy(sort(keys(a:bibresults[l:bibfile]), "atplib#CompareNumbers"))
	    let l:values=deepcopy(l:values_clear)
	    let b:values=l:values
" fill l:values with a:bibrsults	    
	    let l:values["bibfield_key"]=a:bibresults[l:bibfile][l:linenr]["bibfield_key"]
" 	    for l:key in keys(l:values)
" 		if l:key != 'key' && get(a:bibresults[l:bibfile][l:linenr],l:key,"no" . l:key) != "no" . l:key
" 		    let l:values[l:key]=a:bibresults[l:bibfile][l:linenr][l:key]
" 		endif
" SPEED UP:
		call extend(l:values,a:bibresults[l:bibfile][l:linenr],'force')
" 	    endfor
" ----------------------------- SHOW ENTRIES -------------------------
" first we check the keyword flags, @a,@b,... it passes if at least one flag
" is matched
	    let l:check=0
" 	    for l:lkwflag in l:kwflagslist
" 	        let l:kwflagpattern= '\C' . g:kwflagsdict[l:lkwflag]
" 		if l:values['bibfield_key'] =~ l:kwflagpattern
" 		   let l:check=1
" 		endif
" 	    endfor
	    if l:values['bibfield_key'] =~ l:kwflag_pattern
		let l:check=1
	    endif
	    if l:check == 1 || len(l:kwflagslist) == 0
		let l:linenumber=index(s:bibdict[l:bibfile],l:values["bibfield_key"])+1
 		call setline(l:ln,s:z . ". line " . l:linenumber . "  " . l:values["bibfield_key"])
		let l:ln+=1
 		let l:c0=atplib#count(l:values["bibfield_key"],'{')-atplib#count(l:values["bibfield_key"],'(')

	
" this goes over the entry flags:
		for l:lflag in l:flagslist
" we check if the entry was present in bibfile:
		    if l:values[g:bibflagsdict[l:lflag][0]] != "no" . g:bibflagsdict[l:lflag][0]
" 			if l:values[g:bibflagsdict[l:lflag][0]] =~ a:pattern
			    call setline(l:ln, l:skip . g:bibflagsdict[l:lflag][1] . " = " . s:showvalue(l:values[g:bibflagsdict[l:lflag][0]]))
			    let l:ln+=1
" 			else
" 			    call setline(l:ln, l:skip . g:bibflagsdict[l:lflag][1] . " = " . s:showvalue(l:values[g:bibflagsdict[l:lflag][0]]))
" 			    let l:ln+=1
" 			endif
		    endif
		endfor
		let l:lastline=getline(line('$'))
		let l:c1=atplib#count(l:lastline,'{')-atplib#count(l:lastline,'}')
		let l:c2=atplib#count(l:lastline,'(')-atplib#count(l:lastline,')')
		let l:c3=atplib#count(l:lastline,'\"')
		if l:c0 == 1 && l:c1 == -1
		    call setline(line('$'),substitute(l:lastline,'}\s*$','',''))
		    call setline(l:ln,'}')
		    let l:ln+=1
		elseif l:c0 == 1 && l:c1 == 0	
		    call setline(l:ln,'}')
		    let l:ln+=1
		elseif l:c0 == -1 && l:c2 == -1
		    call setline(line('$'),substitute(l:lastline,')\s*$','',''))
		    call setline(l:ln,')')
		    let l:ln+=1
		elseif l:c0 == -1 && l:c1 == 0	
		    call setline(l:ln,')')
		    let l:ln+=1
		endif
		let l:listofkeys[s:z]=l:values["bibfield_key"]
		let s:z+=1
	    endif
	endfor
    endfor
    call matchadd("Search",a:pattern)
    " return l:listofkeys which will be available in the bib search buffer
    " as b:ListOfKeys (see the BibSearch function below)
    let b:ListOfBibKeys = l:listofkeys
    let b:BufNr		= BufNr

    return l:listofkeys
endfunction
"}}}
"}}}

" This function sets the window options common for toc and bibsearch windows.
"{{{1 atplib#setwindow
" this function sets the options of BibSearch, ToC and Labels windows.
function! atplib#setwindow()
" These options are set in the command line
" +setl\\ buftype=nofile\\ filetype=bibsearch_atp   
" +setl\\ buftype=nofile\\ filetype=toc_atp\\ nowrap
" +setl\\ buftype=nofile\\ filetype=toc_atp\\ syntax=labels_atp
	setlocal nonumber
 	setlocal winfixwidth
	setlocal noswapfile	
	setlocal window
	setlocal nobuflisted
	if &filetype == "bibsearch_atp"
" 	    setlocal winwidth=30
	    setlocal nospell
	elseif &filetype == "toc_atp"
" 	    setlocal winwidth=20
	    setlocal nospell
	    setlocal cursorline 
	endif
" 	nnoremap <expr> <buffer> <C-W>l	"keepalt normal l"
" 	nnoremap <buffer> <C-W>h	"keepalt normal h"
endfunction
" }}}1
" {{{1 atplib#count
function! atplib#count(line,keyword,...)
   
    let method = ( a:0 == 0 || a:1 == 0 ) ? 0 : 1

    let line=a:line
    let i=0  
    if method==0
	while stridx(line, a:keyword) != '-1'
	    let line	= strpart(line, stridx(line, a:keyword)+1)
	    let i +=1
	endwhile
    elseif method==1
	let line=escape(line, '\\')
	while match(line, a:keyword . '\zs.*') != '-1'
	    let line=strpart(line, match(line, a:keyword . '\zs.*'))
	    let i+=1
	endwhile
    endif
    return i
endfunction
" }}}1
" Used to append / at the end of a directory name
" {{{1 atplib#append 	
fun! atplib#append(where, what)
    return substitute(a:where, a:what . '\s*$', '', '') . a:what
endfun
" }}}1
" Used to append extension to a filename (if there is no extension).
" {{{1 atplib#append_ext 
" extension has to be with a dot.
fun! atplib#append_ext(fname, ext)
    return substitute(a:fname, a:ext . '\s*$', '', '') . a:ext
endfun
" }}}1

" Check If Closed:
" This functions cheks if an environment is closed/opened.
" atplib#CheckClosed {{{1
" check if last bpat is closed.
" starting from the current line, limits the number of
" lines to search. It returns 0 if the environment is not closed or the line
" number where it is closed (an env is cannot be closed in 0 line)

" ToDo: the two function should only check not commented lines!
"
" Method 0 makes mistakes if the pattern is \begin:\end, if
" \begin{env_name}:\end{env_names} rather no (unless there are nested
" environments in the same name.
" Method 1 doesn't make mistakes and thus is preferable.
" after testing I shall remove method 0
function! atplib#CheckClosed(bpat, epat, line, limit,...)

"     NOTE: THIS IS MUCH FASTER !!! or SLOWER !!! ???            
"
"     let l:pos_saved=getpos(".") 
"     let l:cline=line(".")
"     if a:line != l:cline
" 	let l:col=len(getline(a:line))
" 	keepjumps call setpos(".",[0,a:line,l:col,0])
"     endif
"     let l:line=searchpair(a:bpat,'',a:epat,'nWr','',max([(a:line+a:limit),1]))
"     if a:line != l:cline
" 	keepjumps call setpos(".",l:pos_saved)
"     endif
"     return l:line


    if a:0 == 0 || a:1 == 0
	let l:method = 0
    else
	let l:method = a:1
    endif

    let l:len=len(getbufline(bufname("%"),1,'$'))
    let l:nr=a:line

    if a:limit == "$" || a:limit == "-1"
	let l:limit=l:len-a:line
    else
	let l:limit=a:limit
    endif

    if l:method==0
	while l:nr <= a:line+l:limit
	    let l:line=getline(l:nr)
	" Check if Closed
	    if l:nr == a:line
		if strpart(l:line,getpos(".")[2]-1) =~ '\%(' . a:bpat . '.*\)\@<!' . a:epat
		    return l:nr
		endif
	    else
		if l:line =~ '\%(' . a:epat . '.*\)\@<!' . a:bpat
		    return 0
		elseif l:line =~ '\%(' . a:bpat . '.*\)\@<!' . a:epat 
		    return l:nr
		endif
	    endif
	    let l:nr+=1
	endwhile

    elseif l:method==1

	let l:bpat_count=0
	let l:epat_count=0
	let l:begin_line=getline(a:line)
	let l:begin_line_nr=line(a:line)
	while l:nr <= a:line+l:limit
	    let l:line=getline(l:nr)
	" I assume that the env is opened in the line before!
	    let l:bpat_count+=atplib#count(l:line,a:bpat,1)
	    let l:epat_count+=atplib#count(l:line,a:epat,1)
	    if (l:bpat_count+1) == l:epat_count && l:begin_line !~ a:bpat
		return l:nr
	    elseif l:bpat_count == l:epat_count && l:begin_line =~ a:bpat
		return l:nr
	    endif 
	    let l:nr+=1
	endwhile
	return 0
    endif
endfunction
" }}}1
" atplib#CheckOpened {{{1
" Usage: By default (a:0 == 0 || a:1 == 0 ) it returns line number where the
" environment is opened if the environment is opened and is not closed (for
" completion), else it returns 0. However, if a:1 == 1 it returns line number
" where the environment is opened, if we are inside an environment (it is
" opened and closed below the starting line or not closed at all), it if a:1
" = 2, it just check if env is opened without looking if it is closed (
" cursor position is important).
" a:1 == 0 first non closed
" a:1 == 2 first non closed by counting.

" this function doesn't check if sth is opened in lines which begins with '\\def\>'
" (some times one wants to have a command which opens an environment.

" Todo: write a faster function using searchpairpos() which returns correct
" values.
function! atplib#CheckOpened(bpat,epat,line,limit,...)


"     this is almost good:    
"     let l:line=searchpair(a:bpat,'',a:epat,'bnWr','',max([(a:line-a:limit),1]))
"     return l:line

    if a:0 == 0 || a:1 == 0
	let l:check_mode = 0
    elseif a:1 == 1
	let l:check_mode = 1
    elseif a:1 == 2
	let l:check_mode = 2
    endif

    let l:len=len(getbufline(bufname("%"),1,'$'))
    let l:nr=a:line

    if a:limit == "^" || a:limit == "-1"
	let l:limit=a:line-1
    else
	let l:limit=a:limit
    endif

    if l:check_mode == 0 || l:check_mode == 1
	while l:nr >= a:line-l:limit && l:nr >= 1
	    let l:line=getline(l:nr)
		if l:nr == a:line
			if substitute(strpart(l:line,0,getpos(".")[2]), a:bpat . '.\{-}' . a:epat,'','g')
				    \ =~ a:bpat
			    return l:nr
			endif
		else
		    if l:check_mode == 0
			if substitute(l:line, a:bpat . '.\{-}' . a:epat,'','g')
				    \ =~ a:bpat
			    " check if it is closed up to the place where we start. (There
			    " is no need to check after, it will be checked anyway
			    " b a serrate call in TabCompletion.
			    if !atplib#CheckClosed(a:bpat,a:epat,l:nr,a:limit,0)
					    " LAST CHANGE 1->0 above
" 				let b:cifo_return=2 . " " . l:nr 
				return l:nr
			    endif
			endif
		    elseif l:check_mode == 1
			if substitute(l:line, a:bpat . '.\{-}' . a:epat,'','g')
				    \ =~ '\%(\\def\|\%(re\)\?newcommand\)\@<!' . a:bpat
			    let l:check=atplib#CheckClosed(a:bpat,a:epat,l:nr,a:limit,1)
			    " if env is not closed or is closed after a:line
			    if  l:check == 0 || l:check >= a:line
" 				let b:cifo_return=2 . " " . l:nr 
				return l:nr
			    endif
			endif
		    endif
		endif
	    let l:nr-=1
	endwhile
    elseif l:check_mode == 2
	let l:bpat_count=0
	let l:epat_count=0
	let l:begin_line=getline(".")
	let l:c=0
	while l:nr >= a:line-l:limit  && l:nr >= 1
	    let l:line=getline(l:nr)
	" I assume that the env is opened in line before!
" 		let l:line=strpart(l:line,getpos(".")[2])
	    let l:bpat_count+=atplib#count(l:line,a:bpat,1)
	    let l:epat_count+=atplib#count(l:line,a:epat,1)
	    if l:bpat_count == (l:epat_count+1+l:c) && l:begin_line != line(".") 
		let l:env_name=matchstr(getline(l:nr),'\\begin{\zs[^}]*\ze}')
		let l:check=atplib#CheckClosed('\\begin{' . l:env_name . '}', '\\end{' . l:env_name . '}',1,a:limit,1)
		if !l:check
		    return l:nr
		else
		    let l:c+=1
		endif
	    elseif l:bpat_count == l:epat_count && l:begin_line == line(".")
		return l:nr
	    endif 
	    let l:nr-=1
	endwhile
    endif
    return 0 
endfunction
" }}}1
" This functions makes a test if inline math is closed. This works well with
" \(:\) and \[:\] but not yet with $:$ and $$:$$.  
" {{{1 atplib#CheckOneLineMath
" a:mathZone	= texMathZoneV or texMathZoneW or texMathZoneX or texMathZoneY
" The function return 1 if the mathZone is not closed 
function! atplib#CheckOneLineMath(mathZone)
    let synstack	= map(synstack(line("."), col(".")-1), "synIDattr( v:val, 'name')")
    let check		= 0
    let patterns 	= { 
		\ 'texMathZoneV' : [ '\\\@<!\\(', 	'\\\@<!\\)' 	], 
		\ 'texMathZoneW' : [ '\\\@<!\\\[', 	'\\\@<!\\\]'	]}
    " Limit the search to the first \par or a blank line, if not then search
    " until the end of document:
    let stop_line	= search('\\par\|^\s*$', 'nW') - 1
    let stop_line	= ( stop_line == -1 ? line('$') : stop_line )

    " \(:\), \[:\], $:$ and $$:$$ do not accept blank lines, thus we can limit
    " searching/counting.
    
    " For \(:\) and \[:\] we use searchpair function to test if it is closed or
    " not.
    if (a:mathZone == 'texMathZoneV' || a:mathZone == 'texMathZoneW') && atplib#CheckSyntaxGroups(['texMathZoneV', 'texMathZoneW'])
	if index(synstack, a:mathZone) != -1
	    let condition = searchpair( patterns[a:mathZone][0], '', patterns[a:mathZone][1], 'cnW', '', stop_line)
	    let check 	  = ( !condition ? 1 : check )
	endif

    " $:$ and $$:$$ we are counting $ untill blank line or \par
    " to test if it is closed or not, 
    " then we return the number of $ modulo 2.
    elseif ( a:mathZone == 'texMathZoneX' || a:mathZone == 'texMathZoneY' ) && atplib#CheckSyntaxGroups(['texMathZoneX', 'texMathZoneY'])
	let saved_pos	= getpos(".")
	let line	= line(".")	
	let l:count	= 0
	" count \$ if it is under the cursor
	if search('\\\@<!\$', 'Wc', stop_line)
	    let l:count += 1
	endif
	while line <= stop_line && line != 0
	    keepjumps let line	= search('\\\@<!\$', 'W', stop_line)
	    let l:count += 1
	endwhile
	keepjumps call setpos(".", saved_pos)
	let check	= l:count%2
    endif

    return check
endfunction
" {{{1 atplib#CheckSyntaxGroups
" This functions returns one if one of the environment given in the list
" a:zones is present in they syntax stack at line a:1 and column a:0.
" a:zones =	a list of zones
" a:1	  = 	line nr (default: current cursor line)
" a:2     =	column nr (default: column before the current cursor position)
" The function doesn't make any checks if the line and column supplied are
" valid /synstack() function returns 0 rather than [] in such a case/.
function! atplib#CheckSyntaxGroups(zones,...)
    let line		= a:0 >= 2 ? a:1 : line(".")
    let col		= a:0 >= 2 ? a:2 : col(".")-1
    let col		= max([1, col])
    let zones		= copy(a:zones)

    let synstack	= map(synstack( line, col), 'synIDattr(v:val, "name")') 
    let g:synstack	= synstack

    return max(map(zones, "count(synstack, v:val)"))
endfunction
" atplib#CopyIndentation {{{1
function! atplib#CopyIndentation(line)
    let raw_indent	= split(a:line,'\s\zs')
    let indent		= ""
    for char in raw_indent
	if char =~ '^\%(\s\|\t\)'
	    let indent.=char
	else
	    break
	endif
    endfor
    return indent
endfunction
"}}}1

" Tab Completion Related Functions:
" atplib#SearchPackage {{{1
"
" This function searches if the package in question is declared or not.
" Returns the line number of the declaration  or 0 if it was not found.
"
" It was inspired by autex function written by Carl Mueller, math at carlm e4ward c o m
" and made work for project files using lvimgrep.
"
" This function doesn't support plaintex filse (\\input{})
" ATP support plaintex input lines in a different way (but not that flexible
" as this: for plaintex I use atplib#GrepPackageList on startup (only!) and
" then match input name with the list).
"
" name = package name (tikz library name)
" a:1  = stop line (number of the line \\begin{document} 
" a:2  = pattern matching the command (without '^[^%]*\\', just the name)
" to match \usetikzlibrary{...,..., - 
function! atplib#SearchPackage(name,...)

    if getbufvar("%", "atp_MainFile") == ""
	    call SetProjectName()
    endif

"     let time	= reltime()

"     if bufloaded("^" . a:file . "$")
" 	let file=getbufline("^" . a:file . "$", "1", "$")
"     else
" 	let file=readfile(a:filename)
"     endif

    if a:0 != 0
	let stop_line	= a:1
    else
	if expand("%:p") == b:atp_MainFile
	    let saved_pos=getpos(".")
	    keepjumps call setpos(".", [0,1,1,0])
	    keepjumps let stop_line=search('\\begin\s*{document}','nW')
	else
	    if &l:filetype == 'tex'
		let saved_loclist	= getloclist(0)
		silent! execute '1lvimgrep /\\begin\s*{\s*document\s*}/j ' . fnameescape(b:atp_MainFile)
		let stop_line	= get(get(getloclist(0), 0, {}), 'lnum', 0)
		call setloclist(0, saved_loclist) 
	    else
		let stop_line = 0
	    endif
	endif
    endif

    let com	= a:0 >= 2 ? a:2 : 'usepackage\s*\%(\[[^]]*]\)\?'

    " If the current file is the b:atp_MainFile
    if expand("%:p") == b:atp_MainFile

	if !exists("saved_pos")
	    let saved_pos=getpos(".")
	endif
	if stop_line != 0

	    keepjumps call setpos(".",[0,1,1,0])
	    keepjumps let ret = search('^[^%]*\\'.com."\s*{[^}]*".a:name,'ncW', stop_line)
	    keepjump call setpos(".",saved_pos)

" 	    echo reltimestr(reltime(time))
	    return ret

	else

	    keepjumps call setpos(".",[0,1,1,0])
	    keepjumps let ret = search('^[^%]*\\'.com."\s*{[^}]*".a:name,'ncW')
	    keepjump call setpos(".", saved_pos)

" 	    echo reltimestr(reltime(time))
	    return ret

	endif

    " If the current file is not the mainfile
    else
	" Cache the Preambule / it is not changing so this is completely safe /
	if !exists("s:Preambule")
	    let s:Preambule = readfile(b:atp_MainFile) 
	    if stop_line != 0
		silent! call remove(s:Preambule, stop_line+1, -1)
	    endif
	endif
	let g:preambule = s:Preambule
	let lnum = 1
	for line in s:Preambule
	    if line =~ '^[^%]*\\'.com."\s*{[^}]*".a:name

" 		echo reltimestr(reltime(time))
		return lnum
	    endif
	    let lnum += 1
	endfor
    endif

"     echo reltimestr(reltime(time))

    " If the package was not found return 0 
    return 0

endfunction
" }}}1
" {{{1 atplib#GetPackageList()
" a:1	= '\\usepackage\s*{'
" a:2 	= stop lines
function! atplib#GetPackageList(...)

    let saved_pos	= getpos(".")
    call cursor(1,1)
    let pattern		= a:0 == 0 ? '\\usepackage\s*\(\[[^]]*\]\)\=\s*{' : a:1
    let stop_line 	= a:0  > 1 ? a:2 : search('\\begin\s*{\s*document\s*}')
    call cursor(1,1)

    let package_list	= []

    let line = 1
    while line
	let line	= search(pattern, 'W', stop_line)
	if line
	    let list = split(matchstr(getline(line),pattern.'\zs[^}]*\ze}'), ',') 
	    call map(list, "matchstr(v:val, '\\s*\\zs.*\\ze\\s*')")
	    call extend(package_list, list)
	endif
    endwhile
    call cursor(saved_pos[1], saved_pos[2])
    return package_list
endfunction
"}}}1
"{{{1 atplib#GrepPackageList()
" This function returns list of packages declared in the b:atp_MainFile (or
" a:1). If the filetype is plaintex it returns list of all \input{} files in
" the b:atp_MainFile. 
" I'm not shure if this will be OK for project files written in plaintex: Can
" one declare a package in the middle of document? probably yes. So it might
" be better to use TreeOfFiles in that case.

" This takes =~ 0.02 s. This is too long to call it in TabCompletion.
function! atplib#GrepPackageList(...)
" 	let time = reltime() 
    let file	= a:0 == 0 ? getbufvar("%", "atp_MainFile") : expand("%")
    if file == ""
	return []
    endif

    let ftype	= getbufvar(file, "&filetype")
    if ftype =~ '^\(ams\)\=tex$'
	let pat	= '\\usepackage\s*\(\[[^]]*\]\)\=\s*{'
    elseif ftype == 'plaintex'
	let pat = '\\input\s*{'
    else
" 	echoerr "ATP doesn't recognize the filetype " . &l:filetype . ". Using empty list of packages."
	return []
    endif

    let saved_loclist	= getloclist(0)
    try
	silent execute 'lvimgrep /^[^%]*'.pat.'/j ' . fnameescape(file)
    catch /E480: No match:/
	call setloclist(0, [{'text' : 'empty' }])
    endtry
    let loclist		= getloclist(0)
    call setloclist(0, saved_loclist)

    let pre		= map(loclist, 'v:val["text"]')
    let pre_l		= []
    for line in pre
	let package_l	= matchstr(line, pat.'\zs[^}]*\ze}')
	call add(pre_l, package_l)
    endfor

    " We make a string of packages separeted by commas and the split it
    " (compatibility with \usepackage{package_1,package_2,...})
    let pre_string	= join(pre_l, ',')
    let pre_list	= split(pre_string, ',')
    call filter(pre_list, "v:val !~ '^\s*$'")

"      echo reltimestr(reltime(time))
    return pre_list
endfunction
" atplib#DocumentClass {{{1
function! atplib#DocumentClass(file)

    let saved_loclist	= getloclist(0)
    try
	silent execute 'lvimgrep /\\documentclass/j ' . fnameescape(a:file)
    catch /E480: No match:/
    endtry
    let line		= get(get(getloclist(0), 0, "no_document_class"), 'text')
    call setloclist(0, saved_loclist)


    if line != 'no_document_class'
	return substitute(l:line,'.*\\documentclass\s*\%(\[.*\]\)\?{\(.*\)}.*','\1','')
    endif
 
    return 0
endfunction
" }}}1

" Searching Tools: (kpsewhich)
" {{{1 atplib#KpsewhichGlobPath 
" 	a:format	is the format as reported by kpsewhich --help
" 	a:path		path if set to "", then kpse which will find the path.
" 			The default is what 'kpsewhich -show-path tex' returns
" 			with "**" appended. 
" 	a:name 		can be "*" then finds all files with the given extension
" 			or "*.cls" to find all files with a given extension.
" 	a:1		modifiers (the default is ":t:r")
" 	a:2		filters path names matching the pattern a:1
" 	a:3		filters out path names not matching the pattern a:2
"
" 	Argument a:path was added because it takes time for kpsewhich to return the
" 	path (usually ~0.5sec). ATP asks kpsewhich on start up
" 	(g:atp_kpsewhich_tex) and then locks the variable (this will work
" 	unless sb is reinstalling tex (with different personal settings,
" 	changing $LOCALTEXMF) during vim session - not that often). 
"
" Example: call atplib#KpsewhichGlobPath('tex', '', '*', ':p', '^\(\/home\|\.\)','\%(texlive\|kpsewhich\|generic\)')
" gives on my system only the path of current dir (/.) and my localtexmf. 
" this is done in 0.13s. The long pattern is to 
"
" atp#KpsewhichGlobPath({format}, {path}, {expr=name}, [ {mods}, {pattern_1}, {pattern_2}]) 
function! atplib#KpsewhichGlobPath(format, path, name, ...)
"     let time	= reltime()
    let modifiers = a:0 == 0 ? ":t:r" : a:1
    if a:path == ""
	let path	= substitute(substitute(system("kpsewhich -show-path ".a:format ),'!!','','g'),'\/\/\+','\/','g')
	let path	= substitute(path,':\|\n',',','g')
	let path_list	= split(path, ',')
	let idx		= index(path_list, '.')
	if idx != -1
	    let dot 	= remove(path_list, index(path_list,'.')) . ","
	else
	    let dot 	= ""
	endif
	call map(path_list, 'v:val . "**"')

	let path	= dot . join(path_list, ',')
    else
	let path = a:path
    endif
    " If a:2 is non zero (if not given it is assumed to be 0 for compatibility
    " reasons)
    if get(a:000, 1, 0) != "0"
	let path_list	= split(path, ',')
	call filter(path_list, 'v:val =~ a:2')
	let path	= join(path_list, ',')
    endif
    if get(a:000, 2, 0) != "0"
	let path_list	= split(path, ',')
	call filter(path_list, 'v:val !~ a:3')
	let path	= join(path_list, ',')
    endif

    let list	= split(globpath(path, a:name),'\n') 
    call map(list, 'fnamemodify(v:val, modifiers)')
"     echomsg "TIME:" . join(reltime(time), ".")
    return list
endfunction
" }}}1
" {{{1 atplib#KpsewhichFindFile
" the arguments are similar to atplib#KpsewhichGlob except that the a:000 list
" is shifted:
" a:1		= path	
" 			if set to "" then kpsewhich finds the path.
" a:2		= count (as for findfile())
" a:3		= modifiers 
" a:4		= positive filter for path (see KpsewhichGLob a:1)
" a:5		= negative filter for path (see KpsewhichFind a:2)
"
" needs +path_extra vim feature
"
" atp#KpsewhichFindFile({format}, {expr=name}, [{path}, {count}, {mods}, {pattern_1}, {pattern_2}]) 
function! atplib#KpsewhichFindFile(format, name, ...)

    " Unset the suffixadd option
    let saved_sua	= &l:suffixesadd
    let &l:sua	= ""

"     let time	= reltime()
    let path	= a:0 >= 1 ? a:1 : ""
    let l:count	= a:0 >= 2 ? a:2 : 0
    let modifiers = a:0 >= 3 ? a:3 : ""
    " This takes most of the time!
    if path == ""
	let path	= substitute(substitute(system("kpsewhich -show-path ".a:format ),'!!','','g'),'\/\/\+','\/','g')
	let path	= substitute(path,':\|\n',',','g')
	let path_list	= split(path, ',')
	let idx		= index(path_list, '.')
	if idx != -1
	    let dot 	= remove(path_list, index(path_list,'.')) . ","
	else
	    let dot 	= ""
	endif
	call map(path_list, 'v:val . "**"')

	let path	= dot . join(path_list, ',')
	unlet path_list
    endif


    " If a:2 is non zero (if not given it is assumed to be 0 for compatibility
    " reasons)
    if get(a:000, 3, 0) != 0
	let path_list	= split(path, ',')
	call filter(path_list, 'v:val =~ a:4')
	let path	= join(path_list, ',')
    endif
    if get(a:000, 4, 0) != 0
	let path_list	= split(path, ',')
	call filter(path_list, 'v:val !~ a:5')
	let path	= join(path_list, ',')
    endif
    let g:path = path

    if l:count >= 1
	let result	= findfile(a:name, path, l:count)
    elseif l:count == 0
	let result	= findfile(a:name, path)
    elseif l:count < 0
	let result	= findfile(a:name, path, -1)
    endif
	

    if l:count >= 0 && modifiers != ""
	let result	= fnamemodify(result, modifiers) 
    elseif l:count < 0 && modifiers != ""
	call map(result, 'fnamemodify(v:val, modifiers)')
    endif
"     echomsg "TIME:" . join(reltime(time), ".")

    let &l:sua	= saved_sua
    return result
endfunction
" }}}1

" List Functoins:
" atplib#Extend {{{1
" arguments are the same as for extend(), but it adds only the entries which
" are not present.
function! atplib#Extend(list_a,list_b,...)
    let list_a=deepcopy(a:list_a)
    let list_b=deepcopy(a:list_b)
    let diff=filter(list_b,'count(l:list_a,v:val) == 0')
    if a:0 == 0
	return extend(list_a,diff)
    else
	return extend(list_a,diff, a:1)
    endif
endfunction
" }}}1
" {{{1 atplib#Add
function! atplib#Add(list,what)
    let new=[] 
    for element in a:list
	call add(new,element . a:what)
    endfor
    return new
endfunction
"}}}1

" Close Environments And Brackets:
" atplib#CloseLastEnvironment {{{1
" a:1 = i	(append before, so the cursor will  be after - the dafult)  
" 	a	(append after)
" a:2 = math 		the pairs \(:\), $:$, \[:\] or $$:$$ (if filetype is
" 						plaintex or b:atp_TexFlavor="plaintex")
" 	environment
" 			by the way, treating the math pairs together is very fast. 
" a:3 = environment name (if present and non zero sets a:2 = environment)	
" 	if one wants to find an environment name it must be 0 or "" or not
" 	given at all.
" a:4 = line and column number (in a vim list) where environment is opened
" ToDo: Ad a highlight to messages!!! AND MAKE IT NOT DISAPPEAR SOME HOW?
" (redrawing doesn't help) CHECK lazyredraw. 
" Note: this function tries to not double the checks what to close if it is
" given in the arguments, and find only the information that is not given
" (possibly all the information as all arguments can be omitted).
function! atplib#CloseLastEnvironment(...)

    let l:com	= a:0 >= 1 ? a:1 : 'i'
    let l:close = a:0 >= 2 && a:2 != "" ? a:2 : 0
    if a:0 >= 3
	let l:env_name	= a:3 == "" ? 0 : a:3
	let l:close 	= "environment"
    else
	let l:env_name 	= 0
    endif
    let l:bpos_env	= a:0 >= 4 ? a:4 : [0, 0]



"   {{{2 find the begining line of environment to close (if we are closing
"   an environment)
    if l:env_name == 0 && ( l:close == "environment" || l:close == 0 ) && l:close != "math"

	let filter 	= 'strpart(getline(''.''), 0, col(''.'') - 1) =~ ''\\\@<!%'''

	" Check if and environment is opened (\begin:\end):
	" This is the slow part :( 0.4s)
	" Find the begining line if it was not given.
	if l:bpos_env == [0, 0]
	    " Find line where the environment is opened and not closed:
	    let l:bpos_env		= searchpairpos('\\begin\s*{', '', '\\end\s*{', 'bnW', 'searchpair("\\\\begin\s*{\s*".matchstr(getline("."),"\\\\begin\s*{\\zs[^}]*\\ze\}"), "", "\\\\end\s*{\s*".matchstr(getline("."), "\\\\begin\s*{\\zs[^}]*\\ze}"), "nW", "", "line(".")+g:atp_completion_limits[2]")',max([ 1, (line(".")-g:atp_completion_limits[2])]))
	endif

	let l:env_name		= matchstr(strpart(getline(l:bpos_env[0]),l:bpos_env[1]-1), '\\begin\s*{\s*\zs[^}]*\ze*\s*}')

    " if a:3 (environment name) was given:
    elseif l:env_name != "0" && l:close == "environment" 

	let l:bpos_env	= searchpairpos('\\begin\s*{'.l:env_name.'}', '', '\\end\s*{'.l:env_name.'}', 'bnW', '',max([1,(line(".")-g:atp_completion_limits[2])]))

    endif
"   }}}2
"   {{{2 if a:2 was not given (l:close = 0) we have to check math modes as
"   well.
    if l:close == "0" || l:close == "math" 

	let stopline 		= search('^\s*$\|\\par\>', 'bnW')

	" Check if one of \(:\), \[:\], $:$, $$:$$ is opened using syntax
	" file. If it is fined the starting position.

	let synstack		= map(synstack(line("."),col(".")-1), 'synIDattr(v:val, "name")')
	let math_1		= (index(synstack, 'texMathZoneV') != -1 ? 1  : 0 )   
	    if math_1
		let bpos_math_1	= searchpos('\%(\%(\\\)\@<!\\\)\@<!\\(', 'bnW', stopline)
		let l:begin_line= bpos_math_1[0]
		let math_mode	= "texMathZoneV"
	    endif
	" the \[:\] pair:
	let math_2		= (index(synstack, 'texMathZoneW') != -1 ? 1  : 0 )   
	    if math_2
		let bpos_math_2	= searchpos('\%(\%(\\\)\@<!\\\)\@<!\\[', 'bnW', stopline)
		let l:begin_line= bpos_math_2[0]
		let math_mode	= "texMathZoneW"
	    endif
	" the $:$ pair:
	let math_3		= (index(synstack, 'texMathZoneX') != -1 ? 1  : 0 )   
	    if math_3
		let bpos_math_3	= searchpos('\%(\%(\\\)\@<!\\\)\@<!\$\{1,1}', 'bnW', stopline)
		let l:begin_line= bpos_math_3[0]
		let math_mode	= "texMathZoneX"
	    endif
	" the $$:$$ pair:
	let math_4		= (index(synstack, 'texMathZoneY') != -1 ? 1  : 0 )   
	    if math_4
		let bpos_math_4	= searchpos('\%(\%(\\\)\@<!\\\)\@<!\$\{2,2}', 'bnW', stopline)
		let l:begin_line= bpos_math_4[0]
		let math_mode	= "texMathZoneY"
	    endif
	let b:begin_line	= l:begin_line
    endif
"}}}2
"{{{2 set l:close if a:1 was not given.
if a:0 <= 1
" 	let l:begin_line=max([ l:begin_line_env, l:begin_line_imath, l:begin_line_dmath ])
    " now we can set what to close:
    " the synstack never contains two of the math zones: texMathZoneV,
    " texMathZoneW, texMathZoneX, texMathZoneY.
    if math_1 + math_2 + math_3 + math_4 >= 1
	let l:close = 'math'
    elseif l:begin_line_env
	let l:close = 'environment'
    endif
endif
let l:env=l:env_name
"}}}2

if l:close == "0" 
    return "there was nothing to close"
endif
if ( &filetype != "plaintex" && b:atp_TexFlavor != "plaintex" && exists("math_4") && math_4 )
    echohl ErrorMsg
    echomsg "$$:$$ in LaTeX are deprecated (this breaks some LaTeX packages)" 
    echomsg "You can set b:atp_TexFlavor = 'plaintex', and ATP will ignore this. "
    echohl Normal
    return 
endif
if l:env_name =~ '^\s*document\s*$'
    return ""
endif
let l:cline=getline(".")
let l:pos=getpos(".")
if l:close == "math"
    let l:line	= getline(l:begin_line)
elseif l:close == "environment"
    let l:line	= getline(l:bpos_env[0])
endif
" Copy the indentation of what we are closing.
let l:eindent=atplib#CopyIndentation(l:line)
"{{{2 close environment
    if l:close == 'environment'
	" Info message
	redraw
" 	silent echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0]

	" Rules:
	" env & \[ \]: close in the same line 
	" unless it starts in a serrate line,
	" \( \): close in the same line. 
	"{{{3 close environment in the same line
	if l:line !~ '^\s*\%(\$\|\$\$\|[^\\]\\(\|\\\@<!\\\[\)\?\s*\\begin\s*{[^}]*}\s*\%(([^)]*)\s*\|{[^}]*}\s*\|\[[^\]]*\]\s*\)\{,3}\%(\\label\s*{[^}]*}\s*\)\?$'
" 	    	This pattern matches:
" 	    		^ $
" 	    		^ $$
" 	    		^ \(
" 	    		^ \[
" 	    		^ (one of above or space) \begin { env_name } ( args1 ) [ args2 ] { args3 } \label {label}
" 	    		There are at most 3 args of any type with any order \label is matched optionaly.
" 	    		Any of these have to be followd by white space up to end of line.
	    "
	    " The line above cannot contain "\|^\s*$" pattern! Then the
	    " algorithm for placing the \end in right place is not called.
	    "
	    " 		    THIS WILL BE NEEDED LATER!
" 		    \ (l:close == 'display_math' 	&& l:line !~ '^\s*[^\\]\\\[\s*$') ||
" 		    \ (l:close == 'inline_math' 	&& (l:line !~ '^\s*[^\\]\\(\s*$' || l:begin_line == line("."))) ||
" 		    \ (l:close == 'dolar_math' 		&& l:cline =~ '\$')

	    " the above condition matches for the situations when we have to
	    " complete in the same line in four cases:
	    " l:close == environment, display_math, inline_math or
	    " dolar_math. 

	    " do not complete environments which starts in a definition.
" let b:cle_debug= (getline(l:begin_line) =~ '\\def\|\%(re\)\?newcommand') . " " . (l:begin_line != line("."))
" 	    if getline(l:begin_line) =~ '\\def\|\%(re\)\?newcommand' && l:begin_line != line(".")
"  		let b:cle_return="def"
" 		return b:cle_return
" 	    endif
	    if index(g:atp_no_complete, l:env) == '-1' &&
		\ !atplib#CheckClosed('\%(%.*\)\@<!\\begin\s*{' . l:env,'\%(%.*\)\@<!\\end\s*{' . l:env,line("."),g:atp_completion_limits[2])
		if l:com == 'a'  
		    call setline(line("."), strpart(l:cline,0,getpos(".")[2]) . '\end{'.l:env.'}' . strpart(l:cline,getpos(".")[2]))
		    let l:pos=getpos(".")
		    let l:pos[2]=len(strpart(l:cline,0,getpos(".")[2]) . '\end{'.l:env.'}')+1
		    keepjumps call setpos(".",l:pos)
		elseif l:cline =~ '^\s*$'
		    call setline(line("."), l:eindent . '\end{'.l:env.'}' . strpart(l:cline,getpos(".")[2]-1))
		    let l:pos=getpos(".")
		    let l:pos[2]=len(strpart(l:cline,0,getpos(".")[2]-1) . '\end{'.l:env.'}')+1
		    keepjumps call setpos(".",l:pos)
		else
		    call setline(line("."), strpart(l:cline,0,getpos(".")[2]-1) . '\end{'.l:env.'}' . strpart(l:cline,getpos(".")[2]-1))
		    let l:pos=getpos(".")
		    let l:pos[2]=len(strpart(l:cline,0,getpos(".")[2]-1) . '\end{'.l:env.'}')+1
		    keepjumps call setpos(".",l:pos)
		endif
	    endif "}}}3
	"{{{3 close environment in a new line 
	else 

		" do not complete environments which starts in a definition.

		let l:error=0
		let l:prev_line_nr="-1"
		let l:cenv_lines=[]
		let l:nr=line(".")
		
		let l:line_nr=line(".")
		" l:line_nr number of line which we complete
		" l:cenv_lines list of closed environments (we complete after
		" line number maximum of these numbers.

		let l:pos=getpos(".")
		let l:pos_saved=deepcopy(l:pos)

		while l:line_nr >= 0
			let l:line_nr=search('\%(%.*\)\@<!\\begin\s*{','bW')
		    " match last environment openned in this line.
		    " ToDo: afterwards we can make it works for multiple openned
		    " envs.
		    let l:env_name=matchstr(getline(l:line_nr),'\%(%.*\)\@<!\\begin\s*{\zs[^}]*\ze}\%(.*\\begin\s*{[^}]*}\)\@!')
		    if index(g:atp_long_environments,l:env_name) != -1
			let l:limit=3
		    else
			let l:limit=2
		    endif
		    let l:close_line_nr=atplib#CheckClosed('\%(%.*\)\@<!\\begin\s*{' . l:env_name, 
				\ '\%(%.*\)\@<!\\end\s*{' . l:env_name,
				\ l:line_nr,g:atp_completion_limits[l:limit],1)

		    if l:close_line_nr != 0
			call add(l:cenv_lines,l:close_line_nr)
		    else
			break
		    endif
		    let l:line_nr-=1
		endwhile

		keepjumps call setpos(".",l:pos)
			
		if getline(l:line_nr) =~ '\%(%.*\)\@<!\%(\\def\|\%(re\)\?newcommand\)' && l:line_nr != line(".")
" 		    let b:cle_return="def"
		    return
		endif

		" get all names of environments which begin in this line
		let l:env_names=[]
		let l:line=getline(l:line_nr)
		while l:line =~ '\\begin\s*{' 
		    let l:cenv_begins = match(l:line,'\%(%.*\)\@<!\\begin{\zs[^}]*\ze}\%(.*\\begin\s{\)\@!')
		    let l:cenv_name = matchstr(l:line,'\%(%.*\)\@<!\\begin{\zs[^}]*\ze}\%(.*\\begin\s{\)\@!')
		    let l:cenv_len=len(l:cenv_name)
		    let l:line=strpart(l:line,l:cenv_begins+l:cenv_len)
		    call add(l:env_names,l:cenv_name)
			" DEBUG:
" 			let g:env_names=l:env_names
" 			let g:line=l:line
" 			let g:cenv_begins=l:cenv_begins
" 			let g:cenv_name=l:cenv_name
		endwhile
		" thus we have a list of env names.
		
		" make a dictionary of lines where they closes. 
		" this is a list of pairs (I need the order!)
		let l:env_dict=[]

		" list of closed environments
		let l:cenv_names=[]

		for l:uenv in l:env_names
		    let l:uline_nr=atplib#CheckClosed('\%(%.*\)\@<!\\begin\s*{' . l:uenv . '}', 
				\ '\%(%.*\)\@<!\\end\s*{' . l:uenv . '}', l:line_nr, g:atp_completion_limits[2])
		    call extend(l:env_dict,[ l:uenv, l:uline_nr])
		    if l:uline_nr != '0'
			call add(l:cenv_names,l:uenv)
		    endif
		endfor
		
		" close unclosed environment

		" check if at least one of them is closed
		if len(l:cenv_names) == 0
		    let l:str=""
		    for l:uenv in l:env_names
			if index(g:atp_no_complete,l:uenv) == '-1'
			    let l:str.='\end{' . l:uenv .'}'
			endif
		    endfor
		    " l:uenv will remain the last environment name which
		    " I use!
		    " Do not append empty lines (l:str is empty if all l:uenv
		    " belongs to the g:atp_no_complete list.
		    if len(l:str) == 0
			return 0
		    endif
		    let l:eindent=atplib#CopyIndentation(getline(l:line_nr))
		    let l:pos=getpos(".")
		    if len(l:cenv_lines) > 0 

			let l:max=max(l:cenv_lines)
			let l:pos[1]=l:max+1
			" find the first closed item below the last closed
			" pair (below l:pos[1]). (I assume every env is in
			" a seprate line!
			let l:end=atplib#CheckClosed('\%(%.*\)\@<!\\begin\s*{','\%(%.*\)\@<!\\end\s*{',l:line_nr,g:atp_completion_limits[2],1)
" 			let g:info= " l:max=".l:max." l:end=".l:end." line('.')=".line(".")." l:line_nr=".l:line_nr
			" if the line was found append just befor it.
			if l:end != 0 
				if line(".") <= l:max
				    if line(".") <= l:end
					call append(l:max, l:eindent . l:str)
					echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0] . " at line " . l:end+1  
					call setpos(".",[0,l:max+1,len(l:eindent.l:str)+1,0])
				    else
					call append(l:end-1, l:eindent . l:str)
					echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0] . " at line " . l:end+1 
					call setpos(".",[0,l:end,len(l:eindent.l:str)+1,0])
				    endif
				elseif line(".") < l:end
				    let [ lineNr, pos_lineNr ]	= getline(".") =~ '^\s*$' ? [ line(".")-1, line(".")] : [ line("."), line(".")+1 ]
				    call append(lineNr, l:eindent . l:str)
				    echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0] . " at line " . line(".")+1  
				    call setpos(".",[0, pos_lineNr,len(l:eindent.l:str)+1,0])
				elseif line(".") >= l:end
				    call append(l:end-1, l:eindent . l:str)
				    echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0] . " at line " . l:end
				    call setpos(".",[0,l:end,len(l:eindent.l:str)+1,0])
				endif
			else
			    if line(".") >= l:max
				call append(l:pos_saved[1], l:eindent . l:str)
				keepjumps call setpos(".",l:pos_saved)
				echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0] . " at line " . line(".")+1
				call setpos(".",[0,l:pos_saved[1]+1,len(l:eindent.l:str)+1,0])
			    elseif line(".") < l:max
				call append(l:max, l:eindent . l:str)
				echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0] . " at line " . l:max+1
				call setpos(".",[0,l:max+1,len(l:eindent.l:str)+1,0])
			    endif
			endif
		    else
			let l:pos[1]=l:line_nr
			let l:pos[2]=1
			" put cursor at the end of the line where not closed \begin was
			" found
			keepjumps call setpos(".",[0,l:line_nr,len(getline(l:line_nr)),0])
			let l:cline	= getline(l:pos_saved[1])
			let g:cline	= l:cline
			let g:line	= l:pos_saved[1]
			let l:iline=searchpair('\\begin{','','\\end{','nW')
			if l:iline > l:line_nr && l:iline <= l:pos_saved[1]
			    call append(l:iline-1, l:eindent . l:str)
			    echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0] . " at line " . l:iline
			    let l:pos_saved[2]+=len(l:str)
			    call setpos(".",[0,l:iline,len(l:eindent.l:str)+1,0])
			else
			    if l:cline =~ '\\begin{\%('.l:uenv.'\)\@!'
				call append(l:pos_saved[1]-1, l:eindent . l:str)
				echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0] . " at line " . l:pos_saved[1]
				let l:pos_saved[2]+=len(l:str)
				call setpos(".",[0,l:pos_saved[1],len(l:eindent.l:str)+1,0])
			    elseif l:cline =~ '^\s*$'
				call append(l:pos_saved[1]-1, l:eindent . l:str)
				echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0] . " at line " . l:pos_saved[1]
				let l:pos_saved[2]+=len(l:str)
				call setpos(".",[0,l:pos_saved[1]+1,len(l:eindent.l:str)+1,0])
			    else
				call append(l:pos_saved[1], l:eindent . l:str)
				echomsg "Closing " . l:env_name . " from line " . l:bpos_env[0] . " at line " . l:pos_saved[1]+1
				let l:pos_saved[2]+=len(l:str)
				call setpos(".",[0,l:pos_saved[1]+1,len(l:eindent.l:str)+1,0])
			    endif
			endif 
			return 1
		    endif
		else
		    return "this is too hard?"
		endif
		unlet! l:env_names
		unlet! l:env_dict
		unlet! l:cenv_names
		unlet! l:pos 
		unlet! l:pos_saved
" 		if getline('.') =~ '^\s*$'
" 		    exec "normal dd"
		endif
    "}}}3
    "{{{2 close math: texMathZoneV, texMathZoneW, texMathZoneX, texMathZoneY 
    else
	"{{{3 Close math in the current line
	echomsg "Closing math from line " . l:begin_line
	if    math_mode == 'texMathZoneV' && l:line !~ '^\s*\\(\s*$' 	||
	    \ math_mode == 'texMathZoneW' && l:line !~ '^\s*\\\[\s*$' 	||
	    \ math_mode == 'texMathZoneX' && l:line !~ '^\s*\$\s*$' 	||
	    \ math_mode == 'texMathZoneY' && l:line !~ '^\s*\$\{2,2}\s*$'
	    if math_mode == "texMathZoneW"
	 	if l:com == 'a' 
		    if getline(l:begin_line) =~ '^\s*\\\[\s*$'
			call append(line("."),atplib#CopyIndentation(getline(l:begin_line)).'\]')
		    else
			call setline(line("."), strpart(l:cline,0,getpos(".")[2]) . '\]'. strpart(l:cline,getpos(".")[2]))
		    endif
		else
		    if getline(l:begin_line) =~ '^\s*\\\[\s*$'
			call append(line("."),atplib#CopyIndentation(getline(l:begin_line)).'\]')
		    else
			call setline(line("."), strpart(l:cline,0,getpos(".")[2]-1) . '\]'. strpart(l:cline,getpos(".")[2]-1))
" TODO: This could be optional: (but the option rather
" should be an argument of this function rather than
" here!
		    endif
		    let l:pos=getpos(".")
		    let l:pos[2]+=2
		    keepjumps call setpos(("."),l:pos)
		    let b:cle_return="texMathZoneW"
		endif
	    elseif math_mode == "texMathZoneV"
		if l:com == 'a'
		    call setline(line("."), strpart(l:cline,0,getpos(".")[2]) . '\)'. strpart(l:cline,getpos(".")[2]))
		else
		    call setline(line("."), strpart(l:cline,0,getpos(".")[2]-1) . '\)'. strpart(l:cline,getpos(".")[2]-1))
		    call cursor(line("."),col(".")+2)
		    let b:cle_return="V"
		endif
	    elseif math_mode == "texMathZoneX" 
		call setline(line("."), strpart(l:cline,0,getpos(".")[2]-1) . '$'. strpart(l:cline,getpos(".")[2]-1))
		call cursor(line("."),col(".")+1)
	    elseif math_mode == "texMathZoneY" 
		call setline(line("."), strpart(l:cline,0,getpos(".")[2]-1) . '$$'. strpart(l:cline,getpos(".")[2]-1))
		call cursor(line("."),col(".")+2)
	    endif " }}}3
	"{{{3 Close math in a new line, preserv the indentation.
	else 	    
	    let l:eindent=atplib#CopyIndentation(l:line)
	    if math_mode == 'texMathZoneW'
		let l:iline=line(".")
		" if the current line is empty append before it.
		if getline(".") =~ '^\s*$' && l:iline > 1
		    let l:iline-=1
		endif
		call append(l:iline, l:eindent . '\]')
		echomsg "\[ closed in line " . l:iline
" 		let b:cle_return=2 . " dispalyed math " . l:iline  . " indent " . len(l:eindent) " DEBUG
	    elseif math_mode == 'texMathZoneV'
		let l:iline=line(".")
		" if the current line is empty append before it.
		if getline(".") =~ '^\s*$' && l:iline > 1
		    let l:iline-=1
		endif
		call append(l:iline, l:eindent . '\)')
		echomsg "\( closed in line " . l:iline
" 		let b:cle_return=2 . " inline math " . l:iline . " indent " .len(l:eindent) " DEBUG
	    elseif math_mode == 'texMathZoneX'
		let l:iline=line(".")
		" if the current line is empty append before it.
		if getline(".") =~ '^\s*$' && l:iline > 1
		    let l:iline-=1
		endif
		let sindent=atplib#CopyIndentation(getline(search('\$', 'bnW')))
		call append(l:iline, sindent . '$')
		echomsg "$ closed in line " . l:iline
	    elseif math_mode == 'texMathZoneY'
		let l:iline=line(".")
		" if the current line is empty append before it.
		if getline(".") =~ '^\s*$' && l:iline > 1
		    let l:iline-=1
		endif
		let sindent=atplib#CopyIndentation(getline(search('\$\$', 'bnW')))
		call append(l:iline, sindent . '$$')
		echomsg "$ closed in line " . l:iline
	    endif
	endif "}}3
    endif
    "}}}2
endfunction
" imap <F7> <Esc>:call atplib#CloseLastEnvironment()<CR>
" }}}1
" {{{1 atplib#CloseLastBracket
"
" Note adding a bracket pair doesn't mean that it will be supported!
" This is to be done! and is quite easy.

" Notes: it first closes the most outer opened bracket:
" 	\left\{\Bigl( 
" 	will first close with \right\} and then \Bigl)
" it still doesn't work 100% well with nested brackets (the part that remains is to
" close in right place) But is doesn't close closed pairs !!! 

" {{{2 			atplib#CloseLastBracket	
" a:1 == 1 just return the bracket 
function! atplib#CloseLastBracket(...)
    
    if a:0 >= 1
	let l:only_return = a:1
    else
	let l:only_return = 0
    endif

    " {{{3
    let l:pattern=""
    let l:size_patterns=[]
    for l:size in keys(g:atp_sizes_of_brackets)
	call add(l:size_patterns,escape(l:size,'\'))
    endfor

    let l:pattern_b	= '\C\%('.join(l:size_patterns,'\|').'\)'
    let l:pattern_o	= '\%('.join(map(keys(g:atp_bracket_dict),'escape(v:val,"\\[]")'),'\|').'\)'

"     let g:pattern_b	= l:pattern_b
"     let g:pattern_o	= l:pattern_o

    let l:limit_line	= max([1,(line(".")-g:atp_completion_limits[1])])
        
    let l:pos_saved 	= getpos(".")


   " But maybe we shouldn't check if the bracket is closed sometimes one can
   " want to close closed bracket and delete the old one.
   
   let l:open_col_check_list=[]
   let g:open_col_check_list=l:open_col_check_list

   "    change the position! and then: 
   "    check the flag 'r' in searchpair!!!
   let i=1
    for ket in keys(g:atp_bracket_dict)
	let l:pos=deepcopy(l:pos_saved)
	let l:pair_{i}=searchpairpos(escape(ket,'\[]'),'', escape(g:atp_bracket_dict[ket], '\[]'). '\|\.' ,'bnW',"",l:limit_line)
" 	echomsg ket . " l:pair_".i."=".string(l:pair_{i})
	let l:pos[1]=l:pair_{i}[0]
	let l:pos[2]=l:pair_{i}[1]
	" l:check_{i} is 1 if the bracket is closed
	let l:check_{i}= atplib#CheckClosed(escape(ket, '\'), escape(g:atp_bracket_dict[ket], '\'), line("."), g:atp_completion_limits[0],1) == '0'
	" l:check_dot_{i} is 1 if the bracket is closed with a dot (\right.) . 
	let l:check_dot_{i} = atplib#CheckClosed(escape(ket, '\'), '\\\%(right\|\cb\Cig\{1,2}\%(g\|l\)\@!r\=\)\s*\.',line("."),g:atp_completion_limits[0],1) == '0'
" 	echomsg ket . " l:check_".i."=".string(l:check_{i}) . " l:check_dot_".i."=".string(l:check_dot_{i})
	let l:check_{i}=min([l:check_{i}, l:check_dot_{i}])
	call add(l:open_col_check_list,(l:check_{i}*l:pair_{i}[1]))
	keepjumps call setpos(".",l:pos_saved)
	let i+=1
    endfor
    keepjumps call setpos(".",l:pos_saved)

    " \lceil : \rceil, \lfloor:\rfloor paris
    let pair_ceil	= searchpairpos('\\lceil\>', '', '\\rceil\>', 'bnW', '', l:limit_line)
    let g:pair_ceil	= pair_ceil
    " check if closed:
    let check_ceil	= searchpair('\\lceil\>', '', '\\rceil\>', 'nW', '', line(".")+g:atp_completion_limits[0]) 
    let g:check_ceil	= check_ceil
"     if !check_ceil && pair_ceil != [ 0, 0]
	"close ceil (if all brackets before are closed!)
"     endif
   
    let l:open_col=max(l:open_col_check_list)
    let j=1
    while j<i
	if l:open_col == l:pair_{j}[1] && l:check_{j} != 0
	    let l:open_line=l:pair_{j}[0]
	endif
	let j+=1
    endwhile

    " Check and Close Environment:
    " 	This takes too long:
"  	let open_env		= searchpairpos('\\begin\s*{', '', '\\end\s*{', 'bnW', 'searchpair("\\\\begin\s*{\s*".matchstr(getline("."),"\\\\begin\s*{\\zs[^}]*\\ze\}"), "", "\\\\end\s*{\s*".matchstr(getline("."), "\\\\begin\s*{\\zs[^}]*\\ze}"), "nW", "", "line(".")+g:atp_completion_limits[2]")', l:open_line)

	for env_name in g:atp_closebracket_checkenv
" 	    " To Do: this should check for the most recent opened environment
	    let open_env		= searchpairpos('\\begin\s*{\s*'.env_name.'\s*}', '', '\\end\s*{\s*'.env_name.'\s*}', 'bnW', '', l:open_line)
	    let env_name		= matchstr(strpart(getline(open_env[0]),open_env[1]-1), '\\begin\s*{\s*\zs[^}]*\ze*\s*}')
	    if open_env[0] && atplib#CompareCoordinates([ l:open_line, l:open_col], open_env)
		call atplib#CloseLastEnvironment('i', 'environment', env_name, open_env)
		return
	    endif
	endfor

   " Debug:
"        let g:open_line=l:open_line
"        let g:open_col=l:open_col 

    "}}}3
    " {{{3 main if
   if l:open_col 
	let l:line=getline(l:open_line)

	let l:bline=strpart(l:line,0,(l:open_col-1))
	let l:eline=strpart(l:line,l:open_col-1,2)

	let l:opening_size=matchstr(l:bline,'\zs'.l:pattern_b.'\ze\s*$')
	let l:closing_size=get(g:atp_sizes_of_brackets,l:opening_size,"")
	let l:opening_bracket=matchstr(l:eline,'^'.l:pattern_o)

	if l:opening_size =~ '\\' && l:opening_bracket != '(' && l:opening_bracket != '['
	    let l:bbline=strpart(l:bline, 0, len(l:bline)-1)
	    let l:opening_size2=matchstr(l:bbline,'\zs'.l:pattern_b.'\ze\s*$')
	    let l:closing_size2=get(g:atp_sizes_of_brackets,l:opening_size2,"")
	    let l:closing_size=l:closing_size2.l:closing_size

	    " DEBUG
" 	    let g:bbline=l:bbline
" 	    let g:opening_size2=l:opening_size2
" 	    let g:closing_size2=l:closing_size2
	endif

	echomsg "Closing " . l:opening_size . l:opening_bracket . " from line " . l:open_line

	" DEBUG:
" 	let b:o_bra=l:opening_bracket
" 	let b:o_size=l:opening_size
" 	let b:bline=l:bline
" 	let b:line=l:line
" 	let b:eline=l:eline
" 	let b:opening_size=l:opening_size
" 	let b:closing_size=l:closing_size

	let l:cline=getline(line("."))
	if mode() == 'i'
	    if !l:only_return
		call setline(line("."), strpart(l:cline,0,getpos(".")[2]-1).
			\ l:closing_size.get(g:atp_bracket_dict,l:opening_bracket). 
			\ strpart(l:cline,getpos(".")[2]-1))
	    endif
	    let l:return=l:closing_size.get(g:atp_bracket_dict,l:opening_bracket)
	elseif mode() == 'n'
	    if !l:only_return
		call setline(line("."), strpart(l:cline,0,getpos(".")[2]).
			\ l:closing_size.get(g:atp_bracket_dict,l:opening_bracket). 
			\ strpart(l:cline,getpos(".")[2]))
	    endif
	    let l:return=l:closing_size.get(g:atp_bracket_dict,l:opening_bracket)
	endif
	let l:pos=getpos(".")
	let l:pos[2]+=len(l:closing_size.get(g:atp_bracket_dict,l:opening_bracket))
	keepjumps call setpos(".",l:pos)

	return l:return
   endif
   " }}}3
endfunction
" }}}2
" }}}1

" Tab Completion:
" atplib#TabCompletion {{{1
" This is the main TAB COMPLITION function.
"
" expert_mode = 1 (on)  gives less completions in some cases (commands,...)
" 			the matching pattern has to match at the beginning and
" 			is case sensitive. Furthermode  in expert mode, if
" 			completing a command and found less than 1 match then
" 			the function tries to close \(:\) or \[:\] (but not an
" 			environment, before doing ToDo in line 3832 there is
" 			no sense to make it).
" 			<Tab> or <F7> (if g:atp_no_tab_map=1)
" expert_mode = 0 (off) gives more matches but in some cases better ones, the
" 			string has to match somewhare and is case in
" 			sensitive, for example:
" 			\arrow<Tab> will show all the arrows definded in tex,
" 			in expert mode there would be no match (as there is no
" 			command in tex which begins with \arrow).
" 			<S-Tab> or <S-F7> (if g:atp_no_tab_map=1)
"
" ToDo: \ref{<Tab> do not closes the '}', its by purpose, as sometimes one
" wants to add more than one reference. But this is not allowed by this
" command! :) I can add it.
" Completion Modes:
" 	documentclass (\documentclass)
" 	labels   (\ref,\eqref)
" 	packages (\usepackage)
" 	commands
" 	environments (\begin,\(:\),\[:\])
" 	brackets ((:),[:],{:}) preserves the size operators!
" 		Always: check first brackets then environments. Bracket
" 		funnction can call function which closes environemnts but not
" 		vice versa.
" 	bibitems (\cite\|\citep\|citet)
" 	bibfiles (\bibliography)
" 	bibstyle (\bibliographystyle)
" 	end	 (close \begin{env} with \end{env})
" 	font encoding
" 	font family
" 	font series
" 	font shape
" 
"ToDo: the completion should be only done if the completed text is different
"from what it is. But it might be as it is, there are reasons to keep this.
"
try
function! atplib#TabCompletion(expert_mode,...)
    " {{{2 Match the completed word 
    let l:normal_mode=0

    if a:0 >= 1
	let l:normal_mode=a:1
    endif

    " this specifies the default argument for atplib#CloseLastEnvironment()
    " in some cases it is better to append after than before.
    let l:append='i'

    " Define string parts used in various completitons
    let l:pos		= getpos(".")
    let l:pos_saved	= deepcopy(l:pos)
    let l:line		= join(getbufline("%",l:pos[1]))
    let l:nchar		= strpart(l:line,l:pos[2]-1,1)
"     let l:rest		= strpart(l:line,l:pos[2]-1) 
    let l:l		= strpart(l:line,0,l:pos[2]-1)
    let l:n		= strridx(l:l,'{')
    let l:m		= strridx(l:l,',')
    let l:o		= strridx(l:l,'\')
    let l:s		= strridx(l:l,' ')
    let l:p		= strridx(l:l,'[')
     
    let l:nr=max([l:n,l:m,l:o,l:s,l:p])

    " this matches for \...
    let l:begin=strpart(l:l,l:nr+1)
    let l:cbegin=strpart(l:l,l:nr)
    " and this for '\<\w*$' (beginning of last started word) -- used in
    " tikzpicture completion method 
    let l:tbegin=matchstr(l:l,'\zs\<\w*$')
    let l:obegin=strpart(l:l,l:o)

    " what we are trying to complete: usepackage, environment.
    let l:pline=strpart(l:l,0,l:nr)

"     let g:nchar	= l:nchar
"     let g:l		= l:l
"     let g:n		= l:n
"     let g:o		= l:o
"     let g:s		= l:s
"     let g:p		= l:p
"     let g:nr		= l:nr
" 
"     let g:line	= l:line    
"     let g:tbegin	= l:tbegin
"     let g:cbegin	= l:cbegin
"     let g:obegin	= l:obegin
"     let g:begin	= l:begin 
"     let g:pline	= l:pline


    let l:limit_line=max([1,(l:pos[1]-g:atp_completion_limits[1])])
    let g:limit_line=limit_line
" {{{2 SET COMPLETION METHOD
    " {{{3 --------- command
    if l:o > l:n && l:o > l:s && 
	\ l:pline !~ '\%(input\|include\%(only\)\?\|[^\\]\\\\[^\\]$\)' &&
	\ l:pline !~ '\\\@<!\\$' &&
	\ l:begin !~ '{\|}\|,\|-\|\^\|\$\|(\|)\|&\|-\|+\|=\|#\|:\|;\|\.\|,\||\|?$' &&
	\ l:begin !~ '^\[\|\]\|-\|{\|}\|(\|)' &&
	\ l:cbegin =~ '^\\' && !l:normal_mode &&
	\ l:l !~ '\\\%(no\)\?cite[^}]*$'

	" in this case we are completing a command
	" the last match are the things which for sure do not ends any
	" command. The pattern '[^\\]\\\\[^\\]$' do not matches "\" and "\\\",
	" in which case the line contains "\\" and "\\\\" ( = line ends!)
	" (here "\" is one character \ not like in magic patterns '\\')
	" but matches "" and "\\" (i.e. when completing "\" or "\\\" [end line
	" + command].
	if index(g:atp_completion_active_modes, 'commands') != -1
	    let l:completion_method='command'
	    " DEBUG:
	    let b:comp_method='command'
	else
" 	    let b:comp_method='command fast return'
	    return ''
	endif
    "{{{3 --------- environment names
    elseif (l:pline =~ '\%(\\begin\|\\end\)\s*$' && l:begin !~ '}.*$' && !l:normal_mode)
	if index(g:atp_completion_active_modes, 'environment names') != -1 
	    let l:completion_method='environment_names'
	    " DEBUG:
	    let b:comp_method='environment_names'
	else
" 	    let b:comp_method='environment_names fast return'
	    return ''
	endif
    "{{{3 --------- close environments
"     elseif !l:normal_mode && 
" 		\ ((l:pline =~ '\\begin\s*$' && l:begin =~ '}\s*$') || ( l:pline =~ '\\begin\s*{[^}]*}\s*\\label' ) ) || 
" 		\ l:normal_mode && l:pline =~ '\\begin\s*\({[^}]*}\?\)\?\s*$'
" 	if (!l:normal_mode && index(g:atp_completion_active_modes, 'close environments') != -1 ) ||
" 		    \ (l:normal_mode && index(g:atp_completion_active_modes_normal_mode, 'close environments') != -1 )
" 	    let l:completion_method='close environments'
" 	    " DEBUG:
" 	    let b:comp_method='colse environments'
" 	else
" 	    let b:comp_method='colse environments fast return'
" 	    return ''
" 	endif
    "{{{3 --------- colors
    elseif l:l =~ '\\textcolor{[^}]*$'
	let l:completion_method='colors'
	" DEBUG:
	let b:comp_method='colors'
    "{{{3 --------- label
    elseif l:pline =~ '\\\%(eq\)\?ref\s*$' && !l:normal_mode
	if index(g:atp_completion_active_modes, 'labels') != -1 
	    let l:completion_method='labels'
	    " DEBUG:
	    let b:comp_method='label'
	else
	    let b:comp_method='label fast return'
	    return ''
	endif
    "{{{3 --------- bibitems
    elseif l:pline =~ '\\\%(no\)\?cite' && !l:normal_mode && l:l !~ '\\cite\s*{[^}]*}'
	if index(g:atp_completion_active_modes, 'bibitems') != -1
	    let l:completion_method='bibitems'
	    " DEBUG:
	    let b:comp_method='bibitems'
	else
	    let b:comp_method='bibitems fast return'
	    return ''
	endif
    "{{{3 --------- tikzpicture
    elseif search('\%(\\def\>.*\|\\\%(re\)\?newcommand\>.*\|%.*\)\@<!\\begin{tikzpicture}','bnW') > search('[^%]*\\end{tikzpicture}','bnW') ||
	\ !atplib#CompareCoordinates(searchpos('[^%]*\zs\\tikz{','bnw'),searchpos('}','bnw'))
	"{{{4 ----------- tikzpicture keywords
	if l:l =~ '\%(\s\|\[\|{\|}\|,\|\.\|=\|:\)' . l:tbegin . '$' && !l:normal_mode
	    if index(g:atp_completion_active_modes, 'tikzpicture keywords') != -1 
		" DEBUG:
		let b:comp_method='tikzpicture keywords'
		let l:completion_method="tikzpicture keywords"
	    else
		let b:comp_method='tikzpicture keywords fast return'
		return ''
	    endif
	"{{{4 ----------- tikzpicture commands
	elseif  l:l =~ '\\' . l:tbegin  . '$' && !l:normal_mode
	    if index(g:atp_completion_active_modes, 'tikzpicture commands') != -1
		" DEBUG:
		let b:comp_method='tikzpicture commands'
		let l:completion_method="tikzpicture commands"
	    else
		let b:comp_method='tikzpicture commands fast return'
		return ''
	    endif
	"{{{4 ----------- close_env tikzpicture
	else
	    if (!normal_mode &&  index(g:atp_completion_active_modes, 'close environments') != -1 ) ||
			\ (l:normal_mode && index(g:atp_completion_active_modes_normal_mode, 'close environments') != -1 )
		" DEBUG:
		let b:comp_method='close_env tikzpicture'
		let l:completion_method="close_env"
	    else
		let b:comp_method='close_env tikzpicture fast return'
		return ''
	    endif
	endif
    "{{{3 --------- package
    elseif l:pline =~ '\\usepackage\%([.*]\)\?\s*' && !l:normal_mode
	if index(g:atp_completion_active_modes, 'package names') != -1
	    let l:completion_method='package'
	    " DEBUG:
	    let b:comp_method='package'
	else
	    let b:comp_method='package fast return'
	    return ''
	endif
    "{{{3 --------- tikz libraries
    elseif l:pline =~ '\\usetikzlibrary\%([.*]\)\?\s*' && !l:normal_mode
	if index(g:atp_completion_active_modes, 'tikz libraries') != -1
	    let l:completion_method='tikz libraries'
	    " DEBUG:
	    let b:comp_method='tikz libraries'
	else
	    let b:comp_method='tikz libraries fast return'
	    return ''
	endif
    "{{{3 --------- inputfiles
    elseif ((l:pline =~ '\\input' || l:begin =~ 'input') ||
	  \ (l:pline =~ '\\include' || l:begin =~ 'include') ||
	  \ (l:pline =~ '\\includeonly' || l:begin =~ 'includeonly') ) && !l:normal_mode 
	if l:begin =~ 'input'
	    let l:begin=substitute(l:begin,'.*\%(input\|include\%(only\)\?\)\s\?','','')
	endif
	if index(g:atp_completion_active_modes, 'input files') != -1
	    let l:completion_method='inputfiles'
	    " DEBUG:
	    let b:comp_method='inputfiles'
	else
	    let b:comp_method='inputfiles fast return'
	    return ''
	endif
    "{{{3 --------- bibfiles
    elseif l:pline =~ '\\bibliography\%(style\)\@!' && !l:normal_mode
	if index(g:atp_completion_active_modes, 'bibfiles') != -1
	    let l:completion_method='bibfiles'
	    " DEBUG:
	    let b:comp_method='bibfiles'
	else
	    let b:comp_method='bibfiles fast return'
	    return ''
	endif
    "{{{3 --------- bibstyles
    elseif l:pline =~ '\\bibliographystyle' && !l:normal_mode 
	if (index(g:atp_completion_active_modes, 'bibstyles') != -1 ) 
	    let l:completion_method='bibstyles'
	    let b:comp_method='bibstyles'
	else
	    let b:comp_method='bibstyles fast return'
	    return ''
	endif
    "{{{3 --------- documentclass
    elseif l:pline =~ '\\documentclass\>' && !l:normal_mode 
	if index(g:atp_completion_active_modes, 'documentclass') != -1
	    let l:completion_method='documentclass'
	    let b:comp_method='documentclass'
	else
	    let b:comp_method='documentclass fast return'
	    return ''
	endif
    "{{{3 --------- font family
    elseif l:l =~ '\%(\\usefont{[^}]*}{\|\\DeclareFixedFont{[^}]*}{[^}]*}{\|\\fontfamily{\)[^}]*$' && !l:normal_mode 
	if index(g:atp_completion_active_modes, 'font family') != -1
	    let l:completion_method='font family'
	    let b:comp_method='font family'
	else
	    let b:comp_method='font family fast return'
	    return ''
	endif
    "{{{3 --------- font series
    elseif l:l =~ '\%(\\usefont{[^}]*}{[^}]*}{\|\\DeclareFixedFont{[^}]*}{[^}]*}{[^}]*}{\|\\fontseries{\)[^}]*$' && !l:normal_mode 
	if index(g:atp_completion_active_modes, 'font series') != -1
	    let l:completion_method='font series'
	    let b:comp_method='font series'
	else
	    let b:comp_method='font series fast return'
	    return ''
	endif
    "{{{3 --------- font shape
    elseif l:l =~ '\%(\\usefont{[^}]*}{[^}]*}{[^}]*}{\|\\DeclareFixedFont{[^}]*}{[^}]*}{[^}]*}{[^}]*}{\|\\fontshape{\)[^}]*$' && !l:normal_mode 
	if index(g:atp_completion_active_modes, 'font shape') != -1
	    let l:completion_method='font shape'
	    let b:comp_method='font shape'
	else
	    let b:comp_method='font shape fast return'
	    return ''
	endif
    "{{{3 --------- font encoding
    elseif l:l =~ '\%(\\usefont{\|\\DeclareFixedFont{[^}]*}{\|\\fontencoding{\)[^}]*$' && !l:normal_mode 
	if index(g:atp_completion_active_modes, 'font encoding') != -1
	    let l:completion_method='font encoding'
	    let b:comp_method='font encoding'
	else
	    let b:comp_method='font encoding fast return'
	    return ''
	endif
    "{{{3 --------- brackets
" TODO: make this dependent on g:atp_bracket_dict
    elseif index(g:atp_completion_active_modes, 'brackets') != -1 && 
	\ (searchpairpos('\%(\\\@<!\\\)\@<!(', '', '\%(\\\@<!\\\)\@<!)\|\%(\\\cb\Cig\{1,2\}r\=\|\\right\)\.',    'bnW', "", l:limit_line) 	!= [0, 0] ||
	\ searchpairpos('\%(\\\@<!\\\)\@<!\[', '', '\%(\\\@<!\\\)\@<!\]\|\%(\\\cb\Cig\{1,2\}r\=\|\\right\)\.',   'bnW', "", l:limit_line) 	!= [0, 0] ||
	\ searchpairpos('{',  '', '}\|\%(\\\cb\Cig\{1,2\}r\=\|\\right\)\.',   'bnW', "", l:limit_line) 	!= [0, 0] )
		" \{ can be closed with \right\. 

	if (!normal_mode &&  index(g:atp_completion_active_modes, 'brackets') != -1 ) ||
		\ (l:normal_mode && index(g:atp_completion_active_modes_normal_mode, 'brackets') 		!= -1 )
	    let b:comp_method='brackets'
	    call atplib#CloseLastBracket()
	    return '' 
	else
	    let b:comp_method='brackets fast return'
	    return ''
	endif
    "{{{3 --------- close environments
    else
	if (!normal_mode &&  index(g:atp_completion_active_modes, 'close environments') != '-1' ) ||
		    \ (l:normal_mode && index(g:atp_completion_active_modes_normal_mode, 'close environments') != '-1' )
	    let l:completion_method='close_env'
	    " DEBUG:
	    let b:comp_method='close_env a' 
	else
	    let b:comp_method='close_env a fast return' 
	    return ''
	endif
    endif
" if the \[ is not closed, first close it and then complete the commands, it
" is better as then automatic tex will have better file to operate on.
" {{{2 close environments
    if l:completion_method=='close_env'

	" Close one line math
	if atplib#CheckOneLineMath('texMathZoneV') || 
		    \ atplib#CheckOneLineMath('texMathZoneW') ||
		    \ atplib#CheckOneLineMath('texMathZoneX') ||
		    \ b:atp_TexFlavor == 'plaintex' && atplib#CheckOneLineMath('texMathZoneY')
	    let b:tc_return = "close_env math"
	    call atplib#CloseLastEnvironment(l:append, 'math')
	" Close environments
	else
	    let b:tc_return = "close_env environment"
	    let stopline_forward	= line(".") + g:atp_completion_limits[2]
	    let stopline_backward	= max([ 1, line(".") - g:atp_completion_limits[2]])

	    let line_nr=line(".")
	    while line_nr >= stopline_backward
		let line_nr 		= searchpair('\\begin\s*{', '', '\\end\s*{', 'bnW', 'strpart(getline("."), 0, col(".")-1) =~ "\\\\\\@<!%"', stopline_backward)
		if line_nr >= stopline_backward
		    let env_name	= matchstr(getline(line_nr), '\\begin\s*{\zs[^}]*}\ze}')
		    if env_name		=~# '^\s*document\s*$' 
			break
		    endif
		    let line_forward 	= searchpair('\\begin\s*{'.env_name.'}', '', '\\end\s*{'.env_name.'}', 
							\ 'nW', '', stopline_forward)
		    if line_forward == 0
			break
		    endif
			
		else
		    let line_nr = 0
		endif
	    endwhile

	    if line_nr
	    " the env_name variable might have wrong value as it is
	    " looking using '\\begin' and '\\end' this might be not enough, 
		" however the function atplib#CloseLastEnv works perfectly and this
		" should be save:

		if env_name !~# '^\s*document\s*$'
		    call atplib#CloseLastEnvironment(l:append, 'environment', '', [line_nr, 0])
		    return ""
		else
		    return ""
		endif
	    endif
	endif
	return ""
    endif
" {{{2 SET COMPLETION LIST
    " generate the completion names
    " {{{3 ------------ ENVIRONMENT NAMES
    if l:completion_method == 'environment_names'
	let l:end=strpart(l:line,l:pos[2]-1)
	if l:end !~ '\s*}'
	    let l:completion_list=deepcopy(g:atp_Environments)
	    if g:atp_local_completion
		" Make a list of local envs and commands
		if !exists("s:atp_LocalEnvironments") 
		    let s:atp_LocalEnvironments=LocalCommands()[1]
		    endif
		let l:completion_list=atplib#Extend(l:completion_list,s:atp_LocalEnvironments)
	    endif
	    let l:completion_list=atplib#Add(l:completion_list,'}')
	else
	    let l:completion_list=deepcopy(g:atp_Environments)
	    if g:atp_local_completion
		" Make a list of local envs and commands
		if !exists("s:atp_LocalEnvironments") 
		    let s:atp_LocalEnvironments=LocalCommands()[1]
		    endif
		call atplib#Extend(l:completion_list,s:atp_LocalEnvironments)
	    endif
	endif
	" TIKZ
	keepjumps call setpos(".",[0,1,1,0])
	let l:stop_line=search('\\begin\s*{document}','cnW')
	keepjumps call setpos(".",l:pos_saved)
	if (atplib#SearchPackage('tikz', l:stop_line) || count(b:atp_PackageList, 'tikz.tex')  ) && 
	    \ ( atplib#CheckOpened('\\begin\s*{\s*tikzpicture\s*}', '\\end\s*{\s*tikzpicture\s*}', line('.'),g:atp_completion_limits[2]) || 
	    \ atplib#CheckOpened('\\tikz{','}',line("."),g:atp_completion_limits[2]) )
	    if l:end !~ '\s*}'
		call extend(l:completion_list,atplib#Add(g:atp_tikz_environments,'}'))
	    else
		call extend(l:completion_list,g:atp_tikz_environments)
	    endif
	endif
	" AMSMATH
	if atplib#SearchPackage('amsmath', l:stop_line) || g:atp_amsmath != 0 || atplib#DocumentClass() =~ '^ams'
	    if l:end !~ '\s*}'
		call extend(l:completion_list,atplib#Add(g:atp_amsmath_environments,'}'),0)
	    else
		call extend(l:completion_list,g:atp_amsmath_environments,0)
	    endif
	endif
    "{{{3 ------------ PACKAGES
    elseif l:completion_method == 'package'
	if exists("g:atp_texpackages")
	    let l:completion_list	= copy(g:atp_texpackages)
	else
	    let g:atp_texpackages	= atplib#KpsewhichGlobPath("tex", "", "*.sty")
	    lockvar g:atp_texpackages
	    let l:completion_list	= deepcopy(g:atp_texpackages)
	endif
    "{{{3 ------------ COLORS
    elseif l:completion_method == 'colors'
	" To Do: make a predefined lists of colors depending on package
	" options! 
	" Make a list of local envs and commands
	if !exists("s:atp_LocalColors") 
	    let s:atp_LocalColors=LocalCommands()[2]
	    endif
	let l:completion_list=s:atp_LocalColors
    " {{{3 ------------ TIKZ LIBRARIES
    elseif l:completion_method == 'tikz libraries'
	let l:completion_list=deepcopy(g:atp_tikz_libraries)
    " {{{3 ------------ TIKZ KEYWORDS
    elseif l:completion_method == 'tikzpicture keywords'

	keepjumps call setpos(".",[0,1,1,0])
	let l:stop_line=search('\\begin\s*{document}','cnW')
	keepjumps call setpos(".",l:pos_saved)

	let l:completion_list=deepcopy(g:atp_tikz_keywords)
	" TODO: add support for all tikz libraries 
	let tikz_libraries	= atplib#GetPackageList('\\usetikzlibrary\s*{')
	for lib in tikz_libraries  
	    if exists("g:atp_tikz_library_".lib."_keywords")
		call extend(l:completion_list,g:atp_tikz_library_{lib}_keywords)
	    endif   
	endfor
    " {{{3 ------------ TIKZ COMMANDS
    elseif l:completion_method	== 'tikzpicture commands'
	let l:completion_list = []
	" if tikz is declared and we are in tikz environment.
	let tikz_libraries	= atplib#GetPackageList('\\usetikzlibrary\s*{')
	for lib in tikz_libraries  
	    if exists("g:atp_tikz_library_".lib."_commands")
		call extend(l:completion_list,g:atp_tikz_library_{lib}_keywords)
	    endif   
	endfor
	if searchpair('\\\@<!{', '', '\\\@<!}', 'bnW', "", max([ 1, (line(".")-g:atp_completion_limits[0])]))
	    call extend(l:completion_list, g:atp_Commands)
	endif
    " {{{3 ------------ COMMANDS
    elseif l:completion_method == 'command'
	"{{{4 
	let l:tbegin=strpart(l:l,l:o+1)
	let l:completion_list=[]
	
	" Find end of the preambule.
	if expand("%:p") == b:atp_MainFile
	    " if the file is the main file
	    let saved_pos=getpos(".")
	    keepjumps call setpos(".", [0,1,1,0])
	    keepjumps let stop_line=search('\\begin\s*{document}','nW')
	    keepjumps call setpos(".", saved_pos)
	else
	    " if the file doesn't contain the preambule
	    if &l:filetype == 'tex'
		let saved_loclist	= getloclist(0)
		silent! execute '1lvimgrep /\\begin\s*{\s*document\s*}/j ' . fnameescape(b:atp_MainFile)
		let stop_line	= get(get(getloclist(0), 0, {}), 'lnum', 0)
		call setloclist(0, saved_loclist) 
	    else
		let stop_line = 0
	    endif
	endif
	 
	" Are we in the math mode?
	let l:math_is_opened	= atplib#CheckSyntaxGroups(g:atp_MathZones)

   	"{{{4 -------------------- picture
	if searchpair('\\begin\s*{picture}','','\\end\s*{picture}','bnW',"", max([ 1, (line(".")-g:atp_completion_limits[2])]))
	    call extend(l:completion_list,g:atp_picture_commands)
	endif 
	" {{{4 -------------------- MATH commands 
	" if we are in math mode or if we do not check for it.
	if g:atp_no_math_command_completion != 1 &&  ( !g:atp_MathOpened || l:math_is_opened )
	    call extend(l:completion_list,g:atp_math_commands)
	    " amsmath && amssymb {{{5
	    " if g:atp_amsmath is set or the document class is ams...
	    if (g:atp_amsmath != 0 || atplib#DocumentClass() =~ '^ams')
		call extend(l:completion_list, g:atp_amsmath_commands,0)
		call extend(l:completion_list, g:atp_ams_negations)
		call extend(l:completion_list, g:atp_amsfonts)
		call extend(l:completion_list, g:atp_amsextra_commands)
		if a:expert_mode == 0 
		    call extend(l:completion_list, g:atp_ams_negations_non_expert_mode)
		endif
	    " else check if the packages are declared:
	    else
		if atplib#SearchPackage('amsmath', l:stop_line)
		    call extend(l:completion_list, g:atp_amsmath_commands,0)
		endif
		if atplib#SearchPackage('amssymb', l:stop_line)
		    call extend(l:completion_list, g:atp_ams_negations)
		    if a:expert_mode == 0 
			call extend(l:completion_list, g:atp_ams_negations_non_expert_mode)
		    endif
		endif
	    endif
	    " nicefrac {{{5
	    if atplib#SearchPackage('nicefrac',l:stop_line)
		call add(l:completion_list,"\\nicefrac{")
	    endif
	    " math non expert mode {{{5
	    if a:expert_mode == 0
		call extend(l:completion_list,g:atp_math_commands_non_expert_mode)
	    endif
	endif
	" -------------------- LOCAL commands {{{4
	if g:atp_local_completion

	    " make a list of local envs and commands:
	    if !exists("s:atp_LocalCommands") 
		if exists("b:atp_LocalCommands")
		    let s:atp_LocalCommands=b:atp_LocalCommands
		elseif exists("g:atp_local_commands")
		    let s:atp_LocalCommands=g:atp_local_commands
		else
		    let s:atp_LocalCommands=LocalCommands()[1]
		endif
	    endif
	    call extend(l:completion_list,s:atp_LocalCommands)
	endif
	" {{{4 -------------------- TIKZ commands
	" if tikz is declared and we are in tikz environment.
	let in_tikz=searchpair('\\begin\s*{tikzpicture}','','\\end\s*{tikzpicture}','bnW',"", max([1,(line(".")-g:atp_completion_limits[2])])) || atplib#CheckOpened('\\tikz{','}',line("."),g:atp_completion_limits[0])

	if in_tikz
	    " find all tikz libraries at once:
	    let tikz_libraries	= atplib#GetPackageList('\\usetikzlibrary\s*{')

	    " add every set of library commands:
	    for lib in tikz_libraries  
		if exists("g:atp_tikz_library_".lib."_commands")
		    call extend(l:completion_list, g:atp_tikz_library_{lib}_commands)
		endif   
	    endfor

	    " add common tikz commands:
	    call extend(l:completion_list, g:atp_tikz_commands)

	    " if in text mode add normal commands:
	    if searchpair('\\\@<!{', '', '\\\@<!}', 'bnW', "", max([ 1, (line(".")-g:atp_completion_limits[0])]))
		call extend(l:completion_list, g:atp_Commands)
	    endif
	endif 
	" {{{4 -------------------- COMMANDS
"	if we are not in math mode or if we do not care about it or we are in non expert mode.
	if (!g:atp_MathOpened || !l:math_is_opened ) || a:expert_mode == 0
	    call extend(l:completion_list,g:atp_Commands)
	    " FANCYHDR
	    if atplib#SearchPackage('fancyhdr', l:stop_line)
		call extend(l:completion_list, g:atp_fancyhdr_commands)
	    endif
	    if atplib#SearchPackage('makeidx', l:stop_line)
		call extend(l:completion_list, g:atp_makeidx_commands)
	    endif
	endif
	"}}}4
	" ToDo: add layout commands and many more packages. (COMMANDS FOR
	" PREAMBULE)
	"{{{4 -------------------- final stuff
	let l:env_name=substitute(l:pline,'.*\%(\\\%(begin\|end.*\){\(.\{-}\)}.*\|\\\%(\(item\)\s*\)\%(\[.*\]\)\?\s*$\)','\1\2','') 
	if l:env_name =~ '\\\%(\%(sub\)\?paragraph\|\%(sub\)*section\|chapter\|part\)'
	    let l:env_name=substitute(l:env_name,'.*\\\(\%(sub\)\?paragraph\|\%(sub\)*section\|chapter\|part\).*','\1','')
	endif
	let l:env_name=substitute(l:env_name,'\*$','','')
	" if the pattern did not work do not put the env name.
	" for example \item cos\lab<Tab> the pattern will not work and we do
	" not want env name. 
	if l:env_name == l:pline
	    let l:env_name=''
	endif

	if has_key(g:atp_shortname_dict,l:env_name)
	    if g:atp_shortname_dict[l:env_name] != 'no_short_name' && g:atp_shortname_dict[l:env_name] != '' 
		let l:short_env_name=g:atp_shortname_dict[l:env_name]
		let l:no_separator=0
	    else
		let l:short_env_name=''
		let l:no_separator=1
	    endif
	else
	    let l:short_env_name=''
	    let l:no_separator=1
	endif

" 	if index(g:atp_no_separator_list, l:env_name) != -1
" 	    let l:no_separator = 1
" 	endif

	if g:atp_env_short_names == 1
	    if l:no_separator == 0 && g:atp_no_separator == 0
		let l:short_env_name=l:short_env_name . g:atp_separator
	    endif
	else
	    let l:short_env_name=''
	endif

	call extend(l:completion_list, [ '\label{' . l:short_env_name ],0)
    " {{{3 ------------ LABELS /are done later only the l:completions variable /
    elseif l:completion_method ==  'labels'
	let l:completion_list = []
    " {{{3 ------------ TEX INPUTFILES
    elseif l:completion_method ==  'inputfiles'
	let l:completion_list=[]
	call  extend(l:completion_list, atplib#KpsewhichGlobPath('tex', b:atp_OutDir . ',' . g:atp_texinputs, '*.tex', ':t:r', '^\%(\/home\|\.\|.*users\)', '\%(^\\usr\|texlive\|miktex\|kpsewhich\|generic\)'))
	call sort(l:completion_list)
    " {{{3 ------------ BIBFILES
    elseif l:completion_method ==  'bibfiles'
	let  l:completion_list=[]
	call extend(l:completion_list, atplib#KpsewhichGlobPath('bib', b:atp_OutDir . ',' . g:atp_bibinputs, '*.bib', ':t:r', '^\%(\/home\|\.\|.*users\)', '\%(^\\usr\|texlive\|miktex\|kpsewhich\|generic\|miktex\)'))
	call sort(l:completion_list)
    " {{{3 ------------ BIBSTYLES
    elseif l:completion_method == 'bibstyles'
	let l:completion_list=atplib#KpsewhichGlobPath("bst", "", "*.bst")
    "{{{3 ------------ DOCUMENTCLASS
    elseif l:completion_method == 'documentclass'
	if exists("g:atp_texclasses")
	    let l:completion_list	= copy(g:atp_texclasses)
	else
	    let g:atp_texclasses	= atplib#KpsewhichGlobPath("tex", "", "*.cls")
	    lockvar g:atp_texclasses
	    let l:completion_list	= deepcopy(g:atp_texclasses)
	endif
	" \documentclass must be closed right after the name ends:
	if l:nchar != "}"
	    call map(l:completion_list,'v:val."}"')
	endif
    "{{{3 ------------ FONT FAMILY
    elseif l:completion_method == 'font family'
	let l:bpos=searchpos('\\selectfon\zst','bnW',line("."))[1]
	let l:epos=searchpos('\\selectfont','nW',line("."))[1]-1
	if l:epos == -1
	    let l:epos=len(l:line)
	endif
	let l:fline=strpart(l:line,l:bpos,l:epos-l:bpos)
	let l:encoding=matchstr(l:fline,'\\\%(usefont\|DeclareFixedFont\s*{[^}]*}\|fontencoding\)\s*{\zs[^}]*\ze}')
	if l:encoding == ""
	    let l:encoding=g:atp_font_encoding
	endif
" 	let b:encoding=l:encoding
	let l:completion_list=[]
	let l:fd_list=atplib#FdSearch('^'.l:encoding.l:begin)
" 	let b:fd_list=l:fd_list
	for l:file in l:fd_list
	    call extend(l:completion_list,map(atplib#ShowFonts(l:file),'matchstr(v:val,"usefont\\s*{[^}]*}\\s*{\\zs[^}]*\\ze}")'))
	endfor
	call filter(l:completion_list,'count(l:completion_list,v:val) == 1 ')
    "{{{3 ------------ FONT SERIES
    elseif l:completion_method == 'font series'
	let l:bpos=searchpos('\\selectfon\zst','bnW',line("."))[1]
	let l:epos=searchpos('\\selectfont','nW',line("."))[1]-1
	if l:epos == -1
	    let l:epos=len(l:line)
	endif
	let l:fline=strpart(l:line,l:bpos,l:epos-l:bpos)
" 	let b:fline=l:fline
	let l:encoding=matchstr(l:fline,'\\\%(usefont\|DeclareFixedFont\s*{[^}]*}\|fontencoding\)\s*{\zs[^}]*\ze}')
	if l:encoding == ""
	    let l:encoding=g:atp_font_encoding
	endif
	let l:font_family=matchstr(l:fline,'\\\%(usefont\s*{[^}]*}\|DeclareFixedFont\s*{[^}]*}\s*{[^}]*}\|fontfamily\)\s*{\zs[^}]*\ze}')
" 	let b:font_family=l:font_family
	let l:completion_list=[]
	let l:fd_list=atplib#FdSearch('^'.l:encoding.l:font_family)
	for l:file in l:fd_list
	    call extend(l:completion_list,map(atplib#ShowFonts(l:file),'matchstr(v:val,"usefont{[^}]*}{[^}]*}{\\zs[^}]*\\ze}")'))
	endfor
	call filter(l:completion_list,'count(l:completion_list,v:val) == 1 ')
    "{{{3 ------------ FONT SHAPE
    elseif l:completion_method == 'font shape'
	let l:bpos=searchpos('\\selectfon\zst','bnW',line("."))[1]
	let l:epos=searchpos('\\selectfont','nW',line("."))[1]-1
	if l:epos == -1
	    let l:epos=len(l:line)
	endif
	let l:fline=strpart(l:line,l:bpos,l:epos-l:bpos)
	let l:encoding=matchstr(l:fline,'\\\%(usefont\|DeclareFixedFont\s*{[^}]*}\|fontencoding\)\s*{\zs[^}]*\ze}')
	if l:encoding == ""
	    let l:encoding=g:atp_font_encoding
	endif
	let l:font_family=matchstr(l:fline,'\\\%(usefont{[^}]*}\|DeclareFixedFont\s*{[^}]*}\s*{[^}]*}\|fontfamily\)\s*{\zs[^}]*\ze}')
	let l:font_series=matchstr(l:fline,'\\\%(usefont\s*{[^}]*}\s*{[^}]*}\|DeclareFixedFont\s*{[^}]*}\s*{[^}]*}\s*{[^}]*}\|fontseries\)\s*{\zs[^}]*\ze}')
	let l:completion_list=[]
	let l:fd_list=atplib#FdSearch('^'.l:encoding.l:font_family)

	for l:file in l:fd_list
	    call extend(l:completion_list,map(atplib#ShowFonts(l:file),'matchstr(v:val,"usefont{[^}]*}{'.l:font_family.'}{'.l:font_series.'}{\\zs[^}]*\\ze}")'))
	endfor
	call filter(l:completion_list,'count(l:completion_list,v:val) == 1 ')
    " {{{3 ------------ FONT ENCODING
    elseif l:completion_method == 'font encoding'
	let l:bpos=searchpos('\\selectfon\zst','bnW',line("."))[1]
	let l:epos=searchpos('\\selectfont','nW',line("."))[1]-1
	if l:epos == -1
	    let l:epos=len(l:line)
	endif
	let l:fline=strpart(l:line,l:bpos,l:epos-l:bpos)
	let l:font_family=matchstr(l:fline,'\\\%(usefont\s*{[^}]*}\|DeclareFixedFont\s*{[^}]*}\s*{[^}]*}\|fontfamily\)\s*{\zs[^}]*\ze}')
	if l:font_family != ""
	    let l:fd_list=atplib#FdSearch(l:font_family)
	    let l:completion_list=map(copy(l:fd_list),'toupper(substitute(fnamemodify(v:val,":t"),"'.l:font_family.'.*$","",""))')
	else
" 	    let l:completion_list=[]
" 	    for l:fd_file in l:fd_list
" 		let l:enc=substitute(fnamemodify(l:fd_file,":t"),"\\d\\zs.*$","","")
" 		if l:enc != fnamemodify(l:fd_file,":t")
" 		    call add(l:completion_list,toupper(l:enc))
" 		endif
" 	    endfor
	    let l:completion_list=g:atp_completion_font_encodings
	endif
    " {{{3 ------------ BIBITEMS
    elseif l:completion_method == 'bibitems'
	let l:col = col('.') - 1
	while l:col > 0 && line[l:col - 1] !~ '{\|,'
		let l:col -= 1
	endwhile
	let l:pat=strpart(l:l,l:col)
	let l:bibitems_list=values(atplib#searchbib(l:pat))
	let l:pre_completion_list=[]
	let l:completion_dict=[]
	let l:completion_list=[]
	for l:dict in l:bibitems_list
	    for l:key in keys(l:dict)
		" ToDo: change l:dict[l:key][...] to get() to not get errors
		" if it is not present or to handle situations when it is not
		" present!
		call add(l:pre_completion_list, l:dict[l:key]['bibfield_key']) 
		let l:bibkey=l:dict[l:key]['bibfield_key']
		let l:bibkey=substitute(strpart(l:bibkey,max([stridx(l:bibkey,'{'),stridx(l:bibkey,'(')])+1),',\s*','','')
		if l:nchar != ',' && l:nchar != '}'
		    let l:bibkey.="}"
		endif
		let l:title=get(l:dict[l:key],'title','notitle')
		let l:title=substitute(matchstr(l:title,'^\s*title\s*=\s*\%("\|{\|(\)\zs.*\ze\%("\|}\|)\)\s*\%(,\|$\)'),'{\|}','','g')
		let l:year=get(l:dict[l:key],'year',"")
		let l:year=matchstr(l:year,'^\s*year\s*=\s*\%("\|{\|(\)\zs.*\ze\%("\|}\|)\)\s*\%(,\|$\)')
		let l:abbr=get(l:dict[l:key],'author',"noauthor")
		let l:author = matchstr(l:abbr,'^\s*author\s*=\s*\%("\|{\|(\)\zs.*\ze\%("\|}\|)\)\s*,')
		if l:abbr=="noauthor" || l:abbr == ""
		    let l:abbr=get(l:dict[l:key],'editor',"")
		    let l:author = matchstr(l:abbr,'^\s*editor\s*=\s*\%("\|{\|(\)\zs.*\ze\%("\|}\|)\)\s*,')
		endif
		if len(l:author) >= 40
		    if match(l:author,'\sand\s')
			let l:author=strpart(l:author,0,match(l:author,'\sand\s')) . ' et al.'
		    else
			let l:author=strpart(l:author,0,40)
		    endif
		endif
		let l:author=substitute(l:author,'{\|}','','g')
		if l:dict[l:key]['bibfield_key'] =~ 'article'
		    let l:type="[a]"
		elseif l:dict[l:key]['bibfield_key'] =~ 'book\>'
		    let l:type="[B]"
		elseif l:dict[l:key]['bibfield_key'] =~ 'booklet'
		    let l:type="[b]"
		elseif  l:dict[l:key]['bibfield_key'] =~ 'proceedings\|conference'
		    let l:type="[p]"
		elseif l:dict[l:key]['bibfield_key'] =~ 'unpublished'
		    let l:type="[u]"
		elseif l:dict[l:key]['bibfield_key'] =~ 'incollection'
		    let l:type="[c]"
		elseif l:dict[l:key]['bibfield_key'] =~ 'phdthesis'
		    let l:type="[PhD]"
		elseif l:dict[l:key]['bibfield_key'] =~ 'masterthesis'
		    let l:type="[M]"
		elseif l:dict[l:key]['bibfield_key'] =~ 'misc'
		    let l:type="[-]"
		elseif l:dict[l:key]['bibfield_key'] =~ 'techreport'
		    let l:type="[t]"
		elseif l:dict[l:key]['bibfield_key'] =~ 'manual'
		    let l:type="[m]"
		else
		    let l:type="   "
		endif

		let l:abbr=l:type." ".l:author." (".l:year.") "

		call add(l:completion_dict, { "word" : l:bibkey, "menu" : l:title, "abbr" : l:abbr }) 
	    endfor
	endfor
	for l:key in l:pre_completion_list
	    call add(l:completion_list,substitute(strpart(l:key,max([stridx(l:key,'{'),stridx(l:key,'(')])+1),',\s*','',''))
	endfor

	" add the \bibitems found in include files
	call extend(l:completion_list,keys(atplib#SearchBibItems(b:atp_MainFile)))
    elseif l:completion_method == 'colors'
	" ToDo:
	let l:completion_list=[]
    endif
    " }}}3
    if exists("l:completion_list")
	let b:completion_list=l:completion_list	" DEBUG
    endif
" {{{2 make the list of matching completions
    "{{{3 --------- l:completion_method = !close environments !env_close
    if l:completion_method != 'close environments' && l:completion_method != 'env_close'
	let l:completions=[]
	    " {{{4 --------- Packages, environments, labels, bib and input files 
	    " must match at the beginning (in expert_mode).
	    if (l:completion_method == 'package' 		||
			\ l:completion_method == 'environment_names' ||
			\ l:completion_method == 'colors' 	||
			\ l:completion_method == 'bibfiles' 	||
			\ l:completion_method == 'bibstyles' 	||
			\ l:completion_method == 'font family' 	||
			\ l:completion_method == 'font series' 	||
			\ l:completion_method == 'font shape'	||
			\ l:completion_method == 'font encoding'||
			\ l:completion_method == 'documentclass' )
		if a:expert_mode == 1 
		    let l:completions	= filter(deepcopy(l:completion_list),' v:val =~ "\\C^".l:begin') 
		elseif a:expert_mode !=1
		    let l:completions	= filter(deepcopy(l:completion_list),' v:val =~ l:begin') 
		endif
	    " {{{4 --------- tikz libraries, inputfiles 
	    " match not only in the beginning
	    elseif (l:completion_method == 'tikz libraries' ||
			\ l:completion_method == 'inputfiles')
		let l:completions	= filter(deepcopy(l:completion_list),' v:val =~ l:begin') 
		if l:nchar != "}" && l:nchar != "," && l:completion_method != 'inputfiles'
		    call map(l:completions,'v:val')
		endif
	    " {{{4 --------- Commands 
	    " must match at the beginning (but in a different way)
	    " (only in expert_mode).
	    elseif l:completion_method == 'command' 
			if a:expert_mode == 1 
			    let l:completions	= filter(copy(l:completion_list),'v:val =~ "\\C^\\\\".l:tbegin')
			elseif a:expert_mode != 1 
			    let l:completions	= filter(copy(l:completion_list),'v:val =~ l:tbegin')
			endif
	    " {{{4 --------- Tikzpicture Keywords
	    elseif l:completion_method == 'tikzpicture keywords'
		if a:expert_mode == 1 
		    let l:completions	= filter(deepcopy(l:completion_list),'v:val =~ "\\C^".l:tbegin') 
		elseif a:expert_mode != 1 
		    let l:completions	= filter(deepcopy(l:completion_list),'v:val =~ l:tbegin') 
		endif
	    " {{{4 --------- Tikzpicture Commands
	    elseif l:completion_method == 'tikzpicture commands'
		if a:expert_mode == 1 
		    let l:completions	= filter(deepcopy(l:completion_list),'v:val =~ "\\C^".l:tbegin') 
		elseif a:expert_mode != 1 
		    let l:completions	= filter(deepcopy(l:completion_list),'v:val =~ l:tbegin') 
		endif
	    " {{{4 --------- Labels
	    elseif l:completion_method == 'labels'
		" Complete label by string or number:
		let aux_data		= atplib#GrepAuxFile()
		let l:completions 	= []
		for data in aux_data
		    " match label by string or number
		    if data[0] =~ l:begin || data[1] =~ '^'. l:begin 
			let close = l:nchar == '}' ? '' : '}'
			call add(l:completions, data[0] . close)
		    endif
		endfor
	    endif
    "{{{3 --------- else: try to close environment
    else
	call atplib#CloseLastEnvironment('a', 'environment')
	let b:tc_return="1"
	return ''
    endif
    "{{{3 --------- SORTING and TRUNCATION
    " ToDo: we will not truncate if completion method is specific, this should be
    " made by a variable! Maybe better is to provide a positive list !!!
    if g:atp_completion_truncate && a:expert_mode && 
		\ index(['bibfiles', 'bibitems', 'bibstyles', 'labels', 
		\ 'font family', 'font series', 'font shape', 'font encoding' ],l:completion_method) == -1
	call filter(l:completions,'len(substitute(v:val,"^\\","","")) >= g:atp_completion_truncate')
    endif
"     THINK: about this ...
"     if l:completion_method == "tikzpicture keywords"
" 	let bracket	= atplib#CloseLastBracket(1)
" 	if bracket != ""
" 	    call add(l:completions, bracket)
" 	endif
"     endif
    " if the list is long it is better if it is sorted, if it short it is
    " better if the more used things are at the beginning.
    if g:atp_sort_completion_list && len(l:completions) >= g:atp_sort_completion_list && l:completion_method != 'labels'
	let l:completions=sort(l:completions)
    endif
    " DEBUG
    let b:completions=l:completions 
    " {{{2 COMPLETE 
    " {{{3 labels, package, tikz libraries, environment_names, colors, bibfiles, bibstyles, documentclass, font family, font series, font shape font encoding and input files 
    if l:completion_method == 'labels' 			|| 
		\ l:completion_method == 'package' 	|| 
		\ l:completion_method == 'tikz libraries'    || 
		\ l:completion_method == 'environment_names' ||
		\ l:completion_method == 'colors'	||
		\ l:completion_method == 'bibfiles' 	|| 
		\ l:completion_method == 'bibstyles' 	|| 
		\ l:completion_method == 'documentclass'|| 
		\ l:completion_method == 'font family'  ||
		\ l:completion_method == 'font series'  ||
		\ l:completion_method == 'font shape'   ||
		\ l:completion_method == 'font encoding'||
		\ l:completion_method == 'inputfiles' 
	call complete(l:nr+2,l:completions)
	let b:tc_return="labels,package,tikz libraries,environment_names,bibitems,bibfiles,inputfiles"
    " {{{3 bibitems
    elseif !l:normal_mode && l:completion_method == 'bibitems'
	call complete(l:col+1,l:completion_dict)
    " {{{3 command, tikzcpicture commands
    elseif !l:normal_mode && (l:completion_method == 'command' || l:completion_method == 'tikzpicture commands')
	call complete(l:o+1,l:completions)
	let b:tc_return="command X"
    " {{{3 tikzpicture keywords
    elseif !l:normal_mode && (l:completion_method == 'tikzpicture keywords')
	let l:t=match(l:l,'\zs\<\w*$')
	" in case '\zs\<\w*$ is empty
	if l:t == -1
	    let l:t=col(".")
	endif
	call complete(l:t+1,l:completions)
	let b:tc_return="tikzpicture keywords"
    endif
    " If the completion method was a command (probably in a math mode) and
    " there was no completion, check if environments are closed.
    " {{{ 3 Final call of CloseLastEnvrionment / CloseLastBracket
    let l:len=len(l:completions)
    if l:len == 0 && (!count(['package', 'bibfiles', 'bibstyles', 'inputfiles'], l:completion_method) || a:expert_mode == 1 )|| l:len == 1
	if (l:completion_method == 'command' || l:completion_method == 'tikzpicture commands') && 
	    \ (l:len == 0 || l:len == 1 && l:completions[0] == '\'. l:begin )

	    let filter 		= 'strpart(getline("."), 0, col(".") - 1) =~ ''\\\@<!%'''
	    let stopline 	= search('^\s*$\|\\par\>', 'bnW')

	    " Check Brackets 
	    let cl_return 	= atplib#CloseLastBracket()
	    let g:return	= cl_return
	    " If the bracket was closed return
	    if cl_return != "0"
		return ""
	    endif

	    " Check inline math:
	    if atplib#CheckOneLineMath('texMathZoneV') || 
			\ atplib#CheckOneLineMath('texMathZoneW') ||
			\ atplib#CheckOneLineMath('texMathZoneX') ||
			\ b:atp_TexFlavor == 'plaintex' && atplib#CheckOneLineMath('texMathZoneY')
		let zone = 'texMathZoneVWXY' 	" DEBUG
		call atplib#CloseLastEnvironment(l:append, 'math')

	    " Check environments:
	    else
		let l:env_opened= searchpairpos('\\begin','','\\end','bnW','searchpair("\\\\begin{".matchstr(getline("."),"\\\\begin{\\zs[^}]*\\ze}"),"","\\\\end{".matchstr(getline("."),"\\\\begin{\\zs[^}]*\\ze}"),"nW")',max([1,(line(".")-g:atp_completion_limits[2])]))
		let l:env_name 	= matchstr(strpart(getline(l:env_opened[0]), l:env_opened[1]-1), '\\begin\s*{\zs[^}]*\ze}')
		let zone	= l:env_name 	" DEBUG
		if l:env_opened != [0, 0]
		    call atplib#CloseLastEnvironment('a', 'environment', l:env_name, l:env_opened)
		endif
	    endif
	    " DEBUG
	    if exists("zone")
		let b:tc_return.=" close_env end " . zone
		let b:comp_method.=' close_env end ' . zone
	    else
		let b:tc_return.=" close_env end"
		let b:comp_method.=' close_env end'
	    endif
	elseif l:completion_method == 'package' || 
		    \  l:completion_method == 'bibstyles' || 
		    \ l:completion_method == 'bibfiles'
	    let b:tc_return='close_bracket end'
	    call atplib#CloseLastBracket()
	endif
    endif
    "}}}3
""}}}2
"  ToDo: (a challenging one)  
"  Move one step after completion is done (see the condition).
"  for this one have to end till complete() function will end, and this can be
"  done using (g)vim server functions.
"     let b:check=0
"     if l:completion_method == 'environment_names' && l:end =~ '\s*}'
" 	let b:check=1
" 	let l:pos=getpos(".")
" 	let l:pos[2]+=1
" 	call setpos(".",l:pos) 
"     endif
"
    " unlet variables if there were defined.
    if exists("l:completion_list")
	unlet l:completion_list
    endif
    if exists("l:completions")
	unlet l:completions
    endif
    return ''
    "}}}2
endfunction
catch /E127: Cannot redefine function atplib#TabCompletion: It is in use/
endtry
" }}}1

" Font Preview Functions:
"{{{1 Font Preview Functions
" These functions search for fd files and show them in a buffer with filetype
" 'fd_atp'. There are additional function for this filetype written in
" fd_atp.vim ftplugin. Distributed with atp.
"{{{2 atplib#FdSearch
"([<pattern>,<method>])
function! atplib#FdSearch(...)

    if a:0 == 0
	let pattern	= ""
	let method	= 0
    else
	let pattern	= ( a:0 >= 1 ? a:1 : "" )
	let method	= ( a:0 >= 2 && a:2 != 1 ? 0 : 1 )
    endif

    " Find fd file
    let path	= substitute(substitute(system("kpsewhich -show-path tex"),'!!','','g'),'\/\/\+','\/','g')
    let path	= substitute(path,':\|\n',',','g')
    let fd 	= split(globpath(path,"**/*.fd"),'\n') 

    " Match for l:pattern
    let fd_matches=[]
    if method == 0
	call filter(fd, 'fnamemodify(v:val, ":t") =~ pattern') 
    else
	call filter(fd, 'v:val =~ pattern') 
    endif

    return fd
endfunction
"{{{2 atplib#FontSearch
" atplib#FontSearch(method,[<pattern>]) 
" method = "" match for name of fd file
" method = "!" match against whole path
if !exists("*atplib#FontSearch")
function! atplib#FontSearch(method,...)
	
    let l:method	= ( a:method == "!" ? 1 : 0 )
    let l:pattern	= ( a:0 ? a:1 : "" )

    let s:fd_matches=atplib#FdSearch(l:pattern, l:method)

    " Open Buffer and list fd files
    " set filetype to fd_atp
    let l:tmp_dir=tempname()
    call mkdir(l:tmp_dir)
    let l:fd_bufname="fd_list " . l:pattern
    let l:openbuffer="32vsplit! +setl\\ nospell\\ ft=fd_atp ". fnameescape(l:tmp_dir . "/" . l:fd_bufname )

    let g:fd_matches=[]
    if len(s:fd_matches) > 0
	echohl WarningMsg
	echomsg "Found " . len(s:fd_matches) . " files."
	echohl None
	" wipe out the old buffer and open new one instead
	if buflisted(fnameescape(l:tmp_dir . "/" . l:fd_bufname))
	    silent exe "bd! " . bufnr(fnameescape(l:tmp_dir . "/" . l:fd_bufname))
	endif
	silent exe l:openbuffer
	" make l:tmp_dir available for this buffer.
" 	let b:tmp_dir=l:tmp_dir
	cd /tmp
	map <buffer> q	:bd<CR>

	" print the lines into the buffer
	let l:i=0
	call setline(1,"FONT DEFINITION FILES:")
	for l:fd_file in s:fd_matches
	    " we put in line the last directory/fd_filename:
	    " this is what we cut:
	    let l:path=fnamemodify(l:fd_file,":h:h")
	    let l:fd_name=substitute(l:fd_file,"^" . l:path . '/\?','','')
" 	    call setline(line('$')+1,fnamemodify(l:fd_file,":t"))
	    call setline(line('$')+1,l:fd_name)
	    call add(g:fd_matches,l:fd_file)
	    let l:i+=1
	endfor
	call append('$', ['', 'maps:', 
			\ 'p       Preview font ', 
			\ 'P       Preview font+tex file', 
			\ '<Tab>   Show Fonts in fd file', 
			\ '<Enter> Open fd file', 
			\ 'q       "bd!"',
			\ '',
			\ 'Note: p/P works in visual mode'])
	silent w
	setlocal nomodifiable
	setlocal ro
    else
	echohl WarningMsg
	if !l:method
	    echomsg "No fd file found, try :FontSearch!"
	else
	    echomsg "No fd file found."
	endif
	echohl None
    endif

endfunction
endif
"}}}2
"{{{2 atplib#Fd_completion /not needed/
" if !exists("*atplib#Fd_completion")
" function! atplib#Fd_completion(A,C,P)
"     	
"     " Find all files
"     let l:path=substitute(substitute(system("kpsewhich -show-path tex"),'!!','','g'),'\/\/\+','\/','g')
"     let l:path=substitute(l:path,':\|\n',',','g')
"     let l:fd=split(globpath(l:path,"**/*.fd"),'\n') 
"     let l:fd=map(l:fd,'fnamemodify(v:val,":t:r")')
" 
"     let l:matches=[]
"     for l:fd_file in l:fd
" 	if l:fd_file =~ a:A
" 	    call add(l:matches,l:fd_file)
" 	endif
"     endfor
"     return l:matches
" endfunction
" endif
" }}}2
" {{{2 atplib#OpenFdFile /not working && not needed?/
" function! atplib#OpenFdFile(name)
"     let l:path=substitute(substitute(system("kpsewhich -show-path tex"),'!!','','g'),'\/\/\+','\/','g')
"     let l:path=substitute(l:path,':\|\n',',','g')
"     let b:path=l:path
"     let l:fd=split(globpath(l:path,"**/".a:name.".fd"),'\n') 
"     let l:fd=map(l:fd,'fnamemodify(v:val,":t:r")')
"     let b:fd=l:fd
"     execute "split +setl\\ ft=fd_atp " . l:fd[0]
" endfunction
" }}}2
"{{{2 atplib#Preview
" keep_tex=1 open the tex file of the sample file, otherwise it is deleted (at
" least from the buffer list).
" To Do: fd_file could be a list of fd_files which we would like to see, every
" font should be done after \pagebreak[4]
" if a:fd_files=['buffer'] it means read the current buffer (if one has opened
" an fd file).
function! atplib#Preview(fd_files,keep_tex)
    if a:fd_files != ["buffer"]
	let l:fd_files={}
	for l:fd_file in a:fd_files
	    call extend(l:fd_files,{fd_file : readfile(l:fd_file)})
	endfor
    else
	let l:fd_files={bufname("%"):getline(1,"$")}
    endif
    unlet l:fd_file

    let l:declare_command='\C\%(DeclareFontShape\%(WithSizes\)\?\|sauter@\%(tt\)\?family\|EC@\%(tt\)\?family\|krntstexmplfamily\|HFO@\%(tt\)\?family\)'
    let b:declare_command=l:declare_command
    
    let l:font_decl_dict={}
    for l:fd_file in a:fd_files
	call extend(l:font_decl_dict, {l:fd_file : [ ]})
	for l:line in l:fd_files[l:fd_file]
	    if l:line =~ '\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'
		call add(l:font_decl_dict[l:fd_file],l:line)
	    endif
	endfor
    endfor

"     let l:tmp_dir=tempname()
    if exists("b:tmp_dir")
	let l:tmp_dir=b:tmp_dir
    else
	let l:tmp_dir=tempname()
    endif
    if !isdirectory(l:tmp_dir)
	call mkdir(l:tmp_dir)
    endif
    if a:fd_files == ["buffer"]
	let l:testfont_file=l:tmp_dir . "/" . fnamemodify(bufname("%"),":t:r") . ".tex"
    else
	" the name could be taken from the pattern
	" or join(map(keys(deepcopy(a:fd_files)),'substitute(fnamemodify(v:val,":t:r"),".fd$","","")'),'_')
	" though it can be quite a long name.
	let l:testfont_file=l:tmp_dir . "/" . fnamemodify(a:fd_files[0],":t:r") . ".tex"
    endif
    call system("touch " . l:testfont_file)
    
    let l:fd_bufnr=bufnr("%")

    let s:text="On November 14, 1885, Senator \\& Mrs.~Leland Stanford called
		\ together at their San Francisco mansion the 24~prominent men who had
		\ been chosen as the first trustees of The Leland Stanford Junior University.
		\ They handed to the board the Founding Grant of the University, which they
		\ had executed three days before.\\\\
		\ (!`THE DAZED BROWN FOX QUICKLY GAVE 12345--67890 JUMPS!)"

"     let l:text="On November 14, 1885, Senator \\& Mrs.~Leland Stanford called
" 	\ together at their San Francisco mansion the 24~prominent men who had
" 	\ been chosen as the first trustees of The Leland Stanford Junior University.
" 	\ They handed to the board the Founding Grant of the University, which they
" 	\ had executed three days before. This document---with various amendments,
" 	\ legislative acts, and court decrees---remains as the University's charter.
" 	\ In bold, sweeping language it stipulates that the objectives of the University
" 	\ are ``to qualify students for personal success and direct usefulness in life;
" 	\ and to promote the public welfare by exercising an influence in behalf of
" 	\ humanity and civilization, teaching the blessings of liberty regulated by
" 	\ law, and inculcating love and reverence for the great principles of
" 	\ government as derived from the inalienable rights of man to life, liberty,
" 	\ and the pursuit of happiness.''\\
" 	\ (!`THE DAZED BROWN FOX QUICKLY GAVE 12345--67890 JUMPS!)\\par}}
" 	\ \\def\\\moretext{?`But aren't Kafka's Schlo{\\ss} and {\\AE}sop's {\\OE}uvres
" 	\ often na{\\"\\i}ve  vis-\\`a-vis the d{\\ae}monic ph{\\oe}nix's official r\\^ole
" 	\ in fluffy souffl\\'es? }
" 	\ \\moretext"

    if a:fd_files == ["buffer"]
	let l:openbuffer="edit "
    else
	let l:openbuffer="topleft split!"
    endif
    execute l:openbuffer . " +setlocal\\ ft=tex\\ modifiable\\ noro " . l:testfont_file 
    map <buffer> q :bd!<CR>

    call setline(1,'\documentclass{article}')
    call setline(2,'\oddsidemargin=0pt')
    call setline(3,'\textwidth=450pt')
    call setline(4,'\textheight=700pt')
    call setline(5,'\topmargin=-10pt')
    call setline(6,'\headsep=0pt')
    call setline(7,'\begin{document}')

    let l:i=8
    let l:j=1
    let l:len_font_decl_dict=len(l:font_decl_dict)
    let b:len_font_decl_dict=l:len_font_decl_dict
    for l:fd_file in keys(l:font_decl_dict) 
	if l:j == 1 
	    call setline(l:i,'\textsc\textbf{\Large Fonts from the file '.l:fd_file.'}\\[2em]')
	    let l:i+=1
	else
" 	    call setline(l:i,'\pagebreak[4]')
	    call setline(l:i,'\vspace{4em}')
	    call setline(l:i+1,'')
	    call setline(l:i+2,'\textsc\textbf{\Large Fonts from the file '.l:fd_file.'}\\[2em]')
	    let l:i+=3
	endif
	let l:len_font_decl=len(l:font_decl_dict[l:fd_file])
	let b:match=[]
	for l:font in l:font_decl_dict[l:fd_file]
	    " SHOW THE FONT ENCODING, FAMILY, SERIES and SHAPE
	    if matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') == "b" ||
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') == "bx"
		let b:show_font='\noindent{\large \textit{Font Encoding}: \textsf{' . 
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			    \ ' \textit{Font Family}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^}#]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			    \ ' \textit{Font Series}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') . '}' . 
			    \ ' \textit{Font Shape}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}') . '}}\\[2pt]'
	    else
		let b:show_font='\noindent{\large \textbf{Font Encoding}: \textsf{' . 
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			    \ ' \textbf{Font Family}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^}#]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			    \ ' \textbf{Font Series}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') . '}' . 
			    \ ' \textbf{Font Shape}: \textsf{' .  
			    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}') . '}}\\[2pt]'
	    endif
	    call setline(l:i,b:show_font)
	    let l:i+=1
	    " CHANGE THE FONT
	    call setline(l:i,'{' . substitute(
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'),
			\ l:declare_command,'usefont','') . 
			\ '\selectfont')
	    " WRITE SAMPLE TEXT
	    call add(b:match,matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'))
	    let l:i+=1
	    " END
	    if l:j<l:len_font_decl
		call setline(l:i,s:text . '}\\\\')
	    else
		call setline(l:i,s:text . '}')
	    endif
	    let l:i+=1
	    let l:j+=1
	endfor
    endfor
    call setline(l:i,'\end{document}')
    silent w
    if b:atp_TexCompiler =~ '^pdf'	
	let l:ext=".pdf"
    else
	let l:ext=".dvi"
    endif
    call system(b:atp_TexCompiler . " " . l:testfont_file . 
	    \ " && " . b:atp_Viewer . " " . fnamemodify(l:testfont_file,":p:r") . l:ext ." &")
    if !a:keep_tex
	silent exe "bd"
    endif
endfunction
" }}}2
"{{{2 atplib#FontPreview
" a:fd_file  pattern to find fd file (.fd will be appended if it is not
" present at the end),
" a:1 = encoding
" a:2 = l:keep_tex, i.e. show the tex source.
function! atplib#FontPreview(method, fd_file,...)


    let l:method	= ( a:method == "!" ? 1 : 0 )
    let l:enc		= ( a:0 >= 1 ? a:1 : "" )
    let l:keep_tex 	= ( a:0 >= 2 ? a:2 : 0 )

    if filereadable(a:fd_file)
	let l:fd_file=a:fd_file
    else
	" Find fd file
	if a:fd_file !~ '.fd\s*$'
	    let l:fd_file=a:fd_file.".*.fd"
	else
	    let l:fd_file=a:fd_file
	endif
" 	let l:path=substitute(substitute(system("kpsewhich -show-path tex"),'!!','','g'),'\/\/\+','\/','g')
" 	let l:path=substitute(l:path,':\|\n',',','g')
" 	let l:fd_all=split(globpath(l:path,"**/*.fd"),'\n') 
" 	let l:fd=filter(l:fd_all,'v:val =~ l:fd_file && fnamemodify(v:val,":t") =~ "^".l:enc')

	let l:fd=atplib#FdSearch(a:fd_file, l:method)

	if len(l:fd) == 0
	    if !l:method
		echo "FD file not found. Try :FontPreview!"
	    else
		echo "FD file not found."
	    endif
	    return
	elseif len(l:fd) == 1
	    let l:fd_file_list=l:fd
	else
	    let l:i=1
	    for l:f in l:fd
		echo l:i." ".substitute(f,'^'.fnamemodify(f,":h:h").'/\?','','')
		let l:i+=1
	    endfor
	    let l:choice=input('Which fd file? ')
	    if l:choice == "" 
		return
	    endif
	    let l:choice_list=split(l:choice,',')
	    let b:choice_list=l:choice_list
	    " if there is 1-4  --> a list of 1,2,3,4
	    let l:new_choice_list=[]
	    for l:ch in l:choice_list
		if l:ch =~ '^\d\+$'
		    call add(l:new_choice_list,l:ch)
		elseif l:ch =~ '^\d\+\s*-\s*\d\+$'
		    let l:b=matchstr(l:ch,'^\d\+')
		    let l:e=matchstr(l:ch,'\d\+$')
		    let l:k=l:b
		    while l:k<=l:e
			call add(l:new_choice_list,l:k)
			let l:k+=1
		    endwhile
		endif
	    endfor
	    let b:new_choice_list=l:new_choice_list
	    let l:fd_file_list=map(copy(l:new_choice_list),'get(l:fd,(v:val-1),"")')
	    let l:fd_file_list=filter(l:fd_file_list,'v:val != ""')
" 	    let l:fd_file=get(l:fd,l:choice-1,"return")
	    if len(l:fd_file_list) == 0
		return
	    endif
	endif
    endif
    call atplib#Preview(l:fd_file_list,l:keep_tex)
endfunction
"}}}2
" {{{2 atplib#ShowFonts
function! atplib#ShowFonts(fd_file)
    let l:declare_command='\C\%(DeclareFontShape\%(WithSizes\)\?\|sauter@\%(tt\)\?family\|EC@\%(tt\)\?family\|krntstexmplfamily\|HFO@\%(tt\)\?family\)'
    
    let l:font_decl=[]
    for l:line in readfile(a:fd_file)
	if l:line =~ '\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'
	    call add(l:font_decl,l:line)
	endif
    endfor
    let l:font_commands=[]
    for l:font in l:font_decl
	call add(l:font_commands,substitute(
		    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'),
		    \ l:declare_command,'usefont',''))
    endfor
    return l:font_commands
endfunction
"}}}2
" }}}1
"
" vim:fdm=marker:ff=unix:noet:ts=8:sw=4:fdc=1
