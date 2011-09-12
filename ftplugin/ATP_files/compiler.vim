" Author: 	Marcin Szamotulski	
" Note:		this file contain the main compiler function and related tools, to
" 		view the output, see error file.
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" Language:	tex

" Maps:
"{{{
noremap <silent> <Plug>ATP_ViewOutput	:call atplib_compiler#ViewOutput()<CR>
nmap <buffer> <Plug>SyncTexKeyStroke	:call atplib_compiler#SyncTex("", 0)<CR>
nmap <buffer> <Plug>SyncTexMouse	:call atplib_compiler#SyncTex("", 1)<CR>
noremap <silent> <Plug>ATP_TeXCurrent	:<C-U>call atplib_compiler#TeX(v:count1, "", t:atp_DebugMode)<CR>
noremap <silent> <Plug>ATP_TeXDefault	:<C-U>call atplib_compiler#TeX(v:count1, "", 'default')<CR>
noremap <silent> <Plug>ATP_TeXSilent	:<C-U>call atplib_compiler#TeX(v:count1, "", 'silent')<CR>
noremap <silent> <Plug>ATP_TeXDebug	:<C-U>call atplib_compiler#TeX(v:count1, "", 'Debug')<CR>
noremap <silent> <Plug>ATP_TeXdebug	:<C-U>call atplib_compiler#TeX(v:count1, "", 'debug')<CR>
noremap <silent> <Plug>ATP_TeXVerbose	:<C-U>call atplib_compiler#TeX(v:count1, "", 'verbose')<CR>
inoremap <silent> <Plug>iATP_TeXVerbose	<Esc>:<C-U>call atplib_compiler#TeX(v:count1, "", 'verbose')<CR>
nnoremap <silent> <Plug>SimpleBibtex	:call atplib_compiler#SimpleBibtex()<CR>
nnoremap <silent> <Plug>SimpleBibtex	:call atplib_compiler#Bibtex("")<CR>
nnoremap <silent> <Plug>BibtexDefault	:call atplib_compiler#Bibtex("!", "default")<CR>
nnoremap <silent> <Plug>BibtexSilent	:call atplib_compiler#Bibtex("!", "silent")<CR>
nnoremap <silent> <Plug>Bibtexdebug	:call atplib_compiler#Bibtex("!", "debug")<CR>
nnoremap <silent> <Plug>BibtexDebug	:call atplib_compiler#Bibtex("!", "Debug")<CR>
nnoremap <silent> <Plug>BibtexVerbose	:call atplib_compiler#Bibtex("!", "verbose")<CR>
"}}}
" Commands And Autocommands: 
" {{{
command! -buffer		HighlightErrors		:call atplib#HighlightErrors()
command! -buffer		ClearHighlightErrors	:call atplib#ClearHighlightErrors()
command! -buffer -bang 		Kill			:call atplib_compiler#Kill(<q-bang>)
command! -buffer -nargs=? 	ViewOutput		:call atplib_compiler#ViewOutput(<f-args>)
command! -buffer -bang 		SyncTex			:call atplib_compiler#SyncTex(<q-bang>, 0)
command! -buffer 		PID			:call atplib_compiler#GetPID()
command! -buffer -nargs=? -bang -complete=custom,atplib_compiler#DebugComp MakeLatex		:call atplib_compiler#SetBiberSettings() | call atplib_compiler#MakeLatex(<q-bang>, <q-args>, 0)
nmap <buffer> <Plug>ATP_MakeLatex		:MakeLatex<CR>
command! -buffer -nargs=? -bang -count=1 -complete=custom,atplib_compiler#DebugComp TEX	:call atplib_compiler#TeX(<count>, <q-bang>, <f-args>)
command! -buffer -count=1	DTEX			:call atplib_compiler#TeX(<count>, <q-bang>, 'debug') 
command! -buffer -bang -nargs=? -complete=custom,atplib_compiler#BibtexComp Bibtex		:call atplib_compiler#Bibtex(<q-bang>, <f-args>)
" command! -buffer BibtexOutput	:echo b:atp_BibtexOutput
" command! -buffer MakeidxOutput 	:echo b:atp_MakeidxOutput
command! -buffer -nargs=? -complete=custom,atplib_compiler#ListErrorsFlags_A SetErrorFormat 	:call atplib_compiler#SetErrorFormat(<f-args>,1)

augroup ATP_QuickFix_1
    au!
    au FileType qf command! -buffer -nargs=? -complete=custom,atplib_compiler#ListErrorsFlags_A SetErrorFormat :call atplib_compiler#SetErrorFormat(<q-args>,1)
    au FileType qf command! -buffer -nargs=? -complete=custom,atplib_compiler#ListErrorsFlags_A ErrorFormat :call atplib_compiler#SetErrorFormat(<q-args>,1)
    au FileType qf command! -buffer -nargs=? -complete=custom,atplib_compiler#ListErrorsFlags_A ShowErrors :call atplib_compiler#SetErrorFormat(<f-args>)
augroup END

command! -buffer -nargs=? -complete=custom,atplib_compiler#ListErrorsFlags_A 	ErrorFormat 	:call atplib_compiler#SetErrorFormat(<q-args>,1)
let load_ef=(exists("t:atp_QuickFixOpen") ? !t:atp_QuickFixOpen : 1)
" Note: the following code works nicly with :split (do not reloads the log file) but
" this is not working with :edit
" but one can use: au BufEnter *.tex :cgetfile
if exists("t:atp_QuickFixOpen") && t:atp_QuickFixOpen
    " If QuickFix is opened:
    let load_ef = 0
else
    let load_ef = 1
endif
" let g:load_ef=load_ef
call atplib_compiler#SetErrorFormat(g:atp_DefaultErrorFormat, load_ef)
command! -buffer -nargs=? -complete=custom,atplib_compiler#ListErrorsFlags 	ShowErrors 	:call atplib_compiler#ShowErrors(<f-args>)
" }}}
" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
