" Title:		Vim filetype plugin file
" Author:		Marcin Szamotulski
" Email:		mszamot [AT] gmail [DOT] com
" URL:			https://launchpad.net/automatictexplugin	
" BUG Trucer:	https://bugs.launchpad.net/automatictexplugin
" Language:		tex
" Last Changed: 24 October 2010
" GetLatestVimScripts: 2945 52 :AutoInstall: tex_atp.vim
" GetLatestVimScripts: 884 1 :AutoInstall: AutoAlign.vim
" Copyright Statement: 
" 	  This file is part of Automatic Tex Plugin for Vim.
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

let g:atp_debugMainScript = 0
			" This gives loading time information for debuging purposes.
			" The sourcing of vim scripts is more complicated than this but,
			" at least, this gives some info.
			" Loading times are also acessible using
			" 	vim --startuptime /tmp/time
			" see :h --startuptime
if g:atp_debugMainScript
	redir! >> /tmp/ATP_log
	silent! echo "+++ FILE: " . expand("%")
	let time = reltime()
	let g:time = time
endif

if &cpoptions =~ '<'
	echohl WarningMsg
	echo "ATP is removing < from cpoptions"
	echohl None
	setl cpoptions-=<
endif
	let rtp	= join(map(split(&rtp, ','), 'fnameescape(v:val)'), ',')


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

		if g:atp_debugMainScript
			let g:atprc_loadtime=str2float(reltimestr(reltime(time)))
			silent echo "rc loadtime:        " . string(g:atprc_loadtime)
		endif

	" Source Project Script
	let s:project_src	= findfile("ftplugin/ATP_files/project.vim", rtp) 
	execute 'source ' 	. fnameescape(s:project_src)

		if g:atp_debugMainScript
			let g:atphist_loadtime=str2float(reltimestr(reltime(time)))-g:atprc_loadtime
			silent echo "project loadtime:   " . string(g:atphist_loadtime)
		endif

	" Functions needed before setting options.
	let s:common_src	= findfile("ftplugin/ATP_files/common.vim", rtp) 
	execute 'source ' 	. fnameescape(s:common_src)

		if g:atp_debugMainScript
			let g:atpcom_loadtime=str2float(reltimestr(reltime(time)))-g:atprc_loadtime
			silent echo "com loadtime:       " . string(g:atpcom_loadtime)
		endif

	" Options, global and local variables, autocommands.
	let s:options_src	= findfile("ftplugin/ATP_files/options.vim", rtp) 
	execute 'source '  	. fnameescape(s:options_src)

		if g:atp_debugMainScript
			let g:atpopt_loadtime=str2float(reltimestr(reltime(time)))-g:atpcom_loadtime
			silent echo "opt loadtime:       " . string(g:atpopt_loadtime)
		endif


	" Compilation related stuff.
	let s:compiler_src	= findfile("ftplugin/ATP_files/compiler.vim", rtp) 
	execute 'source ' 	. fnameescape(s:compiler_src)

		if g:atp_debugMainScript
			let g:atpcomp_loadtime=str2float(reltimestr(reltime(time)))-g:atpopt_loadtime
			silent echo "comp loadtime:      " . string(g:atpcomp_loadtime)
		endif

" 	let compiler_file = findfile('compiler/tex_atp.vim', &rtp)
" 	if compiler_file
" 		execute 'source ' 	. fnameescape(compiler_file)
" 	endif

	" LatexBox addons (by D.Munger, with some modifications).
	if g:atp_LatexBox

		let s:LatexBox_common_src		= findfile("ftplugin/ATP_files/LatexBox_common.vim", rtp) 
		execute 'source ' . fnameescape(s:LatexBox_common_src)

		let s:LatexBox_complete_src	= findfile("ftplugin/ATP_files/LatexBox_complete.vim", rtp) 
		execute 'source ' . fnameescape(s:LatexBox_complete_src)

		let s:LatexBox_motion_src		= findfile("ftplugin/ATP_files/LatexBox_motion.vim", rtp) 
		execute 'source ' . fnameescape(s:LatexBox_motion_src)

		let s:LatexBox_latexmk_src		= findfile("ftplugin/ATP_files/LatexBox_latexmk.vim", rtp) 
		execute 'source ' . fnameescape(s:LatexBox_latexmk_src)
	endif

		if g:atp_debugMainScript
			let g:atpLB_loadtime=str2float(reltimestr(reltime(time)))-g:atpcomp_loadtime
			silent echo "LB loadtime:        " . string(g:atpLB_loadtime)
		endif


	let s:motion_src	= findfile("ftplugin/ATP_files/motion.vim", rtp) 
	execute 'source ' . fnameescape(s:motion_src)

		if g:atp_debugMainScript
			let g:atpmot_loadtime=str2float(reltimestr(reltime(time)))-g:atpLB_loadtime
			silent echo "mot loadtime:       " . string(g:atpmot_loadtime)
		endif

	let s:search_src	= findfile("ftplugin/ATP_files/search.vim", rtp) 
	execute 'source ' . fnameescape(s:search_src)

		if g:atp_debugMainScript
			let g:atpsea_loadtime=str2float(reltimestr(reltime(time)))-g:atpmot_loadtime
			silent echo "sea loadtime:       " . string(g:atpsea_loadtime)
		endif

	let s:various_src	= findfile("ftplugin/ATP_files/various.vim", rtp) 
	execute 'source ' . fnameescape(s:various_src)

		if g:atp_debugMainScript
			let g:atpvar_loadtime=str2float(reltimestr(reltime(time)))-g:atpsea_loadtime
			silent echo "var loadtime:       " . string(g:atpvar_loadtime)
		endif


	" Source maps and menu files.
	let s:mappings_src	= findfile("ftplugin/ATP_files/mappings.vim", rtp) 
	execute 'source ' . fnameescape(s:mappings_src)

	if g:atp_LatexBox

		" LatexBox mappings.
		let s:LatexBox_mappings_src		= findfile("ftplugin/ATP_files/LatexBox_mappings.vim", rtp) 
		execute 'source ' . fnameescape(s:LatexBox_mappings_src)
			
	endif

		if g:atp_debugMainScript
			let g:atpmap_loadtime=str2float(reltimestr(reltime(time)))-g:atpvar_loadtime
			silent echo "map loadtime:       " . string(g:atpmap_loadtime)
		endif

	" The menu.
	let s:menu_src	= findfile("ftplugin/ATP_files/menu.vim", rtp) 
	execute 'source ' . fnameescape(s:menu_src)

		if g:atp_debugMainScript
			let g:atpmenu_loadtime=str2float(reltimestr(reltime(time)))-g:atpmap_loadtime
			silent echo "menu loadtime:      " . string(g:atpmenu_loadtime)
		endif

	" Help functions.
	let s:help_src	= findfile("ftplugin/ATP_files/helpfunctions.vim", rtp) 
	execute 'source ' . fnameescape(s:help_src)

		if g:atp_debugMainScript
			let g:atphelp_loadtime=str2float(reltimestr(reltime(time)))-g:atpmenu_loadtime
			silent echo "help loadtime:      " . string(g:atphelp_loadtime)
		endif


		if g:atp_debugMainScript
			let g:atp_loadtime =  str2float(reltimestr(reltime(time)))
			silent echo "LOADTIME:           " . string(g:atp_loadtime)
			redir END
		endif



" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
