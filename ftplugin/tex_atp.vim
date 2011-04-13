" Title:		Vim filetype plugin file
" Author:		Marcin Szamotulski
" URL:			https://sourceforge.net/projects/atp-vim/
" BUGS:			https://lists.sourceforge.net/lists/listinfo/atp-vim-list
" The do NOT DELETE the following line, it is used by :UpdateATP (':help atp-:UpdateATP')
" Time Stamp: 13-04-11_20-33
" (but you can edit, if there is a reason for doing this. The format is dd-mm-yy_HH-MM)
" Language:	    tex
" Last Change: Sat Apr 09 12:00  2011 W
" GetLatestVimScripts: 2945 62 :AutoInstall: tex_atp.vim
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
	let s:atprc_file = globpath($HOME, '.atprc.vim', 1)
	" They override cached variables
	function! <SID>ReadATPRC()
		if filereadable(s:atprc_file) && has("unix")

			" Note: in $HOME/.atprc file the user can set all the local buffer
			" variables without using autocommands
			"
			" Note: it must be sourced at the begining because some options handle
			" how atp will load (for example if we load history or not)
			" It also should be run at the end if the user defines mapping that
			" should be overwrite the ATP settings (this is done via
			" autocommand).
			let path = globpath($HOME, '/.atprc.vim', 1)
			execute 'source ' . fnameescape(path)

		else
			let path	= get(split(globpath(&rtp, "**/ftplugin/ATP_files/atprc.vim"), '\n'), 0, "")
			if path != ""
				execute 'source ' . fnameescape(path)
			endif
		endif
	endfunction

	call <SID>ReadATPRC()
"   This is not working:
" 	augroup ATP_atprc
" 		au! VimEnter * :call <SID>ReadATPRC()
" 	augroup END

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

	" Execute the atprc file.

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
