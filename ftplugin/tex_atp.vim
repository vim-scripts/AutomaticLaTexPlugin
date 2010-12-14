" Title:		Vim filetype plugin file
" Author:		Marcin Szamotulski
" Email:		mszamot [AT] gmail [DOT] com
" URL:			https://launchpad.net/automatictexplugin	
" BUG Trucer:	https://bugs.launchpad.net/automatictexplugin
" Language:		tex
" Last Change: Tue Dec 14 07:00  2010 W
" GetLatestVimScripts: 2945 57 :AutoInstall: tex_atp.vim
" GetLatestVimScripts: 884 1 :AutoInstall: AutoAlign.vim
" Copyright Statement: 
" 	  This file is a part of Automatic Tex Plugin for Vim.
"
"     Automatic Tex Plugin for Vim is free software: you can redistribute it
"     and/or modify it under the terms of the GNU General Public License as
"     published by the Free Software Foundation, either version 3 of the
"     License, or (at your option) any later version.
" 
"     Automatic Tex Plugin for Vim is distributed in the hope that it will be
"     useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
"     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
"     General Public License for more details.
" 
"     You should have received a copy of the GNU General Public License along
"     with Automatic Tex Plugin for Vim.  If not, see <http://www.gnu.org/licenses/>.
"
"     This licence applies to all files shipped with Automatic Tex Plugin.

let b:did_ftplugin	= 1

if !exists("g:atp_reload_functions")
	let g:atp_reload_functions = 0
endif

if &cpoptions =~ '<'
	echohl WarningMsg
	echo "ATP is removing < from cpoptions"
	echohl None
	setl cpoptions-=<
endif

	" Execute the atprc file.
	" They override cached variables
	if filereadable(globpath($HOME, '/.atprc.vim', 1)) && has("unix")

		" Note: in $HOME/.atprc file the user can set all the local buffer
		" variables without using autocommands
		let path = globpath($HOME, '/.atprc.vim', 1)
		execute 'source ' . fnameescape(path)

	else
		let path	= get(split(globpath(&rtp, "**/ftplugin/ATP_files/atprc.vim"), '\n'), 0, "")
		if path != ""
			execute 'source ' . fnameescape(path)
		endif
	endif

	" Source Project Script
	runtime ftplugin/ATP_files/project.vim

	" Functions needed before setting options.
	runtime ftplugin/ATP_files/common.vim

	" Options, global and local variables, autocommands.
	runtime ftplugin/ATP_files/options.vim


	" Compilation related stuff.
	runtime ftplugin/ATP_files/compiler.vim

" 	let compiler_file = findfile('compiler/tex_atp.vim', &rtp)
" 	if compiler_file
" 		execute 'source ' 	. fnameescape(compiler_file)
" 	endif

	" LatexBox addons (by D.Munger, with some modifications).
	if g:atp_LatexBox

		runtime ftplugin/ATP_files/LatexBox_common.vim
		runtime ftplugin/ATP_files/LatexBox_complete.vim
		runtime ftplugin/ATP_files/LatexBox_motion.vim
		runtime ftplugin/ATP_files/LatexBox_latexmk.vim

	endif

	runtime ftplugin/ATP_files/motion.vim

	runtime ftplugin/ATP_files/search.vim

	runtime ftplugin/ATP_files/various.vim

	" Source maps and menu files.
	runtime ftplugin/ATP_files/mappings.vim

	if g:atp_LatexBox

		" LatexBox mappings.
		runtime ftplugin/ATP_files/LatexBox_mappings.vim
			
	endif

	" Source abbreviations.
	runtime ftplugin/ATP_files/abbreviations.vim

	" The menu.
	runtime ftplugin/ATP_files/menu.vim

	" Help functions.
	runtime ftplugin/ATP_files/helpfunctions.vim


" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
