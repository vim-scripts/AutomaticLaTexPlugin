" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 May 31
" URL:		

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

if !exists("*OpenFile")
function! OpenFile()
    let l:line=max([line("."),'2'])-2
    let l:file=g:fd_matches[l:line]

    " The list of fd files starts at second line.
    let l:openbuffer="topleft split! +setl\\ nospell\\ ft=fd_atp\\ noro " . fnameescape(l:file)
    silent exe l:openbuffer
    let b:autex=0
endfunction
endif

" keep_tex=1 open the tex file of the sample file, otherwise it is deleted (at
" least from the bufer list).
function! s:Preview(fd_file,keep_tex)
    if a:fd_file != "buffer" 
	let l:fd_file=readfile(a:fd_file)
    else
	let l:fd_file=getline(1,"$")
    endif
    let l:declare_command='\C\%(DeclareFontShape\%(WithSizes\)\?\|sauter@\%(tt\)\?family\|EC@\%(tt\)\?family\|krntstexmplfamily\|HFO@\%(tt\)\?family\)'
    let b:declare_command=l:declare_command
    
    let l:font_decl=[]
    let b:font_decl=l:font_decl
    for l:line in l:fd_file
	if l:line =~ '\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'
	    call add(l:font_decl,l:line)
	endif
    endfor

"     let l:tmp_dir=tempname()
    if exists("b:tmp_dir")
	let b:debug="tmp_dir from b:tmp_dir"
	let l:tmp_dir=b:tmp_dir
    else
	let b:debug="tmp_dir from tempname()"
	let l:tmp_dir=tempname()
    endif
    if !isdirectory(l:tmp_dir)
	call mkdir(l:tmp_dir)
    endif
    if a:fd_file == "buffer"
	let l:testfont_file=l:tmp_dir . "/" . fnamemodify(bufname("%"),":t:r") . ".tex"
    else
	let l:testfont_file=l:tmp_dir . "/" . fnamemodify(a:fd_file,":t:r") . ".tex"
    endif
    call system("touch " . l:testfont_file)
    
    let l:fd_bufnr=bufnr("%")

    let s:text="On November 14, 1885, Senator \\& Mrs.~Leland Stanford called
		\ together at their San Francisco mansion the 24~prominent men who had
		\ been chosen as the first trustees of The Leland Stanford Junior University.
		\ They handed to the board the Founding Grant of the University, which they
		\ had executed three days before.\\\\
		\ (!`THE DAZED BROWN FOX QUICLY GAVE 12345--67890 JUMPS!)"

"     let l:text="On November 14, 1885, Senator \\& Mrs.~Leland Stanford called
" 	\ together at their San Francisco mansion the 24~prominent men who had
" 	\ been chosen as the first trustees of The Leland Stanford Junior University.
" 	\ They handed to the board the Founding Grant of the University, which they
" 	\ had executed three days before. This document---with various amendments,
" 	\ legislative acts, and court decrees---remains as the University's charter.
" 	\ In bold, sweeping language it stipulates that the objectives of the University
" 	\ are ``to qualify students for personal success and direct usefulness in life;
" 	\ and to promote the publick welfare by exercising an influence in behalf of
" 	\ humanity and civilization, teaching the blessings of liberty regulated by
" 	\ law, and inculcating love and reverence for the great principles of
" 	\ government as derived from the inalienable rights of man to life, liberty,
" 	\ and the pursuit of happiness.''\\
" 	\ (!`THE DAZED BROWN FOX QUICKLY GAVE 12345--67890 JUMPS!)\\par}}
" 	\ \\def\\\moretext{?`But aren't Kafka's Schlo{\\ss} and {\\AE}sop's {\\OE}uvres
" 	\ often na{\\"\\i}ve  vis-\\`a-vis the d{\\ae}monic ph{\\oe}nix's official r\\^ole
" 	\ in fluffy souffl\\'es? }
" 	\ \\moretext"

    if a:fd_file == "buffer"
	let l:openbuffer="edit "
    else
	let l:openbuffer="topleft split!"
    endif
    execute l:openbuffer . " +setlocal\\ ft=tex\\ modifiable\\ noro " . l:testfont_file 
    map <buffer> q :bd!<CR>

    call setline(1,'\documentclass{article}')
    call setline(2,'\oddsidemargin=0pt')
    call setline(3,'\textwidth=450pt')
    call setline(4,'\textheight=700pt')
    call setline(5,'\topmargin=-10pt')
    call setline(6,'\headsep=0pt')
    call setline(7,'\begin{document}')

    let l:i=8
    let l:j=1
    let l:len_font_decl=len(l:font_decl)
    let b:match=[]
    for l:font in l:font_decl
	" SHOW THE FONT ENCODING, FAMILY, SERIES and SHAPE
	if matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') == "b" ||
		    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') == "bx"
	    let b:show_font='\noindent{\large \textit{Font Encoding}: \textsf{' . 
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			\ ' \textit{Font Family}: \textsf{' .  
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{[^}#]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			\ ' \textit{Font Series}: \textsf{' .  
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') . '}' . 
			\ ' \textit{Font Shape}: \textsf{' .  
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}') . '}}\\[2pt]'
	else
	    let b:show_font='\noindent{\large \textbf{Font Encoding}: \textsf{' . 
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			\ ' \textbf{Font Family}: \textsf{' .  
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{[^}#]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}\s*{[^#}]*}') . '}' . 
			\ ' \textbf{Font Series}: \textsf{' .  
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}\s*{[^#}]*}') . '}' . 
			\ ' \textbf{Font Shape}: \textsf{' .  
			\ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{\zs[^#}]*\ze}') . '}}\\[2pt]'
	endif
	call setline(l:i,b:show_font)
	let l:i+=1
	" CHANGE THE FONT
	call setline(l:i,'{' . substitute(
		    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'),
		    \ l:declare_command,'usefont','') . 
		    \ '\selectfont')
	" WRITE SAMPLE TEXT
	call add(b:match,matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'))
	let l:i+=1
	" END
	if l:j<l:len_font_decl
	    call setline(l:i,s:text . '}\\\\')
	else
	    call setline(l:i,s:text . '}')
	endif
	let l:i+=1
	let l:j+=1
    endfor
    call setline(l:i,'\end{document}')
    silent w
    if b:texcompiler =~ '^pdf'	
	let l:ext=".pdf"
    else
	let l:ext=".dvi"
    endif
    call system(b:texcompiler . " " . l:testfont_file . 
	    \ " && " . b:Viewer . " " . fnamemodify(l:testfont_file,":p:r") . l:ext ." &")
"	1st TRY 
"     if v:servername == ""	
" 	call system(b:texcompiler . " " . l:testfont_file . 
" 		\ " && " . b:Viewer . " " . fnamemodify(l:testfont_file,":p:r") . l:ext)
"     else
" 	let g:atp_fd_callback=0
" 	call system(b:texcompiler . " " . l:testfont_file . ";vim --servername " . v:servername . " --remote-send <Esc>:let g:atp_fd_callback=1<CR>")
" 	while g:atp_fd_callback==0
" 	    sleep 250m
" 	    redraw!
" 	    echomsg "waiting for fd_callback"
" 	endwhile
" 	call system("xpdf " . fnamemodify(l:testfont_file,":p:r") . l:ext)
"
"	2nd TRY
"     echomsg system("(" . b:texcompiler . " " . l:testfont_file . "2>&1 1>/dev/null" .
" 	    \ " ; " . b:Viewer . " " . fnamemodify(l:testfont_file,":p:r") . l:ext . 
" 	    \ " ;  cat ". fnameescape(fnamemodify(l:testfont_file,":p:r"). ".log") . ")&" )
"
"	3rd TRY
"     let g:log=system("(" . b:texcompiler . " " . l:testfont_file . "2>&1 1>/dev/null" .
" 	    \ " && " . b:Viewer . " " . fnamemodify(l:testfont_file,":p:r") . l:ext . "" .
" 	    \ " || cat ". fnameescape(fnamemodify(l:testfont_file,":p:r"). ".log") . ")" )
"
"	4th & 5th TRIES
"     let g:log=system("(pdflatex ".fnameescape(l:testfont_file)." 2>&1 1>/dev/null "." && xpdf ".fnameescape(fnamemodify(l:testfont_file,":p:r").l:ext)." || cat ".fnameescape(fnamemodify(l:testfont_file,":p:r").".log)&"))
"     let g:log=system("(pdflatex " . expand("%") . "2>&1 1>/dev/null" .  " && " . b:Viewer . " " . fnamemodify(expand("%"),":p:r") . l:ext .  " || cat ". fnameescape(fnamemodify(expand("%"),":p:r"). ".log") . ")&" )
"     let g:shell_error=v:shell_error
"
"     ?:/ 	One can not get shell command output if it is with '&'.
    if !a:keep_tex
	silent exe "bd"
    endif
endfunction

function! ShowFonts(fd_file)
    let l:declare_command='\C\%(DeclareFontShape\%(WithSizes\)\?\|sauter@\%(tt\)\?family\|EC@\%(tt\)\?family\|krntstexmplfamily\|HFO@\%(tt\)\?family\)'
    let b:declare_command=l:declare_command
    
    let l:font_decl=[]
    let b:font_decl=l:font_decl
    for l:line in readfile(a:fd_file)
	if l:line =~ '\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'
	    call add(l:font_decl,l:line)
	endif
    endfor
    let l:font_commands=[]
    for l:font in l:font_decl
	call add(l:font_commands,substitute(
		    \ matchstr(l:font,'\\'.l:declare_command.'\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}\s*{[^#}]*}'),
		    \ l:declare_command,'usefont',''))
    endfor
    let l:message=""
    for l:fcom in l:font_commands
	let l:message.="\n".l:fcom
    endfor
    let l:message="Fonts Declared:".l:message
    call confirm(l:message)
endfunction

" AUTOCOMMANDS
au CursorHold fd_list* :echo g:fd_matches[(max([line("."),'2'])-2)]

" COMMANDS
if bufname("%") =~ 'fd_list'
    command! -buffer -nargs=1 Preview	:call s:Preview(g:fd_matches[(max([line("."),'2'])-2)],<f-args>)
    command! -buffer ShowFonts		:call ShowFonts(g:fd_matches[(max([line("."),'2'])-2)])
    map <buffer> <Enter> 	:call OpenFile()<CR>
    map <buffer> <Tab>		:call ShowFonts(g:fd_matches[(max([line("."),'2'])-2)])<CR>
else
    command! -buffer -nargs=1 Preview	:call s:Preview("buffer",<f-args>)
endif

" MAPS
noremap <buffer> P :Preview 1<CR>
noremap <buffer> p :Preview 0<CR>
map <buffer> Q :bd!<CR>
map <buffer> q :q!<CR>R
