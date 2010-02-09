" Vim color file
" Maintainer:	Marcin Szamotulski  <mszamot at gmail dot com>
" Last Change:	2007 Mar 29
" Version:	1.0.0
" URL:		http://www.axisym3.net/jdany/vim-the-editor/#ocean237256
"
" These are the colors of the "Ocean237" theme by Chris Vertonghen modified
" to work on 256-color xterms.
"
set background=dark

highlight clear
if exists("syntax_on")
    syntax reset
endif

"let g:colors_name = "coot-256"

highlight Normal         cterm=none           ctermfg=250 ctermbg=233
highlight NonText        cterm=none           ctermfg=105 ctermbg=233

highlight Visual         		      ctermbg=238
highlight VisualNOS      cterm=bold,underline ctermfg=57  ctermbg=233

highlight Cursor         cterm=none           ctermfg=15  ctermbg=93
highlight CursorIM       cterm=bold           ctermfg=15  ctermbg=93
"highlight CursorColumn
"highlight CursorLine

highlight Directory      ctermfg=5            	ctermbg=233

highlight DiffAdd        cterm=none           	ctermfg=15  ctermbg=22
highlight DiffChange     cterm=none           	ctermfg=207 ctermbg=39
highlight DiffDelete     cterm=none           	ctermfg=19  ctermbg=17
highlight DiffText       cterm=bold           	ctermfg=226 ctermbg=39

highlight Question       cterm=bold           	ctermfg=33  ctermbg=233
highlight ErrorMsg       cterm=bold            	ctermfg=160 ctermbg=233
highlight ModeMsg              			ctermfg=33  ctermbg=233
highlight MoreMsg        	           	ctermfg=39  ctermbg=233
highlight WarningMsg    cterm=bold           	ctermfg=161 ctermbg=233

highlight LineNr                              	ctermfg=57 ctermbg=233
highlight Folded  				ctermfg=57 ctermbg=233	
highlight FoldColumn     cterm=none           	ctermfg=green ctermbg=233
"highlight SignColumn

highlight Search         cterm=bold           	ctermfg=black  	ctermbg=226
highlight IncSearch      cterm=bold        	ctermfg=black  	ctermbg=red
highlight MatchParen     			ctermfg=black	ctermbg=red		 

"highlight PMenu
"highlight PMenuSBar
"highlight PMenuSel
"highlight PMenuThumb

highlight SpecialKey     ctermfg=60           	ctermbg=233

highlight StatusLine     cterm=none           	ctermfg=226 ctermbg=232
highlight StatusLineNC   cterm=none           	ctermfg=245 ctermbg=232
highlight VertSplit      cterm=none          	ctermfg=green   ctermbg=233
highlight WildMenu       cterm=bold           	ctermfg=0   ctermbg=118

highlight Title          cterm=bold           	ctermfg=226 	ctermbg=232

"highlight Menu
"highlight Scrollbar
"highlight Tooltip

"          Syntax         Groups
highlight Comment        cterm=none           	ctermfg=90 ctermbg=233

highlight Constant       ctermfg=125          	ctermbg=233
highlight String         cterm=none           	ctermfg=27   ctermbg=233
"highlight Character
highlight Number         cterm=none           	ctermfg=161  ctermbg=233
highlight Boolean        cterm=none           	ctermfg=161  ctermbg=233
"highlight Float

highlight Identifier     		      	ctermfg=39
highlight Function       cterm=none           	ctermfg=51   ctermbg=233

highlight Statement      cterm=none           	ctermfg=135
"248
highlight Conditional    cterm=none           	ctermfg=27   ctermbg=233
highlight Repeat         cterm=none           	ctermfg=82   ctermbg=233
"highlight Label
highlight Operator       cterm=none	      	ctermfg=40   ctermbg=233
highlight Keyword        cterm=none           	ctermfg=197  ctermbg=233
highlight Exception      cterm=none           	ctermfg=82   ctermbg=233

highlight PreProc        ctermfg=82
highlight Include        cterm=none           	ctermfg=130  ctermbg=233
highlight Define         cterm=none           	ctermfg=39   ctermbg=233
highlight Macro          cterm=none           	ctermfg=39   ctermbg=233
highlight PreCondit      cterm=bold           	ctermfg=125  ctermbg=233

"jak mutt odpala vima i \bf,\textrm itd:
highlight Type           cterm=none           	ctermfg=82               
highlight StorageClass   cterm=none           	ctermfg=21   ctermbg=233
highlight Structure      cterm=none           	ctermfg=21   ctermbg=233
highlight Typedef        cterm=none           	ctermfg=21 ctermbg=233

" $, $$:
highlight Special        cterm=none	      	ctermfg=93
"249
"tex math mode
"highlight SpecialChar
"highlight Tag:
"highlight Delimiter
"highlight SpecialComment
"highlight Debug

highlight Underlined     cterm=underline      	ctermfg=102 ctermbg=233
highlight Ignore         ctermfg=67

"highlight SpellBad       ctermfg=21           	ctermbg=233
"highlight SpellCap       ctermfg=19           	ctermbg=233
"highlight SpellRare      ctermfg=18           	ctermbg=233
"highlight SpellLocal     ctermfg=17           	ctermbg=233

highlight Todo           ctermfg=21           ctermbg=233

highlight TabLine	cterm=none	ctermfg=white 	ctermbg=240
highlight TabLineFill 	cterm=none	ctermfg=white 	ctermbg=240
highlight TabLineSel	cterm=bold	ctermfg=white	ctermbg=57
"highlight TabLineSel	cterm=bold	ctermfg=white	ctermbg=197
" \command
highlight texDelimiter			ctermfg=161	ctermbg=233
" \begin, \end:
highlight texSectionMarker		ctermfg=238	ctermbg=233
highlight texSection	cterm=bold	ctermfg=242	ctermbg=233
highlight texDocType			ctermfg=90	ctermbg=233
highlight texInputFile			ctermfg=90	ctermbg=233
highlight texDocTypeArgs		ctermfg=204	ctermbg=233
highlight texInputFileopt		ctermfg=204	ctermbg=233
highlight texType			ctermfg=40	ctermbg=233
highlight texMath			ctermfg=245	ctermbg=233
highlight texStatement 			ctermfg=245	ctermbg=233
highlight texString			ctermfg=39	ctermbg=233
highlight tesSpecialChar		ctermfg=39	ctermbg=233
" \chapter, \section, ... {theorem} {definition}

highlight Error          ctermfg=196         	ctermbg=233
highlight SpellErrors  	 cterm=underline      	ctermfg=darkred ctermbg=233
highlight SpellBad       ctermfg=196         	ctermbg=233
highlight SpellCap       ctermfg=202         	ctermbg=233
highlight SpellRare      ctermfg=203         	ctermbg=233
highlight SpellLocal     ctermfg=202         	ctermbg=233

" BibSearch
" highlight BibResultsFileNames 	cterm=none      ctermfg=161  		ctermbg=233
" highlight BibResultsLabels	cterm=bold	ctermfg=90		ctermbg=233
" highlight BibResultsMatch	cterm=none      ctermfg=40  		ctermbg=233
" highlight BibResultsGeneral	cterm=none      ctermfg=255		ctermbg=233
" highlight BibResultsEntry	cterm=none      ctermfg=white		ctermbg=233
" highlight BibResultsEntryLabel	cterm=bold      ctermfg=white		ctermbg=233
" highlight BibResultsFirstLine	cterm=none      ctermfg=23		ctermbg=233
" highlight BibResultsFieldLabel	cterm=none      ctermfg=green		ctermbg=233
" highlight BibResultsFieldKeyword cterm=bold	ctermfg=red

hi bibsearchInfo 	ctermfg=33
hi bibsearchComment	cterm=bold 	ctermfg=27
hi bibComment2		cterm=bold 	ctermfg=30
hi bibsearchCommentContents cterm=none	ctermfg=30
hi bibsearchType			ctermfg=24
" hi bibsearchEntryData						ctermfg=magenta
hi bibsearchKey		cterm=bold 		ctermfg=white	
hi bibsearchEntry 			ctermfg=33
    hi bibsearchField 				ctermfg=green
	hi bibsearchEntryKw			ctermfg=white
	hi bibsearchVariable 			ctermfg=white

" powyzej dzialaja ponizej nie
	hi bibsearchVarContents			ctermfg=red
 	hi bibsearchQuote			ctermfg=grey
 	hi bibsearchBrace			ctermfg=grey
 	hi bibsearchParen			ctermfg=grey

" ATP toc file
highlight atp_linenumber	cterm=bold	ctermfg=27
highlight atp_number 				ctermfg=33
highlight atp_chapter 		cterm=bold 	ctermfg=white
highlight atp_chaptertitle 	cterm=bold 	ctermfg=white
highlight atp_section				ctermfg=30
highlight atp_sectiontitle			ctermfg=30
highlight atp_subsection			ctermfg=24
highlight atp_subsectiontitle			ctermfg=24
highlight atp_abstract	cterm=bold	ctermfg=gray

" ATP label file
highlight atp_label_linenr cterm=bold	ctermfg=white
highlight atp_label_name 		ctermfg=green

highlight atp_statusline 	cterm=bold	ctermfg=green 	ctermbg=233
highlight atp_statustitle 	cterm=bold	ctermfg=grey 	ctermbg=233  
highlight atp_statussection 	cterm=bold	ctermfg=yellow 	ctermbg=233  
highlight atp_statusoutdir 			ctermfg=grey 	ctermbg=233 
