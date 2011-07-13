" This file is a part of ATP.
" Written by Marcin Szamotulski <atp-list@lists.sourceforge.net>
" beamer loads hyperref and its options are available using
" \documentclass[hyperref=<hyperref_option>"]{beamer}
" The same for xcolor package.
let g:atp_documentclass_beamer_options=["ucs", "utf8", "utf8x", "handout", "hyperref=", "xcolor=", "dvips", 
	    \ "draft", "compress", "t", "c", "aspectratio=", "usepdftitle=", "envcountsect", "notheorems", "noamsthm", 
	    \ "8pt", "9pt", '10pt', '11pt', '12pt', 'smaller', 'bigger', '14pt', '17pt', '20pt', 'trans',
	    \ 'ignorenonframetext', 'notes']
" usepdftitle=[true/false]
