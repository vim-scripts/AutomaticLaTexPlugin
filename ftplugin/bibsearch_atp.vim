" Vim filetype plugin file
" Language:	tex
" Maintainer:	Marcin Szamotulski
" Last Changed: 2010 Jan 25
" URL:		

map <buffer> c :call BibChoose()  <CR>
map <buffer> q :hide<CR>

if !exists("*BibChoose")
function! BibChoose(...)
"     if a:0 == 0
" 	let l:bibresults=s:searchbib('')
" 	let b:listofkeys=s:showresults(l:bibresults,'','')
"     elseif a:0 == 1
" 	let l:bibresults=s:searchbib(a:1)
" 	let b:listofkeys=s:showresults(l:bibresults,'',a:1)
"     else
" 	let l:bibresults=s:searchbib(a:1)
" 	let b:listofkeys=s:showresults(l:bibresults,a:2,a:1)
"     endif
    let l:which=input("Which entry? (enter for none) ")
    if l:which =~ '\<\d*\>'
	let l:start=stridx(b:listofkeys[l:which],'{')+1
	let l:choice=substitute(strpart(b:listofkeys[l:which],l:start),',','','')
	q
	let l:line=getline(".")
	let l:col=col(".")
	let l:line=strpart(l:line,0,l:col) . l:choice . strpart(l:line,l:col)
	call setline(line("."), l:line)
    elseif l:which =~ '\<\d*\a\>'
	    let l:letter=substitute(l:which,'\d','','g')
	    let l:which=substitute(l:which,'\a','','g')
	    let l:start=stridx(b:listofkeys[l:which],'{')+1
	    let l:choice=substitute(strpart(b:listofkeys[l:which],l:start),',','','')
	    silent if l:letter == 'a'
		let @a=l:choice
	    elseif l:letter == 'b'
		let @b=l:choice
	    elseif l:letter == 'c'
		let @c=l:choice
	    elseif l:letter == 'd'
		let @d=l:choice
	    elseif l:letter == 'e'
		let @e=l:choice
	    elseif l:letter == 'f'
		let @f=l:choice
	    elseif l:letter == 'g'
		let @g=l:choice
	    elseif l:letter == 'h'
		let @h=l:choice
	    elseif l:letter == 'i'
		let @i=l:choice
	    elseif l:letter == 'j'
		let @j=l:choice
	    elseif l:letter == 'k'
		let @k=l:choice
	    elseif l:letter == 'l'
		let @l=l:choice
	    elseif l:letter == 'm'
		let @m=l:choice
	    elseif l:letter == 'n'
		let @n=l:choice
	    elseif l:letter == 'o'
		let @o=l:choice
	    elseif l:letter == 'p'
		let @p=l:choice
	    elseif l:letter == 'q'
		let @q=l:choice
	    elseif l:letter == 'r'
		let @r=l:choice
	    elseif l:letter == 's'
		let @s=l:choice
	    elseif l:letter == 't'
		let @t=l:choice
	    elseif l:letter == 'u'
		let @u=l:choice
	    elseif l:letter == 'v'
		let @v=l:choice
	    elseif l:letter == 'w'
		let @w=l:choice
	    elseif l:letter == 'x'
		let @x=l:choice
	    elseif l:letter == 'y'
		let @y=l:choice
	    elseif l:letter == 'z'
		let @z=l:choice
	    elseif l:letter == '*'
		let @-=l:choice
	    elseif l:letter == '+'
		let @+=l:choice
	    elseif l:letter == '-'
		let @@=l:choice
	    endif
	    q
	    echohl WarningMsg | echomsg "Choice written to the register '" . l:letter . "'" | echohl None
    endif
endfunction
endif
command! -buffer -nargs=* BibChoose 	:call BibChoose(<f-args>)

