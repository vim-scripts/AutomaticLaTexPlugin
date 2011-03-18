" Author:	Marcin Szmotulski
" Description:  This file contains mappings defined by ATP.
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" URL:		https://launchpad.net/automatictexplugin
" Language:	tex
" Last Change:

" Commands to library functions (autoload/atplib.vim)
command! -buffer -bang -nargs=* FontSearch	:call atplib#FontSearch(<q-bang>, <f-args>)
command! -buffer -bang -nargs=* FontPreview	:call atplib#FontPreview(<q-bang>,<f-args>)
command! -buffer -nargs=1 -complete=customlist,atplib#Fd_completion OpenFdFile	:call atplib#OpenFdFile(<f-args>) 
command! -buffer -nargs=* CloseLastEnvironment	:call atplib#CloseLastEnvironment(<f-args>)
command! -buffer 	  CloseLastBracket	:call atplib#CloseLastBracket()
let g:atp_map_list	= [ 
	    \ [ g:atp_map_forward_motion_leader, 'i', 		':NInput<CR>', 			'nmap <buffer>' ],
	    \ [ g:atp_map_backward_motion_leader, 'i', 		':NPnput<CR>', 			'nmap <buffer>' ],
	    \ [ g:atp_map_forward_motion_leader, 'gf', 		':NInput<CR>', 			'nmap <buffer>' ],
	    \ [ g:atp_map_backward_motion_leader, 'gf',		':NPnput<CR>', 			'nmap <buffer>' ],
	    \ [ g:atp_map_forward_motion_leader, 'S', 		'<Plug>GotoNextSubSection',	'nmap <buffer>' ],
	    \ [ g:atp_map_backward_motion_leader, 'S', 		'<Plug>vGotoNextSubSection', 	'nmap <buffer>' ],
	    \ ] 

" Add maps, unless the user didn't want them.
if ( !exists("g:no_plugin_maps") || exists("g:no_plugin_maps") && g:no_plugin_maps == 0 ) && 
	    \ ( !exists("g:no_atp_maps") || exists("g:no_plugin_maps") && g:no_atp_maps == 0 ) 

nmap <buffer> <silent> ]*	:SkipCommentForward<CR> 
omap <buffer> <silent> ]*	:SkipCommentForward<CR> 
nmap <buffer> <silent> gc	:SkipCommentForward<CR>
omap <buffer> <silent> gc	:SkipCommentForward<CR>

vmap <buffer> <silent> ]*	<Plug>SkipCommentForward
vmap <buffer> <silent> gc	<Plug>SkipCommentForward
vmap <buffer> <silent> gC	<Plug>SkipCommentBackward
vmap <buffer> <silent> [*	<Plug>SkipCommentBackward

nmap <buffer> <silent> [*	:SkipCommentBackward<CR> 
omap <buffer> <silent> [*	:SkipCommentBackward<CR> 
nmap <buffer> <silent> gC	:SkipCommentBackward<CR>
omap <buffer> <silent> gC	:SkipCommentBackward<CR>

execute "nmap <buffer> ".g:atp_map_forward_motion_leader."i				:NInput<CR>"
execute "nmap <buffer> ".g:atp_map_backward_motion_leader."i				:PInput<CR>"
execute "nmap <buffer> ".g:atp_map_forward_motion_leader."gf				:NInput<CR>"
execute "nmap <buffer> ".g:atp_map_backward_motion_leader."gf				:PInput<CR>"

" Syntax motions:
" imap <C-j> <Plug>TexSyntaxMotionForward
" imap <C-k> <Plug>TexSyntaxMotionBackward
" nmap <C-j> <Plug>TexSyntaxMotionForward
" nmap <C-k> <Plug>TexSyntaxMotionBackward

imap <C-j> <Plug>TexJMotionForward
imap <C-k> <Plug>TexJMotionBackward
nmap <C-j> <Plug>TexJMotionForward
nmap <C-k> <Plug>TexJMotionBackward

    if g:atp_map_forward_motion_leader == "}"
	noremap <buffer> }} }
    endif
    if g:atp_map_backward_motion_leader == "{"
	noremap <buffer> {{ {
    endif

    " ToDo to doc. + vmaps!
    execute "nmap <buffer> ".g:atp_map_forward_motion_leader."S 	<Plug>GotoNextSubSection"
    execute "vmap <buffer> ".g:atp_map_forward_motion_leader."S		<Plug>vGotoNextSubSection"
    execute "nmap <buffer> ".g:atp_map_backward_motion_leader."S 	<Plug>GotoPreviousSubSection"
    execute "vmap <buffer> ".g:atp_map_backward_motion_leader."S 	<Plug>vGotoPreviousSubSection"
    " Toggle this maps on/off!
    execute "nmap <buffer> ".g:atp_map_forward_motion_leader."s 	<Plug>GotoNextSection"
    execute "vmap <buffer> ".g:atp_map_forward_motion_leader."s		<Plug>vGotoNextSection"
    execute "nmap <buffer> ".g:atp_map_backward_motion_leader."s 	<Plug>GotoPreviousSection"
    execute "vmap <buffer> ".g:atp_map_backward_motion_leader."s 	<Plug>vGotoPreviousSection"
    if !( g:atp_map_forward_motion_leader == "]" && &l:diff )
	execute "nmap <buffer> ".g:atp_map_forward_motion_leader."c 	<Plug>GotoNextChapter"
	execute "vmap <buffer> ".g:atp_map_forward_motion_leader."c 	<Plug>vGotoNextChapter"
    endif
    if !( g:atp_map_backward_motion_leader == "]" && &l:diff )
	execute "nmap <buffer> ".g:atp_map_backward_motion_leader."c 	<Plug>GotoPreviousChapter"
	execute "vmap <buffer> ".g:atp_map_backward_motion_leader."c 	<Plug>vGotoPreviousChapter"
    endif
    execute "nmap <buffer> ".g:atp_map_forward_motion_leader."p 	<Plug>GotoNextPart"
    execute "vmap <buffer> ".g:atp_map_forward_motion_leader."p 	<Plug>vGotoNextPart"
    execute "nmap <buffer> ".g:atp_map_backward_motion_leader."p 	<Plug>GotoPreviousPart"
    execute "vmap <buffer> ".g:atp_map_backward_motion_leader."p 	<Plug>vGotoPreviousPart"

    execute "map <buffer> ".g:atp_map_forward_motion_leader."e		<Plug>GotoNextEnvironment"
    execute "map <buffer> ".g:atp_map_backward_motion_leader."e		<Plug>GotoPreviousEnvironment"
"     exe "map <buffer> ".g:atp_map_forward_motion_leader."  <Plug>GotoNextEnvironment"
"     exe "map <buffer> ".g:atp_map_backward_motion_leader." <Plug>GotoPreviousEnvironment"
"     map <buffer> ]m			<Plug>GotoNextInlineMath
"     map <buffer> [m			<Plug>GotoPreviousInlineMath
    execute "map <buffer> ".g:atp_map_forward_motion_leader."m		<Plug>GotoNextMath"
    execute "map <buffer> ".g:atp_map_backward_motion_leader."m		<Plug>GotoPreviousMath"
    execute "map <buffer> ".g:atp_map_forward_motion_leader."M		<Plug>GotoNextDisplayedMath"
    execute "map <buffer> ".g:atp_map_backward_motion_leader."M		<Plug>GotoPreviousDisplayedMath"

    " Goto File Map:
    if has("path_extra")
	nnoremap <buffer> <silent> gf		:call GotoFile("", "")<CR>
    endif

    if exists("g:atp_no_tab_map") && g:atp_no_tab_map == 1
	imap <silent> <buffer> <F7> 		<C-R>=atplib#TabCompletion(1)<CR>
	nnoremap <silent> <buffer> <F7>		:call atplib#TabCompletion(1,1)<CR>
	imap <silent> <buffer> <S-F7> 		<C-R>=atplib#TabCompletion(0)<CR>
	nnoremap <silent> <buffer> <S-F7>	:call atplib#TabCompletion(0,1)<CR> 
    else 
	" the default:
	imap <silent> <buffer> <Tab> 		<C-R>=atplib#TabCompletion(1)<CR>
	imap <silent> <buffer> <S-Tab> 		<C-R>=atplib#TabCompletion(0)<CR>
	" HOW TO: do this with <tab>? Streightforward solution interacts with
	" other maps (e.g. after \l this map is called).
	" when this is set it also runs after the \l map: ?!?
" 	nmap <silent> <buffer> <Tab>		:call atplib#TabCompletion(1,1)<CR>
	nnoremap <silent> <buffer> <S-Tab>	:call atplib#TabCompletion(0,1)<CR> 
	vnoremap <buffer> <silent> <F7> 	:WrapSelection '\{','}','begin'<CR>
    endif

    " Fonts:
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."f		:WrapSelection '{\\usefont{".g:atp_font_encoding."}{}{}{}\\selectfont ', '}', '".(len(g:atp_font_encoding)+11)."'<CR>"


    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."te	:<C-U>InteligentWrapSelection ['\\textrm{'],['\\text{']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."rm	:<C-U>InteligentWrapSelection ['\\textrm{'],['\\mathrm{']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."em	:<C-U>InteligentWrapSelection ['\\emph{'],['\\mathit{']<CR>"
"   Suggested Maps:
"     execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."tx	:<C-U>InteligentWrapSelection [''],['\\text{']<CR>"
"     execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."in	:<C-U>InteligentWrapSelection [''],['\\intertext{']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."it	:<C-U>InteligentWrapSelection ['\\textit{'],['\\mathit{']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."sf	:<C-U>InteligentWrapSelection ['\\textsf{'],['\\mathsf{']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."tt	:<C-U>InteligentWrapSelection ['\\texttt{'],['\\mathtt{']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."bf	:<C-U>InteligentWrapSelection ['\\textbf{'],['\\mathbf{']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."bb	:<C-U>InteligentWrapSelection ['\\textbf{'],['\\mathbb{']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."sl	:<C-U>WrapSelection '\\textsl{'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."sc	:<C-U>WrapSelection '\\textsc{'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."up	:<C-U>WrapSelection '\\textup{'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."md	:<C-U>WrapSelection '\\textmd{'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."un	:<C-U>WrapSelection '\\underline{'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."ov	:<C-U>WrapSelection '\\overline{'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."no	:<C-U>InteligentWrapSelection ['\\textnormal{'],['\\mathnormal{']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."cal	:<C-U>InteligentWrapSelection [''],['\\mathcal{']<CR>"

    " Environments:
    execute "vnoremap <buffer> ".g:atp_vmap_environment_leader."C   :WrapSelection '"."\\"."begin{center}','"."\\"."end{center}','0','1'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_environment_leader."R   :WrapSelection '"."\\"."begin{flushright}','"."\\"."end{flushright}','0','1'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_environment_leader."L   :WrapSelection '"."\\"."begin{flushleft}','"."\\"."end{flushleft}','0','1'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_environment_leader."E   :WrapSelection '"."\\"."begin{equation=g:atp_StarMathEnvDefault<CR>}','"."\\"."end{equation=g:atp_StarMathEnvDefault<CR>}','0','1'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_environment_leader."A   :WrapSelection '"."\\"."begin{align=g:atp_StarMathEnvDefault<CR>}','"."\\"."end{align=g:atp_StarMathEnvDefault<CR>}','0','1'<CR>"

    " Math Modes:
    vmap <buffer> m						:<C-U>WrapSelection '\(', '\)'<CR>
    vmap <buffer> M						:<C-U>WrapSelection '\[', '\]'<CR>

    " Brackets:
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."( 	:WrapSelection '(', ')', 'begin'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."[ 	:WrapSelection '[', ']', 'begin'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."\\{ 	:WrapSelection '\\{', '\\}', 'begin'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."{ 	:WrapSelection '{', '}', 'begin'<CR>"
"     execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."{	:<C-U>InteligentWrapSelection ['{', '}'],['\\{', '\\}']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader.")	:WrapSelection '(', ')', 'end'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."]	:WrapSelection '[', ']', 'end'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."\\}	:WrapSelection '\\{', '\\}', 'end'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."}	:WrapSelection '{', '}', 'end'<CR>"

    execute "vnoremap <buffer> ".g:atp_vmap_big_bracket_leader."(	:WrapSelection '\\left(', '\\right)', 'begin'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_big_bracket_leader."[	:WrapSelection '\\left[', '\\right]', 'begin'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_big_bracket_leader."{	:WrapSelection '\\left\\{','\\right\\}', 'begin'<CR>"
    " for compatibility:
    execute "vnoremap <buffer> ".g:atp_vmap_big_bracket_leader."\\{	:WrapSelection '\\left\\{','\\right\\}', 'begin'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_big_bracket_leader.")	:WrapSelection '\\left(', '\\right)', 'end'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_big_bracket_leader."]	:WrapSelection '\\left[', '\\right]', 'end'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_big_bracket_leader."}	:WrapSelection '\\left\\{', '\\right\\}', 'end'<CR>"
    " for compatibility:
    execute "vnoremap <buffer> ".g:atp_vmap_big_bracket_leader."\\}	:WrapSelection '\\left\\{', '\\right\\}', 'end'<CR>"

    " Tex Align:
    nmap <Localleader>a	:TexAlign<CR>
    " Paragraph Selecting:
    vmap <silent> <buffer> ip 	<Plug>ATP_SelectCurrentParagraphInner
    vmap <silent> <buffer> ap 	<Plug>ATP_SelectCurrentParagraphOuter
    omap <buffer>  ip	:normal vip<CR>
    omap <buffer>  ap	:normal vap<CR>

    " Formating:
    nmap <buffer> gw		m`vipgq``
    " Indent:
    nmap <buffer> g>		m`vip>``
    nmap <buffer> g<		m`vip<``
    nmap <buffer> 2g>		m`vip2>``
    nmap <buffer> 2g<		m`vip2<``
    nmap <buffer> 3g>		m`vip3>``
    nmap <buffer> 3g<		m`vip3<``
    nmap <buffer> 4g>		m`vip4>``
    nmap <buffer> 4g<		m`vip4<``
    nmap <buffer> 5g>		m`vip5>``
    nmap <buffer> 5g<		m`vip5<``
    nmap <buffer> 6g>		m`vip6>``
    nmap <buffer> 6g<		m`vip6<``

    vmap <buffer> <silent> aS		<Plug>SelectOuterSyntax
    vmap <buffer> <silent> iS		<Plug>SelectInnerSyntax

    " From vim.vim plugin (by Bram Mooleaner)
    " Move around functions.
    nnoremap <silent><buffer> [[ m':call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "bW")<CR>
    vnoremap <silent><buffer> [[ m':<C-U>exe "normal! gv"<Bar>call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "bW")<CR>
    nnoremap <silent><buffer> ]] m':call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "W")<CR>
    vnoremap <silent><buffer> ]] m':<C-U>exe "normal! gv"<Bar>call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "W")<CR>
    nnoremap <silent><buffer> [] m':call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "bW")<CR>
    vnoremap <silent><buffer> [] m':<C-U>exe "normal! gv"<Bar>call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "bW")<CR>
    nnoremap <silent><buffer> ][ m':call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "W")<CR>
    vnoremap <silent><buffer> ][ m':<C-U>exe "normal! gv"<Bar>call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "W")<CR>

    " Move around comments
    nnoremap <silent><buffer> ]% :call search('^\(\s*%.*\n\)\@<!\(\s*%\)', "W")<CR>
    vnoremap <silent><buffer> ]% :<C-U>exe "normal! gv"<Bar>call search('^\(\s*%.*\n\)\@<!\(\s*%\)', "W")<CR>
    nnoremap <silent><buffer> [% :call search('\%(^\s*%.*\n\)\%(^\s*%\)\@!', "bW")<CR>
    vnoremap <silent><buffer> [% :<C-U>exe "normal! gv"<Bar>call search('\%(^\s*%.*\n\)\%(^\s*%\)\@!', "bW")<CR>

    " Select comment
    vmap <silent><buffer> <LocalLeader>sc	<Plug>vSelectComment

    " Normal mode maps (mostly)
    nmap  <buffer> <LocalLeader>v		<Plug>ATP_ViewOutput
    nmap  <buffer> <F2> 			<Plug>ToggleSpace
    nmap  <buffer> <LocalLeader>s		<Plug>ToggleStar
    " Todo: to doc:
    nmap  <buffer> <LocalLeader>D		<Plug>ToggleDebugMode
    nmap  <buffer> <F4>				<Plug>ChangeEnv
    nmap  <buffer> <S-F4>			<Plug>ToggleEnvForward
"     nmap  <buffer> <S-F4>			<Plug>ToggleEnvBackward
    nmap  <buffer> <C-S-F4>			<Plug>LatexEnvPrompt
"     ToDo:
"     if g:atp_LatexBox
" 	nmap  <buffer> <F3>			:call <Sid>ChangeEnv()<CR>
"     endif
    nmap  <buffer> <F3>        			<Plug>ATP_ViewOutput
    imap  <buffer> <F3> 			<Esc><Plug>ATP_ViewOutput
    nmap  <buffer> <LocalLeader>g 		<Plug>Getpid
    nmap  <buffer> <LocalLeader>t		<Plug>ATP_TOC
    nmap  <buffer> <LocalLeader>L		<Plug>ATP_Labels
    nmap  <buffer> <LocalLeader>l 		<Plug>ATP_TeXCurrent
    nmap  <buffer> <LocalLeader>d 		<Plug>ATP_TeXDebug
    "ToDo: imaps!
    nmap  <buffer> <F5> 			<Plug>ATP_TeXVerbose
    nmap  <buffer> <s-F5> 			<Plug>ToggleAuTeX
    imap  <buffer> <s-F5> 			<Esc><Plug>ToggleAuTeXa
    nmap  <buffer> `<Tab>			<Plug>ToggleTab
    imap  <buffer> `<Tab>			<Plug>ToggleTab
    nmap  <buffer> <LocalLeader>B		<Plug>SimpleBibtex
    nmap  <buffer> <LocalLeader>b		<Plug>BibtexDefault
    nmap  <buffer> <F6>d 			<Plug>Delete
    imap  <buffer> <F6>d			<Esc><Plug>Deletea
    nmap  <buffer> <silent> <F6>l 		<Plug>OpenLog
    imap  <buffer> <silent> <F6>l 		<Esc><Plug>OpenLog
"     nmap  <buffer<LocalLeader>e 		:cf<CR> 
    nnoremap  <buffer> <F6> 			:ShowErrors e<CR>
    inoremap  <buffer> <F6>e 			:ShowErrors e<CR>
    nnoremap  <buffer> <F6>w 			:ShowErrors w<CR>
    inoremap  <buffer> <F6>w 			:ShowErrors w<CR>
    nnoremap  <buffer> <F6>r 			:ShowErrors rc<CR>
    nnoremap  <buffer> <F6>r 			:ShowErrors rc<CR>
    nnoremap  <buffer> <F6>f 			:ShowErrors f<CR>
    inoremap  <buffer> <F6>f 			:ShowErrors f<CR>
    nnoremap  <buffer> <F6>g 			<Plug>PdfFonts
    nnoremap  <buffer> <F1>			:TexDoc<space>
    inoremap  <buffer> <F1> <esc> 		:TexDoc<space>
"     nmap  <buffer> <LocalLeader>pr 		<Plug>SshPrint

    " FONT MAPPINGS
    if g:atp_imap_first_leader == "]" || g:atp_imap_second_leader == "]" || g:atp_imap_third_leader == "]" || g:atp_imap_fourth_leader == "]" 
	inoremap <buffer> ]] ]
    endif
"     execute 'imap <buffer> '.g:atp_imap_second_leader.'rm \textrm{}<Left>'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'rm <Esc>:call Insert("\\textrm{", "\\mathrm{")<Cr>a'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'up \textup{}<Left>'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'md \textmd{}<Left>'
"     execute 'inoremap <buffer>' .g:atp_imap_second_leader.'it \textit{}<Left>'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'it <Esc>:call Insert("\\textit{", "\\mathit{")<Cr>a'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'sl \textsl{}<Left>'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'sc \textsc{}<Left>'
"     execute 'inoremap <buffer>' .g:atp_imap_second_leader.'sf \textsf{}<Left>'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'sf <Esc>:call Insert("\\textsf{", "\\mathsf{")<Cr>a'
"     execute 'inoremap <buffer>' .g:atp_imap_second_leader.'bf \textbf{}<Left>'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'bf <Esc>:call Insert("\\textbf{", "\\mathbf{")<Cr>a'
"     execute 'inoremap <buffer>' .g:atp_imap_second_leader.'tt \texttt{}<Left>'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'tt <Esc>:call Insert("\\texttt{", "\\mathtt{")<Cr>a'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'em \emph{}<Left>'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'no <Esc>:call Insert("\\textnormal{", "\\mathnormal{")<Cr>a'
	    
"     execute 'inoremap <buffer>' .g:atp_imap_second_leader.'mit \mathit{}<Left>'
"     execute 'inoremap <buffer>' .g:atp_imap_second_leader.'mrm \mathrm{}<Left>'
"     execute 'inoremap <buffer>' .g:atp_imap_second_leader.'msf \mathsf{}<Left>'
"     execute 'inoremap <buffer>' .g:atp_imap_second_leader.'mbf \mathbf{}<Left>'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'bb \mathbb{}<Left>'
"     execute 'imap <buffer>' .g:atp_imap_second_leader.'mtt \mathtt{}<Left>'
    execute 'inoremap <buffer>' .g:atp_imap_second_leader.'cal \mathcal{}<Left>'

    " GREEK LETTERS
    execute 'imap <buffer> '.g:atp_imap_first_leader.'a \alpha'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'b \beta'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'c \chi'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'d \delta'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'e \epsilon'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'ve \varepsilon'
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
    execute 'imap <buffer> '.g:atp_imap_first_leader.'W \Omega'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'Z \mathrm{Z}'  

    let infty_leader = (g:atp_imap_first_leader == "#" ? "_" : g:atp_imap_first_leader ) 
    execute 'imap <buffer> '.infty_leader.'8 \infty'  
    execute 'imap <buffer> '.g:atp_imap_first_leader.'& \wedge'  
    execute 'imap <buffer> '.g:atp_imap_first_leader.'+ \bigcup' 
    execute 'imap <buffer> '.g:atp_imap_first_leader.'- \setminus' 

if g:atp_no_env_maps != 1
    if g:atp_env_maps_old == 1
execute 'imap <buffer> '.g:atp_imap_third_leader.'b \begin{}<Left>'
execute 'imap <buffer> '.g:atp_imap_third_leader.'e \end{}<Left>'

execute 'imap <buffer> '.g:atp_imap_third_leader.'c \begin{center}<CR>\end{center}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_fourth_leader.'c \begin{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'d \begin{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_fourth_leader.'u \begin{enumerate}'.g:atp_EnvOptions_enumerate.'<CR>\end{enumerate}<Esc>O\item'
execute 'imap <buffer> '.g:atp_imap_third_leader.'a \begin{align=(getline(".")[col(".")-2]=="*"?"":g:atp_StarMathEnvDefault)<CR>}<CR>\end{align=(getline(".")[col(".")-2]=="*"?"":g:atp_StarMathEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'i \item'
execute 'imap <buffer> '.g:atp_imap_fourth_leader.'i \begin{itemize}'.g:atp_EnvOptions_itemize.'<CR>\end{itemize}<Esc>O\item'
execute 'imap <buffer> '.g:atp_imap_third_leader.'l \begin{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_fourth_leader.'p \begin{proof}<CR>\end{proof}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'p \begin{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'t \begin{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_fourth_leader.'t \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>'

	if g:atp_extra_env_maps == 1
execute 'imap <buffer> '.g:atp_imap_third_leader.'r \begin{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_fourth_leader.'l \begin{flushleft}<CR>\end{flushleft}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'r \begin{flushright}<CR>\end{flushright}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'f \begin{frame}<CR>\end{frame}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_fourth_leader.'q \begin{equation=(getline(".")[col(".")-2]=="*"?"":g:atp_StarMathEnvDefault)<CR>}<CR>\end{equation=(getline(".")[col(".")-2]=="*"?"":g:atp_StarMathEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'n \begin{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'o \begin{=g:atp_EnvNameObservation<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameObservation<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'x \begin{example=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{example=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
	endif
    else
    " New mapping for the insert mode. 
execute 'imap <buffer> '.g:atp_imap_third_leader.'b \begin{}<Left>'
execute 'imap <buffer> '.g:atp_imap_third_leader.'e \end{}<Left>'

execute 'imap <buffer> '.g:atp_imap_third_leader.'t \begin{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'d \begin{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'P \begin{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'l \begin{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'r \begin{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'C \begin{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'p \begin{proof}<CR>\end{proof}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'x \begin{example=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{example=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'n \begin{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'

execute 'imap <buffer> '.g:atp_imap_third_leader.'E \begin{enumerate}'.g:atp_EnvOptions_enumerate.'<CR>\end{enumerate}<Esc>O\item'
execute 'imap <buffer> '.g:atp_imap_third_leader.'I \begin{itemize}'.g:atp_EnvOptions_itemize.'<CR>\end{itemize}<Esc>O\item'
execute 'imap <buffer> '.g:atp_imap_third_leader.'i 	<Esc>:call InsertItem()<CR>a'


execute 'imap <buffer> '.g:atp_imap_third_leader.'a \begin{align=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{align=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'q \begin{equation=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<CR>\end{equation=(getline(".")[col(".")-2]=="*"?"":g:atp_StarEnvDefault)<CR>}<Esc>O'

execute 'imap <buffer> '.g:atp_imap_third_leader.'c \begin{center}<CR>\end{center}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'L \begin{flushleft}<CR>\end{flushleft}<Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'R \begin{flushright}<CR>\end{flushright}<Esc>O'

execute 'imap <buffer> '.g:atp_imap_third_leader.'T \begin{center}<CR>\begin{tikzpicture}<CR>\end{tikzpicture}<CR>\end{center}<Up><Esc>O'
execute 'imap <buffer> '.g:atp_imap_third_leader.'f \begin{frame}<CR>\end{frame}<Esc>O'
endif

	" imap }c \begin{corollary*}<CR>\end{corollary*}<Esc>O
	" imap }d \begin{definition*}<CR>\end{definition*}<Esc>O
	" imap }x \begin{example*}\normalfont<CR>\end{example*}<Esc>O
	" imap }l \begin{lemma*}<CR>\end{lemma*}<Esc>O
	" imap }n \begin{note*}<CR>\end{note*}<Esc>O
	" imap }o \begin{observation*}<CR>\end{observation*}<Esc>O
	" imap }p \begin{proposition*}<CR>\end{proposition*}<Esc>O
	" imap }r \begin{remark*}<CR>\end{remark*}<Esc>O
	" imap }t \begin{theorem*}<CR>\end{theorem*}<Esc>O

    endif

    " Taken from AucTex:
    " Typing __ results in _{}
    function! <SID>SubBracket()
	let s:insert = "_"
	let s:left = getline(line("."))[col(".")-2]
	if s:left == '_'
	    let s:insert = "{}\<Left>"
	endif
	return s:insert
    endfunction
    if g:atp_imap_first_leader == "_" || g:atp_imap_first_leader == "_" || 
		\ g:atp_imap_third_leader == "_" || g:atp_imap_fourth_leader == "_"   
	imap <buffer> __ _{}<Left>
    else
	inoremap <silent> <buffer> _ <C-R>=<SID>SubBracket()<CR>
    endif

    " Taken from AucTex:
    " Typing ^^ results in ^{}
    function! <SID>SuperBracket()
	let s:insert = "^"
	let s:left = getline(line("."))[col(".")-2]
	if s:left == '^'
	    let s:insert = "{}\<Left>"
	endif
	return s:insert
    endfunction
    if g:atp_imap_first_leader == "_" || g:atp_imap_first_leader == "_" || 
		\ g:atp_imap_third_leader == "_" || g:atp_imap_fourth_leader == "_"   
	imap <buffer> ^^ ^{}<Left>
    else
	inoremap <silent> <buffer> ^ <C-R>=<SID>SuperBracket()<CR>
    endif

"     function! <SID>Infty()
" 	let g:insert 	= g:atp_imap_first_leader
" 	let g:left 	= getline(line("."))[col(".")-2]
" 	if g:left == g:atp_imap_first_leader
" 	    let g:insert = "\\infty"
" 	    let g:new_line = strpart(getline("."),0 ,col(".")) . g:insert . strpart(getline("."), col("."))
" 	    call setline(line("."), g:new_line)
" 	    echomsg "new_line:" . g:new_line
" 	else
" 	    normal a
" 	endif
" 	echomsg "col:" . col(".") . " insert:" . g:insert . " left:" . g:left
" 	return g:insert
"     endfunction
"     execute "inoremap <buffer> 8 <ESC>:call <SID>Infty()<CR>"

    execute "imap <buffer> ".g:atp_imap_third_leader."m \\(\\)<Left><Left>"
    execute "imap <buffer> ".g:atp_imap_third_leader."M \\[\\]<Left><Left>"
endif

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
