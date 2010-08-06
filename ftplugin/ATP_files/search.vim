" Author:	Marcin Szamotulski
" Note:		This file is a part of ATP plugin for vim.



" Make a dictionary of definitions found in all input files.
" {{{ s:make_defi_dict
" Comparing with ]D, ]d, ]i, ]I vim maps this function deals with multiline
" definitions.
"
" The output dictionary is of the form: 
" 	{ input_file : [ [begin_line, end_line], ... ] }
" a:1 	= buffer name to search in for input files
" a:2	= 1 	skip searching for the end_line
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

    let l:inputfiles=FindInputFiles(l:bufname, "0")
    let l:input_files=[]
    let b:input_files=l:input_files

    for l:inputfile in keys(l:inputfiles)
	if l:inputfiles[l:inputfile][0] != "bib"
	    let l:input_file=atplib#append(l:inputfile,'.tex')
	    if filereadable(atplib#append(b:atp_OutDir,'/') . l:input_file)
		let l:input_file=atplib#append(b:atp_OutDir,'/') . l:input_file
	    else
		let l:input_file=findfile(l:inputfile,g:texmf . '**')
	    endif
	    call add(l:input_files, l:input_file)
	endif
    endfor


    let l:input_files=filter(l:input_files, 'v:val != ""')
    if !count(l:input_files,b:atp_MainFile)
	call extend(l:input_files,[ b:atp_MainFile ])
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
    endfor
    endif

    return l:defi_dict
endfunction
"}}}

" Find all names of locally defined commands, colors and environments. 
" Used by the completion function.
"{{{ LocalCommands 
function! LocalCommands(...)

    if a:0 == 0
	let l:pattern='\\def\>\|\\newcommand\>\|\\newenvironment\|\\newtheorem\|\\definecolor'
    else
	let l:pattern=a:1
    endif
    echo "Makeing lists of commands and environments found in input files ... "
" 	    call SetProjectName()
    let l:CommandNames=[]
    let l:EnvironmentNames=[]
    let l:ColorNames=[]

    " ToDo: I need a simpler function here !!!
    " 		we are just looking for definition names not for
    " 		definition itself (this takes time).
    let l:ddict=s:make_defi_dict(b:atp_MainFile,l:pattern,1,1)
" 	    echomsg " LocalCommands DEBUG " . b:atp_MainFile
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
" 				echo l:name . " count: " . (!count(l:CommandNames, "\\".l:name)) . " pattern: " . (l:def !~ '^\s*\(\d\|\.\)*\s*\(mm\|cm\|pt\|in\|em\|ex\)\?$' || l:def == "") . " l:def " . l:def
			if !count(l:CommandNames, "\\".l:name) && (l:def !~ '^\s*\(\d\|\.\)*\s*\(mm\|cm\|pt\|in\|em\|ex\)\?$' || l:def == "")
			    call add(l:CommandNames, "\\".l:name)
			endif
" 				echomsg l:name
		    endif
		endif
		if l:ifile[l:range[0]-1] =~ '\\newenvironment\|\\newtheorem'
		    " check only definitions which starts at 0 column
		    let l:name=matchstr(l:ifile[l:range[0]-1],
				\ '^\\\%(newtheorem\*\?\|newenvironment\){\zs[^}]*\ze}')
		    if l:name != ""
			if !count(l:EnvironmentNames,l:name)
			    call add(l:EnvironmentNames,l:name)
			endif
		    endif
		endif
		if l:ifile[l:range[0]-1] =~ '\\definecolor'
		    let l:name=matchstr(l:ifile[l:range[0]-1],
				\ '^\s*\\definecolor\s*{\zs[^}]*\ze}')
		    if l:name != ""
			if !count(l:ColorNames,l:name)
			    call add(l:ColorNames,l:name)
			endif
		    endif
		endif
	    endfor
	endfor
    let s:atp_LocalCommands	= []
    let s:atp_LocalEnvironments	= []
    let s:atp_LocalColors	= l:ColorNames

    " remove double entries
    for l:type in ['Command', 'Environment']
" 		echomsg l:type
	for l:item in l:{l:type}Names
	    if index(g:atp_{l:type}s,l:item) == '-1'
		call add(s:atp_Local{l:type}s,l:item)
	    endif
	endfor
    endfor

    " Make shallow copies of the lists
    let b:atp_LocalCommands=s:atp_LocalCommands
    let b:atp_LocalEnvironments=s:atp_LocalEnvironments
    let b:atp_LocalColors=s:atp_LocalColors
    return [ s:atp_LocalEnvironments, s:atp_LocalCommands, s:atp_LocalColors ]
endfunction
command! -buffer LocalCommands		:call LocalCommands()
"}}}

" Search for Definition in the definition dictionary (s:make_defi_dict).
"{{{ DefiSearch
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

    let l:ddict	= s:make_defi_dict(bufname("%"),'\\def\|\\newcommand',l:preambule_only)
"     let b:dd=l:ddict

    " open new buffer
    let l:openbuffer=" +setl\\ buftype=nofile\\ nospell\\ syntax=tex " . fnameescape("DefiSearch")
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
	    echohl ErrorMsg
	    echomsg "Definition not found."
	    echohl Normal
	endif
    else
	echohl ErrorMsg
	echomsg "Definition not found."
	echohl Normal
    endif
endfunction
command! -buffer -nargs=* DefiSearch		:call DefiSearch(<f-args>)
"}}}

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

" Should match till the begining of the file name and not use \zs:\ze patterns.
let g:atp_inputfile_pattern = '\\\(input\s*{\=\|include\s*{\|bibliography\s*{\)'

" TreeOfFiles({main_file}, [{pattern}, {flat}, {run_nr}])
function! TreeOfFiles(main_file,...)
"     let time	= reltime()

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
    let g:end_preamb	= end_preamb
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

	    echomsg iname . " " . type

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
    endfor

    " Be recursive if: flat is off, file is of input type.
    if !flat
    for [ifile, line] in ifiles	
	if type_dict[ifile] == "input"
	     let [ ntree, nlist, ntype_dict ] = TreeOfFiles(ifile, pattern, flat, run_nr+1)
	     call extend(tree, { ifile : [ ntree, line ] } )
	     call extend(list, nlist)  
	     call extend(type_dict, ntype_dict)
	endif
    endfor
    endif

"     echomsg "TIME:" . join(reltime(time), ".") . " main_file:" . a:main_file
" echo "TREE=". string(tree)
" echo "LIST" . string(list)
    return [ tree, list, type_dict ]

endfunction
" let s:TreeOfFiles	= TreeOfFiles(b:atp_MainFile)
"}}}1

" Search in tree and return the one level up element and its line number.
" {{{1 SearchInTree
" Before running this function one has to set the two variables
" s:branch/s:branch_line to 0.
" the a:tree variable should be something like:
" a:tree = { b:atp_MainFile, [ TreeOfFiles(b:atp_MainFile)[0], 0 ] }
" necessary a rooted tree!
function! SearchInTree(tree, branch, what)
    let branch	= a:tree[a:branch][0]
    if count(keys(branch), a:what)
	let g:ATP_branch		= a:branch
	let g:ATP_branch_line	= a:tree[a:branch][0][a:what][1]
	return a:branch
    else
	for new_branch in keys(branch)
	    call SearchInTree(branch, new_branch, a:what)
	endfor
    endif
    return "X"
endfunction
" }}}1

" Search in all input files recursively.
" {{{1 Search (recursive)
"
" Variables are used to pass them to next runs (this function calls it self) 
" a:main_file	= b:atp_MainFile
" a:start_file	= expand("%:p") 	/this variable will not change untill the
" 						last instance/ 
" a:tree	= make_tree 		=> make a tree
" 		= any other value	=> use s:TreeOfFiles	
" a:cur_branch	= expand("%") 		/this will change whenever we change a file/
" a:call_nr	= number of the call			
" a:wrap_nr	= if hit top/bottom a:call=0 but a:wrap_nr+=1
" a:winsaveview = winsaveview(0)  	to resotre the view if the pattern was not found
" a:bufnr	= bufnr("%")		to come back to begining buffer if pattern not found
" a:strftime	= strftime(0)		to compute the time
" a:pattern	= 			pattern to search
" a:1		=			flags: 'bcewWs'
" 								
let s:ATP_rs_debug=0	" if 1 sets debugging messages which are appended to '/tmp/ATP_rs_debug' 
			" you can :set errorfile=/tmp/ATP_rs_debug
			" and	  :set efm=.*
			" if 2 show time
try
function! s:RecursiveSearch(main_file, start_file, tree, cur_branch, call_nr, wrap_nr, winsaveview, bufnr, strftime, vim_options, pattern, ... )

    let time0	= reltime()

    " set and restore some options:
    " foldenable	(unset to prevent opening the folds :h winsaveview)
    " comeback to the starting buffer
    if a:call_nr == 1 && a:wrap_nr == 1
	if a:vim_options	== { 'no_options' : 'no_options' }
	    let options 	=  { 'hidden'	: &l:hidden, 
				\ 'foldenable' 	: &l:foldenable }
	endif
	let &l:hidden		= 1
	let &l:foldenable	= 0
    endif
    	
	    " Redirect debuggin messages:
	    if s:ATP_rs_debug
		if a:wrap_nr == 1 && a:call_nr == 1
		    redir! > /tmp/ATP_rs_debug
		else
		    redir! >> /tmp/ATP_rs_debug 
		endif
		silent echo "________________"
		silent echo "Args: a:pattern:".a:pattern." call_nr:".a:call_nr. " wrap_nr:".a:wrap_nr 
	    endif

    	let flags_supplied = a:0 == 1 ? a:1 : ""
	if flags_supplied =~# 'p'
	    let flags_supplied = substitute(flags_supplied, 'p', '', 'g')
	    echohl WarningMsg
	    echomsg "Searching flag 'p' is not supported, filtering it out."
	    echohl Normal
	endif

	if a:tree == 'make_tree'
	    let l:tree 	= { a:main_file : [ TreeOfFiles(a:main_file)[0], 0] }
	elseif exists("s:TreeOfFiles")
	    let l:tree	= s:TreeOfFiles
	else
	    let ttime	= reltime()
	    let s:TreeOfFiles 	= { a:main_file : [ TreeOfFiles(a:main_file)[0], 0] }
	    let l:tree		= s:TreeOfFiles
		if s:ATP_rs_debug > 1
		    silent echo "tTIME:" . reltimestr(reltime(ttime))
		endif
	endif

	if a:cur_branch != "no cur_branch "
	    let cur_branch	= a:cur_branch
	else
	    let cur_branch	= a:main_file
	endif

		if s:ATP_rs_debug > 1
		    silent echo "TIME0:" . reltimestr(reltime(time0))
		endif

" 	if flags_supplied =~# 'E' && a:call_nr == 1 && a:wrap_nr == 1
" 	    let pattern		= escape(a:pattern, '\')
" 	else
" 	    let pattern = a:pattern
" 	    let flags_supplied	= substitute(flags_supplied, 'E', '', 'g')
" 	endif
	let pattern		= a:pattern
	let flags_supplied	= substitute(flags_supplied, '[^bcenswWS]', '', 'g')

    	" Add pattern to the search history
	if a:call_nr == 1
	    call histadd("search", a:pattern)
	    let @/	= pattern
	endif

	" Set up searching flags
	let flag	= flags_supplied
	if a:call_nr > 1 
	    let flag	= flags_supplied !~# 'c' ? flags_supplied . 'c' : flags_supplied
	endif
	if expand("%:p") != fnamemodify(a:main_file, ":p")
	    let flag	= substitute(flag, 'w', '', 'g') . 'W'
	endif
	let flag	= flag !~# 'n' ? substitute(flag, 'n', '', 'g') . 'n' : flag
	let flag	= substitute(flag, 's', '', 'g')

	if flags_supplied !~# 'b'
	    " forward searching flag for input files:
	    let flag_i	= flags_supplied !~# 'c' ? flags_supplied . 'c' : flags_supplied
	else
	    let flag_i	= substitute(flags_supplied, 'c', '', 'g')
	endif
	let flag_i	= flag_i !~# 'n' ? flag_i . 'n' : flag_i
	let flag_i	= substitute(flag_i, 'w', '', 'g') . 'W'
	let flag_i	= substitute(flag_i, 's', '', 'g')

		if s:ATP_rs_debug
		silent echo "      flags_supplied:".flags_supplied." flag:".flag." flag_i:".flag_i." a:1=".(a:0 != 0 ? a:1 : "")
		endif

	" Find pattern and input file 
	let cur_pos		= [line("."), col(".")]
	" We filter out the 's' flag which should be used only once
	" as the flags passed to next s:RecursiveSearch()es are based on flags_supplied variable
	" this will work.
	let s_flag		= flags_supplied =~# 's' ? 1 : 0
	let flags_supplied	= substitute(flags_supplied, 's', '', 'g')
	if s_flag
	    call setpos("''", getpos("."))
	endif
	keepjumps let pat_pos	= searchpos(pattern, flag)

		if s:ATP_rs_debug > 1
		    silent echo "TIME1:" . reltimestr(reltime(time0))
		endif

	" Search for input pattern (we do not need to search further than pat_pos.
	if pat_pos == [0, 0]
	    let stop_line	= flag !~# 'b' ? line("$")  : 1
	else
	    let stop_line	= pat_pos[0]
	endif
	keepjumps let input_pos	= searchpos('\m\\input\s*{', flag_i . 'n', stop_line )
	let g:input		= input_pos

		if s:ATP_rs_debug > 1
		    silent echo "TIME2:" . reltimestr(reltime(time0))
		endif

		if s:ATP_rs_debug
		silent echo "Positions: ".string(cur_pos)." ".string(pat_pos)." ".string(input_pos)." in branch: ".cur_branch."#".expand("%:p") . " stop_line: " . stop_line 
		endif

	" Decide what to do: accept the pattern, go to higher branch, go to lower
	" branch or say Pattern not found
	if flags_supplied !~# 'b'
	    " FORWARD
	    " cur < pat <= input
	    if atplib#CompareCoordinates(cur_pos,pat_pos) && atplib#CompareCoordinates_leq(pat_pos, input_pos)
		let goto	= 'ACCEPT' . 1
	    " cur == pat <= input
	    elseif cur_pos == pat_pos && atplib#CompareCoordinates_leq(pat_pos, input_pos)
		" this means that the 'flag' variable has to contain 'c' or the
		" wrapscan is on
		" ACCEPT if 'c' and wrapscan is off or there is another match below,
		" if there is not go UP.
		let wrapscan	= ( flags_supplied =~# 'w' || &l:wrapscan && flags_supplied !~# 'W' )
		if flag =~# 'c'
		    let goto 	= 'ACCEPT'  . 2
		elseif wrapscan
		    " if in wrapscan and without 'c' flag
		    let goto	= 'UP' . 2
		else
		    " this should not happen: cur == put can hold only in two cases:
		    " wrapscan is on or 'c' is used.
		    let goto	= 'ERROR' . 2
		endif
	    " pat < cur <= input
	    elseif atplib#CompareCoordinates(pat_pos, cur_pos) && atplib#CompareCoordinates_leq(cur_pos, input_pos) 
		let goto	= 'UP' . 4
	    " cur < input < pat
	    elseif atplib#CompareCoordinates(cur_pos, input_pos) && atplib#CompareCoordinates(input_pos, pat_pos)
		let goto	= 'UP' . 41
	    " cur < input == pat 		/we are looking for '\\input'/
	    elseif atplib#CompareCoordinates(cur_pos, input_pos) && input_pos == pat_pos
		let goto	= 'ACCEPT'
	    " input < cur <= pat	(includes input = 0])
	    elseif atplib#CompareCoordinates(input_pos, cur_pos) && atplib#CompareCoordinates_leq(cur_pos, pat_pos)
		" cur == pat thus 'flag' contains 'c'.
		let goto	= 'ACCEPT'
	    " cur == input
	    elseif cur_pos == input_pos
		let goto = 'UP'
	    " input == 0 			/there is no 'input' ahead - flag_i contains 'W'/
	    " 					/but there is no 'pattern ahead as well/
	    " at this stage: pat < cur 	(if not then  input = 0 < cur <= pat was done above).
	    elseif input_pos == [0, 0]
		if expand("%:p") == fnamemodify(a:main_file, ":p")
		    " wrapscan
		    if ( flags_supplied =~# 'w' || &l:wrapscan  && flags_supplied !~# 'W' )
			let new_flags	= substitute(flags_supplied, 'w', '', 'g') . 'W'  
			if a:wrap_nr <= 2
			    call cursor(1,1)

				if s:ATP_rs_debug
				silent echo " END 1 new_flags:" . new_flags 
				redir END
				endif

			    keepjumps call s:RecursiveSearch(a:main_file, a:start_file, "", a:cur_branch, 1, a:wrap_nr+1, a:winsaveview, a:bufnr, a:strftime, a:vim_options, pattern, new_flags) 

			    " restore vim options 
			    if a:vim_options != { 'no_options' : 'no_options' }
				for option in keys(a:vim_options)
				    execute "let &l:".key."=".a:vim_options[key]
				endfor
			    endif

			    return
			else
			    let goto 	= "REJECT".1
" 			    echohl ErrorMsg
" 			    echomsg 'Pattern not found: ' . a:pattern
" 			    echohl None
			endif
		    else
			let goto 	= "REJECT".2
" 			echohl ErrorMsg
" 			echomsg 'Pattern not found: ' . a:pattern
" 			echohl None
		    endif
		" if we are not in the main file go up.
		else
		    let goto	= "DOWN"
		endif
	    else
		let goto = 'ERROR' . 13
	    endif
	else
	    " BACKWARD
	    " input <= pat < cur (pat != 0)
	    if atplib#CompareCoordinates(pat_pos, cur_pos) && atplib#CompareCoordinates_leq(input_pos, pat_pos) && pat_pos != [0, 0]
		" input < pat
		if input_pos != pat_pos
		    let goto	= 'ACCEPT' . 1 . 'b'
		" input == pat
		else
		    let goto	= 'UP' . 1 . 'b'
		endif
	    " input <= pat == cur (input != 0)			/pat == cur => pat != 0/
	    elseif cur_pos == pat_pos && atplib#CompareCoordinates_leq(input_pos, pat_pos) && input_pos != [0, 0]
		" this means that the 'flag' variable has to contain 'c' or the
		" wrapscan is on
		let wrapscan	= ( flags_supplied =~# 'w' || &l:wrapscan  && flags_supplied !~# 'W' )
		if flag =~# 'c'
		    let goto 	= 'ACCEPT'  . 2 . 'b'
		elseif wrapscan
		    " if in wrapscan and without 'c' flag
		    let goto	= 'UP' . 2 . 'b'
		else
		    " this should not happen: cur == put can hold only in two cases:
		    " wrapscan is on or 'c' is used.
		    let goto	= 'ERROR' . 2 . 'b'
		endif
	    " input <= cur < pat (input != 0)
	    elseif atplib#CompareCoordinates(cur_pos, pat_pos) && atplib#CompareCoordinates_leq(input_pos, cur_pos) && input_pos != [0, 0] 
		let goto	= 'UP' . 4 .'b'
	    " pat < input <= cur (input != 0)
	    elseif atplib#CompareCoordinates_leq(input_pos, cur_pos) && atplib#CompareCoordinates(pat_pos, input_pos) && input_pos != [0, 0]
		let goto	= 'UP' . 41 . 'b'
	    " input == pat < cur (pat != 0) 		/we are looking for '\\input'/
	    elseif atplib#CompareCoordinates(input_pos, cur_pos) && input_pos == pat_pos && pat_pos != [0, 0]
		let goto	= 'ACCEPT' . 5 . 'b'
	    " pat <= cur < input (pat != 0) 
	    elseif atplib#CompareCoordinates(cur_pos, input_pos) && atplib#CompareCoordinates_leq(pat_pos, cur_pos) && input_pos != [0, 0]
		" cur == pat thus 'flag' contains 'c'.
		let goto	= 'ACCEPT' . 6 . 'b'
	    " cur == input
	    elseif cur_pos == input_pos
		let goto == 'UP'
	    " input == 0 			/there is no 'input' ahead - flag_i contains 'W'/
	    " 					/but there is no 'pattern ahead as well/
	    " at this stage: cur < pat || pat=input=0  (if not then  pat <= cur was done above, input=pat=0 is the 
	    " 						only posibility to be passed by the above filter).
	    elseif input_pos == [0, 0]
		" I claim that then cur < pat or pat=0
		if expand("%:p") == fnamemodify(a:main_file, ":p")
		    " wrapscan
		    if ( flags_supplied =~# 'w' || &l:wrapscan  && flags_supplied !~# 'W' )
			let new_flags	= substitute(flags_supplied, 'w', '', 'g') . 'W'  
			if a:wrap_nr <= 2
			    call cursor(line("$"), col("$"))

				if s:ATP_rs_debug
				silent echo " END 2 new_flags:".new_flags
				redir END
				endif

			    keepjumps call s:RecursiveSearch(a:main_file, a:start_file, "", a:cur_branch, 1, a:wrap_nr+1, a:winsaveview, a:bufnr, a:strftime, a:vim_options, pattern, new_flags) 

				if s:ATP_rs_debug > 1
				    silent echo "TIME_END:" . reltimestr(reltime(time0))
				endif

			    return
			else
			    let goto 	= "REJECT" . 1 . 'b'
" 			    echohl ErrorMsg
" 			    echomsg 'Pattern not found: ' . a:pattern
" 			    echohl None
			endif
		    else
			let goto 	= "REJECT" . 2 . 'b'
" 		    echohl ErrorMsg
" 		    echomsg 'Pattern not found: ' . a:pattern
" 		    echohl None
		    endif
		" if we are not in the main file go up.
		else
" 		    if searchpos(pattern, 'cnb', line(".")) == [line("."), col(".")] && a:call_nr > 1
" 			let goto	= "ACCEPT"  . 3 . 'b'
" 		    else
			let goto	= "DOWN" . 3 . 'b'
" 		    endif
		endif
	    else
		let goto = 'ERROR' . 13 . 'b'
	    endif
	endif

		if s:ATP_rs_debug
		silent echo "goto:".goto
		endif

	" When ACCEPTING the line:
	if goto =~ '^ACCEPT'
	    keepjumps call setpos(".", [ 0, pat_pos[0], pat_pos[1], 0])
	    if flags_supplied =~#  'e'
		keepjumps call search(pattern, 'e', line("."))
	    endif
	    "A Better solution must be found.
" 	    if &l:hlsearch
" 		execute '2match Search /'.pattern.'/'
" 	    endif
		
	    let time	= matchstr(reltimestr(reltime(a:strftime)), '\d\+\.\d\d\d') . "sec."

	    if a:wrap_nr == 2 && flags_supplied =~# 'b'
		redraw
		echohl WarningMsg
		echo "search hit TOP, continuing at BOTTOM "
		echohl Normal
	    elseif a:wrap_nr == 2
		redraw
		echohl WarningMsg
		echo "search hit BOTTOM, continuing at TOP "
		echohl Normal
	    endif


		if s:ATP_rs_debug
		silent echo "FOUND PATTERN: " . a:pattern . " time " . time
		silent echo ""
		redir END
		endif

	    return

	" when going UP
	elseif goto =~ '^UP'
	    call setpos(".", [ 0, input_pos[0], input_pos[0], 0])
	    " Open file and Search in it"
	    " This should be done by kpsewhich:
	    let file = matchstr(getline(input_pos[0]), '\\input\s*{\zs[^}]*\ze}')
	    let file = atplib#append(fnamemodify(l:file, ':p'), '.tex')

	    let open =  flags_supplied =~ 'b' ? 'edit + ' : 'edit +1 '
	    silent! execute open . file
	    let b:atp_MainFile=a:main_file
	    if flags_supplied =~# 'b'
		call cursor(line("$"), col("$"))
	    else
		call cursor(1,1)
	    endif

		if s:ATP_rs_debug
		silent echo "Opening higher branch: " . l:file	. " pos " line(".").":".col(".") . " edit " . open . " file " . expand("%:p")
		endif

		if s:ATP_rs_debug > 1
		    silent echo "TIME_END:" . reltimestr(reltime(time0))
		endif

" 	    let flag	= flags_supplied =~ 'W' ? flags_supplied : flags_supplied . 'W'
	    keepjumps call s:RecursiveSearch(a:main_file, a:start_file, "", expand("%:p"), a:call_nr+1, a:wrap_nr, a:winsaveview, a:bufnr, a:strftime, a:vim_options, pattern, flags_supplied)


	" when going DOWN
	elseif goto =~ '^DOWN'
	    " We have to get the element in the tree one level up + line number
	    let g:ATP_branch 	= "nobranch"
	    let g:ATP_branch_line	= "nobranch_line"

		if s:ATP_rs_debug
		silent echo "     SearchInTree Args " . expand("%:p")
		endif

	    call SearchInTree(l:tree, a:main_file, expand("%:p"))

	    if g:ATP_branch == "nobranch"
		echohl ErrorMsg
		echomsg "This is an internal error of ATP, please contact with the author."
		echohl Normal

		silent! echomsg "Tree=" . string(l:tree)
		silent! echomsg "MainFile " . a:main_file . " current_file=" . expand("%:p")
	    endif
	    let open =  'edit +'.g:ATP_branch_line." ".g:ATP_branch
	    silent! execute open
	    let b:atp_MainFile=a:main_file
" 	    call cursor(g:ATP_branch_line, 1)
	    if flags_supplied !~# 'b'
		keepjumps call search('\m\\input\s*{[^}]*}', 'e', line(".")) 
	    endif

		if s:ATP_rs_debug
		silent echo "Opening lower branch: " . g:ATP_branch . " at line " . line(".") . ":" . col(".") . " branch_line=" . g:ATP_branch_line	
		endif

		if s:ATP_rs_debug > 1
		    silent echo "TIME_END:" . reltimestr(reltime(time0))
		endif

	    unlet g:ATP_branch
	    unlet g:ATP_branch_line
" 	    let flag	= flags_supplied =~ 'W' ? flags_supplied : flags_supplied . 'W'
	    keepjumps call s:RecursiveSearch(a:main_file, a:start_file, "", expand("%:p"), a:call_nr+1, a:wrap_nr, a:winsaveview, a:bufnr, a:strftime, a:vim_options, pattern, flags_supplied)

	" when REJECT
	elseif goto =~ '^REJECT'
	    echohl ErrorMsg
	    echomsg "Pattern not found"
	    echohl Normal

	    if s:ATP_rs_debug > 1
		silent echo "TIME_END:" . reltimestr(reltime(time0))
	    endif

" 	    restore the window and buffer!
" 		it is better to remember bufnumber
	    silent execute "edit #" . a:bufnr
	    call winrestview(a:winsaveview)

		if s:ATP_rs_debug
		silent echo ""
		redir END
		endif

	    return

	" when ERROR
	elseif
	    echohl ErrorMsg
	    echomsg "This is a bug in ATP."
	    echohl
	    return 
	endif
endfunction

" This is a wrapper function around s:ReverseSearch
" It allows to pass arguments to s:ReverseSearch in a similar way to :vimgrep
" function
function! Search(Bang, Arg)
    let pattern		= matchstr(a:Arg, '^\(\/\|[^\i]\)\zs.*\ze\1')
    let flag		= matchstr(a:Arg, '^\(\/\|[^\i]\).*\1\s*\zs[bcepsSwW]*\ze\s*$')
    if pattern == ""
	let pattern	= matchstr(a:Arg, '^\zs\S*\ze\(\s[bcepsSwW]*\)\=$')
	let flag	= matchstr(a:Arg, '\s\zs[SbcewW]*\ze$')
    endif

    if pattern == ""
	echohl ErrorMsg
	echomsg "Enclose the pattern with /.../"
	echohl Normal
	return
    endif

    if a:Bang == "!"
	call s:RecursiveSearch(b:atp_MainFile, expand("%:p"), 'make_tree', expand("%:p"), 1, 1, winsaveview(), bufnr("%"), reltime(), { 'no_options' : 'no_options' }, pattern, flag)
    else
	call s:RecursiveSearch(b:atp_MainFile, expand("%:p"), '', expand("%:p"), 1, 1, winsaveview(), bufnr("%"), reltime(), { 'no_options' : 'no_options' }, pattern, flag)
    endif
endfunction
catch /E127: Cannot redefine function/  
endtry
" {{{2 Commands, Maps and Completion functions for Search() function. 
command! -buffer -bang -complete=customlist,SearchHistCompletion -nargs=* S 			:call Search(<q-bang>,<q-args>)
if !exists("g:atp_grab_nN")
    let g:atp_grab_nN = 0
endif
if g:atp_grab_nN
    nnoremap <buffer> <silent> <Plug>RecusiveSearchForward	:call <SID>RecursiveSearch(b:atp_MainFile, expand("%:p"), '', expand("%:p"), 1, 1, winsaveview(), bufnr("%"), reltime(), { 'no_options' : 'no_options' }, @/)<CR>
    nnoremap <buffer> <silent> <Plug>RecursiveSearchBackward    :call <SID>RecursiveSearch(b:atp_MainFile, expand("%:p"), '', expand("%:p"), 1, 1, winsaveview(), bufnr("%"), reltime(), { 'no_options' : 'no_options' }, @/, 'b')<CR>
"     nnoremap n	<Plug>RecursiveSearchForward<CR>
"     nnoremap N	<Plug>RecursiveSearchBackward<CR>

    nnoremap <buffer> <silent> n    :call <SID>RecursiveSearch(b:atp_MainFile, expand("%:p"), '', expand("%:p"), 1, 1, winsaveview(), bufnr("%"), reltime(), { 'no_options' : 'no_options' }, @/)<CR>
    nnoremap <buffer> <silent> N    :call <SID>RecursiveSearch(b:atp_MainFile, expand("%:p"), '', expand("%:p"), 1, 1, winsaveview(), bufnr("%"), reltime(), { 'no_options' : 'no_options' }, @/, 'b')<CR>
endif

function! SearchHistCompletion(ArgLead, CmdLine, CursorPos)
    let search_history=[]
    let hist_entry	= histget("search")
    let nr = 0
    while hist_entry != ""
	call add(search_history, hist_entry)
	let nr 		-= 1
	let hist_entry	=  histget("search", nr)
    endwhile
    
    return filter(search_history, "v:val =~# '^'.a:ArgLead")
endfunction
"}}}1

" These are only variables and front end functions for Bib Search Engine of ATP.
" Search engine is define in autoload/atplib.vim script library.
"{{{ BibSearch
"-------------SEARCH IN BIBFILES ----------------------
" This function counts accurence of a:keyword in string a:line, 
" there are two methods keyword is a string to find (a:1=0)or a pattern to
" match, the pattern used to is a:keyword\zs.* to find the place where to cut.
" DEBUG:
" command -buffer -nargs=* Count :echo atplib#count(<args>)

let g:bibentries=['article', 'book', 'booklet', 'conference', 'inbook', 'incollection', 'inproceedings', 'manual', 'mastertheosis', 'misc', 'phdthesis', 'proceedings', 'techreport', 'unpublished']


"{{{ variables
let g:bibmatchgroup		='String'
let g:defaultbibflags		= 'tabejsyu'
let g:defaultallbibflags	= 'tabejfsvnyPNSohiuHcp'
let b:lastbibflags		= g:defaultbibflags	" Set the lastflags variable to the default value on the startup.
let g:bibflagsdict=atplib#bibflagsdict
" These two variables were s:... but I switched to atplib ...
let g:bibflagslist		= keys(g:bibflagsdict)
let g:bibflagsstring		= join(g:bibflagslist,'')
let g:kwflagsdict={ 	  '@a' : '@article', 	
	    		\ '@b' : '@book\%(let\)\@<!', 
			\ '@B' : '@booklet', 	
			\ '@c' : '@in\%(collection\|book\)', 
			\ '@m' : '@misc', 	
			\ '@M' : '@manual', 
			\ '@p' : '@\%(conference\)\|\%(\%(in\)\?proceedings\)', 
			\ '@t' : '@\%(\%(master)\|\%(phd\)\)thesis', 
			\ '@T' : '@techreport', 
			\ '@u' : '@unpublished' }    

"}}}


" Hilighlting
hi link BibResultsFileNames 	Title	
hi link BibResultEntry		ModeMsg
hi link BibResultsMatch		WarningMsg
hi link BibResultsGeneral	Normal

hi link Chapter 		Normal	
hi link Section			Normal
hi link Subsection		Normal
hi link Subsubsection		Normal
hi link CurrentSection		WarningMsg

" Front End Function
" {{{ BibSearch
"  There are three arguments: {pattern}, [flags, [choose]]
function! s:BibSearch(...)
    if a:0 == 0
	let b:atp_LastBibPattern = ""
	call atplib#showresults( atplib#searchbib(''), '', '')
    elseif a:0 == 1
	let b:atp_LastBibPattern = a:1
	call atplib#showresults( atplib#searchbib(a:1), '', a:1)
    else
	let b:atp_LastBibPattern = a:1
	call atplib#showresults( atplib#searchbib(a:1), a:2, a:1)
    endif
endfunction
command! -buffer -nargs=* BibSearch	:call <SID>BibSearch(<f-args>)
nnoremap <silent> <Plug>BibSearchLast	:call <SID>BibSearch(b:atp_LastBibPattern, b:atp_LastBibFlags)<CR>
" }}}
"}}}

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
