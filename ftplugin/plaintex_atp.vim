" Maintainer:	Marcin Szamotulski
" Note:		This file is a part of Automatic Tex Plugin for Vim.
" URL:		https://launchpad.net/automatictexplugin

" b:atp_TexFlavor will be set to plaintex automatically
let path=get(split(globpath(&rtp, 'ftplugin/tex_atp.vim'), "\n"), 0, "")
execute "source " .  fnameescape(path)
