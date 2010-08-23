" This file contains all the options defined on startup of ATP
" you can add your local settings to ~/.atprc.vim or ftplugin/ATP_files/atprc.vim file


" Some options (functions) should be set once:
let s:did_options 	= exists("s:did_options") ? 1 : 0


if filereadable(fnameescape($HOME . '/.atprc.vim'))

	" Note: in $HOME/.atprc file the user can set all the local buffer
	" variables without using autocommands
	execute 'source ' . fnameescape($HOME . '/.atprc.vim')

else
    let path	= get(split(globpath(&rtp, "**/ftplugin/ATP_files/atprc.vim"), '\n'), 0, "")
    if path != ""
	execute 'source ' . path
    endif
endif

"{{{ tab-local variables
" We need to know bufnumber and bufname in a tabpage.
" ToDo: we can set them with s: and call them using <SID> stack
" (how to make the <SID> stack invisible to the user!

    let t:atp_bufname	= bufname("")
    let t:atp_bufnr	= bufnr("")
    let t:atp_winnr	= winnr()


" autocommands for buf/win numbers
" These autocommands are used to remember the last opened buffer number and its
" window number:
if !s:did_options
    augroup ATP_TabLocalVariables
	au!
	au BufLeave *.tex 	let t:atp_bufname	= resolve(fnamemodify(bufname(""),":p"))
	au BufLeave *.tex 	let t:atp_bufnr		= bufnr("")
	" t:atp_winnr the last window used by tex, ToC or Labels buffers:
	au WinEnter *.tex 	let t:atp_winnr		= winnr("#")
	au WinEnter __ToC__ 	let t:atp_winnr		= winnr("#")
	au WinEnter __Labels__ 	let t:atp_winnr		= winnr("#")
	au TabEnter *.tex	let t:atp_SectionStack 	= ( exists("t:atp_SectionStack") ? t:atp_SectionStack : [] ) 
    augroup END
endif
"}}}


" vim options + indetation
" {{{ Vim options

" {{{ Intendation
if !exists("g:atp_indentation")
    let g:atp_indentation=1
endif
" if !exists("g:atp_tex_indent_paragraphs")
"     let g:atp_tex_indent_paragraphs=1
" endif
if g:atp_indentation
"     setl indentexpr=GetTeXIndent()
"     setl nolisp
"     setl nosmartindent
"     setl autoindent
"     setl indentkeys+=},=\\item,=\\bibitem,=\\[,=\\],=<CR>
"     let prefix = expand('<sfile>:p:h:h')
"     exe 'so '.prefix.'/indent/tex_atp.vim'
    let prefix = expand('<sfile>:p:h')    
    exe 'so '.prefix.'/LatexBox_indent.vim'
endif
" }}}

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
    let g:filetype = &l:filetype
    if &l:filetype != "plaintex"
	setlocal include=\\\\input\\(\\s*{\\)\\=\\\\|\\\\include\\s*{
    else
	setlocal include=\\\\input
    endif
    setlocal suffixesadd=.tex

    setlocal includeexpr=substitute(v:fname,'\\%(.tex\\)\\?$','.tex','')
    " TODO set define and work on the above settings, these settings work with [i
    " command but not with [d, [D and [+CTRL D (jump to first macro definition)
    
" This was throwing all autocommand groups to the command line on startup.
" Anyway this is not very good.
"     augroup ATP_makeprg
" 	au VimEnter *.tex let &l:makeprg="vim --servername " . v:servername . " --remote-expr 'Make()'"
"     augroup

" }}}

" Set the project name
"{{{ SetProjectName (function and autocommands)
" This function sets the main project name (b:atp_MainFile)
"
" It is used by EditInputFile which copies the value of this variable to every
" input file included in the main source file. 
"
" nmap gf (GotoFile function) is not using this function.
"
" the b:atp_MainFile variable is set earlier in the startup
" (by the augroup ATP_Syntax_TikzZone), calling SetProjectName to earlier cause
" problems (g:atp_raw_bibinputs undefined). 
"
" ToDo: CHECK IF THIS IS WORKS RECURSIVELY?
" ToDo: THIS FUNCTION SHUOLD NOT SET AUTOCOMMANDS FOR AuTeX function! 
" 	every tex file should be compiled (the compiler function calls the  
" 	right file to compile!
"
" {{{ SetProjectName ( function )
" store a list of all input files associated to some file
fun! SetProjectName()
    " if the project name was already set do not set it for the second time
    " (which sets then b:atp_MainFile to wrong value!)  
    if &filetype == "fd_atp"
	" this is needed for EditInputFile function to come back to the main
	" file.
	let b:atp_MainFile	= fnamemodify(expand("%"), ":p")
	let b:did_project_name	= 1
    endif

    if exists("b:did_project_name") 
	return " project name was already set"
    else
	let b:did_project_name	= 1
    endif

    if !exists("g:atp_project")
	let b:atp_MainFile	= exists("b:atp_MainFile") ? b:atp_MainFile : expand("%:p")
	let pn_return		= " set from history or just set "
    elseif exists("g:atp_project")
	let b:atp_MainFile	= g:atp_project
	let pn_return		= " set from g:atp_project"
    endif

    " we need to escape white spaces in b:atp_MainFile but not in all places so
    " this is not done here

    " Now we can run things that needs the project name: 
    let b:atp_PackageList	= atplib#GrepPackageList()

"     let g:pn_return = pn_return
    return pn_return
endfun
command! SetProjectName	:call SetProjectName()
" }}}

if !s:did_options
    augroup ATP_SetProjectName
	au BufEnter *.tex :call SetProjectName()
	au BufEnter *.fd  :call SetProjectName()
    augroup END
endif
"}}}

" This function sets vim 'errorfile' option.
" {{{ s:SetErrorFile (function and autocommands)
" let &l:errorfile=b:atp_OutDir . fnameescape(fnamemodify(expand("%"),":t:r")) . ".log"
"{{{ s:SetErrorFile
function! s:SetErrorFile()

    " set b:atp_OutDir if it is not set
    if !exists("b:atp_OutDir")
	call s:SetOutDir(0)
    endif

    " set the b:atp_MainFile varibale if it is not set (the project name)
    if !exists("b:atp_MainFile")
	call SetProjectName()
    endif

    " vim doesn't like escaped spaces in file names ( cg, filereadable(),
    " writefile(), readfile() - all acepts a non-escaped white spaces)
    if has("win16") || has("win32") || has("win64") || has("win95")
	let errorfile	= substitute(atplib#append(b:atp_OutDir, '\') . fnamemodify(b:atp_MainFile,":t:r") . ".log", '\\\s', ' ', 'g') 
    else
	let errorfile	= substitute(atplib#append(b:atp_OutDir, '/') . fnamemodify(b:atp_MainFile,":t:r") . ".log", '\\\s', ' ', 'g') 
" 	let errorfile	= findfile(fnamemodify(b:atp_MainFile, ":t:r") . ".log", b:atp_OutDir) 
" 	if !errorfile 
" 	    " This will not work when the out dir is not where main file is put (and
" 	    " the log file doesn't exist)
" 	    let errorfile	= fnamemodify(b:atp_MainFile, ":p:r") . ".log"
" 	endif
    endif
    let &l:errorfile	= errorfile
    return &l:errorfile
endfunction
if expand("%:e") == "tex"
    call s:SetErrorFile()
endif
command! -buffer SetErrorFile		:call s:SetErrorFile()
"}}}

if !s:did_options
    augroup ATP_SetErrorFile
	au BufEnter 	*.tex 		call 		<SID>SetErrorFile()
	au BufRead 	$l:errorfile 	setlocal 	autoread 
    augroup END
endif
"}}}

" Global Variables: (almost all)
" {{{ global variables 

" if !exists("g:atp_closebracket_checkenv")
    " This is a list of environment names. They will be checked by
    " atplib#CloseLastBracket() function (if they are opened/closed:
    " ( \begin{array} ... <Tab>       will then close first \begin{array} and then ')'
    try
	let g:atp_closebracket_checkenv	= [ 'array' ]
	" Changing this variable is not yet supported *see ToDo: in
	" atplib#CloseLastBracket() (autoload/atplib.vim)
	lockvar g:atp_closebracket_checkenv
    catch /E741: Value is locked: g:atp_closebracket_checkenv/
" 	echomsg "Changing this variable is not supported"
    endtry
" endif
if !exists("g:atp_statusOutDir")
    let g:atp_statusOutDir 	= 1
endif
if !exists("g:atp_grabNn")
    let g:atp_grabNn 		= 0
endif
if !exists("g:atp_developer")
    let g:atp_developer		= 0
endif
if !exists("g:atp_TeXdocDefault")
    let g:atp_TeXdocDefault	= '-a lshort'
endif
"ToDo: to doc.
"ToDo: luatex! (can produce both!)
if !exists("g:atp_CompilersDict")
    let g:atp_CompilersDict 	= { 
		\ "pdflatex" 	: ".pdf", 	"pdftex" 	: ".pdf", 
		\ "xetex" 	: ".pdf", 	"latex" 	: ".dvi", 
		\ "tex" 	: ".dvi",	"elatex"	: ".dvi",
		\ "etex"	: ".dvi", 	"luatex"	: ".pdf"}
endif

if !exists("g:CompilerMsg_Dict")
    let g:CompilerMsg_Dict	= { 
		\ 'tex'			: 'TeX', 
		\ 'etex'		: 'eTeX', 
		\ 'pdftex'		: 'pdfTeX', 
		\ 'latex' 		: 'LaTeX',
		\ 'elatex' 		: 'eLaTeX',
		\ 'pdflatex'		: 'pdfLaTeX', 
		\ 'context'		: 'ConTeXt',
		\ 'luatex'		: 'LuaTeX',
		\ 'xetex'		: 'XeTeX'}
endif

if !exists("g:ViewerMsg_Dict")
    let g:ViewerMsg_Dict	= {
		\ 'xpdf'		: 'Xpdf',
		\ 'xdvi'		: 'Xdvi',
		\ 'kpdf'		: 'Kpdf',
		\ 'okular'		: 'Okular', 
		\ 'evince'		: 'Evince',
		\ 'acroread'		: 'AcroRead',
		\ 'epdfview'		: 'epdfView' }
endif

"ToDo: to doc.
if !exists("g:atp_insert_updatetime")
    let g:atp_insert_updatetime = max([ 2000, &l:updatetime])
endif
if !exists("g:atp_DefaultDebugMode")
    " recognised values: silent, normal, debug.
    let g:atp_DefaultDebugMode	= "normal"
endif
if !exists("g:atp_show_all_lines")
    " boolean
    let g:atp_show_all_lines 	= 0
endif
if !exists("g:atp_ignore_unmatched")
    " boolean
    let g:atp_ignore_unmatched 	= 1
endif
if !exists("g:atp_imap_first_leader")
    let g:atp_imap_first_leader	= "#"
endif
if !exists("g:atp_imap_second_leader")
    let g:atp_imap_second_leader= "##"
endif
if !exists("g:atp_imap_third_leader")
    let g:atp_imap_third_leader	= "]"
endif
if !exists("g:atp_imap_fourth_leader")
    let g:atp_imap_fourth_leader= "["
endif
" todo: to doc.
if !exists("g:atp_completion_font_encodings")
    let g:atp_completion_font_encodings	= ['T1', 'T2', 'T3', 'T5', 'OT1', 'OT2', 'OT4', 'UT1']
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
    let g:atp_sizes_of_brackets={'\left': '\right', 
			    \ '\bigl' 	: '\bigr', 
			    \ '\Bigl' 	: '\Bigr', 
			    \ '\biggl' 	: '\biggr' , 
			    \ '\Biggl' 	: '\Biggr', 
			    \ '\big'	: '\big',
			    \ '\Big'	: '\Big',
			    \ '\bigg'	: '\bigg',
			    \ '\Bigg'	: '\Bigg',
			    \ '\' 	: '\',
			    \ }
   " the last one is not a size of a bracket is to a hack to close \(:\), \[:\] and
   " \{:\}
endif
if !exists("g:atp_bracket_dict")
    let g:atp_bracket_dict = { '(' : ')', '{' : '}', '[' : ']' }
endif
" }}}2 			variables
if !exists("g:atp_LatexBox")
    let g:atp_LatexBox		= 1
endif
if !exists("g:atp_check_if_LatexBox")
    let g:atp_check_if_LatexBox	= 1
endif
if !exists("g:atp_autex_check_if_closed")
    let g:atp_autex_check_if_closed = 1
endif
if !exists("g:rmcommand") && executable("perltrash")
    let g:rmcommand="perltrash"
elseif !exists("g:rmcommand")
    let g:rmcommand		= "rm"
endif
if !exists("g:atp_env_maps_old")
    let g:atp_env_maps_old	= 0
endif
if !exists("g:atp_amsmath")
    let g:atp_amsmath=atplib#SearchPackage('ams')
endif
if !exists("g:atp_no_math_command_completion")
    let g:atp_no_math_command_completion = 0
endif
if !exists("g:atp_tex_extensions")
    let g:atp_tex_extensions	= ["aux", "log", "bbl", "blg", "spl", "snm", "nav", "thm", "brf", "out", "toc", "mpx", "idx", "ind", "ilg", "maf", "blg", "glo", "mtc[0-9]", "mtc1[0-9]", "pdfsync"]
endif
if !exists("g:atp_delete_output")
    let g:atp_delete_output	= 0
endif
if !exists("g:keep")
    let g:keep=[ "log", "aux", "toc", "bbl", "ind", "pdfsync" ]
endif
if !exists("g:printingoptions")
    let g:printingoptions	= ''
endif
if !exists("g:atp_ssh")
    let g:atp_ssh=substitute(system("whoami"),'\n','','') . "@localhost"
endif
" opens bibsearch results in vertically split window.
if !exists("g:vertical")
    let g:vertical		= 1
endif
if !exists("g:matchpair")
    let g:matchpair="(:),[:],{:}"
endif
if !exists("g:texmf")
    let g:texmf			= $HOME . "/texmf"
endif
if !exists("g:atp_compare_embedded_comments") || g:atp_compare_embedded_comments != 1
    let g:atp_compare_embedded_comments  = 0
endif
if !exists("g:atp_compare_double_empty_lines") || g:atp_compare_double_empty_lines != 0
    let g:atp_compare_double_empty_lines = 1
endif
"TODO: put toc_window_with and labels_window_width into DOC file
if !exists("t:toc_window_width")
    if exists("g:toc_window_width")
	let t:toc_window_width	= g:toc_window_width
    else
	let t:toc_window_width	= 30
    endif
endif
if !exists("t:atp_labels_window_width")
    if exists("g:labels_window_width")
	let t:atp_labels_window_width=g:labels_window_width
    else
	let t:atp_labels_window_width = 30
    endif
endif
if !exists("g:atp_completion_limits")
    let g:atp_completion_limits	= [40,60,80,120]
endif
if !exists("g:atp_long_environments")
    let g:atp_long_environments	= []
endif
if !exists("g:atp_no_complete")
     let g:atp_no_complete	= ['document']
endif
" if !exists("g:atp_close_after_last_closed")
"     let g:atp_close_after_last_closed=1
" endif
if !exists("g:atp_no_env_maps")
    let g:atp_no_env_maps	= 0
endif
if !exists("g:atp_extra_env_maps")
    let g:atp_extra_env_maps	= 0
endif
" todo: to doc. Now they go first.
" if !exists("g:atp_math_commands_first")
"     let g:atp_math_commands_first=1
" endif
if !exists("g:atp_completion_truncate")
    let g:atp_completion_truncate	= 4
endif
" ToDo: to doc.
" add server call back (then automatically reads errorfiles)
if !exists("g:atp_statusNotif")
    if has('clientserver') && !empty(v:servername) 
	let g:atp_statusNotif	= 1
    else
	let g:atp_statusNotif	= 0
    endif
endif
if !exists("g:atp_statusNotifHi")
    let g:atp_statusNotifHi	= 0
endif
if !exists("g:atp_callback")
    if exists("g:atp_status_notification") && g:atp_status_notification == 1
	let g:atp_callback	= 1
    elseif has('clientserver') && !empty(v:servername) 
	let g:atp_callback	= 1
    else
	let g:atp_callback	= 0
    endif
endif
" ToDo: to doc.
" I switched this off.
" if !exists("g:atp_complete_math_env_first")
"     let g:atp_complete_math_env_first=0
" endif
" }}}

" Buffer Local Variables:
" {{{ buffer variables
let b:atp_running	= 0

" these are all buffer related variables:
let s:optionsDict= { 	"atp_TexOptions" 	: "", 		
	        \ "atp_ReloadOnError" 		: "1", 
		\ "atp_OpenViewer" 		: "1", 		
		\ "atp_autex" 			: "1", 
		\ "atp_History"			: "1",
		\ "atp_Viewer" 			: has("unix") ? "xpdf" : "AcroRd32.exe" , 	
		\ "atp_TexFlavor" 		: &l:filetype, 
		\ "atp_XpdfServer" 		: fnamemodify(expand("%"),":t"), 
		\ "atp_OutDir" 			: substitute(fnameescape(fnamemodify(resolve(expand("%:p")),":h")) . "/", '\\\s', ' ' , 'g'),
		\ "atp_TexCompiler" 		: &filetype == "plaintex" ? "pdftex" : "pdflatex",	
		\ "atp_auruns"			: "1",
		\ "atp_TruncateStatusSection"	: "40", 
		\ "atp_LastBibPattern"		: "" }

" the above atp_OutDir is not used! the function s:SetOutDir() is used, it is just to
" remember what is the default used by s:SetOutDir().

" This function sets options (values of buffer related variables) which were
" not already set by the user.
" {{{ s:SetOptions
function! s:SetOptions()

    let s:optionsKeys		= keys(s:optionsDict)
    let s:optionsinuseDict	= getbufvar(bufname("%"),"")

    "for each key in s:optionsKeys set the corresponding variable to its default
    "value unless it was already set in .vimrc file.
    for l:key in s:optionsKeys
	if string(get(s:optionsinuseDict,l:key, "optionnotset")) == string("optionnotset") && l:key != "atp_OutDir" && l:key != "atp_autex"
	    call setbufvar(bufname("%"),l:key,s:optionsDict[l:key])
	elseif l:key == "atp_OutDir"

	    " set b:atp_OutDir and the value of errorfile option
	    if !exists("b:atp_OutDir")
		call s:SetOutDir(1)
	    endif
	    let s:ask["ask"] 	= 1
	endif
    endfor
    " Do not run tex on tex files which are in texmf tree
    " Exception: if it is opened using the command ':EditInputFile'
    " 		 which sets this itself.
    if string(get(s:optionsinuseDict,"atp_autex", 'optionnotset')) == string('optionnotset')
	let atp_texinputs=split(substitute(substitute(system("kpsewhich -show-path tex"),'\/\/\+','\/','g'),'!\|\n','','g'),':')
	call remove(atp_texinputs, '.')
	call filter(atp_texinputs, 'v:val =~ b:atp_OutDir')
	if len(l:atp_texinputs) == 0
	    let b:atp_autex	= 1
	else
	    let b:atp_autex	= 0
	endif
    endif
endfunction
"}}}
call s:SetOptions()

"}}}

" This is to be extended into a nice function which shows the important options
" and alows to reconfigure atp
"{{{ ShowOptions
let s:file	= expand('<sfile>:p')
function! s:ShowOptions(bang,...)

    let pattern	= a:0 >= 1 ? a:1 : ".*,"
    let mlen	= max(map(copy(keys(s:optionsDict)), "len(v:val)"))

    echo "Local buffer variables:"
    redraw
    for key in keys(s:optionsDict)
	let space = ""
	for s in range(mlen-len(key)+1)
	    let space .= " "
	endfor
	if "b:".key =~ pattern
" 	    if patn != '' && "b:".key !~ patn
	    echo "b:".key.space.getbufvar(bufnr(""), key)
" 	    endif
	endif
    endfor
    if a:bang == "!"
" 	Show some global options
	echo "\n"
	echo "Global variables (defined in ".s:file."):"
	let saved_loclist	= getloclist(0)
	    execute "lvimgrep /^\\s*let\\s\\+g:/j " . fnameescape(s:file)
	let global_vars		= getloclist(0)
	call setloclist(0, saved_loclist)
	let var_list		= []

	for var in global_vars
	    let var_name	= matchstr(var['text'], '^\s*let\s\+\zsg:\S*\ze\s*=')
	    if len(var_name) 
		call add(var_list, var_name)
	    endif
	endfor

	" Filter only matching variables that exists!
	call filter(var_list, 'count(var_list, v:val) == 1 && exists(v:val)')
	let mlen	= max(map(copy(var_list), "len(v:val)"))
	for var_name in var_list
	    let space = ""
	    for s in range(mlen-len(var_name)+1)
		let space .= " "
	    endfor
	    if var_name =~ pattern && var_name !~ '_command\|_amsfonts\|ams_negations\|tikz_\|keywords'
" 		if patn != '' && var_name !~ patn
		echo var_name.space.string({var_name})
" 		endif
	    endif
	endfor

    endif
endfunction
command! -buffer -bang -nargs=* ShowOptions		:call <SID>ShowOptions(<q-bang>, <q-args>)
"}}}

" Debug Mode Variables:
" {{{ Debug Mode
let t:atp_DebugMode	= g:atp_DefaultDebugMode 
" there are three possible values of t:atp_DebugMode
" 	silent/normal/debug
let t:atp_QuickFixOpen	= 0

if !s:did_options
    augroup ATP_DebugMode
	au FileType *.tex let t:atp_DebugMode	= g:atp_DefaultDebugMode
	" When opening the quickfix error buffer:  
	au FileType qf 	let t:atp_QuickFixOpen=1
	" When closing the quickfix error buffer (:close, :q) also end the Debug Mode.
	au FileType qf 	au BufUnload <buffer> let t:atp_DebugMode = g:atp_DefaultDebugMode | let t:atp_QuickFixOpen = 0
	au FileType qf	setl nospell
    augroup END
endif
"}}}

" These are two functions which sets options for Xpdf and Xdvi. 
" {{{ Xpdf, Xdvi
" xdvi - supports forward and reverse searching
" {{{ SetXdvi
fun! SetXdvi()

    " Remove menu entries
    let Compiler		= get(g:CompilerMsg_Dict, matchstr(b:atp_TexCompiler, '^\s*\S*'), 'Compiler')
    let Viewer			= get(g:ViewerMsg_Dict, matchstr(b:atp_Viewer, '^\s*\S*'), 'View\ Output')
    try
	execute "unmenu LaTeX.".Compiler
	execute "unmenu LaTeX.".Compiler."\\ debug"
	execute "unmenu LaTeX.".Compiler."\\ twice"
	execute "unmenu LaTeX.View\\ with\\ ".Viewer
    catch /E329: No menu/
    endtry

    " Set new options:
    let b:atp_TexCompiler	= "latex "
    let b:atp_TexOptions	= " -src-specials "
    let b:atp_Viewer="xdvi " . " -editor '" . v:progname . " --servername " . v:servername . " --remote-wait +%l %f'" 
    " Set Reverse Search Function.
    if !exists("*RevSearch")
    function! RevSearch()
	let dvi_file	= fnameescape(fnamemodify(b:atp_MainFile,":p:r") . ".dvi")
	if !filereadable(dvi_file)
	   echomsg "dvi file doesn't exist" 
	   ViewOutput RevSearch
	   return
	endif

	let options = (exists("g:atp_xdviOptions") ? g:atp_xdviOptions : "" ) . getbufvar(bufnr(""), "atp_xdviOptions")
	let g:options	= options

	let b:xdvi_reverse_search="xdvi " . options . 
		\ " -editor '" . v:progname . " --servername " . v:servername . 
		\ " --remote-wait +%l %f' -sourceposition " . 
		\ line(".") . ":" . col(".") . fnameescape(fnamemodify(expand("%"),":p")) . 
		\ " " . dvi_file
	call system(b:xdvi_reverse_search)
    endfunction
    endif
    " Set Reverse Search Command and Map.
    command! -buffer RevSearch 					:call RevSearch()
    map <buffer> <LocalLeader>rs				:call RevSearch()<CR>
    try
	nmenu 550.65 &LaTeX.Reverse\ Search<Tab>:map\ <LocalLeader>rs	:RevSearch<CR>
    catch /E329: No menu/
    endtry

    " Put new menu entries:
    let Compiler	= get(g:CompilerMsg_Dict, matchstr(b:atp_TexCompiler, '^\s*\zs\S*'), 'Compile')
    let Viewer		= get(g:ViewerMsg_Dict, matchstr(b:atp_Viewer, '^\s*\zs\S*'), "View\\ Output")
    execute "nmenu 550.5 &LaTeX.&".Compiler."<Tab>:TEX			:TEX<CR>"
    execute "nmenu 550.6 &LaTeX.".Compiler."\\ debug<Tab>:TEX\\ debug 	:DTEX<CR>"
    execute "nmenu 550.7 &LaTeX.".Compiler."\\ &twice<Tab>:2TEX		:2TEX<CR>"
    execute "nmenu 550.10 LaTeX.&View\\ with\\ ".Viewer."<Tab>:ViewOutput 		:ViewOutput<CR>"
endfun
command! -buffer SetXdvi			:call SetXdvi()
nnoremap <silent> <buffer> <Plug>SetXdvi	:call SetXdvi()<CR>
" }}}

" xpdf - supports server option (we use the reoding mechanism, which allows to
" copy the output file but not reload the viewer if there were errors during
" compilation (b:atp_ReloadOnError variable)
" {{{ SetXpdf
fun! SetXpdf()

    " Remove menu entries.
    let Compiler		= get(g:CompilerMsg_Dict, matchstr(b:atp_TexCompiler, '^\s*\S*'), 'Compiler')
    let Viewer			= get(g:ViewerMsg_Dict, matchstr(b:atp_Viewer, '^\s*\S*'), 'View\ Output')
    try 
	execute "unmenu LaTeX.".Compiler
	execute "unmenu LaTeX.".Compiler."\\ debug"
	execute "unmenu LaTeX.".Compiler."\\ twice"
	execute "unmenu LaTeX.View\\ with\\ ".Viewer
    catch /E329: No menu/
    endtry

    let b:atp_TexCompiler	= "pdflatex"
    " We have to clear tex options (for example -src-specials set by :SetXdvi)
    let b:atp_TexOptions	= ""
    let b:atp_Viewer		= "xpdf"
    " Remove the maps \rs.
    if hasmapto("RevSearch()",'n')
	unmap <buffer> <LocalLeader>rs
    endif
    " Delete command.
    if exists("RevSearch")
	delcommand RevSearch
    endif
    " Delete menu entry.
    try
	silent aunmenu LaTeX.Reverse\ Search
    catch /E329: No menu/
    endtry

    " Put new menu entries:
    let Compiler	= get(g:CompilerMsg_Dict, matchstr(b:atp_TexCompiler, '^\s*\zs\S*'), 'Compile')
    let Viewer		= get(g:ViewerMsg_Dict, matchstr(b:atp_Viewer, '^\s*\zs\S*'), 'View\ Output')
    execute "nmenu 550.5 &LaTeX.&".Compiler.	"<Tab>:TEX			:TEX<CR>"
    execute "nmenu 550.6 &LaTeX." .Compiler.	"\\ debug<Tab>:TEX\\ debug 	:DTEX<CR>"
    execute "nmenu 550.7 &LaTeX." .Compiler.	"\\ &twice<Tab>:2TEX		:2TEX<CR>"
    execute "nmenu 550.10 LaTeX.&View\\ with\\ ".Viewer.	"<Tab>:ViewOutput 		:ViewOutput<CR>"
endfun
command! -buffer SetXpdf			:call SetXpdf()
nnoremap <silent> <buffer> <Plug>SetXpdf	:call SetXpdf()<CR>
" }}}
" }}}

" These are functions which toggles some of the options:
"{{{ Toggle Functions
if !s:did_options
" {{{ ToggleAuTeX
" command! -buffer -count=1 TEX	:call TEX(<count>)		 
function! ATP_ToggleAuTeX()
  if b:atp_autex != 1
    let b:atp_autex=1	
    echo "automatic tex processing is ON"
    silent! aunmenu LaTeX.Toggle\ AuTeX\ [off]
    silent! aunmenu LaTeX.Toggle\ AuTeX\ [on]
    menu 550.75 &LaTeX.&Toggle\ AuTeX\ [on]<Tab>b:atp_autex	:<C-U>ToggleAuTeX<CR>
    cmenu 550.75 &LaTeX.&Toggle\ AuTeX\ [on]<Tab>b:atp_autex	<C-U>ToggleAuTeX<CR>
    imenu 550.75 &LaTeX.&Toggle\ AuTeX\ [on]<Tab>b:atp_autex	<ESC>:ToggleAuTeX<CR>a
  else
    let b:atp_autex=0
    silent! aunmenu LaTeX.Toggle\ AuTeX\ [off]
    silent! aunmenu LaTeX.Toggle\ AuTeX\ [on]
    menu 550.75 &LaTeX.&Toggle\ AuTeX\ [off]<Tab>b:atp_autex	:<C-U>ToggleAuTeX<CR>
    cmenu 550.75 &LaTeX.&Toggle\ AuTeX\ [off]<Tab>b:atp_autex	<C-U>ToggleAuTeX<CR>
    imenu 550.75 &LaTeX.&Toggle\ AuTeX\ [off]<Tab>b:atp_autex	<ESC>:ToggleAuTeX<CR>a
    echo "automatic tex processing is OFF"
  endif
endfunction
command! -buffer 	ToggleAuTeX 		:call ATP_ToggleAuTeX()
nnoremap <silent> <Plug>ToggleAuTeX 		:call ATP_ToggleAuTeX()<CR>
"}}}
" {{{ ToggleSpace
" Special Space for Searching 
let s:special_space="[off]"
function! ATP_ToggleSpace()
    if maparg('<space>','c') == ""
	echomsg "special space is on"
	cmap <Space> \_s\+
	let s:special_space="[on]"
	silent! aunmenu LaTeX.Toggle\ Space\ [off]
	silent! aunmenu LaTeX.Toggle\ Space\ [on]
	menu 550.78 &LaTeX.&Toggle\ Space\ [on]<Tab>cmap\ <space>\ \\_s\\+	:<C-U>ToggleSpace<CR>
	cmenu 550.78 &LaTeX.&Toggle\ Space\ [on]<Tab>cmap\ <space>\ \\_s\\+	<C-U>ToggleSpace<CR>
	imenu 550.78 &LaTeX.&Toggle\ Space\ [on]<Tab>cmap\ <space>\ \\_s\\+	<Esc>:ToggleSpace<CR>a
	tmenu &LaTeX.&Toggle\ Space\ [on] cmap <space> \_s\+ is curently on
    else
	echomsg "special space is off"
 	cunmap <Space>
	let s:special_space="[off]"
	silent! aunmenu LaTeX.Toggle\ Space\ [on]
	silent! aunmenu LaTeX.Toggle\ Space\ [off]
	menu 550.78 &LaTeX.&Toggle\ Space\ [off]<Tab>cmap\ <space>\ \\_s\\+	:<C-U>ToggleSpace<CR>
	cmenu 550.78 &LaTeX.&Toggle\ Space\ [off]<Tab>cmap\ <space>\ \\_s\\+	<C-U>ToggleSpace<CR>
	imenu 550.78 &LaTeX.&Toggle\ Space\ [off]<Tab>cmap\ <space>\ \\_s\\+	<Esc>:ToggleSpace<CR>a
	tmenu &LaTeX.&Toggle\ Space\ [off] cmap <space> \_s\+ is curently off
    endif
endfunction
command! -buffer 	ToggleSpace 	:call ATP_ToggleSpace()
nnoremap <silent> <Plug>ToggleSpace 	:call ATP_ToggleSpace()<CR>
"}}}
" {{{ ToggleCheckMathOpened
" This function toggles if ATP is checking if editing a math mode.
" This is used by insert completion.
" ToDo: to doc.
function! ATP_ToggleCheckMathOpened()
    if g:atp_MathOpened
	echomsg "check if in math environment is off"
	silent! aunmenu LaTeX.Toggle\ Check\ if\ in\ Math\ [on]
	silent! aunmenu LaTeX.Toggle\ Check\ if\ in\ Math\ [off]
	menu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [off]<Tab>g:atp_MathOpened			
		    \ :<C-U>ToggleCheckMathOpened<CR>
	cmenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [off]<Tab>g:atp_MathOpened			
		    \ <C-U>ToggleCheckMathOpened<CR>
	imenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [off]<Tab>g:atp_MathOpened			
		    \ <Esc>:ToggleCheckMathOpened<CR>a
    else
	echomsg "check if in math environment is on"
	silent! aunmenu LaTeX.Toggle\ Check\ if\ in\ Math\ [off]
	silent! aunmenu LaTeX.Toggle\ Check\ if\ in\ Math\ [off]
	menu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [on]<Tab>g:atp_MathOpened
		    \ :<C-U>ToggleCheckMathOpened<CR>
	cmenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [on]<Tab>g:atp_MathOpened
		    \ <C-U>ToggleCheckMathOpened<CR>
	imenu 550.79 &LaTeX.Toggle\ &Check\ if\ in\ Math\ [on]<Tab>g:atp_MathOpened
		    \ <Esc>:ToggleCheckMathOpened<CR>a
    endif
    let g:atp_MathOpened=!g:atp_MathOpened
endfunction
command! -buffer 	ToggleCheckMathOpened 	:call ATP_ToggleCheckMathOpened()
nnoremap <silent> <Plug>ToggleCheckMathOpened	:call ATP_ToggleCheckMathOpened()<CR>
"}}}
" {{{ ToggleCallBack
function! ATP_ToggleCallBack()
    if g:atp_callback
	echomsg "call back is off"
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [on]
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [off]
	menu 550.80 &LaTeX.Toggle\ &Call\ Back\ [off]<Tab>g:atp_callback	
		    \ :<C-U>call ToggleCallBack()<CR>
	cmenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [off]<Tab>g:atp_callback	
		    \ <C-U>call ToggleCallBack()<CR>
	imenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [off]<Tab>g:atp_callback	
		    \ <Esc>:call ToggleCallBack()<CR>a
    else
	echomsg "call back is on"
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [on]
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [off]
	menu 550.80 &LaTeX.Toggle\ &Call\ Back\ [on]<Tab>g:atp_callback
		    \ :call ToggleCallBack()<CR>
	cmenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [on]<Tab>g:atp_callback
		    \ <C-U>call ToggleCallBack()<CR>
	imenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [on]<Tab>g:atp_callback
		    \ <Esc>:call ToggleCallBack()<CR>a
    endif
    let g:atp_callback=!g:atp_callback
endfunction
command! -buffer 	ToggleCallBack 		:call ATP_ToggleCallBack()
nnoremap <silent> <Plug>ToggleCallBack		:call ATP_ToggleCallBack()<CR>
"}}}
" {{{ ToggleDebugMode
" ToDo: to doc.
" TODO: it would be nice to have this command (and the map) in quickflist (FileType qf)
" describe DEBUG MODE in doc properly.
function! ATP_ToggleDebugMode()
"     call ToggleCallBack()
    if t:atp_DebugMode == "debug"
	echomsg "debug mode is off"

	silent! aunmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [on]
	silent! aunmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [off]
	menu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [off]<Tab>t:atp_DebugMode			
		    \ :<C-U>ToggleDebugMode<CR>
	cmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [off]<Tab>t:atp_DebugMode			
		    \ <C-U>ToggleDebugMode<CR>
	imenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [off]<Tab>t:atp_DebugMode			
		    \ <Esc>:ToggleDebugMode<CR>a

	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [on]
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [off]
	menu 550.80 &LaTeX.Toggle\ &Call\ Back\ [off]<Tab>g:atp_callback	
		    \ :<C-U>ToggleDebugMode<CR>
	cmenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [off]<Tab>g:atp_callback	
		    \ <C-U>ToggleDebugMode<CR>
	imenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [off]<Tab>g:atp_callback	
		    \ <Esc>:ToggleDebugMode<CR>a

	let t:atp_DebugMode	= g:atp_DefaultDebugMode
	silent cclose
    else
	echomsg "debug mode is on"

	silent! aunmenu 550.20.5 LaTeX.Log.Toggle\ Debug\ Mode\ [off]
	silent! aunmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [on]
	menu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [on]<Tab>t:atp_DebugMode
		    \ :<C-U>ToggleDebugMode<CR>
	cmenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [on]<Tab>t:atp_DebugMode
		    \ <C-U>ToggleDebugMode<CR>
	imenu 550.20.5 &LaTeX.&Log.Toggle\ &Debug\ Mode\ [on]<Tab>t:atp_DebugMode
		    \ <Esc>:ToggleDebugMode<CR>a

	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [on]
	silent! aunmenu LaTeX.Toggle\ Call\ Back\ [off]
	menu 550.80 &LaTeX.Toggle\ &Call\ Back\ [on]<Tab>g:atp_callback	
		    \ :<C-U>ToggleDebugMode<CR>
	cmenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [on]<Tab>g:atp_callback	
		    \ <C-U>ToggleDebugMode<CR>
	imenu 550.80 &LaTeX.Toggle\ &Call\ Back\ [on]<Tab>g:atp_callback	
		    \ <Esc>:ToggleDebugMode<CR>a

	let g:atp_callback=1
	let t:atp_DebugMode	= "debug"
	silent copen
    endif
endfunction
command! -buffer 	ToggleDebugMode 	:call ATP_ToggleDebugMode()
nnoremap <silent> <Plug>ToggleDebugMode		:call ATP_ToggleDebugMode()<CR>
if !s:did_options
    augroup ATP_DebugModeCommandsAndMaps
	au FileType qf command! -buffer ToggleDebugMode 	:call <SID>ToggleDebugMode()
	au FileType qf nnoremap <silent> <LocalLeader>D		:ToggleDebugMode<CR>
    augroup END
endif
" }}}
" {{{ ToggleTab
" switches on/off the <Tab> map for TabCompletion
function! ATP_ToggleTab() 
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
command! -buffer 	ToggleTab	 	:call ATP_ToggleTab()
nnoremap <silent> <Plug>ToggleTab		:call ATP_ToggleTab()<CR>
inoremap <silent> <Plug>ToggleTab		<Esc>:call ATP_ToggleTab()<CR>
" }}}
endif
"}}}

" Tab Completion Variables:
" {{{ TAB COMPLETION variables
" ( functions are in autoload/atplib.vim )
"
if !exists("g:atp_History")
    let g:atp_History = 1
endif
if !exists("g:atp_completion_modes")
    let g:atp_completion_modes=[ 
		\ 'commands', 			'labels', 		
		\ 'tikz libraries', 		'environment names',
		\ 'close environments' , 	'brackets',
		\ 'input files',		'bibstyles',
		\ 'bibitems', 			'bibfiles',
		\ 'documentclass',		'tikzpicture commands',
		\ 'tikzpicture',		'tikzpicture keywords',
		\ 'package names',		'font encoding',
		\ 'font family',		'font series',
		\ 'font shape' ]
    lockvar g:atp_completion_modes
endif

if !exists("g:atp_completion_modes_normal_mode")
    let g:atp_completion_modes_normal_mode=[ 
		\ 'close environments' , 	'brackets' ]
    lockvar g:atp_completion_modes_normal_mode
endif

" By defualt all completion modes are ative.
if !exists("g:atp_completion_active_modes")
    let g:atp_completion_active_modes=deepcopy(g:atp_completion_modes)
endif
if !exists("g:atp_completion_active_modes_normal_mode")
    let g:atp_completion_active_modes_normal_mode=deepcopy(g:atp_completion_modes_normal_mode)
endif

if !exists("g:atp_sort_completion_list")
    let g:atp_sort_completion_list = 12
endif

" Note: to remove completions: 'inline_math' or 'displayed_math' one has to
" remove also: 'close_environments' /the function atplib#CloseLastEnvironment can
" close math instead of an environment/.

" ToDo: make list of complition commands from the input files.
" ToDo: make complition fot \cite, and for \ref and \eqref commands.

" ToDo: there is second such a list! line 3150
	let g:atp_Environments=['array', 'abstract', 'center', 'corollary', 
		\ 'definition', 'document', 'description', 'displaymath',
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
		    \ 'proposition' 	: 'prop', 	'definition' 	: 'defi',
		    \ 'lemma' 		: 'lem',	'array' 	: 'ar',
		    \ 'abstract' 	: 'no_short_name',
		    \ 'tikzpicture' 	: 'tikz',	'tabular' 	: 'table',
		    \ 'table' 		: 'table', 	'proof' 	: 'pr',
		    \ 'corollary' 	: 'cor',	'enumerate' 	: 'enum',
		    \ 'example' 	: 'ex',		'itemize' 	: 'it',
		    \ 'item'		: 'itm',
		    \ 'remark' 		: 'rem',	'notation' 	: 'not',
		    \ 'center' 		: '', 		'flushright' 	: '',
		    \ 'flushleft' 	: '', 		'quotation' 	: 'quot',
		    \ 'quot' 		: 'quot',	'tabbing' 	: '',
		    \ 'picture' 	: 'pic',	'minipage' 	: '',	
		    \ 'list' 		: 'list',	'figure' 	: 'fig',
		    \ 'verbatim' 	: 'verb', 	'verse' 	: 'verse',
		    \ 'thebibliography' : '',		'document' 	: 'no_short_name',
		    \ 'titlepave' 	: '', 		'align' 	: 'eq',
		    \ 'alignat' 	: 'eq',		'equation' 	: 'eq',
		    \ 'gather'  	: 'eq', 	'multiline' 	: '',
		    \ 'split'		: 'eq', 	'substack' 	: '',
		    \ 'flalign' 	: 'eq',		'displaymath' 	: 'eq',
		    \ 'part'		: 'prt',	'chapter' 	: 'chap',
		    \ 'section' 	: 'sec',	'subsection' 	: 'ssec',
		    \ 'subsubsection' 	: 'sssec', 	'paragraph' 	: 'par',
		    \ 'subparagraph' 	: 'spar' }

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
	let g:atp_Commands=["\\begin{", "\\end{", 
	\ "\\cite{", "\\nocite{", "\\ref{", "\\pageref{", "\\eqref{", "\\item",
	\ "\\emph{", "\\documentclass{", "\\usepackage{",
	\ "\\section{", "\\subsection{", "\\subsubsection{", "\\part{", 
	\ "\\chapter{", "\\appendix", "\\subparagraph", "\\paragraph",
	\ "\\textbf{", "\\textsf{", "\\textrm{", "\\textit{", "\\texttt{", 
	\ "\\textsc{", "\\textsl{", "\\textup{", "\\textnormal", "\\textcolor{",
	\ "\\bfseries", "\\mdseries", "\\bigskip", "\\bibitem",
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
	\ "\\medskip", "\\smallskip", "\\vskip", "\\vfil", "\\vfill", "\\vspace{", 
	\ "\\hspace", "\\hrulefill", "\hfil", "\\hfill", "\\dotfill",
	\ "\\thispagestyle", "\\mathnormal", "\\markright", "\\pagestyle", "\\pagenumbering",
	\ "\\author{", "\\date{", "\\thanks{", "\\title{",
	\ "\\maketitle", "\\overbrace{", "\\overline", "\\underline{", "\\underbrace{",
	\ "\\marginpar", "\\indent", "\\par", "\\sloppy", "\\pagebreak", "\\nopagebreak",
	\ "\\newpage", "\\newline", "\\newtheorem{", "\\linebreak", "\\line", "\\hyphenation{", "\\fussy",
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
	\ "\\tableofcontents", "\\newfont{", "\\phantom",
	\ "\\DeclareRobustCommand", "\\show", "\\CheckCommand", "\\mathnormal" ]
	
	let g:atp_picture_commands=[ "\\put", "\\circle", "\\dashbox", "\\frame{", 
		    \"\\framebox(", "\\line(", "\\linethickness{",
		    \ "\\makebox(", "\\\multiput(", "\\oval(", "\\put", 
		    \ "\\shortstack", "\\vector(" ]

	" ToDo: end writting layout commands. 
	" ToDo: MAKE COMMANDS FOR PREAMBULE.

	let g:atp_math_commands=["\\forall", "\\exists", "\\emptyset", "\\aleph", "\\partial",
	\ "\\nabla", "\\Box", "\\bot", "\\top", "\\flat", "\\sharp",
	\ "\\mathbf{", "\\mathsf{", "\\mathrm{", "\\mathit{", "\\mathbb{", "\\mathtt{", "\\mathcal{", 
	\ "\\mathop{", "\\mathversion", "\\limits", "\\text{", "\\leqslant", "\\leq", "\\geqslant", "\\geq",
	\ "\\gtrsim", "\\lesssim", "\\gtrless", "\\left", "\\right", 
	\ "\\rightarrow", "\\Rightarrow", "\\leftarrow", "\\Leftarrow", "\\iff", 
	\ "\\leftrightarrow", "\\Leftrightarrow", "\\downarrow", "\\Downarrow", "\\Uparrow",
	\ "\\Longrightarrow", "\\longrightarrow", "\\Longleftarrow", "\\longleftarrow",
	\ "\\overrightarrow{", "\\overleftarrow{", "\\underrightarrow{", "\\underleftarrow{",
	\ "\\uparrow", "\\nearrow", "\\searrow", "\\swarrow", "\\nwarrow", 
	\ "\\hookrightarrow", "\\hookleftarrow", "\\gets", "\\backslash", 
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
	\ "\\hat", "\\grave", "\\bar", "\\acute", "\\mathring", "\\check", "\\dots", "\\dot", "\\vec", "\\breve",
	\ "\\tilde", "\\widetilde" , "\\widehat", "\\ddot", 
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
	\ "\\langle", "\\rangle", "\\Diamond"  ]

	" commands defined by the user in input files.
	" ToDo: to doc.
	" ToDo: this doesn't work with input files well enough. 
	
	" Returns a list of two lists:  [ commanad_names, enironment_names ]

	" The BufEnter augroup doesn't work with EditInputFile, but at least it works
	" when entering. Debuging shows that when entering new buffer it uses
	" wrong b:atp_MainFile, it is still equal to the bufername and not the
	" real main file. Maybe it is better to use s:mainfile variable.

	if !exists("g:atp_local_completion")
	    let g:atp_local_completion = 1
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
		    \ "\\precneq", "\\succneq", "\\precnapprox", "\\ltimes", "\\rtimes" ]

	let g:atp_ams_negations_non_expert_mode=[ "\\lneqq", "\\ngeqq", "\\nleqq", "\\ngeqq", "\\nsubseteqq", 
		    \ "\\nsupseteqq", "\\subsetneqq", "\\supsetneqq", "\\nsucceqq", "\\precneqq", "\\succneqq" ] 

	" ToDo: add more amsmath commands.
	let g:atp_amsmath_commands=[ "\\boxed", "\\intertext", "\\multiligngap", "\\shoveleft", "\\shoveright", "\\notag", "\\tag", 
		    \ "\\notag", "\\raistag{", "\\displaybreak", "\\allowdisplaybreaks", "\\numberwithin{",
		    \ "\\hdotsfor{" , "\\mspace{",
		    \ "\\negthinspace", "\\negmedspace", "\\negthickspace", "\\thinspace", "\\medspace", "\\thickspace",
		    \ "\\leftroot{", "\\uproot{", "\\overset{", "\\underset{", "\\sideset{", 
		    \ "\\dfrac{", "\\tfrac{", "\\cfrac{", "\\dbinom{", "\\tbinom{", "\\smash",
		    \ "\\lvert", "\\rvert", "\\lVert", "\\rVert", "\\DeclareMatchOperator{",
		    \ "\\arccos", "\\arcsin", "\\arg", "\\cos", "\\cosh", "\\cot", "\\coth", "\\csc", "\\deg", "\\det",
		    \ "\\dim", "\\exp", "\\gcd", "\\hom", "\\inf", "\\injlim", "\\ker", "\\lg", "\\lim", "\\liminf", "\\limsup",
		    \ "\\log", "\\min", "\\max", "\\Pr", "\\projlim", "\\sec", "\\sin", "\\sinh", "\\sup", "\\tan", "\\tanh",
		    \ "\\varlimsup", "\\varliminf", "\\varinjlim", "\\varprojlim", "\\mod", "\\bmod", "\\pmod", "\\pod", "\\sideset",
		    \ "\\iint", "\\iiint", "\\iiiint", "\\idotsint", "\\tag",
		    \ "\\varGamma", "\\varDelta", "\\varTheta", "\\varLambda", "\\varXi", "\\varPi", "\\varSigma", 
		    \ "\\varUpsilon", "\\varPhi", "\\varPsi", "\\varOmega" ]
	
	" ToDo: integrate in TabCompletion (amsfonts, euscript packages).
	let g:atp_amsfonts=[ "\\mathfrak{", "\\mathscr{" ]

	" not yet supported: in TabCompletion:
	let g:atp_amsextra_commands=[ "\\sphat", "\\sptilde" ]
	let g:atp_fancyhdr_commands=["\\lfoot{", "\\rfoot{", "\\rhead{", "\\lhead{", 
		    \ "\\cfoot{", "\\chead{", "\\fancyhead{", "\\fancyfoot{",
		    \ "\\fancypagestyle{", "\\fancyhf{}", "\\headrulewidth", "\\footrulewidth",
		    \ "\\rightmark", "\\leftmark", "\\markboth", 
		    \ "\\chaptermark", "\\sectionmark", "\\subsectionmark",
		    \ "\\fancyheadoffset", "\\fancyfootoffset", "\\fancyhfoffset"]

	let g:atp_makeidx_commands=[ "\\makeindex", "\\index{", "\\printindex" ]


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
	" ToDo: completion for arguments in brackets [] for tikz commands.
	let g:atp_tikz_commands=[ "\\begin", "\\end", "\\matrix", "\\node", "\\shadedraw", 
		    \ "\\draw", "\\tikz", "\\tikzset",
		    \ "\\path", "\\filldraw", "\\fill", "\\clip", "\\drawclip", "\\foreach", "\\angle", "\\coordinate",
		    \ "\\useasboundingbox", "\\tikztostart", "\\tikztotarget", "\\tikztonodes", "\\tikzlastnode",
		    \ "\\pgfextra", "\\endpgfextra", "\\verb", "\\coordinate", 
		    \ "\\pattern", "\\shade", "\\shadedraw", "\\colorlet", "\\definecolor" ]
	let g:atp_tikz_keywords=[ 'draw', 'node', 'matrix', 'anchor', 'top', 'bottom',  
		    \ 'west', 'east', 'north', 'south', 'at', 'thin', 'thick', 'semithick', 'rounded', 'corners',
		    \ 'controls', 'and', 'circle', 'step', 'grid', 'very', 'style', 'line', 'help',
		    \ 'color', 'arc', 'curve', 'scale', 'parabola', 'line', 'ellipse', 'bend', 'sin', 'rectangle', 'ultra', 
		    \ 'right', 'left', 'intersection', 'xshift', 'yshift', 'shift', 'near', 'start', 'above', 'below', 
		    \ 'end', 'sloped', 'coordinate', 'cap', 'shape', 'label', 'every', 
		    \ 'edge', 'point', 'loop', 'join', 'distance', 'sharp', 'rotate', 'blue', 'red', 'green', 'yellow', 
		    \ 'black', 'white', 'gray',
		    \ 'text', 'width', 'inner', 'sep', 'baseline', 'current', 'bounding', 'box', 
		    \ 'canvas', 'polar', 'radius', 'barycentric', 'angle', 'opacity', 
		    \ 'solid', 'phase', 'loosly', 'dashed', 'dotted' , 'densly', 
		    \ 'latex', 'diamond', 'double', 'smooth', 'cycle', 'coordinates', 'distance',
		    \ 'even', 'odd', 'rule', 'pattern', 
		    \ 'stars', 'shading', 'ball', 'axis', 'middle', 'outer', 'transorm',
		    \ 'fading', 'horizontal', 'vertical', 'light', 'dark', 'button', 'postaction', 'out',
		    \ 'circular', 'shadow', 'scope', 'borders', 'spreading', 'false', 'position' ]
	let g:atp_tikz_library_arrows_keywords	= [ 'reversed', 'stealth', 'triangle', 'open', 
		    \ 'hooks', 'round', 'fast', 'cap', 'butt'] 
	let g:atp_tikz_library_automata_keywords=[ 'state', 'accepting', 'initial', 'swap', 
		    \ 'loop', 'nodepart', 'lower', 'output']  
	let g:atp_tikz_library_backgrounds_keywords=[ 'background', 'show', 'inner', 'frame', 'framed',
		    \ 'tight', 'loose', 'xsep', 'ysep']

	" NEW:
	let g:atp_tikz_library_calendar_commands=[ '\calendar', '\tikzmonthtext' ]
	let g:atp_tikz_library_calendar_keywords=[ 'week list', 'dates', 'day', 'day list', 'month', 'year', 'execute', 
		    \ 'before', 'after', 'downward', 'upward' ]
	let g:atp_tikz_library_chain_commands=[ '\chainin' ]
	let g:atp_tikz_library_chain_keywords=[ 'chain', 'start chain', 'on chain', 'continue chain', 
		    \ 'start branch', 'branch', 'going', 'numbers', 'greek' ]
	let g:atp_tikz_library_decoration_commands=[ '\\arrowreversed' ]
	let g:atp_tikz_library_decoration_keywords=[ 'decorate', 'decoration', 'lineto', 'straight', 'zigzag',
		    \ 'saw', 'random steps', 'bent', 'aspect', 'bumps', 'coil', 'curveto', 'snake', 
		    \ 'border', 'brace', 'segment lenght', 'waves', 'ticks', 'expanding', 
		    \ 'crosses', 'triangles', 'dart', 'shape', 'width', 'size', 'sep', 'shape backgrounds', 
		    \ 'between', 'along', 'path', 
		    \ 'Koch curve type 1', 'Koch curve type 1', 'Koch snowflake', 'Cantor set', 'footprints',
		    \ 'foot',  'stride lenght', 'foot', 'foot', 'foot of', 'gnome', 'human', 
		    \ 'bird', 'felis silvestris', 'evenly', 'spread', 'scaled', 'star', 'height', 'text',
		    \ 'mark', 'reset', 'marks' ]
	let g:atp_tikz_library_er_keywords	= [ 'entity', 'relationship', 'attribute', 'key']
	let g:atp_tikz_library_fadings_keywords	= [ 'with', 'fuzzy', 'percent', 'ring' ]
	let g:atp_tikz_library_fit_keywords	= [ 'fit']
	let g:atp_tikz_library_matrix_keywords	= ['matrix', 'of', 'nodes', 'math', 'matrix of math nodes', 
		    \ 'matrix of nodes', 'delimiter', 
		    \ 'rmoustache', 'column sep=', 'row sep=' ] 
	let g:atp_tikz_library_mindmap_keywords	= [ 'mindmap', 'concept', 'large', 'huge', 'extra', 'root', 'level',
		    \ 'connection', 'bar', 'switch', 'annotation' ]
	let g:atp_tikz_library_folding_commands	= ["\\tikzfoldingdodecahedron"]
	let g:atp_tikz_library_folding_keywords	= ['face', 'cut', 'fold'] 
        let g:atp_tikz_library_patterns_keywords	= ['lines', 'fivepointed', 'sixpointed', 'bricks', 'checkerboard',
		    \ 'crosshatch', 'dots']
	let g:atp_tikz_library_petri_commands	= ["\\tokennumber" ]
        let g:atp_tikz_library_petri_keywords	= ['place', 'transition', 'pre', 'post', 'token', 'child', 'children', 
		    \ 'are', 'tokens', 'colored', 'structured' ]
	let g:atp_tikz_library_pgfplothandlers_commands	= ["\\pgfplothandlercurveto", "\\pgfsetplottension",
		    \ "\\pgfplothandlerclosedcurve", "\\pgfplothandlerxcomb", "\\pgfplothandlerycomb",
		    \ "\\pgfplothandlerpolarcomb", "\\pgfplothandlermark{", "\\pgfsetplotmarkpeat{", 
		    \ "\\pgfsetplotmarkphase", "\\pgfplothandlermarklisted{", "\\pgfuseplotmark", 
		    \ "\\pgfsetplotmarksize{", "\\pgfplotmarksize" ]
        let g:atp_tikz_library_plotmarks_keywords	= [ 'asterisk', 'star', 'oplus', 'oplus*', 'otimes', 'otimes*', 
		    \ 'square', 'square*', 'triangle', 'triangle*', 'diamond', 'diamond*', 'pentagon', 'pentagon*']

if !exists("g:atp_MathOpened")
    let g:atp_MathOpened = 1
endif
" augroup ATP_MathOpened
"     au!
"     au Syntax tex :let g:atp_MathOpened = 1
" augroup END

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
	    \ ['\\begin{equation', '\\end{equatio\zsn'],
	    \ ['\\begin{\%(display\)\?math', '\\end{\%(display\)\?mat\zsh'] ] 
" ToDo: user command list, env list g:atp_Commands, g:atp_Environments, 
" }}}

" Some of the autocommands (Status Line, LocalCommands, Log File):
" {{{ Autocommands:


if !s:did_options

    augroup ATP_updatetime
	au VimEnter if &l:updatetime == 4000 | let &l:updatetime	= 800 | endif
	au InsertEnter *.tex let s:updatetime=&l:updatetime | let &l:updatetime = g:atp_insert_updatetime
	au InsertLeave *.tex let &l:updatetime=s:updatetime 
    augroup END

    if (exists("g:atp_statusline") && g:atp_statusline == '1') || !exists("g:atp_statusline")
	augroup ATP_Status
	    au!
	    au BufWinEnter *.tex 	call ATPStatus("")
	augroup END
    endif

    if g:atp_local_completion == 2 
	augroup ATP_LocaCommands
	    au!
	    au BufEnter *.tex 	call LocalCommands()
	augroup END
    endif

    augroup ATP_TeXFlavor
	au!
	au FileType *tex 	let b:atp_TexFlavor = &filetype
    augroup END
    " Idea:
    " au 		*.log if LogBufferFileDiffer | silent execute '%g/^\s*$/d' | w! | endif
    " or maybe it is better to do that after latex made the log file in the call back
    " function, but this adds something to every compilation process !
    " This changes the cursor position in the log file which is NOT GOOD.
"     au WinEnter	*.log	execute "normal m'" | silent execute '%g/^\s*$/d' | execute "normal ''"

    " Experimental:
	" This doesn't work !
" 	    let g:debug=0
" 	    fun! GetSynStackI()
" 		let synstack=[]
" 		let synstackI=synstack(line("."), col("."))
" 		try 
" 		    let test =  synstackI == 0
" 		    let b:return 	= 1
" 		    catch /Can only compare List with List/
" 		    let b:return	= 0
" 		endtry
" 		if b:return == 0
" 		    return []
" 		else
" 		    let g:debug+= 1
" 		    return map(synstack, "synIDattr(v:val, 'name')")
" 		endif
" 	    endfunction

    " The first one is not working! (which is the more important of these two :(
"     au CursorMovedI *.tex let g:atp_synstackI	= GetSynStackI()
    " This has problems in visual mode:
"     au CursorMoved  *.tex let g:atp_synstack	= map(synstack(line('.'), col('.')), "synIDattr(v:val, 'name')")
    
endif
" }}}

" This function and the following autocommand toggles the textwidth option if
" editting a math mode. Currently, supported are $:$, \(:\), \[:\] and $$:$$.
" {{{  SetMathVimOptions

if !exists("g:atp_SetMathVimOptions")
    let g:atp_SetMathVimOptions 	= 1
endif

if !exists("g:atp_MathVimOptions")
"     { 'option_name' : [ val_in_math, normal_val], ... }
    let g:atp_MathVimOptions 		=  { 'textwidth' 	: [ 0, 	&textwidth],
						\ }
endif

let g:atp_MathZones	= [ 
	    		\ 'texMathZoneV', 	'texMathZoneW', 
	    		\ 'texMathZoneX', 	'texMathZoneY',
	    		\ 'texMathZoneA', 	'texMathZoneAS',
	    		\ 'texMathZoneB', 	'texMathZoneBS',
	    		\ 'texMathZoneC', 	'texMathZoneCS',
	    		\ 'texMathZoneD', 	'texMathZoneDS',
	    		\ 'texMathZoneE', 	'texMathZoneES',
	    		\ 'texMathZoneF', 	'texMathZoneFS',
	    		\ 'texMathZoneG', 	'texMathZoneGS',
	    		\ 'texMathZoneH', 	'texMathZoneHS',
	    		\ 'texMathZoneI', 	'texMathZoneIS',
	    		\ 'texMathZoneJ', 	'texMathZoneJS',
	    		\ 'texMathZoneK', 	'texMathZoneKS',
	    		\ 'texMathZoneL', 	'texMathZoneLS' 
			\ ]

" a:0 	= 0 check if in math mode
" a:1   = 0 assume cursor is not in math
" a:1	= 1 assume cursor stands in math  
function! s:SetMathVimOptions(...)

	if !g:atp_SetMathVimOptions
	    return "no setting to toggle" 
	endif

	let MathZones = copy(g:atp_MathZones)
	if b:atp_TexFlavor == 'plaintex'
	    call add(MathZones, 'texMathZoneY')
	endif
	    
	" Change the long values to numbers 
	let MathVimOptions = map(copy(g:atp_MathVimOptions),
			\ " v:val[0] =~ v:key ? [ v:val[0] =~ 'no' . v:key ? 0 : 1, v:val[1] ] : v:val " )
	let MathVimOptions = map(MathVimOptions,
			\ " v:val[1] =~ v:key ? [ v:val[0], v:val[1] =~ 'no' . v:key ? 0 : 1 ] : v:val " )

	" check if the current (and 3 steps back) cursor position is in math
	" or use a:1
	let check	= a:0 == 0 ? atplib#CheckSyntaxGroups(MathZones) + atplib#CheckSyntaxGroups(MathZones, line("."), max([ 1, col(".")-3])) : a:1

	if check
	    for option_name in keys(MathVimOptions)
		execute "let &l:".option_name. " = " . MathVimOptions[option_name][0]
	    endfor
	else
	    for option_name in keys(MathVimOptions)
		execute "let &l:".option_name. " = " . MathVimOptions[option_name][1]
	    endfor
	endif

endfunction

if !s:did_options

    augroup ATP_SetMathVimOptions
	au!
	" if leaving the insert mode set the non-math options
	au InsertLeave 	*.tex 	:call s:SetMathVimOptions(0)
	" if entering the insert mode or in the insert mode check if the cursor is in
	" math or not and set the options acrodingly
	au InsertEnter	*.tex 	:call s:SetMathVimOptions()
	au CursorMovedI *.tex 	:call s:SetMathVimOptions()
	" This slows down vim when moving the cursor:
	" au CursorMoved *.tex :call s:SetMathVimOptions()
    augroup END

endif
"}}}

" Add extra syntax groups
" {{{1 ATP_SyntaxGroups
function! s:ATP_SyntaxGroups()
    if atplib#SearchPackage('tikz') || atplib#SearchPackage('pgfplots')
	try
	    call TexNewMathZone("T", "tikzpicture", 0)
	catch /E117/
	endtry
    endif
endfunction

augroup ATP_Syntax_TikzZone
    au Syntax tex :call <SID>ATP_SyntaxGroups()
augroup END

augroup ATP_Devel
    au BufEnter *.sty	:setl nospell	
    au BufEnter *.cls	:setl nospell
    au BufEnter *.fd	:setl nospell
augroup END
"}}}1

"{{{1 Highlightings in help file
augroup ATP_HelpFile_Highlight
au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_FileName') ? "atp_FileName" : "Title",  'highlight atp_FileName\s\+Title')
au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_LineNr') 	? "atp_LineNr"   : "LineNr", 'highlight atp_LineNr\s\+LineNr')
au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_Number') 	? "atp_Number"   : "Number", 'highlight atp_Number\s\+Number')
au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_Chapter') 	? "atp_Chapter"  : "Label",  'highlight atp_Chapter\s\+Label')
au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_Section') 	? "atp_Section"  : "Label",  'highlight atp_Section\s\+Label')
au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_SubSection') ? "atp_SubSection": "Label", 'highlight atp_SubSection\s\+Label')
au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_Abstract')	? "atp_Abstract" : "Label", 'highlight atp_Abstract\s\+Label')

au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_label_FileName') 	? "atp_label_FileName" 	: "Title",	'^\s*highlight atp_label_FileName\s\+Title\s*$')
au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_label_LineNr') 	? "atp_label_LineNr" 	: "LineNr",	'^\s*highlight atp_label_LineNr\s\+LineNr\s*$')
au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_label_Name') 	? "atp_label_Name" 	: "Label",	'^\s*highlight atp_label_Name\s\+Label\s*$')
au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('atp_label_Counter') 	? "atp_label_Counter" 	: "Keyword",	'^\s*highlight atp_label_Counter\s\+Keyword\s*$')

au BufEnter automatic-tex-plugin.txt call matchadd(hlexists('bibsearchInfo')	? "bibsearchInfo"	: "Number",	'^\s*highlight bibsearchInfo\s*$')
augroup END
"}}}1

" {{{1 :Viewer, :Compiler, :DebugMode
function! s:Viewer(viewer) 
    let old_viewer	= b:atp_Viewer
    let oldViewer	= get(g:ViewerMsg_Dict, matchstr(old_viewer, '^\s*\zs\S*'), "")
    let b:atp_Viewer	= a:viewer
    let Viewer		= get(g:ViewerMsg_Dict, matchstr(b:atp_Viewer, '^\s*\zs\S*'), "")
    silent! execute "aunmenu LaTeX.View\\ with\\ ".oldViewer
    silent! execute "aunmenu LaTeX.View\\ Output"
    if Viewer != ""
	execute "menu 550.10 LaTe&X.&View\\ with\\ ".Viewer."<Tab>:ViewOutput 		:<C-U>ViewOutput<CR>"
	execute "cmenu 550.10 LaTe&X.&View\\ with\\ ".Viewer."<Tab>:ViewOutput 		<C-U>ViewOutput<CR>"
	execute "imenu 550.10 LaTe&X.&View\\ with\\ ".Viewer."<Tab>:ViewOutput 		<Esc>:ViewOutput<CR>a"
    else
	execute "menu 550.10 LaTe&X.&View\\ Output\\ <Tab>:ViewOutput 		:<C-U>ViewOutput<CR>"
	execute "cmenu 550.10 LaTe&X.&View\\ Output\\ <Tab>:ViewOutput 		<C-U>ViewOutput<CR>"
	execute "imenu 550.10 LaTe&X.&View\\ Output\\ <Tab>:ViewOutput 		<Esc>:ViewOutput<CR>a"
    endif
endfunction
command! -buffer -nargs=1 -complete=customlist,ViewerComp Viewer	:call <SID>Viewer(<q-args>)
function! ViewerComp(A,L,P)
    let view = [ 'okular', 'xpdf', 'xdvi', 'evince', 'epdfview', 'kpdf', 'acroread' ]
    call filter(view, "v:val =~ '^' . a:A")
    call filter(view, 'executable(v:val)')
    return view
endfunction

function! s:Compiler(compiler) 
    let old_compiler	= b:atp_TexCompiler
    let oldCompiler	= get(g:CompilerMsg_Dict, matchstr(old_compiler, '^\s*\zs\S*'), "")
    let b:atp_TexCompiler	= a:compiler
    let Compiler		= get(g:CompilerMsg_Dict, matchstr(b:atp_TexCompiler, '^\s*\zs\S*'), "")
    silent! execute "aunmenu LaTeX.".oldCompiler
    silent! execute "aunmenu LaTeX.".oldCompiler."\\ debug"
    silent! execute "aunmenu LaTeX.".oldCompiler."\\ twice"
    execute "menu 550.5 LaTe&X.&".Compiler."<Tab>:TEX				:<C-U>TEX<CR>"
    execute "cmenu 550.5 LaTe&X.&".Compiler."<Tab>:TEX				<C-U>TEX<CR>"
    execute "imenu 550.5 LaTe&X.&".Compiler."<Tab>:TEX				<Esc>:TEX<CR>a"
    execute "menu 550.6 LaTe&X.".Compiler."\\ debug<Tab>:TEX\\ debug		:<C-U>DTEX<CR>"
    execute "cmenu 550.6 LaTe&X.".Compiler."\\ debug<Tab>:TEX\\ debug		<C-U>DTEX<CR>"
    execute "imenu 550.6 LaTe&X.".Compiler."\\ debug<Tab>:TEX\\ debug		<Esc>:DTEX<CR>a"
    execute "menu 550.7 LaTe&X.".Compiler."\\ &twice<Tab>:2TEX			:<C-U>2TEX<CR>"
    execute "cmenu 550.7 LaTe&X.".Compiler."\\ &twice<Tab>:2TEX			<C-U>2TEX<CR>"
    execute "imenu 550.7 LaTe&X.".Compiler."\\ &twice<Tab>:2TEX			<Esc>:2TEX<CR>a"
endfunction
command! -buffer -nargs=1 -complete=customlist,CompilerComp Compiler	:call <SID>Compiler(<q-args>)
function! CompilerComp(A,L,P)
    let compilers = [ 'tex', 'pdftex', 'latex', 'pdflatex', 'etex', 'xetex', 'luatex' ]
"     let g:compilers = copy(compilers)
    call filter(compilers, "v:val =~ '^' . a:A")
    call filter(compilers, 'executable(v:val)')
    return compilers
endfunction

command! -buffer -nargs=1 -complete=customlist,DebugComp DebugMode	:let t:atp_DebugMode=<q-args>
function! DebugComp(A,L,P)
    let modes = [ 'silent', 'debug', 'verbose']
    call filter(modes, "v:val =~ '^' . a:A")
    return modes
endfunction
"}}}1
" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
