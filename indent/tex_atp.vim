" Vim indent file
" Language:     LaTeX
" Maintainer:   Marcin Szamotulski <mszamot [AT] gmail [DOT] com
" Created:      Sat, 16 Feb 2002 16:50:19 +0100
" Last Change:	26 Jun 2010
" Last Update:  26 Jun 2010 by M. Szamotulski
" 			(*) support for \[:\]
" Note: Based on file written by Johannes Tanzler <jtanzler@yline.com>
" URL: comming soon: http://www.unet.univie.ac.at/~a9925098/vim/indent/tex.vim

" --> If you're a Vim guru & and you find something that could be done in a
"     better (perhaps in a more Vim-ish or Vi-ish) way, please let me know! 

" Options: {{{
"
" To set the following options (ok, currently it's just one), add a line like
"   let g:tex_indent_items = 1
" to your ~/.vimrc.
"
" * g:tex_indent_items
"
"   If this variable is set, item-environments are indented like Emacs does
"   it, i.e., continuation lines are indented with a shiftwidth.
"   
"   NOTE: I've already set the variable below; delete the corresponding line
"   if you don't like this behaviour.
"
"   Per default, it is set.
"   
"              set                                unset
"   ----------------------------------------------------------------
"       \begin{itemize}                      \begin{itemize}  
"         \item blablabla                      \item blablabla
"           bla bla bla                        bla bla bla  
"         \item blablabla                      \item blablabla
"           bla bla bla                        bla bla bla  
"       \end{itemize}                        \end{itemize}    
"
"
"   This option applies to itemize, description, enumerate, and
"   thebibliography.
"
" }}} 

" Delete the next line to avoid the special indention of items
if !exists("g:tex_indent_items")
  let g:tex_indent_items = 1
endif

if exists("b:did_indent") | finish
endif
let b:did_indent = 1


" setlocal indentexpr=ATP_GetTeXIndent()
" setlocal nolisp
" setlocal nosmartindent
" setlocal autoindent
" setlocal indentkeys+=},=\\item,=\\bibitem,=\\[,=\\],=<CR>


" Only define the function once
if exists("*GetTeXIndent") | finish
endif



function ATP_GetTeXIndent()

  " Find a non-blank line above the current line.
  let lnum = prevnonblank(v:lnum - 1)
  let pnum = (v:lnum - 1)

  " At the start of the file use zero indent.
  if lnum == 0 | return 0 
  endif

  let ind = indent(lnum)
  let line = getline(lnum)             " last line
  let pline = getline(pnum)      " previous line (one up)
  let cline = getline(v:lnum)          " current line

  " Do not change indentation of commented lines.
  if line =~ '^\s*%'
    return ind
  endif

  " Add a 'shiftwidth' after beginning of environments.
  " Don't add it for \begin{document} and \begin{verbatim}
  " LH modification : \begin does not always start a line
  if line =~ '^\s*\\begin{\(document\|verbatim\)\@![^}]*}' 
    let ind = ind + &sw

    if g:tex_indent_items == 1
      " Add another sw for item-environments
      if line =~ 'itemize\|description\|enumerate\|thebibliography'
        let ind = ind + &sw
      endif
    endif
  endif

  
  " Subtract a 'shiftwidth' when an environment ends
  if cline =~ '^\s*\\end' && cline !~ 'verbatim' 
        \&& cline !~ 'document'

    if g:tex_indent_items == 1
      " Remove another sw for item-environments
      if cline =~ 'itemize\|description\|enumerate\|thebibliography'
        let ind = ind - &sw
      endif
    endif

    let ind = ind - &sw
  endif

  " Special treatment for displayed math \[:\]
  " by M. Szamotulski
  " ----------------------------------
		  
  let b:deb=0
  if cline =~ '^\s*\\\[' && line !~ '\\\]'
      let b:deb.=1
      let ind += &sw
  endif

  if line =~ '^\s*\\\[' && line !~ '\\\]' 
      let b:deb.=2
      let mind = len(matchstr(line,'\\[\zs\s*\ze'))
      let ind += mind + 2
  endif

  let did_mindent=0
  if line =~ '\\\]' && cline !~ '^\s*\\\[' 
      let b:deb.=3
      echo "line ".line
      if cline =~ '\\\['
	  let b:deb.=4
	  let ind -= &sw
      else
	  let b:deb.=5
	  let mind=len(matchstr(getline(search('\\[','bnW')),'\\[\zs\s*\ze'))
	  let ind -= &sw 
	  let did_mindent=1
      endif
  endif

  if line =~ '\\\]' && cline =~ '^\s*\\\]'
      let b:deb.=6
      let mind=len(matchstr(getline(search('\\\[','bnW')),'\\[\zs\s*\ze'))
      let ind -= 3 + mind
  endif

  if (cline =~ '^\s*\\\]' && getline(search('\\\[','bnW')) =~ '^\s*\\\[' && cline !~ '^\s*\\\[')
      let b:deb.=7
      let mind=len(matchstr(getline(search('\\\[','bnW')),'\\\[\zs\s*\ze'))
      let ind -= 2 + mind
  endif

  if  ( line =~ '\S\s*\\\]' && line !~ '^\s*\\\[' && cline  =~ '^\s*\\\[' )
      let b:deb.=9
      let ind -= &sw+1
  endif

  if line =~ '\\\]' && cline !~ '^\s*\\\['
      let b:deb.=8
      let ind=indent(s:search())
  endif

  " Intedation of LaTeX Pragraphs"
  " by M. Szamotulski
  " ----------------------------
 
"   if g:atp_tex_indent_paragraphs == 1
" 	
" "       let b:deb="par ".pline." nr ".pnum." "
" 
"       if pline =~ '^\s*$'
" 	  let b:deb.=1
" 	  ind += &sw
"       endif
" 
"       if getline(s:search()-1) =~ '^\s*$'
" 	  let b:deb.=2
" 	  ind -= &sw
"       endif
" 
"   endif

  " Special treatment for 'item'
  " ----------------------------
  
  if g:tex_indent_items == 1

    " '\item' or '\bibitem' itself:
    if cline =~ '^\s*\\\(bib\)\=item' 
      let ind = ind - &sw
    endif

    " lines following to '\item' are indented once again:
    if line =~ '^\s*\\\(bib\)\=item' 
      let ind = ind + &sw
    endif

  endif

  return ind
endfunction

" Some tools by M.S.:
" is a<=b return 1
function s:sompare(a,b)
    if ( a[0] < b[0] ) || a[0] == b[0] && a[1] < b[1]
	return 1
    elseif ( a[0] == b[0] && a[1] >= b[1] ) || ( a[0] > b[0] )
	return 0
    endif
endfunction

" this function finds first line which doesn't contain \]. 
function! Search()
    let pos_save=getpos(".")
    "chech if inside \[:\]
    let check = searchpair('\\\[','','\\\]', 'bnW',"",max([1,line(".")-g:atp_completion_limits[1]]))
    if check
	let pos=search('\\\[', 'bW')
    else
	let pos=line(".")
    endif

    let line=getline(pos-1)
    while line =~ '\\\]'
	let pos=search('\\\[', 'bW')
	let line=getline(pos-1)
    endwhile
    keepjumps call setpos(".",pos_save)
    return prevnonblank(pos-1)
endfunction
