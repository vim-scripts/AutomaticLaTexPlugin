" Author: Marcin Szamotulski

" This script has functions which have to be called before ATP_files/options.vim 
let s:did_common 	= exists("s:did_common") ? 1 : 0

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
" if a:0 >0 0 then b:atp_atp_OutDir is set iff it doesn't exsits.
function! s:SetOutDir(arg, ...)


    if exists("b:atp_OutDir") && a:0 >= 1
	return "atp_OutDir EXISTS"
    endif

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
" 		  echomsg "Output Directory ".b:atp_OutDir

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
call s:SetOutDir(0, 1)
command! -buffer SetOutDir	:call <SID>SetOutDir(1)
" }}}

" Make a tree of input files.
" {{{1 TreeOfFiles
" this is needed to make backward searching.
" It returns:
" 	[ {tree}, {list} , {type_dict}, {level_dict} ]
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
" It skips input files with extension other than '.tex' or '' (for example '.fd').
if &filetype == 'plaintex'
    let g:atp_inputfile_pattern = '^[^%]*\\input\s*'
else
    let g:atp_inputfile_pattern = '^[^%]*\\\(input\s*{\=\|include\s*{\|bibliography\s*{\)'
endif

" TreeOfFiles({main_file}, [{pattern}, {flat}, {run_nr}])
let g:ToF_debug = 0
" debug file - /tmp/tof_log
function! TreeOfFiles(main_file,...)
" let time	= reltime()


    if !exists("b:atp_OutDir")
	call s:SetOutDir(0, 1)
    endif

    let tree		= {}

    let pattern		= a:0 >= 1 	? a:1 : g:atp_inputfile_pattern
    " flat = do a flat search, i.e. fo not search in input files at all.
    let flat		= a:0 >= 2	? a:2 : 0	

    " This prevents from long runs on package files
    " for example babel.sty has lots of input files.
    if expand("%:e") != 'tex'
	redir END
	return [ {}, [], {}, {} ]
    endif
    let run_nr		= a:0 >= 3	? a:3 : 1 

	if g:ToF_debug
	    if run_nr == 1
		redir! > /tmp/tof_log
	    else
		redir! >> /tmp/tof_log
	    endif
	endif

	if g:ToF_debug
	    silent echo run_nr . ") |".a:main_file."| expand=".expand("%:p") 
	endif

    let line_nr		= 1
    let ifiles		= []
    let list		= []
    let type_dict	= {}
    let level_dict	= {}

    let saved_llist	= getloclist(0)
    if run_nr == 1 && &l:filetype =~ '^\(ams\)\=tex$'
	try
	    silent execute 'lvimgrep /\\begin\s*{\s*document\s*}/j ' . fnameescape(a:main_file)
	catch /E480: No match:/
	endtry
	let end_preamb	= get(get(getloclist(0), 0, {}), 'lnum', 0)
    else
	let end_preamb	= 0
    endif

    try
	silent execute "lvimgrep /".pattern."/jg " . fnameescape(a:main_file)
    catch /E480: No match:/
    endtry
    let loclist	= getloclist(0)
    call setloclist(0, saved_llist)
    let lines	= map(loclist, "[ v:val['text'], v:val['lnum'], v:val['col'] ]")

    	if g:ToF_debug
	    silent echo run_nr . ") Lines: " .string(lines)
	endif

    for entry in lines

	    let [ line, lnum, cnum ] = entry
	    " input name (iname) as appeared in the source file
	    let iname	= substitute(matchstr(line, pattern . '\zs\f*\ze'), '\s*$', '', '') 
	    if g:ToF_debug
		silent echo run_nr . ") iname=".iname
	    endif
	    if line =~ '{\s*' . iname
		let iname	= substitute(iname, '\\\@<!}\s*$', '', '')
	    endif

	    let iext	= fnamemodify(iname, ":e")
	    if g:ToF_debug
		silent echo run_nr . ") iext=" . iext
	    endif

	    if iext == "ldf"  || 
			\( &filetype == "plaintex" && getbufvar(b:atp_MainFile, "&filetype") != "tex") 
			\ && expand("%:p") =~ 'texmf'
		" if the extension is ldf (babel.sty) or the file type is plaintex
		" and the filetype of main file is not tex (it can be empty when the
		" buffer is not loaded) then match the full path of the file: if
		" matches then doesn't go below this file. 
		if g:ToF_debug
		    silent echo run_nr . ") CONTINUE"
		endif
		continue
	    endif

	    " type: preambule,bib,input.
	    if lnum < end_preamb && run_nr == 1
		let type	= "preambule"
	    elseif strpart(line, cnum-1)  =~ '^\\bibliography'
		let type	= "bib"
	    else
		let type	= "input"
	    endif

	    if g:ToF_debug
		silent echo run_nr . ") type=" . type
	    endif

	    let inames	= []
	    if type != "bib"
		let inames		= [ atplib#append_ext(iname, '.tex') ]
	    else
		let inames		= map(split(iname, ','), "atplib#append_ext(v:val, '.bib')")
	    endif

	    if g:ToF_debug
		silent echo run_nr . ") inames " . string(inames)
	    endif

	    " Find the full path only if it is not already given. 
	    for iname in inames
		if iname != fnamemodify(iname, ":p")
		    if type != "bib"
			let iname	= atplib#KpsewhichFindFile('tex', iname, b:atp_OutDir . "," . g:atp_texinputs , 1, ':p', '^\%(\/home\|\.\)', '\(^\/usr\|texlive\|kpsewhich\|generic\|miktex\)')
		    else
			let iname	= atplib#KpsewhichFindFile('bib', iname, b:atp_OutDir . "," . g:atp_bibinputs , 1, ':p')
		    endif
		endif

		call add(ifiles, [ iname, lnum] )
		call add(list, iname)
		call extend(type_dict, { iname : type } )
		call extend(level_dict, { iname : run_nr } )
	    endfor
    endfor

	    if g:ToF_debug
		silent echo run_nr . ") list=".string(list)
	    endif

    " Be recursive if: flat is off, file is of input type.
    if !flat || flat <= -1
    for [ifile, line] in ifiles	
	if type_dict[ifile] == "input" && flat <= 0 || ( type_dict[ifile] == "preambule" && flat <= -1 )
	     let [ ntree, nlist, ntype_dict, nlevel_dict ] = TreeOfFiles(ifile, pattern, flat, run_nr+1)

" 		    if g:ToF_debug
" 			silent echo run_nr . ") nlist=".string(nlist)
" 		    endif

	     call extend(tree, 		{ ifile : [ ntree, line ] } )
	     call extend(list, nlist, index(list, ifile)+1)  
	     call extend(type_dict, 	ntype_dict)
	     call extend(level_dict, 	nlevel_dict)
	endif
    endfor
    else
	" Make the flat tree
	for [ ifile, line ]  in ifiles
	    call extend(tree, { ifile : [ {}, line ] })
	endfor
    endif

"	Showing time takes ~ 0.013sec.
"     if run_nr == 1
" 	echomsg "TIME:" . join(reltime(time), ".") . " main_file:" . a:main_file
"     endif
    let [ b:TreeOfFiles, b:ListOfFiles, b:TypeDict, b:LevelDict ] = deepcopy([ tree, list, type_dict, level_dict])
    redir END
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
" a:MainFile	- main file (b:atp_MainFile)
" a:1 = 0 [1]	- use cached values of tree of files.
function! FindInputFiles(MainFile,...)

    let cached_Tree	= a:0 >= 1 ? a:1 : 0

    let saved_llist	= getloclist(0)
    call setloclist(0, [])

    if cached_Tree && exists("b:TreeOfFiles")
	let [ TreeOfFiles, ListOfFiles, DictOfFiles, LevelDict ]= deepcopy([ b:TreeOfFiles, b:ListOfFiles, b:TypeDict, b:LevelDict ]) 
    else
	
	if &filetype == "plaintex"
	    let flat = 1
	else
	    let flat = 0
	endif

	let [ TreeOfFiles, ListOfFiles, DictOfFiles, LevelDict ]= TreeOfFiles(fnamemodify(a:MainFile, ":p"), g:atp_inputfile_pattern, flat)
	" Update the cached values:
	let [ b:TreeOfFiles, b:ListOfFiles, b:TypeDict, b:LevelDict ] = deepcopy([ TreeOfFiles, ListOfFiles, DictOfFiles, LevelDict ])
    endif

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
	    \ { fnamemodify(File,":t:r") : [ DictOfFiles[File] , fnamemodify(a:MainFile, ":p"), File ] })
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
function! s:StatusOutDir() "{{{
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

function! ATPRunning() "{{{
    if exists("b:atp_running") && exists("g:atp_callback") && b:atp_running && g:atp_callback
" 	let b:atp_running	= b:atp_running < 0 ? 0 : b:atp_running
" 	redrawstatus

	for cmd in keys(g:CompilerMsg_Dict) 
	    if b:atp_TexCompiler =~ '^\s*' . cmd . '\s*$'
		let Compiler = g:CompilerMsg_Dict[cmd]
		break
	    else
		let Compiler = b:atp_TexCompiler
	    endif
	endfor

	if b:atp_running >= 2
	    return b:atp_running." ".Compiler." "
	elseif b:atp_running >= 1
	    return Compiler." "
	else
	    return ""
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

function! s:SetNotificationColor() "{{{
    " use the value of the variable g:atp_notification_{g:colors_name}_guibg
    " if it doesn't exists use the default value (the same as the value of StatusLine
    " (it handles also the reverse option!)
    let colors_name = exists("g:colors_name") ? g:colors_name : "default"
"     let g:cname	= colors_name
" 	Note: the names of variable uses gui but equally well it could be cterm. As
" 	they work in gui and vim. 
    if has("gui_running")
	let notification_guibg = exists("g:atp_notification_".colors_name."_guibg") ?
		    \ g:atp_notification_{colors_name}_guibg :
		    \ ( synIDattr(synIDtrans(hlID("StatusLine")), "reverse") ?
			\ synIDattr(synIDtrans(hlID("StatusLine")), "fg#") :
			\ synIDattr(synIDtrans(hlID("StatusLine")), "bg#") )
	let notification_guifg = exists("g:atp_notification_".colors_name."_guifg") ?
		    \ g:atp_notification_{colors_name}_guifg :
		    \ ( synIDattr(synIDtrans(hlID("StatusLine")), "reverse") ?
			\ synIDattr(synIDtrans(hlID("StatusLine")), "bg#") :
			\ synIDattr(synIDtrans(hlID("StatusLine")), "fg#") )
	let notification_gui = exists("g:atp_notification_".colors_name."_gui") ?
		    \ g:atp_notification_{colors_name}_gui :
		    \ ( (synIDattr(synIDtrans(hlID("StatusLine")), "bold") ? "bold" : "" ) . 
			\ (synIDattr(synIDtrans(hlID("StatusLine")), "underline") ? ",underline" : "" ) .
			\ (synIDattr(synIDtrans(hlID("StatusLine")), "underculr") ? ",undercurl" : "" ) .
			\ (synIDattr(synIDtrans(hlID("StatusLine")), "italic") ? ",italic" : "" ) )
    else
	let notification_guibg = exists("g:atp_notification_".colors_name."_ctermbg") ?
		    \ g:atp_notification_{colors_name}_ctermbg :
		    \ ( synIDattr(synIDtrans(hlID("StatusLine")), "reverse") ?
			\ synIDattr(synIDtrans(hlID("StatusLine")), "fg#") :
			\ synIDattr(synIDtrans(hlID("StatusLine")), "bg#") )
	let notification_guifg = exists("g:atp_notification_".colors_name."_ctermfg") ?
		    \ g:atp_notification_{colors_name}_ctermfg :
		    \ ( synIDattr(synIDtrans(hlID("StatusLine")), "reverse") ?
			\ synIDattr(synIDtrans(hlID("StatusLine")), "bg#") :
			\ synIDattr(synIDtrans(hlID("StatusLine")), "fg#") )
	let notification_gui = exists("g:atp_notification_".colors_name."_cterm") ?
		    \ g:atp_notification_{colors_name}_cterm :
		    \ ( (synIDattr(synIDtrans(hlID("StatusLine")), "bold") ? "bold" : "" ) . 
			\ (synIDattr(synIDtrans(hlID("StatusLine")), "underline") ? ",underline" : "" ) .
			\ (synIDattr(synIDtrans(hlID("StatusLine")), "underculr") ? ",undercurl" : "" ) .
			\ (synIDattr(synIDtrans(hlID("StatusLine")), "italic") ? ",italic" : "" ) )
    endif

    if has("gui_running")
	let g:notification_gui		= notification_gui
	let g:notification_guibg	= notification_guibg
	let g:notification_guifg	= notification_guifg
    else
	let g:notification_cterm	= notification_gui
	let g:notification_ctermbg	= notification_guibg
	let g:notification_ctermfg	= notification_guifg
    endif
    if has("gui_running")
	let prefix = "gui"
    else
	let prefix = "cterm"
    endif
    let hi_gui	 = ( notification_gui   !=  "" && notification_gui   	!= -1 ? " ".prefix."="   . notification_gui   : "" )
    let hi_guifg = ( notification_guifg !=  "" && notification_guifg 	!= -1 ? " ".prefix."fg=" . notification_guifg : "" )
    let hi_guibg = ( notification_guibg !=  "" && notification_guibg 	!= -1 ? " ".prefix."bg=" . notification_guibg : "" )

    if (notification_gui == -1 || notification_guifg == -1 || notification_guibg == -1)
	return
    endif
    " Highlight command:
    try
    execute "hi User".g:atp_statusNotifHi ." ". hi_gui . hi_guifg . hi_guibg
    catch /E418: Illegal value:/
    endtry

endfunction

" This should set the variables and run s:SetNotificationColor function
command! -buffer SetNotificationColor :call s:SetNotificationColor()

"}}}

augroup ATP_SetStatusLineNotificationColor
    au BufEnter 	*tex 	:call s:SetNotificationColor()
    au ColorScheme 	* 	:call s:SetNotificationColor()
augroup END

" The main status function, it is called via autocommand defined in 'options.vim'.
let s:errormsg = 0
function! ATPStatus(bang) "{{{
    let g:status_OutDir	= a:bang == "" && g:atp_statusOutDir || a:bang == "!" && !g:atp_statusOutDir ? s:StatusOutDir() : ""
    let status_CTOC	= &filetype =~ '^\(ams\)\=tex' ? CTOC("return") : ''
    if g:atp_statusNotifHi > 9 || g:atp_statusNotifHi < 0
	let g:atp_statusNotifHi = 9
	if !s:errormsg
	    echoerr "Wrong value of g:atp_statusNotifHi, should be 0,1,...,9. Setting it to 9."
	    let s:errormsg = 1
	endif
    endif
    let status_NotifHi	= g:atp_statusNotif && g:atp_statusNotifHi ? '%#User'.g:atp_statusNotifHi . '#' : ''
    let status_NotifHiPost	
		\ = g:atp_statusNotif && g:atp_statusNotifHi ? '%#StatusLine#' : ''
    let status_Notif	= g:atp_statusNotif ? '%{ATPRunning()}' : ''

    let g:atp_StatusLine= '%<%f %(%h%m%r%) %='.status_CTOC." ".status_NotifHi.status_Notif.status_NotifHiPost. 
		\ '%{g:status_OutDir} %-14.16(%l,%c%V%)%P'
    set statusline=%!g:atp_StatusLine
endfunction
    try
	command -buffer -bang Status		:call ATPStatus(<q-bang>) 
    catch /E174: Command already exists/
	command! -buffer -bang ATPStatus	:call ATPStatus(<q-bang>) 
    endtry
" }}}
"}}}

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
