" Author:	Marcin Szmotulski
" Description:  This file contains mappings defined by ATP.
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" URL:		https://launchpad.net/automatictexplugin
" Language:	tex
" Last Change:


" maps is a list of list of the form:
" [ "map", "map_args", "mapleader", "lhs", "rhs", "varname", "help msg" ]
" define = 1/0	1 if map is to be defined (this is a place for a variable name, to turn
" maps on/off on the fly) Note that this must be variable name not a value! 
" for example
" [ "inoremap", "<buffer>", "#a", "\\alpha", 1, "\\alpha" ]

" Fucntions used to define maps.


" Commands to library functions (autoload/atplib.vim)

" <c-c> in insert mode doesn't trigger InsertLeave autocommands
" this fixes this.
if g:atp_MapCC
    imap <silent> <buffer> <c-c> <c-[>
endif

if has("gui")
    cmap <buffer> <C-Space> \_s\+
else
    cmap <buffer> <C-@> \_s\+
endif
cmap <buffer> <C-_> \_s\+

command! -buffer -bang -nargs=* FontSearch	:call atplib#FontSearch(<q-bang>, <f-args>)
command! -buffer -bang -nargs=* FontPreview	:call atplib#FontPreview(<q-bang>,<f-args>)
command! -buffer -nargs=1 -complete=customlist,atplib#Fd_completion OpenFdFile	:call atplib#OpenFdFile(<f-args>) 
command! -buffer -nargs=* CloseLastEnvironment	:call atplib#CloseLastEnvironment(<f-args>)
command! -buffer 	  CloseLastBracket	:call atplib#CloseLastBracket()

" let g:atp_map_list	= [ 
" 	    \ [ g:atp_map_forward_motion_leader, 'i', 		':NInput<CR>', 			'nmap <buffer>' ],
" 	    \ [ g:atp_map_backward_motion_leader, 'i', 		':NPnput<CR>', 			'nmap <buffer>' ],
" 	    \ [ g:atp_map_forward_motion_leader, 'gf', 		':NInput<CR>', 			'nmap <buffer>' ],
" 	    \ [ g:atp_map_backward_motion_leader, 'gf',		':NPnput<CR>', 			'nmap <buffer>' ],
" 	    \ [ g:atp_map_forward_motion_leader, 'S', 		'<Plug>GotoNextSubSection',	'nmap <buffer>' ],
" 	    \ [ g:atp_map_backward_motion_leader, 'S', 		'<Plug>vGotoNextSubSection', 	'nmap <buffer>' ],
" 	    \ ] 



" MAPS:
" Add maps, unless the user didn't want them.
if ( !exists("g:no_plugin_maps") || exists("g:no_plugin_maps") && g:no_plugin_maps == 0 ) && 
	    \ ( !exists("g:no_atp_maps") || exists("g:no_plugin_maps") && g:no_atp_maps == 0 ) 

" They are interfering with vim GG.
exe "nmap <buffer> <silent>	".g:atp_goto_section_leader."S		:<C-U>keepjumps exe v:count1.\"SSec\"<CR>"
exe "nmap <buffer> <silent>	".g:atp_goto_section_leader."s		:<C-U>keepjumps exe v:count1.\"Sec\"<CR>"
exe "nmap <buffer> <silent>	".g:atp_goto_section_leader."c		:<C-U>keepjumps exe v:count1.\"Chap\"<CR>"
exe "nmap <buffer> <silent>	".g:atp_goto_section_leader."p		:<C-U>keepjumps exe v:count1.\"Part\"<CR>"

if g:atp_MapCommentLines    
    nmap <buffer> <silent> <LocalLeader>c	<Plug>CommentLines
    vmap <buffer> <silent> <LocalLeader>c	<Plug>CommentLines
    nmap <buffer> <silent> <LocalLeader>u	<Plug>UnCommentLines
    vmap <buffer> <silent> <LocalLeader>u	<Plug>UnCommentLines
endif

nmap <buffer> <silent> t 		<Plug>SyncTexKeyStroke
nmap <buffer> <silent> <S-LeftMouse> 	<LeftMouse><Plug>SyncTexMouse

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

execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."i			:NInput<CR>"
execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."i			:PInput<CR>"
execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."gf			:NInput<CR>"
execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."gf			:PInput<CR>"

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
	noremap <silent> <buffer> }} }
    endif
    if g:atp_map_backward_motion_leader == "{"
	noremap <silent> <buffer> {{ {
    endif

    " ToDo to doc. + vmaps!
    execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."S 	<Plug>GotoNextSubSection"
    execute "vmap <silent> <buffer> ".g:atp_map_forward_motion_leader."S	<Plug>vGotoNextSubSection"
    execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."S 	<Plug>GotoPreviousSubSection"
    execute "vmap <silent> <buffer> ".g:atp_map_backward_motion_leader."S 	<Plug>vGotoPreviousSubSection"
    " Toggle this maps on/off!
    execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."s 	<Plug>GotoNextSection"
    execute "vmap <silent> <buffer> ".g:atp_map_forward_motion_leader."s	<Plug>vGotoNextSection"
    execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."s 	<Plug>GotoPreviousSection"
    execute "vmap <silent> <buffer> ".g:atp_map_backward_motion_leader."s 	<Plug>vGotoPreviousSection"
    if !( g:atp_map_forward_motion_leader == "]" && &l:diff )
	execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."c 	<Plug>GotoNextChapter"
	execute "vmap <silent> <buffer> ".g:atp_map_forward_motion_leader."c 	<Plug>vGotoNextChapter"
    endif
    if !( g:atp_map_backward_motion_leader == "]" && &l:diff )
	execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."c 	<Plug>GotoPreviousChapter"
	execute "vmap <silent> <buffer> ".g:atp_map_backward_motion_leader."c 	<Plug>vGotoPreviousChapter"
    endif
    execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."p 	<Plug>GotoNextPart"
    execute "vmap <silent> <buffer> ".g:atp_map_forward_motion_leader."p 	<Plug>vGotoNextPart"
    execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."p 	<Plug>GotoPreviousPart"
    execute "vmap <silent> <buffer> ".g:atp_map_backward_motion_leader."p 	<Plug>vGotoPreviousPart"

    execute "map <silent> <buffer> ".g:atp_map_forward_motion_leader."e		<Plug>GotoNextEnvironment"
    execute "map <silent> <buffer> ".g:atp_map_forward_motion_leader."E		<Plug>JumptoNextEnvironment"
"     map <silent> <buffer> <C-F> <Plug>GotoNextEnvironment
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."e	<Plug>GotoPreviousEnvironment"
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."E 	<Plug>JumptoPreviousEnvironment"
"     map <silent> <buffer> <C-B> <Plug>GotoPreviousEnvironment
    execute "map <silent> <buffer> ".g:atp_map_forward_motion_leader."m		<Plug>GotoNextMath"
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."m	<Plug>GotoPreviousMath"
    execute "map <silent> <buffer> ".g:atp_map_forward_motion_leader."M		<Plug>GotoNextDisplayedMath"
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."M	<Plug>GotoPreviousDisplayedMath"

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
	vnoremap <buffer> <silent> <F7> 	:WrapSelection \{ } begin<CR>
    endif

    " Fonts:
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."f		:WrapSelection {\\usefont{".g:atp_font_encoding."}{}{}{}\\selectfont\\  } ".(len(g:atp_font_encoding)+11)."<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."mb	:WrapSelection \\mbox{ } begin<CR>"


    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."te	:<C-U>InteligentWrapSelection ['\\textrm{'],['\\text{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."rm	:<C-U>InteligentWrapSelection ['\\textrm{'],['\\mathrm{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."em	:<C-U>InteligentWrapSelection ['\\emph{'],['\\mathit{']<CR>"
"   Suggested Maps:
"     execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."tx	:<C-U>InteligentWrapSelection [''],['\\text{']<CR>"
"     execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."in	:<C-U>InteligentWrapSelection [''],['\\intertext{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."it	:<C-U>InteligentWrapSelection ['\\textit{'],['\\mathit{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."sf	:<C-U>InteligentWrapSelection ['\\textsf{'],['\\mathsf{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."tt	:<C-U>InteligentWrapSelection ['\\texttt{'],['\\mathtt{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."bf	:<C-U>InteligentWrapSelection ['\\textbf{'],['\\mathbf{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."bb	:<C-U>InteligentWrapSelection ['\\textbf{'],['\\mathbb{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."sl	:<C-U>WrapSelection \\textsl{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."sc	:<C-U>WrapSelection \\textsc{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."up	:<C-U>WrapSelection \\textup{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."md	:<C-U>WrapSelection \\textmd{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."un	:<C-U>WrapSelection \\underline{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."ov	:<C-U>WrapSelection \\overline{<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."no	:<C-U>InteligentWrapSelection ['\\textnormal{'],['\\mathnormal{']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_text_font_leader."cal	:<C-U>InteligentWrapSelection [''],['\\mathcal{']<CR>"

    " Environments:
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_environment_leader."C   :WrapSelection \\begin{center} \\end{center} 0 1<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_environment_leader."R   :WrapSelection \\begin{flushright} \\end{flushright} 0 1<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_environment_leader."L   :WrapSelection \\begin{flushleft} \\end{flushleft} 0 1<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_environment_leader."E   :WrapSelection \\begin{equation=b:atp_StarMathEnvDefault<CR>} \\end{equation=b:atp_StarMathEnvDefault<CR>} 0 1<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_environment_leader."A   :WrapSelection \\begin{align=b:atp_StarMathEnvDefault<CR>} \\end{align=b:atp_StarMathEnvDefault<CR>} 0 1<CR>"

    " Math Modes:
    vmap <silent> <buffer> m				:<C-U>WrapSelection \( \)<CR>
    vmap <silent> <buffer> M				:<C-U>WrapSelection \[ \]<CR>

    " Brackets:
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."( 	:WrapSelection ( ) begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."[ 	:WrapSelection [ ] begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."\\{	:WrapSelection \\{ \\} begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."{ 	:WrapSelection { } begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."< 	:WrapSelection < > begin<CR>"
"     execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."{	:<C-U>InteligentWrapSelection ['{', '}'],['\\{', '\\}']<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader.")	:WrapSelection ( ) end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."]	:WrapSelection [ ] end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."\\}	:WrapSelection \\{ \\} end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."}	:WrapSelection { } end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_bracket_leader."> 	:WrapSelection < > end<CR>"

    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."(	:WrapSelection \\left( \\right) begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."[	:WrapSelection \\left[ \\right] begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."{	:WrapSelection \\left\\{ \\right\\} begin<CR>"
    " for compatibility:
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."\\{	:WrapSelection \\left\\{ \\right\\} begin<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader.")	:WrapSelection \\left( \\right) end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."]	:WrapSelection \\left[ \\right] end<CR>"
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."}	:WrapSelection \\left\\{ \\right\\} end<CR>"
    " for compatibility:
    execute "vnoremap <silent> <buffer> ".g:atp_vmap_big_bracket_leader."\\}	:WrapSelection \\left\\{ \\right\\} end<CR>"

    " Tex Align:
    nmap <silent> <buffer> <Localleader>a	:TexAlign<CR>
    " Paragraph Selecting:
    vmap <silent> <buffer> ip 	<Plug>ATP_SelectCurrentParagraphInner
    vmap <silent> <buffer> ap 	<Plug>ATP_SelectCurrentParagraphOuter
    omap <silent> <buffer>  ip	:normal vip<CR>
    omap <silent> <buffer>  ap	:normal vap<CR>

    " Formating:
    nmap <silent> <buffer> gw		m`vipgq``
    " Indent:
    nmap <silent> <buffer> g>		m`vip>``
    nmap <silent> <buffer> g<		m`vip<``
    nmap <silent> <buffer> 2g>		m`vip2>``
    nmap <silent> <buffer> 2g<		m`vip2<``
    nmap <silent> <buffer> 3g>		m`vip3>``
    nmap <silent> <buffer> 3g<		m`vip3<``
    nmap <silent> <buffer> 4g>		m`vip4>``
    nmap <silent> <buffer> 4g<		m`vip4<``
    nmap <silent> <buffer> 5g>		m`vip5>``
    nmap <silent> <buffer> 5g<		m`vip5<``
    nmap <silent> <buffer> 6g>		m`vip6>``
    nmap <silent> <buffer> 6g<		m`vip6<``

    vmap <buffer> <silent> aS		<Plug>SelectOuterSyntax
    vmap <buffer> <silent> iS		<Plug>SelectInnerSyntax

    " From vim.vim plugin (by Bram Mooleaner)
    " Move around functions.
    nnoremap <silent> <buffer> [[ m':call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "bW")<CR>
    vnoremap <silent> <buffer> [[ m':<C-U>exe "normal! gv"<Bar>call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "bW")<CR>
    nnoremap <silent> <buffer> ]] m':call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "W")<CR>
    vnoremap <silent> <buffer> ]] m':<C-U>exe "normal! gv"<Bar>call search('\\begin\s*{\\|\\\@<!\\\[\\|\\\@<!\$\$', "W")<CR>
    nnoremap <silent> <buffer> [] m':call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "bW")<CR>
    vnoremap <silent> <buffer> [] m':<C-U>exe "normal! gv"<Bar>call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "bW")<CR>
    nnoremap <silent> <buffer> ][ m':call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "W")<CR>
    vnoremap <silent> <buffer> ][ m':<C-U>exe "normal! gv"<Bar>call search('\\end\s*{\\|\\\@<!\\\]\\|\\\@<!\$\$', "W")<CR>

    " Move around comments
    nnoremap <silent> <buffer> ]% :call search('^\(\s*%.*\n\)\@<!\(\s*%\)', "W")<CR>
    vnoremap <silent> <buffer> ]% :<C-U>exe "normal! gv"<Bar>call search('^\(\s*%.*\n\)\@<!\(\s*%\)', "W")<CR>
    nnoremap <silent> <buffer> [% :call search('\%(^\s*%.*\n\)\%(^\s*%\)\@!', "bW")<CR>
    vnoremap <silent> <buffer> [% :<C-U>exe "normal! gv"<Bar>call search('\%(^\s*%.*\n\)\%(^\s*%\)\@!', "bW")<CR>

    " Select comment
"     exe "vmap <silent> <buffer> ".g:atp_MapSelectComment." <Plug>vSelectComment"
    exe "map <silent> <buffer> ".g:atp_MapSelectComment." v<Plug>vSelectComment"

    " Normal mode maps (mostly)
    if mapcheck('<LocalLeader>v') == ""
	nmap  <silent> <buffer> <LocalLeader>v		<Plug>ATP_ViewOutput
    endif

"     nmap  <silent> <buffer> <F2> 			<Plug>ToggleSpace
    nmap  <silent> <buffer> <F2> 			q/:call ATP_CmdwinToggleSpace(1)<CR>i
    if mapcheck('Q/', 'n') == ""
	nmap <silent> <buffer> Q/			q/:call ATP_CmdwinToggleSpace(1)<CR>
    endif
    if mapcheck('Q?', 'n') == ""
	nmap <silent> <buffer> Q?			q?:call ATP_CmdwinToggleSpace(1)<CR>
    endif

    if mapcheck('<LocalLeader>s') == ""
	nmap  <silent> <buffer> <LocalLeader>s		<Plug>ToggleStar
    endif

    nmap  <silent> <buffer> <LocalLeader><Localleader>d	<Plug>ToggledebugMode
    nmap  <silent> <buffer> <LocalLeader><Localleader>D	<Plug>ToggleDebugMode
    vmap  <silent> <buffer> <F4>			<Plug>WrapEnvironment
    nmap  <silent> <buffer> <F4>			<Plug>ChangeEnv
    nmap  <silent> <buffer> <S-F4>			<Plug>ToggleEnvForward
"     nmap  <silent> <buffer> <S-F4>			<Plug>ToggleEnvBackward
    nmap  <silent> <buffer> <C-S-F4>			<Plug>LatexEnvPrompt
"     ToDo:
"     if g:atp_LatexBox
" 	nmap <silent> <buffer> <F3>			:call <Sid>ChangeEnv()<CR>
"     endif
    nmap  <silent> <buffer> <F3>        		<Plug>ATP_ViewOutput
    imap  <silent> <buffer> <F3> 			<Esc><Plug>ATP_ViewOutput
    nmap  <silent> <buffer> <LocalLeader>g 		<Plug>Getpid
    nmap  <silent> <buffer> <LocalLeader>t		<Plug>ATP_TOC
    nmap  <silent> <buffer> <LocalLeader>L		<Plug>ATP_Labels
    nmap  <silent> <buffer> <LocalLeader>l 		<Plug>ATP_TeXCurrent
    nmap  <silent> <buffer> <LocalLeader>d 		<Plug>ATP_TeXdebug
    nmap  <silent> <buffer> <LocalLeader>D 		<Plug>ATP_TeXDebug
"     nmap           <buffer> <c-l>			<Plug>ATP_MakeLatex
    "ToDo: imaps!
    nmap  <silent> <buffer> <F5> 			<Plug>ATP_TeXVerbose
    nmap  <silent> <buffer> <s-F5> 			<Plug>ToggleAuTeX
    imap  <silent> <buffer> <s-F5> 			<Esc><Plug>ToggleAuTeXa
    nmap  <silent> <buffer> `<Tab>			<Plug>ToggleTab
    imap  <silent> <buffer> `<Tab>			<Plug>ToggleTab
    nmap  <silent> <buffer> '<Tab>			<Plug>ToggleMathIMaps
    imap  <silent> <buffer> '<Tab>			<Plug>ToggleMathIMapsa
    nmap  <silent> <buffer> <LocalLeader>B		<Plug>SimpleBibtex
    nmap  <silent> <buffer> <LocalLeader>b		<Plug>BibtexDefault
    nmap  <silent> <buffer> <F6>d 			<Plug>Delete
    imap  <silent> <buffer> <F6>d			<Esc><Plug>Delete
    nmap  <silent> <buffer> <F6>l 			<Plug>OpenLog
    imap  <silent> <buffer> <F6>l 			<Esc><Plug>OpenLog
    nnoremap  <silent> <buffer> <F6> 			:ShowErrors e<CR>
    inoremap  <silent> <buffer> <F6> 			:ShowErrors e<CR>
    noremap   <silent> <buffer> <LocalLeader>e		:ShowErrors<CR>
    nnoremap  <silent> <buffer> <F6>e 			:ShowErrors e<CR>
    inoremap  <silent> <buffer> <F6>e 			:ShowErrors e<CR>
    nnoremap  <silent> <buffer> <F6>w 			:ShowErrors w<CR>
    inoremap  <silent> <buffer> <F6>w 			:ShowErrors w<CR>
    nnoremap  <silent> <buffer> <F6>r 			:ShowErrors rc<CR>
    inoremap  <silent> <buffer> <F6>r 			:ShowErrors rc<CR>
    nnoremap  <silent> <buffer> <F6>f 			:ShowErrors f<CR>
    inoremap  <silent> <buffer> <F6>f 			:ShowErrors f<CR>
    nnoremap  <silent> <buffer> <F6>g 			<Plug>PdfFonts
    nnoremap           <buffer> <F1>			:TexDoc<space>
    inoremap           <buffer> <F1> 			<Esc>:TexDoc<space>

    " FONT MAPPINGS
    if g:atp_imap_first_leader == "]" || g:atp_imap_second_leader == "]" || g:atp_imap_third_leader == "]" || g:atp_imap_fourth_leader == "]" 
	inoremap <silent> <buffer> ]] ]
    endif
"     execute 'imap <silent> <buffer> '.g:atp_imap_second_leader.'rm \textrm{}<Left>'
if !exists("g:atp_imap_define_fonts")
    let g:atp_imap_define_fonts = 1
endif
    if !exists("g:atp_imap_fonts") || g:atp_reload_variables
	let g:atp_imap_fonts = [
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'rm', '<Esc>:call Insert("\\textrm{", "\\mathrm{")<CR>a', "g:atp_imap_define_fonts", 'rm font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'up', '\textup{}<Left>', 				     "g:atp_imap_define_fonts", 'up font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'md', '\textmd{}<Left>', 				     "g:atp_imap_define_fonts", 'md font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'it', '<Esc>:call Insert("\\textit{", "\\mathit{")<CR>a', "g:atp_imap_define_fonts", 'it font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'sl', '\textsl{}<Left>', 				     "g:atp_imap_define_fonts", 'sl font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'sc', '\textsc{}<Left>', 				     "g:atp_imap_define_fonts", 'sc font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'sf', '<Esc>:call Insert("\\textsf{", "\\mathsf{")<CR>a', "g:atp_imap_define_fonts", 'sf font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'bf', '<Esc>:call Insert("\\textbf{", "\\mathbf{")<CR>a', "g:atp_imap_define_fonts", 'bf font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'tt', '<Esc>:call Insert("\\texttt{", "\\mathtt{")<CR>a', "g:atp_imap_define_fonts", 'tt font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'em', '\emph{}<Left>', 				     "g:atp_imap_define_fonts", 'emphasize font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'no', '<Esc>:call Insert("\\textnormal{", "\\mathnormal{")<Cr>a', "g:atp_imap_define_fonts", 'normal font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'bb', '\mathbb{}<Left>', 				     "g:atp_imap_define_fonts", 'mathbb font'],
	    \ [ 'inoremap', '<silent> <buffer>', g:atp_imap_second_leader, 'cal', '\mathcal{}<Left>', 				     "g:atp_imap_define_fonts", 'mathcal font'],
	\ ]
    endif
    call atplib#MakeMaps(g:atp_imap_fonts)
	    
    " GREEK LETTERS
    if !exists("g:atp_imap_greek_letters") || g:atp_reload_variables
	let g:atp_imap_greek_letters= [
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'a', '\alpha',	 "g:atp_imap_define_greek_letters", '\alpha' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'b', '\beta',	 "g:atp_imap_define_greek_letters", '\beta' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'c', '\chi',	 "g:atp_imap_define_greek_letters", '\chi' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'd', '\delta',	 "g:atp_imap_define_greek_letters", '\delta' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'e', '\epsilon',	 "g:atp_imap_define_greek_letters", '\epsilon' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'v', '\varepsilon', "g:atp_imap_define_greek_letters", '\varepsilon' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'f', '\phi',	 "g:atp_imap_define_greek_letters", '\phi' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'y', '\psi',	 "g:atp_imap_define_greek_letters", '\psi' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'g', '\gamma',	 "g:atp_imap_define_greek_letters", '\gamma' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'h', '\eta',	 "g:atp_imap_define_greek_letters", '\eta' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'k', '\kappa',	 "g:atp_imap_define_greek_letters", '\kappa' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'l', '\lambda',	 "g:atp_imap_define_greek_letters", '\lambda' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'i', '\iota',	 "g:atp_imap_define_greek_letters", '\iota' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'm', '\mu',	 "g:atp_imap_define_greek_letters", '\mu' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'n', '\nu',	 "g:atp_imap_define_greek_letters", '\nu' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'p', '\pi',	 "g:atp_imap_define_greek_letters", '\pi' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'o', '\theta',	 "g:atp_imap_define_greek_letters", '\theta' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'r', '\rho',	 "g:atp_imap_define_greek_letters", '\rho' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 's', '\sigma',	 "g:atp_imap_define_greek_letters", '\sigma' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 't', '\tau',	 "g:atp_imap_define_greek_letters", '\tau' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'u', '\upsilon',	 "g:atp_imap_define_greek_letters", '\upsilon' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'v', '\varsigma',	 "g:atp_imap_define_greek_letters", '\varsigma' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'v', '\vartheta',	 "g:atp_imap_define_greek_letters", '\vartheta' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'w', '\omega',	 "g:atp_imap_define_greek_letters", '\omega' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'x', '\xi',	 "g:atp_imap_define_greek_letters", '\xi' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'z', '\zeta',	 "g:atp_imap_define_greek_letters", '\zeta' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'D', '\Delta',	 "g:atp_imap_define_greek_letters", '\Delta' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'Y', '\Psi',	 "g:atp_imap_define_greek_letters", '\Psi' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'F', '\Phi',	 "g:atp_imap_define_greek_letters", '\Phi' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'G', '\Gamma',	 "g:atp_imap_define_greek_letters", '\Gamma' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'L', '\Lambda',	 "g:atp_imap_define_greek_letters", '\Lambda' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'M', '\Mu',	 "g:atp_imap_define_greek_letters", '\Mu' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'P', '\Pi',	 "g:atp_imap_define_greek_letters", '\Pi' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'O', '\Theta',	 "g:atp_imap_define_greek_letters", '\Theta' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'S', '\Sigma',	 "g:atp_imap_define_greek_letters", '\Sigma' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'T', '\Tau',	 "g:atp_imap_define_greek_letters", '\Tau' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'U', '\Upsilon',	 "g:atp_imap_define_greek_letters", '\Upsilon' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'W', '\Omega',	 "g:atp_imap_define_greek_letters", '\Omega' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'Z', '\mathrm',	 "g:atp_imap_define_greek_letters", '\mathrm' ],
		\ ]
    endif

"     call atplib#MakeMaps(g:atp_imap_greek_letters)
    augroup ATP_MathIMaps_GreekLetters
	au!
	au CursorMovedI	*.tex 	:call atplib#ToggleMathIMaps(g:atp_imap_greek_letters, 'CursorMovedI')
	au CursorHoldI 	*.tex 	:call atplib#ToggleMathIMaps(g:atp_imap_greek_letters, 'CursorHoldI')
	au InsertEnter	*.tex 	:call atplib#ToggleMathIMaps(g:atp_imap_greek_letters, 'InsertEnter') 
	" Make imaps visible with :imap /this will not work with i_CTRL-C/
	au InsertLeave	*.tex 	:call atplib#MakeMaps(g:atp_imap_greek_letters, 'InsertLeave')
	au BufEnter	*.tex 	:call atplib#MakeMaps(g:atp_imap_greek_letters, 'BufEnter')
    augroup END

    if !exists("g:atp_imap_math_misc") || g:atp_reload_variables
	let leader = (g:atp_imap_first_leader == '#' ? '`' : g:atp_imap_first_leader ) 
	let g:atp_imap_math_misc = [
		\ [ 'inoremap', '<silent> <buffer>', leader, 		      '8', '\infty', 	"g:atp_imap_define_math_misc", '\infty' ],
		\ [ 'inoremap', '<silent> <buffer>', leader,                  '6', '\partial', 	"g:atp_imap_define_math_misc", '\partial' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '&', '\wedge', 	"g:atp_imap_define_math_misc", '\wedge' ], 
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 've', '\vee', 	"g:atp_imap_define_math_misc", '\vee' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'V', '\Vee', 	"g:atp_imap_define_math_misc", '\Vee' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '+', '\bigcup', 	"g:atp_imap_define_math_misc", '\bigcup' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '*', '\bigcap', 	"g:atp_imap_define_math_misc", '\bigcap' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '\', '\backslash', "g:atp_imap_define_math_misc", '\backslash' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, 'N', '\Nabla', 	"g:atp_imap_define_math_misc", '\Nabla' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '@', '\circ', 	"g:atp_imap_define_math_misc", '\circ' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '=', '\equiv', 	"g:atp_imap_define_math_misc", '\equiv' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '>', '\geq', 	"g:atp_imap_define_math_misc", '\geq' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '<', '\leq', 	"g:atp_imap_define_math_misc", '\leq' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '.', '\dot', 	"g:atp_imap_define_math_misc", '\dot' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '/', '\frac{}{}<Esc>F}i', 	"g:atp_imap_define_math_misc", '\frac{}{}' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_over_leader,  '`', '\grave{}<Left>', 	"g:atp_imap_define_math_misc", '\grave{}' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_over_leader,  'v', '\check{}<Left>', 	"g:atp_imap_define_math_misc", '\check{}' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_over_leader,  '''', '\acute{}<Left>', 	"g:atp_imap_define_math_misc", '\acute{}' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_over_leader,  '.', '\dot{}<Left>', 	"g:atp_imap_define_math_misc", '\dot{}' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_over_leader,  '>', '\vec{}<Left>', 	"g:atp_imap_define_math_misc", '\vec{}' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_over_leader,  '_', '\bar{}<Left>', 	"g:atp_imap_define_math_misc", '\bar{}' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_over_leader,  '~', '\=(g:atp_imap_wide ? "wide" : "")<CR>tilde{}<Left>', 	"g:atp_imap_define_math_misc", '''\''.(g:atp_imap_wide ? "wide" : "")."tilde"' ],
		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_over_leader,  '^', '\=(g:atp_imap_wide ? "wide" : "" )<CR>hat{}<Left>', 	"g:atp_imap_define_math_misc", '''\''.(g:atp_imap_wide ? "wide" : "")."hat"' ], 
		\ ]
" 		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '~', '\=(g:atp_imap_wide ? "wide" : "")<CR>tilde{}<Left>', 	"g:atp_imap_define_math_misc", '''\''.(g:atp_imap_wide ? "wide" : "")."tilde"' ],
" 		\ [ 'inoremap', '<silent> <buffer>', g:atp_imap_first_leader, '^', '\=(g:atp_imap_wide ? "wide" : "" )<CR>hat{}<Left>', 	"g:atp_imap_define_math_misc", '''\''.(g:atp_imap_wide ? "wide" : "")."hat"' ], 
    endif
"     call atplib#MakeMaps(g:atp_imap_math_misc)
    augroup ATP_MathIMaps_misc
	au!
	au CursorMovedI	*.tex 	:call atplib#ToggleMathIMaps(g:atp_imap_math_misc, 'CursorMovedI')
	au CursorHoldI 	*.tex 	:call atplib#ToggleMathIMaps(g:atp_imap_math_misc, 'CursorHoldI') 
	au InsertEnter	*.tex 	:call atplib#ToggleMathIMaps(g:atp_imap_math_misc, 'InsertEnter') 
	" Make imaps visible with :imap /this will not work with i_CTRL-C/
	au InsertLeave	*.tex 	:call atplib#MakeMaps(g:atp_imap_math_misc, 'InsertLeave')
	au BufEnter	*.tex 	:call atplib#MakeMaps(g:atp_imap_math_misc, 'BufEnter')
    augroup END

if g:atp_no_env_maps != 1
    " Left for backward compatibility 
    " New mapping for the insert mode. 
    if !exists("g:atp_imap_environments") || g:atp_reload_variables
    let g:atp_imap_environments = [
	\ [ "inoremap", "<buffer> <silent>", 	g:atp_imap_third_leader, "m", 				'\(\)<Left><Left>', 						"g:atp_imap_define_environments", 'inlince math' ],
	\ [ "inoremap", "<buffer> <silent>", 	g:atp_imap_third_leader, "M", 				'\[\]<Left><Left>', 						"g:atp_imap_define_environments", 'displayed math' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_begin, 		'\begin{}<Left>', 						"g:atp_imap_define_environments", '\begin{}' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_end, 		'\end{}<Left>', 						"g:atp_imap_define_environments", '\end{}' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_proof, 		'\begin{proof}<CR>\end{proof}<Esc>O', 				"g:atp_imap_define_environments", 'proof' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_center, 		'\begin{center}<CR>\end{center}<Esc>O', 			"g:atp_imap_define_environments", 'center' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_flushleft, 		'\begin{flushleft}<CR>\end{flushleft}<Esc>O', 			"g:atp_imap_define_environments", 'flushleft' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_flushright, 	'\begin{flushright}<CR>\end{flushright}<Esc>O', 		"g:atp_imap_define_environments", 'flushright' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_bibliography, 	'\begin{thebibliography}<CR>\end{thebibliography}<Esc>O', 	"g:atp_imap_define_environments", 'bibliography' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_abstract, 		'\begin{abstract}<CR>\end{abstract}<Esc>O', 			"g:atp_imap_define_environments", 'abstract' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_item, 		'<Esc>:call InsertItem()<CR>a', 				"g:atp_imap_define_environments", 'item' 	],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_frame, 		'\begin{frame}<CR>\end{frame}<Esc>O', 				"g:atp_imap_define_environments", 'frame' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_enumerate, 		'\begin{enumerate}'.g:atp_EnvOptions_enumerate.'<CR>\end{enumerate}<Esc>O\item', 	"g:atp_imap_define_environments", 'enumerate' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_itemize, 		'\begin{itemize}'.g:atp_EnvOptions_itemize.'<CR>\end{itemize}<Esc>O\item', 		"g:atp_imap_define_environments", 'itemize' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_tikzpicture, 	'\begin{center}<CR>\begin{tikzpicture}<CR>\end{tikzpicture}<CR>\end{center}<Up><Esc>O', "g:atp_imap_define_environments", 'tikzpicture' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_theorem, 		'\begin{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O',  		"g:atp_imap_define_environments", 'theorem'],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_definition, 	'\begin{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O', 	"g:atp_imap_define_environments", 'definition'],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_proposition, 	'\begin{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O', 	"g:atp_imap_define_environments", 'proposition' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_lemma, 		'\begin{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O', 		"g:atp_imap_define_environments", 'lemma' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_remark, 		'\begin{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O', 		"g:atp_imap_define_environments", 'remark' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_note, 		'\begin{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O', 		"g:atp_imap_define_environments", 'note' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_example, 		'\begin{example=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{example=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O', 		"g:atp_imap_define_environments", 'example' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_corollary, 		'\begin{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O', 	"g:atp_imap_define_environments", 'corollary' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_align, 		'\begin{align=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<CR>\end{align=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<Esc>O', 	"g:atp_imap_define_environments", 'align' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_equation, 		'\begin{equation=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{equation=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O', 	"g:atp_imap_define_environments", 'equation' ],
	\ [ 'inoremap', '<silent> <buffer>',	g:atp_imap_third_leader, g:atp_imap_letter, 		'\begin{letter}{}<CR>\opening{=g:atp_letter_opening<CR>}<CR>\closing{=g:atp_letter_closing<CR>}<CR>\end{letter}<Esc>?\\begin{letter}{\zs<CR>i', 				"g:atp_imap_define_environments", 'letter' ],
	\ ]
    endif
    call atplib#MakeMaps(g:atp_imap_environments)
endif



    if !exists("g:atp_imap_math") || g:atp_reload_variables
    let g:atp_imap_math= [ 
	\ [ "inoremap", "<buffer> <silent> <expr>", "", g:atp_imap_subscript, "!atplib#IsLeft('\\', 1) && atplib#IsInMath() ? '_{}<Left>' : '_' ", "g:atp_imap_define_math", 	'_{}'], 
	\ [ "inoremap", "<buffer> <silent> <expr>", "", g:atp_imap_supscript, "!atplib#IsLeft('\\', 1) && atplib#IsLeft('^') && atplib#IsInMath() ? '<BS>^{}<Left>' : (atplib#IsLeft('~') ? '<BS>\\=(g:atp_imap_wide ? ''wide'' : '''' )<CR>hat{}<Left>' : '^') ", "g:atp_imap_define_math", 	'^{}'], 
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "~", "atplib#IsLeft('~') && atplib#IsInMath() ? '<BS>\\=(g:atp_imap_wide ? \"wide\" : \"\" ) <CR>tilde{}<Left>' : '~' " , "g:atp_imap_define_math", 	'^{}'], 
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "=", "atplib#IsInMath() && atplib#IsLeft('=') && !atplib#IsLeft('&',1) ? '<BS>&=' : '='", "g:atp_imap_define_math",	'&=' ],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "o+", "atplib#IsInMath() ? '\\oplus' 	: 'o+' ", "g:atp_imap_define_math", 		'\\oplus' ],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "O+", "atplib#IsInMath() ? '\\bigoplus' 	: 'O+' ", "g:atp_imap_define_math",		'\\bigoplus'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "o-", "atplib#IsInMath() ? '\\ominus' 	: 'o-' ", "g:atp_imap_define_math",		'\\ominus'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "o.", "atplib#IsInMath() ? '\\odot' 	: 'o.' ", "g:atp_imap_define_math",		'\\odot'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "O.", "atplib#IsInMath() ? '\\bigodot' 	: 'O.' ", "g:atp_imap_define_math",		'\\bigodot'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "o*", "atplib#IsInMath() ? '\\otimes' 	: 'o*' ", "g:atp_imap_define_math",		'\\otimes'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "O*", "atplib#IsInMath() ? '\\bigotimes' 	: 'O*' ", "g:atp_imap_define_math",		'\\bigotimes'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "s+", "atplib#IsInMath() ? '\\cup' 	: 's+' ", "g:atp_imap_define_math",		'\\cup'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "s-", "atplib#IsInMath() ? '\\setminus' 	: 's-' ", "g:atp_imap_define_math",		'\\cup'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "S+", "atplib#IsInMath() ? '\\bigcup' 	: 'S+' ", "g:atp_imap_define_math",		'\\bigcup'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "s*", "atplib#IsInMath() ? '\\cap' 	: 's*' ", "g:atp_imap_define_math",		'\\cap'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "S*", "atplib#IsInMath() ? '\\bigcap' 	: 'S*' ", "g:atp_imap_define_math",		'\\bigcap'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "c*", "atplib#IsInMath() ? '\\prod' 	: 'c*' ", "g:atp_imap_define_math",		'\\prod'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "c+", "atplib#IsInMath() ? '\\coprod' 	: 'c+' ", "g:atp_imap_define_math",		'\\coprod'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "t<", "atplib#IsInMath() ? '\\triangleleft' : 't<' ", "g:atp_imap_define_math",		'\\triangleleft'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "t>", "atplib#IsInMath() ? '\\triangleright' : 't>' ", "g:atp_imap_define_math",		'\\triangleright'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "s<", "atplib#IsInMath() ? '\\subseteq' 	: 's<' ", "g:atp_imap_define_math",		'\\subseteq'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "s>", "atplib#IsInMath() ? '\\supseteq' 	: 's>' ", "g:atp_imap_define_math",		'\\supseteq'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", "<=", "atplib#IsInMath() ? '\\leq' 	: '<=' ", "g:atp_imap_define_math",		'\\leq'],
	\ [ "inoremap", "<buffer> <silent> <expr>", "", ">=", "atplib#IsInMath() ? '\\geq' 	: '>=' ", "g:atp_imap_define_math",		'\\geq'],
	\ ]
    endif
    augroup ATP_MathIMaps
	au!
	au CursorMovedI	*.tex 	:call atplib#ToggleMathIMaps(g:atp_imap_math, 'CursorMovedI')
	au CursorHoldI 	*.tex 	:call atplib#ToggleMathIMaps(g:atp_imap_math, 'CursorHoldI')
	au InsertEnter	*.tex 	:call atplib#ToggleMathIMaps(g:atp_imap_math, 'InsertEnter')
	" Make imaps visible with :imap  /this will not work with i_CTRL-C/
	au InsertLeave	*.tex 	:call atplib#MakeMaps(g:atp_imap_math, 'InsertLeave')
	au BufEnter	*.tex 	:call atplib#MakeMaps(g:atp_imap_math, 'BufEnter')
    augroup END

endif

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
