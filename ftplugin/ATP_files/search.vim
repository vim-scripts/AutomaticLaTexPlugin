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
" a:3	= 1 	skip searching for the end_line
"
" ToDo: it is possible to check for the end using searchpairpos, but it
" operates on a list not on a buffer.
function! s:make_defi_dict(bang,...)

    let bufname	= a:0 >= 1 ? a:1 : b:atp_MainFile

    " pattern to match the definitions this function is also used to fine
    " \newtheorem, and \newenvironment commands  
    let pattern	= a:0 >= 2 ? a:2 : '\\def\|\\newcommand'

    let preambule_only= a:bang == "!" ? 0 : 1

    " this is still to slow!
    let only_begining	= a:0 >= 3 ? a:3 : 0

    let defi_dict={}

    let inputfiles=FindInputFiles(bufname)
    let input_files=[]

    " TeX: How this work in TeX files.
    for inputfile in keys(inputfiles)
	if inputfiles[inputfile][0] != "bib" && ( !preambule_only || inputfiles[inputfile][0] == "preambule" )
	    call add(input_files, inputfiles[inputfile][2])
	endif
    endfor

    let input_files=filter(input_files, 'v:val != ""')
    if !count(input_files, b:atp_MainFile)
	call extend(input_files,[ b:atp_MainFile ])
    endif

    if len(input_files) > 0
    for inputfile in input_files
	let defi_dict[inputfile]=[]
	" do not search for definitions in bib files 
	"TODO: it skips lines somehow. 
	let ifile=readfile(inputfile)
	
	" search for definitions
	let lnr=1
	while (lnr <= len(ifile) && (!preambule_only || ifile[lnr-1] !~ '\\begin\s*{document}'))

	    let match=0

	    let line=ifile[lnr-1]
	    if substitute(line,'%.*','','') =~ pattern

		let b_line=lnr

		let lnr+=1	
		if !only_begining
		    let open=atplib#count(line,'{')    
		    let close=atplib#count(line,'}')
		    while open != close
			"go to next line and count if the definition ends at
			"this line
			let line	= ifile[lnr-1]
			let open	+=atplib#count(line,'{')    
			let close	+=atplib#count(line,'}')
			let lnr		+=1	
		    endwhile
		    let e_line	= lnr-1
		    call add(defi_dict[inputfile], [ b_line, e_line ])
		else
		    call add(defi_dict[inputfile], [ b_line ])
		endif
	    else
		let lnr+=1
	    endif
	endwhile
    endfor
    endif

    return defi_dict
endfunction
"}}}

" Find all names of locally defined commands, colors and environments. 
" Used by the completion function.
"{{{ LocalCommands 
" a:1 = pattern
" a:2 = "!" => renegenerate the input files.
function! LocalCommands(...)
"     let time = reltime()
    let pattern = a:0 >= 1 && a:1 != '' ? a:1 : '\\def\>\|\\newcommand\>\|\\newenvironment\|\\newtheorem\|\\definecolor'
    let bang	= a:0 >= 2 ? a:2 : '' 

    " Regenerate the package list
    if bang == "!"
	let b:atp_PacakgeList	= atplib#GrepPackageList()
    endif


    " Makeing lists of commands and environments found in input files
    if bang == "!" || !exists("b:TreeOfFiles")
	 " Update the cached values:
	 let [ b:TreeOfFiles, b:ListOfFiles, b:TypeDict, b:LevelDict ] = TreeOfFiles(b:atp_MainFile)
     endif
     let [ Tree, List, Type_Dict, Level_Dict ] = deepcopy([ b:TreeOfFiles, b:ListOfFiles, b:TypeDict, b:LevelDict ])

     let saved_loclist	= getloclist(0)
     " I should scan the preambule separately!
     " This will make the function twice as fast!
     silent! execute "lvimgrep /".pattern."/j " . fnameescape(b:atp_MainFile)
     for file in List
	 if get(Type_Dict, file, 'no_file') == 'preambule'
	     silent! execute "lvimgrepadd /".pattern."/j " . fnameescape(file)
	 endif
     endfor
     let loclist	= getloclist(0)
     call setloclist(0, saved_loclist)

     let atp_LocalCommands	= []
     let atp_LocalEnvironments	= []
     let atp_LocalColors	= []

     for line in loclist
	" the order of pattern is important
	if line['text'] =~ '\\definecolor'
	    " color name
	    let name=matchstr(line['text'],
			\ '\\definecolor\s*{\s*\zs[^}]*\ze\s*}')
	    let type="Colors"
	elseif line['text'] =~ '\\def\|\\newcommand'
	    " definition name 
	    let name= '\' . matchstr(line['text'],
			\ '\\def\\\zs[^{#]*\ze[{#]\|\\newcommand{\?\\\zs[^\[{]*\ze}')
	    let type="Commands"
	    " definition
" 	    let def=matchstr(line['text'],
" 			\ '^\%(\\def\\[^{]*{\zs.*\ze}\|\\newcommand\\[^{]*{\zs.*\ze}\)') 
	elseif line['text'] =~ '\%(\\newenvironment\|\\newtheorem\)'
	    " environment name
	    let name=matchstr(line['text'],
			\ '\\\%(newtheorem\*\?\|newenvironment\)\s*{\s*\zs[^}]*\ze\s*}')
	    let type="Environments"
	endif
	if name != '' && name != '\'
	    if count(atp_Local{type}, name) == 0
		call add(atp_Local{type}, name)
	    endif
	endif
    endfor

    let b:atp_LocalCommands		= atp_LocalCommands
    let b:atp_LocalEnvironments		= atp_LocalEnvironments
    let b:atp_LocalColors		= atp_LocalColors
"     echomsg reltimestr(reltime(time))
    return [ atp_LocalEnvironments, atp_LocalCommands, atp_LocalColors ]

endfunction
command! -buffer -bang LocalCommands		:call LocalCommands("",<q-bang>)
"}}}

" Search for Definition in the definition dictionary (s:make_defi_dict).
"{{{ DefiSearch
function! DefiSearch(bang,...)

    let pattern		= a:0 >= 1 ? a:1 : ''
    let preambule_only	= a:bang == "!" ? 0 : 1

    let defi_dict	= s:make_defi_dict(a:bang, b:atp_MainFile, '\\def\|\\newcommand')

    " open new buffer
    let openbuffer=" +setl\\ buftype=nofile\\ nospell\\ syntax=tex " . fnameescape("DefiSearch")
    if g:vertical ==1
	let openbuffer="vsplit " . openbuffer 
    else
	let openbuffer="split " . openbuffer 
    endif

    if len(defi_dict) > 0
	" wipe out the old buffer and open new one instead
	if bufloaded("DefiSearch")
	    exe "silent bd! " . bufnr("DefiSearch") 
	endif
	silent exe openbuffer
	map <buffer> q	:bd<CR>

	for inputfile in keys(defi_dict)
	    let ifile	= readfile(inputfile)
	    for l:range in defi_dict[inputfile]
		if ifile[l:range[0]-1] =~ pattern
		    " print the lines into the buffer
		    let i=0
		    let c=0
		    " add an empty line if the definition is longer than one line
		    if l:range[0] != l:range[1]
			call setline(line('$')+1,'')
			let i+=1
		    endif
		    while c <= l:range[1]-l:range[0] 
			let line=l:range[0]+c
			call setline(line('$')+1,ifile[line-1])
			let i+=1
			let c+=1
		    endwhile
		endif
	    endfor
	endfor
	if getbufline("DefiSearch",'1','$') == ['']
	    :bw
	    redraw
	    echohl ErrorMsg
	    echomsg "Definition not found."
	    echohl Normal
	endif
    else
	redraw
	echohl ErrorMsg
	echomsg "Definition not found."
	echohl Normal
    endif
endfunction
command! -buffer -bang -nargs=* DefiSearch		:call DefiSearch(<q-bang>, <q-args>)
"}}}

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
	let g:ATP_branch	= a:branch
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
" a:2 is not not used:
" a:2		= 			goto = DOWN_ACCEPT / Must not be used by the end user/
" 					0/1 1=DOWN_ACCEPT	
" 								
let s:ATP_rs_debug=0	" if 1 sets debugging messages which are appended to '/tmp/ATP_rs_debug' 
			" you can :set errorfile=/tmp/ATP_rs_debug
			" and	  :set efm=.*
			" if 2 show time
" log file : /tmp/ATP_rs_debug
" {{{2 s:RecursiveSearch function
try
function! <SID>RecursiveSearch(main_file, start_file, tree, cur_branch, call_nr, wrap_nr, winsaveview, bufnr, strftime, vim_options, pattern, ... )

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

    	let flags_supplied = a:0 >= 1 ? a:1 : ""

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
	let flag	= substitute(flag, 'w', '', 'g') . 'W'
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

	" FIND PATTERN: 
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

	" FIND INPUT PATTERN: 
	" (we do not need to search further than pat_pos)
	if pat_pos == [0, 0]
	    let stop_line	= flag !~# 'b' ? line("$")  : 1
	else
	    let stop_line	= pat_pos[0]
	endif
	keepjumps let input_pos	= searchpos('\m^[^%]*\\input\s*{', flag_i . 'n', stop_line )

		if s:ATP_rs_debug > 1
		    silent echo "TIME2:" . reltimestr(reltime(time0))
		endif

		if s:ATP_rs_debug
		silent echo "Positions: ".string(cur_pos)." ".string(pat_pos)." ".string(input_pos)." in branch: ".cur_branch."#".expand("%:p") . " stop_line: " . stop_line 
		endif

	" Down Accept:
	" the current value of down_accept
	let DOWN_ACCEPT = a:0 >= 2 ? a:2 : 0
	" the value of down_accept in next turn 
	let down_accept	= getline(input_pos[0]) =~ pattern || input_pos == [0, 0] ?  1 : 0

" 		if s:ATP_rs_debug
" 		    silent echo "DOWN_ACCEPT=" . DOWN_ACCEPT . " down_accept=" . down_accept
" 		endif

	" Decide what to do: accept the pattern, go to higher branch, go to lower
	" branch or say Pattern not found
	if flags_supplied !~# 'b'
	    " FORWARD
	    " cur < pat <= input
	    if atplib#CompareCoordinates(cur_pos,pat_pos) && atplib#CompareCoordinates_leq(pat_pos, input_pos)
		let goto	= 'ACCEPT' . 1
		let goto_s	= 'ACCEPT'
	    " cur == pat <= input
	    elseif cur_pos == pat_pos && atplib#CompareCoordinates_leq(pat_pos, input_pos)
		" this means that the 'flag' variable has to contain 'c' or the
		" wrapscan is on
		" ACCEPT if 'c' and wrapscan is off or there is another match below,
		" if there is not go UP.
		let wrapscan	= ( flags_supplied =~# 'w' || &l:wrapscan && flags_supplied !~# 'W' )
		if flag =~# 'c'
		    let goto 	= 'ACCEPT'  . 2
		let goto_s	= 'ACCEPT'
		elseif wrapscan
		    " if in wrapscan and without 'c' flag
		    let goto	= 'UP' . 2
		let goto_s	= 'UP'
		else
		    " this should not happen: cur == put can hold only in two cases:
		    " wrapscan is on or 'c' is used.
		    let goto	= 'ERROR' . 2
		    let goto_s	= 'ERROR'
		endif
	    " pat < cur <= input
	    elseif atplib#CompareCoordinates(pat_pos, cur_pos) && atplib#CompareCoordinates_leq(cur_pos, input_pos) 
		let goto	= 'UP' . 4
		let goto_s	= 'UP'
	    " cur < input < pat
	    elseif atplib#CompareCoordinates(cur_pos, input_pos) && atplib#CompareCoordinates(input_pos, pat_pos)
		let goto	= 'UP' . 41
		let goto_s	= 'UP'
	    " cur < input == pat 		/we are looking for '\\input'/
	    elseif atplib#CompareCoordinates(cur_pos, input_pos) && input_pos == pat_pos
		let goto	= 'ACCEPT'
		let goto_s	= 'ACCEPT'
	    " input < cur <= pat	(includes input = 0])
	    elseif atplib#CompareCoordinates(input_pos, cur_pos) && atplib#CompareCoordinates_leq(cur_pos, pat_pos)
		" cur == pat thus 'flag' contains 'c'.
		let goto	= 'ACCEPT'
		let goto_s	= 'ACCEPT'
	    " cur == input
	    elseif cur_pos == input_pos
		let goto 	= 'UP'
		let goto_s	= 'UP'
	    " cur < input < pat
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
			    let goto_s 	= "REJECT"
" 			    echohl ErrorMsg
" 			    echomsg 'Pattern not found: ' . a:pattern
" 			    echohl None
			endif
		    else
			let goto 	= "REJECT".2
			let goto_s 	= "REJECT"
" 			echohl ErrorMsg
" 			echomsg 'Pattern not found: ' . a:pattern
" 			echohl None
		    endif
		" if we are not in the main file go up.
		else
		    let goto	= "DOWN" . 21
		    let goto_s	= "DOWN"
		endif
	    else
		let goto 	= 'ERROR' . 13
		let goto_s 	= 'ERROR'
	    endif
	else
	    " BACKWARD
	    " input <= pat < cur (pat != 0)
	    if atplib#CompareCoordinates(pat_pos, cur_pos) && atplib#CompareCoordinates_leq(input_pos, pat_pos) && pat_pos != [0, 0]
		" input < pat
		if input_pos != pat_pos
		    let goto	= 'ACCEPT' . 1 . 'b'
		    let goto_s	= 'ACCEPT'
		" input == pat
		else
		    let goto	= 'UP' . 1 . 'b'
		    let goto_s	= 'UP'
		endif
	    " input <= pat == cur (input != 0)			/pat == cur => pat != 0/
	    elseif cur_pos == pat_pos && atplib#CompareCoordinates_leq(input_pos, pat_pos) && input_pos != [0, 0]
		" this means that the 'flag' variable has to contain 'c' or the
		" wrapscan is on
		let wrapscan	= ( flags_supplied =~# 'w' || &l:wrapscan  && flags_supplied !~# 'W' )
		if flag =~# 'c'
		    let goto 	= 'ACCEPT'  . 2 . 'b'
		    let goto_s 	= 'ACCEPT'
		elseif wrapscan
		    " if in wrapscan and without 'c' flag
		    let goto	= 'UP' . 2 . 'b'
		    let goto_s	= 'UP'
		else
		    " this should not happen: cur == put can hold only in two cases:
		    " wrapscan is on or 'c' is used.
		    let goto	= 'ERROR' . 2 . 'b'
		    let goto_s	= 'ERROR'
		endif
	    " input <= cur < pat (input != 0)
	    elseif atplib#CompareCoordinates(cur_pos, pat_pos) && atplib#CompareCoordinates_leq(input_pos, cur_pos) && input_pos != [0, 0] 
		let goto	= 'UP' . 4 .'b'
		let goto_s	= 'UP'
	    " pat < input <= cur (input != 0)
	    elseif atplib#CompareCoordinates_leq(input_pos, cur_pos) && atplib#CompareCoordinates(pat_pos, input_pos) && input_pos != [0, 0]
		let goto	= 'UP' . 41 . 'b'
		let goto_s	= 'UP'
	    " input == pat < cur (pat != 0) 		/we are looking for '\\input'/
	    elseif atplib#CompareCoordinates(input_pos, cur_pos) && input_pos == pat_pos && pat_pos != [0, 0]
		let goto	= 'ACCEPT' . 5 . 'b'
		let goto_s	= 'ACCEPT'
	    " pat <= cur < input (pat != 0) 
	    elseif atplib#CompareCoordinates(cur_pos, input_pos) && atplib#CompareCoordinates_leq(pat_pos, cur_pos) && input_pos != [0, 0]
		" cur == pat thus 'flag' contains 'c'.
		let goto	= 'ACCEPT' . 6 . 'b'
		let goto_s	= 'ACCEPT'
	    " cur == input
	    elseif cur_pos == input_pos
		let goto 	= 'UP'
		let goto_s 	= 'UP'
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
			    let goto_s 	= "REJECT"
" 			    echohl ErrorMsg
" 			    echomsg 'Pattern not found: ' . a:pattern
" 			    echohl None
			endif
		    else
			let goto 	= "REJECT" . 2 . 'b'
			let goto_s 	= "REJECT"
		    endif
		" if we are not in the main file go up.
		else
		    let goto	= "DOWN" . 3 . 'b'
		    let goto_s	= "DOWN" 
		    " If using the following line DOWN_ACCEPT and down_accept
		    " variables are not needed. This seems to be the best way.
		    " 	There is no need to use this feature for
		    " 	\input <file_name> 	files.
		    if pattern =~ '\\\\input' || pattern =~ '\\\\include'
" 			if getline(input_pos[0]) =~ pattern || getline(".") =~ pattern
			let goto	= "DOWN_ACCEPT" . 3 . 'b'
			let goto_s	= "DOWN_ACCEPT"
		    endif
		endif
	    else
		let goto 	= 'ERROR' . 13 . 'b'
		let goto_s 	= 'ERROR'
	    endif
	endif

		if s:ATP_rs_debug
		silent echo "goto:".goto
		endif

	" When ACCEPTING the line:
	if goto_s == 'ACCEPT'
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
	elseif goto_s == 'UP'
	    call setpos(".", [ 0, input_pos[0], input_pos[0], 0])
	    " Open file and Search in it"
	    " This should be done by kpsewhich:
	    let file = matchstr(getline(input_pos[0]), '\\input\s*{\zs[^}]*\ze}')
	    let file = atplib#append_ext(fnamemodify(l:file, ':p'), '.tex')

	    let open =  flags_supplied =~ 'b' ? 'edit + ' : 'edit +1 '
	    if !( a:call_nr == 1 && a:wrap_nr == 1 )
		let open = "keepjumps keepalt " . open
	    endif
 
	    silent! execute open . file

	    let b:atp_MainFile=a:main_file
	    if flags_supplied =~# 'b'
		call cursor(line("$"), col("$"))
	    else
		call cursor(1,1)
	    endif

		if s:ATP_rs_debug
		silent echo "Opening higher branch: " . l:file	. " pos " line(".").":".col(".") . " edit " . open . " file " . expand("%:p")
		silent echo "flags_supplied=" . flags_supplied
		endif

		if s:ATP_rs_debug > 1
		    silent echo "TIME_END:" . reltimestr(reltime(time0))
		endif

" 	    let flag	= flags_supplied =~ 'W' ? flags_supplied : flags_supplied . 'W'
	    keepalt keepjumps call s:RecursiveSearch(a:main_file, a:start_file, "", expand("%:p"), a:call_nr+1, a:wrap_nr, a:winsaveview, a:bufnr, a:strftime, a:vim_options, pattern, flags_supplied, down_accept)


	" when going DOWN
	elseif goto_s == 'DOWN' || goto_s == 'DOWN_ACCEPT'
	    " We have to get the element in the tree one level up + line number
	    let g:ATP_branch 	= "nobranch"
	    let g:ATP_branch_line	= "nobranch_line"

		if s:ATP_rs_debug
		silent echo "     SearchInTree Args " . expand("%:p")
		endif

	    call SearchInTree(l:tree, a:main_file, expand("%:p"))

	    if g:ATP_branch == "nobranch"
		echohl ErrorMsg
		echomsg "This probably happend while searching for \\input, it is not yet supported, if not it is a bug"
		echohl Normal

		silent! echomsg "Tree=" . string(l:tree)
		silent! echomsg "MainFile " . a:main_file . " current_file=" . expand("%:p")

" 		return
	    endif
	    if a:call_nr == 1 && a:wrap_nr == 1 
		let open =  'edit +'.g:ATP_branch_line." ".g:ATP_branch
	    else
		let open =  'keepjumps keepalt edit +'.g:ATP_branch_line." ".g:ATP_branch
	    endif
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
	    if goto_s == 'DOWN'
		keepalt keepjumps call s:RecursiveSearch(a:main_file, a:start_file, "", expand("%:p"), a:call_nr+1, a:wrap_nr, a:winsaveview, a:bufnr, a:strftime, a:vim_options, pattern, flags_supplied)
	    endif

	" when REJECT
	elseif goto_s == 'REJECT'
	    echohl ErrorMsg
	    echomsg "Pattern not found"
	    echohl Normal

	    if s:ATP_rs_debug > 1
		silent echo "TIME_END:" . reltimestr(reltime(time0))
	    endif

" 	    restore the window and buffer!
" 		it is better to remember bufnumber
	    silent execute "keepjumps keepalt edit #" . a:bufnr
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
catch /E127: Cannot redefine function/  
endtry
" }}}2

" This is a wrapper function around s:ReverseSearch
" It allows to pass arguments to s:ReverseSearch in a similar way to :vimgrep
" function
" {{{2 Search()
try
function! Search(Bang, Arg)
    let pattern		= matchstr(a:Arg, '\m^\(\/\|[^\i]\)\zs.*\ze\1')
    let flag		= matchstr(a:Arg, '\m^\(\/\|[^\i]\).*\1\s*\zs[bcepsSwW]*\ze\s*$')
    if pattern == ""
	let pattern	= matchstr(a:Arg, '\m^\zs\S*\ze\(\s[bcepsSwW]*\)\=$')
	let flag	= matchstr(a:Arg, '\m\s\+\zs[SbcewW]*\ze$')
    endif

    if pattern == ""
	echohl ErrorMsg
	echomsg "Enclose the pattern with /.../"
	echohl Normal
	return
    endif

    let g:pattern = pattern

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
" Debug:
" function! RecursiveSearch(main_file, start_file, tree, cur_branch, call_nr, wrap_nr, winsaveview, bufnr, strftime, vim_options, pattern, ... )
"     let a1 =  a:0 >= 1 ? a:1 : "" 
"     let g:main_file	=a:main_file
"     let g:start_file	=a:start_file
"     let g:tree		=a:tree 
"     let g:cur_branch	=a:cur_branch
"     let g:call_nr	=a:call_nr
"     let g:wrap_nr	=a:wrap_nr
"     let g:winsaveview	=a:winsaveview
"     let g:bufnr		=a:bufnr
"     let g:strftime	=a:strftime
"     let g:vim_options	=a:vim_options
"     let g:pattern	=a:pattern
"     let g:a1		=a1
"     call s:RecursiveSearch(a:main_file, a:start_file, a:tree, a:cur_branch, a:call_nr, a:wrap_nr, a:winsaveview, a:bufnr, a:strftime, a:vim_options, a:pattern, a1 )
" endfunction
nmap <buffer> <silent> <Plug>RecursiveSearchn 	:call <SID>RecursiveSearch(b:atp_MainFile, expand("%:p"), '', expand("%:p"), 1, 1, winsaveview(), bufnr("%"), reltime(), { 'no_options' : 'no_options' }, @/, v:searchforward ? "" : "b")<CR>
nmap <buffer> <silent> <Plug>RecursiveSearchN 	:call <SID>RecursiveSearch(b:atp_MainFile, expand("%:p"), '', expand("%:p"), 1, 1, winsaveview(), bufnr("%"), reltime(), { 'no_options' : 'no_options' }, @/, !v:searchforward ? "" : "b")<CR>

if g:atp_grabNn
" These two maps behaves now like n (N): after forward search n (N) acts as forward (backward), after
" backward search n acts as backward (forward, respectively).

nmap  n		<Plug>RecursiveSearchn
nmap  N		<Plug>RecursiveSearchN
endif
" }}}2
function! ATP_ToggleNn() " {{{2
	if maparg('n', 'n') != ""
	    silent! nunmap <buffer> n
	    silent! nunmap <buffer> N
	    silent! aunmenu LaTeX.Toggle\ Nn\ [on]
	    let g:atp_grabNn	= 0
	    nmenu 550.79 &LaTeX.Toggle\ &Nn\ [off]<Tab>:ToggleNn		:ToggleNn<CR>
	    imenu 550.79 &LaTeX.Toggle\ &Nn\ [off]<Tab>:ToggleNn		<Esc>:ToggleNn<CR>a
	    tmenu LaTeX.Toggle\ Nn\ [off] Do not grab n,N vim normal commands.
	    echomsg "vim nN maps"  
	else
	    silent! nmap <buffer> <silent> n    <Plug>RecursiveSearchn
	    silent! nmap <buffer> <silent> N    <Plug>RecursiveSearchN
	    silent! aunmenu LaTeX.Toggle\ Nn\ [off]
	    let g:atp_grabNn	= 1
	    nmenu 550.79 &LaTeX.Toggle\ &Nn\ [on]<Tab>:ToggleNn			:ToggleNn<CR>
	    imenu 550.79 &LaTeX.Toggle\ &Nn\ [on]<Tab>:ToggleNn			<Esc>:ToggleNn<CR>a
	    tmenu LaTeX.Toggle\ Nn\ [on] Grab n,N vim normal commands.
	    echomsg "atp nN maps"
	endif
endfunction
command! -buffer ToggleNn	:call ATP_ToggleNn()

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
function! BibSearch(bang,...)
    let pattern = a:0 >= 1 ? a:1 : ""
    let flag	= a:0 >= 2 ? a:2 : ""
    let b:atp_LastBibPattern 	= pattern
    let b:atp_LastBibFlags	= flag
    let @/			= pattern
    call atplib#showresults( atplib#searchbib(pattern, a:bang), flag, pattern)
endfunction
command! -buffer -bang -nargs=* BibSearch	:call BibSearch(<q-bang>, <f-args>)
nnoremap <silent> <Plug>BibSearchLast		:call BibSearch("", b:atp_LastBibPattern, b:atp_LastBibFlags)<CR>
" }}}
"}}}

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
