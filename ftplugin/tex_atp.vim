" Vim filetype plugin file
" Language:	tex
" Author:	Marcin Szamotulski
" Last Changed: 2010 July 8
" URL:		
" Email:	mszamot [AT] gmail [DOT] com
" GetLatestVimScripts: 2945 32 :AutoInstall: tex_atp.vim
" Copyright:    Copyright (C) 2010 Marcin Szamotulski Permission is hereby 
"		granted to use and distribute this code, with or without
" 		modifications, provided that this copyright notice is copied
" 		with it. Like anything else that's free, Automatic TeX Plugin
" 		is provided *as is* and comes with no warranty of any kind,
" 		either expressed or implied. By using this plugin, you agree
" 		that in no event will the copyright holder be liable for any
" 		damages resulting from the use of this software. 
" 		This licence is valid for all files distributed with ATP
" 		plugin.

let prefix 	= expand('<sfile>:p:h') . '/ATP_files'
let pprefix = expand('<sfile>:p:h:h')

if &cpoptions =~ '<'
	echohl WarningMsg
	echo "ATP is removing < from cpoptions"
	echohl None
	setl cpoptions-=<
endif

	" Functions needed before setting options.
	execute 'source ' 	. fnameescape(prefix . '/common.vim')

	" Options, global and local variables, autocommands.
	execute 'source '  	. fnameescape(prefix . '/options.vim')


	execute 'source ' 	. fnameescape(prefix . '/common.vim')

	" Compilation related stuff.
	execute 'source ' 	. fnameescape(prefix . '/compiler.vim')

	let compiler_file = findfile('tex_atp.vim', &rtp)
	if compiler_file
		execute 'source ' 	. fnameescape(compiler_file)
	endif

	" LatexBox addons (by D.Munger, with some modifications).
	if g:atp_LatexBox
		execute 'source ' . fnameescape(prefix . '/LatexBox_common.vim')
		execute 'source ' . fnameescape(prefix . '/LatexBox_complete.vim')
		execute 'source ' . fnameescape(prefix . '/LatexBox_motion.vim')
	endif


	execute 'source ' . fnameescape(prefix . '/motion.vim')
	execute 'source ' . fnameescape(prefix . '/search.vim')
	execute 'source ' . fnameescape(prefix . '/various.vim')


	" Source maps and menu files.
	execute 'source ' . fnameescape(prefix . '/mappings.vim')

	if g:atp_LatexBox

		" LatexBox mappings.
		execute 'source ' . fnameescape(prefix . '/LatexBox_mappings.vim')
			
	endif

	" The menu.
	execute 'source ' . fnameescape(prefix . '/menu.vim')

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
