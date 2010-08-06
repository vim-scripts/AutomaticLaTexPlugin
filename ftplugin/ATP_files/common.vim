" Author: Marcin Szamotulski
" 
" This file contains set of functions which are needed to set to set the atp
" options and some common tools.

" This function finds all the input files declared in the source file.
" {{{ Find Input Files
" It returns a dictionary of the form:
" { <input__name> : [ 'type', 'main_file', 'full_path'] } 
" where 'type' is one of 'bib', 'input', 'main file'. 
" 			'main file' 	if it is recognized as a main project file
" 			'bib' 		if it is a bibliography 'input' 	if it
" 					is an included file in the source file ( by
" 					one of \include, \includeonly, \input
" FindInputFile([bufname],[echo])

" ToDo: this function should have a mode to find input files recursively.
" a:1 	= file name 	(if not present the current buffer)
" a:2   = 0/1		(echo the results or not, default is to echo) 
" there is also a function atplib#Find
" This function is needed outside the script (atplib.vim)
function! FindInputFiles(...)    

    let l:bufname 	= ( a:0 == 0 ? bufname("%") : a:1 )
    let l:echo 		= ( a:0 >= 2 ? a:2 : 1 )

    let l:dir=fnamemodify(l:bufname,":p:h")
    if buflisted(fnamemodify(l:bufname,":t"))
	let l:texfile=getbufline(fnamemodify(l:bufname,":t"),1,'$')
    else
	try
	    let l:texfile=readfile(fnamemodify(l:bufname,":p"))
	catch /E484: Cannot open file/
" 	    echoerr "FindInputFiles Error. Cannot open file " . fnamemodify(l:bufname,":p")
	    return {}
	endtry
    endif
"     let b:texfile=l:texfile
    let s:i=0
    let l:inputlines=[]
    for l:line in l:texfile
	if l:line =~ "\\\\\\(input\\|include\\|includeonly\\)" && l:line !~ "^\s*%"
	    "add the line but cut it before first '%', thus we should get the
	    "file name.
	    let l:col=stridx(l:line,"%")
	    if l:col != -1
		let l:line=strpart(l:line,0,l:col)
	    endif
	    let l:inputlines=add(l:inputlines,l:line) 
	endif
    endfor

   " this is the dictionary that will be returned, its format is:
   " { input file name (as appear in tex file : [ input/include/bib, name of the main tex file ] }
    let l:inputfiles={}

    for l:line in l:inputlines
	if l:line !~ '{'
	    let l:inputfile=substitute(l:line,'\\\%(input\|include\|includeonly\)\s\+\(.*\)','\1','')
	    call extend(l:inputfiles, { l:inputfile : [ 'input' , fnamemodify(expand("%"),":p") ] } )
	else
	    let l:bidx=stridx(l:line,'{')
	    let l:eidx=len(l:line)-stridx(join(reverse(split(l:line,'\zs')),''),'}')-1
	    let l:inputfile=strpart(l:line,l:bidx+1,l:eidx-l:bidx-1)
	    call extend(l:inputfiles, { l:inputfile : [ 'include' , fnamemodify(expand("%"),":p") ] } )
	endif
    endfor
    call extend(l:inputfiles, FindBibFiles(l:bufname))
    " this function is used to set b:atp_MainFile, but at this stage there is no
    " need to add b:atp_MainFile to the list of input files (this is also
    " a requirement for the function SetProjectName.
    if exists("b:atp_MainFile")
	call extend(l:inputfiles, { fnamemodify(b:atp_MainFile,":t") : ['main file', b:atp_MainFile]}, "error") 
    endif
    let l:inputfiless=deepcopy(l:inputfiles)
    call filter(l:inputfiless, 'v:key !~ fnamemodify(bufname("%"),":t:r")')
    if l:echo 
	if len(keys(l:inputfiless)) > 0 
	    echohl WarningMsg | echomsg "Found input files:" 
	else
	    echohl WarningMsg | echomsg "No input files found." | echohl None
	    return {}
	endif
	echohl texInput
	let l:nr=1
	for l:inputfile in keys(l:inputfiless)
	    if l:inputfiless[l:inputfile][0] == 'main file'
		echomsg fnamemodify(l:inputfile,":t") 
		let l:nr+=1
	    endif
	endfor
	for l:inputfile in keys(l:inputfiless)
	    if l:inputfiless[l:inputfile][0] == 'input'
		echomsg substitute(l:inputfile,'^\s*\"\|\"\s*$','','g') 
		let l:nr+=1
	    endif
	endfor
	for l:inputfile in keys(l:inputfiless)
	    if l:inputfiless[l:inputfile][0] == 'include'
		echomsg substitute(l:inputfile,'^\s*\"\|\"\s*$','','g') 
		let l:nr+=1
	    endif
	endfor
	for l:inputfile in keys(l:inputfiless)
	    if l:inputfiless[l:inputfile][0] == 'bib'
		echomsg substitute(l:inputfile,'^\s*\"\|\"\s*$','','g') 
		let l:nr+=1
	    endif
	endfor
	echohl None
    endif
    let s:inputfiles=l:inputfiles
return l:inputfiles
endfunction
command! -buffer -nargs=? -complete=buffer	FindInputFiles	:call FindInputFiles(<f-args>)
" }}}

" This function finds all the bibliography files declared in the source file.
" {{{ Find Bib Files 
" Returns a dictionary:
" { <input_name> : [ 'bib', 'main file', 'full path' ] }
"			 with the same format as the output of FindInputFiles
function! FindBibFiles(...)

    if a:0==0
	let l:bufname=bufname("%")
    else
	let l:bufname=a:1
    endif

    let s:i	 =0
    let s:bibline=[]

    let saved_llist	= getloclist(0)
    try
	silent execute "lvimgrep /^[^%]*\\\\bibliography\s*{/j " . l:bufname
    catch /E480: No match:/
    endtry
    let loclist		= getloclist(0)
    call setloclist(0, saved_llist)
    let s:bibline	= map(loclist, "v:val['text']")

    let l:nr	= s:i
    let s:i	= 1
    let l:allbibfiles = []
    " make a comma separated list of bibfiles
    for l:line in s:bibline
	    let file	= matchstr(l:line, '\\bibliography{\zs[^}]*\ze}')
	    call add(l:allbibfiles, file)
	let s:i+=1
    endfor

    " add the list b:bibfiles 
    if exists('b:bibfiles')
	call extend(l:allbibfiles, b:bibfiles)
    endif
    
    " clear the list s:allbibfile from double entries 
    let l:callbibfiles=[]
    for l:f in l:allbibfiles
	if count(l:callbibfiles,l:f) == 0
	    call add(l:callbibfiles,l:f)
	endif
    endfor
    let l:allbibfiles=deepcopy(l:callbibfiles)
"     let b:abf=l:allbibfiles

    " this variable will store unreadable bibfiles:    
    let s:notreadablebibfiles=[]

    " this variable will store the final result:   
"     let l:bibfiles={}
    let l:bibfiles_dict={}
    let b:bibfiles_dict=l:bibfiles_dict

    " Make a list of all bib files which tex can find.
    let l:bibfiles_list=[]
    let b:bibfiles_list=l:bibfiles_list " DEBUG
    for l:dir in split(g:atp_raw_bibinputs, ',')
	let l:bibfiles_list=extend(l:bibfiles_list,atplib#FindInputFilesInDir(l:dir,0,".bib"))
    endfor

    for l:f in l:allbibfiles
	" ToDo: change this to find in any directory under g:atp_raw_bibinputs. 
	" also change in the line 1406 ( atplib#s:searchbib )
	for l:bibfile in l:bibfiles_list
	    if count(l:allbibfiles,fnamemodify(l:bibfile,":t:r"))
		if filereadable(l:bibfile) 
		call extend(l:bibfiles_dict, 
		    \ {fnamemodify(l:bibfile,":t:r") : [ 'bib' , fnamemodify(expand("%"),":p"), l:bibfile ] })
		else
		" echo warning if a bibfile is not readable
		    echohl WarningMsg | echomsg "Bibfile " . l:f . ".bib not found." | echohl None
		    if count(s:notreadablebibfiles,fnamemodify(l:f,":t:r")) == 0 
			call add(s:notreadablebibfiles,fnamemodify(l:f,":t:r"))
		    endif
		endif
	    endif
	endfor
    endfor

    " return the list  of readable bibfiles
    return l:bibfiles_dict
endfunction
"}}}

" All Status Line related things:
"{{{ Status Line
function! ATPStatusOutDir() "{{{
let status=""
if exists("b:atp_OutDir")
    if b:atp_OutDir != "" 
	let status= status . "Output dir: " . pathshorten(substitute(b:atp_OutDir,"\/\s*$","","")) 
    else
	let status= status . "Please set the Output directory, b:atp_OutDir"
    endif
endif	
    return status
endfunction "}}}

" There is a copy of this variable in compiler.vim
let s:CompilerMsg_Dict	= { 
	    \ 'tex'		: 'TeX', 
	    \ 'etex'		: 'eTeX', 
	    \ 'pdftex'		: 'pdfTeX', 
	    \ 'latex' 		: 'LaTeX',
	    \ 'elatex' 		: 'eLaTeX',
	    \ 'pdflatex'	: 'pdfLaTeX', 
	    \ 'context'		: 'ConTeXt',
	    \ 'luatex'		: 'LuaTeX',
	    \ 'xetex'		: 'XeTeX'}

function! ATPRunning() "{{{
    if exists("b:atp_running") && exists("g:atp_callback") && b:atp_running && g:atp_callback
	redrawstatus

	for cmd in keys(s:CompilerMsg_Dict) 
	if b:atp_TexCompiler =~ '^\s*' . cmd . '\s*$'
		let Compiler = s:CompilerMsg_Dict[cmd]
		break
	    else
		let Compiler = b:atp_TexCompiler
	    endif
	endfor

	if b:atp_running >= 2
	    return b:atp_running." ".Compiler." "
	else
	    return Compiler." "
	endif
    endif
    return ''
endfunction "}}}

" {{{ Syntax and Hilighting
" ToDo:
" syntax 	match 	atp_statustitle 	/.*/ 
" syntax 	match 	atp_statussection 	/.*/ 
" syntax 	match 	atp_statusoutdir 	/.*/ 
" hi 	link 	atp_statustitle 	Number
" hi 	link 	atp_statussection 	Title
" hi 	link 	atp_statusoutdir 	String
" }}}

" The main status function, it is called via autocommand defined in 'options.vim'.
function! ATPStatus() "{{{
"     echomsg "Status line set by ATP." 
    if &filetype == 'tex'
	if g:atp_status_notification
	    let &statusline='%<%f %(%h%m%r %)  %{CTOC("return")}%= %{ATPRunning()} %{ATPStatusOutDir()} %-14.16(%l,%c%V%)%P'
	else
	    let &statusline='%<%f %(%h%m%r %)  %{CTOC("return")}%= %{ATPStatusOutDir()} %-14.16(%l,%c%V%)%P'
	endif 
    else 
	if g:atp_status_notification
	    let  &statusline='%<%f %(%h%m%r %)  %= %{ATPRunning()} %{ATPStatusOutDir()} %-14.16(%l,%c%V%)%P'
	else
	    let  &statusline='%<%f %(%h%m%r %)  %= %{ATPStatusOutDir()} %-14.16(%l,%c%V%)%P'
	endif
    endif
endfunction
command! -buffer ATPStatus		:call ATPStatus() 
" }}}
"}}}

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
