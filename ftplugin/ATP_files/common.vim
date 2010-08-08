" Author: Marcin Szamotulski

" {{{1 Variables
if !exists("g:askfortheoutdir")
    let g:askfortheoutdir=0
endif
if !exists("g:atp_raw_texinputs")
    let g:atp_raw_texinputs = substitute(substitute(substitute(system("kpsewhich -show-path tex"),'!!','','g'),'\/\/\+','\/','g'), ':\|\n', ',', 'g')
"     lockvar g:atp_raw_texinputs
endif

" atp tex and bib inputs directories (kpsewhich)
if !exists("g:atp_texinputs")
    let path_list	= split(g:atp_raw_texinputs, ',')
    let idx		= index(path_list, '.')
    if idx != -1
	let dot = remove(path_list, index(path_list,'.')) . ","
    else
	let dot = ""
    endif
    call map(path_list, 'v:val . "**"')

    let g:atp_texinputs	= dot . join(path_list, ',')
endif
" a list where tex looks for bib files
" It must be defined before SetProjectName function.
if !exists("g:atp_raw_bibinputs")
    let g:atp_raw_bibinputs=substitute(substitute(substitute(
		\ system("kpsewhich -show-path bib"),
		\ '\/\/\+',	'\/',	'g'),	
		\ '!\|\n',	'',	'g'),
		\ ':',		',' ,	'g')
endif
if !exists("g:atp_bibinputs")
    let path_list	= split(g:atp_raw_bibinputs, ',')
    let idx		= index(path_list, '.')
    if idx != -1
	let dot = remove(path_list, index(path_list,'.')) . ","
    else
	let dot = ""
    endif
    call map(path_list, 'v:val . "**"')

    let g:atp_bibinputs	= dot . join(path_list, ',')
endif
" }}}1

" This file contains set of functions which are needed to set to set the atp
" options and some common tools.

" This functions sets the value of b:atp_OutDir variable
" {{{ s:SetOutDir
" This options are set also when editing .cls files.
" It can overwrite the value of b:atp_OutDir
" if arg != 0 then set errorfile option accordingly to b:atp_OutDir
function! s:SetOutDir(arg)
    " first we have to check if this is not a project file
    if exists("g:atp_project") || exists("s:inputfiles") && 
		\ ( index(keys(s:inputfiles),fnamemodify(bufname("%"),":t:r")) != '-1' || 
		\ index(keys(s:inputfiles),fnamemodify(bufname("%"),":t")) != '-1' )
	    " if we are in a project input/include file take the correct value of b:atp_OutDir from the atplib#s:outdir_dict dictionary.
	    
	    if index(keys(s:inputfiles),fnamemodify(bufname("%"),":t:r")) != '-1'
		let b:atp_OutDir=substitute(g:outdir_dict[s:inputfiles[fnamemodify(bufname("%"),":t:r")][1]], '\\\s', ' ', 'g')
	    elseif index(keys(s:inputfiles),fnamemodify(bufname("%"),":t")) != '-1'
		let b:atp_OutDir=substitute(g:outdir_dict[s:inputfiles[fnamemodify(bufname("%"),":t")][1]], '\\\s', ' ', 'g')
	    endif
    else
	
	    " if we are not in a project input/include file set the b:atp_OutDir
	    " variable	

	    " if the user want to be asked for b:atp_OutDir
	    if g:askfortheoutdir == 1 
		let b:atp_OutDir=substitute(input("Where to put output? do not escape white spaces "), '\\\s', ' ', 'g')
	    endif

	    if ( get(getbufvar(bufname("%"),""),"outdir","optionnotset") == "optionnotset" 
			\ && g:askfortheoutdir != 1 
			\ || b:atp_OutDir == "" && g:askfortheoutdir == 1 )
			\ && !exists("$TEXMFOUTPUT")
		 let b:atp_OutDir=substitute(fnamemodify(resolve(expand("%:p")),":h") . "/", '\\\s', ' ', 'g')
		 echoh WarningMsg | echomsg "Output Directory "b:atp_OutDir | echoh None

	    elseif exists("$TEXMFOUTPUT")
		 let b:atp_OutDir=substitute($TEXMFOUTPUT, '\\\s', ' ', 'g') 
	    endif	

	    " if arg != 0 then set errorfile option accordingly to b:atp_OutDir
	    if bufname("") =~ ".tex$" && a:arg != 0
		 call s:SetErrorFile()
	    endif

	    if exists("g:outdir_dict")
		let g:outdir_dict	= extend(g:outdir_dict, {fnamemodify(bufname("%"),":p") : b:atp_OutDir })
	    else
		let g:outdir_dict	= { fnamemodify(bufname("%"),":p") : b:atp_OutDir }
	    endif
    endif
    return b:atp_OutDir
endfunction
call s:SetOutDir(0)
command! -buffer SetOutDir	:call <SID>SetOutDir(1)
" }}}

" Make a tree of input files.
" {{{1 TreeOfFiles
" this is needed to make backward searching.
" It returns:
" 	[ {tree}, {list} , {type_dict} ]
" 	where {tree}:
" 		is a tree of files of the form
" 			{ file : [ subtree, linenr ] }
"		where the linenr is the linenr of \input{file} iline the one level up
"		file.
"	{list}:
"		is just list of all found input files.
"	{type_dict}: 
"		is a dictionary of types for files in {list}
"		type is one of: preambule, input, bib. 
"
" {flat} =  1 	do not be recursive
" {flat} =  0	the deflaut be recursive for input files (not bib and not preambule) 
" 		bib and preambule files are not added to the tree	
" {flat} = -1 	include input and premabule files into the tree
" 		

" Should match till the begining of the file name and not use \zs:\ze patterns.
let g:atp_inputfile_pattern = '\\\(input\s*{\=\|include\s*{\|bibliography\s*{\)'

" TreeOfFiles({main_file}, [{pattern}, {flat}, {run_nr}])
function! TreeOfFiles(main_file,...)
"     let time	= reltime()

    if !exists("b:atp_OutDir")
	call s:SetOutDir(0)
    endif

    let tree		= {}
    let main_file	= readfile(a:main_file)
    let pattern		= a:0 >= 1 	? a:1 : g:atp_inputfile_pattern
    " flat = do a flat search, i.e. fo not search in input files at all.
    let flat		= a:0 >= 2	? a:2 : 0	
    let run_nr		= a:0 >= 3	? a:3 : 1 
"     let saved_view	= a:0 >= 4	? a:4 : winsaveview()
"     let bufnr		= a:0 >= 5	? a:5 : bufnr("%")	

    let line_nr		= 1
    let ifiles		= []
    let list		= []
    let type_dict	= {}
    let level_dict	= {}

    let saved_llist	= getloclist(0)
    if run_nr == 1 && &l:filetype == "tex"
	try
	    silent execute 'lvimgrep /\\begin\s*{\s*document\s*}/j ' . a:main_file
	catch /E480: No match:/
	endtry
	let end_preamb	= get(get(getloclist(0), 0, {}), 'lnum', 0)
    else
	let end_preamb	= 0
    endif

    try
	silent execute "lvimgrep /".pattern."/jg " . a:main_file
    catch /E480: No match:/
    endtry
    let loclist	= getloclist(0)
    call setloclist(0, saved_llist)
    let lines	= map(loclist, "[ v:val['text'], v:val['lnum'], v:val['col'] ]")

    for entry in lines

	    let line = entry[0]
	    let lnum = entry[1]
	    let cnum = entry[2]
	    " input name (iname) as appears in the source file
	    let iname	= substitute(matchstr(line, pattern . '\zs\f*\ze'), '\s*$', '', '') 
	    if line =~ '{\s*' . iname
		let iname	= substitute(iname, '\\\@<!}\s*$', '', '')
	    endif

	    " type: preambule,bib,input.
	    if lnum < end_preamb && run_nr == 1
		let type	= "preambule"
	    elseif strpart(line, cnum-1)  =~ '^\\bibliography'
		let type	= "bib"
	    else
		let type	= "input"
	    endif

" 	    echomsg iname . " " . type

	    if type != "bib"
		let iname		= atplib#append(iname, '.tex')
	    else
		let iname		= atplib#append(iname, '.bib')
	    endif

	    " Find the full path only if it is not already given. 
	    if iname != fnamemodify(iname, ":p")
		if type != "bib"
		    let iname	= atplib#KpsewhichFindFile('tex', iname, g:atp_texinputs . "," . b:atp_OutDir, 1, ':p', '^\%(\/home\|\.\)', '\(texlive\|kpsewhich\|generic\)')
		else
		    let iname	= atplib#KpsewhichFindFile('bib', iname, g:atp_bibinputs . "," . b:atp_OutDir, 1, ':p')
		endif
	    endif

	    call add(ifiles, [ iname, lnum] )
	    call add(list, iname)
	    call extend(type_dict, { iname : type } )
	    call extend(level_dict, { iname : run_nr } )
    endfor

    " Be recursive if: flat is off, file is of input type.
    if !flat || flat == -1
    for [ifile, line] in ifiles	
	if type_dict[ifile] == "input" && flat <= 0 || ( type_dict[ifile] == "preambule" && flat == -1 )
	     let [ ntree, nlist, ntype_dict, nlevel_dict ] = TreeOfFiles(ifile, pattern, flat, run_nr+1)
	     call extend(tree, 		{ ifile : [ ntree, line ] } )
	     call extend(list, nlist, index(list, ifile)+1)  
	     call extend(type_dict, 	ntype_dict)
	     call extend(level_dict, 	nlevel_dict)
	endif
    endfor
    endif

"     echomsg "TIME:" . join(reltime(time), ".") . " main_file:" . a:main_file
" echo "TREE=". string(tree)
" echo "LIST" . string(list)
    return [ tree, list, type_dict, level_dict ]

endfunction
command! InputFiles		:echo "Found input files:\n" . join(TreeOfFiles(b:atp_MainFile)[1], "\n")
" let s:TreeOfFiles	= TreeOfFiles(b:atp_MainFile)
"}}}1

" This function finds all the input and bibliography files declared in the source files (recursive).
" {{{ FindInputFiles 
" Returns a dictionary:
" { <input_name> : [ 'bib', 'main file', 'full path' ] }
"			 with the same format as the output of FindInputFiles
function! FindInputFiles(MainFile)

    let saved_llist	= getloclist(0)
    call setloclist(0, [])
    let [ TreeOfFiles, ListOfFiles, DictOfFiles, LevelDict ]	= TreeOfFiles(a:MainFile)
    let AllInputFiles	= keys(filter(copy(DictOfFiles), " v:val == 'input' || v:val == 'preambule' "))
    let AllBibFiles	= keys(filter(copy(DictOfFiles), " v:val == 'bib' "))

    let b:AllInputFiles		= deepcopy(AllInputFiles)
    let b:AllBibFiles		= deepcopy(AllBibFiles)

    " this variable will store unreadable bibfiles:    
    let NotReadableInputFiles=[]

    " this variable will store the final result:   
    let Files		= {}

    for File in ListOfFiles
	if filereadable(File) 
	call extend(Files, 
	    \ { fnamemodify(File,":t:r") : [ DictOfFiles[File] , a:MainFile, File ] })
	else
	" echo warning if a bibfile is not readable
	    echohl WarningMsg | echomsg "File " . File . " not found." | echohl None
	    if count(NotReadableInputFiles, File) == 0 
		call add(NotReadableInputFiles, File)
	    endif
	endif
    endfor
    let g:NotReadableInputFiles	= NotReadableInputFiles

    " return the list  of readable bibfiles
    return Files
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
