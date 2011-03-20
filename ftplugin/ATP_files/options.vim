" Author: 	Marcin Szamotulski	
" Description: 	This file contains all the options defined on startup of ATP
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" URL:		https://launchpad.net/automatictexplugin
" Language:	tex
" Last Change:

" NOTE: you can add your local settings to ~/.atprc.vim or
" ftplugin/ATP_files/atprc.vim file

" Some options (functions) should be set once:
let s:did_options 	= exists("s:did_options") ? 1 : 0

let g:atp_reload	= 0
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

" ATP Debug Variables: (to debug atp behaviour)
" {{{ debug variables
if !exists("g:atp_debugML")
    " debug MakeLatex (compiler.vim)
    let g:atp_debugML	= 0
endif
if !exists("g:atp_debugGAF")
    " debug aptlib#GrepAuxFile
    let g:atp_debugGAF	= 0
endif
if !exists("g:atp_debugSCP")
    " debug s:SelectCurrentParapgrahp (LatexBox_motion.vim)
    let g:atp_debugSCP	= 0
endif
if !exists("g:atp_debugSIT")
    " debug <SID>SearchInTree (search.vim)
    let g:atp_debugSIT		= 0
endif
if !exists("g:atp_debugSync")
    " debug forward search (vim->viewer) (search.vim)
    let g:atp_debugSync		= 0
endif
if !exists("g:atp_debugV")
    " debug ViewOutput() (compiler.vim)
    let g:atp_debugV		= 0
endif
if !exists("g:atp_debugLPS")
    " Debug s:LoadProjectFile() (history.vim)
    " (currently it gives just the loading time info)
    let g:atp_debugLPS		= 0
endif
if !exists("g:atp_debugCompiler")
    " Debug s:Compiler() function (compiler.vim)
    " when equal 2 output is more verbose.
    let g:atp_debugCompiler 	= 0
endif
if !exists("g:atp_debugST")
    " Debug <SID>CallBack() function (compiler.vim)
    let g:atp_debugCallBack	= 0
endif
if !exists("g:atp_debugST")
    " Debug SyncTex() (various.vim) function
    let g:atp_debugST 		= 0
endif
if !exists("g:atp_debugCLE")
    " Debug atplib#CloseLastEnvironment()
    let g:atp_debugCLE 		= 0
endif
if !exists("g:atp_debugMainScript")
    " loading times of scripts sources by main script file: ftpluing/tex_atp.vim
    " NOTE: it is listed here for completeness, it can only be set in
    " ftplugin/tex_atp.vim script file.
    let g:atp_debugMainScript 	= 0
endif

if !exists("g:atp_debugProject")
    " <SID>LoadScript(), <SID>LoadProjectScript(), <SID>WriteProject()
    " The value that is set in history file matters!
    let g:atp_debugProject 	= 0
endif
if !exists("g:atp_debugCB")
    " atplib#CheckBracket()
    let g:atp_debugCB 		= 0
endif
if !exists("g:atp_debugCLB")
    " atplib#CloseLastBracket()
    let g:atp_debugCLB 		= 0
endif
if !exists("g:atp_debugTC")
    " atplib#TabCompletion()
    let g:atp_debugTC 		= 0
endif
if !exists("g:atp_debugBS")
    " atplib#searchbib()
    " atplib#showresults()
    " BibSearch() in ATP_files/search.vim
    " log file: /tmp/ATP_log 
    let g:atp_debugBS 		= 0
endif
if !exists("g:atp_debugToF")
    " TreeOfFiles() ATP_files/common.vim
    let g:atp_debugToF 		= 0
endif
if !exists("g:atp_debgTOF")
    " TreeOfFiles() redirect only the output to
    " /tmp/ATP_log
    let g:atp_debugTOF 		= 0
endif
if !exists("g:atp_debugBabel")
    " echo msg if  babel language is not supported.
    let g:atp_debugBabel 	= 0
endif
"}}}

" vim options + indentation
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

setl nrformats=alpha
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
	    \ . '\|DeclareFixedFont\s*{\s*'
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

" Buffer Local Variables:
" {{{ buffer variables
let b:atp_running	= 0

" these are all buffer related variables:
let s:optionsDict= { 	
		\ "atp_TexOptions" 		: "-synctex=1", 
	        \ "atp_ReloadOnError" 		: "1", 
		\ "atp_OpenViewer" 		: "1", 		
		\ "atp_autex" 			: !&l:diff && expand("%:e") == 'tex', 
		\ "atp_ProjectScript"		: "1",
		\ "atp_Viewer" 			: has("win26") || has("win32") || has("win64") || has("win95") || has("win32unix") ? "AcroRd32.exe" : "okular" , 
		\ "atp_TexFlavor" 		: &l:filetype, 
		\ "atp_XpdfServer" 		: fnamemodify(b:atp_MainFile,":t:r"), 
		\ "atp_OutDir" 			: substitute(fnameescape(fnamemodify(resolve(expand("%:p")),":h")) . "/", '\\\s', ' ' , 'g'),
		\ "atp_TmpDir"			: substitute(b:atp_OutDir . "/.tmp", '\/\/', '\/', 'g'),
		\ "atp_TexCompiler" 		: &filetype == "plaintex" ? "pdftex" : "pdflatex",	
		\ "atp_TexCompilerVariable"	: "max_print_line=2000",
		\ "atp_auruns"			: "1",
		\ "atp_TruncateStatusSection"	: "40", 
		\ "atp_LastBibPattern"		: "" }

let g:optionsDict=deepcopy(s:optionsDict)
" the above atp_OutDir is not used! the function s:SetOutDir() is used, it is just to
" remember what is the default used by s:SetOutDir().

" This function sets options (values of buffer related variables) which were
" not already set by the user.
" {{{ s:SetOptions
let s:ask = { "ask" : "0" }
function! s:SetOptions()

    let s:optionsKeys		= keys(s:optionsDict)
    let s:optionsinuseDict	= getbufvar(bufname("%"),"")

    "for each key in s:optionsKeys set the corresponding variable to its default
    "value unless it was already set in .vimrc file.
    for key in s:optionsKeys
	if string(get(s:optionsinuseDict,key, "optionnotset")) == string("optionnotset") && key != "atp_OutDir" && key != "atp_autex" || key == "atp_TexCompiler"
	    call setbufvar(bufname("%"), key, s:optionsDict[key])
	elseif key == "atp_OutDir"

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
	call remove(atp_texinputs, index(atp_texinputs, '.'))
	call filter(atp_texinputs, 'b:atp_OutDir =~# v:val')
	let b:atp_autex = ( len(atp_texinputs) ? 0 : s:optionsDict['atp_autex'])  
    endif

    if !exists("b:TreeOfFiles") || !exists("b:ListOfFiles") || !exists("b:TypeDict") || !exists("b:LevelDict")
	if exists("b:atp_MainFile") 
	    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)
	    call TreeOfFiles(atp_MainFile)
	else
	    echomsg "b:atp_MainFile " . "doesn't exists."
	endif
    endif
endfunction
"}}}
call s:SetOptions()

"}}}

" Global Variables: (almost all)
" {{{ global variables 
if !exists("g:atp_cpcmd") || g:atp_reload
    " This will avoid using -i switch which might be defined in an alias file. 
    " This doesn't make much harm, but it might be better. 
    let g:atp_cpcmd="/bin/cp"
endif
" Variables for imaps, standard environment names:
    if !exists("g:atp_EnvNameTheorem") || g:atp_reload
	let g:atp_EnvNameTheorem="theorem"
    endif
    if !exists("g:atp_EnvNameDefinition") || g:atp_reload
	let g:atp_EnvNameDefinition="definition"
    endif
    if !exists("g:atp_EnvNameProposition") || g:atp_reload
	let g:atp_EnvNameProposition="proposition"
    endif
    if !exists("g:atp_EnvNameObservation") || g:atp_reload
	" This mapping is defined only in old layout:
	" i.e. if g:atp_env_maps_old == 1
	let g:atp_EnvNameObservation="observation"
    endif
    if !exists("g:atp_EnvNameLemma") || g:atp_reload
	let g:atp_EnvNameLemma="lemma"
    endif
    if !exists("g:atp_EnvNameNote") || g:atp_reload
	let g:atp_EnvNameNote="note"
    endif
    if !exists("g:atp_EnvNameCorollary") || g:atp_reload
	let g:atp_EnvNameCorollary="corollary"
    endif
    if !exists("g:atp_EnvNameRemark") || g:atp_reload
	let g:atp_EnvNameRemark="remark"
    endif
if !exists("g:atp_StarEnvDefault") || g:atp_reload
    " Values are "" or "*". 
    " It will be added to enrionemnt names which support it.
    let g:atp_StarEnvDefault=""
endif
if !exists("g:atp_StarMathEnvDefault") || g:atp_reload
    " Values are "" or "*". 
    " It will be added to enrionemnt names which support it.
    let g:atp_StarMathEnvDefault=""
endif
if !exists("g:atp_EnvOptions_enumerate") || g:atp_reload
    " add options to \begin{enumerate} for example [topsep=0pt,noitemsep] Then the
    " enumerate map <Leader>E will put \begin{enumerate}[topsep=0pt,noitemsep] Useful
    " options of enumitem to make enumerate more condenced.
    let g:atp_EnvOptions_enumerate=""
endif
if !exists("g:atp_EnvOptions_itemize") || g:atp_reload
    " Similar to g:atp_enumerate_options.
    let g:atp_EnvOptions_itemize=""
endif
if !exists("g:atp_VimCompatible") || g:atp_reload
    " Used by: % (s:JumpToMatch in LatexBox_motion.vim).
    let g:atp_VimCompatible = "no"
    " It can be 0/1 or yes/no.
endif 
if !exists("g:atp_CupsOptions") || g:atp_reload
    " lpr command options for completion of SshPrint command.
    let g:atp_CupsOptions = [ 'landscape=', 'scaling=', 'media=', 'sides=', 'Collate=', 'orientation-requested=', 
		\ 'job-sheets=', 'job-hold-until=', 'page-ragnes=', 'page-set=', 'number-up=', 'page-border=', 
		\ 'number-up-layout=', 'fitplot=', 'outputorder=', 'mirror=', 'raw=', 'cpi=', 'columns=',
		\ 'page-left=', 'page-right=', 'page-top=', 'page-bottom=', 'prettyprint=', 'nowrap=', 'position=',
		\ 'natural-scaling=', 'hue=', 'ppi=', 'saturation=', 'blackplot=', 'penwidth=']
endif
if !exists("g:atp_lprcommand") || g:atp_reload
    " Used by :SshPrint
    let g:atp_lprcommand = "lpr"
endif 
if !exists("g:atp_iabbrev_leader") || g:atp_reload
    " Used for abbreviations: =theorem= (from both sides).
    let g:atp_iabbrev_leader = "="
endif 
if !exists("g:atp_bibrefRegister") || g:atp_reload
    " A register to which bibref obtained from AMS will be copied.
    let g:atp_bibrefRegister = "0"
endif
if !exists("g:atpbib_pathseparator") || g:atp_reload
    if has("win16") || has("win32") || has("win64") || has("win95")
	let g:atpbib_pathseparator = "\\"
    else
	let g:atpbib_pathseparator = "/"
    endif 
endif
if !exists("g:atpbib_WgetOutputFile") || g:atp_reload
    let g:atpbib_WgetOutputFile = "amsref.html"
endif
if !exists("g:atpbib_wget") || g:atp_reload
    let g:atpbib_wget="wget"
endif
if !exists("g:atp_vmap_text_font_leader") || g:atp_reload
    let g:atp_vmap_text_font_leader="<LocalLeader>"
endif
if !exists("g:atp_vmap_environment_leader") || g:atp_reload
    let g:atp_vmap_environment_leader="<LocalLeader>"
endif
if !exists("g:atp_vmap_bracket_leader") || g:atp_reload
    let g:atp_vmap_bracket_leader="<LocalLeader>"
endif
if !exists("g:atp_vmap_big_bracket_leader") || g:atp_reload
    let g:atp_vmap_big_bracket_leader='<LocalLeader>b'
endif
if !exists("g:atp_map_forward_motion_leader") || g:atp_reload
    let g:atp_map_forward_motion_leader='>'
endif
if !exists("g:atp_map_backward_motion_leader") || g:atp_reload
    let g:atp_map_backward_motion_leader='<'
endif
if !exists("g:atp_RelativePath") || g:atp_reload
    " This is here only for completness, the default value is set in project.vim
    let g:atp_RelativePath 	= 1
endif
if !exists("g:atp_SyncXpdfLog") || g:atp_reload
    let g:atp_SyncXpdfLog 	= 0
endif
if !exists("g:atp_LogSync") || g:atp_reload
    let g:atp_LogSync 		= 0
endif

	function! s:Sync(...)
	    let arg = ( a:0 >=1 ? a:1 : "" )
	    if arg == "on"
		let g:atp_LogSync = 1
	    elseif arg == "off"
		let g:atp_LogSync = 0
	    else
		let g:atp_LogSync = !g:atp_LogSync
	    endif
	    echomsg "g:atp_LogSync = " . g:atp_LogSync
	endfunction
	command! -buffer -nargs=? -complete=customlist,s:SyncComp LogSync :call s:Sync(<f-args>)
	function! s:SyncComp(ArgLead, CmdLine, CursorPos)
	    return filter(['on', 'off'], "v:val =~ a:ArgLead") 
	endfunction

if !exists("g:atp_Compare") || g:atp_reload
    " Use b:changedtick variable to run s:Compiler automatically.
    let g:atp_Compare = "changedtick"
endif
if !exists("g:atp_babel") || g:atp_reload 
    let g:atp_babel = 0
endif
" if !exists("g:atp_closebracket_checkenv") || g:atp_reload
    " This is a list of environment names. They will be checked by
    " atplib#CloseLastBracket() function (if they are opened/closed:
    " ( \begin{array} ... <Tab>       will then close first \begin{array} and then ')'
    try
	let g:atp_closebracket_checkenv	= [ 'array' ]
	" Changing this variable is not yet supported *see ToDo: in
	" atplib#CloseLastBracket() (autoload/atplib.vim)
	lockvar g:atp_closebracket_checkenv
    catch /E741:/
" 	echomsg "Changing this variable is not supported"
    endtry
" endif
" if !exists("g:atp_ProjectScript") || g:atp_reload
"     let g:atp_ProjectScript = 1
" endif
if !exists("g:atp_OpenTypeDict") || g:atp_reload
    let g:atp_OpenTypeDict = { 
		\ "pdf" 	: "xpdf",		"ps" 	: "evince",
		\ "djvu" 	: "djview",		"txt" 	: "split" ,
		\ "tex"		: "edit",		"dvi"	: "xdvi -s 5" }
    " for txt type files supported viewers: cat, gvim = vim = tabe, split, edit
endif
if !exists("g:atp_LibraryPath") || g:atp_reload
    let g:atp_LibraryPath	= 0
endif
if !exists("g:atp_statusOutDir") || g:atp_reload
    let g:atp_statusOutDir 	= 1
endif
if !exists("g:atp_developer") || g:atp_reload
    let g:atp_developer		= 0
endif
if !exists("g:atp_mapNn") || g:atp_reload
	let g:atp_mapNn		= 0 " This value is used only on startup, then :LoadHistory sets the default value.
endif  				    " user cannot change the value set by :LoadHistory on startup in atprc file.
" 				    " Unless using: 
" 				    	au VimEnter *.tex let b:atp_mapNn = 0
" 				    " Recently I changed this: in project files it is
" 				    better to start with atp_mapNn = 0 and let the
" 				    user change it. 
if !exists("g:atp_TeXdocDefault") || g:atp_reload
    let g:atp_TeXdocDefault	= '-a -I lshort'
endif
"ToDo: to doc.
"ToDo: luatex! (can produce both!)
if !exists("g:atp_CompilersDict") || g:atp_reload
    let g:atp_CompilersDict 	= { 
		\ "pdflatex" 	: ".pdf", 	"pdftex" 	: ".pdf", 
		\ "xetex" 	: ".pdf", 	"latex" 	: ".dvi", 
		\ "tex" 	: ".dvi",	"elatex"	: ".dvi",
		\ "etex"	: ".dvi", 	"luatex"	: ".pdf"}
endif

if !exists("g:CompilerMsg_Dict") || g:atp_reload
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

if !exists("g:ViewerMsg_Dict") || g:atp_reload
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
if !exists("g:atp_insert_updatetime") || g:atp_reload
    let g:atp_insert_updatetime = max([ 2000, &l:updatetime])
endif
if !exists("g:atp_DefaultDebugMode") || g:atp_reload
    " recognised values: silent, debug.
    let g:atp_DefaultDebugMode	= "silent"
endif
if !exists("g:atp_show_all_lines") || g:atp_reload
    " boolean
    let g:atp_show_all_lines 	= 0
endif
if !exists("g:atp_ignore_unmatched") || g:atp_reload
    " boolean
    let g:atp_ignore_unmatched 	= 1
endif
if !exists("g:atp_imap_first_leader") || g:atp_reload
    let g:atp_imap_first_leader	= "#"
endif
if !exists("g:atp_imap_second_leader") || g:atp_reload
    let g:atp_imap_second_leader= "##"
endif
if !exists("g:atp_imap_third_leader") || g:atp_reload
    let g:atp_imap_third_leader	= "]"
endif
if !exists("g:atp_imap_fourth_leader") || g:atp_reload
    let g:atp_imap_fourth_leader= "["
endif
" todo: to doc.
if !exists("g:atp_completion_font_encodings") || g:atp_reload
    let g:atp_completion_font_encodings	= ['T1', 'T2', 'T3', 'T5', 'OT1', 'OT2', 'OT4', 'UT1']
endif
" todo: to doc.
if !exists("g:atp_font_encoding") || g:atp_reload
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
if !exists("g:atp_sizes_of_brackets") || g:atp_reload
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
if !exists("g:atp_algorithmic_dict") || g:atp_reload
    let g:atp_algorithmic_dict = { 'IF' : 'ENDIF', 'FOR' : 'ENDFOR', 'WHILE' : 'ENDWHILE' }
endif
if !exists("g:atp_bracket_dict") || g:atp_reload
    let g:atp_bracket_dict = { '(' : ')', '{' : '}', '[' : ']', '\lceil' : '\rceil', '\lfloor' : '\rfloor', '\langle' : '\rangle', '\lgroup' : '\rgroup' }
endif
if !exists("g:atp_LatexBox") || g:atp_reload
    let g:atp_LatexBox		= 1
endif
if !exists("g:atp_check_if_LatexBox") || g:atp_reload
    let g:atp_check_if_LatexBox	= 1
endif
if !exists("g:atp_autex_check_if_closed") || g:atp_reload
    let g:atp_autex_check_if_closed = 1
endif
if ( !exists("g:rmcommand") || g:atp_reload ) && executable("perltrash")
    let g:rmcommand="perltrash"
elseif !exists("g:rmcommand") || g:atp_reload   
    let g:rmcommand		= "rm"
endif
if !exists("g:atp_env_maps_old") || g:atp_reload
    let g:atp_env_maps_old	= 0
endif
if !exists("g:atp_amsmath") || g:atp_reload
    let g:atp_amsmath=atplib#SearchPackage('ams')
endif
if !exists("g:atp_no_math_command_completion") || g:atp_reload
    let g:atp_no_math_command_completion = 0
endif
if !exists("g:atp_tex_extensions") || g:atp_reload
    let g:atp_tex_extensions	= ["tex.project.vim", "aux", "log", "bbl", "blg", "spl", "snm", "nav", "thm", "brf", "out", "toc", "mpx", "idx", "ind", "ilg", "maf", "glo", "mtc[0-9]", "mtc1[0-9]", "pdfsync", "synctex.gz" ]
endif
if !exists("g:atp_delete_output") || g:atp_reload
    let g:atp_delete_output	= 0
endif
if !exists("g:keep") || g:atp_reload
    let g:keep=[ "log", "aux", "toc", "bbl", "ind", "pdfsync", "synctex.gz" ]
endif
if !exists("g:atp_ssh") || g:atp_reload
    let g:atp_ssh=substitute(system("whoami"),'\n','','') . "@localhost"
endif
" opens bibsearch results in vertically split window.
if !exists("g:vertical") || g:atp_reload
    let g:vertical		= 1
endif
if !exists("g:matchpair") || g:atp_reload
    let g:matchpair="(:),[:],{:}"
endif
if !exists("g:texmf") || g:atp_reload
    let g:texmf			= $HOME . "/texmf"
endif
if !exists("g:atp_compare_embedded_comments") || g:atp_reload || g:atp_compare_embedded_comments != 1
    let g:atp_compare_embedded_comments  = 0
endif
if !exists("g:atp_compare_double_empty_lines") || g:atp_reload || g:atp_compare_double_empty_lines != 0
    let g:atp_compare_double_empty_lines = 1
endif
"TODO: put toc_window_with and labels_window_width into DOC file
if !exists("t:toc_window_width") || g:atp_reload
    if exists("g:toc_window_width")
	let t:toc_window_width	= g:toc_window_width
    else
	let t:toc_window_width	= 30
    endif
endif
if !exists("t:atp_labels_window_width") || g:atp_reload
    if exists("g:labels_window_width")
	let t:atp_labels_window_width = g:labels_window_width
    else
	let t:atp_labels_window_width = 30
    endif
endif
if !exists("g:atp_completion_limits") || g:atp_reload
    let g:atp_completion_limits	= [40,60,80,120]
endif
if !exists("g:atp_long_environments") || g:atp_reload
    let g:atp_long_environments	= []
endif
if !exists("g:atp_no_complete") || g:atp_reload
     let g:atp_no_complete	= ['document']
endif
" if !exists("g:atp_close_after_last_closed") || g:atp_reload
"     let g:atp_close_after_last_closed=1
" endif
if !exists("g:atp_no_env_maps") || g:atp_reload
    let g:atp_no_env_maps	= 0
endif
if !exists("g:atp_extra_env_maps") || g:atp_reload
    let g:atp_extra_env_maps	= 0
endif
" todo: to doc. Now they go first.
" if !exists("g:atp_math_commands_first") || g:atp_reload
"     let g:atp_math_commands_first=1
" endif
if !exists("g:atp_completion_truncate") || g:atp_reload
    let g:atp_completion_truncate	= 4
endif
" ToDo: to doc.
" add server call back (then automatically reads errorfiles)
if !exists("g:atp_statusNotif") || g:atp_reload
    if has('clientserver') && !empty(v:servername) 
	let g:atp_statusNotif	= 1
    else
	let g:atp_statusNotif	= 0
    endif
endif
if !exists("g:atp_statusNotifHi") || g:atp_reload
    let g:atp_statusNotifHi	= 0
endif
if !exists("g:atp_callback") || g:atp_reload
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
" if !exists("g:atp_complete_math_env_first") || g:atp_reload
"     let g:atp_complete_math_env_first=0
" endif
" }}}

" Project Settings:
" {{{1
if !exists("g:atp_ProjectLocalVariables") || g:atp_reload
    " This is a list of variable names which will be preserved in project files
    let g:atp_ProjectLocalVariables = [
		\ "b:atp_MainFile", 	"g:atp_mapNn", 		"b:atp_autex", 
		\ "b:atp_TexCompiler", 	"b:atp_TexFlavor", 	"b:atp_OutDir" , 
		\ "b:atp_auruns", 	"b:atp_ReloadOnErr", 	"b:atp_OpenViewer", 
		\ "b:atp_XpdfServer",	"b:atp_ProjectDir", 	"b:atp_Viewer"
		\ ] 
endif
" the variable a:1 is the name of the variable which stores the list of variables to
" save.
function! SaveProjectVariables(...)
    let variables_List	= ( a:0 >= 1 ? {a:1} : g:atp_ProjectLocalVariables )
    let variables_Dict 	= {}
    for var in variables_List
	if exists(var)
	    call extend(variables_Dict, { var : {var} })
	endif
    endfor
    return variables_Dict
endfunction
function! RestoreProjectVariables(variables_Dict)
    for var in keys(a:variables_Dict)
 	let g:cmd =  "let " . var . "=" . string(a:variables_Dict[var])
" 	echo g:cmd
	exe "let " . var . "=" . string(a:variables_Dict[var])
    endfor
endfunction
" }}}1

" This is to be extended into a nice function which shows the important options
" and allows to reconfigure atp
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

" Babel
" {{{1 variables
if !exists("g:atp_keymaps") || g:atp_reload
let g:atp_keymaps = { 
		\ 'british'	: 'ignore',		'english' 	: 'ignore',
		\ 'USenglish'	: 'ignore', 		'UKenglish'	: 'ignore',
		\ 'american'	: 'ignore',
	    	\ 'bulgarian' 	: 'bulgarian-bds', 	'croatian' 	: 'croatian',
		\ 'czech'	: 'czech',		'greek'		: 'greek',
		\ 'plutonikogreek': 'greek',		'hebrew'	: 'hebrew',
		\ 'russian' 	: 'russian-jcuken',	'serbian' 	: 'serbian',
		\ 'slovak' 	: 'slovak', 		'ukrainian' 	: 'ukrainian-jcuken',
		\ 'polish' 	: 'polish-slash' }
else "extend the existing dictionary with default values not ovverriding what is defind:
    for lang in [ 'croatian', 'czech', 'greek', 'hebrew', 'serbian', 'slovak' ] 
	call extend(g:atp_keymaps, { lang : lang }, 'keep')
    endfor
    call extend(g:atp_keymaps, { 'british' 	: 'ignore' }, 		'keep')
    call extend(g:atp_keymaps, { 'american' 	: 'ignore' }, 		'keep')
    call extend(g:atp_keymaps, { 'english' 	: 'ignore' }, 		'keep')
    call extend(g:atp_keymaps, { 'UKenglish' 	: 'ignore' }, 		'keep')
    call extend(g:atp_keymaps, { 'USenglish' 	: 'ignore' }, 		'keep')
    call extend(g:atp_keymaps, { 'bulgarian' 	: 'bulgarian-bds' }, 	'keep')
    call extend(g:atp_keymaps, { 'plutonikogreek' : 'greek' }, 		'keep')
    call extend(g:atp_keymaps, { 'russian' 	: 'russian-jcuken' }, 	'keep')
    call extend(g:atp_keymaps, { 'ukrainian' 	: 'ukrainian-jcuken' },	'keep')
endif

" {{{1 function
function! <SID>Babel()
    " Todo: make notification.
    if &filetype != "tex" || !exists("b:atp_MainFile") || !has("keymap")
	" This only works for LaTeX documents.
	" but it might work for plain tex documents as well!
	return
    endif
    let atp_MainFile	= atplib#FullPath(b:atp_MainFile)

    let saved_loclist = getloclist(0)
    try
	execute '1lvimgrep /^[^%]*\\usepackage.*{babel}/j ' . fnameescape(atp_MainFile)
	" Find \usepackage[babel_options]{babel} - this is the only way that one can
	" pass options to babel.
    catch /E480:/
	return
    catch /E683:/ 
	return
    endtry
    let babel_line 	= get(get(getloclist(0), 0, {}), 'text', '')
    call setloclist(0, saved_loclist) 
    let languages	= split(matchstr(babel_line, '\[\zs[^]]*\ze\]'), ',')
    if len(languages) == 0
	return
    endif
    let default_language 	= get(languages, '-1', '') 
	if g:atp_debugBabel
	    echomsg "Babel : defualt language:" . default_language
	endif
    let keymap 			= get(g:atp_keymaps, default_language, '')

    if keymap == ''
	if g:atp_debugBabel
	    echoerr "No keymap in g:atp_keymaps.\n" . babel_line
	endif
	return
    endif

    if keymap != 'ignore'
	execute "set keymap=" . keymap
    else
	execute "set keymap="
    endif
endfunction
command! -buffer Babel	:call <SID>Babel()
" {{{1 start up
if g:atp_babel
    call <SID>Babel()
endif
"  }}}1

" These are two functions which sets options for Xpdf and Xdvi. 
" {{{ Xpdf, Xdvi
" xdvi - supports forward and reverse searching
" {{{ SetXdvi
function! <SID>SetXdvi()

    " Remove menu entries
    let Compiler		= get(g:CompilerMsg_Dict, matchstr(b:atp_TexCompiler, '^\s*\S*'), 'Compiler')
    let Viewer			= get(g:ViewerMsg_Dict, matchstr(b:atp_Viewer, '^\s*\S*'), 'View\ Output')
    try
	execute "aunmenu LaTeX.".Compiler
	execute "aunmenu LaTeX.".Compiler."\\ debug"
	execute "aunmenu LaTeX.".Compiler."\\ twice"
	execute "aunmenu LaTeX.View\\ with\\ ".Viewer
    catch /E329:/
    endtry

    " Set new options:
    let b:atp_TexCompiler	= "latex "
    let b:atp_TexOptions	= " -src-specials "
    let b:atp_Viewer="xdvi " . " -editor '" . v:progname . " --servername " . v:servername . " --remote-wait +%l %f'" 
    map <buffer> <LocalLeader>rs				:call RevSearch()<CR>
    try
	nmenu 550.65 &LaTeX.Reverse\ Search<Tab>:map\ <LocalLeader>rs	:RevSearch<CR>
    catch /E329:/
    endtry

    " Put new menu entries:
    let Compiler	= get(g:CompilerMsg_Dict, matchstr(b:atp_TexCompiler, '^\s*\zs\S*'), 'Compile')
    let Viewer		= get(g:ViewerMsg_Dict, matchstr(b:atp_Viewer, '^\s*\zs\S*'), "View\\ Output")
    execute "nmenu 550.5 &LaTeX.&".Compiler."<Tab>:TEX			:TEX<CR>"
    execute "nmenu 550.6 &LaTeX.".Compiler."\\ debug<Tab>:TEX\\ debug 	:DTEX<CR>"
    execute "nmenu 550.7 &LaTeX.".Compiler."\\ &twice<Tab>:2TEX		:2TEX<CR>"
    execute "nmenu 550.10 LaTeX.&View\\ with\\ ".Viewer."<Tab>:ViewOutput 		:ViewOutput<CR>"
endfunction
command! -buffer SetXdvi			:call <SID>SetXdvi()
nnoremap <silent> <buffer> <Plug>SetXdvi	:call <SID>SetXdvi()<CR>
" }}}

" xpdf - supports server option (we use the reoding mechanism, which allows to
" copy the output file but not reload the viewer if there were errors during
" compilation (b:atp_ReloadOnError variable)
" {{{ SetXpdf
function! <SID>SetPdf(viewer)

    " Remove menu entries.
    let Compiler		= get(g:CompilerMsg_Dict, matchstr(b:atp_TexCompiler, '^\s*\S*'), 'Compiler')
    let Viewer			= get(g:ViewerMsg_Dict, matchstr(b:atp_Viewer, '^\s*\S*'), 'View\ Output')
    try 
	execute "aunmenu LaTeX.".Compiler
	execute "aunmenu LaTeX.".Compiler."\\ debug"
	execute "aunmenu LaTeX.".Compiler."\\ twice"
	execute "aunmenu LaTeX.View\\ with\\ ".Viewer
    catch /E329:/
    endtry

    let b:atp_TexCompiler	= "pdflatex"
    " We have to clear tex options (for example -src-specials set by :SetXdvi)
    let b:atp_TexOptions	= "-synctex=1"
    let b:atp_Viewer		= a:viewer

    " Delete menu entry.
    try
	silent aunmenu LaTeX.Reverse\ Search
    catch /E329:/
    endtry

    " Put new menu entries:
    let Compiler	= get(g:CompilerMsg_Dict, matchstr(b:atp_TexCompiler, '^\s*\zs\S*'), 'Compile')
    let Viewer		= get(g:ViewerMsg_Dict, matchstr(b:atp_Viewer, '^\s*\zs\S*'), 'View\ Output')
    execute "nmenu 550.5 &LaTeX.&".Compiler.	"<Tab>:TEX			:TEX<CR>"
    execute "nmenu 550.6 &LaTeX." .Compiler.	"\\ debug<Tab>:TEX\\ debug 	:DTEX<CR>"
    execute "nmenu 550.7 &LaTeX." .Compiler.	"\\ &twice<Tab>:2TEX		:2TEX<CR>"
    execute "nmenu 550.10 LaTeX.&View\\ with\\ ".Viewer.	"<Tab>:ViewOutput 		:ViewOutput<CR>"
endfunction
command! -buffer SetXpdf			:call <SID>SetPdf('xpdf')
command! -buffer SetOkular			:call <SID>SetPdf('okular')
nnoremap <silent> <buffer> <Plug>SetXpdf	:call <SID>SetPdf('xpdf')<CR>
nnoremap <silent> <buffer> <Plug>SetOkular	:call <SID>SetPdf('okular')<CR>
" }}}
""
" }}}

" These are functions which toggles some of the options:
"{{{ Toggle Functions
if !s:did_options
" {{{ ATP_ToggleAuTeX
" command! -buffer -count=1 TEX	:call TEX(<count>)		 
function! ATP_ToggleAuTeX(...)
  let on	= ( a:0 >=1 ? ( a:1 == 'on'  ? 1 : 0 ) : !b:atp_autex )
    if on
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
"}}}
" {{{ ATP_ToggleSpace
" Special Space for Searching 
let s:special_space="[off]"
function! ATP_ToggleSpace(...)
    let on	= ( a:0 >=1 ? ( a:1 == 'on'  ? 1 : 0 ) : maparg('<space>','c') == "" )
    if on
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
"}}}
" {{{ ATP_ToggleCheckMathOpened
" This function toggles if ATP is checking if editing a math mode.
" This is used by insert completion.
" ToDo: to doc.
function! ATP_ToggleCheckMathOpened(...)
    let on	= ( a:0 >=1 ? ( a:1 == 'on'  ? 1 : 0 ) :  !g:atp_MathOpened )
"     if g:atp_MathOpened
    if !on
	let g:atp_MathOpened = 0
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
	let g:atp_MathOpened = 1
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
endfunction
"}}}
" {{{ ATP_ToggleCallBack
function! ATP_ToggleCallBack(...)
    let on	= ( a:0 >=1 ? ( a:1 == 'on'  ? 1 : 0 ) :  !g:atp_callback )
    if !on
	let g:atp_callback	= 0
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
	let g:atp_callback	= 1
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
endfunction
"}}}
" {{{ ATP_ToggleDebugMode
" ToDo: to doc.
" TODO: it would be nice to have this command (and the map) in quickflist (FileType qf)
" describe DEBUG MODE in doc properly.
function! ATP_ToggleDebugMode(...)
    let on	= ( a:0 >=1 ? ( a:1 == 'on'  ? 1 : 0 ) :  t:atp_DebugMode != "debug" )
    if !on
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
	let winnr = bufwinnr("%")
	silent copen
	exe winnr . " wincmd w"
    endif
endfunction
augroup ATP_DebugModeCommandsAndMaps
    au!
    au FileType qf command! -buffer ToggleDebugMode 	:call <SID>ToggleDebugMode()
    au FileType qf nnoremap <silent> <LocalLeader>D		:ToggleDebugMode<CR>
augroup END
" }}}
" {{{ ATP_ToggleTab
" switches on/off the <Tab> map for TabCompletion
function! ATP_ToggleTab(...)
    if mapcheck('<F7>','i') !~ 'atplib#TabCompletion'
	let on	= ( a:0 >=1 ? ( a:1 == 'on'  ? 1 : 0 ) : mapcheck('<Tab>','i') !~# 'atplib#TabCompletion' )
	if !on 
	    iunmap <buffer> <Tab>
	    echo '<Tab> map turned off'
	else
	    imap <buffer> <Tab> <C-R>=atplib#TabCompletion(1)<CR>
	    echo '<Tab> map turned on'
	endif
    endif
endfunction
" }}}
endif
 
"  Commands And Maps:
command! -buffer -nargs=? -complete=customlist,atplib#OnOffComp ToggleAuTeX 	:call ATP_ToggleAuTeX(<f-args>)
nnoremap <silent> <buffer> 	<Plug>ToggleAuTeX 		:call ATP_ToggleAuTeX()<CR>

command! -buffer -nargs=? -complete=customlist,atplib#OnOffComp ToggleSpace 	:call ATP_ToggleSpace(<f-args>)
nnoremap <silent> <buffer> 	<Plug>ToggleSpace 	:call ATP_ToggleSpace()<CR>

command! -buffer -nargs=? -complete=customlist,atplib#OnOffComp	ToggleCheckMathOpened 	:call ATP_ToggleCheckMathOpened(<f-args>)
nnoremap <silent> <buffer> 	<Plug>ToggleCheckMathOpened	:call ATP_ToggleCheckMathOpened()<CR>

command! -buffer -nargs=? -complete=customlist,atplib#OnOffComp	ToggleCallBack 		:call ATP_ToggleCallBack(<f-args>)
nnoremap <silent> <buffer> 	<Plug>ToggleCallBack		:call ATP_ToggleCallBack()<CR>

command! -buffer -nargs=? -complete=customlist,atplib#OnOffComp	ToggleDebugMode 	:call ATP_ToggleDebugMode(<f-args>)
nnoremap <silent> <buffer> 	<Plug>ToggleDebugMode		:call ATP_ToggleDebugMode()<CR>

command! -buffer -nargs=? -complete=customlist,atplib#OnOffComp	ToggleTab	 	:call ATP_ToggleTab(<f-args>)
nnoremap <silent> <buffer> 	<Plug>ToggleTab		:call ATP_ToggleTab()<CR>
inoremap <silent> <buffer> 	<Plug>ToggleTab		<Esc>:call ATP_ToggleTab()<CR>
"}}}

" Tab Completion Variables:
" {{{ TAB COMPLETION variables
" ( functions are in autoload/atplib.vim )
"
try 
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
	    \ 'font shape',		'algorithmic',
	    \ 'beamerthemes', 		'beamerinnerthemes',
	    \ 'beamerouterthemes', 	'beamercolorthemes',
	    \ 'beamerfontthemes',	'todonotes' ]
lockvar 2 g:atp_completion_modes
catch /E741:/
endtry

if !exists("g:atp_completion_modes_normal_mode") || g:atp_reload
    let g:atp_completion_modes_normal_mode=[ 
		\ 'close environments' , 'brackets', 'algorithmic' ]
    lockvar g:atp_completion_modes_normal_mode
endif

" By defualt all completion modes are ative.
if !exists("g:atp_completion_active_modes") || g:atp_reload
    let g:atp_completion_active_modes=deepcopy(g:atp_completion_modes)
endif
if !exists("g:atp_completion_active_modes_normal_mode") || g:atp_reload
    let g:atp_completion_active_modes_normal_mode=deepcopy(g:atp_completion_modes_normal_mode)
endif

if !exists("g:atp_sort_completion_list") || g:atp_reload
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
		\ 'itemize', 'lemma', 'list', 'letter', 'notation', 'minipage', 
		\ 'proof', 'proposition', 'picture', 'theorem', 'tikzpicture',  
		\ 'tabular', 'table', 'tabbing', 'thebibliography', 'titlepage',
		\ 'quotation', 'quote',
		\ 'remark', 'verbatim', 'verse' ]

	let g:atp_amsmath_environments=['align', 'alignat', 'equation', 'gather',
		\ 'multline', 'split', 'substack', 'flalign', 'smallmatrix', 'subeqations',
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
		    \ 'item'		: 'itm',	'algorithmic'	: 'alg',
		    \ 'algorithm'	: 'alg',
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
		    \ 'gather'  	: 'eq', 	'multline' 	: 'eq',
		    \ 'split'		: 'eq', 	'substack' 	: '',
		    \ 'flalign' 	: 'eq',		'displaymath' 	: 'eq',
		    \ 'part'		: 'prt',	'chapter' 	: 'chap',
		    \ 'section' 	: 'sec',	'subsection' 	: 'ssec',
		    \ 'subsubsection' 	: 'sssec', 	'paragraph' 	: 'par',
		    \ 'subparagraph' 	: 'spar',	'subequations'	: 'eq' }

	" ToDo: Doc.
	" Usage: \label{l:shorn_env_name . g:atp_separator
	if !exists("g:atp_separator") || g:atp_reload
	    let g:atp_separator=':'
	endif
	if !exists("g:atp_no_separator") || g:atp_reload
	    let g:atp_no_separator = 0
	endif
	if !exists("g:atp_no_short_names") || g:atp_reload
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
	\ "\\cite", "\\nocite{", "\\ref{", "\\pageref{", "\\eqref{", "\\item",
	\ "\\emph{", "\\documentclass{", "\\usepackage{",
	\ "\\section", "\\subsection", "\\subsubsection", "\\part", 
	\ "\\chapter", "\\appendix", "\\subparagraph", "\\paragraph",
	\ "\\textbf{", "\\textsf{", "\\textrm{", "\\textit{", "\\texttt{", 
	\ "\\textsc{", "\\textsl{", "\\textup{", "\\textnormal", "\\textcolor{",
	\ "\\bfseries", "\\mdseries", "\\bigskip", "\\bibitem",
	\ "\\tiny",  "\\scriptsize", "\\footnotesize", "\\small",
	\ "\\noindent", "\\normalfont", "\normalsize", "\\normalsize", "\\normal", 
	\ "\\hfill", "\\hspace","\\hline",  
	\ "\\large", "\\Large", "\\LARGE", "\\huge", "\\HUGE",
	\ "\\overline", 
	\ "\\usefont{", "\\fontsize{", "\\selectfont", "\\fontencoding{", "\\fontfamiliy{", "\\fontseries{", "\\fontshape{",
	\ "\\rmdefault", "\\sfdefault", "\\ttdefault", "\\bfdefault", "\\mddefault", "\\itdefault",
	\ "\\sldefault", "\\scdefault", "\\updefault",  "\\renewcommand{", "\\newcommand{",
	\ "\\addcontentsline{", "\\addtocontents",
	\ "\\input", "\\include", "\\includeonly", "\\includegraphics",  
	\ "\\savebox", "\\sbox", "\\usebox", "\\rule", "\\raisebox{", 
	\ "\\parbox{", "\\mbox{", "\\makebox{", "\\framebox{", "\\fbox{",
	\ "\\medskip", "\\smallskip", "\\vskip", "\\vfil", "\\vfill", "\\vspace{", 
	\ "\\hrulefill", "\hfil", "\\dotfill",
	\ "\\thispagestyle{", "\\mathnormal", "\\markright{", "\\markleft{", "\\pagestyle{", "\\pagenumbering{",
	\ "\\author{", "\\date{", "\\thanks{", "\\title{",
	\ "\\maketitle",
	\ "\\marginpar", "\\indent", "\\par", "\\sloppy", "\\pagebreak", "\\nopagebreak",
	\ "\\newpage", "\\newline", "\\newtheorem{", "\\linebreak", "\\line", "\\linespread{",
	\ "\\hyphenation{", "\\fussy", "\\eject",
	\ "\\enlagrethispage{", "\\clearpage", "\\cleardoublepage",
	\ "\\caption{",
	\ "\\opening{", "\\name{", "\\makelabels{", "\\location{", "\\closing{", "\\address{", 
	\ "\\signature{", "\\stopbreaks", "\\startbreaks",
	\ "\\newcounter{", "\\refstepcounter{", 
	\ "\\roman{", "\\Roman{", "\\stepcounter{", "\\setcounter{", 
	\ "\\usecounter{", "\\value{", 
	\ "\\newlength{", "\\setlength{", "\\addtolength{", "\\settodepth{", 
	\ "\\settoheight{", "\\settowidth{", "\\stretch{",
	\ "\\width", "\\height", "\\depth", "\\totalheight",
	\ "\\footnote{", "\\footnotemark", "\\footnotetetext", 
	\ "\\bibliography{", "\\bibliographystyle{", "\\baselineskip",
	\ "\\flushbottom", "\\onecolumn", "\\raggedbottom", "\\twocolumn",  
	\ "\\alph{", "\\Alph{", "\\arabic{", "\\fnsymbol{", "\\reversemarginpar",
	\ "\\exhyphenpenalty",
	\ "\\topmargin", "\\oddsidemargin", "\\evensidemargin", "\\headheight", "\\headsep", 
	\ "\\textwidth", "\\textheight", "\\marginparwidth", "\\marginparsep", "\\marginparpush", "\\footskip", "\\hoffset",
	\ "\\voffset", "\\paperwidth", "\\paperheight", "\\theequation", "\\thepage", "\\usetikzlibrary{",
	\ "\\tableofcontents", "\\newfont{", "\\phantom",
	\ "\\DeclareRobustCommand", "\\DeclareFixedFont", "\\DeclareMathSymbol", 
	\ "\\DeclareTextFontCommand", "\\DeclareMathVersion", "\\DeclareSymbolFontAlphabet",
	\ "\\DeclareMathDelimiter", "\\DeclareMathAccent", "\\DeclareMathRadical",
	\ "\\SetMathAlphabet", "\\show", "\\CheckCommand", "\\mathnormal",
	\ "\\pounds", "\\magstep{", "\\hyperlink", "\\newenvironment{", 
	\ "\\renewenvironemt{", "\\DeclareFixedFont", "\\layout", "\\parskip" ]
	
	let g:atp_picture_commands=[ "\\put", "\\circle", "\\dashbox", "\\frame{", 
		    \"\\framebox(", "\\line(", "\\linethickness{",
		    \ "\\makebox(", "\\\multiput(", "\\oval(", "\\put", 
		    \ "\\shortstack", "\\vector(" ]

	" ToDo: end writting layout commands. 
	" ToDo: MAKE COMMANDS FOR PREAMBULE.

	let g:atp_math_commands=["\\forall", "\\exists", "\\emptyset", "\\aleph", "\\partial",
	\ "\\nabla", "\\Box", "\\bot", "\\top", "\\flat", "\\natural",
	\ "\\mathbf{", "\\mathsf{", "\\mathrm{", "\\mathit{", "\\mathtt{", "\\mathcal{", 
	\ "\\mathop{", "\\mathversion", "\\limits", "\\text{", "\\leqslant", "\\leq", "\\geqslant", "\\geq",
	\ "\\gtrsim", "\\lesssim", "\\gtrless", "\\left", "\\right", 
	\ "\\rightarrow", "\\Rightarrow", "\\leftarrow", "\\Leftarrow", "\\iff", 
	\ "\\oplus", "\\otimes", "\\odot", "\\oint",
	\ "\\leftrightarrow", "\\Leftrightarrow", "\\downarrow", "\\Downarrow", 
	\ "\\overline", "\\underline", "\\overbrace{", "\\Uparrow",
	\ "\\Longrightarrow", "\\longrightarrow", "\\Longleftarrow", "\\longleftarrow",
	\ "\\overrightarrow{", "\\overleftarrow{", "\\underrightarrow{", "\\underleftarrow{",
	\ "\\uparrow", "\\nearrow", "\\searrow", "\\swarrow", "\\nwarrow", "\\mapsto", "\\longmapsto",
	\ "\\hookrightarrow", "\\hookleftarrow", "\\gets", "\\to", "\\backslash", 
	\ "\\sum", "\\bigsum", "\\cup", "\\bigcup", "\\cap", "\\bigcap", 
	\ "\\prod", "\\coprod", "\\bigvee", "\\bigwedge", "\\wedge",  
	\ "\\int", "\\bigoplus", "\\bigotimes", "\\bigodot", "\\times",  
	\ "\\smile", "\\frown", 
	\ "\\dashv", "\\vdash", "\\vDash", "\\Vdash", "\\models", "\\sim", "\\simeq", 
	\ "\\prec", "\\preceq", "\\preccurlyeq", "\\precapprox", "\\mid",
	\ "\\succ", "\\succeq", "\\succcurlyeq", "\\succapprox", "\\approx", 
	\ "\\ldots", "\\cdots", "\\vdots", "\\ddots", "\\circ", 
	\ "\\thickapprox", "\\cong", "\\bullet",
	\ "\\lhd", "\\unlhd", "\\rhd", "\\unrhd", "\\dagger", "\\ddager", "\\dag", "\\ddag", 
	\ "\\vartriangleright", "\\vartriangleleft", 
	\ "\\triangle", "\\triangledown", "\\trianglerighteq", "\\trianglelefteq",
	\ "\\copyright", "\\textregistered", "\\puonds",
	\ "\\big", "\\Big", "\\Bigg", "\\huge", 
	\ "\\bigr", "\\Bigr", "\\biggr", "\\Biggr",
	\ "\\bigl", "\\Bigl", "\\biggl", "\\Biggl", 
	\ "\\hat", "\\grave", "\\bar", "\\acute", "\\mathring", "\\check", 
	\ "\\dots", "\\dot", "\\vec", "\\breve",
	\ "\\tilde", "\\widetilde" , "\\widehat", "\\ddot", 
	\ "\\sqrt", "\\frac", "\\binom{", "\\cline", "\\vline", "\\hline", "\\multicolumn{", 
	\ "\\nouppercase", "\\sqsubseteq", "\\sqsubset", "\\sqsupseteq", "\\sqsupset", 
	\ "\\square", "\\blacksquare",  
	\ "\\nexists", "\\varnothing", "\\Bbbk", "\\circledS", 
	\ "\\complement", "\\hslash", "\\hbar", 
	\ "\\eth", "\\rightrightarrows", "\\leftleftarrows", "\\rightleftarrows", "\\leftrighrarrows", 
	\ "\\downdownarrows", "\\upuparrows", "\\rightarrowtail", "\\leftarrowtail", 
	\ "\\rightharpoondown", "\\rightharpoonup", "\\rightleftharpoons", "\\leftharpoondown", "\\leftharpoonup",
	\ "\\twoheadrightarrow", "\\twoheadleftarrow", "\\rceil", "\\lceil", "\\rfloor", "\\lfloor", 
	\ "\\bigtriangledown", "\\bigtriangleup", "\\ominus", "\\bigcirc", "\\amalg", "\\asymp",
	\ "\\vert", "\\Arrowvert", "\\arrowvert", "\\bracevert", "\\lmoustache", "\\rmoustache",
	\ "\\setminus", "\\sqcup", "\\sqcap", "\\bowtie", "\\owns", "\\oslash",
	\ "\\lnot", "\\notin", "\\neq", "\\smile", "\\frown", "\\equiv", "\\perp",
	\ "\\quad", "\\qquad", "\\stackrel", "\\displaystyle", "\\textstyle", "\\scriptstyle", "\\scriptscriptstyle",
	\ "\\langle", "\\rangle", "\\Diamond", "\\lgroup", "\\rgroup", "\\propto", "\\Join", "\\div", 
	\ "\\land", "\\star", "\\uplus", "\\leadsto", "\\rbrack", "\\lbrack", "\\mho", 
	\ "\\diamondsuit", "\\heartsuit", "\\clubsuit", "\\spadesuit", "\\top", "\\ell", 
	\ "\\imath", "\\jmath", "\\wp", "\\Im", "\\Re", "\\prime", "\\ll", "\\gg" ]

	let g:atp_math_commands_PRE=[ "\\diagdown", "\\diagup", "\\subset", "\\subseteq", "\\supset", "\\supsetneq",
		    \ "\\sharp", "\\underline", "\\underbrace{",  ]

	" commands defined by the user in input files.
	" ToDo: to doc.
	" ToDo: this doesn't work with input files well enough. 
	
	" Returns a list of two lists:  [ commanad_names, enironment_names ]

	" The BufEnter augroup doesn't work with EditInputFile, but at least it works
	" when entering. Debuging shows that when entering new buffer it uses
	" wrong b:atp_MainFile, it is still equal to the bufername and not the
	" real main file. Maybe it is better to use s:mainfile variable.

	if !exists("g:atp_local_completion") || g:atp_reload
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
	let g:atp_amsmath_commands=[ "\\boxed", "\\intertext", "\\multiligngap", "\\shoveleft{", "\\shoveright{", "\\notag", "\\tag", 
		    \ "\\notag", "\\raistag{", "\\displaybreak", "\\allowdisplaybreaks", "\\numberwithin{",
		    \ "\\hdotsfor{" , "\\mspace{",
		    \ "\\negthinspace", "\\negmedspace", "\\negthickspace", "\\thinspace", "\\medspace", "\\thickspace",
		    \ "\\leftroot{", "\\uproot{", "\\overset{", "\\underset{", "\\substack{", "\\sideset{", 
		    \ "\\dfrac", "\\tfrac", "\\cfrac", "\\dbinom{", "\\tbinom{", "\\smash",
		    \ "\\lvert", "\\rvert", "\\lVert", "\\rVert", "\\DeclareMatchOperator{",
		    \ "\\arccos", "\\arcsin", "\\arg", "\\cos", "\\cosh", "\\cot", "\\coth", "\\csc", "\\deg", "\\det",
		    \ "\\dim", "\\exp", "\\gcd", "\\hom", "\\inf", "\\injlim", "\\ker", "\\lg", "\\lim", "\\liminf", "\\limsup",
		    \ "\\log", "\\min", "\\max", "\\Pr", "\\projlim", "\\sec", "\\sin", "\\sinh", "\\sup", "\\tan", "\\tanh",
		    \ "\\varlimsup", "\\varliminf", "\\varinjlim", "\\varprojlim", "\\mod", "\\bmod", "\\pmod", "\\pod", "\\sideset",
		    \ "\\iint", "\\iiint", "\\iiiint", "\\idotsint", "\\tag",
		    \ "\\varGamma", "\\varDelta", "\\varTheta", "\\varLambda", "\\varXi", "\\varPi", "\\varSigma", 
		    \ "\\varUpsilon", "\\varPhi", "\\varPsi", "\\varOmega" ]
	
	" ToDo: integrate in TabCompletion (amsfonts, euscript packages).
	let g:atp_amsfonts=[ "\\mathbb{", "\\mathfrak{", "\\mathscr{" ]

	" not yet supported: in TabCompletion:
	let g:atp_amsextra_commands=[ "\\sphat", "\\sptilde" ]
	let g:atp_fancyhdr_commands=["\\lfoot{", "\\rfoot{", "\\rhead{", "\\lhead{", 
		    \ "\\cfoot{", "\\chead{", "\\fancyhead{", "\\fancyfoot{",
		    \ "\\fancypagestyle{", "\\fancyhf{}", "\\headrulewidth", "\\footrulewidth",
		    \ "\\rightmark", "\\leftmark", "\\markboth{", 
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
		    \ "\\pattern", "\\shade", "\\shadedraw", "\\colorlet", "\\definecolor",
		    \ "\\pgfmatrixnextcell" ]
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
		    \ 'circular', 'shadow', 'scope', 'borders', 'spreading', 'false', 'position', 'midway',
		    \ 'paint', 'from', 'to' ]
	let g:atp_tikz_library_arrows_keywords	= [ 'reversed', 'stealth', 'triangle', 'open', 
		    \ 'hooks', 'round', 'fast', 'cap', 'butt'] 
	let g:atp_tikz_library_automata_keywords=[ 'state', 'accepting', 'initial', 'swap', 
		    \ 'loop', 'nodepart', 'lower', 'upper', 'output']  
	let g:atp_tikz_library_backgrounds_keywords=[ 'background', 'show', 'inner', 'frame', 'framed',
		    \ 'tight', 'loose', 'xsep', 'ysep']

	let g:atp_tikz_library_calendar_commands=[ '\calendar', '\tikzmonthtext' ]
	let g:atp_tikz_library_calendar_keywords=[ 'week list', 'dates', 'day', 'day list', 'month', 'year', 'execute', 
		    \ 'before', 'after', 'downward', 'upward' ]
	let g:atp_tikz_library_chain_commands=[ '\chainin' ]
	let g:atp_tikz_library_chain_keywords=[ 'chain', 'start chain', 'on chain', 'continue chain', 
		    \ 'start branch', 'branch', 'going', 'numbers', 'greek' ]
	let g:atp_tikz_library_decorations_commands=[ '\\arrowreversed' ]
	let g:atp_tikz_library_decorations_keywords=[ 'decorate', 'decoration', 'lineto', 'straight', 'zigzag',
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
		    \ 'square', 'square*', 'triangle', 'triangle*', 'diamond*', 'pentagon', 'pentagon*']
	let g:atp_tikz_library_shadow_keywords 	= ['general shadow', 'shadow', 'drop shadow', 'copy shadow', 'glow' ]
	let g:atp_tikz_library_shapes_keywords 	= ['shape', 'center', 'base', 'mid', 'trapezium', 'semicircle', 'chord', 'regular polygon', 'corner', 'star', 'isoscales triangle', 'border', 'stretches', 'kite', 'vertex', 'side', 'dart', 'tip', 'tail', 'circular', 'sector', 'cylinder', 'minimum', 'height', 'width', 'aspect', 'uses', 'custom', 'body', 'forbidden sign', 'cloud', 'puffs', 'ignores', 'starburst', 'random', 'signal', 'pointer', 'tape', 
		    \ 'single', 'arrow', 'head', 'extend', 'indent', 'after', 'before', 'arrow box', 'shaft', 
		    \ 'lower', 'upper', 'split', 'empty', 'part', 
		    \ 'callout', 'relative', 'absolute', 'shorten',
		    \ 'logic gate', 'gate', 'inputs', 'inverted', 'radius', 'use', 'US style', 'CDH style', 'nand', 'and', 'or', 'nor', 'xor', 'xnor', 'not', 'buffer', 'IEC symbol', 'symbol', 'align', 
		    \ 'cross out', 'strike out', 'length', 'chamfered rectangle' ]
	let g:atp_tikz_library_topath_keywords	= ['line to', 'curve to', 'out', 'in', 'relative', 'bend', 'looseness', 'min', 'max', 'control', 'loop']
	let g:atp_tikz_library_through_keywords	= ['through']
	let g:atp_tikz_library_trees_keywords	= ['grow', 'via', 'three', 'points', 'two', 'child', 'children', 'sibling', 'clockwise', 'counterclockwise', 'edge', 'parent', 'fork'] 

	" BEAMER
	let g:atp_BeamerEnvironments = ["frame", "beamercolorbox", "onlyenv", "altenv", 
		    \ "visibleenv", "uncoverenv", "invisibleenv", "overlayarea", "overprint", "actionenv",
		    \ 'description', 'structureenv', 'alertenv', 'block', 'alertblock', 'exampleblock', 'beamercolorbox',
		    \ 'beamerboxesrounded', 'columns', 'semiverbatim' ]

	let g:atp_BeamerCommands = ["\\alert{", "\\frametitle{", "\\framesubtitle", "\\titlepage", "\\setbeamercolor{", 
		    \ "\\pauze", "\\onslide", "\\only", "\\uncover", "\\visible", "\\invisible", "\\temporal", "\\alt",
		    \ "\\usebeamercolor{", "\\usetheme{", "\\includeonlyframes{", "\\againframe", "\\setbeamersize{",
		    \ "\\action{", "\\inserttocsection", "\\inserttocsectionumber", "\\lecture", "\\AtBeginLecture{",
		    \ "\\appendix", "\\hypertarget", "\\beamerbutton", "\\beamerskipbutton", "\\beamerreturnbutton", 
		    \ "\\beamergotobutton", '\hyperlinkslideprev', '\hyperlinkslidenext', '\hyperlinkframestart', 
		    \ '\hyperlinkframeend', '\hyperlinkframestartnext', '\hyperlinkframeendprev', 
		    \ '\hyperlinkpresentationstart', '\hyperlinkpresentationend', '\hyperlinkappendixstart', 
		    \  '\hyperlinkappendixend', '\hyperlinkdocumentstart',  '\hyperlinkdocumentend',
		    \ '\framezoom', '\structure', '\insertblocktitle', '\column', '\movie', '\animate', 
		    \ '\hyperlinksound', '\hyperlinkmute',
		    \ '\usetheme', '\usecolortheme', '\usefonttheme', '\useinnertheme', '\useoutertheme',
		    \ '\usefonttheme', '\note', '\AtBeginNote', '\AtEndNote', '\setbeameroption{',
		    \ '\setbeamerfont{', '\mode' ]

	let g:atp_BeamerThemes = [ "default", "boxes", "Bergen", "Boadilla", "Madrid", "AnnArbor", 
		    \ "CambridgeUS", "Pittsburgh", "Rochester", "Antibes", "JuanLesPins", "Montpellier", 
		    \ "Berkeley" , "PalAlto", "Gottingen", "Marburg", "Hannover", "Berlin", "Ilmenau", 
		    \ "Dresden", "Darmstadt", "Frankfurt", "Singapore", "Szeged", "Copenhagen", "Luebeck", "Malmoe", 
		    \ "Warsaw", ]
	let g:atp_BeamerInnerThemes = [ "default", "circles", "rectangles", "rounded", "inmargin" ]
	let g:atp_BeamerOuterThemes = [ "default", "infolines", "miniframes", "smoothbars", "sidebar",
		    \ "split", "shadow", "tree", "smoothtree" ]
	let g:atp_BeamerColorThemes = [ "default", "structure", "sidebartab", "albatross", "beetle", "crane", 
		    \ "dove", "fly", "seagull", "wolverine", "beaver", "lily", "orchid", "rose", "whale", "seahorse", 
		    \ "dolphin" ]
	let g:atp_BeamerFontThemes = [ "default", "serif", "structurebold", "structureitalicserif",
		    \ "structuresmallcapsserif" ]

	let g:atp_MathTools_math_commands = [ '\cramped', '\crampedllap', '\crampedclap', '\crampedrlap', '\smashoperator',
		    \ '\adjustlimits', '\newtagform{', '\usetagform{', '\renewtagform{', 
		    \ '\xleftrightarrow', '\xRightarrow', '\xLeftarrow', '\xLeftrightarrow', 
		    \ '\xhookleftarrow', '\xhookrightarrow', '\xmapsto', '\underbracket', '\overbracket',
		    \ '\LaTeXunderbrace', '\LaTeXoverbrace', '\Aboxed', '\ArrowBetweenLines', '\ArrowBetweenLines*',
		    \ '\shortintertext', '\lparen', '\rparen', '\vcentcolon', 
		    \ '\ordinarycolon', '\mathtoolsset{', '\prescript',
		    \ '\newgathered', '\renewgathered', '\splitfrac{', '\splitdfrac{' ]
	let g:atp_MathTools_commands = [ '\DeclarePairedDelimiter{', '\DeclarePairedDelimiterX{' ]

	let g:atp_MathTools_environments = [ 'matrix*', 'pmatrix*', 'bmatrix*', 'Bmatrix*', 'vmatrix*', 'Vmatrix*', 
		    \ 'multilined', 'dcases', 'dcases*', 'rcases', 'rcases*', 'drcases*', 'cases*', 'spreadlines',
		    \ 'lgathered', 'rgathered' ]

	let g:atp_TodoNotes_commands = [ '\todo{', '\listoftodos', '\missingfigure' ] 
	let g:atp_TodoNotes_todo_options	= [ 'disable', 'color=', 'backgroundcolor=', 'linecolor=', 'bordercolor=', 
		    \ 'line', 'noline', 'inline', 'noinline', 'size=', 'list', 'nolist', 
		    \ 'caption=', 'prepend', 'noprepend', 'fancyline']   
	let g:atp_TodoNotes_missingfigure_options = [ 'figwidth=' ]
if !exists("g:atp_MathOpened") || g:atp_reload
    let g:atp_MathOpened = 1
endif
" augroup ATP_MathOpened
"     au!
"     au Syntax tex :let g:atp_MathOpened = 1
" augroup END

let g:atp_math_modes=[ ['\%([^\\]\|^\)\%(\\\|\\\{3}\)(','\%([^\\]\|^\)\%(\\\|\\\{3}\)\zs)'],
	    \ ['\%([^\\]\|^\)\%(\\\|\\\{3}\)\[','\%([^\\]\|^\)\%(\\\|\\\{3}\)\zs\]'],	
	    \ ['\\begin{align', '\\end{alig\zsn'], 	['\\begin{gather', '\\end{gathe\zsr'], 
	    \ ['\\begin{falign', '\\end{flagi\zsn'], 	['\\begin[multline', '\\end{multlin\zse'],
	    \ ['\\begin{equation', '\\end{equatio\zsn'],
	    \ ['\\begin{\%(display\)\?math', '\\end{\%(display\)\?mat\zsh'] ] 

" Completion variables for \pagestyle{} and \thispagestyle{} LaTeX commands.
let g:atp_pagestyles = [ 'plain', 'headings', 'empty', 'myheadings' ]
let g:atp_fancyhdr_pagestyles = [ 'fancy' ]

" Completion variable for \pagenumbering{} LaTeX command.
let g:atp_pagenumbering = [ 'arabic', 'roman', 'Roman', 'alph', 'Alph' ]
" }}}
"

" Some of the autocommands (Status Line, LocalCommands, Log File):
" {{{ Autocommands:


if !s:did_options

    augroup ATP_deltmpdir
	au VimLeave *.tex :call system("rmdir " . b:atp_TmpDir)
    augroup END

    augroup ATP_updatetime
	au VimEnter if &l:updatetime == 4000 | let &l:updatetime = 800 | endif
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
" editing a math mode. Currently, supported are $:$, \(:\), \[:\] and $$:$$.
" {{{  SetMathVimOptions

if !exists("g:atp_SetMathVimOptions") || g:atp_reload
    let g:atp_SetMathVimOptions 	= 1
endif

if !exists("g:atp_MathVimOptions") || g:atp_reload
"     { 'option_name' : [ val_in_math, normal_val], ... }
    let g:atp_MathVimOptions 		=  { 'textwidth' 	: [ 0, 	&textwidth],
						\ }
endif

if !exists("g:atp_MathZones") || g:atp_reload
let g:atp_MathZones	= &l:filetype == "tex" ? [ 
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
	    		\ 'texMathZoneL', 	'texMathZoneLS',
			\ 'texMathZoneT'
			\ ]
			\ : [ 'plaintexMath' ] 
endif

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
			\ " v:val[0] =~ v:key ? [ v:val[0] =~ '^no' . v:key ? 0 : 1, v:val[1] ] : v:val " )
	let MathVimOptions = map(MathVimOptions,
			\ " v:val[1] =~ v:key ? [ v:val[0], v:val[1] =~ '^no' . v:key ? 0 : 1 ] : v:val " )

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
	catch /E117:/
	endtry
    endif
    if atplib#SearchPackage('algorithmic')
	try
	    call TexNewMathZone("ALG", "algorithmic", 0)
	catch /E117:/ 
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
    let view = [ 'okular', 'xpdf', 'xdvi', 'evince', 'epdfview', 'kpdf', 'acroread', 'zathura' ]
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
