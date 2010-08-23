" Vim filetype plugin file
" Language:	tex
" Author:	Marcin Szamotulski
" Last Changed: 2010 July 23
" URL:		https://launchpad.net/automatictexplugin	
" Email:	mszamot [AT] gmail [DOT] com
" GetLatestVimScripts: 2945 40 :AutoInstall: tex_atp.vim
" GetLatestVimScripts: 884 1 :AutoInstall: AutoAlign.vim
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

let b:did_ftplugin	= 1

let atp_debug = 0
			" This gives loading time information for debuging purposes.
			" The sourcing of vim scripts is more complicated than this but,
			" at least, this gives some info.
if atp_debug
	let time = reltime()
endif

if &cpoptions =~ '<'
	echohl WarningMsg
	echo "ATP is removing < from cpoptions"
	echohl None
	setl cpoptions-=<
endif
	let rtp	= join(map(split(&rtp, ','), 'fnameescape(v:val)'), ',')

	" Execute the atprc file.
	let atp_rc		= ([findfile(".atprc.vim", $HOME)] + [findfile("ftplugin/ATP_files/atprc.vim", rtp)])[0]
	if filereadable(atp_rc)
		execute 'source ' . fnameescape(atp_rc)
	endif

		if atp_debug
			let g:atprc_loadtime=reltimestr(reltime(time))
			echomsg "rc loadtime:" . g:atprc_loadtime
		endif

	" Source History Script
	let history_src	= findfile("ftplugin/ATP_files/history.vim", rtp) 
	execute 'source ' 	. fnameescape(history_src)

		if atp_debug
			let g:atphist_loadtime=string(str2float(reltimestr(reltime(time)))-str2float(g:atprc_loadtime))
			echomsg "hist loadtime:" . g:atphist_loadtime
		endif

	" Functions needed before setting options.
	let common_src	= findfile("ftplugin/ATP_files/common.vim", rtp) 
	execute 'source ' 	. fnameescape(common_src)

		if atp_debug
			let g:atpcom_loadtime=string(str2float(reltimestr(reltime(time)))-str2float(g:atphist_loadtime))
			echomsg "com loadtime:" . g:atpcom_loadtime
		endif

	" Options, global and local variables, autocommands.
	let options_src	= findfile("ftplugin/ATP_files/options.vim", rtp) 
	execute 'source '  	. fnameescape(options_src)

		if atp_debug
			let g:atpopt_loadtime=string(str2float(reltimestr(reltime(time)))-str2float(g:atpcom_loadtime))
			echomsg "opt loadtime:" . g:atpopt_loadtime
		endif


	" Compilation related stuff.
	let compiler_src	= findfile("ftplugin/ATP_files/compiler.vim", rtp) 
	execute 'source ' 	. fnameescape(compiler_src)

		if atp_debug
			let g:atpcomp_loadtime=string(str2float(reltimestr(reltime(time)))-str2float(g:atpopt_loadtime))
			echomsg "comp loadtime:" . g:atpcomp_loadtime
		endif

" 	let compiler_file = findfile('compiler/tex_atp.vim', &rtp)
" 	if compiler_file
" 		execute 'source ' 	. fnameescape(compiler_file)
" 	endif

	" LatexBox addons (by D.Munger, with some modifications).
	if g:atp_LatexBox

		let LatexBox_common_src		= findfile("ftplugin/ATP_files/LatexBox_common.vim", rtp) 
		execute 'source ' . fnameescape(LatexBox_common_src)

		let LatexBox_complete_src	= findfile("ftplugin/ATP_files/LatexBox_complete.vim", rtp) 
		execute 'source ' . fnameescape(LatexBox_complete_src)

		let LatexBox_motion_src		= findfile("ftplugin/ATP_files/LatexBox_motion.vim", rtp) 
		execute 'source ' . fnameescape(LatexBox_motion_src)

	endif

		if atp_debug
			let g:atpLB_loadtime=string(str2float(reltimestr(reltime(time)))-str2float(g:atpcomp_loadtime))
			echomsg "LB loadtime:" . g:atpLB_loadtime
		endif


	let motion_src	= findfile("ftplugin/ATP_files/motion.vim", rtp) 
	execute 'source ' . fnameescape(motion_src)

		if atp_debug
			let g:atpmot_loadtime=string(str2float(reltimestr(reltime(time)))-str2float(g:atpLB_loadtime))
			echomsg "mot loadtime:" . g:atpmot_loadtime
		endif

	let search_src	= findfile("ftplugin/ATP_files/search.vim", rtp) 
	execute 'source ' . fnameescape(search_src)

		if atp_debug
			let g:atpsea_loadtime=string(str2float(reltimestr(reltime(time)))-str2float(g:atpmot_loadtime))
			echomsg "sea loadtime:" . g:atpsea_loadtime
		endif

	let various_src	= findfile("ftplugin/ATP_files/various.vim", rtp) 
	execute 'source ' . fnameescape(various_src)

		if atp_debug
			let g:atpvar_loadtime=string(str2float(reltimestr(reltime(time)))-str2float(g:atpsea_loadtime))
			echomsg "var loadtime:" . g:atpvar_loadtime
		endif


	" Source maps and menu files.
	let mappings_src	= findfile("ftplugin/ATP_files/mappings.vim", rtp) 
	execute 'source ' . fnameescape(mappings_src)

	if g:atp_LatexBox

		" LatexBox mappings.
		let LatexBox_mappings_src		= findfile("ftplugin/ATP_files/LatexBox_mappings.vim", rtp) 
		execute 'source ' . fnameescape(LatexBox_mappings_src)
			
	endif

		if atp_debug
			let g:atpmap_loadtime=string(str2float(reltimestr(reltime(time)))-str2float(g:atpvar_loadtime))
			echomsg "map loadtime:" . g:atpmap_loadtime
		endif

	" The menu.
	let menu_src	= findfile("ftplugin/ATP_files/menu.vim", rtp) 
	execute 'source ' . fnameescape(menu_src)

		if atp_debug
			let g:atpmenu_loadtime=string(str2float(reltimestr(reltime(time)))-str2float(g:atpmap_loadtime))
			echomsg "menu loadtime:" . g:atpmenu_loadtime
		endif


		if atp_debug
			let g:atp_loadtime =  reltimestr(reltime(time))
			echomsg "loadtime:" . g:atp_loadtime

			echomsg "overall load time:"string(str2float(g:atpmenu_loadtime)+str2float(g:atpmap_loadtime)+str2float(g:atpvar_loadtime)+str2float(g:atpsea_loadtime)+str2float(g:atpmot_loadtime)+str2float(g:atpLB_loadtime)+str2float(g:atpcomp_loadtime)+str2float(g:atpopt_loadtime)+str2float(g:atpcom_loadtime)+str2float(g:atphist_loadtime)+str2float(g:atprc_loadtime))
		endif

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4
