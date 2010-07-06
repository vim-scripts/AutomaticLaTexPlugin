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
    let b:atp_autex=0
endfunction
endif
"}}}1
"{{{1 ShowFonts
function! ShowFonts(fd_file)

    let l:font_commands=atplib#ShowFont(a:fd_file)

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
"{{{1 Preview
function! Preview(...)
    if a:0 == 0 
	let l:keep_tex = 0
    else
	let l:keep_tex = a:1
    endif
    let l:b_pos=getpos("'<")[1]
    let l:e_pos=getpos("'>")[1]
"     let b:b=l:b_pos
"     let b:e=l:e_pos
    if getpos("'<") != [0, 0, 0, 0] && getpos("'<") != [0, 0, 0, 0]
" 	let b:deb=1
	let l:fd_files=filter(copy(g:fd_matches),'index(g:fd_matches,v:val)+1 >= l:b_pos-1 && index(g:fd_matches,v:val)+1 <= l:e_pos-1')
    else
" 	let b:deb=2
	let l:fd_files=[g:fd_matches[(max([line("."),'2'])-2)]]
    endif
    let g:fd_files=l:fd_files
    call atplib#Preview(l:fd_files,l:keep_tex)
endfunction
"}}}2
"{{{1 Commands
if bufname("%") =~ 'fd_list'
    command! -buffer -nargs=? -range Preview	:call Preview(<f-args>)
    command! -buffer ShowFonts		:call ShowFonts(g:fd_matches[(max([line("."),'2'])-2)])
    map <buffer> <Enter> 	:call OpenFile()<CR>
    map <buffer> <Tab>		:call ShowFonts(g:fd_matches[(max([line("."),'2'])-2)])<CR>
else
    command! -buffer -nargs=1 Preview	:call atplib#Preview(["buffer"],<f-args>)
endif
"}}}1
"{{{1 Maps
map <buffer> 	P :Preview 1<CR>
map <buffer> 	p :Preview 0<CR>
vmap <buffer> 	P :Preview 1<CR>
vmap <buffer> 	p :Preview 0<CR>
map <buffer> 	Q :bd!<CR>
map <buffer> 	q :q!<CR>R
"}}}1
