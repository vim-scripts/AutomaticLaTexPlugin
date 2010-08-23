" Author:	Marcin Szmotulski

" Commands to library functions (autoload/atplib.vim)
command! -buffer -bang -nargs=* FontSearch	:call atplib#FontSearch(<q-bang>, <f-args>)
command! -buffer -bang -nargs=* FontPreview	:call atplib#FontPreview(<q-bang>,<f-args>)
command! -buffer -nargs=1 -complete=customlist,atplib#Fd_completion OpenFdFile	:call atplib#OpenFdFile(<f-args>) 
command! -buffer -nargs=* CloseLastEnvironment	:call atplib#CloseLastEnvironment(<f-args>)
command! -buffer 	  CloseLastBracket	:call atplib#CloseLastBracket()
command! -buffer NInput				:S /\(\\input\|\\include\s*{\)/
command! -buffer PInput 			:S /\(\\input\|\\include\s*{\)/ b
nmap <buffer> ]gf				:NInput<CR>
nmap <buffer> [gf				:PInput<CR>


" Add maps, unless the user didn't want them.
if !exists("no_plugin_maps") && !exists("no_atp_maps")

    " ToDo to doc. + vmaps!
    map <buffer> <LocalLeader>ns 	<Plug>GoToNextSection
    map <buffer> <LocalLeader>ps 	<Plug>GoToPreviousSection
    map <buffer> <LocalLeader>nc 	<Plug>GoToNextChapter
    map <buffer> <LocalLeader>pc 	<Plug>GoToPreviousChapter
    map <buffer> <LocalLeader>np 	<Plug>GoToNextPart
    map <buffer> <LocalLeader>pp 	<Plug>GoToPreviousPart
    map <buffer> <LocalLeader>ne	<Plug>GoToNextEnvironment
    map <buffer> <LocalLeader>pe	<Plug>GoToPreviousEnvironment

    " Goto File Map:
    if has("path_extra")
	nnoremap <buffer> <silent> gf		:call GotoFile("")<CR>
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
    if !exists("g:atp_vmap_text_font_leader")
	let g:atp_vmap_text_font_leader="<LocalLeader>"
    endif

    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."f		:WrapSelection '{\\usefont{".g:atp_font_encoding."}{}{}{}\\selectfont ', '}', '".(len(g:atp_font_encoding)+11)."'<CR>"


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
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."no	:<C-U>InteligentWrapSelection ['\\textnormal{'],['\\mathnormal{']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_text_font_leader."cal	:<C-U>InteligentWrapSelection [''],['\\mathcal{']<CR>"

    " Environments:
    if !exists("atp_vmap_environment_leader")
	let g:atp_vmap_environment_leader=""
    endif
    execute "vnoremap <buffer> ".g:atp_vmap_environment_leader."C   :WrapSelection '"."\\"."begin{center}','"."\\"."end{center}','0','1'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_environment_leader."R   :WrapSelection '"."\\"."begin{flushright}','"."\\"."end{flushright}','0','1'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_environment_leader."L   :WrapSelection '"."\\"."begin{flushleft}','"."\\"."end{flushleft}','0','1'<CR>"

    " Math Modes:
    vmap <buffer> m						:<C-U>WrapSelection '\(', '\)'<CR>
    vmap <buffer> M						:<C-U>WrapSelection '\[', '\]'<CR>

    " Brackets:
    if !exists("*atp_vmap_bracket_leader")
	let g:atp_vmap_bracket_leader="<LocalLeader>"
    endif
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."( 	:WrapSelection '(', ')', 'begin'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."[ 	:WrapSelection '[', ']', 'begin'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."\\{ 	:WrapSelection '\\{', '\\}', 'begin'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."{ 	:WrapSelection '{', '}', 'begin'<CR>"
"     execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."{	:<C-U>InteligentWrapSelection ['{', '}'],['\\{', '\\}']<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader.")	:WrapSelection '(', ')', 'end'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."]	:WrapSelection '[', ']', 'end'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."\\}	:WrapSelection '\\{', '\\}', 'end'<CR>"
    execute "vnoremap <buffer> ".g:atp_vmap_bracket_leader."}	:WrapSelection '{', '}', 'end'<CR>"

    if !exists("*atp_vmap_big_bracket_leader")
	let g:atp_vmap_big_bracket_leader='<LocalLeader>b'
    endif
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

    nmap <buffer> <LocalLeader>E		<Plug>Echo
    " Normal mode maps (mostly)
    nmap  <buffer> <LocalLeader>v		<Plug>ATP_ViewOutput
    nmap  <buffer> <F2> 			<Plug>ToggleSpace
    nmap  <buffer> <LocalLeader>s		<Plug>ToggleStar
    " Todo: to doc:
    nmap  <buffer> <LocalLeader>D		<Plug>ToggleDebugMode
    nmap  <buffer> <F4>				<Plug>ToggleEnvForward
    nmap  <buffer> <S-F4>			<Plug>ToggleEnvBackward
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
    nmap  <buffer> <LocalLeader>e 		:cf<CR> 
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
    execute 'imap <buffer> '.g:atp_imap_first_leader.'V \Varsigma'
    execute 'imap <buffer> '.g:atp_imap_first_leader.'W \Omega'

    if g:atp_no_env_maps != 1
	if g:atp_env_maps_old == 1
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'b \begin{}<Left>'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'e \end{}<Left>'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'c \begin{center}<CR>\end{center}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'c \begin{corollary}<CR>\end{corollary}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'d \begin{definition}<CR>\end{definition}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'u \begin{enumerate}<CR>\end{enumerate}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'a \begin{align}<CR>\end{align}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'i \item'
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'i \begin{itemize}<CR>\end{itemize}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'l \begin{lemma}<CR>\end{lemma}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'p \begin{proof}<CR>\end{proof}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'p \begin{proposition}<CR>\end{proposition}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'t \begin{theorem}<CR>\end{theorem}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'t \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>'

	    if g:atp_extra_env_maps == 1
		execute 'imap <buffer> '.g:atp_imap_third_leader.'r \begin{remark}<CR>\end{remark}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_fourth_leader.'l \begin{flushleft}<CR>\end{flushleft}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_third_leader.'r \begin{flushright}<CR>\end{flushright}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_third_leader.'f \begin{frame}<CR>\end{frame}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_fourth_leader.'q \begin{equation}<CR>\end{equation}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_third_leader.'n \begin{note}<CR>\end{note}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_third_leader.'o \begin{observation}<CR>\end{observation}<Esc>O'
		execute 'imap <buffer> '.g:atp_imap_third_leader.'x \begin{example}<CR>\end{example}<Esc>O'
	    endif
	else
	    " New mapping for the insert mode. 
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'b \begin{}<Left>'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'e \end{}<Left>'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'c \begin{center}<CR>\end{center}<Esc>O'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'d \begin{definition}<CR>\end{definition}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'t \begin{theorem}<CR>\end{theorem}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'P \begin{proposition}<CR>\end{proposition}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'l \begin{lemma}<CR>\end{lemma}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'r \begin{remark}<CR>\end{remark}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'C \begin{corollary}<CR>\end{corollary}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'p \begin{proof}<CR>\end{proof}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'x \begin{example}<CR>\end{example}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'n \begin{note}<CR>\end{note}<Esc>O'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'E \begin{enumerate}<CR>\end{enumerate}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'I \begin{itemize}<CR>\end{itemize}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'i 	<Esc>:call InsertItem()<CR>a'


	    execute 'imap <buffer> '.g:atp_imap_third_leader.'a \begin{align}<CR>\end{align}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'q \begin{equation}<CR>\end{equation}<Esc>O'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'L \begin{flushleft}<CR>\end{flushleft}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'R \begin{flushright}<CR>\end{flushright}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'T \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'f \begin{frame}<CR>\end{frame}<Esc>O'
	endif

	" imap {c \begin{corollary*}<CR>\end{corollary*}<Esc>O
	" imap {d \begin{definition*}<CR>\end{definition*}<Esc>O
	" imap {x \begin{example*}\normalfont<CR>\end{example*}<Esc>O
	" imap {l \begin{lemma*}<CR>\end{lemma*}<Esc>O
	" imap {n \begin{note*}<CR>\end{note*}<Esc>O
	" imap {o \begin{observation*}<CR>\end{observation*}<Esc>O
	" imap {p \begin{proposition*}<CR>\end{proposition*}<Esc>O
	" imap {r \begin{remark*}<CR>\end{remark*}<Esc>O
	" imap {t \begin{theorem*}<CR>\end{theorem*}<Esc>O

    endif

    imap <buffer> __ _{}<Left>
    imap <buffer> ^^ ^{}<Left>
    imap <buffer> ]m \(\)<Left><Left>
    imap <buffer> ]M \[\]<Left><Left>
endif

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
