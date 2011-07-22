" This file is a part of ATP.
" Author: Marcin Szamotulski

let g:atp_package_enumitem_commands=[
	    \ '\setlist{', '\setenumerate{', '\setdescription{',
	    \ '\setitemize{', '\SetEnumerateShortLabel{', '\newlist{', 
	    \ '\AddEnumerateCounter{', '\setdisplayed{' 
	    \ ]
let env_options = [ 'label=', 'label*=', 'start=', 'ref=', 'align=', 'font=',
	\ 'topsep=', 'partopsep=', 'parsep=', 'itemsep=', 'leftmargin=',
	\ 'rightmargin=', 'listparindent=', 'labelwidth=', 'labelsep=', 'labelindent=', 'itemindent=',
	\ 'resume=', 'resume*=', 'beginpenalty=', 'midpenalty=', 'endpenalty=',
	\ 'before=', 'before*=', 'after=', 'after*=', 'style=', 'noitemsep', 'nolistsep', 
	\ 'fullwidth', 'widest=' ]

let g:atp_package_enumitem_environment_options={
    \ '\<\%(enumerate\|itemize\|description\)\>' : env_options
    \ }
let g:atp_package_enumitem_command_values={
    \ '\\setlist{' : env_options
    \ }
