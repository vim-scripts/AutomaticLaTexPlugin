" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 May 31
" URL:		
"{{{1 Load Once
if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1
"}}}1
"{{{1 OpenFile
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
"}}}1
"{{{1 ShowFonts
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
"}}}1
"{{{1 Autocommand
au CursorHold fd_list* :echo g:fd_matches[(max([line("."),'2'])-2)]
"}}}1
"{{{1 Commands
if bufname("%") =~ 'fd_list'
    command! -buffer -nargs=1 Preview	:call atplib#Preview(g:fd_matches[(max([line("."),'2'])-2)],<f-args>)
    command! -buffer ShowFonts		:call ShowFonts(g:fd_matches[(max([line("."),'2'])-2)])
    map <buffer> <Enter> 	:call OpenFile()<CR>
    map <buffer> <Tab>		:call ShowFonts(g:fd_matches[(max([line("."),'2'])-2)])<CR>
else
    command! -buffer -nargs=1 Preview	:call atplib#Preview("buffer",<f-args>)
endif
"}}}1
"{{{1 MapS
noremap <buffer> P :Preview 1<CR>
noremap <buffer> p :Preview 0<CR>
map <buffer> Q :bd!<CR>
map <buffer> q :q!<CR>R
"}}}1
