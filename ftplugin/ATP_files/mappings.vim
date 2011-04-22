" Author:	Marcin Szmotulski
" Description:  This file contains mappings defined by ATP.
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" URL:		https://launchpad.net/automatictexplugin
" Language:	tex
" Last Change:

" Commands to library functions (autoload/atplib.vim)

" <c-c> in insert mode doesn't trigger InsertLeave autocommands
" this fixes this.
if g:atp_MapCC
    imap <silent> <buffer> <c-c> <c-[>
endif

if has("gui")
    cmap <silent> <buffer> <C-Space> \_s\+
else
    cmap <silent> <buffer> <C-@>	\_s\+
endif
cmap <silent> <buffer> <C-_> 	\_s\+

if g:atp_MapUpdateToCLine
    nmap <buffer> <silent> <C-F> <C-F>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <S-Down> <S-Down>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <PageDown> <PageDown>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> z+	z+:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <S-ScrollWheelUp> <S-ScrollWheelUp>:call UpdateToCLine()
    nmap <buffer> <silent> <C-ScrollWheelUp> <C-ScrollWheelUp>:call UpdateToCLine()
    nmap <buffer> <silent> <ScrollWheelUp> <ScrollWheelUp>:call UpdateToCLine()
    nmap <buffer> <silent> <C-U> <C-U>:call UpdateToCLine()<CR>
"     nmap <buffer> <silent> <C-E> <C-E>:call UpdateToCLine()<CR>

    nmap <buffer> <silent> <C-B> <C-B>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <S-ScrollWheelDown> <S-ScrollWheelDown>:call UpdateToCLine()
    nmap <buffer> <silent> <C-ScrollWheelDown> <C-ScrollWheelDown>:call UpdateToCLine()
    nmap <buffer> <silent> <ScrollWheelDown> <ScrollWheelDown>:call UpdateToCLine()
    nmap <buffer> <silent> <S-Up> <S-Up>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <PageUp> <PageUp>:call UpdateToCLine()<CR>
    nmap <buffer> <silent> <C-D> <C-D>:call UpdateToCLine()<CR>
"     nmap <buffer> <silent> <C-Y> <C-Y>:call YpdateToCLine()<CR>

    nmap <buffer> <silent> gj	gj:call UpdateToCLine(1)<CR>
    nmap <buffer> <silent> gk	gk:call UpdateToCLine(1)<CR>

    if maparg('j', 'n') == ''
	nmap <buffer> <silent> j	j:call UpdateToCLine(0)<CR>
    elseif maparg('j', 'n') == 'gj'
	nmap <buffer> <silent> j	gj:call UpdateToCLine(0)<CR>
    endif

    if maparg('k', 'n') == ''
	nmap <buffer> <silent> k	k:call UpdateToCLine(1)<CR>
    elseif maparg('j', 'n') == 'gj'
	nmap <buffer> <silent> k	gk:call UpdateToCLine(1)<CR>
    endif
endif


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

nmap <buffer> <silent>	Gs		:<C-U>keepjumps exe v:count1."Sec"<CR>
nmap <buffer> <silent>	Gc		:<C-U>keepjumps exe v:count1."Chap"<CR>
nmap <buffer> <silent>	Gp		:<C-U>keepjumps exe v:count1."Part"<CR>

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

execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."i				:NInput<CR>"
execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."i				:PInput<CR>"
execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."gf				:NInput<CR>"
execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."gf				:PInput<CR>"

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
    execute "vmap <silent> <buffer> ".g:atp_map_forward_motion_leader."S		<Plug>vGotoNextSubSection"
    execute "nmap <silent> <buffer> ".g:atp_map_backward_motion_leader."S 	<Plug>GotoPreviousSubSection"
    execute "vmap <silent> <buffer> ".g:atp_map_backward_motion_leader."S 	<Plug>vGotoPreviousSubSection"
    " Toggle this maps on/off!
    execute "nmap <silent> <buffer> ".g:atp_map_forward_motion_leader."s 	<Plug>GotoNextSection"
    execute "vmap <silent> <buffer> ".g:atp_map_forward_motion_leader."s		<Plug>vGotoNextSection"
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
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."e		<Plug>GotoPreviousEnvironment"
    execute "map <silent> <buffer> ".g:atp_map_forward_motion_leader."m		<Plug>GotoNextMath"
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."m		<Plug>GotoPreviousMath"
    execute "map <silent> <buffer> ".g:atp_map_forward_motion_leader."M		<Plug>GotoNextDisplayedMath"
    execute "map <silent> <buffer> ".g:atp_map_backward_motion_leader."M		<Plug>GotoPreviousDisplayedMath"

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
    exe "vmap <silent> <buffer> ".g:atp_MapSelectComment." <Plug>vSelectComment"
    exe "map <silent> <buffer> ".g:atp_MapSelectComment." v<Plug>vSelectComment"

    " Normal mode maps (mostly)
    if mapcheck('<LocalLeader>v') == ""
	nmap  <silent> <buffer> <LocalLeader>v		<Plug>ATP_ViewOutput
    endif
"     nmap  <silent> <buffer> <F2> 			<Plug>ToggleSpace
    nmap  <silent> <buffer> <F2> 			q/:call ATP_CmdwinToggleSpace('on')<CR>i
    if mapcheck('Q/', 'n') == ""
	nmap <silent> <buffer> Q/					q/:call ATP_CmdwinToggleSpace('on')<CR>
    endif
    if mapcheck('Q?', 'n') == ""
	nmap <silent> <buffer> Q?					q?:call ATP_CmdwinToggleSpace('on')<CR>
    endif
    if mapcheck('<LocalLeader>s') == ""
	nmap  <silent> <buffer> <LocalLeader>s		<Plug>ToggleStar
    endif

    nmap  <silent> <buffer> <LocalLeader><Localleader>d	<Plug>ToggledebugMode
    nmap  <silent> <buffer> <LocalLeader><Localleader>D	<Plug>ToggleDebugMode
    vmap  <silent> <buffer> <F4>				<Plug>WrapEnvironment
    nmap  <silent> <buffer> <F4>				<Plug>ChangeEnv
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
    "ToDo: imaps!
    nmap  <silent> <buffer> <F5> 			<Plug>ATP_TeXVerbose
    nmap  <silent> <buffer> <s-F5> 			<Plug>ToggleAuTeX
    imap  <silent> <buffer> <s-F5> 			<Esc><Plug>ToggleAuTeXa
    nmap  <silent> <buffer> `<Tab>			<Plug>ToggleTab
    imap  <silent> <buffer> `<Tab>			<Plug>ToggleTab
    nmap  <silent> <buffer> <LocalLeader>B		<Plug>SimpleBibtex
    nmap  <silent> <buffer> <LocalLeader>b		<Plug>BibtexDefault
    nmap  <silent> <buffer> <F6>d 			<Plug>Delete
    imap  <silent> <buffer> <F6>d			<Esc><Plug>Deletea
    nmap  <silent> <buffer> <F6>l 		<Plug>OpenLog
    imap  <silent> <buffer> <F6>l 		<Esc><Plug>OpenLog
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
    nnoremap  <silent> <buffer> <F1>			:TexDoc<space>
    inoremap  <silent> <buffer> <F1> <esc> 		:TexDoc<space>

    " FONT MAPPINGS
    if g:atp_imap_first_leader == "]" || g:atp_imap_second_leader == "]" || g:atp_imap_third_leader == "]" || g:atp_imap_fourth_leader == "]" 
	inoremap <silent> <buffer> ]] ]
    endif
"     execute 'imap <silent> <buffer> '.g:atp_imap_second_leader.'rm \textrm{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'rm <Esc>:call Insert("\\textrm{", "\\mathrm{")<Cr>a'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'up \textup{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'md \textmd{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'it \textit{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'it <Esc>:call Insert("\\textit{", "\\mathit{")<Cr>a'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'sl \textsl{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'sc \textsc{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'sf \textsf{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'sf <Esc>:call Insert("\\textsf{", "\\mathsf{")<Cr>a'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'bf \textbf{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'bf <Esc>:call Insert("\\textbf{", "\\mathbf{")<Cr>a'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'tt \texttt{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'tt <Esc>:call Insert("\\texttt{", "\\mathtt{")<Cr>a'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'em \emph{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'no <Esc>:call Insert("\\textnormal{", "\\mathnormal{")<Cr>a'
	    
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'mit \mathit{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'mrm \mathrm{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'msf \mathsf{}<Left>'
"     execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'mbf \mathbf{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'bb \mathbb{}<Left>'
"     execute 'imap <silent> <buffer>' .g:atp_imap_second_leader.'mtt \mathtt{}<Left>'
    execute 'inoremap <silent> <buffer>' .g:atp_imap_second_leader.'cal \mathcal{}<Left>'

    " GREEK LETTERS
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'a \alpha'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'b \beta'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'c \chi'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'d \delta'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'e \epsilon'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'ve \varepsilon'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'f \phi'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'y \psi'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'g \gamma'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'h \eta'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'k \kappa'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'l \lambda'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'i \iota'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'m \mu'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'n \nu'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'p \pi'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'o \theta'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'r \rho'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'s \sigma'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'t \tau'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'u \upsilon'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'vs \varsigma'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'vo \vartheta'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'w \omega'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'x \xi'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'z \zeta'

    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'D \Delta'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'Y \Psi'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'F \Phi'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'G \Gamma'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'L \Lambda'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'M \Mu'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'N \Nu'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'P \Pi'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'O \Theta'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'S \Sigma'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'T \Tau'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'U \Upsilon'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'W \Omega'
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'Z \mathrm{Z}'  

    let infty_leader = (g:atp_imap_first_leader == "#" ? "_" : g:atp_imap_first_leader ) 
    execute 'imap <silent> <buffer> '.infty_leader.'8 \infty'  
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'& \wedge'  
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'+ \bigcup' 
    execute 'imap <silent> <buffer> '.g:atp_imap_first_leader.'- \setminus' 

if g:atp_no_env_maps != 1
    if g:atp_env_maps_old == 1
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'b \begin{}<Left>'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'e \end{}<Left>'

execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'c \begin{center}<CR>\end{center}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_fourth_leader.'c \begin{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'d \begin{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_fourth_leader.'u \begin{enumerate}'.g:atp_EnvOptions_enumerate.'<CR>\end{enumerate}<Esc>O\item'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'a \begin{align=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<CR>\end{align=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'i \item'
execute 'imap <silent> <buffer> '.g:atp_imap_fourth_leader.'i \begin{itemize}'.g:atp_EnvOptions_itemize.'<CR>\end{itemize}<Esc>O\item'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'l \begin{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_fourth_leader.'p \begin{proof}<CR>\end{proof}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'p \begin{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'t \begin{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_fourth_leader.'t \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>'

	if g:atp_extra_env_maps == 1
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'r \begin{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_fourth_leader.'l \begin{flushleft}<CR>\end{flushleft}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'r \begin{flushright}<CR>\end{flushright}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'f \begin{frame}<CR>\end{frame}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_fourth_leader.'q \begin{equation=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<CR>\end{equation=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'n \begin{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'o \begin{=g:atp_EnvNameObservation<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameObservation<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'x \begin{example=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{example=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
	endif
    else
    " New mapping for the insert mode. 
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'b \begin{}<Left>'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'e \end{}<Left>'

execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'t \begin{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameTheorem<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'d \begin{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameDefinition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer>  '.g:atp_imap_third_leader.'P \begin{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameProposition<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'l \begin{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameLemma<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'r \begin{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameRemark<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'C \begin{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameCorollary<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'p \begin{proof}<CR>\end{proof}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'x \begin{example=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{example=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'n \begin{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{=g:atp_EnvNameNote<CR>=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'

execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'E \begin{enumerate}'.g:atp_EnvOptions_enumerate.'<CR>\end{enumerate}<Esc>O\item'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'I \begin{itemize}'.g:atp_EnvOptions_itemize.'<CR>\end{itemize}<Esc>O\item'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'i 	<Esc>:call InsertItem()<CR>a'


execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'a \begin{align=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<CR>\end{align=(getline(".")[col(".")-2]=="*"?"":b:atp_StarMathEnvDefault)<CR>}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'q \begin{equation=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<CR>\end{equation=(getline(".")[col(".")-2]=="*"?"":b:atp_StarEnvDefault)<CR>}<Esc>O'

execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'c \begin{center}<CR>\end{center}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'L \begin{flushleft}<CR>\end{flushleft}<Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'R \begin{flushright}<CR>\end{flushright}<Esc>O'

execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'T \begin{center}<CR>\begin{tikzpicture}<CR>\end{tikzpicture}<CR>\end{center}<Up><Esc>O'
execute 'imap <silent> <buffer> '.g:atp_imap_third_leader.'f \begin{frame}<CR>\end{frame}<Esc>O'
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
	imap <silent> <buffer> __ _{}<Left>
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
	imap <silent> <buffer> ^^ ^{}<Left>
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
"     execute "inoremap <silent> <buffer> 8 <ESC>:call <SID>Infty()<CR>"

    execute "imap <silent> <buffer> ".g:atp_imap_third_leader."m \\(\\)<Left><Left>"
    execute "imap <silent> <buffer> ".g:atp_imap_third_leader."M \\[\\]<Left><Left>"
endif

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
