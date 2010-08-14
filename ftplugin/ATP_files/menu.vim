"Author:		Marcin Szamotulski
" This file sets up the menu.

let Compiler	= get(g:CompilerMsg_Dict, matchstr(b:atp_TexCompiler, '^\s*\zs\S*'), 'Compile')

let Viewer	= get(g:ViewerMsg_Dict, matchstr(b:atp_Viewer, '^\s*\zs\S*'), "View\\ Output")

if !exists("no_plugin_menu") && !exists("no_atp_menu")
execute "menu 550.5 LaTe&X.&".Compiler."<Tab>:TEX				:<C-U>TEX<CR>"
execute "menu 550.6 LaTe&X.".Compiler."\\ debug<Tab>:TEX\\ debug		:<C-U>DTEX<CR>"
execute "menu 550.7 LaTe&X.".Compiler."\\ &twice<Tab>:2TEX			:<C-U>2TEX<CR>"
menu 550.8 LaTe&X.&MakeLatex<Tab>:MakeLatex					:<C-U>MakeLatex<CR>
menu 550.9 LaTe&X.&Bibtex<Tab>:Bibtex						:<C-U>Bibtex<CR>
execute "menu 550.10 LaTe&X.&View\\ with\\ ".Viewer."<Tab>:ViewOutput 		:<C-U>ViewOutput<CR>"
"
menu 550.20.1 LaTe&X.&Errors<Tab>:ShowErrors					:<C-U>ShowErrors<CR>
nmenu 550.20.1 LaTe&X.&Log.&Open\ Log\ File<Tab>:ShowErrors\ o			:<C-U>ShowErrors\ o<CR>
if t:atp_DebugMode == "debug"
    nmenu 550.20.5 LaTe&X.&Log.Toggle\ &Debug\ Mode\ [on]			:<C-U>ToggleDebugMode<CR>
else
    nmenu 550.20.5 LaTe&X.&Log.Toggle\ &Debug\ Mode\ [off]			:<C-U>ToggleDebugMode<CR>
endif  
menu 550.20.20 LaTe&X.&Log.-ShowErrors-						:
menu 550.20.20 LaTe&X.&Log.&Warnings<Tab>:ShowErrors\ w 			:<C-U>ShowErrors w<CR>
menu 550.20.20 LaTe&X.&Log.&Citation\ Warnings<Tab>:ShowErrors\ c		:<C-U>ShowErrors c<CR>
menu 550.20.20 LaTe&X.&Log.&Reference\ Warnings<Tab>:ShowErrors\ r		:<C-U>ShowErrors r<CR>
menu 550.20.20 LaTe&X.&Log.&Font\ Warnings<Tab>ShowErrors\ f			:<C-U>ShowErrors f<CR>
menu 550.20.20 LaTe&X.&Log.Font\ Warnings\ &&\ Info<Tab>:ShowErrors\ fi		:<C-U>ShowErrors fi<CR>
menu 550.20.20 LaTe&X.&Log.&Show\ Files<Tab>:ShowErrors\ F			:<C-U>ShowErrors F<CR>
"
menu 550.20.20 LaTe&X.&Log.-PdfFotns- 						:
menu 550.20.20 LaTe&X.&Log.&Pdf\ Fonts<Tab>:PdfFonts				:<C-U>PdfFonts<CR>

menu 550.20.20 LaTe&X.&Log.-Delete-						:
menu 550.20.20 LaTe&X.&Log.&Delete\ Tex\ Output\ Files<Tab>:Delete		:<C-U>Delete<CR>
menu 550.20.20 LaTe&X.&Log.Set\ Error\ File<Tab>:SetErrorFile			:<C-U>SetErrorFile<CR> 
"
menu 550.25 LaTe&X.-Print- 							:
menu 550.26 LaTe&X.&SshPrint<Tab>:SshPrint					:<C-U>SshPrint 
"
menu 550.30 LaTe&X.-TOC- 							:
menu 550.30 LaTe&X.&Table\ of\ Contents<Tab>:TOC				:<C-U>TOC<CR>
menu 550.30 LaTe&X.L&abels<Tab>:Labels						:<C-U>Labels<CR>
"
menu 550.40 LaTe&X.&Go\ to.&GotoFile<Tab>:GotoFile				:gf
"
menu 550.40 LaTe&X.&Go\ to.-Environment- 					:
menu 550.40 LaTe&X.&Go\ to.Next\ Definition<Tab>:NEnv\ definition		:<C-U>NEnv definition<CR>
menu 550.40 LaTe&X.&Go\ to.Previuos\ Definition<Tab>:PEnv\ definition		:<C-U>PEnv definition<CR>
menu 550.40 LaTe&X.&Go\ to.Next\ Environment<Tab>:NEnv\ [pattern]		:<C-U>NEnv 
menu 550.40 LaTe&X.&Go\ to.Previuos\ Environment<Tab>:PEnv\ [pattern]		:<C-U>PEnv 
"
menu 550.40 LaTe&X.&Go\ to.-Section- 						:
menu 550.40 LaTe&X.&Go\ to.&Next\ Section<Tab>:NSec				:NSec<CR>
menu 550.40 LaTe&X.&Go\ to.&Previuos\ Section<Tab>:PSec				:<C-U>PSec<CR>
menu 550.40 LaTe&X.&Go\ to.Next\ Chapter<Tab>:NChap				:<C-U>NChap<CR>
menu 550.40 LaTe&X.&Go\ to.Previous\ Chapter<Tab>:PChap				:<C-U>PChap<CR>
menu 550.40 LaTe&X.&Go\ to.Next\ Part<Tab>:NPart				:<C-U>NPart<CR>
menu 550.40 LaTe&X.&Go\ to.Previuos\ Part<Tab>:PPart				:<C-U>PPart<CR>
"
menu 550.50 LaTe&X.-Bib-							:
menu 550.50 LaTe&X.Bib\ Search<Tab>:Bibsearch\ [pattern]			:<C-U>BibSearch 
menu 550.50 LaTe&X.Input\ Files<Tab>:InputFiles					:<C-U>InputFiles<CR>
"
menu 550.60 LaTe&X.-Viewer-							:
menu 550.60 LaTe&X.Set\ &XPdf<Tab>:SetXpdf					:<C-U>SetXpdf<CR>
menu 550.60 LaTe&X.Set\ X&Dvi\ (inverse\/reverse\ search)<Tab>:SetXdvi		:<C-U>SetXdvi<CR>
"
menu 550.70 LaTe&X.-Editting-							:
"
" ToDo: show options doesn't work from the menu (it disappears immediately, but at
" some point I might change it completely)
menu 550.70 LaTe&X.&Options.&Show\ Options<Tab>:ShowOptions			:<C-U>ShowOptions<CR> 
if g:atp_callback
    menu 550.70 LaTe&X.&Options.Toggle\ &Call\ Back\ [on]<Tab>g:atp_callback	:<C-U>ToggleCallBack<CR>
else
    menu 550.70 LaTe&X.&Options.Toggle\ &Call\ Back\ [off]<Tab>g:atp_callback	:<C-U>ToggleCallBack<CR>
endif  
menu 550.70 LaTe&X.&Options.-set\ options- 					:
menu 550.70 LaTe&X.&Options.Automatic\ TeX\ Processing<Tab>b:atp_autex		:<C-U>let b:atp_autex=
menu 550.70 LaTe&X.&Options.Set\ Runs<Tab>b:atp_auruns				:<C-U>let b:atp_auruns=
menu 550.70 LaTe&X.&Options.Set\ TeX\ Compiler<Tab>b:atp_TexCompiler		:<C-U>let b:atp_TexCompiler="
menu 550.70 LaTe&X.&Options.Set\ Viewer<Tab>b:atp_Viewer				:<C-U>let b:atp_Viewer="
menu 550.70 LaTe&X.&Options.Set\ Output\ Directory<Tab>b:atp_OutDir		:<C-U>let b:atp_ViewerOptions="
menu 550.70 LaTe&X.&Options.Set\ Output\ Directory\ to\ the\ default\ value<Tab>:SetOutDir	:<C-U>SetOutDir<CR> 
menu 550.70 LaTe&X.&Options.Ask\ for\ the\ Output\ Directory<Tab>g:askfortheoutdir		:<C-U>let g:askfortheoutdir="
menu 550.70 LaTe&X.&Options.Viewer<Tab>b:atp_Viewer				:<C-U>let b:atp_Viewer="
menu 550.70 LaTe&X.&Options.Set\ Error\ File<Tab>:SetErrorFile			:<C-U>SetErrorFile<CR> 
menu 550.70 LaTe&X.&Options.Which\ TeX\ files\ to\ copy<Tab>g:keep		:<C-U>let g:keep="
menu 550.70 LaTe&X.&Options.Tex\ extensions<Tab>g:atp_tex_extensions		:<C-U>let g:atp_tex_extensions="
menu 550.70 LaTe&X.&Options.Remove\ Command<Tab>g:rmcommand			:<C-U>let g:rmcommand="
menu 550.70 LaTe&X.&Options.Default\ Bib\ Flags<Tab>g:defaultbibflags		:<C-U>let g:defaultbibflags="
"
menu 550.78 LaTe&X.&Toggle\ Space\ [off]<Tab>cmap\ <space>\ \\_s\\+ 		:<C-U>ToggleSpace<CR>
tmenu LaTe&X.&Toggle\ Space\ [off] cmap <space> \_s\+ is curently off
if maparg('n', 'n') != ""
    menu 550.79 LaTe&X.Toggle\ &Nn\ [on]<Tab>:ToggleNn				:<C-U>ToggleNn<CR>
"     tmenu LaTeX.Toggle\ Nn\ [on] Grab n,N vim normal commands.
else
    menu 550.79 LaTe&X.Toggle\ &Nn\ [off]<Tab>:ToggleNn				:<C-U>ToggleNn<CR>
"     tmenu LaTeX.Toggle\ Nn\ [off] Do not grab n,N vim normal commands.
endif
if g:atp_MathOpened
    menu 550.80 LaTe&X.Toggle\ &Check\ if\ in\ Math\ [on]<Tab>g:atp_MathOpened  :<C-U>ToggleCheckMathOpened<CR>
else
    menu 550.80 LaTe&X.Toggle\ &Check\ if\ in\ Math\ [off]<Tab>g:atp_MathOpened :<C-U>ToggleCheckMathOpened<CR>
endif
endif

" vim:fdm=marker:tw=85:ff=unix:noet:ts=8:sw=4:fdc=1
