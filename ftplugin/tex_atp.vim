" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 June 23
" URL:		
" Email:	mszamot [AT] gmail [DOT] com
" GetLatestVimScripts: 2945 25 :AutoInstall: tex_atp.vim
" {{{1 Copyright
" Copyright:    Copyright (C) 2010 Marcin Szamotulski Permission is hereby 
"		granted to use and distribute this code, with or without
" 		modifications, provided that this copyright notice is copied
" 		with it. Like anything else that's free, Automatic TeX Plugin
" 		is provided *as is* and comes with no warranty of any kind,
" 		either expressed or implied. By using this plugin, you agree
" 		that in no event will the copyright holder be liable for any
" 		damages resulting from the use of this software. 
" 		This licence is valid for all files distributed with ATP
" 		plugin.
"}}}1
"{{{1 Ideas:
" Extend WrapSelection to specify the end and add some mapps. It can also
" encolse paragraphs with \begin{}:\end{} pairs and brackets
" (:),{:},[:],\(:\),\[:\]! 
"
" To set the master file: a scaning function for a main file:
" one can do that like in latex-suite with master.tex.some_suffix file
" or scan .tex files (recursively for a string \input ..., this might be slow?
" but there is no need of makeing extra files. Make a list of files and let
" user to choose which is a master file. Mayby there is a way to remember this
" in vim (saveview/loadview ?) so that if this is done this will be
" remembered. 
"
" check if how it is done now (using EditInputFile) is well documented in doc
"}}}1
"{{{1 ToDo:
" Idea: to make it load faster I can use: 41.14 *write-plugin-quickload* or
" even better 41.15 *write-library-script*.
"
" Todo: \usetikzlibrary
"
" Todo: generate the g:bibresults dictionary with pattern "" and then match
" aginst it. This could be faster. And make command to regenerate the bib
" database.
"
" Idea: write a diff function wich compares two files ignoring new lines, but
" using the structure of \begin:\end \(:\), etc... .
"
" Todo: make small Help functions with list of most important mappings and
" commands for each window (this can help at the begining) make it possible to
" turn it off.
"
" Done: using a symbolic link, run \v it will use the name of symbolic name
" not the target. Also the name of the xpdfserver is taken from the actually
" opend file (for example input file) and not the target name of the link. 
" Look intfor b:texcommand.
"
" Done: modify EditInputFiles so that it finds file in the b:atp_mainfile
"
" Done: EditInputFile if running from an input file a main file should be
" added. Or there should be a function to come back.
"
" Done: make a function which list all definitions
"
" TODO: to make s:maketoc and generatelabels read all input files between
" \begin{document} and \end{document}, and make it recursive.
" now s:maketoc finds only labels of chapters/sections/...
"
" TODO: make toc work with parts!
" 		The work has started ...
"
" Comment: The time consuming part of TOC command is: opening new window
" ('vnew') as shown by profiling.
"
" TODO: Check against lilypond 
"
" Done: make a split version of EditInputFile
"
" Done: for input files which filetype=plaintex (for example hyphenation
" files), the variable b:autex is not set. Just added plaintex_atp.vim file
" which sources tex_atp.vim file.  
" }}}1
"
" NOTES:
" s:tmpfile =	temporary file value of tempname()
" b:texfile =	readfile(bunfname("%")
" {{{1 Load once
if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1
" }}}1
"{{{1 some variables
" We need to know bufnumber and bufname in a tabpage.

let t:bufname=bufname("")
let t:bufnr=bufnr("")
let t:winnr=winnr()

" This limits how many consecutive runs there can be maximally.
let s:runlimit=5 

let s:texinteraction="nonstopmode"
compiler tex
"}}}1
"{{{1 autocommands for buf/win numbers
" These autocommands are used to remember the last opened buffer number and its
" window number:
au BufLeave *.tex let t:bufname=resolve(fnamemodify(bufname(""),":p"))
au BufLeave *.tex let t:bufnr=bufnr("")
" t:winnr the last window used by tex, ToC or Labels buffers:
au WinEnter *.tex let t:winnr=winnr("#")
au WinEnter __ToC__ 	let t:winnr=winnr("#")
au WinEnter __Labels__ 	let t:winnr=winnr("#")
"}}}1
" {{{1 Vim options

" {{{2 Intendation
if !exists("g:atp_intendation")
    let g:atp_intendation=1
endif
if !exists("g:atp_tex_indent_paragraphs")
    let g:atp_tex_indent_paragraphs=1
endif
if g:atp_intendation
    setl indentexpr=ATP_GetTeXIndent()
    setl nolisp
    setl nosmartindent
    setl autoindent
    setl indentkeys+=},=\\item,=\\bibitem,=\\[,=\\],=<CR>
    let prefix = expand('<sfile>:p:h:h')
    exe 'so '.prefix.'/indent/tex_atp.vim'
endif
" }}}2

setl keywordprg=texdoc\ -m
" Borrowed from tex.vim written by Benji Fisher:
    " Set 'comments' to format dashed lists in comments
    setlocal com=sO:%\ -,mO:%\ \ ,eO:%%,:%

    " Set 'commentstring' to recognize the % comment character:
    " (Thanks to Ajit Thakkar.)
    setlocal cms=%%s

    " Allow "[d" to be used to find a macro definition:
    " Recognize plain TeX \def as well as LaTeX \newcommand and \renewcommand .
    " I may as well add the AMS-LaTeX DeclareMathOperator as well.
    let &l:define='\\\([egx]\|char\|mathchar\|count\|dimen\|muskip\|skip\|toks\)\='
	    \ .	'def\|\\font\|\\\(future\)\=let'
	    \ . '\|\\new\(count\|dimen\|skip\|muskip\|box\|toks\|read\|write'
	    \ .	'\|fam\|insert\)'
	    \ . '\|\\\(re\)\=new\(boolean\|command\|counter\|environment\|font'
	    \ . '\|if\|length\|savebox\|theorem\(style\)\=\)\s*\*\=\s*{\='
	    \ . '\|DeclareMathOperator\s*{\=\s*'
    setlocal include=\\\\input\\\\|\\\\include{
    setlocal suffixesadd=.tex

setl includeexpr=substitute(v:fname,'\\%(.tex\\)\\?$','.tex','')
" TODO set define and work on the above settings, these settings work with [i
" command but not with [d, [D and [+CTRL D (jump to first macro definition)
" }}}1

" {{{1 FindInputFiles
" it should return in the values of the dictionary the name of the file that
" FindInputFile([bufname],[echo])

" ToDo: this function should have a mode to find input files recursively.
if !exists("*FindInputFiles") 
function! FindInputFiles(...)    

    let l:echo=1
    if a:0==0
	let l:bufname=bufname("%")
    else
	let l:bufname=a:1
	if a:0 == 2
	    let l:echo=0
	endif
    endif

    let l:dir=fnamemodify(l:bufname,":p:h")
    if buflisted(fnamemodify(l:bufname,":t"))
	let l:texfile=getbufline(fnamemodify(l:bufname,":t"),1,'$')
    else
	let l:texfile=readfile(fnamemodify(l:bufname,":p"))
    endif
    let b:texfile=l:texfile
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
    call extend(l:inputfiles,FindBibFiles(l:bufname))
    " this function is used to set b:atp_mainfile, but at this stage there is no
    " need to add b:atp_mainfile to the list of input files (this is also
    " a requirement for the function s:setprojectname.
    if exists("b:atp_mainfile")
	call extend(l:inputfiles, { fnamemodify(b:atp_mainfile,":t") : ['main file', b:atp_mainfile]}, "error") 
    endif
    let l:inputfiless=deepcopy(l:inputfiles)
    call filter(l:inputfiless, 'v:key !~ fnamemodify(bufname("%"),":t:r")')
    if l:echo 
	if len(keys(l:inputfiless)) > 0 
	    echohl WarningMsg | echomsg "Found input files:" 
	else
	    echohl WarningMsg | echomsg "No input files found." | echohl None
	    return []
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
endif
" }}}1
" {{{1 FIND BIB FILES 
if !exists("*FindBibFiles")
function! FindBibFiles(...)

    if a:0==0
	let l:bufname=bufname("%")
    else
	let l:bufname=a:1
    endif

"     let b:texfile=readfile(l:bufname)
    if buflisted(fnamemodify(l:bufname,":p"))
	let b:texfile=getbufline(l:bufname,1,'$')
    else
	let b:texfile=readfile(fnameescape(fnamemodify(l:bufname,":p")))
    endif
    let s:i=0
    let s:bibline=[]
    " find all lines which define bibliography files
    for line in b:texfile
	" ToDo: %\bibliography should not be matched!
	if line =~ "^[^%]*\\\\bibliography{"
	    let s:bibline=add(s:bibline,line) 
	    let s:i+=1
	endif
    endfor
    let l:nr=s:i
    let s:i=1
    let files=""
    " make a comma separated list of bibfiles
    for l:line in s:bibline
	if s:i==1
	    let files=substitute(l:line,"\\\\bibliography{\\(.*\\)}","\\1","") . ","
	else
	    let files=files . substitute(l:line,"\\\\bibliography{\\(.*\\)}","\\1","") . "," 
	endif
	let s:i+=1
    endfor

    " rewrite files into a vim list
    let l:allbibfiles=split(files,',')
    
    " add the list b:bibfiles 
    if exists('b:bibfiles')
	call extend(l:allbibfiles,b:bibfiles)
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
    for l:dir in g:atp_bibinputs
	let l:bibfiles_list=extend(l:bibfiles_list,atplib#FindInputFiles(l:dir,0,".bib"))
    endfor

    for l:f in l:allbibfiles
	" ToDo: change this to find in any directory under g:atp_bibinputs. 
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
endif
"}}}1
"{{{1 DefiSearch and s:make_defi_dic

" {{{2 s:make_defi_dic
" make a dictionary: { input_file : [[beginning_line,end_line],...] }
" a:1 is given it is the name of the buffer in which to search for input files.
" a:2=1 skip searching for the end_line
"
" ToDo: it is possible to check for the end using searchpairpos, but it
" operates on a list not on a buffer.
function! s:make_defi_dict(...)

    if a:0 >= 1
	let l:bufname=a:1
    else
	let l:bufname=bufname("%")
    endif

    " pattern to match the definitions this function is also used to fine
    " \newtheorem, and \newenvironment commands  
    if a:0 >= 2	
	let l:pattern = a:2
    else
	let l:pattern = '\\def\|\\newcommand'
    endif

    if a:0 >= 3
	let l:preambule_only=a:3
    else
	let l:preambule_only=1
    endif

    " this is still to slow!
    if a:0 >= 4
	let l:only_begining=a:4
    else
	let l:only_begining=0
    endif

    let l:defi_dict={}

    let l:inputfiles=FindInputFiles(l:bufname,"0")
    let l:input_files=[]
    let b:input_files=l:input_files

    for l:inputfile in keys(l:inputfiles)
	if l:inputfiles[l:inputfile][0] != "bib"
	    let l:input_file=atplib#append(l:inputfile,'.tex')
	    if filereadable(atplib#append(b:outdir,'/') . l:input_file)
		let l:input_file=atplib#append(b:outdir,'/') . l:input_file
	    else
		let l:input_file=findfile(l:inputfile,g:texmf . '**')
	    endif
	    call add(l:input_files, l:input_file)
	endif
    endfor


    let l:input_files=filter(l:input_files, 'v:val != ""')
    if !count(l:input_files,b:atp_mainfile)
	call extend(l:input_files,[ b:atp_mainfile ])
    endif

    if len(l:input_files) > 0
    for l:inputfile in l:input_files
	let l:defi_dict[l:inputfile]=[]
	" do not search for definitions in bib files 
	"TODO: it skips lines somehow. 
	let l:ifile=readfile(l:inputfile)
	
	" search for definitions
	let l:lnr=1
	while (l:lnr <= len(l:ifile) && (!l:preambule_only || l:ifile[l:lnr-1] !~ '\\begin\s*{document}'))
" 	    echo l:lnr . " " . l:inputfile . " " . l:ifile[l:lnr-1] !~ '\\begin\s*{document}'

	    let l:match=0

	    let l:line=l:ifile[l:lnr-1]
	    if substitute(l:line,'%.*','','') =~ l:pattern

		let l:b_line=l:lnr

		let l:lnr+=1	
		if !l:only_begining
		    let l:open=atplib#count(l:line,'{')    
		    let l:close=atplib#count(l:line,'}')
		    while l:open != l:close
			"go to next line and count if the definition ends at
			"this line
			let l:line=l:ifile[l:lnr-1]
			let l:open+=atplib#count(l:line,'{')    
			let l:close+=atplib#count(l:line,'}')
			let l:lnr+=1	
		    endwhile
		    let l:e_line=l:lnr-1
		    call add(l:defi_dict[l:inputfile], [ l:b_line, l:e_line ])
		else
		    call add(l:defi_dict[l:inputfile], [ l:b_line ])
		endif
	    else
		let l:lnr+=1
	    endif
	endwhile
" 	echomsg l:lnr . " " . l:inputfile
    endfor
    endif

    return l:defi_dict
endfunction
"}}}2

"{{{2 DefiSearch
if !exists("*DefiSearch")
function! DefiSearch(...)

    if a:0 == 0
	let l:pattern=''
    else
	let l:pattern='\C' . a:1
    endif
    if a:0 >= 2 
	let l:preambule_only=a:2
    else
	let l:preambule_only=1
    endif

    let l:ddict=s:make_defi_dict(bufname("%"),'\\def\|\\newcommand',l:preambule_only)
"     let b:dd=l:ddict

    " open new buffer
    let l:openbuffer=" +setl\\ buftype=nofile\\ nospell " . fnameescape("DefiSearch")
    if g:vertical ==1
	let l:openbuffer="vsplit " . l:openbuffer 
    else
	let l:openbuffer="split " . l:openbuffer 
    endif

    if len(l:ddict) > 0
	" wipe out the old buffer and open new one instead
	if bufloaded("DefiSearch")
	    exe "silent bd! " . bufnr("DefiSearch") 
	endif
	silent exe l:openbuffer
	map <buffer> q	:bd<CR>

	for l:inputfile in keys(l:ddict)
	    let l:ifile=readfile(l:inputfile)
	    for l:range in l:ddict[l:inputfile]

		if l:ifile[l:range[0]-1] =~ l:pattern
		    " print the lines into the buffer
		    let l:i=0
		    let l:c=0
		    " add an empty line if the definition is longer than one line
		    if l:range[0] != l:range[1]
			call setline(line('$')+1,'')
			let l:i+=1
		    endif
		    while l:c <= l:range[1]-l:range[0] 
			let l:line=l:range[0]+l:c
			call setline(line('$')+1,l:ifile[l:line-1])
			let l:i+=1
			let l:c+=1
		    endwhile
		endif
	    endfor
	endfor

	if getbufline("DefiSearch",'1','$') == ['']
	    :bw
	    echomsg "Definition not found."
	endif
    else
	echomsg "Definition not found."
    endif
    try
	setl filetype=tex
    catch /Cannot redefine function DefiSearch/
    finally
	setl filetype=tex
    endtry
endfunction
endif
"}}}2
"}}}1

"{{{1 SET THE PROJECT NAME
" {{{2 s:setprojectname
" store a list of all input files associated to some file
fun! s:setprojectname()
    " if the project name was already set do not set it for the second time
    " (which sets then b:atp_mainfile to wrong value!)  
    if &filetype == "fd_atp"
	let b:atp_mainfile=fnamemodify(expand("%"),":p")
	let b:atp_projectname_is_set=1
    endif
    if exists("b:atp_projectname_is_set")
	let b:pn_return.=" exists"
	return b:pn_return
    else
	let b:atp_projectname_is_set=1
    endif

    if !exists("s:inputfiles")
	let s:inputfiles=FindInputFiles(expand("%"),0)
    else
	call extend(s:inputfiles,FindInputFiles(bufname("%"),0))
    endif

    if !exists("g:atp_project")
	" the main file is not an input file (at this stage!)
	if index(keys(s:inputfiles),fnamemodify(bufname("%"),":t:r")) == '-1' &&
	 \ index(keys(s:inputfiles),fnamemodify(bufname("%"),":t"))   == '-1' &&
	 \ index(keys(s:inputfiles),fnamemodify(bufname("%"),":p:r")) == '-1' &&
	 \ index(keys(s:inputfiles),fnamemodify(bufname("%"),":p"))   == '-1' 
	    let b:atp_mainfile=fnamemodify(expand("%"),":p")
	    let b:pn_return="not an input file"
" 	    let b:atp_mainfile=atplib#append(b:outdir,'/') . expand("%")
	elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":t")) != '-1'
	    let b:atp_mainfile=fnamemodify(s:inputfiles[fnamemodify(bufname("%"),":t")][1],":p")
	    let b:pn_return="input file 1"
	    if !exists('#CursorHold#' . fnamemodify(bufname("%"),":p"))
		exe "au CursorHold " . fnamemodify(bufname("%"),":p") . " call s:auTeX()"
	    endif
	elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":t:r")) != '-1'
	    let b:atp_mainfile=fnamemodify(s:inputfiles[fnamemodify(bufname("%"),":t:r")][1],":p")
	    let b:pn_return="input file 2"
	    if !exists('#CursorHold#' . fnamemodify(bufname("%"),":p"))
		exe "au CursorHold " . fnamemodify(bufname("%"),":p") . " call s:auTeX()"
	    endif
	elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":p:r")) != '-1' 
	    let b:atp_mainfile=fnamemodify(s:inputfiles[fnamemodify(bufname("%"),":p:r")][1],":p")
" 	    let b:pn_return="input file 3"
	    if !exists('#CursorHold#' . fnamemodify(bufname("%"),":p"))
		exe "au CursorHold " . fnamemodify(bufname("%"),":p") . " call s:auTeX()"
	    endif
	elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":p"))   != '-1' 
	    let b:atp_mainfile=fnamemodify(s:inputfiles[fnamemodify(bufname("%"),":p")][1],":p")
" 	    let b:pn_return="input file 3"
	    if !exists('#CursorHold#' . fnamemodify(bufname("%"),":p"))
		exe "au CursorHold " . fnamemodify(bufname("%"),":p") . " call s:auTeX()"
	    endif
	endif
    elseif exists("g:atp_project")
	let b:atp_mainfile=g:atp_project
	let b:pn_return="set from g:atp_project"
    endif

    " we need to escape white spaces in b:atp_mainfile but not in all places so
    " this is not done here
    return b:pn_return
endfun
" command! SetProjectName	:call s:setprojectname()
" }}}2

au BufEnter *.tex :call s:setprojectname()
au BufEnter *.fd  :call s:setprojectname()
"}}}1
" {{{1 SetErrorFile
" let &l:errorfile=b:outdir . fnameescape(fnamemodify(expand("%"),":t:r")) . ".log"
if !exists("*SetErrorFile")
function! SetErrorFile()

    " set b:outdir if it is not set
    if !exists("b:outdir")
	call s:setoutdir(0)
    endif

    " set the b:atp_mainfile varibale if it is not set (the project name)
    if !exists("b:atp_mainfile")
	call s:setprojectname()
    endif

"     let l:ef=b:outdir . fnamemodify(expand("%"),":t:r") . ".log"
    let l:ef=b:outdir . fnamemodify(b:atp_mainfile,":t:r") . ".log"
    let &l:errorfile=l:ef
    return &l:errorfile
endfunction
endif

"{{{2 autocommands:
au BufEnter *.tex call SetErrorFile()
au BufRead $l:errorfile setlocal autoread 
"}}}2
"}}}1
" {{{1 s:setoutdir
" This options are set also when editing .cls files.
function! s:setoutdir(arg)
    " first we have to check if this is not a project file
    if exists("g:atp_project") || exists("s:inputfiles") && 
		\ ( index(keys(s:inputfiles),fnamemodify(bufname("%"),":t:r")) != '-1' || 
		\ index(keys(s:inputfiles),fnamemodify(bufname("%"),":t")) != '-1' )
	    " if we are in a project input/include file take the correct value of b:outdir from the atplib#s:outdir_dict dictionary.
	    
	    if index(keys(s:inputfiles),fnamemodify(bufname("%"),":t:r")) != '-1'
		let b:outdir=g:outdir_dict[s:inputfiles[fnamemodify(bufname("%"),":t:r")][1]]
	    elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":t")) != '-1'
		let b:outdir=g:outdir_dict[s:inputfiles[fnamemodify(bufname("%"),":t")][1]]
	    endif
    else
	
	    " if we are not in a project input/include file set the b:outdir
	    " variable	

	    " if the user want to be asked for b:outdir
	    if g:askfortheoutdir == 1 
		let b:outdir=input("Where to put output? do not escape white spaces ")
	    endif

	    if ( get(getbufvar(bufname("%"),""),"outdir","optionnotset") == "optionnotset" 
			\ && g:askfortheoutdir != 1 
			\ || b:outdir == "" && g:askfortheoutdir == 1 )
			\ && !exists("$TEXMFOUTPUT")
		 let b:outdir=fnamemodify(resolve(expand("%:p")),":h") . "/"
		 echoh WarningMsg | echomsg "Output Directory "b:outdir | echoh None

	    elseif exists("$TEXMFOUTPUT")
		 let b:outdir=$TEXMFOUTPUT 
	    endif	

	    " if arg != 0 then set errorfile option accordingly to b:outdir
	    if bufname("") =~ ".tex$" && a:arg != 0
		 call SetErrorFile()
	    endif

	    if exists("g:outdir_dict")
		let g:outdir_dict=extend(g:outdir_dict, {fnamemodify(bufname("%"),":p") : b:outdir })
	    else
		let g:outdir_dict={ fnamemodify(bufname("%"),":p") : b:outdir }
	    endif
    endif
    return b:outdir
endfunction
" }}}1

" {{{1 GLOBAL AND LOCAL VARIABLES /some are set elsewere/
if !exists("g:atp_imap_first_leader")
    let g:atp_imap_first_leader="#"
endif
if !exists("g:atp_imap_second_leader")
    let g:atp_imap_second_leader="##"
endif
if !exists("g:atp_imap_third_leader")
    let g:atp_imap_third_leader="]"
endif
if !exists("g:atp_imap_fourth_leader")
    let g:atp_imap_fourth_leader="["
endif
" todo: to doc.
if !exists("g:atp_completion_font_encodings")
    let g:atp_completion_font_encodings=['T1', 'T2', 'T3', 'T5', 'OT1', 'OT2', 'OT4', 'UT1'] 
endif
" todo: to doc.
if !exists("g:atp_font_encoding")
    let s:line=atplib#SearchPackage('fontenc')
    if s:line != 0
	" the last enconding is the default one for fontenc, this we will
	" use
	let s:enc=matchstr(getline(s:line),'\\usepackage\s*\[\%([^,]*,\)*\zs[^]]*\ze\]\s*{fontenc}')
    else
	let s:enc='OT1'
    endif
    let g:atp_font_encoding=s:enc
    unlet s:line
    unlet s:enc
endif
if !exists("g:atp_no_star_environments")
    let g:atp_no_star_environments=['document', 'flushright', 'flushleft', 'center', 
		\ 'enumerate', 'itemize', 'tikzpicture', 'scope', 
		\ 'picture', 'array', 'proof', 'tabular', 'table' ]
endif
let s:ask={ "ask" : "0" }
if !exists("g:atp_sizes_of_brackets")
    let g:atp_sizes_of_brackets={'\left': '\right', '\bigl' : '\bigr', 
		\ '\Bigl' : '\Bigr', '\biggl' : '\biggr' , 
		\ '\Biggl' : '\Biggr', '\' : '\' }
endif
if !exists("g:atp_bracket_dict")
    let g:atp_bracket_dict = { '(' : ')', '{' : '}', '[' : ']'  }
endif
" }}}2 			variables
if !exists("g:atp_LatexBox")
    let g:atp_LatexBox=1
endif
if !exists("g:atp_check_if_LatexBox")
    let g:atp_check_if_LatexBox=1
endif
if !exists("g:atp_autex_check_if_closed")
    let g:atp_autex_check_if_closed=1
endif
if !exists("g:rmcommand") && executable("perltrash")
    let g:rmcommand="perltrash"
elseif !exists("g:rmcommand")
    let g:rmcommand="rm"
endif
if !exists("g:atp_env_maps_old")
    let g:atp_env_maps_old=0
endif
if !exists("g:atp_amsmath")
    let g:atp_amsmath=0
endif
if !exists("g:atp_no_math_command_completion")
    let g:atp_no_math_command_completion=0
endif
if !exists("g:askfortheoutdir")
    let g:askfortheoutdir=0
endif
if !exists("g:atp_tex_extensions")
    let g:atp_tex_extensions=["aux", "log", "bbl", "blg", "spl", "snm", "nav", "thm", "brf", "out", "toc", "mpx", "idx", "maf", "blg", "glo", "mtc[0-9]", "mtc1[0-9]"]
endif
if !exists("g:atp_delete_output")
    let g:atp_delete_output=0
endif
if !exists("g:keep")
    let g:keep=["log","aux","toc","bbl"]
endif
if !exists("g:printingoptions")
    let g:printingoptions=''
endif
if !exists("g:atp_ssh")
    let g:atp_ssh=substitute(system("whoami"),'\n','','') . "@localhost"
endif
" opens bibsearch results in vertically split window.
if !exists("g:vertical")
    let g:vertical=1
endif
if !exists("g:matchpair")
    let g:matchpair="(:),[:],{:}"
endif
if !exists("g:texmf")
    let g:texmf=$HOME . "/texmf"
endif
" a list where tex looks for bib files
if !exists("g:atp_bibinputs")
    let g:atp_bibinputs=split(substitute(substitute(
		\ system("kpsewhich -show-path bib")
		\ ,'\/\/\+','\/','g'),'!\|\n','','g'),':')
endif
if !exists("g:atp_compare_embedded_comments") || g:atp_compare_embedded_comments != 1
    let g:atp_compare_embedded_comments = 0
endif
if !exists("g:atp_compare_double_empty_lines") || g:atp_compare_double_empty_lines != 0
    let g:atp_compare_double_empty_lines = 1
endif
"TODO: put toc_window_with and labels_window_width into DOC file
if !exists("t:toc_window_width")
    if exists("g:toc_window_width")
	let t:toc_window_width=g:toc_window_width
    else
	let t:toc_window_width=30
    endif
endif
if !exists("t:labels_window_width")
    if exists("g:labels_window_width")
	let t:labels_window_width=g:labels_window_width
    else
	let t:labels_window_width=30
    endif
endif
if !exists("g:atp_completion_limits")
    let g:atp_completion_limits=[40,60,80,120]
endif
if !exists("g:atp_long_environments")
    let g:atp_long_environments=[]
endif
if !exists("g:atp_no_complete")
     let g:atp_no_complete=['document']
endif
" if !exists("g:atp_close_after_last_closed")
"     let g:atp_close_after_last_closed=1
" endif
if !exists("g:atp_no_env_maps")
    let g:atp_no_env_maps=0
endif
if !exists("g:atp_extra_env_maps")
    let g:atp_extra_env_maps=0
endif
" todo: to doc. Now they go first.
" if !exists("g:atp_math_commands_first")
"     let g:atp_math_commands_first=1
" endif
if !exists("g:atp_completion_truncate")
    let g:atp_completion_truncate=4
endif
" ToDo: to doc.
" add server call back (then automatically reads errorfiles)
if !exists("g:atp_status_notification")
    let g:atp_status_notification=0
endif
if !exists("g:atp_callback")
    if exists("g:atp_status_notification") && g:atp_status_notification == 1
	let g:atp_callback=1
    else
	let g:atp_callback=0
    endif
endif
" ToDo: to doc.
" I switched this off.
" if !exists("g:atp_complete_math_env_first")
"     let g:atp_complete_math_env_first=0
" endif
let b:atp_running=0
" ToDo: to doc.
" this shows errors as ShowErrors better use of call back mechnism is :copen!
if !exists("g:atp_debug_mode")
    let g:atp_debug_mode=0
endif
if !exists("*ATPRunnig")
function! ATPRunning()
    if b:atp_running && g:atp_callback
	redrawstatus
	return b:texcompiler
    endif
    return ''
endfunction
endif
" these are all buffer related variables:
let s:optionsDict= { 	"texoptions" 	: "", 		"reloadonerror" : "0", 
		\	"openviewer" 	: "1", 		"autex" 	: "1", 
		\	"Viewer" 	: "xpdf", 	"ViewerOptions" : "", 
		\	"XpdfServer" 	: fnamemodify(expand("%"),":t"), 
		\	"outdir" 	: fnameescape(fnamemodify(resolve(expand("%:p")),":h")) . "/",
		\	"texcompiler" 	: "pdflatex",	"auruns"	: "1",
		\ 	"truncate_status_section"	: "40"}
" {{{2 s:setoptions
" This function sets options (values of buffer related variables) which were
" not set by the user to their default values.
function! s:setoptions()
    let s:optionsKeys=keys(s:optionsDict)
    let s:optionsinuseDict=getbufvar(bufname("%"),"")

    "for each key in s:optionsKeys set the corresponding variable to its default
    "value unless it was already set in .vimrc file.
    for l:key in s:optionsKeys

	if get(s:optionsinuseDict,l:key,"optionnotset") == "optionnotset" && l:key != "outdir" && l:key != "autex"
	    call setbufvar(bufname("%"),l:key,s:optionsDict[l:key])
	elseif l:key == "outdir"
	    
	    " set b:outdir and the value of errorfile option
	    call s:setoutdir(1)
	    let s:ask["ask"] = 1
	endif
    endfor
    if get(s:optionsinuseDict,"autex","optionnotset") == "optionnotset"
	let l:atp_texinputs=split(substitute(substitute(system("kpsewhich -show-path tex"),'\/\/\+','\/','g'),'!\|\n','','g'),':')
    call remove(l:atp_texinputs,'.')
	call filter(l:atp_texinputs,'v:val =~ b:outdir')
	if len(l:atp_texinputs) == 0
	    let b:autex=1
	else
	    let b:autex=0
	endif
    endif

endfunction
call s:setoptions()
"}}}2
"{{{2 ShowOptions
if !exists("*ShowOptions")
function! ShowOptions(...)
    redraw!
    let s:bibfiles=keys(FindBibFiles(bufname("%")))
    if a:0 == 0
	echomsg "variable=local value"  
	echohl BibResultsMatch
	echomsg "b:texcompiler=   " . b:texcompiler 
	echomsg "b:texoptions=    " . b:texoptions 
	echomsg "b:autex=         " . b:autex 
	echomsg "b:outdir=        " . b:outdir 
	echomsg "b:Viewer=        " . b:Viewer 
	echomsg "b:ViewerOptions=   " . b:ViewerOptions 
	echohl BibResultsGeneral
	if b:Viewer == "xpdf"
	    echomsg "    b:XpdfServer=    " . b:XpdfServer 
	    echomsg "    b:reloadonerror= " . b:reloadonerror 
	endif
	echomsg "b:openviewer=    " . b:openviewer 
	echomsg "g:askfortheoutdir=" . g:askfortheoutdir 
	if (exists("g:atp_statusline") && g:atp_statusline == '1') || !exists("g:atp_statusline")
	    echomsg "status line set by atp"
	endif
	echohl BibResultsMatch
	echomsg "g:keep=          " . string(g:keep)  
	echomsg "g:atp_tex_extensions= " . string(g:atp_tex_extensions)
	echomsg "g:rmcommand=     " . g:rmcommand
	echohl BibResultsFileNames
	echomsg "g:defaultbibflags=     " . g:defaultbibflags
	echomsg "g:defaultallbibflags=  " . g:defaultallbibflags
	echomsg "Available Flags        " . string(keys(g:bibflagsdict))
	echomsg "Available KeyWordFlags " . string(keys(g:kwflagsdict))
	echohl BibResultsMatch
	if exists('b:lastbibflags')
	    echomsg "b:lastbibflags=    " . b:lastbibflags
	endif
	echohl None
	echomsg "g:bibentries=    " . string(g:bibentries)
	echohl BibResultsFileNames
	if exists('b:bibfiles')
	    echomsg "b:bibfiles=      " .  string(b:bibfiles)
	endif
	if exists('s:bibfiles')
	    echomsg "s:bibfiles=      " .  string(s:bibfiles)	. " bibfiles used by atp."
	endif
	if exists('s:notreadablebibfiles')
	    echomsg "s:notreadablebibfiles=" .  string(s:notreadablebibfiles)
	endif
	echohl None
    elseif a:0>=1 
	echohl BibResultsMatch
	echomsg "b:texcompiler=   " . b:texcompiler . "  [" . s:optionsDict["texcompiler"] . "]" 
	echomsg "b:texoptions=    " . b:texoptions . "  [" . s:optionsDict["texoptions"] . "]" 
	echomsg "b:autex=         " . b:autex . "  [" . s:optionsDict["autex"] . "]" 
	echomsg "b:outdir=        " . b:outdir . "  [" . s:optionsDict["outdir"] . "]" 
	echomsg "b:Viewer=        " . b:Viewer . "  [" . s:optionsDict["Viewer"] . "]" 
	echomsg "b:ViewerOptions=   " . b:ViewerOptions . "  [" . s:optionsDict["ViewerOptions"] . "]" 
	echohl None
	if b:Viewer == "xpdf"
	    echomsg "    b:XpdfServer=    " . b:XpdfServer . "  [" . s:optionsDict["XpdfServer"] . "]" 
	    echomsg "    b:reloadonerror= " . b:reloadonerror . "  [" . s:optionsDict["reloadonerror"] . "]" 
	endif
	echomsg "g:askfortheoutdir=" . g:askfortheoutdir . "  [" . s:optionsDict["askfortheoutdir"] . "]" 
	echomsg "b:openviewer=    " . b:openviewer . "  [" . s:optionsDict["openviewer"] . "]" 
	echo
	echohl BibResultsMatch
	echomsg "g:keep=          " . string(g:keep)  
	echomsg "g:atp_tex_extensions= " . string(g:atp_tex_extensions)
	echomsg "g:rmcommand=     " . g:rmcommand
	echohl None
	echohl BibResultsFileNames
	echomsg "g:defaultbibflags=     " . g:defaultbibflags
	echomsg "g:defaultallbibflags=  " . g:defaultallbibflags
	echomsg " "
	echomsg "Available Flags        "
	echomsg "   g:bibflagsdict=     " . string(items(g:bibflagsdict))
	echomsg " "
	echomsg "Available KeyWordFlags "
	echomsg "   g:kwflagsdict=      " . string(items(g:kwflagsdict))
	echomsg " "
	echohl BibResultsMatch
	if exists('b:lastbibflags')
	    echomsg "b:lastbibflags=" . b:lastbibflags
	endif
	echohl BibResultsLabel
	echomsg "g:bibentries=" . string(g:bibentries) . "  ['article', 'book', 'booklet', 'conference', 'inbook', 'incollection', 'inproceedings', 'manual', 'masterthesis', 'misc', 'phdthesis', 'proceedings', 'techreport', 'unpublished']"
	echohl BibResultsFileNames
	if exists('b:bibfiles')
	    echomsg "b:bibfiles=  " .  string(b:bibfiles)
	endif
	if exists('s:bibfiles')
	    echomsg "s:bibfiles=      " .  string(s:bibfiles)	. " bibfiles used by atp."
	endif
	if exists('s:notreadablebibfiles')
	    echomsg "s:notreadablebibfiles=" .  string(s:notreadablebibfiles)
	endif
	echohl None
	echomsg ""
    endif
endfunction
endif
"}}}2
"}}}1

"			 FUNCTIONS

"{{{1 Status Line
function! ATPStatusOutDir()
let s:status=""
if exists("b:outdir")
    if b:outdir != "" 
	let s:status= s:status . "Output dir: " . pathshorten(substitute(b:outdir,"\/\s*$","","")) 
    else
	let s:status= s:status . "Please set the Output directory, b:outdir"
    endif
endif	
    return s:status
endfunction

syntax match atp_statustitle 	/.*/ 
syntax match atp_statussection 	/.*/ 
syntax match atp_statusoutdir 	/.*/ 
hi link atp_statustitle Number
hi link atp_statussection Title
hi link atp_statusoutdir String

if !exists("*ATPStatus")
function! ATPStatus()
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
endif
if (exists("g:atp_statusline") && g:atp_statusline == '1') || !exists("g:atp_statusline")
     au BufWinEnter *.tex call ATPStatus()
endif
"}}}1
" {{{1 ViewOutput
if !exists("*ViewOutput")
function! ViewOutput()
    call atplib#outdir()
    if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex"
	let l:ext = ".pdf"
    else
	let l:ext = ".dvi"	
    endif

    let l:link=system("readlink " . shellescape(b:atp_mainfile))
    if l:link != ""
	let l:outfile=fnamemodify(l:link,":r") . l:ext
    else
	let l:outfile=fnamemodify(b:atp_mainfile,":r"). l:ext 
    endif
    let b:outfile=l:outfile
    if b:Viewer == "xpdf"	
	let l:viewer=b:Viewer . " -remote " . shellescape(b:XpdfServer) . " " . b:ViewerOptions 
    else
	let l:viewer=b:Viewer  . " " . b:ViewerOptions
    endif
    let l:view=l:viewer . " " . shellescape(l:outfile)  . " &"
		let b:outfile=l:outfile
		let b:viewcommand=l:view " DEBUG
    if filereadable(l:outfile)
	if b:Viewer == "xpdf"	
	    let b:view=l:view
	    call system(l:view)
	else
	    call system(l:view)
	    redraw!
	endif
    else
	echomsg "Output file do not exists. Calling " . b:texcompiler
	call s:compiler(0,1,1,0,"AU",b:atp_mainfile)
    endif	
endfunction
endif
"}}}1
"{{{1 Getpid
function! s:getpid()
	let s:command="ps -ef | grep -v " . $SHELL  . " | grep " . b:texcompiler . " | grep -v grep | grep " . fnameescape(expand("%")) . " | awk 'BEGIN {ORS=\" \"} {print $2}'" 
	let s:var=system(s:command)
	return s:var
endfunction
if !exists("*Getpid")
function! Getpid()
	let s:var=s:getpid()
	if s:var != ""
		echomsg b:texcompiler . " pid " . s:var 
	else
		echomsg b:texcompiler . " is not running"
	endif
endfunction
endif
"}}}1
"{{{1 s:xpdfpid
if !exists("*s:xpdfpid")
function! s:xpdfpid() 
    let s:checkxpdf="ps -ef | grep -v grep | grep xpdf | grep '-remote '" . shellescape(b:XpdfServer) . " | awk '{print $2}'"
    return substitute(system(s:checkxpdf),'\D','','')
endfunction
endif
"}}}1
"{{{1 s:compare
function! s:compare(file)
    let l:buffer=getbufline(bufname("%"),"1","$")

    " rewrite l:buffer to remove all commands 
    let l:buffer=filter(l:buffer, 'v:val !~ "^\s*%"')

    let l:i = 0
    if g:atp_compare_double_empty_lines == 0 || g:atp_compare_embedded_comments == 0
    while l:i < len(l:buffer)-1
	let l:rem=0
	" remove comment lines at the end of a line
	if g:atp_compare_embedded_comments == 0
	    let l:buffer[l:i] = substitute(l:buffer[l:i],'%.*$','','')
	endif

	" remove double empty lines (i.e. from two conecutive empty lines
	" the first one is deleted, the second remains), if the line was
	" removed we do not need to add 1 to l:i (this is the role of
	" l:rem).
	if g:atp_compare_double_empty_lines == 0 && l:i< len(l:buffer)-2
	    if l:buffer[l:i] =~ '^\s*$' && l:buffer[l:i+1] =~ '^\s*$'
		call remove(l:buffer,l:i)
		let l:rem=1
	    endif
	endif
	if l:rem == 0
	    let l:i+=1
	endif
    endwhile
    endif
 
    " do the same with a:file
    let l:file=filter(a:file, 'v:val !~ "^\s*%"')

    let l:i = 0
    if g:atp_compare_double_empty_lines == 0 || g:atp_compare_embedded_comments == 0
    while l:i < len(l:file)-1
	let l:rem=0
	" remove comment lines at the end of a line
	if g:atp_compare_embedded_comments == 0
	    let l:file[l:i] = substitute(a:file[l:i],'%.*$','','')
	endif
	
	" remove double empty lines (i.e. from two conecutive empty lines
	" the first one is deleted, the second remains), if the line was
	" removed we do not need to add 1 to l:i (this is the role of
	" l:rem).
	if g:atp_compare_double_empty_lines == 0 && l:i < len(l:file)-2
	    if l:file[l:i] =~ '^\s*$' && l:file[l:i+1] =~ '^\s*$'
		call remove(l:file,l:i)
		let l:rem=1
	    endif
	endif
	if l:rem == 0
	    let l:i+=1
	endif
    endwhile
    endif

    return l:file !=# l:buffer
endfunction
"}}}1
"{{{1 s:copy
function! s:copy(input,output)
	call writefile(readfile(a:input),a:output)
endfunction
"}}}1
" {{{1 COMPILE FUNCTION s:compiler
" this variable =1 if s:compiler was called and tex has not finished.
" let b:atp_running=0
" This is the MAIN FUNCTION which sets the command and calls it.
" NOTE: the filename argument is not escaped!
function! s:compiler(bibtex,start,runs,verbose,command,filename)
    if has('clientserver')
	let b:atp_running=1
    endif
    call atplib#outdir()
    	" IF b:texcompiler is not compatible with the viewer
	if b:texcompiler =~ "^\s*pdf" && b:Viewer == "xdvi" ? 1 :  b:texcompiler !~ "^\s*pdf" && (b:Viewer == "xpdf" || b:Viewer == "epdfview" || b:Viewer == "acroread" || b:Viewer == "kpdf")
	     
	    echohl WaningMsg | echomsg "Your"b:texcompiler"and"b:Viewer"are not compatible:" 
	    echomsg "b:texcompiler=" . b:texcompiler	
	    echomsg "b:Viewer=" . b:Viewer	
	endif

	" there is no need to run more than s:runlimit (=5) consecutive runs
	" this prevents from running tex as many times as the current line
	" what can be done by a mistake using the range for the command.
	if a:runs > s:runlimit
	    let l:runs = s:runlimit
	else
	    let l:runs = a:runs
	endif

	let s:tmpdir=tempname()
	let s:tmpfile=atplib#append(s:tmpdir,"/") . fnamemodify(a:filename,":t:r")
" 	let b:tmpdir=s:tmpdir " DEBUG
	if exists("*mkdir")
	    call mkdir(s:tmpdir, "p", 0700)
	else
	    echoerr 'Your vim doesn't have mkdir function, there is a workaround this though. 
			\ Send an email to the author: mszamot@gmail.com '
	endif

	" SET THE NAME OF OUTPUT FILES
	" first set the extension pdf/dvi
	if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex"
	    let l:ext = ".pdf"
	else
	    let l:ext = ".dvi"	
	endif

	" check if the file is a symbolic link, if it is then use the target
	" name.
	let l:link=system("readlink " . a:filename)
	if l:link != ""
	    let l:basename=fnamemodify(l:link,":r")
	else
	    let l:basename=a:filename
	endif

	" finaly, set the the output file names. 
	let l:outfile = b:outdir . fnamemodify(l:basename,":t:r") . l:ext
	let l:outaux  = b:outdir . fnamemodify(l:basename,":t:r") . ".aux"
	let l:outlog  = b:outdir . fnamemodify(l:basename,":t:r") . ".log"

"	COPY IMPORTANT FILES TO TEMP DIRECTORY WITH CORRECT NAME 
	let l:list=filter(copy(g:keep),'v:val != "log"')
	for l:i in l:list
	    let l:ftc=b:outdir . fnamemodify(l:basename,":t:r") . "." . l:i
	    if filereadable(l:ftc)
		call s:copy(l:ftc,s:tmpfile . "." . l:i)
	    endif
	endfor

" 	HANDLE XPDF RELOAD 
	if b:Viewer == "xpdf"
	    if a:start == 1
		"if xpdf is not running and we want to run it.
		let s:xpdfreload = b:Viewer . " -remote " . shellescape(b:XpdfServer) . " " . shellescape(l:outfile)
	    else
		if s:xpdfpid() != ""
		    "if xpdf is running (then we want to reload it).
		    "This is where I use ps command to check if xpdf is
		    "running.
		    let s:xpdfreload = b:Viewer . " -remote " . shellescape(b:XpdfServer) . " -reload"	
		else
		    "if xpdf is not running (but we do not want
		    "to run it).
		    let s:xpdfreload = ""
		endif
	    endif
	else
	    if a:start == 1
		" if b:Viewer is not running and we want to open it.
		let s:xpdfreload = b:Viewer . " " . shellescape(l:outfile) 
	    else
		" if b:Viewer is not running then we do not want to
		" open it.
		let s:xpdfreload = ""
	    endif	
	endif
"  	echomsg "DEBUG xpdfreload="s:xpdfreload
" 	IF OPENINIG NON EXISTING OUTPUT FILE
"	only xpdf needs to be run before (we are going to reload it)
"	Check: THIS DO NOT WORKS!!!
	if a:start == 1 && b:Viewer == "xpdf"
	    let s:start = b:Viewer . " -remote " . shellescape(b:XpdfServer) . " " . b:ViewerOptions . " & "
	else
	    let s:start = ""	
	endif

"	SET THE COMMAND 
	let s:comp=b:texcompiler . " " . b:texoptions . " -interaction " . s:texinteraction . " -output-directory " . s:tmpdir . " " . fnameescape(a:filename)
	let s:vcomp=b:texcompiler . " " . b:texoptions  . " -interaction errorstopmode -output-directory " . s:tmpdir .  " " . fnameescape(a:filename)
	if a:verbose == 0 || l:runs > 1
	    let s:texcomp=s:comp
	else
	    let s:texcomp=s:vcomp
	endif
	if l:runs >= 2 && a:bibtex != 1
	    " how many times we wan to call b:texcompiler
	    let l:i=1
	    while l:i < l:runs - 1
		let l:i+=1
		let s:texcomp=s:texcomp . " ; " . s:comp
	    endwhile
	    if a:verbose == 0
		let s:texcomp=s:texcomp . " ; " . s:comp
	    else
		let s:texcomp=s:texcomp . " ; " . s:vcomp
	    endif
	endif
	
"  	    	echomsg "DEBUG X command s:texcomp=" s:texcomp
	if a:bibtex == 1
	    if filereadable(l:outaux)
		call s:copy(l:outaux,s:tmpfile . ".aux")
		let s:texcomp="bibtex " . s:tmpfile . ".aux ; " . s:comp . "  1>/dev/null 2>&1 "
	    else
		let s:texcomp=s:comp . " ; clear ; bibtex " . s:tmpfile . ".aux ; " . s:comp . " 1>/dev/null 2>&1 "
	    endif
	    if a:verbose != 0
		let s:texcomp=s:texcomp . " ; " . s:vcomp
	    else
		let s:texcomp=s:texcomp . " ; " . s:comp
	    endif
	endif

	let s:cpoption="--remove-destination "
	let s:cpoutfile="cp " . s:cpoption . shellescape(atplib#append(s:tmpdir,"/")) . "*" . l:ext . " " . shellescape(atplib#append(b:outdir,"/")) 
	if a:start
	    let s:command="(" . s:texcomp . " ; (" . s:cpoutfile . " ; " . s:xpdfreload . ") || (" . s:cpoutfile . ")" 
	else
	    let s:command="(" . s:texcomp . " && (" . s:cpoutfile . " ; " . s:xpdfreload . ") || (" . s:cpoutfile . ")" 
	endif
	let s:copy=""
	let l:j=1
	for l:i in g:keep 
" 	    ToDo: this can be don using internal vim functions.
	    let s:copycmd=" cp " . s:cpoption . " " . shellescape(atplib#append(s:tmpdir,"/")) . 
			\ "*." . l:i . " " . shellescape(atplib#append(b:outdir,"/"))  
" 	    let b:copycmd=s:copycmd " DEBUG
	    if l:j == 1
		let s:copy=s:copycmd
	    else
		let s:copy=s:copy . " ; " . s:copycmd	  
	    endif
	    let l:j+=1
	endfor
	    let s:command=s:command . " ; " . s:copy

	if has('clientserver') && v:servername != "" && g:atp_callback == 1
	    let s:command = s:command . ' ; vim --servername ' . v:servername . 
			\ ' --remote-send "<ESC>:let b:atp_running=0<CR>"'
" 	    in g:atp_debug_mode a copen window with list of errors is opened,
" 	    there is no need to run Show
	    let s:command = s:command . ' ; vim --servername ' . v:servername . 
			\ ' --remote-send "<ESC>:cg<CR>"'
" 	    Saving and preserving the mode doesn't work! Leaving in insert
" 	    mode neither.
	endif

 	let s:rmtmp="rm -r " . s:tmpdir 
	let s:command=s:command . " ; " . s:rmtmp . ")&"
	if a:start == 1 
	    let s:command=s:start . s:command
	endif
	let b:texcommand=s:command
	let s:backup=&backup
	let s:writebackup=&writebackup
	if a:command == "AU"  
	    if &backup || &writebackup | setlocal nobackup | setlocal nowritebackup | endif
	endif
	silent! w
	if a:command == "AU"  
	    let &l:backup=s:backup 
	    let &l:writebackup=s:writebackup 
	endif
	if a:verbose == 0
	    call system(s:command)
	else
" 	    let s:command="!clear;" . s:texcomp . " ; " . s:cpoutfile . " ; " . s:copy . " ; " . s:rmtmp
	    let s:command="!clear;" . s:texcomp . " ; " . s:cpoutfile . " ; " . s:copy 
	    exe s:command
	endif
	let b:texomp=s:texcomp
endfunction
"}}}1
" {{{1 s:auTeX
" To Do: we can now check if the last env is closed and run latex if it is, to
" not run latex if the 
function! s:auTeX()
   if b:autex
	" if the file (or input file is modified) compile the document 
	if filereadable(expand("%"))
	    if s:compare(readfile(expand("%")))

" 	let b:autex_debug=!g:atp_autex_check_if_closed || 
" 	    \ (!atplib#CheckClosed('\\begin\s*{','\\end\s*{',line("."),g:atp_completion_limits[2],1) &&
" 	    \  !atplib#CheckClosed(g:atp_math_modes[0][0],g:atp_math_modes[0][1],line("."),g:atp_completion_limits[0],1) &&
" 	    \  !atplib#CheckClosed(g:atp_math_modes[1][0],g:atp_math_modes[1][1],line("."),g:atp_completion_limits[1],1))
" 
" 		if !g:atp_autex_check_if_closed || 
" 		    \ (!atplib#CheckClosed('\\begin\s*{','\\end\s*{',line("."),g:atp_completion_limits[2],1) &&
" 		    \  !atplib#CheckClosed(g:atp_math_modes[0][0],g:atp_math_modes[0][1],line("."),g:atp_completion_limits[0],1) &&
" 		    \  !atplib#CheckClosed(g:atp_math_modes[1][0],g:atp_math_modes[1][1],line("."),g:atp_completion_limits[1],1))
		    call s:compiler(0,0,b:auruns,0,"AU",b:atp_mainfile)
		    redraw
		    return "compile" 
" 		endif
	    endif
	else

" 	let b:autex_debug=!g:atp_autex_check_if_closed || 
" 	    \ (!atplib#CheckClosed('\\begin\s*{','\\end\s*{',line("."),g:atp_completion_limits[2],1) &&
" 	    \  !atplib#CheckClosed(g:atp_math_modes[0][0],g:atp_math_modes[0][1],line("."),g:atp_completion_limits[0],1) &&
" 	    \  !atplib#CheckClosed(g:atp_math_modes[1][0],g:atp_math_modes[1][1],line("."),g:atp_completion_limits[1],1))

" 	    if !g:atp_autex_check_if_closed ||
" 		\ (!atplib#CheckClosed('\\begin\s*{','\\end\s*{',line("."),g:atp_completion_limits[2],1) &&
" 		\  !atplib#CheckClosed('\(','\)',line("."),g:atp_completion_limits[0],1) &&
" 		\  !atplib#CheckClosed('\[','\]',line("."),g:atp_completion_limits[1],1))
		call s:compiler(0,0,b:auruns,0,"AU",b:atp_mainfile)
		redraw
		return "compile first time"
" 	    endif
	endif
	return "file does not differ"
   endif
   return "autex is off"
endfunction
if !exists('#CursorHold#' . $HOME . '/*.tex')
    au CursorHold *.tex call s:auTeX()
endif
"}}}1
" {{{1 TEX
if !exists("*TEX")
function! TEX(...)
let s:name=tempname()
if a:0 >= 1
    if a:1 > 2 && a:1 <= 5
	echomsg b:texcompiler . " will run " . a:1 . " times."
    elseif a:1 == 2
	echomsg b:texcompiler . " will run twice."
    elseif a:1 == 1
	echomsg b:texcompiler . " will run once."
    elseif a:1 > 5
	echomsg b:texcompiler . " will run " . s:runlimit . " times."
    endif
    call s:compiler(0,0,a:1,0,"COM",b:atp_mainfile)
elseif a:0 == 0
    call s:compiler(0,0,1,0,"COM",b:atp_mainfile)
endif
endfunction
endif
"}}}1

" {{{1 ToggleAuTeX
" command! -buffer -count=1 TEX	:call TEX(<count>)		 
if !exists("*ToggleAuTeX")
function! ToggleAuTeX()
  if b:autex != 1
    let b:autex=1	
    echo "automatic tex processing is ON"
  else
    let b:autex=0
    echo "automatic tex processing is OFF"
endif
endfunction
endif
"}}}1
"{{{1 VTEX
if !exists("*VTEX")
function! VTEX(...)
    let s:name=tempname()
if a:0 >= 1
    if a:1 > 2
	echomsg b:texcompiler . " will run " . a:1 . " times."
    elseif a:1 == 2
	echomsg b:texcompiler . " will run twice."
    elseif a:1 == 1
	echomsg b:texcompiler . " will run once."
    endif
    sleep 1
    call s:compiler(0,0,a:1,1,"COM",b:atp_mainfile)
else
    call s:compiler(0,0,1,1,"COM",b:atp_mainfile)
endif
endfunction
endif
"}}}1
"{{{1 Bibtex
if !exists("*SimpleBibtex")
function! SimpleBibtex()
    call atplib#outdir() 
    let l:bibcommand="bibtex "
    let l:auxfile=b:outdir . (fnamemodify(expand("%"),":t:r")) . ".aux"
    if filereadable(l:auxfile)
	let l:command=l:bibcommand . shellescape(l:auxfile)
	echo system(l:command)
    else
	echomsg "No aux file in " . b:outdir
    endif
"  	!clear;if [[ -h "%" ]];then realname=`readlink "%"`;realdir=`dirname "$realname"`;b_name=`basename "$realname" .tex`;else realdir="%:p:h";b_name="%:r";fi;bibtex "$realdir/$b_name".aux
endfunction
endif
if !exists("*Bibtex")
function! Bibtex(...)
    let s:bibname=tempname()
    let s:auxf=s:bibname . ".aux"
    if a:0 == 0
"  	    echomsg "DEBUG Bibtex"
	call s:compiler(1,0,0,0,"COM",b:atp_mainfile)
    else
"  	    echomsg "DEBUG Bibtex verbose"
	call s:compiler(1,0,0,1,"COM",b:atp_mainfile)
    endif
endfunction
endif
"}}}1

"{{{1 Delete
if !exists("*Delete")
function! Delete()
    call atplib#outdir()
    let l:atp_tex_extensions=deepcopy(g:atp_tex_extensions)
    let s:error=0
    if g:atp_delete_output
	if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex"
	    let l:ext="pdf"
	else
	    let l:ext="dvi"
	endif
	call add(l:atp_tex_extensions,l:ext)
    endif
    for l:ext in l:atp_tex_extensions
	if executable(g:rmcommand)
	    if g:rmcommand =~ "^\s*rm\p*" || g:rmcommand =~ "^\s*perltrash\p*"
		if l:ext != "dvi" && l:ext != "pdf"
		    let l:rm=g:rmcommand . " " . shellescape(b:outdir) . "*." . l:ext . " 2>/dev/null && echo Removed ./*" . l:ext . " files"
		else
		    let l:rm=g:rmcommand . " " . fnamemodify(b:atp_mainfile,":r").".".l:ext . " 2>/dev/null && echo Removed " . fnamemodify(b:atp_mainfile,":r").".".l:ext
		endif
	    endif
" 	    echomsg "DEBUG " l:rm
	echo system(l:rm)
	else
	    let s:error=1
		let l:file=b:outdir . fnamemodify(expand("%"),":t:r") . "." . l:ext
		if delete(l:file) == 0
		    echo "Removed " . l:file 
		endif
	endif
    endfor


" 	if s:error
" 		echo "Pleas set g:rmcommand to clear the working directory"
" 	endif
endfunction
endif
"}}}1
"{{{1 OpenLog, TexLog, TexLog Buffer Options, PdfFonts, YesNoCompletion
if !exists("*OpenLog")
function! OpenLog()
    if filereadable(&l:errorfile)
	exe "tabe +set\\ nospell\\ ruler " . &l:errorfile
    else
	echo "No log file"
    endif
endfunction
endif

" TeX LOG FILE
if &buftype == 'quickfix'
	setlocal modifiable
	setlocal autoread
endif	
if !exists("*TexLog")
function! TexLog(options)
    if executable("texloganalyser")
       let s:command="texloganalyser " . a:options . " " . &l:errorfile
       echo system(s:command)
    else	
       echo "Please install 'texloganalyser' to have this functionality. The perl program written by Thomas van Oudenhove."  
    endif
endfunction
endif

if !exists("*PdfFonts")
function! PdfFonts()
    if b:outdir !~ "\/$"
	b:outdir=b:outdir . "/"
    endif
    if executable("pdffonts")
	let s:command="pdffonts " . fnameescape(fnamemodify(b:atp_mainfile,":r")) . ".pdf"
	echo system(s:command)
    else
	echo "Please install 'pdffonts' to have this functionality. In 'gentoo' it is in the package 'app-text/poppler-utils'."  
    endif
endfunction	
endif

" function! s:setprintexpr()
"     if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex"
" 	let s:ext = ".pdf"
"     else
" 	let s:ext = ".dvi"	
"     endif
"     let &printexpr="system('lpr' . (&printdevice == '' ? '' : ' -P' . &printdevice) . ' " . fnameescape(fnamemodify(expand("%"),":p:r")) . s:ext . "') . + v:shell_error"
" endfunction
" call s:setprintexpr()

fun! YesNoCompletion(A,P,L)
    return ['yes','no']
endfun
"}}}1
"{{{1 Print, Lpstat, ListPrinters
if !exists("*Print")
function! Print(...)

    call atplib#outdir()

    " set the extension of the file to print
    if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex" 
	let l:ext = ".pdf"
    elseif b:texcompiler =~ "lua"
	if b:texoptions == "" || b:texoptions =~ "output-format=\s*pdf"
	    let l:ext = ".pdf"
	else
	    let l:ext = ".dvi"
	endif
    else
	let l:ext = ".dvi"	
    endif

    " set the file to print
    let l:pfile=b:outdir . fnameescape(fnamemodify(expand("%"),":t:r")) . l:ext
    let b:pfile=l:pfile

    " set the printing command
    let l:lprcommand="lpr "
    if a:0 >= 2
	let l:lprcommand.= " " . a:2
    endif

    " print locally or remotely
    " the default is to print locally (g:atp_ssh=`whoami`@localhost)
    if exists("g:atp_ssh") 
	let l:server=strpart(g:atp_ssh,stridx(g:atp_ssh,"@")+1)
    else
	let l:server='localhost'
    endif
    echomsg "SERVER " . l:server
    let b:server=l:server
    if l:server =~ 'localhost'
	if g:printingoptions != "" || (a:0 >= 2 && a:2 != "")
	    if a:0 < 2
		let l:message=g:printingoptions
	    else
		let l:message=a:2
	    endif
	    " TODO: write completion :).
	    let l:ok = confirm("Are the printing options set right?\n".l:message,"&Yes\n&No\n&Cancel")
	    if l:ok == "1" 
		if a:0 <= 1
		    let l:printingoptions=g:printingoptions
		else
		    let l:printingoptions=a:2
		endif
	    elseif l:ok == "2"
		let l:printingoptions=input("Give printing options ")
	    elseif l:ok == "3"
		return 0
	    endif
	else
	    let l:printingoptions=""
	endif
	if a:0 == 0 || (a:0 != 0 && a:1 == 'default')
	    let l:com=l:lprcommand . " " . l:printingoptions . " " .  fnameescape(l:pfile)
	else
	    let l:com=l:lprcommand . " " . l:printingoptions . " -P " . a:1 . " " . fnameescape(l:pfile) 
	endif
	redraw!
	echomsg "Printing ...  " . l:com
" 	let b:com=l:com " DEBUG
	call system(l:com)
    " print over ssh on the server g:atp_ssh with the printer a:1 (or the
    " default system printer if a:0 == 0
    else 
	if a:0 == 0 || (a:0 != 0 && a:1 =~ 'default')
	    let l:com="cat " . fnameescape(l:pfile) . " | ssh " . g:atp_ssh . " " . l:lprcommand
	else
	    let l:com="cat " . fnameescape(l:pfile) . " | ssh " . g:atp_ssh . " " . l:lprcommand . " -P " . a:1 
	endif
	if g:printingoptions != "" || (a:0 >= 2 && a:2 != "")
	    if a:0 < 2
		let l:message=g:printingoptions
	    else
		let l:message=a:2
	    endif
	    " TODO: write completion :).
	    let l:ok = confirm("Are the printing options set right?\n".l:message,"&Yes\n&No\n&Cancel")
	    if l:ok == "1" 
		if a:0 <= 1
		    let l:printingoptions=g:printingoptions
		else
		    let l:printingoptions=a:2
		endif
	    elseif l:ok == "2"
		let l:printingoptions=input("Give printing options ")
	    elseif l:ok == "3"
		return 0
	    endif
	else
	    let l:printingoptions=""
	endif
	let l:com = l:com . " " . l:printingoptions
	redraw!
	echomsg "Printing ...  " . l:com
	call system(l:com)
    endif
endfunction
endif

fun! Lpstat()
    if exists("g:apt_ssh") 
	let l:server=strpart(g:atp_ssh,stridx(g:atp_ssh,"@")+1)
    else
	let l:server='locahost'
    endif
    if l:server == 'localhost'
	echo system("lpstat -l")
    else
	echo system("ssh " . g:atp_ssh . " lpstat -l ")
    endif
endfunction

" it is used for completetion of the command SshPrint
if !exists("*ListPrinters")
function! ListPrinters(A,L,P)
    if exists("g:atp_ssh") && g:atp_ssh !~ '@localhost' && g:atp_ssh != ""
	let l:com="ssh -q " . g:atp_ssh . " lpstat -a | awk '{print $1}'"
    else
	let l:com="lpstat -a | awk '{print $1}'"
    endif
    return system(l:com)
endfunction
endif
"}}}1

"{{{1 BibSearch
"-------------SEARCH IN BIBFILES ----------------------
" This function counts accurence of a:keyword in string a:line, 
" there are two methods keyword is a string to find (a:1=0)or a pattern to
" match, the pattern used to is a:keyword\zs.* to find the place where to cut.
" DEBUG:
" command -buffer -nargs=* Count :echo atplib#count(<args>)

let g:bibentries=['article', 'book', 'booklet', 'conference', 'inbook', 'incollection', 'inproceedings', 'manual', 'mastertheosis', 'misc', 'phdthesis', 'proceedings', 'techreport', 'unpublished']


"{{{2 variables
let g:bibmatchgroup='String'
let g:defaultbibflags='tabejsyu'
let g:defaultallbibflags='tabejfsvnyPNSohiuHcp'
let b:lastbibflags=g:defaultbibflags	" Set the lastflags variable to the default value on the startup.
let g:bibflagsdict=atplib#bibflagsdict
" These two variables were s:... but I switched to atplib ...
let g:bibflagslist=keys(g:bibflagsdict)
let g:bibflagsstring=join(g:bibflagslist,'')
let g:kwflagsdict={ 	  '@a' : '@article', 	'@b' : '@book\%(let\)\@<!', 
			\ '@B' : '@booklet', 	'@c' : '@in\%(collection\|book\)', 
			\ '@m' : '@misc', 	'@M' : '@manual', 
			\ '@p' : '@\%(conference\)\|\%(\%(in\)\?proceedings\)', 
			\ '@t' : '@\%(\%(master)\|\%(phd\)\)thesis', 
			\ '@T' : '@techreport', '@u' : '@unpublished'}    

" Set the g:{b:Viewer}Options as b:ViewerOptions for the current buffer
"}}}2
fun! s:set_viewer_options()
    if exists("b:Viewer") && exists("g:" . b:Viewer . "Options")
	let b:ViewerOptions=g:{b:Viewer}Options
    endif
endfun
au BufEnter *.tex :call s:set_viewer_options()

" Hilighlting
hi link BibResultsFileNames 	Title	
hi link BibResultEntry		ModeMsg
hi link BibResultsMatch		WarningMsg
hi link BibResultsGeneral	Normal


hi link Chapter 			Normal	
hi link Section			Normal
hi link Subsection		Normal
hi link Subsubsection		Normal
hi link CurrentSection		WarningMsg


if !exists("*BibSearch")
"  There are three arguments: {pattern}, [flags, [choose]]
function! BibSearch(...)
    if a:0 == 0
	let l:bibresults=atplib#searchbib('')
	let b:listofkeys=atplib#showresults(l:bibresults,'','')
    elseif a:0 == 1
	let l:bibresults=atplib#searchbib(a:1)
	let b:listofkeys=atplib#showresults(l:bibresults,'',a:1)
    else
	let l:bibresults=atplib#searchbib(a:1)
	let b:listofkeys=atplib#showresults(l:bibresults,a:2,a:1)
    endif
endfunction
endif
" }}}1
" {{{1 TOC
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
" It makes t:toc - a dictionary (with keys: full path of the buffer name)
" which values are dictionaries which keys are: line numbers and values lists:
" [ 'section-name', 'number', 'title'] where section name is element of
" keys(g:atp_sections), number is the total number, 'title=\1' where \1 is
" returned by the g:section['key'][0] pattern.
" {{{2 Maketoc /new function/
function! Maketoc(filename)
    let l:toc={}
    " if the dictinary with labels is not defined, define it
    if !exists("t:labels")
	let t:labels={}
    endif
    " TODO we could check if there are changes in the file and copy the buffer
    " to this variable only if there where changes.
    let l:auxfile=[]
    " getbufline reads only loaded buffers, unloaded can be read from file.
    let l:auxfname=fnamemodify(a:filename,":r").'.aux'
    if filereadable(l:auxfname)
	let l:auxfile=readfile(l:auxfname)
    else
	echohl WarningMsg
	echomsg "No aux file, run ".b:texcompiler."."
	echohl Normal
    endif
    call filter(l:auxfile,' v:val =~ "\\\\@writefile{toc}"') 
"     while l:line in l:auxfile
    for l:line in l:auxfile
	let l:sec_unit=matchstr(l:line,'\\contentsline\s*{\zs[^}]*\ze}')
	let l:sec_number=matchstr(l:line,'\\numberline\s*{\zs[^}]*\ze}')
" 	echomsg l:sec_number
	" To Do: how to match the long_title
	let l:long_title=matchstr(l:line,'\\contentsline\s*{[^}]*}{\%(\\numberline\s*{[^}]*}\)\?\s*\zs.*') 
	if l:long_title =~ '\\GenericError'
	    let l:long_title=substitute(l:long_title,'\\GenericError\s*{[^}]*}{[^}]*}{[^}]*}{[^}]*}','','g')
	endif
	if l:long_title =~ '\\relax\s'
	    let l:long_title=substitute(l:long_title,'\\relax\s','','g')
	endif	   
	if l:long_title =~ '\\unhbox '
	    let l:long_title=substitute(l:long_title,'\\unhbox\s','','g')
	endif	   
	if l:long_title =~ '\\nobreakspace'
	    let l:long_title=substitute(l:long_title,'\\nobreakspace\s*{}',' ','g')
	endif	   
	let l:i=0
	let l:braces=0
	while l:braces >= 0 && l:i < len(l:long_title)
	    if l:long_title[l:i] == '{'
		let l:braces+=1
	    elseif l:long_title[l:i] == '}'
		let l:braces-=1
	    endif
	    let l:i+=1
	endwhile
" 	echo "len " len(l:long_title) . " l:i" . l:i
	let l:long_title=strpart(l:long_title,0,l:i-1)

" 	let l:star_c=matchstr(l:line,'\\contentsline\s*{[^}]*}{\%(\\numberline\s*{[^}]*}\)\?\s*\%([^}]*\|{[^}]*}\)*}{\zs[^}]*\ze}')
	let l:star_version= l:line =~ l:sec_unit.'\*'

	" find line number in the current tex file (this is not the best!) we
	" should check if we are in mainfile.
	let l:line_nr=search('\\'.l:sec_unit.'.*'.l:long_title,'n')
	let l:tex_line=getline(l:line_nr)
" 	echomsg "tex_line=".l:tex_line."sec_unit=".l:sec_unit." sec_number=".l:sec_number." l:long_title=".l:long_title." star=".l:star_version 
	" find short title
	let l:short_title=l:line
	let l:start=stridx(l:short_title,'[')+1
	if l:start == 0
	    let l:short_title=''
	else
	    let l:short_title=strpart(l:short_title,l:start)
	    " we are looking for the maching ']' 
	    let l:count=1
	    let l:i=-1
	    while l:i<=len(l:short_title)
		let l:i+=1
		if strpart(l:short_title,l:i,1) == '['	
		    let l:count+=1
		elseif strpart(l:short_title,l:i,1) == ']'
		    let l:count-=1
		endif
		if l:count==0
		    break
		endif
	    endwhile	
	    let l:short_title=strpart(l:short_title,0,l:i)
	endif
	call extend(l:toc, { l:line_nr : [l:sec_unit, l:sec_number, l:long_title, l:star_version, l:short_title] }) 
    endfor
    let t:toc_new={ a:filename : l:toc }
    return t:toc_new
endfunction
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
" {{{2 MAKETOC
function! MAKETOC(filename)
    
    " this will store information { 'linenumber' : ['chapter/section/..', 'sectionnumber', 'section title', '0/1=not starred/starred'] }
    let l:toc={}

    " if the dictinary with labels is not defined, define it
    if !exists("t:labels")
	let t:labels={}
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

		    " Extend t:labels
		    let l:lname=matchstr(l:line,'\\label\s*{.*','')
		    let l:start=stridx(l:lname,'{')+1
		    let l:lname=strpart(l:lname,l:start)
		    let l:end=stridx(l:lname,'}')
		    let l:lname=strpart(l:lname,0,l:end)
" 		    let b:lname=l:lname
		    if	l:lname != ''
			" if there was no t:labels for a:filename make an entry in
			" t:labels
			if !has_key(t:labels,a:filename)
			    let t:labels[a:filename] = {}
			endif
			call extend(t:labels[a:filename],{ l:tline : l:lname },"force")
		    endif
		endif
	    endif
	endfor
    endfor
    if exists("t:toc")
	call extend(t:toc, { a:filename : l:toc },"force")
    else
	let t:toc={ a:filename : l:toc }
    endif
    return t:toc
endfunction
" }}}2
" {{{2 Make a List of Buffers
if !exists("t:buflist")
    let t:buflist=[]
endif
function! s:buflist()
    " this names are used in TOC and passed to s:maketoc, which
    " makes a dictionary whose keys are the values of l:name defined here
    " below:
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
" {{{2 Show TOC
function! s:showtoc(toc,...)
    let l:new=0
    if a:0 == 1
	let l:new=a:1
    endif
    " this is a dictionary of line numbers where a new file begins.
    let l:cline=line(".")
"     " Open new window or jump to the existing one.
"     " Remember the place from which we are coming:
"     let t:bufname=bufname("")
"     let t:winnr=winnr()	 these are already set by TOC()
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
    " first get the line number of the begging of the ToC of t:bufname
    " (current buffer)
" 	let t:numberdict=l:numberdict	"DEBUG
" 	t:bufname is the full path to the current buffer.
    let l:num=l:numberdict[t:bufname]
    let l:sorted=sort(keys(a:toc[t:bufname]),"atplib#CompareList")
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
"{{{2 TOC
if !exists("*TOC")
function! TOC(...)
    " skip generating t:toc list if it exists and if a:0 != 0
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
    if l:skip == 0 || ( l:skip == 1 && !exists("t:toc") )
	for l:buffer in t:buflist 
    " 	    let t:toc=Maketoc(l:buffer)
		let t:toc=MAKETOC(l:buffer)
	endfor
    endif
    call s:showtoc(t:toc,l:new)
endfunction
endif
" }}}2
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
" {{{3 s:CTOC
function! s:CTOC()
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
    let t:bufname=resolve(fnamemodify(bufname("%"),":p"))
    
    " if t:toc(t:bufname) exists use it otherwise make it 
    if !exists("t:toc") || !has_key(t:toc,t:bufname) 
	silent let t:toc=MAKETOC(t:bufname)
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

    for l:key in keys(t:toc[t:bufname])
	if t:toc[t:bufname][l:key][0] == 'chapter'
	    " return the short title if it is provided
	    if t:toc[t:bufname][l:key][4] != ''
		call extend(l:chapter, {l:key : t:toc[t:bufname][l:key][4]},'force')
	    else
		call extend(l:chapter, {l:key : t:toc[t:bufname][l:key][2]},'force')
	    endif
	elseif t:toc[t:bufname][l:key][0] == 'section'
	    " return the short title if it is provided
	    if t:toc[t:bufname][l:key][4] != ''
		call extend(l:section, {l:key : t:toc[t:bufname][l:key][4]},'force')
	    else
		call extend(l:section, {l:key : t:toc[t:bufname][l:key][2]},'force')
	    endif
	elseif t:toc[t:bufname][l:key][0] == 'subsection'
	    " return the short title if it is provided
	    if t:toc[t:bufname][l:key][4] != ''
		call extend(l:subsection, {l:key : t:toc[t:bufname][l:key][4]},'force')
	    else
		call extend(l:subsection, {l:key : t:toc[t:bufname][l:key][2]},'force')
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
if !exists("*CTOC")
    function CTOC(...)
	" if there is any argument given, then the function returns the value
	" (used by ATPStatus()), otherwise it echoes the section/subsection
	" title. It returns only the first b:truncate_status_section
	" characters of the the whole titles.
	let l:names=s:CTOC()
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
		    return substitute(strpart(l:chapter_name,0,b:truncate_status_section/2), '\_s*$', '','') . "/" . substitute(strpart(l:section_name,0,b:truncate_status_section/2), '\_s*$', '','')
		endif
	    else
" 		if a:0 == '0'
" 		    echo "XXX" . l:chapter_name
" 		else
		if a:0 != 0
		    return substitute(strpart(l:chapter_name,0,b:truncate_status_section), '\_s*$', '','')
		endif
	    endif

	elseif l:chapter_name == "" && l:section_name != ""
	    if l:subsection_name != ""
" 		if a:0 == '0'
" 		    echo "XXX" . l:section_name . "/" . l:subsection_name 
" 		else
		if a:0 != 0
		    return substitute(strpart(l:section_name,0,b:truncate_status_section/2), '\_s*$', '','') . "/" . substitute(strpart(l:subsection_name,0,b:truncate_status_section/2), '\_s*$', '','')
		endif
	    else
" 		if a:0 == '0'
" 		    echo "XXX" . l:section_name
" 		else
		if a:0 != 0
		    return substitute(strpart(l:section_name,0,b:truncate_status_section), '\_s*$', '','')
		endif
	    endif

	elseif l:chapter_name == "" && l:section_name == "" && l:subsection_name != ""
" 	    if a:0 == '0'
" 		echo "XXX" . l:subsection_name
" 	    else
	    if a:0 != 0
		return substitute(strpart(l:subsection_name,0,b:truncate_status_section), '\_s*$', '','')
	    endif
	endif
    endfunction
endif
" }}}3
" }}}2
" }}}1
" {{{1 Labels
if !exists("*Labels")
function! Labels()
    let t:bufname=bufname("%")
    let l:bufname=resolve(fnamemodify(t:bufname,":p"))
    " Generate the dictionary with labels
    let t:labels=atplib#generatelabels(l:bufname)
    " Show the labels in seprate window
    call atplib#showlabels(t:labels[l:bufname])
endfunction
endif
" }}}1
" {{{1 Edit Input Files 
if !exists("*EditInputFile")
function! EditInputFile(...)

    let l:mainfile=b:atp_mainfile

    if a:0 == 0
	let l:inputfile=""
	let l:bufname=b:atp_mainfile
	let l:opencom="edit"
    elseif a:0 == 1
	let l:inputfile=a:1
	let l:bufname=b:atp_mainfile
	let l:opencom="edit"
    else
	let l:inputfile=a:1
	let l:opencom=a:2

	" the last argument is the bufername in which search for the input files 
	if a:0 > 2
	    let l:bufname=a:3
	else
	    let l:bufname=b:atp_mainfile
	endif
    endif

    let l:dir=fnamemodify(b:atp_mainfile,":p:h")

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
"     if l:ifile == fnamemodify(b:atp_mainfile,":t")
" 	let l:ifile=b:atp_mainfile
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
	let l:ifilename=b:atp_mainfile
    endif
    if l:ifile !~ '\s*\/'
	if filereadable(l:dir . "/" . l:ifilename) 
	    let s:ft=&filetype
	    exe "edit " . fnameescape(b:outdir . l:ifilename)
	    let &l:filetype=s:ft
	else
	    if l:inputfiles[l:ifile][0] == 'input' || l:inputfiles[l:ifile][0] == 'include'
		let l:ifilename=findfile(l:ifile,g:texmf . '**')
		let s:ft=&filetype
		exe l:opencom . " " . fnameescape(l:ifilename)
		let &l:filetype=s:ft
		let b:atp_mainfile=l:mainfile
	    elseif l:inputfiles[l:ifile][0] == 'bib' 
		let s:ft=&filetype
		exe l:opencom . " " . l:inputfiles[l:ifile][2]
		let &l:filetype=s:ft
		let b:atp_mainfile=l:mainfile
	    elseif  l:inputfiles[l:ifile][0] == 'main file' 
		exe l:opencom . " " . b:atp_mainfile
		let b:atp_mainfile=l:mainfile
	    endif
	endif
    else
	exe l:opencom . " " . fnameescape(l:ifilename)
	let b:atp_mainfile=l:mainfile
    endif
endfunction
endif

if !exists("*EI_compl")
fun! EI_compl(A,P,L)
"     let l:inputfiles=FindInputFiles(bufname("%"),1)

    let l:inputfiles=filter(FindInputFiles(b:atp_mainfile,1), 'v:key !~ fnamemodify(bufname("%"),":t:r")')
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
endif
" }}}1
" {{{1 ToDo
"
" TODO if the file was not found ask to make one.
function! ToDo(keyword,stop,...)

    if a:0==0
	let l:bufname=bufname("%")
    else
	let l:bufname=a:1
    endif

    " read the buffer
    let l:texfile=getbufline(l:bufname, 1, "$")

    " find ToDos
    let b:todo={}
    let l:nr=1
    for l:line in l:texfile
	if l:line =~ '%.*' . a:keyword 
	    call extend(b:todo, { l:nr : l:line }) 
	endif
	let l:nr+=1
    endfor

    " Show ToDos
    echohl atp_Todo
    if len(keys(b:todo)) == 0
	echomsg " List for '%.*" . a:keyword . "' in '" . l:bufname . "' is empty."
	return
    endif
    echomsg " List for '%.*" . a:keyword . "' in '" . l:bufname . "':"
    let l:sortedkeys=sort(keys(b:todo),"atplib#CompareList")
    for l:key in l:sortedkeys
	" echo the todo line.
	echomsg l:key . " " . substitute(substitute(b:todo[l:key],'%','',''),'\t',' ','g')
	let l:true=1
	let l:a=1
	let l:linenr=l:key
	" show all comment lines right below the found todo line.
	while l:true && l:texfile[l:linenr] !~ '%.*\c\<todo\>' 
	    let l:linenr=l:key+l:a-1
	    if l:texfile[l:linenr] =~ "\s*%" && l:texfile[l:linenr] !~ a:stop
		" make space of length equal to len(l:linenr)
		let l:space=""
		let l:j=0
		while l:j < len(l:linenr)
		    let l:space=l:space . " " 
		    let l:j+=1
		endwhile
		echomsg l:space . " " . substitute(substitute(l:texfile[l:linenr],'%','',''),'\t',' ','g')
	    else
		let l:true=0
	    endif
	    let l:a+=1
	endwhile
    endfor
    echohl None
endfunction
" }}}1
" {{{1 FOLDING (not working}
" "
" let s:a=0
" function! FoldExpr(line)
"     let s:a+=1
" "     echomsg "DEBUG " . s:a " at line " . a:line
" 
"     call MAKETOC(fnamemodify(bufname("%"),":p"))
"     let l:line=a:line
" 
"     " make a fold of the preambule /now this folds too much/
"     let l:sorted=sort(keys(t:toc[fnamemodify(bufname("%"),":p")]),"atplib#CompareList")
"     if a:line < l:sorted[0]
" 	return 1
"     endif
" 
"     let l:secname=""
"     while l:secname == ""  
" 	let l:secname=get(t:toc[fnamemodify(bufname("%"),":p")],l:line,'')[0]
" 	let l:line-=1
"     endwhile
"     let l:line+=1
"     if l:secname == 'part'
" 	return 1
"     elseif l:secname == 'chapter'
" 	return 2
"     elseif l:secname == 'section'
" 	return 3
"     elseif l:secname == 'subsection'
" 	return 4
"     elseif l:secname == 'subsubsection'
" 	return 5
"     elseif l:secname == 'paragraph'
" 	return 6
"     elseif l:secname == 'subparagraph'
" 	return 7
"     else 
" 	return 0
"     endif
" endfunction
" setlocal foldmethod=expr
" foldmethod=marker do not work in preamble as there might appear
" } } } (spaces are for vim)
" this folds entire document with one fold when there are only sections
" it is thus not a good method of folding.
" setlocal foldexpr=FoldExpr(v:lnum)
" }}}1
" {{{1 SHOW ERRORS
"
" this functions sets errorformat according to the flag given in the argument,
" possible flags:
" e	- errors (or empty flag)
" w	- all warning messages
" c	- citasion warning messages
" r	- reference warning messages
" f	- font warning messages
" fi	- font warning and info messages
" F	- files
" p	- package info messages
function! s:SetErrorFormat(...)
    let &l:errorformat=""
    if a:0 == 0 || a:0 > 0 && a:1 =~ 'e'
	if &l:errorformat == ""
	    let &l:errorformat= "%E!\ LaTeX\ %trror:\ %m,\%E!\ %m"
	else
	    let &l:errorformat= &l:errorformat . ",%E!\ LaTeX\ %trror:\ %m,\%E!\ %m"
	endif
    endif
    if a:0>0 && a:1 =~ 'w'
	if &l:errorformat == ""
	    let &l:errorformat='%WLaTeX\ %tarning:\ %m\ on\ input\ line\ %l%.,
			\%WLaTeX\ %.%#Warning:\ %m,
	    		\%Z(Font) %m\ on\ input\ line\ %l%.,
			\%+W%.%#\ at\ lines\ %l--%*\\d'
	else
	    let &l:errorformat= &l:errorformat . ',%WLaTeX\ %tarning:\ %m\ on\ input\ line\ %l%.,
			\%WLaTeX\ %.%#Warning:\ %m,
	    		\%Z(Font) %m\ on\ input\ line\ %l%.,
			\%+W%.%#\ at\ lines\ %l--%*\\d'
" 	    let &l:errorformat= &l:errorformat . ',%+WLaTeX\ %.%#Warning:\ %.%#line\ %l%.%#,
" 			\%WLaTeX\ %.%#Warning:\ %m,
" 			\%+W%.%#\ at\ lines\ %l--%*\\d'
	endif
    endif
    if a:0>0 && a:1 =~ '\Cc'
" NOTE:
" I would like to include 'Reference/Citation' as an error message (into %m)
" but not include the 'LaTeX Warning:'. I don't see how to do that actually. 
" The only solution, that I'm aware of, is to include the whole line using
" '%+W' but then the error messages are long and thus not readable.
	if &l:errorformat == ""
	    let &l:errorformat = "%WLaTeX\ Warning:\ Citation\ %m\ on\ input\ line\ %l%.%#"
	else
	    let &l:errorformat = &l:errorformat . ",%WLaTeX\ Warning:\ Citation\ %m\ on\ input\ line\ %l%.%#"
	endif
    endif
    if a:0>0 && a:1 =~ '\Cr'
	if &l:errorformat == ""
	    let &l:errorformat = "%WLaTeX\ Warning:\ Reference %m on\ input\ line\ %l%.%#,%WLaTeX\ %.%#Warning:\ Reference %m,%C %m on input line %l%.%#"
	else
	    let &l:errorformat = &l:errorformat . ",%WLaTeX\ Warning:\ Reference %m on\ input\ line\ %l%.%#,%WLaTeX\ %.%#Warning:\ Reference %m,%C %m on input line %l%.%#"
	endif
    endif
    if a:0>0 && a:1 =~ '\Cf'
	if &l:errorformat == ""
	    let &l:errorformat = "%WLaTeX\ Font\ Warning:\ %m,%Z(Font) %m on input line %l%.%#"
	else
	    let &l:errorformat = &l:errorformat . ",%WLaTeX\ Font\ Warning:\ %m,%Z(Font) %m on input line %l%.%#"
	endif
    endif
    if a:0>0 && a:1 =~ '\Cfi'
	if &l:errorformat == ""
	    let &l:errorformat = '%ILatex\ Font\ Info:\ %m on input line %l%.%#,
			\%ILatex\ Font\ Info:\ %m,
			\%Z(Font) %m\ on input line %l%.%#,
			\%C\ %m on input line %l%.%#'
	else
	    let &l:errorformat = &l:errorformat . ',%ILatex\ Font\ Info:\ %m on input line %l%.%#,
			\%ILatex\ Font\ Info:\ %m,
			\%Z(Font) %m\ on input line %l%.%#,
			\%C\ %m on input line %l%.%#'
	endif
    endif
    if a:0>0 && a:1 =~ '\CF'
	if &l:errorformat == ""
	    let &l:errorformat = 'File: %m'
	else
	    let &l:errorformat = &l:errorformat . ',File: %m'
	endif
    endif
    if a:0>0 && a:1 =~ '\Cp'
	if &l:errorformat == ""
	    let &l:errorformat = 'Package: %m'
	else
	    let &l:errorformat = &l:errorformat . ',Package: %m'
	endif
    endif
    if &l:errorformat != "" && &l:errorformat !~ "fi"
	let &l:errorformat = &l:errorformat . ",%Cl.%l\ %m,
			    \%+C\ \ %m%.%#,
			    \%+C%.%#-%.%#,
			    \%+C%.%#[]%.%#,
			    \%+C[]%.%#,
			    \%+C%.%#%[{}\\]%.%#,
			    \%+C<%.%#>%.%#,
			    \%+C%m,
			    \%-GSee\ the\ LaTeX%m,
			    \%-GType\ \ H\ <return>%m,
			    \%-G\ ...%.%#,
			    \%-G%.%#\ (C)\ %.%#,
			    \%-G(see\ the\ transcript%.%#),
			    \%-G\\s%#,
			    \%+O(%*[^()])%r,
			    \%+O%*[^()](%*[^()])%r"
" this defines wrong file name and I think this is not that important in TeX. 			    
" 			    \%+P(%f%r,
" 			    \%+P\ %\\=(%f%r,
" 			    \%+P%*[^()](%f%r,
" 			    \%+P[%\\d%[^()]%#(%f%r,
" 			    \%+Q)%r,
" 			    \%+Q%*[^()])%r,
" 			    \%+Q[%\\d%*[^()])%r"
    endif
endfunction

function! s:ShowErrors(...)

    " read the log file and merge warning lines 
    if !filereadable(&errorfile)
	echohl WarningMsg
	echomsg "No error file: " . &errorfile  
	echohl Normal
	return
    endif
    let l:log=readfile(&errorfile)
    let l:nr=1
    for l:line in l:log
	if l:line =~ "LaTeX Warning:" && l:log[l:nr] !~ "^$" 
	    let l:newline=l:line . l:log[l:nr]
	    let l:log[l:nr-1]=l:newline
	    call remove(l:log,l:nr)
	endif
	let l:nr+=1
    endfor
    call writefile(l:log,&errorfile)
    
    " set errorformat 
    if a:0 > 0

	" if one uses completeion to set different flags, they will be in
	" different variables, so we concatenate them first.
	let l:arg=''
	let l:i=1 
	while l:i<=a:0
	    let l:arg.=a:{l:i}
	    let l:i+=1
	endwhile
	call s:SetErrorFormat(l:arg)
    else
	call s:SetErrorFormat()
    endif

    " read the log file
    cg
    " list errors
    cl
endfunction

if !exists("*ListErrorsFlags")
function! ListErrorsFlags(A,L,P)
	return "e\nw\nc\nr\ncr\nf\nfi\nF"
endfunction
endif
"}}}1
" {{{1 Set Viewers: xpdf, xdvi
" {{{2 SetXdvi
fun! SetXdvi()
    let b:texcompiler="latex"
    let b:texoptions="-src-specials"
    if exists("g:xdviOptions")
	let b:ViewerOptions=g:xdviOptions
    endif
    let b:Viewer="xdvi " . b:ViewerOptions . " -editor 'gvim --servername " . v:servername . " --remote-wait +%l %f'"
    if !exists("*RevSearch")
    function RevSearch()
	let b:xdvi_reverse_search="xdvi " . b:ViewerOptions . 
		\ " -editor 'gvim --servername " . v:servername . 
		\ " --remote-wait +%l %f' -sourceposition " . 
		\ line(".") . ":" . col(".") . fnameescape(fnamemodify(expand("%"),":p")) . 
		\ " " . fnameescape(fnamemodify(expand("%"),":p:r") . ".dvi")
	call system(b:xdvi_reverse_search)
    endfunction
    endif
    command! -buffer RevSearch 					:call RevSearch()
    map <buffer> <LocalLeader>rs				:call RevSearch()<CR>
    nmenu 550.65 &LaTeX.Reverse\ Search<Tab>:map\ <LocalLeader>rs	:RevSearch<CR>
endfun
" }}}2
" {{{2 SetXpdf
fun! SetXpdf()
    let b:texcompiler="pdflatex"
    let b:texoptions=""
    let b:Viewer="xpdf"
    if exists("g:xpdfOptions")
	let b:ViewerOptions=g:xpdfOptions
    else
	let b:ViewerOptions=''
    endif
    if hasmapto("RevSearch()",'n')
	unmap <buffer> <LocalLeader>rs
    endif
    if exists("RevSearch")
	delcommand RevSearch
    endif
    if exists("RevSearch")
	delcommand RevSearch
    endif
    aunmenu LaTeX.Reverse\ Search
endfun
" }}}2
" }}}1
" {{{1 Search for Matching Pair (commented out)
"This is a tiny modification of the function defined in matchparent.vim to
"handle multibyte characters
"
" The function that is invoked (very often) to define a ":match" highlighting
" for any matching paren.
" function! s:Highlight_Matching_Pair()
"   " Remove any previous match.
"   if exists('w:paren_hl_on') && w:paren_hl_on
"     3match none
"     let w:paren_hl_on = 0
"   endif
" 
"   " Avoid that we remove the popup menu.
"   " Return when there are no colors (looks like the cursor jumps).
"   if pumvisible() || (&t_Co < 8 && !has("gui_running"))
"     return
"   endif
" 
"   " Get the character under the cursor and check if it's in 'matchpairs'.
"   let c_lnum = line('.')
"   let c_col = col('.')
"   let before = 0
" 
" 
"   let plist = split(g:matchpairs, '.\zs[:,]')
"   let i = index(plist, c)
"   if i < 0
"     " not found, in Insert mode try character before the cursor
"     if c_col > 1 && (mode() == 'i' || mode() == 'R')
"       let before = 1
"       let c = getline(c_lnum)[c_col - 2]
"       let i = index(plist, c)
"     endif
"     if i < 0
"       " not found, nothing to do
"       return
"     endif
"   endif
" 
"   " Figure out the arguments for searchpairpos().
"   if i % 2 == 0
"     let s_flags = 'nW'
"     let c2 = plist[i + 1]
"   else
"     let s_flags = 'nbW'
"     let c2 = c
"     let c = plist[i - 1]
"   endif
"   if c == '['
"     let c = '\['
"     let c2 = '\]'
"   endif
" 
"   " Find the match.  When it was just before the cursor move it there for a
"   " moment.
"   if before > 0
"     let save_cursor = winsaveview()
"     call cursor(c_lnum, c_col - before)
"   endif
" 
"   " When not in a string or comment ignore matches inside them.
"   let s_skip ='synIDattr(synID(line("."), col("."), 0), "name") ' .
" 	\ '=~?  "string\\|character\\|singlequote\\|comment"'
"   execute 'if' s_skip '| let s_skip = 0 | endif'
" 
"   " Limit the search to lines visible in the window.
"   let stoplinebottom = line('w$')
"   let stoplinetop = line('w0')
"   if i % 2 == 0
"     let stopline = stoplinebottom
"   else
"     let stopline = stoplinetop
"   endif
" 
"   try
"     " Limit the search time to 300 msec to avoid a hang on very long lines.
"     " This fails when a timeout is not supported.
"     let [m_lnum, m_col] = searchpairpos(c, '', c2, s_flags, s_skip, stopline, 300)
"   catch /E118/
"     " Can't use the timeout, restrict the stopline a bit more to avoid taking
"     " a long time on closed folds and long lines.
"     " The "viewable" variables give a range in which we can scroll while
"     " keeping the cursor at the same position.
"     " adjustedScrolloff accounts for very large numbers of scrolloff.
"     let adjustedScrolloff = min([&scrolloff, (line('w$') - line('w0')) / 2])
"     let bottom_viewable = min([line('$'), c_lnum + &lines - adjustedScrolloff - 2])
"     let top_viewable = max([1, c_lnum-&lines+adjustedScrolloff + 2])
"     " one of these stoplines will be adjusted below, but the current values are
"     " minimal boundaries within the current window
"     if i % 2 == 0
"       if has("byte_offset") && has("syntax_items") && &smc > 0
" 	let stopbyte = min([line2byte("$"), line2byte(".") + col(".") + &smc * 2])
" 	let stopline = min([bottom_viewable, byte2line(stopbyte)])
"       else
" 	let stopline = min([bottom_viewable, c_lnum + 100])
"       endif
"       let stoplinebottom = stopline
"     else
"       if has("byte_offset") && has("syntax_items") && &smc > 0
" 	let stopbyte = max([1, line2byte(".") + col(".") - &smc * 2])
" 	let stopline = max([top_viewable, byte2line(stopbyte)])
"       else
" 	let stopline = max([top_viewable, c_lnum - 100])
"       endif
"       let stoplinetop = stopline
"     endif
"     let [m_lnum, m_col] = searchpairpos(c, '', c2, s_flags, s_skip, stopline)
"   endtry
" 
"   if before > 0
"     call winrestview(save_cursor)
"   endif
" 
"   " If a match is found setup match highlighting.
"   if m_lnum > 0 && m_lnum >= stoplinetop && m_lnum <= stoplinebottom 
"     exe '3match MatchParen /\(\%' . c_lnum . 'l\%' . (c_col - before) .
" 	  \ 'c\)\|\(\%' . m_lnum . 'l\%' . m_col . 'c\)/'
"     let w:paren_hl_on = 1
"   endif
" endfunction
" }}}1
" {{{1 MOVING FUNCTIONS
" Move to next environment which name is given as the argument. Do not wrap
" around the end of the file.
function! NextEnv(envname)
    call search('\%(%.*\)\@<!\\begin{' . a:envname . '}','W')
endfunction

function! PrevEnv(envname)
    call search('\%(%.*\)\@<!\\begin{' . a:envname . '}','bW')
endfunction

" Move to next section, the extra argument is a pattern to match for the
" section title. The first, obsolete argument stands for:
" part,chapter,section,subsection,etc.
" This commands wrap around the end of the file.
function! NextSection(secname,...)
    if a:0==0
	call search('\\' . a:secname . '\>','w')
    else
	call search('\\' . a:secname . '\>' . '\s*{.*' . a:1,'w') 
    endif
endfunction
function! PrevSection(secname,...)
    if a:0==0
	call search('\\' . a:secname . '\>','bw')
    else
	call search('\\' . a:secname . '\>' . '\s*{.*' . a:1,'bw') 
    endif
endfunction

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
" }}}1
"{{{1 Toggle Functions
" {{{2 ToggleSpace
" Special Space for Searching 
let s:special_space="[off]"
" if !exists("*ToggleSpace")
function! ToggleSpace()
    if maparg('<space>','c') == ""
	echomsg "special space is on"
	cmap <Space> \_s\+
	let s:special_space="[on]"
	silent! aunmenu LaTeX.Toggle\ Space\ [off]
	silent! aunmenu LaTeX.Toggle\ Space\ [on]
	nmenu 550.78 &LaTeX.&Toggle\ Space\ [on]	:ToggleSpace<CR>
	tmenu &LaTeX.&Toggle\ Space\ [on] cmap <space> \_s\+ is curently on
    else
	echomsg "special space is off"
 	cunmap <Space>
	let s:special_space="[off]"
	silent! aunmenu LaTeX.Toggle\ Space\ [on]
	silent! aunmenu LaTeX.Toggle\ Space\ [off]
	nmenu 550.78 &LaTeX.&Toggle\ Space\ [off]	:ToggleSpace<CR>
	tmenu &LaTeX.&Toggle\ Space\ [off] cmap <space> \_s\+ is curently off
    endif
endfunction
"}}}2
" {{{2 ToggleCheckMathOpened
function! ToggleCheckMathOpened()
    if g:atp_math_opened
	echomsg "check if in math environment is off"
	silent! aunmenu LaTeX.Toggle\ Check\ if\ in\ Math\ [on]
	silent! aunmenu LaTeX.Toggle\ Check\ if\ in\ Math\ [off]
	nmenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [off]<Tab>g:atp_math_opened			
		    \ :ToggleCheckMathOpened<CR>
    else
	echomsg "check if in math environment is on"
	silent! aunmenu LaTeX.Toggle\ Check\ if\ in\ Math\ [off]
	silent! aunmenu LaTeX.Toggle\ Check\ if\ in\ Math\ [off]
	nmenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [on]<Tab>g:atp_math_opened
		    \ :ToggleCheckMathOpened<CR>
    endif
    let g:atp_math_opened=!g:atp_math_opened
endfunction
"}}}2
" {{{2 ToggleCallBack
function! ToggleCallBack()
    if g:atp_callback
	echomsg "call back is off"
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [on]
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [off]
	nmenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [off]<Tab>g:atp_callback	
		    \ :call ToggleCallBack()<CR>
    else
	echomsg "call back is on"
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [on]
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [off]
	nmenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [on]<Tab>g:atp_callback
		    \ :call ToggleCallBack()<CR>
    endif
    let g:atp_callback=!g:atp_callback
endfunction
"}}}2
" {{{2 ToggleDebugMode
" ToDo: to doc.
" describe DEBUG MODE in doc properly.
function! ToggleDebugMode()
"     call ToggleCallBack()
    if g:atp_debug_mode
	echomsg "debug mode is off"

	silent! aunmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [on]
	silent! aunmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [off]
	nmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [off]<Tab>g:atp_debug_mode			
		    \ :call ToggleDebugMode()<CR>

	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [on]
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [off]
	nmenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [off]<Tab>g:atp_callback	
		    \ :call ToggleDebugMode()<CR>

	let g:atp_callback=0
	let g:atp_debug_mode=0
	let g:atp_status_notification=0
	if g:atp_statusline
	    call ATPStatus()
	endif
	silent cclose
    else
	echomsg "debug mode is on"

	silent! aunmenu 550.20.5 LaTeX.Log.Toggle\ Debug\ Mode\ [off]
	silent! aunmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [on]
	nmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [on]<Tab>g:atp_debug_mode
		    \ :call ToggleDebugMode()<CR>

	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [on]
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [off]
	nmenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [on]<Tab>g:atp_callback	
		    \ :call ToggleDebugMode()<CR>

	let g:atp_callback=1
	let g:atp_debug_mode=1
	let g:atp_status_notification=1
	if g:atp_statusline
	    call ATPStatus()
	endif
	silent copen
    endif
endfunction
" }}}2
" {{{2 ToggleTab
" switches on/off the <Tab> map for TabCompletion
function! ToggleTab() 
    if mapcheck('<F7>','i') !~ 'atplib#TabCompletion'
	if mapcheck('<Tab>','i') =~ 'atplib#TabCompletion'
	    iunmap <buffer> <Tab>
	    let l:map=0
	else
	    let l:map=1
	    imap <buffer> <Tab> <C-R>=atplib#TabCompletion(1)<CR>
	endif
" 	if mapcheck('<Tab>','n') =~ 'atplib#TabCompletion'
" 	    nunmap <buffer> <Tab>
" 	else
" 	    imap <buffer> <Tab> <C-R>=atplib#TabCompletion(1,1)<CR>
" 	endif
	if l:map 
	    echo '<Tab> map turned on'
	else
	    echo '<Tab> map turned off'
	endif
    endif
endfunction
" }}}2
"{{{2 ToggleStar
" this function adds a star to the current environment
" todo: to doc.
if !exists("*ToggleStar")
function! ToggleStar()

    " limit:
    let l:from_line=max([1,line(".")-g:atp_completion_limits[2]])
    let l:to_line=line(".")+g:atp_completion_limits[2]

    " omit pattern
    let l:omit=join(g:atp_no_star_environments,'\|')
    let l:open_pos=searchpairpos('\\begin\s*{','','\\end\s*{[^}]*}\zs','bnW','getline(".") =~ "\\\\begin\\s*{".l:omit."}"',l:from_line)
    let l:env_name=matchstr(strpart(getline(l:open_pos[0]),l:open_pos[1]),'begin\s*{\zs[^}]*\ze}')
    let b:env_name=l:env_name
    if l:open_pos == [0, 0] || index(g:atp_no_star_environments,l:env_name) != -1
	return
    endif
    if l:env_name =~ '*$'
	let l:env_name=substitute(l:env_name,'*$','','')
	let b:env=l:env_name
	let l:close_pos=searchpairpos('\\begin\s*{'.l:env_name.'\*}','','\\end\s*{'.l:env_name.'\*}\zs','nW',"",l:to_line)
	if l:close_pos != [0, 0]
	    call setline(l:open_pos[0],substitute(getline(l:open_pos[0]),'\(\\begin\s*{\)'.l:env_name.'\*}','\1'.l:env_name.'}',''))
	    call setline(l:close_pos[0],substitute(getline(l:close_pos[0]),
			\ '\(\\end\s*{\)'.l:env_name.'\*}','\1'.l:env_name.'}',''))
	    echomsg "Star removed from '".l:env_name."*' at lines: " .l:open_pos[0]." and ".l:close_pos[0]
	endif
    else
	let l:close_pos=searchpairpos('\\begin\s{'.l:env_name.'}','','\\end\s*{'.l:env_name.'}\zs','nW',"",l:to_line)
	if l:close_pos != [0, 0]
	    call setline(l:open_pos[0],substitute(getline(l:open_pos[0]),
		    \ '\(\\begin\s*{\)'.l:env_name.'}','\1'.l:env_name.'\*}',''))
	    call setline(l:close_pos[0],substitute(getline(l:close_pos[0]),
			\ '\(\\end\s*{\)'.l:env_name.'}','\1'.l:env_name.'\*}',''))
	    echomsg "Star added to '".l:env_name."' at lines: " .l:open_pos[0]." and ".l:close_pos[0]
	endif
    endif
endfunction
endif
"}}}2
"{{{2 ToggleEnvironment
" this function toggles envrionment name.
" Todo: to doc.
" Todo: This will have some sence when the environemnts will be restricted to some
" smaller substets!

if !exists("g:atp_no_toggle_environments")
    let g:atp_no_toggle_environments=[ 'document', 'tikzpicture', 'picture']
endif
if !exists("g:atp_toggle_environment_1")
    let g:atp_toggle_environment_1=[ 'center', 'flushleft', 'flushright', 'minipage' ]
endif
if !exists("g:atp_toggle_environment_2")
    let g:atp_toggle_environment_2=[ 'enumerate', 'itemize', 'list', 'description' ]
endif
if !exists("g:atp_toggle_environment_3")
    let g:atp_toggle_environment_3=[ 'quotation', 'quote', 'verse' ]
endif
if !exists("g:atp_toggle_environment_4")
    let g:atp_toggle_environment_4=[ 'theorem', 'proposition', 'lemma' ]
endif
if !exists("g:atp_toggle_environment_5")
    let g:atp_toggle_environment_5=[ 'corollary', 'remark', 'note' ]
endif
if !exists("g:atp_toggle_environment_6")
    let g:atp_toggle_environment_6=[  'equation', 'align', 'array', 'alignat', 'gather', 'flalign'  ]
endif
if !exists("g:atp_toggle_environment_7")
    let g:atp_toggle_environment_7=[ 'smallmatrix', 'pmatrix', 'bmatrix', 'Bmatrix', 'vmatrix' ]
endif
if !exists("g:atp_toggle_environment_8")
    let g:atp_toggle_environment_8=[ 'tabbing', 'tabular']
endif
if !exists("g:atp_toggle_labels")
    let g:atp_toggle_labels=1
endif

" the argument specifies the speed (if -1 then toggle back)
if !exists("*ToggleEnvironment")
function! ToggleEnvironment(...)

    if a:0 >= 1
	let l:add=a:1
    else
	let l:add=1
    endif
    let b:add=l:add

    " limit:
    let l:from_line=max([1,line(".")-g:atp_completion_limits[2]])
    let l:to_line=line(".")+g:atp_completion_limits[2]

    " omit pattern
    let l:omit=join(g:atp_no_toggle_environments,'\|')
    let l:open_pos=searchpairpos('\\begin\s*{','','\\end\s*{[^}]*}\zs','bnW','getline(".") =~ "\\\\begin\\s*{".l:omit."}"',l:from_line)
    let l:env_name=matchstr(strpart(getline(l:open_pos[0]),l:open_pos[1]),'begin\s*{\zs[^}]*\ze}')

    let l:label=matchstr(strpart(getline(l:open_pos[0]),l:open_pos[1]),'\\label\s*{\zs[^}]*\ze}')
    " DEBUG
    let b:line=strpart(getline(l:open_pos[0]),l:open_pos[1])
    let b:label=l:label
    let b:env_name=l:env_name
    if l:open_pos == [0, 0] || index(g:atp_no_toggle_environments,l:env_name) != -1
	return
    endif

    let l:env_name_ws=substitute(l:env_name,'\*$','','')
    let l:variable="g:atp_toggle_environment_1"
    let l:i=1
    while 1
	let l:env_idx=index({l:variable},l:env_name_ws)
	if l:env_idx != -1
	    break
	else
	    let l:i+=1
	    let l:variable="g:atp_toggle_environment_".l:i
	endif
	if !exists(l:variable)
	    return
	endif
    endwhile

    if l:add > 0 && l:env_idx > len({l:variable})-l:add-1
	let l:env_idx=0
    elseif ( l:add < 0 && l:env_idx < -1*l:add )
	let l:env_idx=len({l:variable})-1
    else
	let l:env_idx+=l:add
    endif
    let l:new_env_name={l:variable}[l:env_idx]
    if l:env_name =~ '\*$'
	let l:new_env_name.="*"
    endif

    " DEBUG
"     let b:i=l:i
"     let b:env_idx=l:env_idx
"     let b:env_name=l:env_name
"     let b:new_env_name=l:new_env_name

    let l:env_name=escape(l:env_name,'*')
    let l:close_pos=searchpairpos('\\begin\s*{'.l:env_name.'}','','\\end\s*{'.l:env_name.'}\zs','nW',"",l:to_line)
    if l:close_pos != [0, 0]
	call setline(l:open_pos[0],substitute(getline(l:open_pos[0]),'\(\\begin\s*{\)'.l:env_name.'}','\1'.l:new_env_name.'}',''))
	call setline(l:close_pos[0],substitute(getline(l:close_pos[0]),
		    \ '\(\\end\s*{\)'.l:env_name.'}','\1'.l:new_env_name.'}',''))
	echomsg "Environment toggeled at lines: " .l:open_pos[0]." and ".l:close_pos[0]
    endif

    if l:label != "" && g:atp_toggle_labels
	let l:new_env_name_ws=substitute(l:new_env_name,'\*$','','')
	let l:new_short_name=get(g:atp_shortname_dict,l:new_env_name_ws,"")
	let l:short_pattern=join(values(filter(g:atp_shortname_dict,'v:val != ""')),'\|')
	let l:short_name=matchstr(l:label,'^'.l:short_pattern)
	let l:new_label=substitute(l:label,'^'.l:short_name,l:new_short_name,'')

	" check if new label is in use!
	let l:pos_save=getpos(".")
	let l:n=search('\C\\\(label\|\%(eq\|page\)\?ref\)\s*{'.l:new_label.'}','nwc')
" 	let b:n=l:n

	if l:short_name != "" && l:n == 0 && l:new_label != l:label
	    silent! keepjumps execute '%substitute /\\\(eq\|page\)\?\(ref\s*\){'.l:label.'}/\\\1\2{'.l:new_label.'}/gIe'
	    silent! keepjumps execute l:open_pos[0].'substitute /\\label{'.l:label.'}/\\label{'.l:new_label.'}'
	    keepjumps call setpos(".",l:pos_save)
	elseif l:n != 0 && l:new_label != l:label
	    echohl WarningMsg
	    echomsg "Labels not changed, new label: ".l:new_label." is in use!"
	    echohl Normal
	endif
    endif
    return  l:open_pos[0]."-".l:close_pos[0]
endfunction
endif
"}}}2
"}}}1

" {{{1 TAB COMPLETION variables
" ( functions are in autoload/atplib.vim )
"
let g:atp_completion_modes=[ 
	    \ 'commands', 		'labels', 		
	    \ 'tikz libraries', 	'environment names',
	    \ 'close environments' , 	'brackets',
	    \ 'input files',		'bibstyles',
	    \ 'bibitems', 		'bibfiles',
	    \ 'documentclass',		'tikzpicture commands',
	    \ 'tikzpicture',		'tikzpicture keywords',
	    \ 'package names',		'font encoding',
	    \ 'font family',		'font series',
	    \ 'font shape' ]
let g:atp_completion_modes_normal_mode=[ 
	    \ 'close environments' , 	'brackets' ]

" By defualt all completion modes are ative.
if !exists("g:atp_completion_active_modes")
    let g:atp_completion_active_modes=deepcopy(g:atp_completion_modes)
endif
if !exists("g:atp_completion_active_modes_normal_mode")
    let g:atp_completion_active_modes_normal_mode=deepcopy(g:atp_completion_modes_normal_mode)
endif

" Note: to remove completions: 'inline_math' or 'displayed_math' one has to
" remove also: 'close_environments' /the function atplib#CloseLastEnvironment can
" close math instead of an environment/.

" ToDo: make list of complition commands from the input files.
" ToDo: make complition fot \cite, and for \ref and \eqref commands.

" ToDo: there is second such a list! line 3150
	let g:atp_environments=['array', 'abstract', 'center', 'corollary', 
		\ 'definition', 'document', 'description',
		\ 'enumerate', 'example', 'eqnarray', 
		\ 'flushright', 'flushleft', 'figure', 'frontmatter', 
		\ 'keywords', 
		\ 'itemize', 'lemma', 'list', 'notation', 'minipage', 
		\ 'proof', 'proposition', 'picture', 'theorem', 'tikzpicture',  
		\ 'tabular', 'table', 'tabbing', 'thebibliography', 'titlepage',
		\ 'quotation', 'quote',
		\ 'remark', 'verbatim', 'verse' ]

	let g:atp_amsmath_environments=['align', 'alignat', 'equation', 'gather',
		\ 'multiline', 'split', 'substack', 'flalign', 'smallmatrix', 'subeqations',
		\ 'pmatrix', 'bmatrix', 'Bmatrix', 'vmatrix' ]

	" if short name is no_short_name or '' then both means to do not put
	" anything, also if there is no key it will not get a short name.
	let g:atp_shortname_dict = { 'theorem' : 'thm', 
		    \ 'proposition' : 'prop', 	'definition' : 'defi',
		    \ 'lemma' : 'lem',		'array' : 'ar',
		    \ 'abstract' : 'no_short_name',
		    \ 'tikzpicture' : 'tikz',	'tabular' : 'table',
		    \ 'table' : 'table', 	'proof' : 'pr',
		    \ 'corollary' : 'cor',	'enumerate' : 'enum',
		    \ 'example' : 'ex',		'itemize' : 'it',
		    \ 'item'	: 'itm',
		    \ 'remark' : 'rem',		'notation' : 'not',
		    \ 'center' : '', 		'flushright' : '',
		    \ 'flushleft' : '', 	'quotation' : 'quot',
		    \ 'quot' : 'quot',		'tabbing' : '',
		    \ 'picture' : 'pic',	'minipage' : '',	
		    \ 'list' : 'list',		'figure' : 'fig',
		    \ 'verbatim' : 'verb', 	'verse' : 'verse',
		    \ 'thebibliography' : '',	'document' : 'no_short_name',
		    \ 'titlepave' : '', 	'align' : 'eq',
		    \ 'alignat' : 'eq',		'equation' : 'eq',
		    \ 'gather'  : 'eq', 	'multiline' : '',
		    \ 'split'	: 'eq', 	'substack' : '',
		    \ 'flalign' : 'eq',
		    \ 'part'	: 'prt',	'chapter' : 'chap',
		    \ 'section' : 'sec',	'subsection' : 'ssec',
		    \ 'subsubsection' : 'sssec', 'paragraph' : 'par',
		    \ 'subparagraph' : 'spar' }

	" ToDo: Doc.
	" Usage: \label{l:shorn_env_name . g:atp_separator
	if !exists("g:atp_separator")
	    let g:atp_separator=':'
	endif
	if !exists("g:atp_no_separator")
	    let g:atp_no_separator = 0
	endif
	if !exists("g:atp_no_short_names")
	    let g:atp_env_short_names = 1
	endif
	" the separator will not be put after the environments in this list:  
	" the empty string is on purpose: to not put separator when there is
	" no name.
	let g:atp_no_separator_list=['', 'titlepage']

" 	let g:atp_package_list=sort(['amsmath', 'amssymb', 'amsthm', 'amstex', 
" 	\ 'babel', 'booktabs', 'bookman', 'color', 'colorx', 'chancery', 'charter', 'courier',
" 	\ 'enumerate', 'euro', 'fancyhdr', 'fancyheadings', 'fontinst', 
" 	\ 'geometry', 'graphicx', 'graphics',
" 	\ 'hyperref', 'helvet', 'layout', 'longtable',
" 	\ 'newcent', 'nicefrac', 'ntheorem', 'palatino', 'stmaryrd', 'showkeys', 'tikz',
" 	\ 'qpalatin', 'qbookman', 'qcourier', 'qswiss', 'qtimes', 'verbatim', 'wasysym'])

	" the command \label is added at the end.
	let g:atp_commands=["\\begin{", "\\end{", 
	\ "\\cite{", "\\nocite{", "\\ref{", "\\pageref{", "\\eqref{", "\\bibitem", "\\item",
	\ "\\emph{", "\\documentclass{", "\\usepackage{",
	\ "\\section{", "\\subsection{", "\\subsubsection{", "\\part{", 
	\ "\\chapter{", "\\appendix", "\\subparagraph", "\\paragraph",
	\ "\\textbf{", "\\textsf{", "\\textrm{", "\\textit{", "\\texttt{", 
	\ "\\textsc{", "\\textsl{", "\\textup{", "\\textnormal", "\\textcolor{",
	\ "\\bfseries", "\\mdseries",
	\ "\\tiny",  "\\scriptsize", "\\footnotesize", "\\small",
	\ "\\noindent", "\\normalfont", "\normalsize", "\\normalsize", "\\normal", 
	\ "\\large", "\\Large", "\\LARGE", "\\huge", "\\HUGE",
	\ "\\usefont{", "\\fontsize{", "\\selectfont", "\\fontencoding{", "\\fontfamiliy{", "\\fontseries{", "\\fontshape{",
	\ "\\rmdefault", "\\sfdefault", "\\ttdefault", "\\bfdefault", "\\mddefault", "\\itdefault",
	\ "\\sldefault", "\\scdefault", "\\updefault",  "\\renewcommand{", "\\newcommand{",
	\ "\\addcontentsline{", "\\addtocontents",
	\ "\\input", "\\include", "\\includeonly", "\\inlucegraphics",  
	\ "\\savebox", "\\sbox", "\\usebox", "\\rule", "\\raisebox{", 
	\ "\\parbox{", "\\mbox{", "\\makebox{", "\\framebox{", "\\fbox{",
	\ "\\bigskip", "\\medskip", "\\smallskip", "\\vfill", "\\vspace{", 
	\ "\\hspace", "\\hrulefill", "\\hfill", "\\dots", "\\dotfill",
	\ "\\thispagestyle", "\\mathnormal", "\\markright", "\\pagestyle", "\\pagenumbering",
	\ "\\author{", "\\date{", "\\thanks{", "\\title{",
	\ "\\maketitle", "\\overbrace{", "\\underbrace{",
	\ "\\marginpar", "\\indent", "\\par", "\\sloppy", "\\pagebreak", "\\nopagebreak",
	\ "\\newpage", "\\newline", "\\newtheorem{", "\\linebreak", "\\hyphenation{", "\\fussy",
	\ "\\enlagrethispage{", "\\clearpage", "\\cleardoublepage",
	\ "\\caption{",
	\ "\\opening{", "\\name{", "\\makelabels{", "\\location{", "\\closing{", "\\address{", 
	\ "\\signature{", "\\stopbreaks", "\\startbreaks",
	\ "\\newcounter{", "\\refstepcounter{", 
	\ "\\roman{", "\\Roman{", "\\stepcounter{", "\\setcounter{", 
	\ "\\usecounter{", "\\value{", 
	\ "\\newlength{", "\\setlength{", "\\addtolength{", "\\settodepth{", 
	\ "\\settoheight{", "\\settowidth{", 
	\ "\\width", "\\height", "\\depth", "\\totalheight",
	\ "\\footnote{", "\\footnotemark", "\\footnotetetext", 
	\ "\\bibliography{", "\\bibliographystyle{", 
	\ "\\flushbottom", "\\onecolumn", "\\raggedbottom", "\\twocolumn",  
	\ "\\alph{", "\\Alph{", "\\arabic{", "\\fnsymbol{", "\\reversemarginpar",
	\ "\\exhyphenpenalty",
	\ "\\topmargin", "\\oddsidemargin", "\\evensidemargin", "\\headheight", "\\headsep", 
	\ "\\textwidth", "\\textheight", "\\marginparwidth", "\\marginparsep", "\\marginparpush", "\\footskip", "\\hoffset",
	\ "\\voffset", "\\paperwidth", "\\paperheight", "\\theequation", "\\thepage", "\\usetikzlibrary{",
	\ "\\tableofcontents", "\\newfont{" ]
	
	let g:atp_picture_commands=[ "\\put", "\\circle", "\\dashbox", "\\frame{", 
		    \"\\framebox(", "\\line(", "\\linethickness{",
		    \ "\\makebox(", "\\\multiput(", "\\oval(", "\\put", 
		    \ "\\shortstack", "\\vector(" ]

	" ToDo: end writting layout commands. 
	" ToDo: MAKE COMMANDS FOR PREAMBULE.

	let g:atp_math_commands=["\\forall", "\\exists", "\\emptyset", "\\aleph", "\\partial",
	\ "\\nabla", "\\Box", "\\Diamond", "\\bot", "\\top", "\\flat", "\\sharp",
	\ "\\mathbf{", "\\mathsf{", "\\mathrm{", "\\mathit{", "\\mathbb{", "\\mathtt{", "\\mathcal{", 
	\ "\\mathop{", "\\limits", "\\text{", "\\leqslant", "\\leq", "\\geqslant", "\\geq",
	\ "\\gtrsim", "\\lesssim", "\\gtrless", "\\left", "\\right", 
	\ "\\rightarrow", "\\Rightarrow", "\\leftarrow", "\\Leftarrow", "\\iff", 
	\ "\\leftrightarrow", "\\Leftrightarrow", "\\downarrow", "\\Downarrow", "\\Uparrow",
	\ "\\Longrightarrow", "\\longrightarrow", "\\Longleftarrow", "\\longleftarrow",
	\ "\\overrightarrow{", "\\overleftarrow{", "\\underrightarrow{", "\\underleftarrow{",
	\ "\\uparrow", "\\nearrow", "\\searrow", "\\swarrow", "\\nwarrow", 
	\ "\\hookrightarrow", "\\hookleftarrow", "\\gets", 
	\ "\\sum", "\\bigsum", "\\cup", "\\bigcup", "\\cap", "\\bigcap", 
	\ "\\prod", "\\coprod", "\\bigvee", "\\bigwedge", "\\wedge",  
	\ "\\oplus", "\\otimes", "\\odot", "\\oint",
	\ "\\int", "\\bigoplus", "\\bigotimes", "\\bigodot", "\\times",  
	\ "\\smile", "\\frown", "\\subset", "\\subseteq", "\\supset", "\\supseteq",
	\ "\\dashv", "\\vdash", "\\vDash", "\\Vdash", "\\models", "\\sim", "\\simeq", 
	\ "\\prec", "\\preceq", "\\preccurlyeq", "\\precapprox",
	\ "\\succ", "\\succeq", "\\succcurlyeq", "\\succapprox", "\\approx", 
	\ "\\thickapprox", "\\conq", "\\bullet", 
	\ "\\lhd", "\\unlhd", "\\rhd", "\\unrhd", "\\dagger", "\\ddager", "\\dag", "\\ddag", 
	\ "\\ldots", "\\cdots", "\\vdots", "\\ddots", 
	\ "\\vartriangleright", "\\vartriangleleft", "\\trianglerighteq", "\\trianglelefteq",
	\ "\\copyright", "\\textregistered", "\\puonds",
	\ "\\big", "\\Big", "\\Bigg", "\\huge", 
	\ "\\bigr", "\\Bigr", "\\biggr", "\\Biggr",
	\ "\\bigl", "\\Bigl", "\\biggl", "\\Biggl",
	\ "\\hat", "\\grave", "\\bar", "\\acute", "\\mathring", "\\check", "\\dot", "\\vec", "\\breve",
	\ "\\tilde", "\\widetilde " , "\\widehat", "\\ddot", 
	\ "\\sqrt", "\\frac{", "\\binom{", "\\cline", "\\vline", "\\hline", "\\multicolumn{", 
	\ "\\nouppercase", "\\sqsubset", "\\sqsupset", "\\square", "\\blacksquare", "\\triangledown", "\\triangle", 
	\ "\\diagdown", "\\diagup", "\\nexists", "\\varnothing", "\\Bbbk", "\\circledS", 
	\ "\\complement", "\\hslash", "\\hbar", 
	\ "\\eth", "\\rightrightarrows", "\\leftleftarrows", "\\rightleftarrows", "\\leftrighrarrows", 
	\ "\\downdownarrows", "\\upuparrows", "\\rightarrowtail", "\\leftarrowtail", 
	\ "\\twoheadrightarrow", "\\twoheadleftarrow", "\\rceil", "\\lceil", "\\rfloor", "\\lfloor", 
	\ "\\bullet", "\\bigtriangledown", "\\bigtriangleup", "\\ominus", "\\bigcirc", "\\amalg", 
	\ "\\setminus", "\\sqcup", "\\sqcap", 
	\ "\\lnot", "\\notin", "\\neq", "\\smile", "\\frown", "\\equiv", "\\perp",
	\ "\\quad", "\\qquad", "\\stackrel", "\\displaystyle", "\\textstyle", "\\scriptstyle", "\\scriptscriptstyle",
	\ "\\langle", "\\rangle" ]

	" commands defined by the user in input files.
	" ToDo: to doc.
	" ToDo: this doesn't work with input files well enough. 
	
	" Returns a list of two lists:  [ commanad_names, enironment_names ]

	" The BufEnter augroup doesn't work with EditInputFile, but at least it works
	" when entering. Debuging shows that when entering new buffer it uses
	" wrong b:atp_mainfile, it is still equal to the bufername and not the
	" real main file. Maybe it is better to use s:mainfile variable.

	if !exists("g:atp_local_completion")
	    let g:atp_local_completion = 1
	endif
	if g:atp_local_completion == 2 
	    au BufEnter *.tex call LocalCommands()
	endif


	let g:atp_math_commands_non_expert_mode=[ "\\leqq", "\\geqq", "\\succeqq", "\\preceqq", 
		    \ "\\subseteqq", "\\supseteqq", "\\gtrapprox", "\\lessapprox" ]
	 
	" requiers amssymb package:
	let g:atp_ams_negations=[ "\\nless", "\\ngtr", "\\lneq", "\\gneq", "\\nleq", "\\ngeq", "\\nleqslant", "\\ngeqslant", 
		    \ "\\nsim", "\\nconq", "\\nvdash", "\\nvDash", 
		    \ "\\nsubseteq", "\\nsupseteq", 
		    \ "\\varsubsetneq", "\\subsetneq", "\\varsupsetneq", "\\supsetneq", 
		    \ "\\ntriangleright", "\\ntriangleleft", "\\ntrianglerighteq", "\\ntrianglelefteq", 
		    \ "\\nrightarrow", "\\nleftarrow", "\\nRightarrow", "\\nLeftarrow", 
		    \ "\\nleftrightarrow", "\\nLeftrightarrow", "\\nsucc", "\\nprec", "\\npreceq", "\\nsucceq", 
		    \ "\\precneq", "\\succneq", "\\precnapprox" ]

	let g:atp_ams_negations_non_expert_mode=[ "\\lneqq", "\\ngeqq", "\\nleqq", "\\ngeqq", "\\nsubseteqq", 
		    \ "\\nsupseteqq", "\\subsetneqq", "\\supsetneqq", "\\nsucceqq", "\\precneqq", "\\succneqq" ] 

	" ToDo: add more amsmath commands.
	let g:atp_amsmath_commands=[ "\\boxed", "\\intertext", "\\multiligngap", "\\shoveleft", "\\shoveright", "\\notag", "\\tag", 
		    \ "\\raistag{", "\\displaybreak", "\\allowdisplaybreaks", "\\numberwithin{",
		    \ "\\hdotsfor{" , "\\mspace{",
		    \ "\\negthinspace", "\\negmedspace", "\\negthickspace", "\\thinspace", "\\medspace", "\\thickspace",
		    \ "\\leftroot{", "\\uproot{", "\\overset{", "\\underset{", "\\sideset{", 
		    \ "\\dfrac{", "\\tfrac{", "\\cfrac{", "\\dbinom{", "\\tbinom{", "\\smash",
		    \ "\\lvert", "\\rvert", "\\lVert", "\\rVert", "\\DeclareMatchOperator{",
		    \ "\\arccos", "\\arcsin", "\\arg", "\\cos", "\\cosh", "\\cot", "\\coth", "\\csc", "\\deg", "\\det",
		    \ "\\dim", "\\exp", "\\gcd", "\\hom", "\\inf", "\\injlim", "\\ker", "\\lg", "\\lim", "\\liminf", "\\limsup",
		    \ "\\log", "\\min", "\\max", "\\Pr", "\\projlim", "\\sec", "\\sin", "\\sinh", "\\sup", "\\tan", "\\tanh",
		    \ "\\varlimsup", "\\varliminf", "\\varinjlim", "\\varprojlim", "\\mod", "\\bmod", "\\pmod", "\\pod", "\\sideset",
		    \ "\\iint", "\\iiint", "\\iiiint", "\\idotsint",
		    \ "\\varGamma", "\\varDelta", "\\varTheta", "\\varLambda", "\\varXi", "\\varPi", "\\varSigma", 
		    \ "\\varUpsilon", "\\varPhi", "\\varPsi", "\\varOmega" ]
	
	" ToDo: integrate in TabCompletion (amsfonts, euscript packages).
	let g:atp_amsfonts=[ "\\mathfrak", "\\mathscr" ]

	" not yet supported: in TabCompletion:
	let g:atp_amsxtra_commands=[ "\\sphat", "\\sptilde" ]
	let g:atp_fancyhdr_commands=["\\lfoot{", "\\rfoot{", "\\rhead{", "\\lhead{", 
		    \ "\\cfoot{", "\\chead{", "\\fancyhead{", "\\fancyfoot{",
		    \ "\\fancypagestyle{", "\\fancyhf{}", "\\headrulewidth", "\\footrulewidth",
		    \ "\\rightmark", "\\leftmark", "\\markboth", 
		    \ "\\chaptermark", "\\sectionmark", "\\subsectionmark",
		    \ "\\fancyheadoffset", "\\fancyfootoffset", "\\fancyhfoffset"]


	" ToDo: remove tikzpicture from above and integrate the
	" tikz_envirnoments variable
	" \begin{pgfonlayer}{background} (complete the second argument as
	" well}
	"
	" Tikz command cuold be accitve only in tikzpicture and after \tikz
	" command! There is a way to do that.
	" 
	let g:atp_tikz_environments=['tikzpicture', 'scope', 'pgfonlayer', 'background' ]
	" ToDo: this should be completed as packages.
	let g:atp_tikz_libraries=sort(['arrows', 'automata', 'backgrounds', 'calc', 'calendar', 'chains', 'decorations', 
		    \ 'decorations.footprints', 'decorations.fractals', 
		    \ 'decorations.markings', 'decorations.pathmorphing', 
		    \ 'decorations.replacing', 'decorations.shapes', 
		    \ 'decorations.text', 'er', 'fadings', 'fit',
		    \ 'folding', 'matrix', 'mindmap', 'scopes', 
		    \ 'patterns', 'pteri', 'plothandlers', 'plotmarks', 
		    \ 'plcaments', 'pgflibrarypatterns', 'pgflibraryshapes',
		    \ 'pgflibraryplotmarks', 'positioning', 'replacements', 
		    \ 'shadows', 'shapes.arrows', 'shapes.callout', 'shapes.geometric', 
		    \ 'shapes.gates.logic.IEC', 'shapes.gates.logic.US', 'shapes.misc', 
		    \ 'shapes.multipart', 'shapes.symbols', 'topaths', 'through', 'trees' ])
	" tikz keywords = begin without '\'!
	" ToDo: add mote keywords: done until page 145.
	" ToDo: put them in a correct order!!!
	let g:atp_tikz_keywords=[ 'draw', 'node', 'matrix', 'anchor', 'top', 'bottom',  
		    \ 'west', 'east', 'north', 'south', 'at', 'thin', 'thick', 'semithick', 'rounded', 'corners',
		    \ 'controls', 'and', 'circle', 'step', 'grid', 'very', 'style', 'line', 'help',
		    \ 'color', 'arc', 'curve', 'scale', 'parabola', 'line', 'ellipse', 'bend', 'sin', 'rectangle', 'ultra', 
		    \ 'right', 'left', 'intersection', 'xshift', 'yshift', 'shift', 'near', 'start', 'above', 'below', 
		    \ 'end', 'sloped', 'coordinate', 'cap', 'shape', 'transition', 'place', 'label', 'every', 
		    \ 'edge', 'point', 'loop', 'join', 'distance', 'sharp', 'rotate', 'blue', 'red', 'green', 'yellow', 
		    \ 'black', 'white', 'gray',
		    \ 'text', 'width', 'inner', 'sep', 'baseline', 'current', 'bounding', 'box', 
		    \ 'canvas', 'polar', 'radius', 'barycentric', 'angle', 'opacity', 
		    \ 'solid', 'phase', 'loosly', 'dashed', 'dotted' , 'densly', 
		    \ 'latex', 'diamond', 'double', 'smooth', 'cycle', 'coordinates', 'distance',
		    \ 'even', 'odd', 'rule', 'pattern', 
		    \ 'stars', 'fivepointed', 'shading', 'ball', 'axis', 'middle', 'outer', 'transorm',
		    \ 'fading', 'horizontal', 'vertical', 'light', 'crosshatch', 'button', 'postaction', 'out',
		    \ 'circular', 'shadow', 'scope', 'borders', 'spreading', 'false', 'position' ]
	let g:atp_tikz_library_arrows_keywords=[ "reversed'", "stealth'", 'triangle', 'open', 
		    \ 'hooks', 'round', 'fast', 'cap', 'butt'] 
	let g:atp_tikz_library_automata_keywords=[ 'state', 'accepting', 'initial', 'swap', 'edge',
		    \ 'loop', 'nodepart', 'lower', 'output']  
	let g:atp_tikz_library_backgrounds_keywords=[ 'background', 'show', 'inner', 'frame', 'framed',
		    \ 'tight', 'loose', 'xsep', 'ysep']

	" NEW:
	let g:atp_tikz_library_calendar=[ '\calendar', '\tikzmonthtext' ]
	let g:atp_tikz_library_calendar_keywords=[ 'week list', 'dates', 'day', 'day list', 'month', 'year', 'execute', 
		    \ 'before', 'after', 'downward', 'upward' ]
	let g:atp_tikz_library_chain=[ '\chainin' ]
	let g:atp_tikz_library_chain_keywords=[ 'chain', 'start chain', 'on chain', 'continue chain', 
		    \ 'start branch', 'branch', 'going', 'numbers', 'greek' ]
" 	let g:atp_tikz_library_decoration=[]
	let g:atp_tikz_library_decoration_keywords=[ 'decorate', 'decoration', 'lineto', 'straight', 'zigzag',
		    \ 'saw', 'random steps', 'bent', 'aspect', 'bumps', 'coil', 'curveto', 'snake', 
		    \ 'border', 'brace', 'segment lenght', 'waves', 'ticks', 'expanding', 
		    \ 'crosses', 'triangles', 'dart', 'shape sep', 'shape backgrounds', 'between', 'text along path', 
		    \ 'Koch curve type 1', 'Koch curve type 1', 'Koch snowflake', 'Cantor set', 'footprints',
		    \ 'foot lenght',  'stride lenght', 'foot sep', 'foot angle', 'foot of', 'gnome', 'human', 
		    \ 'bird', 'felis silvestris' ]
	" for tikz keywords we can complete sentences, like 'matrix of
	" math nodes'!
	let g:atp_tikz_library_matrix_keywords=['matrix of nodes', 'matrix of math nodes', 'nodes', 'delimiter', 
		    \ 'rmoustache', 'column sep=', 'row sep=' ] 
	" ToDo: completion for arguments in brackets [] for tikz commands.
	let g:atp_tikz_commands=[ "\\begin", "\\end", "\\matrix", "\\node", "\\shadedraw", 
		    \ "\\draw", "\\tikz", "\\tikzset",
		    \ "\\path", "\\filldraw", "\\fill", "\\clip", "\\drawclip", "\\foreach", "\\angle", "\\coordinate",
		    \ "\\useasboundingbox", "\\tikztostart", "\\tikztotarget", "\\tikztonodes", "\\tikzlastnode",
		    \ "\\pgfextra", "\\endpgfextra", "\\verb", "\\coordinate", 
		    \ "\\pattern", "\\shade", "\\shadedraw", "\\colorlet", "\\definecolor" ]

" ToDo: to doc.
" adding commands to completion list whether to check or not if we are in the
" correct environment (for example \tikz or \begin{tikzpicture})
if !exists("g:atp_check_if_opened")
    let g:atp_check_if_opened=1
endif
" This is as the above, but works only if one uses \(:\), \[:\]
if !exists("g:atp_math_opened")
    if search('\%([^\\]\|^\)\$\$\?','wnc') != 0
	let g:atp_math_opened=0
    else
	let g:atp_math_opened=1
    endif
endif
" ToDo: Think about even better math modes patterns.
" \[ - math mode \\[ - not mathmode (this can be at the end of a line as: \\[3pt])
" \\[ - this is math mode, but tex will complain (now I'm not matching it,
" that's maybe good.) 
" How to deal with $:$ (they are usually in one line, we could count them)  and $$:$$ 
" matchpair

let g:atp_math_modes=[ ['\%([^\\]\|^\)\%(\\\|\\\{3}\)(','\%([^\\]\|^\)\%(\\\|\\\{3}\)\zs)'],
	    \ ['\%([^\\]\|^\)\%(\\\|\\\{3}\)\[','\%([^\\]\|^\)\%(\\\|\\\{3}\)\zs\]'], 	
	    \ ['\\begin{align', '\\end{alig\zsn'], 	['\\begin{gather', '\\end{gathe\zsr'], 
	    \ ['\\begin{falign', '\\end{flagi\zsn'], 	['\\begin[multiline', '\\end{multilin\zse'],
	    \ ['\\begin{equation', '\\end{equatio\zsn'] ]
" ToDo: user command list, env list g:atp_commands, g:atp_environments, 
" }}}1
"{{{1 LocalCommands 
if !exists("*LocalCommands")
function! LocalCommands(...)

    if a:0 == 0
	let l:pattern='\\def\>\|\\newcommand\>\|\\newenvironment\|\\newtheorem\|\\definecolor'
    else
	let l:pattern=a:1
    endif
    echo "Makeing lists of commands and environments found in input files ... "
" 	    call s:setprojectname()
    let l:command_names=[]
    let l:environment_names=[]
    let l:color_names=[]

    " ToDo: I need a simpler function here !!!
    " 		we are just looking for definition names not for
    " 		definition itself (this takes time).
    let l:ddict=s:make_defi_dict(b:atp_mainfile,l:pattern,1,1)
" 	    echomsg " LocalCommands DEBUG " . b:atp_mainfile
    let b:ddict=l:ddict
	for l:inputfile in keys(l:ddict)
	    let l:ifile=readfile(l:inputfile)
	    for l:range in l:ddict[l:inputfile]
		if l:ifile[l:range[0]-1] =~ '\\def\|\\newcommand'
		    " check only definitions which starts at 0 column
		    " definition name 
		    let l:name=matchstr(l:ifile[l:range[0]-1],
				\ '^\%(\\def\\\zs[^{#]*\ze[{#]\|\\newcommand{\?\\\zs[^\[{]*\ze[\[{}]}\?\)')
		    " definition
		    let l:def=matchstr(l:ifile[l:range[0]-1],
				\ '^\%(\\def\\[^{]*{\zs.*\ze}\|\\newcommand\\[^{]*{\zs.*\ze}\)') 
		    if l:name != ""
			" add a definition if it is not a lenght:
			" \def\myskip{2cm}
			" will not be added.
" 				echo l:name . " count: " . (!count(l:command_names, "\\".l:name)) . " pattern: " . (l:def !~ '^\s*\(\d\|\.\)*\s*\(mm\|cm\|pt\|in\|em\|ex\)\?$' || l:def == "") . " l:def " . l:def
			if !count(l:command_names, "\\".l:name) && (l:def !~ '^\s*\(\d\|\.\)*\s*\(mm\|cm\|pt\|in\|em\|ex\)\?$' || l:def == "")
			    call add(l:command_names, "\\".l:name)
			endif
" 				echomsg l:name
		    endif
		endif
		if l:ifile[l:range[0]-1] =~ '\\newenvironment\|\\newtheorem'
		    " check only definitions which starts at 0 column
		    let l:name=matchstr(l:ifile[l:range[0]-1],
				\ '^\\\%(newtheorem\*\?\|newenvironment\){\zs[^}]*\ze}')
		    if l:name != ""
			if !count(l:environment_names,l:name)
			    call add(l:environment_names,l:name)
			endif
		    endif
		endif
		if l:ifile[l:range[0]-1] =~ '\\definecolor'
		    let l:name=matchstr(l:ifile[l:range[0]-1],
				\ '^\s*\\definecolor\s*{\zs[^}]*\ze}')
		    if l:name != ""
			if !count(l:color_names,l:name)
			    call add(l:color_names,l:name)
			endif
		    endif
		endif
	    endfor
	endfor
    let s:atp_local_commands		= []
    let s:atp_local_environments	= []
    let s:atp_local_colors		= l:color_names

    " remove double entries
    for l:type in ['command', 'environment']
" 		echomsg l:type
	for l:item in l:{l:type}_names
" 		    if l:type == 'environment'
" 			echomsg l:item . "  " . index(g:atp_{l:type}s,l:item)
" 		    endif
	    if index(g:atp_{l:type}s,l:item) == '-1'
		call add(s:atp_local_{l:type}s,l:item)
	    endif
	endfor
    endfor

    " Make shallow copies of the lists
    let b:atp_local_commands=s:atp_local_commands
    let b:atp_local_environments=s:atp_local_environments
    let b:atp_local_colors=s:atp_local_colors
    return [ s:atp_local_environments, s:atp_local_commands, s:atp_local_colors ]
endfunction
endif
"}}}1
" command! SearchBibItems 	:echo atplib#SearchBibItems(b:atp_mainfile)
" }}}1
"{{{1 Debugging Commands for Check... functions
" command -buffer -nargs=* CheckOpened	:echo atplib#CheckOpened(<args>)
" command -buffer -nargs=* CheckClosed	:echo atplib#CheckClosed(<args>)
" Usage:
" command -buffer CheckA	:echomsg "CheckA " . atplib#CheckClosed(g:atp_math_modes[0][0],g:atp_math_modes[0][1],line('.'),g:atp_completion_limits[0])
" command -buffer CheckB	:echomsg "CheckB " .  atplib#CheckClosed(g:atp_math_modes[1][0],g:atp_math_modes[1][1],line('.'),g:atp_completion_limits[1])
" command -buffer CheckC	:echomsg "CheckC " .  atplib#CheckClosed('\\begin{','\\end{',line('.'),g:atp_completion_limits[2])
" command -buffer OCheckA	:echomsg "OCheckA " .  atplib#CheckOpened(g:atp_math_modes[0][0],g:atp_math_modes[0][1],line('.'),g:atp_completion_limits[0])
" command -buffer OCheckB	:echomsg "OCheckB " .  atplib#CheckOpened(g:atp_math_modes[1][0],g:atp_math_modes[1][1],line('.'),g:atp_completion_limits[1])
" command -buffer OCheckC	:echomsg "OCheckC " .  atplib#CheckOpened('\\begin{','\\end{',line('.'),g:atp_completion_limits[2])
"}}}1
"{{{1 Help ----- to do:		
function! TEXdoc(name)
    call system("texdoc -m " . a:name)
endfunction
function! TEXdoc_complete(A,L,P)
    return atplib#Search_Package("tex","sty")
endfunction
command -buffer -complete=customlist,TEXdoc_complete TEXdoc 	:call TEXdoc(<f-args>)
"}}}1


" {{{1 Load Latex_Box addonds (omni completion, and  %) by David Munger 
if g:atp_LatexBox == 1 || (g:atp_check_if_LatexBox && len(split(globpath(&rtp,'ftplugin/tex_LatexBox.vim')))) 
    if !exists('s:loaded_LatexBox') 
	if !exists('g:LatexBox_cite_pattern')
		let g:LatexBox_cite_pattern = '\\cite\(p\|t\)\?\*\?\_\s*{'
	endif
	if !exists('g:LatexBox_ref_pattern')
		let g:LatexBox_ref_pattern = '\\v\?\(eq\|page\)\?ref\*\?\_\s*{'
	endif

	" Global Variables {{{
	let g:LatexBox_complete_with_brackets = 1
	let g:LatexBox_bibtex_wild_spaces = 1

	let g:LatexBox_completion_environments = [
		\ {'word': 'itemize',		'menu': 'bullet list' },
		\ {'word': 'enumerate',		'menu': 'numbered list' },
		\ {'word': 'description',	'menu': 'description' },
		\ {'word': 'center',		'menu': 'centered text' },
		\ {'word': 'figure',		'menu': 'floating figure' },
		\ {'word': 'table',		'menu': 'floating table' },
		\ {'word': 'equation',		'menu': 'equation (numbered)' },
		\ {'word': 'align',		'menu': 'aligned equations (numbered)' },
		\ {'word': 'align*',		'menu': 'aligned equations' },
		\ {'word': 'document' },
		\ {'word': 'abstract' },
		\ ]

	let g:LatexBox_completion_commands = [
		\ {'word': '\begin{' },
		\ {'word': '\end{' },
		\ {'word': '\item' },
		\ {'word': '\label{' },
		\ {'word': '\ref{' },
		\ {'word': '\eqref{eq:' },
		\ {'word': '\cite{' },
		\ {'word': '\nonumber' },
		\ {'word': '\bibliography' },
		\ {'word': '\bibliographystyle' },
		\ ]
	" }}}

	let prefix = expand('<sfile>:p:h')
	execute 'source ' . prefix . '/atp_LatexBox.vim'
	let s:loaded_LatexBox = 1
    endif
endif
" Latex_Box end
" }}}1

" {{{1 WrapSelection
" ------- Wrap Seclection ----------------------------
if !exists("*WrapSelection")
function! WrapSelection(wrapper,...)

    if a:0 == 0
	let l:end_wrapper='}'
    else
	let l:end_wrapper=a:1
    endif
    if a:0 >= 2
	let l:cursor_pos=a:2
    else
	let l:cursor_pos="end"
    endif
    if a:0 >= 3
	let l:new_line=a:3
    else
	let l:new_line=0
    endif

"     let b:new_line=l:new_line
"     let b:cursor_pos=l:cursor_pos
"     let b:end_wrapper=l:end_wrapper

    let l:begin=getpos("'<")
    " todo: if and on 'ą' we should go one character further! (this is
    " a multibyte character)
    let l:end=getpos("'>")
    let l:pos_save=getpos(".")

    " hack for that:
    let l:pos=deepcopy(l:end)
    keepjumps call setpos(".",l:end)
    execute 'normal l'
    let l:pos_new=getpos(".")
    if l:pos_new[2]-l:pos[2] > 1
	let l:end[2]+=l:pos_new[2]-l:pos[2]-1
    endif

    let l:begin_line=getline(l:begin[1])
    let l:end_line=getline(l:end[1])

    let b:begin=l:begin[1]
    let b:end=l:end[1]

    " ToDo: this doesn't work yet!
    let l:add_indent='    '
    if l:begin[1] != l:end[1]
	let l:bbegin_line=strpart(l:begin_line,0,l:begin[2]-1)
	let l:ebegin_line=strpart(l:begin_line,l:begin[2]-1)

	" DEBUG
	let b:bbegin_line=l:bbegin_line
	let b:ebegin_line=l:ebegin_line

	let l:bend_line=strpart(l:end_line,0,l:end[2])
	let l:eend_line=strpart(l:end_line,l:end[2])

	if l:new_line == 0
	    " inline
" 	    let b:debug=0
	    let l:begin_line=l:bbegin_line.a:wrapper.l:ebegin_line
	    let l:end_line=l:bend_line.l:end_wrapper.l:eend_line
	    call setline(l:begin[1],l:begin_line)
	    call setline(l:end[1],l:end_line)
	    let l:end[2]+=len(l:end_wrapper)
	else
	    let b:debug=1
	    " in seprate lines
	    let l:indent=atplib#CopyIndentation(l:begin_line)
	    if l:bbegin_line !~ '^\s*$'
		let b:debug.=1
		let l:begin_choice=1
		call setline(l:begin[1],l:bbegin_line)
		call append(l:begin[1],l:indent.a:wrapper) " THERE IS AN ISSUE HERE!
		call append(copy(l:begin[1])+1,l:indent.substitute(l:ebegin_line,'^\s*','',''))
		let l:end[1]+=2
" 		return
	    elseif l:bbegin_line =~ '^\s\+$'
		let b:debug.=2
		let l:begin_choice=2
		call append(l:begin[1]-1,l:indent.a:wrapper)
		call append(l:begin[1],l:begin_line.l:ebegin_line)
		let l:end[1]+=2
	    else
		let b:debug.=3
		let l:begin_choice=3
" 		let l:indent_b=atplib#CopyIndentation(l:begin_line)
		call append(copy(l:begin[1])-1,l:indent.a:wrapper)
" 		call append(l:begin[1],l:ebegin_line)
		let l:end[1]+=1
	    endif
	    if l:eend_line !~ '^\s*$'
		let b:debug.=4
		let l:end_choice=4
" 		let l:indent_e=atplib#CopyIndentation(l:bend_line)
		call setline(l:end[1],l:bend_line)
		call append(l:end[1],l:indent.l:end_wrapper)
		call append(copy(l:end[1])+1,l:indent.substitute(l:eend_line,'^\s*','',''))
	    else
		let b:debug.=5
		let l:end_choice=5
" 		let l:indent=atplib#CopyIndentation(l:bend_line)
" 		call setline(l:end[1],l:bend_line)
		call append(l:end[1],l:indent.l:end_wrapper)
	    endif
	    " indent lines in the middle: 
	    if (l:end[1] - l:begin[1]) >= 0
		let b:debug.=6
		if l:begin_choice == 1
		    let i=2
		elseif l:begin_choice == 2
		    let i=2
		elseif l:begin_choice == 3 
		    let i=1
		endif
		if l:end_choice == 5 
		    let j=l:end[1]-l:begin[1]+1
		else
		    let j=l:end[1]-l:begin[1]+1
		endif
		while i < j
		    " Adding indentation doesn't work in this simple way here?
		    " but the result is ok.
		    call setline(l:begin[1]+i,l:indent.l:add_indent.getline(l:begin[1]+i))
		    let i+=1
		endwhile
	    endif
	    let l:end[1]+=2
	    let l:end[2]=1
	endif
    else
	let l:begin_l=strpart(l:begin_line,0,l:begin[2]-1)
	let l:middle_l=strpart(l:begin_line,l:begin[2]-1,l:end[2]-l:begin[2]+1)
	let l:end_l=strpart(l:begin_line,l:end[2])
	if l:new_line == 0
	    " inline
" 	    let b:debug="X1"
	    let l:line=l:begin_l.a:wrapper.l:middle_l.l:end_wrapper.l:end_l
	    call setline(l:begin[1],l:line)
	    let l:end[2]+=len(a:wrapper)+1
	else
" 	    let b:debug="X1"
	    " in seprate lines

	    let b:begin_l=l:begin_l
	    let b:middle_l=l:middle_l
	    let b:end_l=l:end_l

	    let l:indent=atplib#CopyIndentation(l:begin_line)
	    let b:debug="  ".len(l:indent)

	    if l:begin_l =~ '\S' 
		call setline(l:begin[1],l:begin_l)
		call append(copy(l:begin[1]),l:indent.a:wrapper)
		call append(copy(l:begin[1])+1,l:indent.l:add_indent.l:middle_l)
		call append(copy(l:begin[1])+2,l:indent.l:end_wrapper)
		if substitute(l:end_l,'^\s*','','') =~ '\S'
		    call append(copy(l:begin[1])+3,l:indent.substitute(l:end_l,'^\s*','',''))
		endif
	    else
		call setline(copy(l:begin[1]),l:indent.a:wrapper)
		call append(copy(l:begin[1]),l:indent.l:add_indent.l:middle_l)
		call append(copy(l:begin[1])+1,l:indent.l:end_wrapper)
		if substitute(l:end_l,'^\s*','','') =~ '\S'
		    call append(copy(l:begin[1])+2,l:indent.substitute(l:end_l,'^\s*','',''))
		endif
	    endif
	endif
    endif
    if l:cursor_pos == "end"
	let l:end[2]+=len(l:end_wrapper)-1
	call setpos(".",l:end)
    elseif l:cursor_pos =~ '\d\+'
	let l:pos=l:begin
	let l:pos[2]+=l:cursor_pos
	call setpos(".",l:pos)
    elseif l:cursor_pos == "current"
	keepjumps call setpos(".",l:pos_save)
    elseif l:cursor_pos == "begin"
	let l:begin[2]+=len(a:wrapper)-1
	keepjumps call setpos(".",l:begin)
    endif
endfunction
endif
"}}}1
" {{{1  RELOAD

if !exists("g:debug_atp_plugin")
    let g:debug_atp_plugin=0
endif
if g:debug_atp_plugin==1 && !exists("*Reload")
" Reload() - reload all the tex_apt functions
" Reload(func1,func2,...) reload list of functions func1 and func2
fun! Reload(...)
    let l:pos_saved=getpos(".")
    let l:bufname=fnamemodify(expand("%"),":p")

    if a:0 == 0
	let l:runtime_path=split(&runtimepath,',')
	echo "Searching for atp plugin files"
	let l:file_list=['ftplugin/tex_atp.vim', 'ftplugin/fd_atp.vim', 
		    \ 'ftplugin/bibsearch_atp.vim', 'ftplugin/toc_atp.vim', 
		    \ 'autoload/atplib.vim', 'ftplugin/atp_LatexBox.vim' ]
	let l:file_path=[]
	for l:file in l:file_list
		call add(l:file_path,globpath(&rtp,l:file))
	endfor
	for l:file in l:file_path
	    echomsg "deleting FUNCTIONS and VARIABLES from " . l:file
	    let l:atp=readfile(l:file)
	    for l:line in l:atp
		let l:function_name=matchstr(l:line,'^\s*fun\%(ction\)\?!\?\s\+\zs\<[^(]*\>\ze(')
		if l:function_name != "" && l:function_name != "Reload"
		    if exists("*" . l:function_name)
			if exists("b:atp_debug")
			    if b:atp_debug == "v" || b:atp_debug == "verbose"
				echomsg "deleting function " . l:function_name
			    endif
			endif
			execute "delfunction " . l:function_name
		    endif
		endif
		let l:variable_name=matchstr(l:line,'^\s*let\s\+\zsg:[a-zA-Z_^{}]*\ze\>')
		if exists(l:variable_name)
		    execute "unlet ".l:variable_name
		    if exists("b:atp_debug")
			if b:atp_debug == "v" || b:atp_debug == "verbose"
			    echomsg l:variable_name
			endif
		    endif
		endif
	    endfor
	endfor
    else
	if a:1 != "maps" && a:1 != "reload"
	    let l:f_list=split(a:1,',')
	    let g:f_list=l:f_list
	    for l:function in l:f_list
		execute "delfunction " . l:function
	    endfor
	endif
    endif
    au! CursorHold *.tex
    w
"   THIS IS THE SLOW WAY:
    bd!
    execute "edit " . fnameescape(l:bufname)
    keepjumps call setpos(".",l:pos_saved)
"   This could be faster: but aparently doesn't work.
"     execute "source " . l:file_path[0]
endfunction
endif
command -buffer -nargs=* -complete=function Reload	:call Reload(<f-args>)
" }}}1
" {{{1 MAPS
" Add maps, unless the user didn't want this.
" ToDo: to doc.
if !exists("no_plugin_maps") && !exists("no_atp_maps")
    " ToDo to doc.
    map <buffer> <LocalLeader>ns :NSec<CR>
    map <buffer> <LocalLeader>ps :PSec<CR>
    map <buffer> <LocalLeader>nc :NChap<CR>
    map <buffer> <LocalLeader>pc :PChap<CR>
    map <buffer> <LocalLeader>np :NPart<CR>
    map <buffer> <LocalLeader>pp :PPart<CR>
    " ToDo to doc.
    if exists("g:atp_no_tab_map") && g:atp_no_tab_map == 1
	imap <buffer> <F7> <C-R>=atplib#TabCompletion(1)<CR>
	nmap <buffer> <F7>	:call atplib#TabCompletion(1,1)<CR>
	imap <buffer> <S-F7> <C-R>=atplib#TabCompletion(0)<CR>
	nmap <buffer> <S-F7>	:call atplib#TabCompletion(0,1)<CR> 
    else 
	" the default:
	imap <buffer> <Tab> <C-R>=atplib#TabCompletion(1)<CR>
	" HOW TO: do this with <tab>? Streightforward solution interacts with
	" other maps (e.g. after \l this map is called).
" when this is set it also runs after the \l map: ?!?
" 	nmap <buffer> <Tab>	:call atplib#TabCompletion(1,1)<CR>
	imap <buffer> <S-Tab> <C-R>=atplib#TabCompletion(0)<CR>
	nmap <buffer> <S-Tab>	:call atplib#TabCompletion(0,1)<CR> 
	vmap <buffer> <silent> <F7> <Esc>:call WrapSelection('')<CR>i
    endif

"     nmap <buffer> <F7>c :call atplib#CloseLastEnvironment()<CR>
"     imap <buffer> <F7>c <Esc>:call atplib#CloseLastEnvironment()<CR>i
"     nmap <buffer> <F7>b :call atplib#CloseLastBracket()<CR>
"     imap <buffer> <F7>b <Esc>:call atplib#CloseLastBracket()<CR>i

" Done: to doc:
    " Fonts
    vmap <buffer> f				:WrapSelection '{\usefont{'.g:atp_font_encoding.'}{}{}{}\selectfont ', '}',(len(g:atp_font_encoding)+11)<CR>

    if !exists("g:atp_vmap_text_font_leader")
	let g:atp_vmap_text_font_leader="<LocalLeader>"
    else
	let g:debug=1
    endif
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."rm		:WrapSelection '"."\\"."textrm{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."em		:WrapSelection '"."\\"."emph{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."it		:WrapSelection '"."\\"."textit{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."sf		:WrapSelection '"."\\"."textsf{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."tt		:WrapSelection '"."\\"."texttt{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."bf		:WrapSelection '"."\\"."textbf{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."sl		:WrapSelection '"."\\"."textsl{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."sc		:WrapSelection '"."\\"."textsc{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."up		:WrapSelection '"."\\"."textup{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."md		:WrapSelection '"."\\"."textmd{'<CR>"

    " Math Fonts
    if !exists("g:atp_vmap_text_font_leader")
	let g:atp_vmap_math_font_leader="<LocalLeader>m"
    endif
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."rm		:WrapSelection '"."\\"."mathrm{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."bf		:WrapSelection '"."\\"."mathbf{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."it		:WrapSelection '"."\\"."mathit{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."sf		:WrapSelection '"."\\"."mathsf{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."tt		:WrapSelection '"."\\"."mathtt{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."n		:WrapSelection '"."\\"."mathnormal{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."cal		:WrapSelection '"."\\"."mathcal{'<CR>"
"     vmap <buffer> <LocalLeader>c				:WrapSelection '\textcolor{}{','}','10'<CR>

    " Environments
    if !exists("atp_vmap_environment_leader")
	let g:atp_vmap_environment_leader=""
    endif
    execute "vmap <buffer> ".g:atp_vmap_environment_leader."C   :WrapSelection '"."\\"."begin{center}','"."\\"."end{center}','0','1'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_environment_leader."R   :WrapSelection '"."\\"."begin{flushright}','"."\\"."end{flushright}','0','1'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_environment_leader."L   :WrapSelection '"."\\"."begin{flushleft}','"."\\"."end{flushleft}','0','1'<CR>"

    " Math modes
    vmap <buffer> m						:WrapSelection '\(', '\)'<CR>
    vmap <buffer> M						:WrapSelection '\[', '\]'<CR>

    " Brackets
    if !exists("*atp_vmap_bracket_leader")
	let g:atp_vmap_bracket_leader="<LocalLeader>"
    endif
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader."( 	:WrapSelection '(', ')', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader."[ 	:WrapSelection '[', ']', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader."{ 	:WrapSelection '{', '}', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader.")	:WrapSelection '(', ')', 'end'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader."]	:WrapSelection '[', ']', 'end'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader."}	:WrapSelection '{', '}', 'end'<CR>"

    if !exists("*atp_vmap_big_bracket_leader")
	let g:atp_vmap_big_bracket_leader='<LocalLeader>b'
    endif
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader."(	:WrapSelection '"."\\"."left(', '"."\\"."right)', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader."[	:WrapSelection '"."\\"."left[', '"."\\"."right]', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader."{	:WrapSelection '"."\\"."left{', '"."\\"."right}', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader.")	:WrapSelection '"."\\"."left(', '"."\\"."right)', 'end'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader."]	:WrapSelection '"."\\"."left[', '"."\\"."right]', 'end'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader."}	:WrapSelection '"."\\"."left{', '"."\\"."right}', 'end'<CR>"

    " Normal mode maps (mostly)
    nmap  <buffer> <LocalLeader>v		:call ViewOutput() <CR><CR>
    nmap  <buffer> <F2> 			:ToggleSpace<CR>
    nmap  <buffer> <LocalLeader>s		:call ToggleStar()<CR>
    nmap  <buffer> <F4>				:call ToggleEnvironment()<CR>
    nmap  <buffer> <S-F4>			:call ToggleEnvironment(-1)<CR>
    nmap  <buffer> <F3>        			:call ViewOutput() <CR><CR>
    imap  <buffer> <F3> <Esc> 			:call ViewOutput() <CR><CR>
    nmap  <buffer> <LocalLeader>g 		:call Getpid()<CR>
    nmap  <buffer> <LocalLeader>t		:call TOC(1)<CR>
    nmap  <buffer> <LocalLeader>L		:Labels<CR>
    nmap  <buffer> <LocalLeader>l 		:TEX<CR>	
    nmap  <buffer> 2<LocalLeader>l 		:2TEX<CR>	 
    nmap  <buffer> 3<LocalLeader>l		:3TEX<CR>
    nmap  <buffer> 4<LocalLeader>l		:4TEX<CR>
    " imap <buffer> <LocalLeader>l	<Left><ESC>:TEX<CR>a
    " imap <buffer> 2<LocalLeader>l	<Left><ESC>:2TEX<CR>a
    " todo: this is nice idea but it do not works as it should: 
    " map  <buffer> <f4> [d:let nr = input("which one: ")<bar>exe "normal " . nr . "[\t"<CR> 
    nmap  <buffer> <F5> 				:call VTEX() <CR>	
    nmap  <buffer> <s-F5> 			:call ToggleAuTeX()<CR>
    nmap  <buffer> `<Tab>			:call ToggleTab()<CR>
    imap <buffer> <F5> <left><esc> 		:call VTEX() <CR>a
    nmap  <buffer> <localleader>B		:call SimpleBibtex()<CR>
    nmap  <buffer> <localleader>b		:call Bibtex()<CR>
    nmap  <buffer> <F6>d 			:call Delete() <CR>
    imap <buffer> <silent> <F6>l 		:call OpenLog() <CR>
    nmap  <buffer> <silent> <F6>l 		:call OpenLog() <CR>
    nmap  <buffer> <localleader>e 		:cf<CR> 
    nmap  <buffer> <F6> 			:ShowErrors e<CR>
    imap <buffer> <F6> 				:ShowErrors e<CR>
    nmap  <buffer> <F6>w 			:ShowErrors w<CR>
    imap <buffer> <F6>w 			:ShowErrors w<CR>
    nmap  <buffer> <F6>r 			:ShowErrors rc<CR>
    nmap <buffer> <F6>r 			:ShowErrors rc<CR>
    nmap  <buffer> <F6>f 			:ShowErrors f<CR>
    imap <buffer> <F6>f 			:ShowErrors f<CR>
    nmap  <buffer> <F6>g 			:call PdfFonts()<CR>
    nmap  <buffer> <F1> 	   			:!clear;texdoc -m 
    imap <buffer> <F1> <esc> 			:!clear;texdoc -m  
    nmap  <buffer> <localleader>p 		:call print('','')<CR>

    " FONT MAPPINGS
    execute 'imap <buffer> '.g:atp_imap_second_leader.'rm \textrm{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'up \textup{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'md \textmd{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'it \textit{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'sl \textsl{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'sc \textsc{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'sf \textsf{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'bf \textbf{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'tt \texttt{}<Left>'
	    
    execute 'imap <buffer>' .g:atp_imap_second_leader.'mit \mathit{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'mrm \mathrm{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'msf \mathsf{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'mbf \mathbf{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'mtt \mathtt{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'mcal \mathcal{}<Left>'

    " GREEK LETTERS
    execute 'imap <buffer> '.g:atp_imap_first_leader.'a \alpha'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'b \beta'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'c \chi'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'d \delta'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'e \epsilon'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'f \phi'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'y \psi'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'g \gamma'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'h \eta'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'k \kappa'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'l \lambda'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'i \iota'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'m \mu'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'n \nu'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'p \pi'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'o \theta'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'r \rho'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'s \sigma'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'t \tau'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'u \upsilon'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'vs \varsigma'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'vo \vartheta'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'w \omega'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'x \xi'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'z \zeta'

    execute 'imap <buffer> '.g:atp_imap_first_leader.'D \Delta'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'Y \Psi'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'F \Phi'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'G \Gamma'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'L \Lambda'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'M \Mu'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'N \Nu'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'P \Pi'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'O \Theta'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'S \Sigma'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'T \Tau'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'U \Upsilon'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'V \Varsigma'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'W \Omega'

    if g:atp_no_env_maps != 1
	if g:atp_env_maps_old == 1
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'b \begin{}<Left>'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'e \end{}<Left>'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'c \begin{center}<CR>\end{center}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'c \begin{corollary}<CR>\end{corollary}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'d \begin{definition}<CR>\end{definition}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'e \begin{enumerate}<CR>\end{enumerate}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'a \begin{align}<CR>\end{align}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'i \item'
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'i \begin{itemize}<CR>\end{itemize}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'l \begin{lemma}<CR>\end{lemma}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'p \begin{proof}<CR>\end{proof}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'p \begin{proposition}<CR>\end{proposition}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'t \begin{theorem}<CR>\end{theorem}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'t \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>'

	    if g:atp_extra_env_maps == 1
		execute 'imap <buffer> '.g:atp_imap_third_leader.'r \begin{remark}<CR>\end{remark}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_fourth_leader.'l \begin{flushleft}<CR>\end{flushleft}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_third_leader.'r \begin{flushright}<CR>\end{flushright}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_third_leader.'f \begin{frame}<CR>\end{frame}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_fourth_leader.'q \begin{equation}<CR>\end{equation}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_third_leader.'n \begin{note}<CR>\end{note}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_third_leader.'o \begin{observation}<CR>\end{observation}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_third_leader.'x \begin{example}<CR>\end{example}<Esc>O'
	    endif
	else
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'b \begin{}<Left>'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'e \end{}<Left>'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'c \begin{center}<CR>\end{center}<Esc>O'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'d \begin{definition}<CR>\end{definition}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'t \begin{theorem}<CR>\end{theorem}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'P \begin{proposition}<CR>\end{proposition}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'l \begin{lemma}<CR>\end{lemma}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'r \begin{remark}<CR>\end{remark}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'o \begin{corollary}<CR>\end{corollary}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'p \begin{proof}<CR>\end{proof}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'x \begin{example}<CR>\end{example}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'n \begin{note}<CR>\end{note}<Esc>O'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'u \begin{enumerate}<CR>\end{enumerate}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'i \begin{itemize}<CR>\end{itemize}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'I \item'


	    execute 'imap <buffer> '.g:atp_imap_third_leader.'a \begin{align}<CR>\end{align}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'q \begin{equation}<CR>\end{equation}<Esc>O'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'l \begin{flushleft}<CR>\end{flushleft}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'R \begin{flushright}<CR>\end{flushright}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'z \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'f \begin{frame}<CR>\end{frame}<Esc>O'
	endif

	" imap {c \begin{corollary*}<CR>\end{corollary*}<Esc>O
	" imap {d \begin{definition*}<CR>\end{definition*}<Esc>O
	" imap {x \begin{example*}\normalfont<CR>\end{example*}<Esc>O
	" imap {l \begin{lemma*}<CR>\end{lemma*}<Esc>O
	" imap {n \begin{note*}<CR>\end{note*}<Esc>O
	" imap {o \begin{observation*}<CR>\end{observation*}<Esc>O
	" imap {p \begin{proposition*}<CR>\end{proposition*}<Esc>O
	" imap {r \begin{remark*}<CR>\end{remark*}<Esc>O
	" imap {t \begin{theorem*}<CR>\end{theorem*}<Esc>O
    endif

    imap <buffer> __ _{}<Left>
    imap <buffer> ^^ ^{}<Left>
    imap <buffer> ]m \(\)<Left><Left>
    imap <buffer> ]M \[\]<Left><Left>
endif
" }}}1
" {{{1 Syntax for tikz coordinates
" This is an additional syntax group for enironment provided by the TIKZ
" package, a very powerful tool to make beautiful diagrams, and all sort of
" pictures in latex.
syn match texTikzCoord '\(|\)\?([A-Za-z0-9]\{1,3})\(|\)\?\|\(|\)\?(\d\d)|\(|\)\?'
"}}}1
" {{{1 COMMANDS
command! -buffer ViewOutput					:call ViewOutput()
command! -buffer SetErrorFile					:call SetErrorFile()
command! -buffer -nargs=? ShowOptions				:call ShowOptions(<f-args>)
command! -buffer GPID						:call Getpid()
command! -buffer CXPDF						:echo s:xpdfpid()
command! -buffer -nargs=? -count=1 TEX				:call TEX(<count>,<f-args>)
command! -buffer -nargs=? -count=1 VTEX				:call VTEX(<count>,<f-args>)
command! -buffer SBibtex					:call SimpleBibtex()
command! -buffer -nargs=? Bibtex				:call Bibtex(<f-args>)
command! -buffer -nargs=? -complete=buffer FindBibFiles 	:echo keys(FindBibFiles(<f-args>))
command! -buffer -nargs=* BibSearch				:call BibSearch(<f-args>)
command! -buffer -nargs=* DefiSearch				:call DefiSearch(<f-args>)
command! -buffer -nargs=* FontSearch	:call atplib#FontSearch(<f-args>)
command! -buffer -nargs=* FontPreview	:call atplib#FontPreview(<f-args>)
command! -buffer -nargs=1 -complete=customlist,atplib#Fd_completion OpenFdFile	:call atplib#OpenFdFile(<f-args>) 
command! -buffer TOC						:call TOC()
command! -buffer CTOC						:call CTOC()
command! -buffer Labels						:call Labels() 
command! -buffer SetOutDir					:call s:setoutdir(1)
command! -buffer ATPStatus					:call ATPStatus() 
command! -buffer PdfFonts					:call PdfFonts()
command! -buffer -nargs=? -range WrapSelection			:call WrapSelection(<args>)
command! -buffer -nargs=? 					SetErrorFormat 	:call s:SetErrorFormat(<f-args>)
command! -buffer -nargs=? -complete=custom,ListErrorsFlags 	ShowErrors 	:call s:ShowErrors(<f-args>)
command! -buffer 						OpenLog		:call OpenLog()
command! -buffer -nargs=? -complete=buffer	 		FindInputFiles	:call FindInputFiles(<f-args>)
command! -buffer -nargs=* -complete=customlist,EI_compl	 	EditInputFile 	:call EditInputFile(<f-args>)
command! -buffer -nargs=? -complete=buffer	 ToDo			:call ToDo('\c\<to\s*do\>','\s*%\c.*\<note\>',<f-args>)
command! -buffer -nargs=? -complete=buffer	 Note			:call ToDo('\c\<note\>','\s*%\c.*\<to\s*do\>',<f-args>)
command! -buffer SetXdvi		:call SetXdvi()
command! -buffer SetXpdf		:call SetXpdf()	
command! -complete=custom,ListPrinters  -buffer -nargs=* SshPrint	:call Print(<f-args>)
command! -buffer Lpstat	:call Lpstat()
command! -buffer LocalCommands		:call LocalCommands()

command! -buffer -nargs=* CloseLastEnvironment	:call atplib#CloseLastEnvironment(<f-args>)
command! -buffer 	  CloseLastBracket	:call atplib#CloseLastBracket()

" to do make count for this commands and maps!
command! -buffer -count=1 -nargs=1 -complete=customlist,Env_compl NEnv		:call NextEnv(<f-args>)
command! -buffer -count=1 -nargs=1 -complete=customlist,Env_compl PEnv		:call PrevEnv(<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NSec		:call NextSection('section',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PSec		:call PrevSection('section',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NChap		:call NextSection('chapter',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PChap		:call PrevSection('chapter',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl NPart		:call NextSection('part',<f-args>)
command! -buffer -count=1 -nargs=? -complete=customlist,Env_compl PPart		:call PrevSection('part',<f-args>)
command! -buffer 	ToggleSpace 		:call ToggleSpace()
command! -buffer -nargs=? ToggleEnvironment  	:call ToggleEnvironment(<f-args>)
command! -buffer 	ToggleStar   		:call ToggleStar()
command! -buffer 	ToggleTab   		:call ToggleTab()
command! -buffer 	ToggleCheckMathOpened 	:call ToggleCheckMathOpened()
command! -buffer 	ToggleDebugMode 	:call ToggleDebugMode()
command! -buffer 	ToggleCallBack 		:call ToggleCallBack()
" }}}1
" {{{1 MENU
if !exists("no_plugin_menu") && !exists("no_atp_menu")
nmenu 550.10 &LaTeX.&Make<Tab>:TEX						:TEX<CR>
nmenu 550.10 &LaTeX.Make\ &twice<Tab>:2TEX					:2TEX<CR>
nmenu 550.10 &LaTeX.Make\ verbose<Tab>:VTEX					:VTEX<CR>
nmenu 550.10 &LaTeX.&Bibtex<Tab>:Bibtex						:Bibtex<CR>
" nmenu 550.10 &LaTeX.&Bibtex\ (bibtex)<Tab>:SBibtex				:SBibtex<CR>
nmenu 550.10 &LaTeX.&View<Tab>:ViewOutput 					:ViewOutput<CR>
"
nmenu 550.20.1 &LaTeX.&Errors<Tab>:ShowErrors					:ShowErrors<CR>
nmenu 550.20.1 &LaTeX.&Log.&Open\ Log\ File<Tab>:map\ <F6>l			:call OpenLog()<CR>
if g:atp_callback
    nmenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [on]<Tab>g:atp_callback		:call ToggleCallBack()<CR>
else
    nmenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [off]<Tab>g:atp_callback		:call ToggleCallBack()<CR>
endif  
if g:atp_debug_mode
    nmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [on]			:call ToggleDebugMode()<CR>
else
    nmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [off]			:call ToggleDebugMode()<CR>
endif  
nmenu 550.20.20 &LaTeX.&Log.-ShowErrors-	:
nmenu 550.20.20 &LaTeX.&Log.&Warnings<Tab>:ShowErrors\ w 			:ShowErrors w<CR>
nmenu 550.20.20 &LaTeX.&Log.&Citation\ Warnings<Tab>:ShowErrors\ c		:ShowErrors c<CR>
nmenu 550.20.20 &LaTeX.&Log.&Reference\ Warnings<Tab>:ShowErrors\ r		:ShowErrors r<CR>
nmenu 550.20.20 &LaTeX.&Log.&Font\ Warnings<Tab>ShowErrors\ f			:ShowErrors f<CR>
nmenu 550.20.20 &LaTeX.&Log.Font\ Warnings\ &&\ Info<Tab>:ShowErrors\ fi	:ShowErrors fi<CR>
nmenu 550.20.20 &LaTeX.&Log.&Show\ Files<Tab>:ShowErrors\ F			:ShowErrors F<CR>
"
nmenu 550.20.20 &LaTeX.&Log.-PdfFotns- :
nmenu 550.20.20 &LaTeX.&Log.&Pdf\ Fonts<Tab>:PdfFonts				:PdfFonts<CR>

nmenu 550.20.20 &LaTeX.&Log.-Delete-	:
nmenu 550.20.20 &LaTeX.&Log.&Delete\ Tex\ Output\ Files<Tab>:map\ <F6>d		:call Delete()<CR>
nmenu 550.20.20 &LaTeX.&Log.Set\ Error\ File<Tab>:SetErrorFile			:SetErrorFile<CR> 
"
nmenu 550.30 &LaTeX.-TOC- :
nmenu 550.30 &LaTeX.&Table\ of\ Contents<Tab>:TOC				:TOC<CR>
nmenu 550.30 &LaTeX.L&abels<Tab>:Labels						:Labels<CR>
"
nmenu 550.40 &LaTeX.&Go\ to.&EditInputFile<Tab>:EditInputFile			:EditInputFile<CR>
"
nmenu 550.40 &LaTeX.&Go\ to.-Environment- :
nmenu 550.40 &LaTeX.&Go\ to.Next\ Definition<Tab>:NEnv\ definition		:NEnv definition<CR>
nmenu 550.40 &LaTeX.&Go\ to.Previuos\ Definition<Tab>:PEnv\ definition		:PEnv definition<CR>
nmenu 550.40 &LaTeX.&Go\ to.Next\ Environment<Tab>:NEnv\ <arg>			:NEnv 
nmenu 550.40 &LaTeX.&Go\ to.Previuos\ Environment<Tab>:PEnv\ <arg>		:PEnv 
"
nmenu 550.40 &LaTeX.&Go\ to.-Section- :
nmenu 550.40 &LaTeX.&Go\ to.&Next\ Section<Tab>:NSec				:NSec<CR>
nmenu 550.40 &LaTeX.&Go\ to.&Previuos\ Section<Tab>:PSec			:PSec<CR>
nmenu 550.40 &LaTeX.&Go\ to.Next\ Chapter<Tab>:NChap				:NChap<CR>
nmenu 550.40 &LaTeX.&Go\ to.Previous\ Chapter<Tab>:PChap			:PChap<CR>
nmenu 550.40 &LaTeX.&Go\ to.Next\ Part<Tab>:NPart				:NPart<CR>
nmenu 550.40 &LaTeX.&Go\ to.Previuos\ Part<Tab>:PPart				:PPart<CR>
"
nmenu 550.50 &LaTeX.-Bib-			:
nmenu 550.50 &LaTeX.Bib\ Search<Tab>:Bibsearch\ <arg>				:BibSearch 
nmenu 550.50 &LaTeX.Find\ Bib\ Files<Tab>:FindBibFiles				:FindBibFiles<CR> 
nmenu 550.50 &LaTeX.Find\ Input\ Files<Tab>:FindInputFiles			:FindInputFiles<CR>
"
nmenu 550.60 &LaTeX.-Viewer-			:
nmenu 550.60 &LaTeX.Set\ &XPdf<Tab>:SetXpdf					:SetXpdf<CR>
nmenu 550.60 &LaTeX.Set\ X&Dvi\ (inverse\/reverse\ search)<Tab>:SetXdvi		:SetXdvi<CR>
"
nmenu 550.70 &LaTeX.-Editting-			:
"
" ToDo: show options doesn't work from the menu (it disappears immediately, but at
" some point I might change it completely)
nmenu 550.70 &LaTeX.&Options.&Show\ Options<Tab>:ShowOptions			:ShowOptions<CR> 
nmenu 550.70 &LaTeX.&Options.-set\ options- :
nmenu 550.70 &LaTeX.&Options.Automatic\ TeX\ Processing<Tab>b:autex		:let b:autex=
nmenu 550.70 &LaTeX.&Options.Set\ Runs<Tab>b:auruns				:let b:auruns=
nmenu 550.70 &LaTeX.&Options.Set\ TeX\ Compiler<Tab>b:texcompiler		:let b:texcompiler="
nmenu 550.70 &LaTeX.&Options.Set\ Viewer<Tab>b:Viewer				:let b:Viewer="
nmenu 550.70 &LaTeX.&Options.Set\ Viewer\ Options<Tab>b:ViewerOptions		:let b:ViewerOptions="
nmenu 550.70 &LaTeX.&Options.Set\ Output\ Directory<Tab>b:outdir		:let b:ViewerOptions="
nmenu 550.70 &LaTeX.&Options.Set\ Output\ Directory\ to\ the\ default\ value<Tab>:SetOutDir	:SetOutDir<CR> 
nmenu 550.70 &LaTeX.&Options.Ask\ for\ the\ Output\ Directory<Tab>g:askfortheoutdir		:let g:askfortheoutdir="
nmenu 550.70 &LaTeX.&Options.Open\ Viewer<Tab>b:openviewer			:let b:openviewer="
nmenu 550.70 &LaTeX.&Options.Open\ Viewer<Tab>b:openviewer			:let b:openviewer="
nmenu 550.70 &LaTeX.&Options.Set\ Error\ File<Tab>:SetErrorFile			:SetErrorFile<CR> 
nmenu 550.70 &LaTeX.&Options.Which\ TeX\ files\ to\ copy<Tab>g:keep		:let g:keep="
nmenu 550.70 &LaTeX.&Options.Tex\ extensions<Tab>g:atp_tex_extensions		:let g:atp_tex_extensions="
nmenu 550.70 &LaTeX.&Options.Remove\ Command<Tab>g:rmcommand			:let g:rmcommand="
nmenu 550.70 &LaTeX.&Options.Default\ Bib\ Flags<Tab>g:defaultbibflags		:let g:defaultbibflags="
"
nmenu 550.78 &LaTeX.&Toggle\ Space\ [off]					:ToggleSpace<CR>
if g:atp_math_opened
    nmenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [on]<Tab>g:atp_math_opened  :ToggleCheckMathOpened<CR>
else
    nmenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [off]<Tab>g:atp_math_opened :ToggleCheckMathOpened<CR>
endif
tmenu &LaTeX.&Toggle\ Space\ [off] cmap <space> \_s\+ is curently off
" ToDo: add menu for printing.
endif
"}}}1
" vim:fdm=marker:ff=unix:noet:ts=8:sw=4:fdc=1
