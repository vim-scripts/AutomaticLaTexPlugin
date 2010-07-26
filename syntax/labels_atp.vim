" Vim syntax file
" Language:	toc_atp
" Maintainer:	Marcin Szamotulski
" Last Changed: 21/07/2010 
" URL:		

syntax region 	atp_label_line start=/^/ end=/$/ transparent contains=atp_label_sectionnr,atp_label_name,atp_label_linenr  oneline nextgroup=atp_label_section
syntax match 	atp_label_sectionnr	/^\%(\d\%(\d\|\.\)*\)\|\%(\C[IXVL]\+\)/ nextgroup=atp_label_counter,atp_label_name
syntax match 	atp_label_name 		/\s\S.*\ze(/ contains=atp_label_counter
syntax match 	atp_label_counter	/\[\w\=\]/ contained
syntax match  	atp_label_linenr 	/(\d\+)/ nextgroup=atp_label_linenr
syntax match 	atp_label_filename 	/^\(\S\&\D\).*(\/[^)]*)$/	

hi link atp_label_filename 	Title
hi link atp_label_linenr 	LineNr
hi link atp_label_name 		Label
hi link atp_label_counter	Keyword
