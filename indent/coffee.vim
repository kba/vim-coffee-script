" Language:    CoffeeScript
" Maintainer:  Mick Koch <kchmck@gmail.com>
" URL:         http://github.com/kchmck/vim-coffee-script
" License:     WTFPL

if exists("b:did_indent")
  finish
endif

let b:did_indent = 1

setlocal autoindent
setlocal indentexpr=GetCoffeeIndent(v:lnum)
" Make sure GetCoffeeIndent is run when these are typed so they can be nicely
" outdented
setlocal indentkeys+=0],0),=else,=catch,=finally

" Only define the function once
if exists("*GetCoffeeIndent")
  finish
endif

" Outdent certain keywords, etc.
let s:outdent = ['^else', '^catch', '^finally', '^}', '^]', '^)']

" Indent after certain keywords, functions, etc.
let s:indent_after = ['^if\>', '^else\>', '^for\>', '^while\>', '^switch\>',
\                     '^when\>', '^try\>', '^catch\>', '^finally\>', '^class\>',
\                     '[$', '{$', '($', '->$', '=>$']

" Outdent after certain keywords
let s:outdent_after = ['^return\>', '^break\>', '^continue\>', '^throw\>']
" Don't outdent if the previous line contains one of these keywords (for cases
" like 'return if a is b', 'break unless a', etc.)
let s:dont_outdent_after = ['\<if\>', '\<unless\>']

" A hint that the previous line is a one-liner, so the current line doesn't need
" to be indented or outdented
let s:oneliner_hint = '\<then\>'

" See if a line contains any regular expression in regexps
function! s:Search(line, regexps)
  for regexp in a:regexps
    if a:line =~ regexp
      return 1
    endif
  endfor

  return 0
endfunction

" Check for a one-line else statement (e.g., 'else return a' but
" not 'else if a'), which doesn't need an indent afterwards
function! s:IsOneLineElse(line)
  " Check if the line actually starts with 'else', then if the line contains
  " anything other than 'else', then finally if the line is actually an 'else'
  " statement rather than an 'else if' statement
  return a:line =~ '^else\>' && a:line !~ '^else$' && a:line !~ '^else if\>'
endfunction

function! s:ShouldOutdent(prevline, curline)
  return a:prevline !~ s:oneliner_hint
  \      && !s:Search(a:prevline, s:outdent_after)
  \      && s:Search(a:curline, s:outdent)
endfunction

function! s:ShouldIndentAfter(prevline)
  return a:prevline !~ s:oneliner_hint
  \      && !s:IsOneLineElse(a:prevline)
  \      && s:Search(a:prevline, s:indent_after)
endfunction

function! s:ShouldOutdentAfter(prevline)
  return !s:Search(a:prevline, s:dont_outdent_after)
  \      && s:Search(a:prevline, s:outdent_after)
endfunction

function! GetCoffeeIndent(curlinenum)
  " Find a non-blank line above the current line
  let prevlinenum = prevnonblank(a:curlinenum - 1)

  " No indenting is needed at the start of a file
  if prevlinenum == 0
    return 0
  endif

  let curindent = indent(a:curlinenum)
  let previndent = indent(prevlinenum)

  " Strip off leading whitespace
  let curline = getline(a:curlinenum)[curindent : -1]
  let prevline = getline(prevlinenum)[previndent : -1]

  if s:ShouldOutdent(prevline, curline)
    return curindent - &shiftwidth
  endif

  if s:ShouldIndentAfter(prevline)
    return previndent + &shiftwidth
  endif

  if s:ShouldOutdentAfter(prevline)
    return previndent - &shiftwidth
  endif

  " No indenting or outdenting is needed
  return previndent
endfunction