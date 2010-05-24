" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 May 23
" URL:		
" GetLatestVimScripts: 2945 16 :AutoInstall: tex_atp.vim
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
"
" ToDo: tikz commands showup in ordinary math environment \(:\).
"
" Todo: make small Help functions with list of most important mappings and
" commands for each window (this can help at the begining) make it possible to
" turn it off.
"
" Todo: write commands to help choose nice fonts! (Integrate my bash script).
"
" Todo: update mappings <F6>+w r f (see :h atp-texlog). 
"
" Todo: check completion for previous/next environment with MCNw.tex there are
" some ambiguities.
"
" Done: using a symbolic link, run \v it will use the name of symbolic name
" not the target. Also the name of the xpdfserver is taken from the actually
" opend file (for example input file) and not the target name of the link. 
" Look intfor b:texcommand.
"
" Done: modify EditInputFiles so that it finds file in the g:mainfile
"
" Done: EditInputFile if running from an input file a main file should be
" added. Or there should be a function to come back.
"
" Done: make a function which list all definitions
"
" TODO: bibtex is not processing right (after tex+bibtex+tex+tex, +\l gives
" the citation numbers)
"
" Done: g:mainfile is not working with b:outdir, (b:outdir should not be
" changed for input files)
"
" TODO: to make s:maketoc and s:generatelabels read all input files between
" \begin{document} and \end{document}, and make it recursive.
" now s:maketoc finds only labels of chapters/sections/...
" TODO: make toc work with parts!
"
" Comment: The time consuming part of TOC command is: opening new window
" ('vnew') as shown by profiling.
"
" TODO: pid file
" Comment: b:changedtick "HOW MANY CHANGES WERE DONE! this could be useful.
"
" TODO: Check against lilypond 
"
" Done: make a split version of EditInputFile
"
" Done: for input files which filetype=plaintex (for example hyphenation
" files), the variable b:autex is not set. Just added plaintex_atp.vim file
" which sources tex_atp.vim file.  
"
" NOTES
" s:tmpfile =	temporary file value of tempname()
" b:texfile =	readfile(bunfname("%")

" We need to know bufnumber and bufname in a tabpage.
let t:bufname=bufname("")
let t:bufnr=bufnr("")
let t:winnr=winnr()

" This limits how many consecutive runs there can be maximally.
let s:runlimit=5 

" These autocommands are used to remember the last opened buffer number and its
" window number:
au BufLeave *.tex let t:bufname=resolve(fnamemodify(bufname(""),":p"))
au BufLeave *.tex let t:bufnr=bufnr("")
" t:winnr the last window used by tex, ToC or Labels buffers:
au WinEnter *.tex let t:winnr=winnr("#")
au WinEnter __ToC__ 	let t:winnr=winnr("#")
au WinEnter __Labels__ 	let t:winnr=winnr("#")

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

" Options
setl keywordprg=texdoc\ -m
" setl matchpairs='(:),[:],{:}' " multibyte characters are not supported yet
" so \(:\), \[:\] want work :(. New function
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

"------------ append / at the end of a directory name ------------
fun! s:append(where,what)
    return substitute(a:where,a:what . "\s*$",'','') . a:what
endfun
" ----------------- FindInputFiles ---------------
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
    " this function is used to set g:mainfile, but at this stage there is no
    " need to add g:mainfile to the list of input files (this is also
    " a requirement for the function s:setprojectname.
    if exists("g:mainfile")
	call extend(l:inputfiles, { fnamemodify(g:mainfile,":t") : ['main file', g:mainfile]}, "error") 
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
" ----------------- FIND BIB FILES ----------------------------------	
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
	let b:texfile=readfile(l:bufname,":p")
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

    " this variable will store unreadable bibfiles:    
    let s:notreadablebibfiles=[]

    " this variable will store the final result:   
    let l:bibfiles={}

    for l:f in l:allbibfiles
	" ToDo: change this to find in any directory under g:bibinputs. 
	" also change in the line 1406 ( s:searchbib )
	if filereadable(b:outdir . s:append(l:f,'.bib')) 
" 		    || filereadable(s:append(g:bibinputs,"/") . s:append(l:f,'.bib'))
	    call extend(l:bibfiles,{l:f : [ 'bib' , fnamemodify(expand("%"),":p") ] })
	elseif filereadable(findfile(s:append(l:f,'.bib'),s:append(g:bibinputs,"/") . "**"))
	    call extend(l:bibfiles,{l:f : [ 'bib' , fnamemodify(expand("%"),":p") ] })
	else
	    " echo warning if a bibfile is not readable
	    echohl WarningMsg | echomsg "Bibfile " . l:f . ".bib not found." | echohl None
	    if count(s:notreadablebibfiles,l:f) == 0 
		call add(s:notreadablebibfiles,l:f)
	    endif
	endif
    endfor

    " return the list  of readable bibfiles
    return l:bibfiles
endfunction
endif
"--------------------SHOW ALL DEFINITIONS----------------------------

function! s:make_defi_dict()
    "dictionary: { input_file : [[beginning_line,end_line],...] }
    let l:defi_dict={}


    let l:inputfiles=FindInputFiles(bufname("%"),"0")
    let l:input_files=[]

    for l:inputfile in keys(l:inputfiles)
	if l:inputfiles[l:inputfile][0] != "bib"
	    let l:input_file=s:append(l:inputfile,'.tex')
	    if filereadable(b:outdir . '/' . l:input_file)
		let l:input_file=b:outdir . '/' . l:input_file
	    else
		let l:input_file=findfile(l:inputfile,g:texmf . '**')
	    endif
	    call add(l:input_files, l:input_file)
	endif
    endfor

    let l:input_files=filter(l:input_files, 'v:val != ""')
    call extend(l:input_files,[ g:mainfile ])

    if len(l:input_files) > 0
    for l:inputfile in l:input_files
	let l:defi_dict[l:inputfile]=[]
	" do not search for definitions in bib files 
	"TODO: it skips lines somehow. 
	let l:ifile=readfile(l:inputfile)
	
	" search for definitions
	let l:lnr=1
	while l:lnr <= len(l:ifile)

	    let l:match=0

	    let l:line=l:ifile[l:lnr-1]
	    if substitute(l:line,'%.*','','') =~ '\\def'

		let l:b_line=l:lnr
		let l:open=s:count(l:line,'{')    
		let l:close=s:count(l:line,'}')

		let l:lnr+=1	
		while l:open != l:close
		    "go to next line and count if the definition ends at
		    "this line
		    let l:line=l:ifile[l:lnr-1]
		    let l:open+=s:count(l:line,'{')    
		    let l:close+=s:count(l:line,'}')
		    let l:lnr+=1	
		endwhile
		let l:e_line=l:lnr-1
		call add(l:defi_dict[l:inputfile], [ l:b_line, l:e_line ])
	    else
		let l:lnr+=1
	    endif
	endwhile
    endfor
    endif

    return l:defi_dict
endfunction

if !exists("*DefiSearch")
function! DefiSearch(...)

    if a:0 == 0
	let l:pattern=''
    else
	let l:pattern='\C' . a:1
    endif

    let l:ddict=s:make_defi_dict()
    let b:dd=l:ddict

    " open new buffer
    let l:openbuffer=" +setl\\ buftype=nofile\\ nospell " . fnameescape("DefiSearch")
    if g:vertical ==1
	let l:openbuffer="vsplit " . l:openbuffer 
    else
	let l:openbuffer="split " . l:openbuffer 
    endif

    if len(l:ddict) > 0
	" wipe out the old buffer and open new one instead
	if bufexists("DefiSearch")
	    exe "silent bw! " . bufnr("DefiSearch") 
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
"--------------------SET THE PROJECT NAME----------------------------
" store a list of all input files associated to some file
fun! s:setprojectname()
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
	    let g:mainfile=fnamemodify(expand("%"),":p")
	elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":t")) != '-1'
	    let g:mainfile=s:inputfiles[fnamemodify(bufname("%"),":t")][1]
	    if !exists('#CursorHold#' . fnamemodify(bufname("%"),":p"))
		exe "au CursorHold " . fnamemodify(bufname("%"),":p") . " call s:auTeX()"
	    endif
	elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":t:r")) != '-1'
	    let g:mainfile=s:inputfiles[fnamemodify(bufname("%"),":t:r")][1]
	    if !exists('#CursorHold#' . fnamemodify(bufname("%"),":p"))
		exe "au CursorHold " . fnamemodify(bufname("%"),":p") . " call s:auTeX()"
	    endif
	elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":p:r")) != '-1' 
	    let g:mainfile=s:inputfiles[fnamemodify(bufname("%"),":p:r")][1]
	    if !exists('#CursorHold#' . fnamemodify(bufname("%"),":p"))
		exe "au CursorHold " . fnamemodify(bufname("%"),":p") . " call s:auTeX()"
	    endif
	elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":p"))   != '-1' 
	    let g:mainfile=s:inputfiles[fnamemodify(bufname("%"),":p")][1]
	    if !exists('#CursorHold#' . fnamemodify(bufname("%"),":p"))
		exe "au CursorHold " . fnamemodify(bufname("%"),":p") . " call s:auTeX()"
	    endif
	endif
    elseif exists("g:atp_project")
	let g:mainfile=g:atp_project
    endif

    " we need to escape white spaces in g:mainfile but not in all places so
    " this is not done here
    return 0
endfun
" DEBUG
" command! SetProjectName	:call s:setprojectname()
" DEBUG
" command! InputFiles 		:echo s:inputfiles

au BufEnter *.tex :call s:setprojectname()

" let &l:errorfile=b:outdir . fnameescape(fnamemodify(expand("%"),":t:r")) . ".log"
if !exists("*SetErrorFile")
function! SetErrorFile()

    " set b:outdir if it is not set
    if !exists("b:outdir")
	call s:setoutdir(0)
    endif

    " set the g:mainfile varibale if it is not set (the project name)
    if !exists("g:mainfile")
	call s:setprojectname()
    endif

"     let l:ef=b:outdir . fnamemodify(expand("%"),":t:r") . ".log"
    let l:ef=b:outdir . fnamemodify(g:mainfile,":t:r") . ".log"
    let &l:errorfile=l:ef
endfunction
endif

au BufEnter *.tex call SetErrorFile()

" This options are set also when editing .cls files.
function! s:setoutdir(arg)
    " first we have to check if this is not a project file
    if exists("g:atp_project") || exists("s:inputfiles") && 
		\ ( index(keys(s:inputfiles),fnamemodify(bufname("%"),":t:r")) != '-1' || 
		\ index(keys(s:inputfiles),fnamemodify(bufname("%"),":t")) != '-1' )
	    " if we are in a project input/include file take the correct value of b:outdir from the s:outdir_dict dictionary.
	    
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
endfunction


" these are all buffer related variables:
let s:optionsDict= { 	"texoptions" 	: "", 		"reloadonerror" : "0", 
		\	"openviewer" 	: "1", 		"autex" 	: "1", 
		\	"Viewer" 	: "xpdf", 	"ViewerOptions" : "", 
		\	"XpdfServer" 	: fnamemodify(expand("%"),":t"), 
		\	"outdir" 	: fnameescape(fnamemodify(resolve(expand("%:p")),":h")) . "/",
		\	"texcompiler" 	: "pdflatex",	"auruns"	: "1",
		\ 	"truncate_status_section"	: "40" }
let s:ask={ "ask" : "0" }
if !exists("g:rmcommand") && executable("perltrash")
    let g:rmcommand="perltrash"
elseif !exists("g:rmcommand")
    let g:rmcommand="rm"
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
if !exists("g:texextensions")
    let g:texextensions=["aux", "log", "bbl", "blg", "spl", "snm", "nav", "thm", "brf", "out", "toc", "mpx", "idx", "maf", "blg", "glo", "mtc[0-9]", "mtc1[0-9]"]
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
    let g:matchpair="(:),\\(:\\),[:],\\[:\\],{:}"
endif
if !exists("g:texmf")
    let g:texmf=$HOME . "/texmf"
endif
if exists("g:bibinputs")
    let $BIBINPUTS=g:bibinputs
elseif exists("$BIBINPUTS")
    let g:bibinputs=$BIBINPUTS
else
    let $BIBINPUTS=substitute(g:texmf,'\/\s*$','','') . '/bibtex//'
    let g:bibinputs=$BIBINPUTS
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
    let g:atp_completion_limits=[40,150,150]
endif
if !exists("g:atp_no_complete")
     let g:atp_no_complete=['document']
endif
if !exists("g:atp_close_after_last_closed")
    let g:atp_close_after_last_closed=1
endif

" This function sets options (values of buffer related variables) which were
" not set by the user to their default values.
function! s:setoptions()
    let s:optionsKeys=keys(s:optionsDict)
    let s:optionsinuseDict=getbufvar(bufname("%"),"")

    "for each key in s:optionsKeys set the corresponding variable to its default
    "value unless it was already set in .vimrc file.
    for l:key in s:optionsKeys

	if get(s:optionsinuseDict,l:key,"optionnotset") == "optionnotset" && l:key != "outdir" 
	    call setbufvar(bufname("%"),l:key,s:optionsDict[l:key])
	elseif l:key == "outdir"
	    
	    " set b:outdir and the value of errorfile option
	    call s:setoutdir(1)
	    let s:ask["ask"] = 1
	endif
    endfor
endfunction
call s:setoptions()

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
	echomsg "g:texextensions= " . string(g:texextensions)
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
	echomsg "g:texextensions= " . string(g:texextensions)
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
	echomsg "g:bibentries=" . string(g:bibentries) . "  ['article', 'book', 'booklet', 'conference', 'inbook', 'incollection', 'inproceedings', 'manual', 'mastertheosis', 'misc', 'phdthesis', 'proceedings', 'techreport', 'unpublished']"
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
let g:atp_running=0
" ToDo: to doc.
" this shows errors as ShowErrors better use of call back mechnism is :copen!
if !exists("g:atp_show_errors")
    let g:atp_show_errors=0
endif
if !exists("*ATPRunnig")
function! ATPRunning()
    if g:atp_running && g:atp_callback
	redrawstatus
	return b:texcompiler
    endif
    return ''
endfunction
endif

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
let b:texruns=0
let b:log=0	
let b:ftype=getftype(expand("%:p"))	
let s:texinteraction="nonstopmode"
compiler tex
let s:lockef=1
au BufRead $l:errorfile setlocal autoread 

"--------- FUNCTIONs -----------------------------------------------------
function! s:outdir()
    if b:outdir !~ "\/$"
	let b:outdir=b:outdir . "/"
    endif
endfunction

if !exists("*ViewOutput")
function! ViewOutput()
    call s:outdir()
    if b:texcompiler == "pdftex" || b:texcompiler == "pdflatex"
	let l:ext = ".pdf"
    else
	let l:ext = ".dvi"	
    endif

    let l:link=system("readlink " . g:mainfile)
    if l:link != ""
	let l:outfile=fnamemodify(l:link,":r") . l:ext
    else
	let l:outfile=fnamemodify(g:mainfile,":r"). l:ext 
    endif
    if b:Viewer == "xpdf"	
	let l:viewer=b:Viewer . " -remote " . shellescape(b:XpdfServer) . " " . b:ViewerOptions 
    else
	let l:viewer=b:Viewer  . " " . b:ViewerOptions
    endif
    let l:view=l:viewer . " " . shellescape(l:outfile)  . " &"
		let b:outfile=l:outfile
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
	    call s:compiler(0,1,1,0,"AU",g:mainfile)
    endif	
endfunction
endif
"-------------------------------------------------------------------------
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

if !exists("*s:xpdfpid")
function! s:xpdfpid() 
    let s:checkxpdf="ps -ef | grep -v grep | grep '-remote '" . shellescape(b:XpdfServer) . " | awk '{print $2}'"
    return substitute(system(s:checkxpdf),'\D','','')
endfunction
endif
"-------------------------------------------------------------------------
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
"-------------------------------------------------------------------------
function! s:copy(input,output)
	call writefile(readfile(a:input),a:output)
endfunction

" this variable =1 if s:complier was called and tex has not finished.
" let g:atp_running=0
" This is the MAIN FUNCTION which sets the command and calls it.
" NOTE: the filename argument is not escaped!
function! s:compiler(bibtex,start,runs,verbose,command,filename)
    if has('clientserver')
	let g:atp_running=1
    endif
    call s:outdir()
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
	let s:tmpfile=s:append(s:tmpdir,"/") . fnamemodify(a:filename,":t:r")
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
	
	" add g:atp_running
	if has('clientserver') && v:servername != "" && g:atp_callback == 1
	    let s:texcomp = s:texcomp . ' ; vim --servername ' . v:servername . 
			\ ' --remote-send "<ESC>:let g:atp_running=0<CR>"'
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
	let s:cpoutfile="cp " . s:cpoption . shellescape(s:append(s:tmpdir,"/")) . "*" . l:ext . " " . shellescape(s:append(b:outdir,"/")) 
	let s:command="(" . s:texcomp . " && (" . s:cpoutfile . " ; " . s:xpdfreload . ") || (" . s:cpoutfile . ")" 
	let s:copy=""
	let l:j=1
	for l:i in g:keep 
" 	    ToDo: this can be don using internal vim functions.
	    let s:copycmd=" cp " . s:cpoption . " " . shellescape(s:append(s:tmpdir,"/")) . 
			\ "*." . l:i . " " . shellescape(s:append(b:outdir,"/"))  
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
" 	    let s:command = s:command . ' ; vim --servername ' . v:servername . 
" 			\ ' --remote-send "<ESC>echomsg &errorfile<CR>"'
	    let s:command = s:command . ' ; vim --servername ' . v:servername . 
			\ ' --remote-send "<ESC>:cg<CR>"'
	    if  g:atp_show_errors == 1
		let s:command = s:command . ' ; vim --servername ' . v:servername . 
			    \ ' --remote-send "<ESC>:ShowErrors<CR>"'
	    endif
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
"-------------------------------------------------------------------------
function! s:auTeX()
   if b:autex
	" if the file (or input file is modified) compile the document 
	if filereadable(expand("%"))
	    if s:compare(readfile(expand("%")))
		call s:compiler(0,0,b:auruns,0,"AU",g:mainfile)
		redraw
	    endif
	else
	    call s:compiler(0,0,b:auruns,0,"AU",g:mainfile)
	    redraw
	endif
   endif
endfunction
if !exists('#CursorHold#' . $HOME . '/*.tex')
    au CursorHold $HOME/*.tex call s:auTeX()
endif
"-------------------------------------------------------------------------
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
    call s:compiler(0,0,a:1,0,"COM",g:mainfile)
elseif a:0 == 0
    call s:compiler(0,0,1,0,"COM",g:mainfile)
endif
endfunction
endif

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
    call s:compiler(0,0,a:1,1,"COM",g:mainfile)
else
    call s:compiler(0,0,1,1,"COM",g:mainfile)
endif
endfunction
endif
"-------------------------------------------------------------------------
if !exists("*SimpleBibtex")
function! SimpleBibtex()
    call s:outdir() 
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
	call s:compiler(1,0,0,0,"COM",g:mainfile)
    else
"  	    echomsg "DEBUG Bibtex verbose"
	call s:compiler(1,0,0,1,"COM",g:mainfile)
    endif
endfunction
endif

"-------------------------------------------------------------------------

" TeX LOG FILE
if &buftype == 'quickfix'
	setlocal modifiable
	setlocal autoread
endif	

"-------------------------------------------------------------------------
if !exists("*Delete")
function! Delete()
    call s:outdir()
    let s:error=0
    for l:ext in g:texextensions
	if executable(g:rmcommand)
	    if g:rmcommand =~ "^\s*rm\p*" || g:rmcommand =~ "^\s*perltrash\p*"
		let l:rm=g:rmcommand . " " . shellescape(b:outdir) . "*." . l:ext . " 2>/dev/null && echo Removed ./*" . l:ext . " files"
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

"-------------------------------------------------------------------------
if !exists("*OpenLog")
function! OpenLog()
    if filereadable(&l:errorfile)
	exe "tabe +set\\ nospell\\ ruler " . &l:errorfile
    else
	echo "No log file"
    endif
endfunction
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
	let s:command="pdffonts " . b:outdir . fnameescape(fnamemodify(expand("%"),":t:r")) . ".pdf"
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

if !exists("*Print")
function! Print(...)

    call s:outdir()

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

    " set the printing command
    let l:lprcommand="lpr "
    if a:0 >= 2
	let l:lprcommand.= " " . a:2
    endif

    " print locally or remotely
    " the default is to print locally (g:atp_ssh=`whoami`@localhost)
    if exists("g:apt_ssh") 
	let l:server=strpart(g:atp_ssh,stridx(g:atp_ssh,"@")+1)
    else
	let l:server='locahost'
    endif
    if l:server =~ 'localhost'
	if a:0 == 0 || (a:0 != 0 && a:1 == 'default')
	    let l:com=l:lprcommand . " " . l:pfile
	else
	    let l:com=l:lprcommand . " -P " . a:1 . " " . l:pfile 
	endif
" 	call system(l:com)
	echo l:com
    " print over ssh on the server g:atp_ssh with the printer a:1 (or the
    " default system printer if a:0 == 0
    else 
	if a:0 == 0 || (a:0 != 0 && a:1 =~ 'default')
	    let l:com="cat " . l:pfile . " | ssh " . g:atp_ssh . " " . l:lprcommand
	else
	    let l:com="cat " . l:pfile . " | ssh " . g:atp_ssh . " " . l:lprcommand . " -P " . a:1 
	endif
	if g:printingoptions != "" || (a:0 >= 2 && a:2 != "")
	    if a:0 < 2
		echo "Printing Options: " . g:printingoptions
	    else
		echo a:2
	    endif
	    let l:ok = input("Is this OK? y/n")
	    if l:ok == 'y'
		if a:0 < 2
		    let l:printingoptions=g:printingoptions
		else
		    let l:printingoptions=a:2
		endif
	    else
		let l:printingoptions=input("Give printing options ")
	    endif
	else
	    let l:printingoptions=""
	endif
	let l:com = l:com . " " . l:printingoptions
	echo "\n " . l:com
	echo "Printing ..." 
	call system(l:com)
    endif

endfunction
endif

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

"---------------------- SEARCH IN BIBFILES ----------------------
" This function counts accurence of a:keyword in string a:line, 
" there are two methods keyword is a string to find (a:1=0)or a pattern to
" match, the pattern used to is a:keyword\zs.* to find the place where to cut.
function! s:count(line,keyword,...)
   
    if a:0 == 0 || a:1 == 0
	let l:method=0
    elseif a:1 == 1
	let l:method=1
    endif

    let l:line=a:line
    let l:i=0  
    if l:method==0
	while stridx(l:line,a:keyword) != '-1'
" 		if stridx(l:line,a:keyword) !='-1' 
	    let l:line=strpart(l:line,stridx(l:line,a:keyword)+1)
" 		endif
	    let l:i+=1
	endwhile
    elseif l:method==1
	let l:line=escape(l:line,'\\')
" 	let b:line=l:line " DEBUG
	while match(l:line,a:keyword . '\zs.*') != '-1'
	    let l:line=strpart(l:line,match(l:line,a:keyword . '\zs.*'))
	    let l:i+=1
	endwhile
    endif
    return l:i
endfunction
" DEBUG:
command -buffer -nargs=* Count :echo s:count(<args>)

let g:bibentries=['article', 'book', 'booklet', 'conference', 'inbook', 'incollection', 'inproceedings', 'manual', 'mastertheosis', 'misc', 'phdthesis', 'proceedings', 'techreport', 'unpublished']


"--------------------- SEARCH ENGINE ------------------------------ 
" ToDo should not search in comment lines.

" let s:bibfiles=FindBibFiles(bufname('%'))
function! s:searchbib(pattern) 
" 	echomsg "DEBUG pattern" a:pattern
    call s:outdir()
    let s:bibfiles=keys(FindBibFiles(bufname('%')))
    
    " Make a pattern which will match for the elements of the list g:bibentries
    let l:pattern = '^\s*@\(\%(\<article\>\)'
    for l:bibentry in g:bibentries
	if l:bibentry != 'article'
	let l:pattern=l:pattern . '\|\%(\<' . l:bibentry . '\>\)'
	endif
    endfor
    unlet l:bibentry
    let l:pattern=l:pattern . '\)'
    let b:bibentryline={} 
    
    " READ EACH BIBFILE IN TO DICTIONARY s:bibdict, WITH KEY NAME BEING THE bibfilename
    let s:bibdict={}
    let l:bibdict={}
    let b:bibdict={}	" DEBUG
    for l:f in s:bibfiles
	let s:bibdict[l:f]=[]

	" read the bibfile if it is in b:outdir or in g:bibinputs directory
	" ToDo: change this to look in directories under g:bibinputs. 
	" (see also ToDo in FindBibFiles 284)
	if filereadable(fnameescape(s:append(b:outdir,'/') . s:append(l:f,'.bib'))) 
	    let s:bibdict[l:f]=readfile(fnameescape(s:append(b:outdir,'/') . s:append(l:f,'.bib')))	
	else
" 	    let s:bibdict[l:f]=readfile(fnameescape(s:append(g:bibinputs,'/') . s:append(l:f,'.bib')))
	    let s:bibdict[l:f]=readfile(fnameescape(findfile(s:append(l:f,'.bib'),s:append(g:bibinputs,"/") . "**")))
	endif
	let l:bibdict[l:f]=copy(s:bibdict[l:f])
	" clear the s:bibdict values from lines which begin with %    
	let l:x=0
	for l:line in s:bibdict[l:f]
	    if l:line =~ '^\s*\%(%\|@\cstring\)' 
		call remove(l:bibdict[l:f],l:x)
	    else
		let l:x+=1
	    endif
	endfor
	unlet l:line
    endfor
    for l:f in s:bibfiles
	let l:list=[]
	let l:nr=1
	for l:line in l:bibdict[l:f]
	    if substitute(l:line,'{\|}','','g') =~ a:pattern
		let l:true=1
		let l:t=0
		while l:true == 1
		    let l:tnr=l:nr-l:t
		   if l:bibdict[l:f][l:tnr-1] =~ l:pattern && l:tnr >= 0
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
    let l:pentry="A"		" We want to ensure that l:entry (a number) and p:entry are different
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
"   CHECK EACH BIBFILE
    let l:bibresults={}
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
	    let l:i=s:count(get(l:bibdict[l:bibfile],l:linenr-1),"{")-s:count(get(l:bibdict[l:bibfile],l:linenr-1),"}")
	    let l:j=s:count(get(l:bibdict[l:bibfile],l:linenr-1),"(")-s:count(get(l:bibdict[l:bibfile],l:linenr-1),")") 
	    let s:lbibd={}
	    let s:lbibd["KEY"]=get(l:bibdict[l:bibfile],l:linenr-1)
	    let l:x=1
" we go from the first line of bibentry, i.e. @article{ or @article(, until the { and (
" will close. In each line we count brackets.	    
            while l:i>0	|| l:j>0
		let l:tlnr=l:x+l:linenr
		let l:pos=s:count(get(l:bibdict[l:bibfile],l:tlnr-1),"{")
		let l:neg=s:count(get(l:bibdict[l:bibfile],l:tlnr-1),"}")
		let l:i+=l:pos-l:neg
		let l:pos=s:count(get(l:bibdict[l:bibfile],l:tlnr-1),"(")
		let l:neg=s:count(get(l:bibdict[l:bibfile],l:tlnr-1),")")
		let l:j+=l:pos-l:neg
		let l:lkey=tolower(matchstr(strpart(get(l:bibdict[l:bibfile],l:tlnr-1),0,stridx(get(l:bibdict[l:bibfile],l:tlnr-1),"=")),'\<\w*\>'))
		if l:lkey != ""
		    let s:lbibd[l:lkey]=get(l:bibdict[l:bibfile],l:tlnr-1)
			let l:y=0
" IF THE LINE IS SPLIT ATTACH NEXT LINE									
			let l:lline=substitute(get(l:bibdict[l:bibfile],l:tlnr+l:y-1),'\\"\|\\{\|\\}\|\\(\|\\)','','g')
			let l:pos=s:count(l:lline,"{")
			let l:neg=s:count(l:lline,"}")
			let l:m=l:pos-l:neg
			let l:pos=s:count(l:lline,"(")
			let l:neg=s:count(l:lline,")")
			let l:n=l:pos-l:neg
			let l:o=s:count(l:lline,"\"")
" this checks if bracets {}, and () and "" appear in pairs in the current line:  
			if l:m>0 || l:n>0 || l:o>l:o/2*2 
			    while l:m>0 || l:n>0 || l:o>l:o/2*2 
				let l:pos=s:count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"{")
				let l:neg=s:count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"}")
				let l:m+=l:pos-l:neg
				let l:pos=s:count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"(")
				let l:neg=s:count(get(l:bibdict[l:bibfile],l:tlnr+l:y),")")
				let l:n+=l:pos-l:neg
				let l:o+=s:count(get(l:bibdict[l:bibfile],l:tlnr+l:y),"\"")
" Let us append the next line: 
				let s:lbibd[l:lkey]=substitute(s:lbibd[l:lkey],'\s*$','','') . " ". substitute(get(l:bibdict[l:bibfile],l:tlnr+l:y),'^\s*','','')
				let l:y+=1
				if l:y > 30
				    echoerr "ATP-Error /see :h atp-errors-bibsearch/, missing '}', ')' or '\"' in bibentry at line " . l:linenr . " (check line " . l:tlnr . ") in " . l:f
				    break
				endif
			    endwhile
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
"
"------------------------SHOW FOUND BIBFIELDS----------------------------
let g:bibmatchgroup='String'
let g:defaultbibflags='tabejsyu'
let g:defaultallbibflags='tabejfsvnyPNSohiuHcp'
let b:lastbibflags=g:defaultbibflags	" Set the lastflags variable to the default value on the startup.
" g:bibflagsdict={ 'flag' : ['name','what to print on the screen /13 letters/'] }
let g:bibflagsdict={ 't' : ['title', 'title        '] , 'a' : ['author', 'author       '], 
		\ 'b' : ['booktitle', 'booktitle    '], 'c' : ['mrclass', 'mrclass      '], 
		\ 'e' : ['editor', 'editor       '], 	'j' : ['journal', 'journal      '], 
		\ 'f' : ['fjournal', 'fjournal     '], 	'y' : ['year', 'year         '], 
		\ 'n' : ['number', 'number       '], 	'v' : ['volume', 'volume       '], 
		\ 's' : ['series', 'series       '], 	'p' : ['pages', 'pages        '], 
		\ 'P' : ['publisher', 'publisher    '], 'N' : ['note', 'note         '], 
		\ 'S' : ['school', 'school       '], 	'h' : ['howpublished', 'howpublished '], 
		\ 'o' : ['organization', 'organization '], 'I' : ['institution' , 'institution '],
		\ 'u' : ['url','url          '],
		\ 'H' : ['homepage', 'homepage     '], 	'i' : ['issn', 'issn         '] }
let s:bibflagslist=keys(g:bibflagsdict)
let s:bibflagsstring=join(s:bibflagslist,'')
let g:kwflagsdict={ 	  '@a' : '@article', 	'@b' : '@book\%(let\)\@<!', 
			\ '@B' : '@booklet', 	'@c' : '@in\%(collection\|book\)', 
			\ '@m' : '@misc', 	'@M' : '@manual', 
			\ '@p' : '@\%(conference\)\|\%(\%(in\)\?proceedings\)', 
			\ '@t' : '@\%(\%(master)\|\%(phd\)\)thesis', 
			\ '@T' : '@techreport', '@u' : '@unpublished'}    

" Set the g:{b:Viewer}Options as b:ViewerOptions for the current buffer
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

function! s:comparelist(i1, i2)
   return str2nr(a:i1) == str2nr(a:i2) ? 0 : str2nr(a:i1) > str2nr(a:i2) ? 1 : -1
endfunction
"-------------------------s:showresults--------------------------------------
function! s:showresults(bibresults,flags,pattern)
 
    "if nothing was found inform the user and return:
    if len(a:bibresults) == count(a:bibresults,{})
	echo "BibSearch: no bib fields matched."
	return 0
    endif

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
	    let a:flags=substitute(a:flags,'i','io','') 
	elseif a:flags !~ '\Ci' && a:flags =~ '\Co'
	    let a:flags=substitute(a:flags,'o','oi','')
	endif
	if a:flags !~ 'All'
	    if a:flags =~ 'L'
 		if strpart(a:flags,0,1) != '+'
 		    let l:flags=b:lastbibflags . substitute(strpart(a:flags,0),'\CL','','g')
 		else
 		    let l:flags=b:lastbibflags . substitute(a:flags,'\CL','','g')
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
	    let b:lastbibflags=substitute(l:flags,'+\|L','','g')
		if l:flags != ""
		    let l:expr='\C[' . s:bibflagsstring . ']' 
		    while len(l:flags) >=1
			let l:oneflag=strpart(l:flags,0,1)
    " if we get a flag from the variable s:bibflagsstring we copy it to the list l:flagslist 
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
" 	let b:flagslist=l:flagslist			" DEBUG
" 	let b:kwflagslist=l:kwflagslist			" DEBUG
"   Open a new window.
    let l:bufnr=bufnr("___" . a:pattern . "___"  )
    if l:bufnr != -1
	let l:bdelete=l:bufnr . "bdelete"
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
    silent exe l:openbuffer

"     set the window options
    silent call s:setwindow()

    for l:bibfile in keys(a:bibresults)
	if a:bibresults[l:bibfile] != {}
	    call setline(l:ln, "Found in " . l:bibfile )	
	    let l:ln+=1
	endif
	for l:linenr in copy(sort(keys(a:bibresults[l:bibfile]),"s:comparelist"))
" make a dictionary of clear values, which we will fill with found entries. 	    
" the default value is no<keyname>, which after all is matched and not showed
	    let l:values={'key' : 'nokey'}	
	    for l:flag in s:bibflagslist 
		let l:values=extend(l:values,{ g:bibflagsdict[l:flag][0] : 'no' . g:bibflagsdict[l:flag][0] })
	    endfor
	    unlet l:flag
	    let b:values=l:values
" fill l:values with a:bibrsults	    
	    let l:values["key"]=a:bibresults[l:bibfile][l:linenr]["KEY"]
	    for l:key in keys(l:values)
		if l:key != 'key' && get(a:bibresults[l:bibfile][l:linenr],l:key,"no" . l:key) != "no" . l:key
		    let l:values[l:key]=a:bibresults[l:bibfile][l:linenr][l:key]
		endif
	    endfor
" ----------------------------- SHOW ENTRIES -------------------------
" first we check the keyword flags, @a,@b,... it passes if at least one flag
" is matched
	    let l:check=0
	    for l:lkwflag in l:kwflagslist
	        let l:kwflagpattern= '\C' . g:kwflagsdict[l:lkwflag]
		if l:values['key'] =~ l:kwflagpattern
		   let l:check=1
		endif
	    endfor
	    if l:check == 1 || len(l:kwflagslist) == 0
		let l:linenumber=index(s:bibdict[l:bibfile],l:values["key"])+1
 		call setline(l:ln,s:z . ". line " . l:linenumber . "  " . l:values["key"])
		let l:ln+=1
 		let l:c0=s:count(l:values["key"],'{')-s:count(l:values["key"],'(')

	
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
		let l:c1=s:count(l:lastline,'{')-s:count(l:lastline,'}')
		let l:c2=s:count(l:lastline,'(')-s:count(l:lastline,')')
		let l:c3=s:count(l:lastline,'\"')
" 		echomsg "last line " . line('$') . "     l:ln=" l:ln . "    l:c0=" . l:c0		"DEBUG
		if l:c0 == 1 && l:c1 == -1
		    call setline(line('$'),substitute(l:lastline,'}\s*$','',''))
		    call setline(l:ln,'}')
		    let l:ln+=1
		elseif l:c0 == 1 && l:c1 == 0	
		    call setline(l:ln,'}')
		    let l:ln+=1
		elseif l:c0 == -1 && l:c2 == -1
		    call setline(line('$'),substitute(l:lastline,')\s*$','','')
		    call setline(l:ln,')')
		    let l:ln+=1
		elseif l:c0 == -1 && l:c1 == 0	
		    call setline(l:ln,')')
		    let l:ln+=1
		endif
		let l:listofkeys[s:z]=l:values["key"]
		let s:z+=1
	    endif
	endfor
    endfor
    call matchadd("Search",a:pattern)
    " return l:listofkeys which will be available in the bib search buffer
    " as b:listofkeys (see the BibSearch function below)
    return l:listofkeys
endfunction

if !exists("*BibSearch")
"  There are three arguments: {pattern}, [flags, [choose]]
function! BibSearch(...)
    if a:0 == 0
	let l:bibresults=s:searchbib('')
	let b:listofkeys=s:showresults(l:bibresults,'','')
    elseif a:0 == 1
	let l:bibresults=s:searchbib(a:1)
	let b:listofkeys=s:showresults(l:bibresults,'',a:1)
    else
	let l:bibresults=s:searchbib(a:1)
	let b:listofkeys=s:showresults(l:bibresults,a:2,a:1)
    endif
endfunction
endif

"---------- TOC -----------------------------------------------------------
" this function sets the options of BibSearch, ToC and Labels windows.
function! s:setwindow()
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
	endif
endfunction

let g:sections={
    \	'chapter' 	: [           '^\s*\(\\chapter.*\)',	'\\chapter\*'],	
    \	'section' 	: [           '^\s*\(\\section.*\)',	'\\section\*'],
    \ 	'subsection' 	: [	   '^\s*\(\\subsection.*\)',	'\\subsection\*'],
    \	'subsubsection' : [ 	'^\s*\(\\subsubsection.*\)',	'\\subsubsection\*'],
    \	'bibliography' 	: ['^\s*\(\\begin.*{bibliography}.*\|\\bibliography\s*{.*\)' , 'nopattern'],
    \	'abstract' 	: ['^\s*\(\\begin\s*{abstract}.*\|\\abstract\s*{.*\)',	'nopattern']}

"----------- Make TOC -----------------------------
" This makes sense only for latex documents.
"
" It makes t:toc - a dictionary (with keys: full path of the buffer name)
" which values are dictionaries which keys are: line numbers and values lists:
" [ 'section-name', 'number', 'title'] where section name is element of
" keys(g:sections), number is the total number, 'title=\1' where \1 is
" returned by the g:section['key'][0] pattern.
function! s:maketoc(filename)
    let b:fname=a:filename
    "
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
    if bufloaded("^" . l:bufname . "$")
	let l:texfile=getbufline("^" . l:bufname . "$","1","$")
    else
	w
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
    for l:section in keys(g:sections)
	let l:ind{l:section}=0
    endfor
    " make a filter
    let l:j=0
    for l:section in keys(g:sections)
	if l:j == 0 
	    let l:filter=g:sections[l:section][0] . ''
	else
	    let l:filter=l:filter . '\|' . g:sections[l:section][0] 
	endif
	let l:j+=1
    endfor
    " filter l:texfile    
    let s:filtered=filter(deepcopy(l:texfile),'v:val =~ l:filter')
    let b:filtered=s:filtered
    let b:texfile=l:texfile
    for l:line in s:filtered
	for l:section in keys(g:sections)
	    if l:line =~ g:sections[l:section][0] 
		if l:line !~ '^\s*%'
		    " THIS DO NOT WORKS WITH \abstract{ --> empty set, but with
		    " \chapter{title} --> title, solution: the name of
		    " 'Abstract' will be plased, as we know what we have
		    " matched
		    let l:title=l:line
		    " test if it is a starred version.
		    let l:star=0
		    if g:sections[l:section][1] != 'nopattern' && l:line =~ g:sections[l:section][1] 
			let l:star=1 
		    else
			let l:star=0
		    endif
		    let l:i=index(l:texfile,l:line)
		    let l:tline=l:i+l:bline+1
		    " if it is not starred version add one to the section number
		    if l:star==0
			let l:ind{l:section}+=1
		    endif

		    " Find the title:
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

		    " Find the short title:
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
		    let b:lname=l:lname
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
let t:texcompiler=b:texcompiler
"--------------------- Make a List of Buffers ----
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
endfunction
call s:buflist()
 
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
"---------------------- Show TOC -----------------
function! s:showtoc(toc)
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
	silent call s:setwindow()
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
	let l:chapon=0
	let l:chnr=0
	let l:secnr=0
	let l:ssecnr=0
	let l:sssecnr=0
	let l:path=fnamemodify(bufname(""),":p:h")
	for l:line in keys(a:toc[l:openfile])
	    if a:toc[l:openfile][l:line][0] == 'chapter'
		let l:chapon=1
		break
	    endif
	endfor
	let l:sorted=sort(keys(a:toc[l:openfile]),"s:comparelist")
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
	    if a:toc[l:openfile][l:line][0] == 'abstract'
		call setline(l:number, l:showline . "\t" . "  " . "Abstract" )
	    elseif a:toc[l:openfile][l:line][0] =~ 'bibliography\|references'
		call setline (l:number, l:showline . "\t" . "  " . a:toc[l:openfile][l:line][2])
	    elseif a:toc[l:openfile][l:line][0] == 'chapter'
		let l:chnr=a:toc[l:openfile][l:line][1]
		let l:nr=l:chnr
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
		if l:chapon
		    let l:nr=l:chnr . "." . l:secnr  
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
		if l:chapon
		    let l:nr=l:chnr . "." . l:secnr  . "." . l:ssecnr
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
		if l:chapon
		    let l:nr=l:chnr . "." . l:secnr . "." . l:sssecnr  
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
	let l:number=l:numberdict[t:bufname]
	let l:sorted=sort(keys(a:toc[t:bufname]),"s:comparelist")
	let t:sorted=l:sorted
	for l:line in l:sorted
	    if l:cline>=l:line
		let l:number+=1
	    endif
	call setpos('.',[bufnr(""),l:number,1,0])
	endfor
endfunction
"------------------- TOC ---------------------------------------------
if !exists("*TOC")
function! TOC()
    if &filetype != 'tex'    
	echoerr "Wrong 'filetype'. This function works only for latex documents."
	return
    endif
    " for each buffer in t:buflist (set by s:buflist)
    for l:buffer in t:buflist 
	    let t:toc=s:maketoc(l:buffer)
    endfor
    call s:showtoc(t:toc)
endfunction
endif
"------------------- Current TOC -------------------------------------
" This function finds the section name of the current section unit with
" respect to the dictionary a:section={ 'line number' : 'section name', ... }
" it returns the [ section_name, section line, next section line ]
function! s:nearestsection(section)
    let l:cline=line('.')

    let l:sorted=sort(keys(a:section),"s:comparelist")
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

function! s:CTOC()
    if &filetype != 'tex'    
	echomsg "CTOC: Wrong 'filetype'. This function works only for latex documents."
	" Set the status line once more, to remove the CTOC() function.
	call ATPStatus()
	return ""
    endif
    " resolve the full path:
    let t:bufname=resolve(fnamemodify(bufname("%"),":p"))
    
    " if t:toc(t:bufname) exists use it otherwise make it 
    if !exists("t:toc") || !has_key(t:toc,t:bufname) 
	silent let t:toc=s:maketoc(t:bufname)
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
	return ['Preambule']
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

if !exists("*CTOC")
    function CTOC(...)
	" if there is any argument given, then the function returns the value
	" (used by ATPStatus()), otherwise it echoes the section/subsection
	" title. It returns only the first b:truncate_status_section
	" characters of the the whole titles.
	let l:names=s:CTOC()
	let b:names=l:names
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
		if a:0 == '0'
		    echo "XXX" . l:chapter_name . "/" . l:section_name 
		else
		    return substitute(strpart(l:chapter_name,0,b:truncate_status_section/2), '\_s*$', '','') . "/" . substitute(strpart(l:section_name,0,b:truncate_status_section/2), '\_s*$', '','')
		endif
	    else
		if a:0 == '0'
		    echo "XXX" . l:chapter_name
		else
		    return substitute(strpart(l:chapter_name,0,b:truncate_status_section), '\_s*$', '','')
		endif
	    endif

	elseif l:chapter_name == "" && l:section_name != ""
	    if l:subsection_name != ""
		if a:0 == '0'
		    echo "XXX" . l:section_name . "/" . l:subsection_name 
		else
		    return substitute(strpart(l:section_name,0,b:truncate_status_section/2), '\_s*$', '','') . "/" . substitute(strpart(l:subsection_name,0,b:truncate_status_section/2), '\_s*$', '','')
		endif
	    else
		if a:0 == '0'
		    echo "XXX" . l:section_name
		else
		    return substitute(strpart(l:section_name,0,b:truncate_status_section), '\_s*$', '','')
		endif
	    endif

	elseif l:chapter_name == "" && l:section_name == "" && l:subsection_name != ""
	    if a:0 == '0'
		echo "XXX" . l:subsection_name
	    else
		return substitute(strpart(l:subsection_name,0,b:truncate_status_section), '\_s*$', '','')
	    endif
	endif
    endfunction
endif

"--------- LABELS --------------------------------------------------------
" the argument should be: resolved full path to the file:
" resove(fnamemodify(bufname("%"),":p"))
function! s:generatelabels(filename)
    let s:labels={}
    let l:bufname=fnamemodify(a:filename,":t")
    " getbufline reads onlu loaded buffers, unloaded can be read from file.
    if bufloaded("^" . l:bufname . "$")
	let l:texfile=getbufline("^" . l:bufname . "$","1","$")
    else
	w
	let l:texfile=readfile(a:filename)
    endif
"     echomsg "DEBUG X        " . fnamemodify(a:filename,":t")
    let l:true=1
    let l:i=0
    " remove the bart before \begin{document}
    while l:true == 1
	if l:texfile[0] =~ '\\begin\s*{document}'
		let l:true=0
	endif
	call remove(l:texfile,0)
	let l:i+=1
    endwhile
    let l:bline=l:i
    let l:i=0
    while l:i < len(l:texfile)
	if l:texfile[l:i] =~ '\\label\s*{'
	    let l:lname=matchstr(l:texfile[l:i],'\\label\s*{.*','')
	    let l:start=stridx(l:lname,'{')+1
	    let l:lname=strpart(l:lname,l:start)
	    let l:end=stridx(l:lname,'}')
	    let l:lname=strpart(l:lname,0,l:end)
	    let b:lname=l:lname
    "This can be extended to have also the whole environmet which
    "could be shown.
	    call extend(s:labels,{ l:i+l:bline+1 : l:lname })
	endif
	let l:i+=1 
    endwhile
    if exists("t:labels")
	call extend(t:labels,{ a:filename : s:labels },"force")
    else
	let t:labels={ a:filename : s:labels }
    endif
    return t:labels
endfunction

" The argument is the dictionary generated by s:generatelabels.
function! s:showlabels(labels)
    " the argument a:labels=t:labels[bufname("")] !
    let l:cline=line(".")
    let l:lines=sort(keys(a:labels),"s:comparelist")
    " Open new window or jump to the existing one.
    let l:bufname=bufname("")
"     let l:bufpath=fnamemodify(bufname(""),":p:h")
    let l:bufpath=fnamemodify(resolve(fnamemodify(bufname("%"),":p")),":h")
    let l:bname="__Labels__"
    let l:labelswinnr=bufwinnr("^" . l:bname . "$")
    let t:labelswinnr=winnr()
    let t:labelsbufnr=bufnr("^" . l:bname . "$") 
    let l:labelswinnr=bufwinnr(t:labelsbufnr)
    if l:labelswinnr != -1
	" Jump to the existing window.
	exe l:labelswinnr . " wincmd w"
	if l:labelswinnr != t:labelswinnr
	    silent exe "%delete"
	else
	    echoerr "ATP error in function s:showtoc, TOC/LABEL buffer 
		    \ and the tex file buffer agree."
	    return
	endif
    else
    " Open new window if its width is defined (if it is not the code below
    " will put lab:cels in the current buffer so it is better to return.
	if !exists("t:labels_window_width")
	    echoerr "t:labels_window_width not set"
	    return
	endif
	let l:openbuffer=t:labels_window_width . "vsplit +setl\\ buftype=nofile\\ filetype=toc_atp\\ syntax=labels_atp __Labels__"
	silent exe l:openbuffer
	silent call s:setwindow()
	let t:labelsbufnr=bufnr("")
    endif
    call setline(1,l:bufname . " (" . l:bufpath . ")")
    let l:ln=2
    for l:line in l:lines
	call setline(l:ln, l:line . "\t" . a:labels[l:line]) 
	let l:ln+=1
    endfor
    " set the cursor position on the correct line number.
    let l:number=1
    for l:line in l:lines
    if l:cline>=l:line
	call setpos('.',[bufnr(bufname('%')),l:number+1,1,0])
    elseif l:number == 1 && l:cline<l:line
	call setpos('.',[bufnr(bufname('%')),l:number+1,1,0])
    endif
    let l:number+=1
    endfor
endfunction
" -------------------- Labels ---------------------------------------
if !exists("*Labels")
function! Labels()
    let t:bufname=bufname("%")
    let l:bufname=resolve(fnamemodify(t:bufname,":p"))
    " Generate the dictionary with labels
    let t:labels=s:generatelabels(l:bufname)
    " Show the labels in seprate window
    call s:showlabels(t:labels[l:bufname])
endfunction
endif
" ------------- Edit Input Files  -----------------------------------
if !exists("*EditInputFile")
function! EditInputFile(...)

    let l:mainfile=g:mainfile

    if a:0 == 0
	let l:inputfile=""
	let l:bufname=g:mainfile
	let l:opencom="edit"
    elseif a:0 == 1
	let l:inputfile=a:1
	let l:bufname=g:mainfile
	let l:opencom="edit"
    else
	let l:inputfile=a:1
	let l:opencom=a:2

	" the last argument is the bufername in which search for the input files 
	if a:0 > 2
	    let l:bufname=a:3
	else
	    let l:bufname=g:mainfile
	endif
    endif

    let l:dir=fnamemodify(g:mainfile,":p:h")

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
"     if l:ifile == fnamemodify(g:mainfile,":t")
" 	let l:ifile=g:mainfile
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
	let l:ifilename=s:append(l:ifile,'.tex')
    elseif l:inputfiles[l:ifile][0] == 'bib'
	let l:ifilename=s:append(l:ifile,'.bib')
    elseif  l:inputfiles[l:ifile][0] == 'main file'
	let l:ifilename=g:mainfile
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
		let g:mainfile=l:mainfile
	    elseif l:inputfiles[l:ifile][0] == 'bib' 
		let s:ft=&filetype
		exe l:opencom . " " . fnameescape(s:append(g:bibinputs,'/') . l:ifilename)
		let &l:filetype=s:ft
		let g:mainfile=l:mainfile
	    elseif  l:inputfiles[l:ifile][0] == 'main file' 
		exe l:opencom . " " . g:mainfile
		let g:mainfile=l:mainfile
	    endif
	endif
    else
	exe l:opencom . " " . fnameescape(l:ifilename)
	let g:mainfile=l:mainfile
    endif
endfunction
endif

if !exists("*EI_compl")
fun! EI_compl(A,P,L)
"     let l:inputfiles=FindInputFiles(bufname("%"),1)

    let l:inputfiles=filter(FindInputFiles(g:mainfile,1), 'v:key !~ fnamemodify(bufname("%"),":t:r")')
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

" TODO if the file was not found ask to make one.
"--------- ToDo -----------------------------------------------------------
"
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
    let l:sortedkeys=sort(keys(b:todo),"s:comparelist")
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
" 
"--------- FOLDING --------------------------------------------------------
"
let s:a=0
function! FoldExpr(line)
    let s:a+=1
"     echomsg "DEBUG " . s:a " at line " . a:line

    call s:maketoc(fnamemodify(bufname("%"),":p"))
    let l:line=a:line

    " make a fold of the preambule /now this folds too much/
    let l:sorted=sort(keys(t:toc[fnamemodify(bufname("%"),":p")]),"s:comparelist")
    if a:line < l:sorted[0]
	return 1
    endif

    let l:secname=""
    while l:secname == ""  
	let l:secname=get(t:toc[fnamemodify(bufname("%"),":p")],l:line,'')[0]
	let l:line-=1
    endwhile
    let l:line+=1
    if l:secname == 'part'
	return 1
    elseif l:secname == 'chapter'
	return 2
    elseif l:secname == 'section'
	return 3
    elseif l:secname == 'subsection'
	return 4
    elseif l:secname == 'subsubsection'
	return 5
    elseif l:secname == 'paragraph'
	return 6
    elseif l:secname == 'subparagraph'
	return 7
    else 
	return 0
    endif
endfunction
" setlocal foldmethod=expr
" foldmethod=marker do not work in preamble as there might appear }}}
" this folds entire document with one fold when there are only sections
" it is thus not a good method of folding.
" setlocal foldexpr=FoldExpr(v:lnum)
"
"-------- SHOW ERRORS -----------------------------------------------------
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
"--------- Set Viewers  ------------------------------------------------------
"
fun! SetXdvi()
    let b:texcompiler="latex"
    let b:texoptions="-src-specials"
    if exists("g:xdviOptions")
	let b:ViewerOptions=g:xdviOptions
    endif
    let b:Viewer="xdvi " . b:ViewerOptions . " -editor 'gvim --servername " . v:servername . " --remote-wait +%l %f'"
    if !exists("*RevSearch")
    function RevSearch()
	let l:xdvi_reverse_search="xdvi " . b:ViewerOptions . " -editor 'gvim --servername " . v:servername . " --remote-wait +%l %f' -sourceposition " . line(".") . ":" . col(".") . fnamemodify(expand("%"),":p") . " " . fnamemodify(expand("%"),":p:r") . ".dvi"
	call system(l:xdvi_reverse_search)
    endfunction
    endif
    command! -buffer RevSearch 					:call RevSearch()
    map <buffer> <LocalLeader>rs				:call RevSearch()<CR>
    nmenu 550.65 &LaTeX.Reverse\ Search<Tab>:map\ <LocalLeader>rs	:RevSearch<CR>
endfun

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

"--------- Search for Matching Pair  -----------------------------------------
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

"--------- MOVING FUNCTIONS ----------------------------------------------- 

" Move to next environment which name is given as the argument. Do not wrap
" around the end of the file.
function! NextEnv(envname)
    call search('\\begin{' . a:envname . '}','W')
endfunction

function! PrevEnv(envname)
    call search('\\begin{' . a:envname . '}','bW')
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

"--------- Special Space for Searching  ----------------------------------
let s:special_space="[off]"
" if !exists("*ToggleSpace")
function! ToggleSpace()
    if maparg('<space>','c') == ""
	echomsg "special space is on"
	cmap <Space> \_s\+
	let s:special_space="[on]"
	aunmenu LaTeX.Toggle\ Space\ [off]
	nmenu 550.78 &LaTeX.&Toggle\ Space\ [on]	:ToggleSpace<CR>
	tmenu &LaTeX.&Toggle\ Space\ [on] cmap <space> \_s\+ is curently on
    else
	echomsg "special space is off"
 	cunmap <Space>
	let s:special_space="[off]"
	aunmenu LaTeX.Toggle\ Space\ [on]
	nmenu 550.78 &LaTeX.&Toggle\ Space\ [off]	:ToggleSpace<CR>
	tmenu &LaTeX.&Toggle\ Space\ [off] cmap <space> \_s\+ is curently off
    endif
endfunction
" endif

function! ToggleCheckMathOpened()
    if g:atp_math_opened
	echomsg "check if in math environment is off"
	aunmenu LaTeX.Toggle\ Check\ if\ in\ Math\ [on]
	nmenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [off]<Tab>g:atp_math_opened			
		    \ :ToggleCheckMathOpened<CR>
    else
	echomsg "check if in math environment is on"
	aunmenu LaTeX.Toggle\ Check\ if\ in\ Math\ [off]
	nmenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [on]<Tab>g:atp_math_opened
		    \ :ToggleCheckMathOpened<CR>
    endif
    let g:atp_math_opened=!g:atp_math_opened
endfunction
"
"--------- TAB COMPLETION ----------------------------------------------------
"
" This function searches if the package in question is declared or not.
" Returns 1 if it is and 0 if it is not.
" It was inspired by autex function written by Carl Mueller, math at carlm e4ward c o m
function! s:Search_Package(name)
    let l:n=1
    let l:line=join(getbufline(fnamemodify(g:mainfile,":t"),l:n))
    let l:len=len(getbufline(fnamemodify(g:mainfile,":t"),1,'$'))
    while l:line !~ '\\begin\s*{document}' &&  l:n <= l:len
	if l:line =~ '^[^%]*\\usepackage\s*{.*' . a:name
	    return 1
	endif
	let l:n+=1
	let l:line=join(getbufline(fnamemodify(g:mainfile,":t"),l:n))
    endwhile
    return 0
endfunction
" DEBUG
" command! -nargs=1 SearchPackage 	:echo s:Search_Package(<f-args>)

function! s:Document_Class()
    let l:n=1
    let l:line=join(getbufline(fnamemodify(g:mainfile,":t"),l:n))
    if l:line =~ '\\documentclass'
" 	let b:line=l:line " DEBUG
	return substitute(l:line,'.*\\documentclass\s*\%(\[.*\]\)\?{\(.*\)}.*','\1','')
    endif
    while l:line !~ '\\documentclass'
	if l:line =~ '\\documentclass'
	    return substitute(l:line,'.*\\documentclass\s*\%(\[.*\]\)\?{\(.*\)}.*','\1','')
	endif
	let l:n+=1
	let l:line=join(getbufline(fnamemodify(g:mainfile,":t"),l:n))
    endwhile
endfunction

" ToDo: make list of complition commands from the input files.
" ToDo: make complition fot \cite, and for \ref and \eqref commands.

" ToDo: there is second such a list! line 3150
	let g:atp_environments=['array', 'abstract', 'center', 'corollary', 
		\ 'definition', 'document', 
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

	let g:atp_package_list=sort(['amsmath', 'amssymb', 'amsthm', 'amstex', 
	\ 'babel', 'booktabs', 'bookman', 'color', 'colorx', 'chancery', 'charter', 'courier',
	\ 'enumerate', 'euro', 'fancyhdr', 'fancyheadings', 'fontinst', 
	\ 'geometry', 'graphicx', 'graphics',
	\ 'hyperref', 'helvet', 'layout', 'longtable',
	\ 'newcent', 'nicefrac', 'ntheorem', 'palatino', 'stmaryrd', 'showkeys', 'tikz',
	\ 'qpalatin', 'qbookman', 'qcourier', 'qswiss', 'qtimes', 'verbatim', 'wasysym'])

	" the command \label is added at the end.
	let g:atp_commands=['begin{', 'end{', 
	\ 'cite{', 'nocite{', 'ref{', 'pageref{', 'eqref{', 'bibitem', 'item',
	\ 'emph{', 'documentclass{', 'usepackage{',
	\ 'section{', 'subsection{', 'subsubsection{', 'part{', 
	\ 'chapter{', 'appendix ', 'subparagraph ', 'paragraph ',
	\ 'textbf{', 'textsf{', 'textrm{', 'textit{', 'texttt{', 
	\ 'textsc{', 'textsl{', 'textup{', 'textnormal ', 
	\ 'bfseries', 'mdseries',
	\ 'tiny ', 'scriptsize ', 'footnotesize ', 'small ',
	\ 'normal ', 'large ', 'Large ', 'LARGE ', 'huge ', 'HUGE ',
	\ 'usefont{', 'fontsize{', 'selectfont ',
	\ 'addcontentsline{', 'addtocontents ',
	\ 'input', 'include', 'includeonly', 
	\ 'savebox', 'sbox', 'usebox ', 'rule ', 'raisebox{', 
	\ 'parbox{', 'mbox{', 'makebox{', 'framebox{', 'fbox{',
	\ 'bigskip ', 'medskip ', 'smallskip ', 'vfill ', 'vspace{', 
	\ 'hspace ', 'hrulefill ', 'hfill ', 'dotfill ',
	\ 'thispagestyle ', 'markright ', 'pagestyle ', 'pagenumbering ',
	\ 'author{', 'date{', 'thanks{', 'title{',
	\ 'maketitle ', 'overbrace{', 'underbrace{',
	\ 'marginpar ', 'indent ', 'noindent ', 'par ', 'sloppy ', 'pagebreak[', 'nopagebreak[',
	\ 'newpage ', 'newline ', 'linebreak[', 'hyphenation{', 'fussy ',
	\ 'enlagrethispage{', 'clearpage ', 'cleardoublepage ',
	\ 'opening{', 'name{', 'makelabels{', 'location{', 'closing{', 'address{', 
	\ 'signature{', 'stopbreaks ', 'startbreaks ',
	\ 'newcounter{', 'refstepcounter{', 
	\ 'roman{', 'Roman{', 'stepcounter{', 'setcounter{', 
	\ 'usecounter{', 'value{', 'newtheorem{', 'newfont{', 
	\ 'newlength{', 'setlength{', 'addtolength{', 'settodepth{', 
	\ 'settoheight{', 'settowidth{', 
	\ 'width', 'height', 'depth', 'totalheight',
	\ 'footnote{', 'footnotemark ', 'footnotetetext', 
	\ 'bibliography{', 'bibliographystyle{', 'linethickness', 'line', 'circle',
	\ 'frame', 'multiput', 'oval', 'put', 'shortstack', 'vector', 'dashbox',
	\ 'flushbottom', 'onecolumn', 'raggedbottom', 'twocolumn',  
	\ 'alph{', 'Alph{', 'arabic{', 'fnsymbol{', 'reversemarginpar',
	\ 'hat{', 'grave{', 'bar{', 'acute{', 'mathring{', 'check{', 'dot{', 'vec{', 'breve{',
	\ 'tilde{', 'widetilde{', 'widehat{', 'ddot{', 'exhyphenpenalty',
	\ 'topmargin', 'oddsidemargin', 'evensidemargin', 'headheight', 'headsep', 
	\ 'textwidth', 'textheight', 'marginparwidth', 'marginparsep', 'marginparpush', 'footskip', 'hoffset',
	\ 'voffset', 'paperwidth', 'paperheight', 'theequation', 'thepage' ]
	
	" ToDo: end writting layout commands. 
	" ToDo: MAKE COMMANDS FOR PREAMBULE.

	let g:atp_math_commands=['forall', 'exists', 'emptyset', 'aleph', 'partial',
	\ 'nabla', 'Box', 'Diamond', 'bot', 'top', 'flat', 'sharp',
	\ 'mathbf{', 'mathsf{', 'mathrm{', 'mathit{', 'mathbb{', 'mathtt{', 'mathcal{', 
	\ 'mathop{', 'limits', 'text{', 'leqslant', 'leq', 'geqslant', 'geq',
	\ 'gtrsim', 'lesssim', 'gtrless', 
	\ 'rightarrow', 'Rightarrow', 'leftarrow', 'Leftarrow', 'iff', 
	\ 'leftrightarrow', 'Leftrightarrow', 'downarrow', 'Downarrow', 'Uparrow',
	\ 'Longrightarrow', 'longrightarrow', 'Longleftarrow', 'longleftarrow',
	\ 'overrightarrow{', 'overleftarrow{', 'underrightarrow{', 'underleftarrow{',
	\ 'uparrow', 'nearrow', 'searrow', 'swarrow', 'nwarrow', 
	\ 'hookrightarrow', 'hookleftarrow', 'gets', 
	\ 'sum', 'bigsum', 'cup', 'bigcup', 'cap', 'bigcap', 
	\ 'prod', 'coprod', 'bigvee', 'bigwedge', 'wedge',  
	\ 'oplus', 'otimes', 'odot', 'oint',
	\ 'int', 'bigoplus', 'bigotimes', 'bigodot', 'times',  
	\ 'smile', 'frown', 'subset', 'subseteq', 'supset', 'supseteq',
	\ 'dashv', 'vdash', 'vDash', 'Vdash', 'models', 'sim', 'simeq', 
	\ 'prec', 'preceq', 'preccurlyeq', 'precapprox',
	\ 'succ', 'succeq', 'succcurlyeq', 'succapprox', 'approx', 
	\ 'thickapprox', 'conq', 'bullet', 
	\ 'lhd', 'unlhd', 'rhd', 'unrhd', 'dagger', 'ddager', 'dag', 'ddag', 
	\ 'ldots', 'cdots', 'vdots', 'ddots', 
	\ 'vartriangleright', 'vartriangleleft', 'trianglerighteq', 'trianglelefteq',
	\ 'copyright', 'textregistered', 'puonds',
	\ 'big', 'Big', 'Bigg', 'huge', 
	\ 'sqrt', 'frac{', 'cline', 'vline', 'hline', 'multicolumn{', 
	\ 'nouppercase', 'sqsubset', 'sqsupset', 'square', 'blacksqaure', 'triangledown', 'triangle', 
	\ 'diagdown', 'diagup', 'nexists', 'varnothing', 'Bbbk', 'circledS', 'complement', 'hslash', 'hbar', 
	\ 'eth', 'rightrightarrows', 'leftleftarrows', 'rightleftarrows', 'leftrighrarrows', 
	\ 'downdownarrows', 'upuparrows', 'rightarrowtail', 'leftarrowtail', 
	\ 'twoheadrightarrow', 'twoheadleftarrow', 'rceil', 'lceil', 'rfloor', 'lfloor', 
	\ 'bullet', 'bigtriangledown', 'bigtriangleup', 'ominus', 'bigcirc', 'amalg', 
	\ 'setminus', 'sqcup', 'sqcap', 
	\ 'notin', 'neq', 'smile', 'frown', 'equiv', 'perp',
	\ 'quad', 'qquad' ]

	let g:atp_math_commands_non_expert_mode=[ 'leqq', 'geqq', 'succeqq', 'preceqq', 
		    \ 'subseteqq', 'supseteqq', 'gtrapprox', 'lessapprox' ]
	 
	" requiers amssymb package:
	let g:atp_ams_negations=[ 'nless', 'ngtr', 'lneq', 'gneq', 'nleq', 'ngeq', 'nleqslant', 'ngeqslant', 
		    \ 'nsim', 'nconq', 'nvdash', 'nvDash', 
		    \ 'nsubseteq', 'nsupseteq', 
		    \ 'varsubsetneq', 'subsetneq', 'varsupsetneq', 'supsetneq', 
		    \ 'ntriangleright', 'ntriangleleft', 'ntrianglerighteq', 'ntrianglelefteq', 
		    \ 'nrightarrow', 'nleftarrow', 'nRightarrow', 'nLeftarrow', 
		    \ 'nleftrightarrow', 'nLeftrightarrow', 'nsucc', 'nprec', 'npreceq', 'nsucceq', 
		    \ 'precneq', 'succneq', 'precnapprox' ]

	let g:atp_ams_negations_non_expert_mode=[ 'lneqq', 'ngeqq', 'nleqq', 'ngeqq', 'nsubseteqq', 
		    \ 'nsupseteqq', 'subsetneqq', 'supsetneqq', 'nsucceqq', 'precneqq', 'succneqq' ] 

	" ToDo: add more amsmath commands.
	let g:atp_amsmath_commands=[ 'inserttext', 'multiligngap', 'shoveleft', 'shoveright', 'notag', 'tag', 
		    \ 'raistag{', 'displaybreak', 'allowdisplaybreaks', 'numberwithin{',
		    \ 'hdotsfor{' , 'mspace{',
		    \ 'negthinspace', 'negmedspace', 'negthickspace', 'thinspace', 'medspace', 'thickspace' ]
	
	let g:atp_fancyhdr_commands=['lfoot{', 'rfoot{', 'rhead{', 'lhead{', 
		    \ 'cfoot{', 'chead{', 'fancyhead{', 'fancyfoot{',
		    \ 'fancypagestyle{', 'fancyhf{}', 'headrulewidth ', 'footrulewidth ',
		    \ 'rightmark', 'leftmark', 'markboth', 
		    \ 'chaptermark', 'sectionmark', 'subsectionmark',
		    \ 'fancyheadoffset', 'fancyfootoffset', 'fancyhfoffset']


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
	" ToDo: completion for arguments in brackets [] for tikz commands.
	let g:atp_tikz_commands=[ 'matrix', 'node', 'shadedraw', 'draw', 'tikz', 'usetikzlibrary{', 'tikzset',
		    \ 'path', 'filldraw', 'fill', 'clip', 'drawclip', 'foreach', 'angle', 'coordinate',
		    \ 'useasboundingbox', 'tikztostart', 'tikztotarget', 'tikztonodes', 'tikzlastnode',
		    \ 'pgfextra', 'endpgfextra',
		    \ 'pattern', 'shade', 'shadedraw', ]
	" ToDo: think of keyword completions
" 	let g:tikz_keywords=[]

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
	let g:atp_check_if_math_opend=1
    endif
endif
" ToDo: Think about even better math modes patterns.
" \[ - math mode \\[ - not mathmode (this can be at the end of a line as: \\[3pt])
" \\[ - this is math mode, but tex will complain (now I'm not matching it,
" that's maybe good.) 
" How to deal with $:$ (they are usually in one line, we could count them)  and $$:$$ 
" matchpair
let g:atp_math_modes=[['[^\\]\\(','\[^\\]\)'], ['\[^\\]\\[','\[^\\]\\]'], 	['\begin{equation', '\end{equation'],
	    \ ['\\begin{align', '\end{align'], 		['\\begin{gather', '\\end{gather'], 
	    \ ['\\begin{flign', '\\end{flagin'], 	['\\begin[multiline', '\\end{multiline'],
	    \ ['\\begin{tikz', '\\end{tikz']]
" ToDo: user command list, env list g:atp_commands, g:atp_environments, 
"
" this function looks for an input file: in the list of buffers, under a path if
" it is given, then in the b:outdir.
" directory. The last argument if equal to 1, then look also
" under g:texmf.
function! s:Read_Input_File(ifile,check_texmf)

    let l:input_file = []

    " read the buffer or read file if the buffer is not listed.
    if buflisted(fnamemodify(a:ifile,":t"))
	let l:input_file=getbufline(fnamemodify(a:ifile,":t"),1,'$')
    " if the ifile is given with a path it should be tried to reaad from there
    elseif filereadable(a:ifile)
	let l:input_file=readfile(a:ifile)
    " if not then try to read it from b:outdir
    elseif filereadable(b:outdir . fnamemodify(a:ifile,":t"))
	let l:input_file=readfile(filereadable(b:outdir . fnamemodify(a:ifile,":t")))
    " the last chance is to look for it in the g:texmf directory
    elseif a:check_texmf && filereadable(findfile(a:ifile,g:texmf . '**'))
	let l:input_file=readfile(findfile(a:ifile,g:texmf . '**'))
    endif

    return l:input_file
endfunction
 
function! s:Add_to_List(list,what)

    let l:new=[] 
    for l:el in a:list
	call add(l:new,l:el . a:what)
    endfor
    return l:new
endfunction

" the argument should be g:mainfile but in any case it is made in this way.
" it specifies in which file to search for include files.
function! s:Search_Bib_Items(name)

    " we are going to make a dictionary { citekey : label } (see :h \bibitem) 
    let l:citekey_label_dict={}

    " make a list of include files.
    let l:inputfile_dict=FindInputFiles(a:name,0)
    let l:includefile_list=[]
    for l:key in keys(l:inputfile_dict)
	if l:inputfile_dict[l:key][0] =~ '^\%(include\|input\|includeonly\)$'
	    call add(l:includefile_list,s:append(l:key,'.tex'))
	endif
    endfor
    call add(l:includefile_list,g:mainfile) 
    let b:ifl=l:includefile_list

    " search for bibitems in all include files.
    for l:ifile in l:includefile_list

	let l:input_file = s:Read_Input_File(l:ifile,0)

	    " search for bibitems and make a dictionary of labels and citekeys
	    for l:line in l:input_file
		if l:line =~ '\\bibitem'
		    let l:label=substitute(l:line,'.*\\bibitem\s*\[\(.*\)\].*$','\1','')
		    if l:label =~ 'bibitem'
			let l:label=''
		    endif
		    call extend(l:citekey_label_dict,
			\ { substitute(l:line,'.*\\bibitem\s*\%(\[.*\]\)\?\s*{\(.*\)}.*$','\1','') : l:label },
			\ 'error') 
		endif
	    endfor
    endfor
	
    return l:citekey_label_dict
endfunction

" this function is for complition of \bibliography and \input commands it returns a list
" of all files under a:dir dir and in g:outdir with a given xtension.
function! s:Find_files(dir,in_current_dir,ext)
	let l:raw_bibfiles=split(globpath(s:append(a:dir,'/'),'**'))
	if a:in_current_dir
	    call extend(l:raw_bibfiles,split(globpath(b:outdir,'*')))
	endif
	let b:raw=l:raw_bibfiles
	let l:bibfiles=[]
	for l:key in l:raw_bibfiles
	    if l:key =~ a:ext . '$'
		call add(l:bibfiles,l:key)
	    endif
	endfor
	return l:bibfiles
endfunction

command! SearchBibItems 	:echo s:Search_Bib_Items(g:mainfile)

" ToDo: \ref{<Tab> do not closes the '}', its by purpose, as sometimes one
" wants to add more than one reference. But this is not allowed by this
" command! :) I can add it.
" works for:
" 	labels   (\ref,\eqref)
" 	bibitems (\cite)
" 	bibfiles (\bibliography)
" 	packages (\usepackage)
" 	commands
" 	environments (\begin)
" 	end	     (close \begin{env} with \end{env})
"

"ToDo: the completion should be only done if the completed text is different
"from what it is. But it might be as it is, there are reasons to keep this.
"

function! s:Copy_Indentation(line)
    let l:indent=split(a:line,'\s\zs')
    let l:eindent=""
    for l:s in l:indent
	if l:s =~ '^\%(\s\|\t\)'
	    let l:eindent.=l:s
	else
	    break
	endif
    endfor
    return l:eindent
endfunction
" the argument specifies if to use i or a (append before or after)
" default is to use i (before), so the cursor will be after.
" the second argument specifies which environment to close (without it tries
" checks which to close.
" ToDo: this would be nice if it worked with nested environments which starts in
" the same line (if starts in seprate lines the only thing to change is to
" move the cursor to the end of inserted closing).
" ToDo: add closing of other pairs {:},[:],\{:\} , \left:\right 
function! CloseLastEnv(...)

    if a:0 == 0 
	let l:com = 'i'
    elseif a:0 >= 1  && a:1 == 'a' 
	let l:com ='a'
    elseif  a:0 >= 1 && a:1 == 'i'
	let l:com = 'i'
    endif

    if a:0 >= 2
	let l:close=a:2
    endif
    if a:0 >= 3
	let l:env_name=a:3
    else
	let l:env_name="0"
    endif

    " ADD: if l:com == 'i' move before what we put.

"     let b:debug=0
"     let b:com=l:com "DEBUG

    if l:env_name == "0"
	let l:begin_line_env 	= searchpair('\\begin\s*{', '', '\\end\s*{', 'bnW')
	let l:begin_line_dmath 	= searchpair('[^\\]\\\[','','[^\\]\\\]', 'bnW')
	let l:begin_line_imath 	= searchpair('[^\\]\\(','','[^\\]\\)', 'bnW')
    else
	let l:begin_line 	= searchpair('\\begin\s*{' . l:env_name , '', '\\end\s*{' . l:env_name, 'bnW')
    endif

    if a:0 <= 1
	let l:begin_line=max([ l:begin_line_env, l:begin_line_imath, l:begin_line_dmath])
" 	echo "OK"
    elseif a:0 <= 2 && l:close == "environment"
" 	echo "env"
	let l:begin_line = l:begin_line_env
    elseif a:0 <= 2 && l:close == "displayed_math"
" 	echo "disp"
	let l:begin_line = l:begin_line_dmath
    elseif a:0 <= 2 && l:close == "inline_math"
" 	echo "inl"
	let l:begin_line = l:begin_line_imath
    endif

    if a:0 <= 2
	if l:begin_line_env >= l:begin_line_dmath && l:begin_line_env >= l:begin_line_imath
	    let l:close='environment'
	elseif l:begin_line_dmath > l:begin_line_env && l:begin_line_dmath > l:begin_line_imath
	    let l:close='displayed_math'
	else
	    let l:close='inline_math'
	endif
    endif

    " regardles of a:2 if a:3 is given:
    if a:0 == 3
	let l:close='environment'
    endif
"     let b:close=l:close " DEBUG
"     let b:begin_line=l:begin_line "DEBUG

    if l:begin_line
	let l:line=getline(l:begin_line)
	let l:cline=getline(".")
" 	let b:line=l:line	" DEBUG
	if l:close == 'environment'
	    if l:env_name == 0
		let l:env = matchstr(l:line, '\%(\\begin\s*{[^}]*}\s*\%(\\label\s*{[^}]*}\)\?\)*\s*\\begin{\zs[^}]*\ze}\%(.*\\begin\s{\)\@!')
	    else
		let l:env=l:env_name
	    endif
	endif
" 	let b:env=l:env " DEBUG
	let l:pos=getpos(".")
	" Copy the intendation of what we are closing.
	let l:eindent=s:Copy_Indentation(l:line)

	" Rules:
	" env & \[ \]: close in the same line unless it starts in a seprate
	" line,
	" \( \): close in the same line 
" 	if (l:close == 'environment' && l:line !~ '^\s*\\begin\s*{[^}]*}\s*\%(\[[^]]*\]\|\\label{[^}]*}\)*\s*$' 
" 		    \ && l:line !~ '^\s*\\begin\s*{\%(array\|tabular\)}\s*{[^}]*}\s*$' ) ||
" 		    \ (l:close == 'displayed_math' && l:line !~ '^\s*\\\[\s*$' ) ||
" 		    \ (l:close == 'inline_math' && (l:line !~ '^\s*\\(\s*$' || l:begin_line == line(".") )) 
	if (l:close == 'environment' 
		    \ && l:line !~ '^\s*\%(\$\|\$\$\|[^\\]\\(\|[^\\]\\\[\)\?\s*\\begin\s*{[^}]*}\s*\%(\[[^]]*\]\|\\label{[^}]*}\)*\s*$' 
		    \ && l:line !~ '^\s*\%(\$\|\$\$\|[^\\]\\(\|[^\\]\\\[\)\?\s*\\begin\s*{\%(array\|tabular\)}\%(\s*{[^}]*}\)\?\s*$' ) ||
		    \ (l:close == 'displayed_math' && l:line !~ '^\s*[^\\]\\\[\s*$' ) ||
		    \ (l:close == 'inline_math' && (l:line !~ '^\s*[^\\]\\(\s*$' || l:begin_line == line(".") )) 
	    " the above condition matches for the situations when we have to
	    " complete in the same line in three cases:
	    " l:close == environment, displayd_math or inline_math. 
	    if l:close == 'environment' && index(g:atp_no_complete,l:env) == '-1' 
		let b:d=1
" 		exec 'normal ' . l:com . '\end{'.l:env.'}'
		if l:com == 'a'
		    call setline(line("."), strpart(l:cline,0,getpos(".")[2]) . '\end{'.l:env.'}' . strpart(l:cline,getpos(".")[2]))
		else
		    call setline(line("."), strpart(l:cline,0,getpos(".")[2]-1) . '\end{'.l:env.'}' . strpart(l:cline,getpos(".")[2]-1))
		endif
	    elseif l:close == 'displayed_math'
		let b:d=2
" 		exec 'normal ' . l:com . '\]'
		if l:com == 'a'
		    call setline(line("."), strpart(l:cline,0,getpos(".")[2]) . '\]'. strpart(l:cline,getpos(".")[2]))
		else
		    call setline(line("."), strpart(l:cline,0,getpos(".")[2]-1) . '\]'. strpart(l:cline,getpos(".")[2]-1))
" TODO: This could be optional: (but the option rather
" should be on the argument of this function rather than
" here!
		    let l:pos=getpos(".")
		    let l:pos[2]+=2
		    call setpos(("."),l:pos)
		endif
	    elseif l:close == 'inline_math'
		let b:d=2
" 		exec "normal " . l:com  . "\\)"
		if l:com == 'a'
		    call setline(line("."), strpart(l:cline,0,getpos(".")[2]) . '\)'. strpart(l:cline,getpos(".")[2]))
		else
		    call setline(line("."), strpart(l:cline,0,getpos(".")[2]-1) . '\)'. strpart(l:cline,getpos(".")[2]-1))
		    let l:pos=getpos(".")
		    let l:pos[2]+=2
		    call setpos(("."),l:pos)
		endif
	    endif
" 	    let b:debug=1 " DEBUG
	else
	" We are closing in a new line, preerving the indentation.
	    
	    let l:line_nr=line(".")

	    "Debug:
	    "redraw!
	    if l:close == 'environment'
	    " NESTING
		let l:error=0
		let l:prev_line_nr="-1"
		let l:cenv_lines=[]
		let b:env_open_name=[] " DEBUG
		let l:nr=line(".")
		" l:line_nr number of line which we complete
		" l:cenv_lines list of closed environments (we complete after
		" line number maximum of these numbers.
		echomsg "DEBUG ----------"

		if g:atp_close_after_last_closed == 1	
		    let l:pos=getpos(".")
		endif

		while 1
		    if g:atp_close_after_last_closed == 1	
			let l:line_nr=search('\\begin\s*{','bW')
		    else
			let l:line_nr=s:Check_if_Opened('\\begin\s*{', '\\end\s*{',
				\ l:line_nr,g:atp_completion_limits[2],1)
		    endif
		    " match last environment openned in this line.
		    " ToDo: afterwards we can make it works for multiple openned
		    " envs.
		    let l:env_name=matchstr(getline(l:line_nr),'\\begin\s*{\zs[^}]*\ze}\%(.*\\begin\s*{[^}]*}\)\@!')
		    let l:close_line_nr=s:Check_if_Closed('\\begin\s*{' . l:env_name, 
				\ '\\end\s*{' . l:env_name,
				\ l:line_nr,g:atp_completion_limits[2],1)
		    echomsg "CLE line_nr " . l:line_nr . " close_line_nr " . l:close_line_nr . " env_name " . l:env_name

" 			let l:bis_close_line_nr=s:Check_if_Closed('\\begin\s*{', '\\end\s*{',
" 				    \ l:line_nr,g:atp_completion_limits[2],1)
" 			if l:bis_close_line_nr != 0 && l:bis_close_line_nr < l:nr
" 			    call add(l:cenv_lines,l:bis_close_line_nr)
" 			endif

		    if l:close_line_nr != 0
			call add(l:cenv_lines,l:close_line_nr)
		    else
			break
		    endif
		    let l:line_nr-=1
		endwhile

		if g:atp_close_after_last_closed == 1	
		    call setpos(".",l:pos)
		endif
		    
		let b:cenv_lines=deepcopy(l:cenv_lines)

		let b:line_nr=l:line_nr " DEBUG
			
		" get all names of environments which begin in this line
		let l:env_names=[]
		let l:line=getline(l:line_nr)
		while l:line =~ '\\begin\s*{' 
		    let l:cenv_begins = match(l:line,'\\begin{\zs[^}]*\ze}\%(.*\\begin\s{\)\@!')
		    let l:cenv_name = matchstr(l:line,'\\begin{\zs[^}]*\ze}\%(.*\\begin\s{\)\@!')
		    let l:cenv_len=len(l:cenv_name)
		    let l:line=strpart(l:line,l:cenv_begins+l:cenv_len)
		    call add(l:env_names,l:cenv_name)
			" DEBUG
" 			let b:env_names=l:env_names
" 			let b:line=l:line
" 			let b:cenv_begins=l:cenv_begins
" 			let b:cenv_name=l:cenv_name
		endwhile
		" thus we have a list of env names.
		
		" make a dictionary of lines where they closes. 
		" this is a list of pairs (I need the order!)
		let l:env_dict=[]
" 		let b:env_dict=l:env_dict
		" list of closed environments
		let l:cenv_names=[]
" 		let b:cenv_names=l:cenv_names
		for l:uenv in l:env_names
		    let l:uline_nr=s:Check_if_Closed('\\begin\s*{' . l:uenv . '}', 
				\ '\end\s*{' . l:uenv . '}', l:line_nr, g:atp_completion_limits[2])
		    call extend(l:env_dict,[ l:uenv, l:uline_nr])
		    if l:uline_nr != '0'
			call add(l:cenv_names,l:uenv)
		    endif
		endfor
		
		" close unclosed environments

		" check if at least one of them is closed
		if len(l:cenv_names) == 0
" 		    echomsg "cle DEBUG A1"
		    let l:str=""
		    for l:uenv in l:env_names
			if index(g:atp_no_complete,l:uenv) == '-1'
			    let l:str.='\end{' . l:uenv .'}'
			endif
		    endfor
		    " Do not append empty lines (l:str is empty if all l:uenv
		    " belongs to the g:atp_no_complete list.
		    if len(l:str) == 0
			return 0
		    endif
" 		    let b:str=l:str
		    let l:eindent=s:Copy_Indentation(getline(l:line_nr))
		    if len(l:cenv_lines) > 0 
			call append(max(l:cenv_lines), l:eindent . l:str)
		    else
" NEW CODE:
			" save to position and set go to l:line_nr (where
			" '\begin{' is not closed.
			let l:pos=getpos(".")
			let l:pos_saved=l:pos
			let l:pos[1]=l:line_nr
			let l:pos[2]=1
			call setpos(".",l:pos)
			
			" go from the line l:line_nr up and find first
			" \end{line} which is not in l:cenv_lines.
			while 1
			    let l:end_line=search('\\end{','bW',l:pos_saved[1])
			    if index(l:cenv_lines,l:end_line) != '-1'
				let l:pos[1]=l:end_line
				call setpos(".",l:pos)
			    else
				break
			    endif
			endwhile 
			if l:end_line != 0
			    call append(l:end_line-1, l:eindent . l:str)
			else	
" OLD LINE: 
			    call append(line("."), l:eindent . l:str)
			endif
		    endif
" END OF NEW CODE.
		else
		    return "this is too hard?"
" 		    for l:cenv in l:cenv_names
" 			let l:n=match(l:env_dict, [l:cenv,'0'])
" 			for l:m < l:n
" 		    endfor
		endif
		unlet l:env_names
		unlet l:env_dict
		unlet l:cenv_names
		unlet l:cenv_lines
" 		if getline('.') =~ '^\s*$'
" 		    exec "normal dd"
" 		endif
	    elseif  l:close == 'displayed_math'
		call append(l:iline, l:eindent . '\]')
	    elseif l:close == 'inline_math'
		call append(l:iline, l:eindent . '\)')
	    endif
" 	    let b:debug=2 " DEBUG
	    return ''
	endif
	" preserve the intendation
	if getline(line(".")) =~ '^\s\+\\end{'
	    call setline(line("."),substitute(getline(line(".")),'^\s*',l:eindent,''))
	endif
    endif
endfunction
" imap <F7> <Esc>:call CloseLastEnv()<CR>

" check if last bpat is closed.
" starting from the current line, limits the number of
" lines to search. It returns 0 if the environment is not closed or the line
" number where it is closed (an env is cannot be closed in 0 line)

" ToDo: the two function should only check not commented lines!
" ToDo: this do not works well with nested envs.
function! s:Check_if_Closed(bpat,epat,line,limit,...)

    if a:0 == 0 || a:1 == 0
	let l:method = 0
    elseif a:1 == 1
	let l:method = 1
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
    " 	echomsg "line " . l:nr . " " . l:line
    " 	echomsg " match A " . l:match_a . " match B " . l:match_b . " match C " . l:match_c
	" Check if Closed
	    if l:nr == a:line
		if strpart(l:line,getpos(".")[2]) =~ '\%(' . a:bpat . '.*\)\@<!' . a:epat
		    return l:nr
		endif
	    else
		if l:line =~ '\%(' . a:epat . '.*\)\@<!' . a:bpat
		    return 0
		elseif l:line =~ '\%(' . a:bpat . '.*\)\@<!' . a:epat 
    " 	    if l:line =~ a:epat 
		    return l:nr
		endif
	    endif
	    let l:nr+=1
	endwhile
	elseif l:method==1
	    " FIX:
	    " There is small issue with position and empty lines, this is
	    " a fix for some situtations (but not for empty lines):
" 	    let l:pos=getpos(".")
" 	    let l:pos_new=l:pos
" 	    if l:pos[2]<=1
" 		let l:pos_new[2]+=1
" 		call setpos(".",l:pos_new)
" 	    endif
	    " the position is restored at the end. END of FIX. 	

	    let l:bpat_count=0
	    let l:epat_count=0
	    let l:begin_line=getline(a:line)
	    let l:begin_line_nr=line(a:line)
" 	    echomsg "CC DEBUG ------------"
	    while l:nr <= a:line+l:limit
		let l:line=getline(l:nr)
	    " I assume that the env is opened in the line before!
		let l:bpat_count+=s:count(l:line,a:bpat,1)
		let l:epat_count+=s:count(l:line,a:epat,1)
" 		echomsg "cc line nr " . l:nr . " bpat " . l:bpat_count . " epat " . l:epat_count
		if (l:bpat_count+1) == l:epat_count && l:begin_line !~ a:bpat
" 		    echomsg "A"
		    return l:nr
		elseif l:bpat_count == l:epat_count && l:begin_line =~ a:bpat
" 		    echomsg "B"
		    return l:nr
		endif 
		let l:nr+=1
	    endwhile
" 	    if l:pos != l:pos_new
" 		call setpos(".",l:pos_new)
" 	    endif
	    return 0
	endif
endfunction

" Usage: By default (a:0 == 0 || a:1 == 0 ) it returns line number where the
" environment is opened if the environment is opened and is not closed (for
" completion), else it returns 0. However, if a:1 == 1 it returns line number
" where the environment is opened, if we are inside an environemt (it is
" openned and closed below the starting line or not closed at all), it if a:1
" = 2, it just check if env is opened without looking if it is closed (
" cursor position is important).
" a:1 == 0 first non closed
" a:1 == 2 first non closed by counting.
function! s:Check_if_Opened(bpat,epat,line,limit,...)

    if a:0 == 0 || a:1 == 0
	let l:check_mode = 0
    elseif a:1 == 1
	let l:check_mode = 1
    elseif a:1 == 2
	let l:check_mode = 2
    endif

    let b:check_mode=l:check_mode

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
    " 	echo "DEBUG A " . l:nr . " " . l:line
		if l:nr == a:line
			if substitute(strpart(l:line,0,getpos(".")[2]), a:bpat . '.\{-}' . a:epat,'','g')
				    \ =~ a:bpat
			    let b:ret=1
			    return l:nr
			endif
		else
		    if l:check_mode == 0
			if substitute(l:line, a:bpat . '.\{-}' . a:epat,'','g')
				    \ =~ a:bpat
			    " check if it is closed up to the place where we start. (There
			    " is no need to check after, it will be checked anyway
			    " b a seprate call in Tab_Completion.
			    if !s:Check_if_Closed(a:bpat,a:epat,l:nr,a:limit,0)
					    " LAST CHANGE 1->0 above
				let b:ret=2 . " " . l:nr 
				return l:nr
			    endif
			endif
		    elseif l:check_mode == 1
			if substitute(l:line, a:bpat . '.\{-}' . a:epat,'','g')
				    \ =~ a:bpat
			    let l:check=s:Check_if_Closed(a:bpat,a:epat,l:nr,a:limit)
    " 		    echo "DEBUG line nr: " l:nr . " line: " . l:line . " check: " . l:check
			    " if env is not closed or is closed after a:line
			    if  l:check == 0 || l:check >= a:line
				let b:ret=2 . " " . l:nr 
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
	    let l:bpat_count+=s:count(l:line,a:bpat,1)
	    let l:epat_count+=s:count(l:line,a:epat,1)
" 		echomsg "co " . l:c . " lnr " . l:nr . " bpat " . l:bpat_count . " epat " . l:epat_count
	    if l:bpat_count == (l:epat_count+1+l:c) && l:begin_line != line(".") 
		let l:env_name=matchstr(getline(l:nr),'\\begin{\zs[^}]*\ze}')
		let b:check=s:Check_if_Closed('\\begin{' . l:env_name . '}', '\\end{' . l:env_name . '}',1,a:limit,1)
" 			echomsg "co DEBUG " b:check . " env " . l:env_name
		if !b:check
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

command -buffer -nargs=* CheckIfOpened	:echo s:Check_if_Opened(<args>)
command -buffer -nargs=* CheckIfClosed	:echo s:Check_if_Closed(<args>)
" usage:
command -buffer CheckA	:echo s:Check_if_Closed('[^\\]\\(','[^\\]\\)',line('.'),"$")
command -buffer CheckB	:echo s:Check_if_Closed('\[^\\]\\[','[^\\]\\\]',line('.'),"$")
command -buffer CheckC	:echo s:Check_if_Closed('\\begin{','\\end{',line('.'),"$")
command -buffer OCheckA	:echo s:Check_if_Opened('[^\\]\\(','[^\\]\\)',line('.'),"^")
command -buffer OCheckB	:echo s:Check_if_Opened('[^\\]\\\[','[^\\]\\\]',line('.'),"^")
command -buffer OCheckC	:echo s:Check_if_Opened('\\begin{','\\end{',line('.'),"^")

" ToDo: to doc.
" I switched this off.
" if !exists("g:atp_complete_math_env_first")
"     let g:atp_complete_math_env_first=0
" endif
if !exists("g:atp_math_commands_first")
    let g:atp_math_commands_first=1
endif

" This is the main TAB COMPLITION function.
"
" expert_mode = 1 (on)  gives less completions in some cases (commands,...)
" 			the matching pattern has to match at the begining and
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
" ToDo: line 3832.
" ToDo: add math completion only if in math mode \(:\) or \[:\], but many
" people cab be used to $:$ and $$:$$.
" the pattern:
" \$\zs\([^\$]\|\\\)*\ze\$
" matches math modes (but not only, also the connecting parts, and it doesn't
" behave well with line breaks)
"
" Would it be hard to implement rules for completion
" environments are usually followed by \label, [...] or \end{}.
" ToDo: add closing for [:].


let g:atp_completion_modes=[ 
	    \ 'commands', 		'inline_math', 
	    \ 'displayed_math', 	'package_names', 
	    \ 'tikz_libraries', 	'environment_names', 
	    \ 'close_environments' , 	'labels', 
	    \ 'bibitems', 		'input_files',
	    \ 'bibfiles' ] 

if !exists("g:atp_completion_active_modes")
    let g:atp_completion_active_modes=g:atp_completion_modes
endif
" CHECK: l:completion_method=end ?
function! Tab_Completion(expert_mode)

    " this specifies the default argument for CloseLastEnv()
    " in some cases it is better to append after than before.
    let b:append='i'

    let l:pos=getpos(".")
    let l:rawline=getbufline("%",l:pos[1])
    let l:line=join(l:rawline)
    let l:l=strpart(l:line,0,l:pos[2]-1)
    let b:l=l:l	"DEBUG
    let l:n=strridx(l:l,'{')
    let l:m=strridx(l:l,',')
    let l:o=strridx(l:l,'\')
    let l:s=strridx(l:l,' ')

    let l:nr=max([l:n,l:m,l:o,l:s])
    let l:begin=strpart(l:l,l:nr+1)
    let b:begin=l:begin "DEBUG
    " what we are trying to complete: usepackage, environment.
    let l:pline=strpart(l:l,0,l:nr)
    let b:pline=l:pline	"DEBUG
    if l:pline =~ '\\usepackage\%([.*]\)\?\s*'
	if index(g:atp_completion_active_modes, 'package_names') != '-1'
	    let l:completion_method='package'
	    let b:comp_method='package' "DEBUG
	else
	    return ''
	endif
    elseif l:pline =~ '\\usetikzlibrary\%([.*]\)\?\s*'
	if index(g:atp_completion_active_modes, 'tikz_libraries') != '-1'
	    let l:completion_method='tikz_libraries'
	    let b:comp_method='tikz_libraries' "DEBUG
	else
	    return ''
	endif
    elseif l:pline =~ '\%(\\begin\|\\end\)\s*$' && l:begin !~ '}\s*$'
	if index(g:atp_completion_active_modes, 'environment_names') != '-1'
	    let l:completion_method='environment_names'
	    let b:comp_method='begin' "DEBUG
	else
	    return ''
	endif
    elseif (l:pline =~ '\\begin\s*$' && l:begin =~ '}\s*$') || ( l:pline =~ '\\begin\s*{[^}]*}\s*\\label' )
" CHECK THIS:
	if index(g:atp_completion_active_modes, 'close_environments') != '-1'
	    let l:completion_method='end'
	    let b:comp_method='end' "DEBUG
	else
	    return ''
	endif
    elseif l:o > l:n && l:o > l:s && 
		\ l:pline !~ '\%(input\|include\%(only\)\?\)' && 
		\ l:begin !~ '{\|}\|,\|-\|\^\|\$\|(\|)\|&\|-\|+\|=\|#\|:\|;\|\.\|,\||\|?$' &&
		\ l:begin !~ '^\[\|\]\|-\|{\|}\|(\|)'
	" in this case we are completeing a command
	" the last match are the things which for sure do not ends any
	" command.
	if index(g:atp_completion_active_modes, 'commands') != '-1'
	    let l:completion_method='command'
	    let b:comp_method='command' "DEBUG
	else
	    return ''
	endif
    elseif l:pline =~ '\\\%(eq\)\?ref\s*$'
	if index(g:atp_completion_active_modes, 'labels') != '-1'
	    let l:completion_method='labels'
	    let b:comp_method='label'  "DEBUG	
	else
	    return ''
	endif
    elseif l:pline =~ '\\\%(no\)\?cite'
	if index(g:atp_completion_active_modes, 'bibitems') != '-1'
	    let l:completion_method='bibitems'
	    let b:comp_method='bibitems'  "DEBUG	
	    if l:begin =~ '}\s*$'
		return ''
	    endif 
	else
	    return ''
	endif
    elseif (l:pline =~ '\\input' || l:begin =~ 'input') ||
		\ (l:pline =~ '\\include' || l:begin =~ 'include') ||
		\ (l:pline =~ '\\includeonly' || l:begin =~ 'includeonly') 
	if l:begin =~ 'input'
	    let l:begin=substitute(l:begin,'.*\%(input\|include\%(only\)\?\)\s\?','','')
	endif
	if index(g:atp_completion_active_modes, 'input_files') != '-1'
	    let l:completion_method='inputfiles'
	    let b:comp_method='inputfiles' " DEBUG
	else
	    return ''
	endif
    elseif l:pline =~ '\\bibliography'
	if index(g:atp_completion_active_modes, 'bibitems') != '-1'
	    let l:completion_method='bibfiles'
	    let b:comp_method='bibfiles' " DEBUG
	else
	    return ''
	endif
    else
	if index(g:atp_completion_active_modes, 'close_environments') != '-1'
	    let l:completion_method='close_env'
	    let b:comp_method='close_env' "DEBUG
	else
	    return ''
	endif
    endif


    " if the \[ is not closed we prefer to first close it and then to complete
    " the commands, it is better as then automatic tex will have better file
    " to operate on.
    
"     echomsg join(getpos("."))
"     let l:pos=getpos(".")
"     let l:pos_changed=0
"     if l:pos[2]>1
" 	let l:pos[2]-=1
" 	let l:pos_changed=1
"     endif
"     call setpos(".",l:pos)
    " ToDo: envrionments should be called with name! 
    " and this is known later :(
"     let l:env_lnr=search('\\begin\s*{','bnW')
"     let l:env_name=matchstr(getline(l:env_lnr),'\\begin\s*{\zs[^}]*\ze}\%(.*\\begin\s*{\)\@!')
    let l:env_opened 	= s:Check_if_Opened('\\begin{','\\end{',
				\ line('.'),g:atp_completion_limits[2],2)
    let b:env_opened = l:env_opened
    if l:env_opened != 0
	let l:env_lnr=l:env_opened
	let l:env_name=matchstr(getline(l:env_lnr),'\\begin\s*{\zs[^}]*\ze}\%(.*\\begin\s*{\)\@!')
	let b:env_name=l:env_name " DEBUG
	let l:env_closed 	= s:Check_if_Closed('\\begin{' . l:env_name,'\\end{' . l:env_name,
				\ line('.'),g:atp_completion_limits[2],1)
    else
	let l:env_closed=1
	let l:env_name=0 	" this is compatible with CloseLastEnv() function (argument for a:3).
    endif
    let l:imath_closed	= s:Check_if_Closed('[^\\]\\(','[^\\]\\)',line('.'),g:atp_completion_limits[0])
    let l:imath_opened	= s:Check_if_Opened('[^\\]\\(','[^\\]\\)',line('.'),g:atp_completion_limits[0])
    let l:dmath_closed	= s:Check_if_Closed('[^\\]\\\[','[^\\]\\\]',line('.'),g:atp_completion_limits[1])
    let l:dmath_opened	= s:Check_if_Opened('[^\\]\\\[','[^\\]\\\]',line('.'),g:atp_completion_limits[1])
    " DEBUG:
"     echomsg "ic " l:imath_closed 		. " io " . l:imath_opened . 
" 		\ " dc " . l:dmath_closed 	. " do " . l:dmath_opened . 
" 		\ " ec " . l:env_closed 	. " eo " . l:env_opened
"     let b:imath_closed=l:imath_closed
"     let b:imath_opened=l:imath_opened
"     let b:dmath_closed=l:dmath_closed
"     let b:dmath_opened=l:dmath_opened
    let b:env_closed = l:env_closed " DEBUG
    let b:env_opened = l:env_opened " DEBUG

"     if l:pos_changed==1
" 	 let l:pos[2]+=1
" 	 let l:pos_changed=0
" 	 call setpos(".",l:pos)
"     endif
"     if l:completion_method=='command' && g:atp_complete_math_env_first
" 	 if !s:Check_if_Closed('\\\[','\\\]',line('.'),g:atp_completion_limits[1]) && !s:Check_if_Closed('\\(','\\)',line('.'),g:atp_completion_limits[1])
" " 	 if !l:env_closed && !
" 	     let l:completion_method='close_env'
" 	     let b:comp_method='close_env'
" 	     let b:append='a'
" 	 endif
"     endif

    if l:completion_method=='close_env'
" 	let b:debugg = !l:env_closed || !l:imath_closed || !l:dmath_closed
	if !l:env_closed || !l:imath_closed || !l:dmath_closed
	    " ToDo: to make this work only if env is not closed every environment
	    " has to be called separatly, thus CloseLastEnv must be changed.
" 	    echomsg l:imath_closed . l:imath_opened 
" 	    echomsg l:dmath_closed . l:dmath_opened
" 	    echomsg l:env_closed . l:env_opened
	    if !l:imath_closed && l:imath_opened 
		let b:return="colse_env inl"
		call CloseLastEnv(b:append,'inline_math')
	    elseif !l:dmath_closed && l:dmath_opened
		let b:return="colse_env disp"
		call CloseLastEnv(b:append,'displayed_math')
	    else
"           elseif !l:env_closed && l:env_opened	
" DEBUG:
		let b:return="colse_env env_name "  . l:env_name . " closed:" . l:env_closed . " opened:" . l:env_opened 
		" the env name above might be not the one because it is looked
		" using '\\begin' and '\\end' this might be not enough,
		" however the function CloseLastEnv works prefectly and this
		" should be save:
		call CloseLastEnv(b:append,'environment')
	    endif
	endif
" 	if !exists("b:return")
" 	    call CloseLastEnv(b:append,'environment')
" 	    let b:return="close_env XY"
" 	endif

	" unlet variables if there were defined.
	if exists("l:completion_list")
	    unlet l:completion_list
	endif
	if exists("l:completions")
	    unlet l:completions
	endif
	return ''
    endif

    " generate the completion names
    " ------------ BEGIN --------------
    if l:completion_method == 'environment_names'
	let l:end=strpart(l:line,l:pos[2]-1)
	if l:end !~ '\s*}'
	    let l:completion_list=deepcopy(s:Add_to_List(g:atp_environments,'}'))
	else
	    let l:completion_list=deepcopy(g:atp_environments)
	endif
		    " TIKZ
		    if s:Search_Package('tikz') && 
				\ ( !g:atp_check_if_opened || 
				\ s:Check_if_Opened('\\begin{tikzpicture}','\\end{tikzpicture}',line('.'),80) || 
				\ s:Check_if_Opened('\\tikz{','}',line("."),g:atp_completion_limits[2]) )
			if l:end !~ '\s*}'
			    call deepcopy(extend(l:completion_list,s:Add_to_List(g:atp_tikz_environments,'}')))
			else
			    call deepcopy(extend(l:completion_list,g:atp_tikz_environments))
			endif
		    endif
		    " AMSMATH
		    let b:ddebug=0
		    if s:Search_Package('amsmath') || g:atp_amsmath == 1 || s:Document_Class() =~ '^ams'
			let b:ddebug=2
			if l:end !~ '\s*}'
			    call deepcopy(extend(l:completion_list,s:Add_to_List(g:atp_amsmath_environments,'}'),0))
			else
			    call deepcopy(extend(l:completion_list,g:atp_amsmath_environments,0))
			endif
		    endif
    " ------------ PACKAGE ---------------
    elseif l:completion_method == 'package'
	let l:completion_list=deepcopy(g:atp_package_list)    
    " ------------ TIKZ LIBRARIES --------
    elseif l:completion_method == 'tikz_libraries'
	let l:completion_list=deepcopy(g:atp_tikz_libraries)
    " ------------ COMMAND ---------------
    elseif l:completion_method == 'command'
	let l:obegin=strpart(l:l,l:o+1)
	let l:completion_list=[]

		" Are we in the math mode?
		let l:math_is_opened=0
		if g:atp_math_opened
		    for l:key in g:atp_math_modes
			if s:Check_if_Opened(l:key[0],l:key[1],line("."),g:atp_completion_limits[2])
			    let l:math_is_opened=1
			    break
			endif
		    endfor
		endif

		" if math is not opened or we do not check for math mode
		if ( !g:atp_math_opened || !l:math_is_opened )
		    let l:completion_list=deepcopy(g:atp_commands)
		endif


		" if we are in math mode or if we do not check for it ...
" 		let b:adebug=0
" 		echomsg "DEBUG " . g:atp_no_math_command_completion != 1 &&  ( !g:atp_math_opened  || l:math_is_opened )
		if g:atp_no_math_command_completion != 1 &&  ( !g:atp_math_opened || l:math_is_opened )
" 		    let b:adebug=1
		    " add commands if thier package is declared.
		    " TIKZ 
		    if s:Search_Package('tikz')
			call deepcopy(extend(l:completion_list,g:atp_tikz_commands))
		    endif
		    " NICEFRAC
		    if s:Search_Package('nicefrac')
			call add(l:completion_list,'nicefrac')
		    endif

		    " AMSMATH
		    let b:debug="no amsmath commands"
		    if g:atp_amsmath == 1 || s:Search_Package('amsmath') || 
				\ s:Search_Package('amssymb') || s:Document_Class() =~ '^ams'
			let b:debug="amsmath commands added"
			if a:expert_mode == 0
			    call deepcopy(extend(l:completion_list,g:atp_math_commands_non_expert_mode))
			endif
			if g:atp_math_commands_first == 1
			    call deepcopy(extend(l:completion_list,g:atp_amsmath_commands,0))
			    call deepcopy(extend(l:completion_list,g:atp_math_commands,0))
			else
			    call deepcopy(extend(l:completion_list,g:atp_math_commands,len(l:completion_list)))
			    call deepcopy(extend(l:completion_list,g:atp_amsmath_commands,len(l:completion_list)))
			endif
		    endif
		    if s:Search_Package('amssymb')
			call deepcopy(extend(l:completion_list,g:atp_ams_negations))
			if a:expert_mode == 0 
			    call deepcopy(extend(l:completion_list,g:atp_ams_negations_non_expert_mode))
			endif
		    endif
		endif
		" FANCYHDR
		if s:Search_Package('fancyhdr')
		    call deepcopy(extend(l:completion_list,g:atp_fancyhdr_commands))
		endif
		" ToDo: LAYOUT and many more packages.
		
" change the \label{ to \label{short_env_name, also adds it if we are labeling an item (but only if \label is just after \itme\s*\([ ]\)\s* (in the item text one want to have a diffrent prefix).
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
	let b:env_name=l:env_name " DEBUG

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

" 	if index(g:atp_no_separator_list,l:env_name) != -1
" 	    let l:no_separator = 1
" 	endif

	if g:atp_env_short_names == 1
	    if l:no_separator == 0 && g:atp_no_separator == 0
		let l:short_env_name=l:short_env_name . g:atp_separator
	    endif
	else
	    let l:short_env_name=''
	endif

" 	let b:no_sep=l:no_separator " DEBUG
	call deepcopy(extend(l:completion_list, [ 'label{' . l:short_env_name ],0))

    " ----------- LABELS ------------------
    elseif l:completion_method == 'labels'
	let l:completion_list=[]
	let l:precompletion_list=deepcopy(values(s:generatelabels(fnamemodify(bufname("%"),":p"))[fnamemodify(bufname("%"),":p")]))
	for l:label in l:precompletion_list
	    call add(l:completion_list,l:label . '}')
	endfor

    " ----------- TEX_INPUTFILES ----------------- 
    elseif l:completion_method ==  'inputfiles'
	let l:inputfiles=s:Find_files(g:texmf,1,".tex")
	let l:completion_list=[]
	for l:key in l:inputfiles
	    call add(l:completion_list,fnamemodify(l:key,":t:r"))
	endfor
	call sort(l:completion_list)
    " ----------- BIBFILES ----------------- 
    elseif l:completion_method ==  'bibfiles'
	let l:bibfiles=s:Find_files(g:bibinputs,1,".bib")
	let l:completion_list=[]
	for l:key in l:bibfiles
	    call add(l:completion_list,fnamemodify(l:key,":t:r"))
	endfor
	call sort(l:completion_list)
    " ----------- BIBITEMS ----------------- 
    elseif l:completion_method == 'bibitems'
	let l:bibitems_list=values(s:searchbib(''))
	let b:bibitems_list=l:bibitems_list
	let l:pre_completion_list=[]
	let l:completion_list=[]
	for l:dict in l:bibitems_list
	    for l:key in keys(l:dict)
		call add(l:pre_completion_list,l:dict[l:key]['KEY']) 
	    endfor
	endfor
	for l:key in l:pre_completion_list
	    call add(l:completion_list,substitute(strpart(l:key,max([stridx(l:key,'{'),stridx(l:key,'(')])+1),',\s*','',''))
	endfor

	" add the \bibitems found in include files
	call deepcopy(extend(l:completion_list,keys(s:Search_Bib_Items(g:mainfile))))
    endif
    if exists("l:completion_list")
	let b:completion_list=l:completion_list	" DEBUG
    endif

    " make the list of matching items
    if l:completion_method != 'end' && l:completion_method != 'env_close'
	let l:completions=[]
	for l:item in l:completion_list
	    " Packages, environments, labels, bib and input files must match
	    " at the beginning (in expert_mode).
	    if (l:completion_method == 'package' ||
			\ l:completion_method == 'environment_names' ||
			\ l:completion_method == 'labels' ||
			\ l:completion_method == 'bibfiles' )
		if a:expert_mode == 1 && l:item =~ '\C^' . l:begin
		    call add(l:completions,l:item)
		elseif a:expert_mode!=1 && l:item =~ l:begin
		    call add(l:completions,l:item)
		endif
	    " Bibitems match not only in the beginning!!! 
	    elseif (l:completion_method == 'bibitems' ||
			\ l:completion_method == 'tikz_libraries' ||
			\ l:completion_method == 'inputfiles') &&
			\ l:item =~ l:begin
		call add(l:completions,l:item)
	    " Commands must match at the beginning (but in a different way)
	    " (only in epert_mode).
	    elseif l:completion_method == 'command' 
		if a:expert_mode == 1 && l:item =~ '\C^' . l:obegin
		    call add(l:completions, '\' . l:item)
		elseif a:expert_mode != 1 && l:item =~  l:obegin
		    call add(l:completions, '\' . l:item)
		endif
	    endif
	endfor
    else
	" preserve the indentation
	let l:indent=substitute(l:l,'^\(\s*\)\\begin.*','\1','')
	let b:indent=l:indent " DEBUG
	" 	LAST CHANGE
" 	call append(line("."),l:indent . '\end{' . substitute(l:l,'.*\\begin{\(.\{-}}\).*','\1',''))
	let b:return="1"
	call CloseLastEnv('a','environment')
	
	return ''
    endif

    let b:completions=l:completions " DEBUG

    " if the list is long it is better if it is sorted, if it short it is
    " better if the more used things are at the begining.
    if len(l:completions) > 5 && l:completion_method != 'labels'
	let l:completions=sort(l:completions)
    endif

    if l:completion_method == 'environment_names' || l:completion_method == 'package' || 
		\ l:completion_method == 'tikz_libraries' 	|| l:completion_method == 'labels' ||
		\ l:completion_method == 'bibitems' 		|| l:completion_method == 'bibfiles' || 
		\ l:completion_method == 'bibfiles'		|| l:completion_method == 'inputfiles'
	call complete(l:nr+2,l:completions)
	let b:return="2"
    elseif l:completion_method == 'command'
	call complete(l:o+1,l:completions)
	let b:return="3 X"
    endif

    " it the completion method was a command (probably in a math mode) and
    " there was no completion check if the \[ and \( are closed.
" E523 exec 'normal a\\)' do not works but setline works.
    if l:completion_method == 'command' && (len(l:completions) == 0 && a:expert_mode
		\ || len(l:completions) == 1 && l:completions[0] == '\'. l:begin )
		\ && ( !s:Check_if_Closed('[^\\]\\\[','[^\\]\\\]',line("."),g:atp_completion_limits[1]) ||
		\ !s:Check_if_Closed('[^\\]\\(','[^\\]\\)',line("."),g:atp_completion_limits[0]) )
	if s:Check_if_Closed('[^\\]\\\[','[^\\]\\\]',line('.'),g:atp_completion_limits[1]) && s:Check_if_Opened('[^\\]\\\[','[^\\]\\\]',line('.'),g:atp_completion_limits[1])
	    let l:a='disp; " DEBUG
	    call CloseLastEnv('i','displayed_math')
	elseif s:Check_if_Closed('[^\\]\\(','[^\\]\\)',line('.'),g:atp_completion_limits[0]) && s:Check_if_Opened('[^\\]\\(','[^\\]\\)',line('.'),g:atp_completion_limits[1])
	    call CloseLastEnv('i','inline_math')
	    let l:a='inl' " DEBUG
	endif
	let b:comp_method='e:close_env' "DEBUG
	let b:return="close_env end" 
    endif

"  ToDo: (a chalanging one)  
"  Move one step after completion is done (see the condition).
"  for this one have to end till complete() function will end, and this I do
"  not know how to do. 
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
endfunction

" ------- Wrap Seclection ----------------------------
function! WrapSelection(wrapper)
    normal `>a}
    exec 'normal `<i\'.a:wrapper.'{'
endfunction

"--------- MAPPINGS -------------------------------------------------------
" Add mappings, unless the user didn't want this.
" ToDo: to doc.
if !exists("g:atp_no_env_maps")
    let g:atp_no_env_maps=0
endif
if !exists("no_plugin_maps") && !exists("no_atp_maps")
    " ToDo to doc.
    if exists("g:atp_no_tab_map") && g:atp_no_tab_map == 1
	inoremap <buffer> <F7> <C-R>=Tab_Completion(1)<CR>
	inoremap <buffer> <S-F7> <C-R>=Tab_Completion(0)<CR>
    else
	inoremap <buffer> <Tab> <C-R>=Tab_Completion(1)<CR>
	inoremap <buffer> <S-Tab> <C-R>=Tab_Completion(0)<CR>
	vmap <buffer> <silent> <F7> <Esc>:call WrapSelection('')<CR>i
    endif

    map  <buffer> <LocalLeader>v		:call ViewOutput() <CR><CR>
    map  <buffer> <F2> 				:ToggleSpace<CR>
    map  <buffer> <F3>        			:call ViewOutput() <CR><CR>
    imap <buffer> <F3> <Esc> 			:call ViewOutput() <CR><CR>
    map  <buffer> <LocalLeader>g 		:call Getpid()<CR>
    map  <buffer> <LocalLeader>t		:TOC<CR>
    map  <buffer> <LocalLeader>L		:Labels<CR>
    map  <buffer> <LocalLeader>l 		:TEX<CR>	
    map  <buffer> 2<LocalLeader>l 		:2TEX<CR>	 
    map  <buffer> 3<LocalLeader>l		:3TEX<CR>
    map  <buffer> 4<LocalLeader>l		:4TEX<CR>
    " imap <buffer> <LocalLeader>l	<Left><ESC>:TEX<CR>a
    " imap <buffer> 2<LocalLeader>l	<Left><ESC>:2TEX<CR>a
    " todo: this is nice idea but it do not works as it should: 
    " map  <buffer> <f4> [d:let nr = input("which one: ")<bar>exe "normal " . nr . "[\t"<cr> 
    map  <buffer> <f5> 				:call VTEX() <cr>	
    map  <buffer> <s-f5> 			:call ToggleAuTeX()<cr>
    imap <buffer> <f5> <left><esc> 		:call VTEX() <cr>a
    map  <buffer> <localleader>sb		:call SimpleBibtex()<cr>
    map  <buffer> <localleader>b		:call Bibtex()<cr>
    map  <buffer> <f6>d 			:call Delete() <cr>
    imap <buffer> <silent> <f6>l 		:call OpenLog() <cr>
    map  <buffer> <silent> <f6>l 		:call OpenLog() <cr>
    map  <buffer> <localleader>e 		:cf<cr> 
    map  <buffer> <f6>w 			:call texlog("-w")<cr>
    imap <buffer> <f6>w 			:call texlog("-w")<cr>
    map  <buffer> <f6>r 			:call texlog("-r")<cr>
    imap <buffer> <f6>r 			:call texlog("-r")<cr>
    map  <buffer> <f6>f 			:call texlog("-f")<cr>
    imap <buffer> <f6>f 			:call texlog("-f")<cr>
    map  <buffer> <f6>g 			:call PdfFonts()<cr>
    map  <buffer> <f1> 	   			:!clear;texdoc -m 
    imap <buffer> <f1> <esc> 			:!clear;texdoc -m  
    map  <buffer> <localleader>p 		:call print('','')<cr>

    " FONT MAPPINGS
    imap <buffer> ##rm \textrm{}<Left>
    imap <buffer> ##it \textit{}<Left>
    imap <buffer> ##sl \textsl{}<Left>
    imap <buffer> ##sf \textsf{}<Left>
    imap <buffer> ##bf \textbf{}<Left>
	    
    imap <buffer> ##mit \mathit{}<Left>
    imap <buffer> ##mrm \mathrm{}<Left>
    imap <buffer> ##msf \mathsf{}<Left>
    imap <buffer> ##mbf \mathbf{}<Left>

    " GREEK LETTERS
    imap <buffer> #a \alpha
    imap <buffer> #b \beta
    imap <buffer> #c \chi
    imap <buffer> #d \delta
    imap <buffer> #e \epsilon
    imap <buffer> #f \phi
    imap <buffer> #y \psi
    imap <buffer> #g \gamma
    imap <buffer> #h \eta
    imap <buffer> #k \kappa
    imap <buffer> #l \lambda
    imap <buffer> #i \iota
    imap <buffer> #m \mu
    imap <buffer> #n \nu
    imap <buffer> #p \pi
    imap <buffer> #o \theta
    imap <buffer> #r \rho
    imap <buffer> #s \sigma
    imap <buffer> #t \tau
    imap <buffer> #u \upsilon
    imap <buffer> #vs \varsigma
    imap <buffer> #vo \vartheta
    imap <buffer> #w \omega
    imap <buffer> #x \xi
    imap <buffer> #z \zeta

    imap <buffer> #D \Delta
    imap <buffer> #Y \Psi
    imap <buffer> #F \Phi
    imap <buffer> #G \Gamma
    imap <buffer> #L \Lambda
    imap <buffer> #M \Mu
    imap <buffer> #N \Nu
    imap <buffer> #P \Pi
    imap <buffer> #O \Theta
    imap <buffer> #S \Sigma
    imap <buffer> #T \Tau
    imap <buffer> #U \Upsilon
    imap <buffer> #V \Varsigma
    imap <buffer> #W \Omega

    if g:atp_no_env_maps != 1
	imap <buffer> [b \begin{}<Left>
	imap <buffer> [e \end{}<Left>
	imap [s \begin{}<CR>\end{}<Up><Right>

	imap <buffer> ]c \begin{center}<Cr>\end{center}<Esc>O
	imap <buffer> [c \begin{corollary}<Cr>\end{corollary}<Esc>O
	imap <buffer> [d \begin{definition}<Cr>\end{definition}<Esc>O
	imap <buffer> ]e \begin{enumerate}<Cr>\end{enumerate}<Esc>O
	imap <buffer> [q \begin{equation}<Cr>\end{equation}<Esc>O
	imap <buffer> [a \begin{align}<Cr>\end{align}<Esc>O
	imap <buffer> [x \begin{example}<Cr>\end{example}<Esc>O
	imap <buffer> ]q \begin{equation}<Cr>\end{equation}<Esc>O
	imap <buffer> ]l \begin{flushleft}<Cr>\end{flushleft}<Esc>O
	imap <buffer> ]r \begin{flushright}<Cr>\end{flushright}<Esc>O
	imap <buffer> [f \begin{frame}<Cr>\end{frame}<Esc>O
	imap <buffer> [i \item
	imap <buffer> ]i \begin{itemize}<Cr>\end{itemize}<Esc>O
	imap <buffer> [l \begin{lemma}<Cr>\end{lemma}<Esc>O
	imap <buffer> [n \begin{note}<Cr>\end{note}<Esc>O
	imap <buffer> [o \begin{observation}<Cr>\end{observation}<Esc>O
	imap <buffer> ]p \begin{proof}<Cr>\end{proof}<Esc>O
	imap <buffer> [p \begin{proposition}<Cr>\end{proposition}<Esc>O
	imap <buffer> [r \begin{remark}<Cr>\end{remark}<Esc>O
	imap <buffer> [t \begin{theorem}<Cr>\end{theorem}<Esc>O
	imap <buffer> ]t \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>

	" imap {c \begin{corollary*}<Cr>\end{corollary*}<Esc>O
	" imap {d \begin{definition*}<Cr>\end{definition*}<Esc>O
	" imap {x \begin{example*}\normalfont<Cr>\end{example*}<Esc>O
	" imap {l \begin{lemma*}<Cr>\end{lemma*}<Esc>O
	" imap {n \begin{note*}<Cr>\end{note*}<Esc>O
	" imap {o \begin{observation*}<Cr>\end{observation*}<Esc>O
	" imap {p \begin{proposition*}<Cr>\end{proposition*}<Esc>O
	" imap {r \begin{remark*}<Cr>\end{remark*}<Esc>O
	" imap {t \begin{theorem*}<Cr>\end{theorem*}<Esc>O
    endif

    imap <buffer> __ _{}<Left>
    imap <buffer> ^^ ^{}<Left>
    imap <buffer> [m \[\]<Left><Left>
endif

" This is an additional syntax group for enironment provided by the TIKZ
" package, a very powerful tool to make beautiful diagrams, and all sort of
" pictures in latex.
syn match texTikzCoord '\(|\)\?([A-Za-z0-9]\{1,3})\(|\)\?\|\(|\)\?(\d\d)|\(|\)\?'

" COMMANDS
command! -buffer ViewOutput		:call ViewOutput()
command! -buffer SetErrorFile 		:call SetErrorFile()
command! -buffer -nargs=? ShowOptions 	:call ShowOptions(<f-args>)
command! -buffer GPID 			:call Getpid()
command! -buffer CXPDF 			:echo s:xpdfpid()
command! -buffer -nargs=? -count=1 TEX  :call TEX(<count>,<f-args>)
command! -buffer -nargs=? -count=1 VTEX	:call VTEX(<count>,<f-args>)
command! -buffer SBibtex 		:call SimpleBibtex()
command! -buffer -nargs=? Bibtex 	:call Bibtex(<f-args>)
command! -buffer -nargs=? -complete=buffer FindBibFiles 	:echo keys(FindBibFiles(<f-args>))
command! -buffer -nargs=* BibSearch	:call BibSearch(<f-args>)
command! -buffer -nargs=? DefiSearch	:call DefiSearch(<f-args>)
command! -buffer TOC 			:call TOC()
command! -buffer CTOC 			:call CTOC()
command! -buffer Labels			:call Labels() 
command! -buffer SetOutDir 		:call s:setoutdir(1)
command! -buffer ATPStatus 		:call ATPStatus() 
command! -buffer PdfFonts		:call PdfFonts()
command! -buffer -nargs=? 					SetErrorFormat 	:call s:SetErrorFormat(<f-args>)
command! -buffer -nargs=? -complete=custom,ListErrorsFlags 	ShowErrors 	:call s:ShowErrors(<f-args>)
command! -buffer -nargs=? -complete=buffer	 		FindInputFiles	:call FindInputFiles(<f-args>)
command! -buffer -nargs=* -complete=customlist,EI_compl	 	EditInputFile 	:call EditInputFile(<f-args>)
command! -buffer -nargs=? -complete=buffer	 ToDo 			:call ToDo('\c\<todo\>','\s*%\c.*\<note\>',<f-args>)
command! -buffer -nargs=? -complete=buffer	 Note			:call ToDo('\c\<note\>','\s*%\c.*\<todo\>',<f-args>)
command! -buffer SetXdvi		:call SetXdvi()
command! -buffer SetXpdf		:call SetXpdf()	
command! -complete=custom,ListPrinters  -buffer -nargs=* SshPrint	:call Print(<f-args>)

command! -buffer -nargs=1 -complete=customlist,Env_compl NEnv			:call NextEnv(<f-args>)
command! -buffer -nargs=1 -complete=customlist,Env_compl PEnv			:call PrevEnv(<f-args>)
command! -buffer -nargs=? -complete=customlist,Env_compl NSec			:call NextSection('section',<f-args>)
command! -buffer -nargs=? -complete=customlist,Env_compl PSec			:call PrevSection('section',<f-args>)
command! -buffer -nargs=? -complete=customlist,Env_compl NChap			:call NextSection('chapter',<f-args>)
command! -buffer -nargs=? -complete=customlist,Env_compl PChap			:call PrevSection('chapter',<f-args>)
command! -buffer -nargs=? -complete=customlist,Env_compl NPart			:call NextSection('part',<f-args>)
command! -buffer -nargs=? -complete=customlist,Env_compl PPart			:call PrevSection('part',<f-args>)
command! -buffer ToggleSpace   		:call ToggleSpace()
command! -buffer ToggleCheckMathOpened 	:call ToggleCheckMathOpened()

" MENU
if !exists("no_plugin_menu") && !exists("no_atp_menu")
nmenu 550.10 &LaTeX.&Make<Tab>:TEX		:TEX<CR>
nmenu 550.10 &LaTeX.Make\ &twice<Tab>:2TEX	:2TEX<CR>
nmenu 550.10 &LaTeX.Make\ verbose<Tab>:VTEX	:VTEX<CR>
nmenu 550.10 &LaTeX.&Bibtex<Tab>:Bibtex	:Bibtex<CR>
" nmenu 550.10 &LaTeX.&Bibtex\ (bibtex)<Tab>:SBibtex		:SBibtex<CR>
nmenu 550.10 &LaTeX.&View<Tab>:ViewOutput 	:ViewOutput<CR>
"
nmenu 550.20 &LaTeX.&Log.&Open\ Log\ File<Tab>:map\ <F6>l		:call OpenLog()<CR>
nmenu 550.20 &LaTeX.&Log.-ShowErrors-	:
nmenu 550.20 &LaTeX.&Log.&Errors<Tab>:ShowErrors			:ShowErrors<CR>
nmenu 550.20 &LaTeX.&Log.&Warnings<Tab>:ShowErrors\ w 			:ShowErrors w<CR>
nmenu 550.20 &LaTeX.&Log.&Citation\ Warnings<Tab>:ShowErrors\ c		:ShowErrors c<CR>
nmenu 550.20 &LaTeX.&Log.&Reference\ Warnings<Tab>:ShowErrors\ r		:ShowErrors r<CR>
nmenu 550.20 &LaTeX.&Log.&Font\ Warnings<Tab>ShowErrors\ f			:ShowErrors f<CR>
nmenu 550.20 &LaTeX.&Log.Font\ Warnings\ &&\ Info<Tab>:ShowErrors\ fi	:ShowErrors fi<CR>
nmenu 550.20 &LaTeX.&Log.&Show\ Files<Tab>:ShowErrors\ F			:ShowErrors F<CR>
"
nmenu 550.20 &LaTeX.&Log.-PdfFotns- :
nmenu 550.20 &LaTeX.&Log.&Pdf\ Fonts<Tab>:PdfFonts		:PdfFonts<CR>
"
nmenu 550.20 &LaTeX.&Log.-Delete-	:
nmenu 550.20 &LaTeX.&Log.&Delete\ Tex\ Output\ Files<Tab>:map\ <F6>d		:call Delete()<CR>
nmenu 550.20 &LaTeX.&Log.Set\ Error\ File<Tab>:SetErrorFile	:SetErrorFile<CR> 
"
nmenu 550.30 &LaTeX.-TOC- :
nmenu 550.30 &LaTeX.&Table\ of\ Contents<Tab>:TOC		:TOC<CR>
nmenu 550.30 &LaTeX.L&abels<Tab>:Labels			:Labels<CR>
"
nmenu 550.40 &LaTeX.&Go\ to.&EditInputFile<Tab>:EditInputFile		:EditInputFile<CR>
"
nmenu 550.40 &LaTeX.&Go\ to.-Environment- :
nmenu 550.40 &LaTeX.&Go\ to.Next\ Definition<Tab>:NEnv\ definition	:NEnv definition<CR>
nmenu 550.40 &LaTeX.&Go\ to.Previuos\ Definition<Tab>:PEnv\ definition	:PEnv definition<CR>
nmenu 550.40 &LaTeX.&Go\ to.Next\ Environment<Tab>:NEnv\ <arg>		:NEnv 
nmenu 550.40 &LaTeX.&Go\ to.Previuos\ Environment<Tab>:PEnv\ <arg>	:PEnv 
"
nmenu 550.40 &LaTeX.&Go\ to.-Section- :
nmenu 550.40 &LaTeX.&Go\ to.&Next\ Section<Tab>:NSec			:NSec<CR>
nmenu 550.40 &LaTeX.&Go\ to.&Previuos\ Section<Tab>:PSec		:PSec<CR>
nmenu 550.40 &LaTeX.&Go\ to.Next\ Chapter<Tab>:NChap			:NChap<CR>
nmenu 550.40 &LaTeX.&Go\ to.Previous\ Chapter<Tab>:PChap		:PChap<CR>
nmenu 550.40 &LaTeX.&Go\ to.Next\ Part<Tab>:NPart			:NPart<CR>
nmenu 550.40 &LaTeX.&Go\ to.Previuos\ Part<Tab>:PPart			:PPart<CR>
"
nmenu 550.50 &LaTeX.-Bib-			:
nmenu 550.50 &LaTeX.Bib\ Search<Tab>:Bibsearch\ <arg>			:BibSearch 
nmenu 550.50 &LaTeX.Find\ Bib\ Files<Tab>:FindBibFiles			:FindBibFiles<CR> 
nmenu 550.50 &LaTeX.Find\ Input\ Files<Tab>:FindInputFiles			:FindInputFiles<CR>
"
nmenu 550.60 &LaTeX.-Viewer-			:
nmenu 550.60 &LaTeX.Set\ &XPdf<Tab>:SetXpdf					:SetXpdf<CR>
nmenu 550.60 &LaTeX.Set\ X&Dvi\ (inverse\/reverse\ search)<Tab>:SetXdvi	:SetXdvi<CR>
"
nmenu 550.70 &LaTeX.-Editting-			:
"
" ToDo: show options doesn't work from the menu (it disappears immediately, but at
" some point I might change it completely)
nmenu 550.70 &LaTeX.&Options.&Show\ Options<Tab>:ShowOptions		:ShowOptions<CR> 
nmenu 550.70 &LaTeX.&Options.-set\ options- :
nmenu 550.70 &LaTeX.&Options.Automatic\ TeX\ Processing<Tab>b:autex	:let b:autex=
nmenu 550.70 &LaTeX.&Options.Set\ Runs<Tab>b:auruns			:let b:auruns=
nmenu 550.70 &LaTeX.&Options.Set\ TeX\ Compiler<Tab>b:texcompiler	:let b:texcompiler="
nmenu 550.70 &LaTeX.&Options.Set\ Viewer<Tab>b:Viewer			:let b:Viewer="
nmenu 550.70 &LaTeX.&Options.Set\ Viewer\ Options<Tab>b:ViewerOptions	:let b:ViewerOptions="
nmenu 550.70 &LaTeX.&Options.Set\ Output\ Directory<Tab>b:outdir	:let b:ViewerOptions="
nmenu 550.70 &LaTeX.&Options.Set\ Output\ Directory\ to\ the\ default\ value<Tab>:SetOutDir	:SetOutDir<CR> 
nmenu 550.70 &LaTeX.&Options.Ask\ for\ the\ Output\ Directory<Tab>g:askfortheoutdir		:let g:askfortheoutdir="
nmenu 550.70 &LaTeX.&Options.Open\ Viewer<Tab>b:openviewer		:let b:openviewer="
nmenu 550.70 &LaTeX.&Options.Open\ Viewer<Tab>b:openviewer		:let b:openviewer="
nmenu 550.70 &LaTeX.&Options.Set\ Error\ File<Tab>:SetErrorFile		:SetErrorFile<CR> 
nmenu 550.70 &LaTeX.&Options.Which\ TeX\ files\ to\ copy<Tab>g:keep	:let g:keep="
nmenu 550.70 &LaTeX.&Options.Tex\ extensions<Tab>g:texextensions	:let g:texextensions="
nmenu 550.70 &LaTeX.&Options.Remove\ Command<Tab>g:rmcommand		:let g:rmcommand="
nmenu 550.70 &LaTeX.&Options.Default\ Bib\ Flags<Tab>g:defaultbibflags	:let g:defaultbibflags="
"
nmenu 550.78 &LaTeX.&Toggle\ Space\ [off]				:ToggleSpace<CR>
if g:atp_math_opened
    nmenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [on]<Tab>g:atp_math_opened			:ToggleCheckMathOpened<CR>
else
    nmenu 550.79 &LaTeX.&Toggle\ &Check\ if\ in\ Math\ [off]<Tab>g:atp_math_opened			:ToggleCheckMathOpened<CR>
endif
tmenu &LaTeX.&Toggle\ Space\ [off] cmap <space> \_s\+ is curently off
" ToDo: add menu for printing.
endif
