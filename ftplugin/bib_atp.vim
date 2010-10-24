" Title:		Vim filetype plugin file
" Author:		Marcin Szamotulski
" Email:		mszamot [AT] gmail [DOT] com
" URL:			https://launchpad.net/automatictexplugin	
" BUG Trucer:		https://bugs.launchpad.net/automatictexplugin
" Language:		bib
" Last Changed: 22 October 2010
" Copyright Statement: 
" 	  This file is part of Automatic Tex Plugin for Vim.
"
"     Automatic Tex Plugin for Vim is free software: you can redistribute it
"     and/or modify it under the terms of the GNU General Public License as
"     published by the Free Software Foundation, either version 3 of the
"     License, or (at your option) any later version.
" 
"     Automatic Tex Plugin for Vim is distributed in the hope that it will be
"     useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
"     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
"     General Public License for more details.
" 
"     You should have received a copy of the GNU General Public License along
"     with Automatic Tex Plugin for Vim.  If not, see <http://www.gnu.org/licenses/>.
"
"     This licence applies to all files shipped with Automatic Tex Plugin.

if !exists("g:atpbib_pathseparator")
    if has("win16") || has("win32") || has("win64") || has("win95")
	let g:atpbib_pathseparator = "\\"
    else
	let g:atpbib_pathseparator = "/"
    endif 
endif
if !exists("g:atpbib_WgetOutputFile")
    let tmpname = tempname()
    let g:atpbib_WgetOutputFile = tmpname . g:atpbib_pathseparator . "amsref.html"
    call mkdir(tmpname)
endif
if !exists("g:atpbib_wget")
    let g:atpbib_wget="wget -O " . g:atpbib_WgetOutputFile
endif
if !exists("g:atpbib_Article")
    let g:atpbib_Article = [ '@article{',
		\ '	Author	= {},',
		\ '	Title	= {},',
		\ '	Journal	= {},',
		\ '	Year	= {},', 
		\ '}' ]
endif
nmap <buffer> <LocalLeader>a	:call append(line("."), g:atpbib_Article)<CR>
if !exists("g:atpbib_Book")
    let g:atpbib_Book = [ '@book{' ,
		\ '	Author     	= {},',
		\ '	Title      	= {},',
		\ '	Publisher  	= {},',
		\ '	Year       	= {},', 
		\ '}' ]
endif
if !exists("g:atpbib_Booklet")
    let g:atpbib_Booklet = [ '@booklet{' ,
		\ '	Title      	= {},', 
		\ '}' ]
endif
if !exists("g:atpbib_Conference")
    let g:atpbib_Conference = [ '@conference{' ,
		\ '	Author     	= {},',
		\ '	Title      	= {},',
		\ '	Booktitle  	= {},',
		\ '	Publisher  	= {},',
		\ '	Year       	= {},',
		\ '}' ]
endif
if !exists("g:atpbib_InBook")
    let g:atpbib_InBook = [ '@inbook{' ,
		\ '	Author     	= {},',
		\ '	Title      	= {},',
		\ '	Chapter    	= {},',
		\ '	Publisher  	= {},',
		\ '	Year       	= {},',
		\ '}' ]
endif
if !exists("g:atpbib_InCollection")
    let g:atpbib_InCollection = [ '@incollection{' ,
		\ '	Author     	= {},',
		\ '	Title      	= {},',
		\ '	Booktitle  	= {},',
		\ '	Publisher  	= {},',
		\ '	Year       	= {},',
		\ '}' ]
endif
if !exists("g:atpbib_InProceedings")
    let g:atpbib_InProceedings = [ '@inproceedings{' ,
		\ '	Author     	= {},',
		\ '	Title      	= {},',
		\ '	Booktitle  	= {},',
		\ '	Publisher  	= {},',
		\ '	Year       	= {},',
		\ '}' ]
endif
if !exists("g:atpbib_Manual")
    let g:atpbib_Manual = [ '@manual{' ,
		\ '	Title      	= {},',
		\ '}' ]
endif
if !exists("g:atpbib_MastersThesis")
    let g:atpbib_MastersThesis = [ '@mastersthesis{' ,
		\ '	Author     	= {},',
		\ '	Title      	= {},',
		\ '	School     	= {},',
		\ '	Year       	= {},',
		\ '}' ]
endif
if !exists("g:atpbib_Misc")
    let g:atpbib_Misc = [ '@misc{',
		\ '	Title      	= {},',
		\ '}' ]
endif
if !exists("g:atpbib_PhDThesis")
    let g:atpbib_PhDThesis = [ '@phdthesis{' ,
		\ '	Author     	= {},',
		\ '	Title      	= {},',
		\ '	School     	= {},',
		\ '	Year       	= {},',
		\ '}' ]
endif
if !exists("g:atpbib_Proceedings")
    let g:atpbib_Proceedings = [ '@proceedings{' ,
		\ '	Title      	= {},',
		\ '	Year       	= {},', 
		\ '}' ]
endif
if !exists("g:atpbib_TechReport")
    let g:atpbib_TechReport = [ '@TechReport{' ,
		\ '	Author     	= {},',
		\ '	Title      	= {},',
		\ '	Institution	= {},',
		\ '	Year       	= {},', 
		\ '}' ]
endif
if !exists("g:atpbib_Unpublished")
    let g:atpbib_Unpublished = [ '@unpublished{',
		\ '	Author     	= {},',
		\ '	Title      	= {},',
		\ '	Note       	= {},',
		\ '}' ]
endif

" AMSRef:
" {{{ <SID>AMSRef
try
function! <SID>GetAMSRef(what, bibfile)
    let what = substitute(a:what," ", "+", "g")
    let g:what=what 
    let cmd = g:atpbib_wget . " " . '"http://www.ams.org/mathscinet-mref?ref='.what.'&dataType=bibtex"'
    let g:cmd=cmd
    call system(cmd)
    let loclist = getloclist(0)

    let pattern = '@\%(article\|book\%(let\)\=\|conference\|inbook\|incollection\|\%(in\)\=proceedings\|manual\|masterthesis\|misc\|phdthesis\|techreport\|unpublished\)\s*{\|^\s*\%(ADDRESS\|ANNOTE\|AUTHOR\|BOOKTITLE\|CHAPTER\|CROSSREF\|EDITION\|EDITOR\|HOWPUBLISHED\|INSTITUTION\|JOURNAL\|KEY\|MONTH\|NOTE\|NUMBER\|ORGANIZATION\|PAGES\|PUBLISHER\|SCHOOL\|SERIES\|TITLE\|TYPE\|VOLUME\|YEAR\|MRCLASS\|MRNUMBER\|MRREVIEWER\)\s*=\s*.*$'
    try 
	exe 'lvimgrep /'.pattern.'/j ' . g:atpbib_WgetOutputFile 
    catch /E480:/
    endtry
    let data = getloclist(0)
    let g:data = copy(data)
    if !len(data) 
	echohl WarningMsg
	echomsg "Nothing found."
	echohl None
	return
    endif
    call setloclist(0, loclist)

    let linenumbers = map(copy(data), 'v:val["lnum"]')
    let begin	= min(linenumbers)
"     let g:begin = begin
    let end	= max(linenumbers)
"     let g:end	= end

    let bufnr = bufnr(g:atpbib_WgetOutputFile)
    let g:bufnr = bufnr
    " To use getbufline() buffer must be loaded. It is enough to use :buffer
    " command because vimgrep loads buffer and then unloads it. 
    execute "buffer " . bufnr
    let bibdata	= getbufline(bufnr, begin, end)
    let g:bibdata = bibdata
    execute "bdelete " . bufnr 
    let type = matchstr(bibdata[0], '@\%(article\|book\%(let\)\=\|conference\|inbook\|incollection\|\%(in\)\=proceedings\|manual\|masterthesis\|misc\|phdthesis\|techreport\|unpublished\)\ze\s*\%("\|{\|(\)')
"     let g:type = type
"     Suggest Key:
"     let author = substitute(matchstr(get(filter(copy(bibdata), "v:val =~ '\\<author\\>'"),0, ""), 'author\s*=\s*\("\|{\|''\|(\)\zs.*\ze'), '{\|}\|(\|)\|''\|"\|,', '', 'g')
"     let firstauthor = split(author, "and")[0]
"     let title = substitute(matchstr(get(filter(copy(bibdata), "v:val =~ '\\<title\\>'"),0, ""), 'title\s*=\s*\("\|{\|''\|(\)\zs.*\ze'), '{\|}\|(\|)\|''\|"\|,', '', 'g')
"     let suggested_key = substitute(firstauthor . ":" . title, " ", "_", "g")
"     let g:suggested_key = suggested_key
    let bibkey = input("Provide a key (Enter for the AMS bibkey): ")
    if !empty(bibkey)
	let bibdata[0] = type . '{' . bibkey
    else
	let bibdata[0] = substitute(matchstr(bibdata[0], '@\w*.*$'), '\(@\w*\)\(\s*\)', '\1', '')
    endif
    call add(bibdata, "}")

    " Open bibfile and append the bibdata:
    execute "edit " . a:bibfile
"     let g:eline = getline(line('$')) !~ '^\s*$'
    if getline(line('$')) !~ '^\s*$' 
	let bibdata = extend([''], bibdata)
    endif
"     echomsg string(bibdata)
    call append(line('$'), bibdata)
    normal GG
    return bibdata
endfunction
catch /E127/
endtry

command! -buffer -nargs=1 AMSRef    call <SID>GetAMSRef(<q-args>, expand("%:p"))
"}}}

" JMotion:
function JMotion(flag)
    let pattern = '\%(\%(address\|annote\|author\|booktitle\|chapter\|crossref\|edition\|editor\|howpublished\|institution\|journal\|key\|month\|note\|number\|organization\|pages\|publisher\|school\|series\|title\|type\|volume\|year\|mrclass\|mrnumber\|mrreviewer\)\s*=\s.\zs\|@\w*\%({\|"\|(\|''\)\zs\)'
    call search(pattern, a:flag)
endfunction

" NEntry
function! NEntry(flag,...)
    let keepjumps = ( a:0 >= 1 ? a:1 : "" )
    let pattern = '@\%(article\|book\%(let\)\=\|conference\|inbook\|incollection\|\%(in\)\=proceedings\|manual\|masterthesis\|misc\|phdthesis\|techreport\|unpublished\)'
    let g:cmd = keepjumps . " call search(".pattern.",".a:flag.")" 
    execute keepjumps . " call search(pattern, a:flag)"
endfunction
 
" EntryEnd
function! EntryEnd(flag)
    call NEntry("bc", "keepjumps")
    if a:flag =~# 'b'
	call NEntry("b", "keepjumps")
    endif
    keepjumps call search('\%({\|(\|"\|''\)')
    normal %
endfunction

nmap <buffer> <silent> ]]	:call NEntry("")<CR>
nmap <buffer> <silent> }	:call NEntry("")<CR>zz
nmap <buffer> <silent> [[	:call NEntry("b")<CR>
nmap <buffer> <silent> {	:call NEntry("b")<CR>zz

nmap <buffer> <silent> ][	:call EntryEnd("")<CR>
nmap <buffer> <silent> []	:call EntryEnd("b")<CR>

nmap <buffer> <c-j> 	:call JMotion("")<CR>
nmap <buffer> <c-k>	:call JMotion("b")<CR>	
imap <buffer> <c-j>	<Esc>l:call JMotion("")<CR>i
imap <buffer> <c-k>	<Esc>l:call JMotion("b")<CR>i

nnoremap <buffer> <silent> <F1>		:call system("texdoc bibtex")<CR>

nnoremap <buffer> <LocalLeader>a	:call append(line("."), g:atpbib_Article)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>b	:call append(line("."), g:atpbib_Book)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>bo	:call append(line("."), g:atpbib_Book)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>c	:call append(line("."), g:atpbib_InProceedings)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>bl	:call append(line("."), g:atpbib_Booklet)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>ib	:call append(line("."), g:atpbib_InBook)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>ic	:call append(line("."), g:atpbib_InCollection)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>ma	:call append(line("."), g:atpbib_Manual)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>mt	:call append(line("."), g:atpbib_MasterThesis)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>mi	:call append(line("."), g:atpbib_Misc)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>phd	:call append(line("."), g:atpbib_PhDThesis)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>pr	:call append(line("."), g:atpbib_Proceedings)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>tr	:call append(line("."), g:atpbib_TechReport)<CR>:call JMotion("")<CR>
nnoremap <buffer> <LocalLeader>un	:call append(line("."), g:atpbib_Unpublished)<CR>:call JMotion("")<CR>
