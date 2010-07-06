" Author: 	David Munger
" Maintainer:	Marcin Szamotulski

" Latex_Box variables used by tools from David Munger.
if g:atp_LatexBox == 1 || (g:atp_check_if_LatexBox && len(split(globpath(&rtp,'ftplugin/tex_LatexBox.vim')))) 
" {{{
    if !exists('g:LatexBox_cite_pattern')
	    let g:LatexBox_cite_pattern = '\\cite\(p\|t\)\?\*\?\_\s*{'
    endif

    if !exists('g:LatexBox_ref_pattern')
	    let g:LatexBox_ref_pattern = '\\v\?\(eq\|page\)\?ref\*\?\_\s*{'
    endif

    let g:LatexBox_complete_with_brackets = 1
    let g:LatexBox_bibtex_wild_spaces = 1

    let g:LatexBox_completion_environments = [
	    \ {'word': 'itemize',		'menu': 'bullet list' },
	    \ {'word': 'enumerate',		'menu': 'numbered list' },
	    \ {'word': 'description',	'menu': 'description' },
	    \ {'word': 'center',		'menu': 'centered text' },
	    \ {'word': 'figure',		'menu': 'floating figure' },
	    \ {'word': 'table',		'menu': 'floating table' },
	    \ {'word': 'equation',		'menu': 'equation (numbered)' },
	    \ {'word': 'align',		'menu': 'aligned equations (numbered)' },
	    \ {'word': 'align*',		'menu': 'aligned equations' },
	    \ {'word': 'document' },
	    \ {'word': 'abstract' },
	    \ ]

    let g:LatexBox_completion_commands = [
	    \ {'word': '\begin{' },
	    \ {'word': '\end{' },
	    \ {'word': '\item' },
	    \ {'word': '\label{' },
	    \ {'word': '\ref{' },
	    \ {'word': '\eqref{eq:' },
	    \ {'word': '\cite{' },
	    \ {'word': '\nonumber' },
	    \ {'word': '\bibliography' },
	    \ {'word': '\bibliographystyle' },
	    \ ]
" }}}
endif
