" syntax clear


syntax keyword texlogKeyword 		LuaTeX LaTeX2e Babel pdfTeXk pdfTeX Web2C pdflatex latex teTeX TeXLive ON OFF 
" Does not work:
" syntax keyword texlogLatexKeyword	LaTeX 			contained

syntax match texlogBrackets		'(\|)\|{\|}\|\[\|\]\|<\|>'

syntax match texlogOpenOut		'\\openout\d\+'

syntax match texlogDate			'\%(\s\|<\)\zs\%(\d\d\s\w\w\w\s\d\d\d\d\s\d\d:\d\d\|\d\d\d\d\/\d\d\/\d\d\)\ze\%(\s\|>\|$\)' 	
syntax match texlogVersion		'\%(v\|ver\)\s*\d*\.\d*\w'
syntax keyword texlogWarningKeyword	obsolete undefined 

syntax match texlogLatexInfo		'LaTeX Info:' 		contains=NONE
syntax match texlogLatexFontInfo	'LaTeX Font Info:' 	contains=NONE
syntax match texlogEndInfo		'Output written on\s\+\%(\S\|\.\|\\\s\|\n\)*' contains=texlogOutputWritten,texlogFileName transparent
syntax match texlogOutputWritten	'Output written on' 	contained 
syntax match texlogPages		'(\zs\_d\+\_s\+pages\ze,\_s*\_d\+\_s\+bytes)'

syntax match texlogPath			'\%(\/\%(\w\|-\|\\\s\|\n\)\+\)\+\%(\.\w\+\)\+'
syntax match texlogFont			'\%(OT\d\|T\d\|OMS\|OML\|U\|OMX\|PD\d\)\n\?\%(\/\_w\+\)\+'
syntax match texlogFontB		'\%(OT\d\|T\d\|OMS\|OML\|U\|OMX\|PD\d\)\n\?+\_w\+'
syntax match texlogFontSize		'<\d\+\%(\.\d\+\)\?>'

syntax match texlogLatexWarning		'LaTeX Warning:' 	contains=NONE
" is visible in synstack but is not highlighted.
syntax match texlogLatexFontWarning	'LaTeX Font Warning:' 	contains=NONE

syntax match texlogPdfTeXWarning	'pdfTeX warning'	contains=NONE

syntax match texlogPackageWarning	'Package\s\+\_w\+\_s\+Warning'
syntax match texlogPackageInfo		'Package\s\+\_w\+\_s\+Info'

syntax match texlogError		'^!.*$'

syntax match texlogOverfullBox		'Overfull\_s\\[hv]box'
syntax match texlogUnderfullBox		'Underfull\_s\\[hv]box'
syntax match texlogTooWide		'too\_swide'

syntax match texlogLineNr		'\%(^l\.\|input\_sline\_s*\)\_d\+\|lines\_s\+\_d\+--\_d\+'
syntax match texlogPageNr		'\[\_d\+\%(\_s*{[^}]*}\)\?\]\|page\_s\_d\+'

syntax match texlogDocumentClass	'Document Class:\s\+\S*'
syntax match texlogPackage		'Package:\s\+\S*'
syntax match texlogFile			'File:\s\+\S*'
syntax match texlogFileName		'\/\zs\%(\w\|\\\s\|-\|\n\)\+\.\%(dvi\|pdf\|ps\)' contained
syntax match texlogCitation		'Citation\s\+\`[^']*\'' 	contains=texlogScope
syntax match texlogReference		'Reference\s\+\`[^']*\'' 	contains=texlogScope
syntax match texlogScope		'\%(\`\|\'\)[^']*\''

syntax match texlogFontShapes		'\Cfont shapes' 
syntax match texlogNotAvailable		'not available'

" syntax match texlogDelimiter		'(\|)'
"
" This works only with 'sync fromstart' which is slow for long log files.
syntax region texlogBracket	start="(" skip="\\[()]"	end=")" transparent contains=texlogPath,texlogLatexInfo,texlogFontInfo,texlogEndInfo,texlogOutputWritten,texlogLatexWarning,texlogLatexFontInfo,texlogLatexFontWarning,texlogPackageWarning,texlogPackageInfo,texlogError,texlogLineNr,texlogPageNr,texlogPackage,texlogDocumentClass,texlogFile,texlogCitation,texlogReference,texlogKeyword,texlogLatexKeyword,texlogScope,texlogFont,texlogFontB,texlogFontSize,texlogOverfullBox,texlogUnderfullBox,texlogTooWide,texlogDate,texlogVersion,texlogWarningKeyword,texlogPages,texlogFontShapes,texlogNotAvailable,texlogOpenOut,texlogPdfTeXWarning,texlogBrackets

syntax sync fromstart 

hi def link texlogKeyword		Keyword
hi def link texlogLatexKeyword		Keyword
hi def link texlogBrackets		Special
hi def link texlogOpenOut		Statement
hi def link texlogWarningKeyword	Identifier
hi def link texlogPath			Include

hi def link texlogLatexInfo 		String

hi def link texlogOutputWritten		String
hi def link texlogFileName		Identifier
hi def link texlogPages			Identifier

hi def link texlogLatexFontInfo 	String
hi def link texlogLatexWarning 		Identifier
hi def link texlogLatexFontWarning 	Identifier
hi def link texlogPackageWarning	Identifier
hi def link texlogPdfTeXWarning		Identifier
hi def link texlogPackageInfo 		String
hi def link texlogError 		Error

hi def link texlogLineNr		Number
hi def link texlogPageNr		Number

hi def link texlogDocumentClass		String
hi def link texlogPackage		String
hi def link texlogFile			String
hi def link texlogCitation		String
hi def link texlogReference		String
hi def link texlogOverfullBox		Function
hi def link texlogUnderfullBox		Function
hi def link texlogTooWide		Function
hi def link texlogScope			Label 

hi def link texlogFont			Label
hi def link texlogFontB			Label
hi def link texlogFontSize		Label
hi def link texlogFontShapes		String
hi def link texlogNotAvailable		Identifier

hi def link texlogDate			Number
hi def link texlogVersion		Number
