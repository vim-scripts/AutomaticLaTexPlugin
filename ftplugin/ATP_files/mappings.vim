" Author:	Marcin Szmotulski

" Commands to library functions (autoload/atplib.vim)
command! -buffer -nargs=* FontSearch	:call atplib#FontSearch(<f-args>)
command! -buffer -nargs=* FontPreview	:call atplib#FontPreview(<f-args>)
command! -buffer -nargs=1 -complete=customlist,atplib#Fd_completion OpenFdFile	:call atplib#OpenFdFile(<f-args>) 
command! -buffer -nargs=* CloseLastEnvironment	:call atplib#CloseLastEnvironment(<f-args>)
command! -buffer 	  CloseLastBracket	:call atplib#CloseLastBracket()


" Add maps, unless the user didn't want this.
" ToDo: to doc.
if !exists("no_plugin_maps") && !exists("no_atp_maps")
    " ToDo to doc. + vmaps!
    map <buffer> <LocalLeader>ns 	<Plug>GoToNextSection<CR>
    map <buffer> <LocalLeader>ps 	<Plug>GoToPreviousSection<CR>
    map <buffer> <LocalLeader>nc 	<Plug>GoToNextChapter<CR>
    map <buffer> <LocalLeader>pc 	<Plug>GoToPreviousChapter<CR>
    map <buffer> <LocalLeader>np 	<Plug>GoToNextPart<CR>
    map <buffer> <LocalLeader>pp 	<Plug>GoToPreviousPart<CR>
    " ToDo to doc.
    if exists("g:atp_no_tab_map") && g:atp_no_tab_map == 1
	imap <buffer> <F7> <C-R>=atplib#TabCompletion(1)<CR>
	nmap <buffer> <F7>	:call atplib#TabCompletion(1,1)<CR>
	imap <buffer> <S-F7> <C-R>=atplib#TabCompletion(0)<CR>
	nmap <buffer> <S-F7>	:call atplib#TabCompletion(0,1)<CR> 
    else 
	" the default:
	" this was not working with synstack commands
	imap <buffer> <Tab> <C-R>=atplib#TabCompletion(1)<CR>
	imap <buffer> <S-Tab> <C-R>=atplib#TabCompletion(0)<CR>
	" HOW TO: do this with <tab>? Streightforward solution interacts with
	" other maps (e.g. after \l this map is called).
	" when this is set it also runs after the \l map: ?!?
" 	nmap <buffer> <Tab>	:call atplib#TabCompletion(1,1)<CR>
	nmap <buffer> <S-Tab>	:call atplib#TabCompletion(0,1)<CR> 
	vmap <buffer> <silent> <F7> 	<Plug>WrapSelection<CR>
    endif

"     nmap <buffer> <F7>c :call atplib#CloseLastEnvironment()<CR>
"     imap <buffer> <F7>c <Esc>:call atplib#CloseLastEnvironment()<CR>i
"     nmap <buffer> <F7>b :call atplib#CloseLastBracket()<CR>
"     imap <buffer> <F7>b <Esc>:call atplib#CloseLastBracket()<CR>i

    " Fonts
"     vmap <buffer> f	:WrapSelection '{\usefont{'.g:atp_font_encoding.'}{}{}{}\selectfont ', '}',(len(g:atp_font_encoding)+11)<CR>
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."f		:WrapSelection '{\\usefont{".g:atp_font_encoding."}{}{}{}\\selectfont ', '}', '".(len(g:atp_font_encoding)+11)."'<CR>"

    if !exists("g:atp_vmap_text_font_leader")
	let g:atp_vmap_text_font_leader="<LocalLeader>"
    else
	let g:debug=1
    endif

    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."rm		:WrapSelection '\\textrm{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."em		:WrapSelection '\\emph{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."it		:WrapSelection '\\textit{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."sf		:WrapSelection '\\textsf{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."tt		:WrapSelection '\\texttt{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."bf		:WrapSelection '\\textbf{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."sl		:WrapSelection '\\textsl{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."sc		:WrapSelection '\\textsc{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."up		:WrapSelection '\\textup{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_text_font_leader."md		:WrapSelection '\\textmd{'<CR>"

    " Math Fonts
    if !exists("g:atp_vmap_math_font_leader")
	let g:atp_vmap_math_font_leader="<LocalLeader>m"
    endif
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."rm		:WrapSelection '"."\\"."mathrm{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."bf		:WrapSelection '"."\\"."mathbf{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."it		:WrapSelection '"."\\"."mathit{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."sf		:WrapSelection '"."\\"."mathsf{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."tt		:WrapSelection '"."\\"."mathtt{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."n		:WrapSelection '"."\\"."mathnormal{'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_math_font_leader."cal		:WrapSelection '"."\\"."mathcal{'<CR>"
"     vmap <buffer> <LocalLeader>c				:WrapSelection '\textcolor{}{','}','10'<CR>

    " Environments
    if !exists("atp_vmap_environment_leader")
	let g:atp_vmap_environment_leader=""
    endif
    execute "vmap <buffer> ".g:atp_vmap_environment_leader."C   :WrapSelection '"."\\"."begin{center}','"."\\"."end{center}','0','1'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_environment_leader."R   :WrapSelection '"."\\"."begin{flushright}','"."\\"."end{flushright}','0','1'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_environment_leader."L   :WrapSelection '"."\\"."begin{flushleft}','"."\\"."end{flushleft}','0','1'<CR>"

    " Math modes
    vmap <buffer> m						:WrapSelection '\(', '\)'<CR>
    vmap <buffer> M						:WrapSelection '\[', '\]'<CR>

    " Brackets
    if !exists("*atp_vmap_bracket_leader")
	let g:atp_vmap_bracket_leader="<LocalLeader>"
    endif
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader."( 	:WrapSelection '(', ')', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader."[ 	:WrapSelection '[', ']', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader."{ 	:WrapSelection '{', '}', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader.")	:WrapSelection '(', ')', 'end'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader."]	:WrapSelection '[', ']', 'end'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_bracket_leader."}	:WrapSelection '{', '}', 'end'<CR>"

    if !exists("*atp_vmap_big_bracket_leader")
	let g:atp_vmap_big_bracket_leader='<LocalLeader>b'
    endif
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader."(	:WrapSelection '"."\\"."left(', '"."\\"."right)', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader."[	:WrapSelection '"."\\"."left[', '"."\\"."right]', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader."{	:WrapSelection '"."\\"."left{', '"."\\"."right}', 'begin'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader.")	:WrapSelection '"."\\"."left(', '"."\\"."right)', 'end'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader."]	:WrapSelection '"."\\"."left[', '"."\\"."right]', 'end'<CR>"
    execute "vmap <buffer> ".g:atp_vmap_big_bracket_leader."}	:WrapSelection '"."\\"."left{', '"."\\"."right}', 'end'<CR>"

    nmap <buffer> <LocalLeader>E		<Plug>Echo<CR>
    " Normal mode maps (mostly)
    nmap  <buffer> <LocalLeader>v		<Plug>ATP_ViewOutput<CR>
    nmap  <buffer> <F2> 			<Plug>ToggleSpace<CR>
    nmap  <buffer> <LocalLeader>s		<Plug>ToggleStar<CR>
    " Todo: to doc:
    nmap  <buffer> <LocalLeader>D		<Plug>ToggleDebugMode<CR>
    nmap  <buffer> <F4>				<Plug>ToggleEnvForward<CR>
    nmap  <buffer> <S-F4>			<Plug>ToggleEnvBackward<CR>
    nmap  <buffer> <C-S-F4>			<Plug>LatexEnvPrompt<CR>
"     ToDo:
"     if g:atp_LatexBox
" 	nmap  <buffer> <F3>			:call <Sid>ChangeEnv()<CR>
"     endif
    nmap  <buffer> <F3>        			<Plug>ViewOutput<CR>
    imap  <buffer> <F3> 			<Esc><Plug>ViewOutput<CR>
    nmap  <buffer> <LocalLeader>g 		<Plug>Getpid<CR>
    nmap  <buffer> <LocalLeader>t		<Plug>ATP_TOC<CR>
    nmap  <buffer> <LocalLeader>L		<Plug>ATP_Labels<CR>
    nmap  <buffer> <LocalLeader>l 		<Plug>ATP_TeXCurrent<CR>
    nmap  <buffer> <LocalLeader>d 		<Plug>ATP_TeXDebug<CR>
    "ToDo: imaps!
    nmap  <buffer> <F5> 			<Plug>ATP_TeXVerbose<CR>
    nmap  <buffer> <s-F5> 			<Plug>ToggleAuTeX<CR>
    nmap  <buffer> `<Tab>			<Plug>ToggleTab<CR>
    nmap  <buffer> <LocalLeader>B		<Plug>SimpleBibtex<CR>
    nmap  <buffer> <LocalLeader>b		<Plug>BibtexDefault<CR>
    nmap  <buffer> <F6>d 			:call Delete() <CR>
    imap  <buffer> <silent> <F6>l 		<Plug>OpenLog<CR>
    nmap  <buffer> <silent> <F6>l 		<Plug>OpenLog<CR>
    nmap  <buffer> <LocalLeader>e 		:cf<CR> 
    nmap  <buffer> <F6> 			:ShowErrors e<CR>
    imap  <buffer> <F6> 			:ShowErrors e<CR>
    nmap  <buffer> <F6>w 			:ShowErrors w<CR>
    imap  <buffer> <F6>w 			:ShowErrors w<CR>
    nmap  <buffer> <F6>r 			:ShowErrors rc<CR>
    nmap  <buffer> <F6>r 			:ShowErrors rc<CR>
    nmap  <buffer> <F6>f 			:ShowErrors f<CR>
    imap  <buffer> <F6>f 			:ShowErrors f<CR>
    nmap  <buffer> <F6>g 			<Plug>PdfFonts<CR>
    nmap  <buffer> <F1>				:TeXdoc<space>
    imap  <buffer> <F1> <esc> 			:TeXdoc<space>
    nmap  <buffer> <LocalLeader>p 		<Plug>SshPrint<CR>

    " FONT MAPPINGS
    execute 'imap <buffer> '.g:atp_imap_second_leader.'rm \textrm{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'up \textup{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'md \textmd{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'it \textit{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'sl \textsl{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'sc \textsc{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'sf \textsf{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'bf \textbf{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'tt \texttt{}<Left>'
	    
    execute 'imap <buffer>' .g:atp_imap_second_leader.'mit \mathit{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'mrm \mathrm{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'msf \mathsf{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'mbf \mathbf{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'mtt \mathtt{}<Left>'
    execute 'imap <buffer>' .g:atp_imap_second_leader.'mcal \mathcal{}<Left>'

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
	    execute 'imap <buffer> '.g:atp_imap_fourth_leader.'e \begin{enumerate}<CR>\end{enumerate}<Esc>O'
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
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'b \begin{}<Left>'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'e \end{}<Left>'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'c \begin{center}<CR>\end{center}<Esc>O'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'d \begin{definition}<CR>\end{definition}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'t \begin{theorem}<CR>\end{theorem}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'P \begin{proposition}<CR>\end{proposition}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'l \begin{lemma}<CR>\end{lemma}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'r \begin{remark}<CR>\end{remark}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'o \begin{corollary}<CR>\end{corollary}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'p \begin{proof}<CR>\end{proof}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'x \begin{example}<CR>\end{example}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'n \begin{note}<CR>\end{note}<Esc>O'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'u \begin{enumerate}<CR>\end{enumerate}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'i \begin{itemize}<CR>\end{itemize}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'I \item'


	    execute 'imap <buffer> '.g:atp_imap_third_leader.'a \begin{align}<CR>\end{align}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'q \begin{equation}<CR>\end{equation}<Esc>O'

	    execute 'imap <buffer> '.g:atp_imap_third_leader.'l \begin{flushleft}<CR>\end{flushleft}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'R \begin{flushright}<CR>\end{flushright}<Esc>O'
	    execute 'imap <buffer> '.g:atp_imap_third_leader.'z \begin{center}<CR>\begin{tikzpicture}<CR><CR>\end{tikzpicture}<CR>\end{center}<Up><Up>'
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
