"=============================================================================
" License : MIT license {{{
"
"   Permission is hereby granted, free of charge, to any person obtaining
"   a copy of this software and associated documentation files (the
"   "Software"), to deal in the Software without restriction, including
"   without limitation the rights to use, copy, modify, merge, publish,
"   distribute, sublicense, and/or sell copies of the Software, and to
"   permit persons to whom the Software is furnished to do so, subject to
"   the following conditions:
"   
"   The above copyright notice and this permission notice shall be included
"   in all copies or substantial portions of the Software.
"   
"   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

" source gtags/ref {{{
let s:ref = {
      \ 'name' : 'ref',
      \ 'description' : 'global with -rs option',
      \ 'result' : function('unite#libs#gtags#result2unite'),
      \}
function! s:ref.option(args, context)
  if empty(a:args)
    let l:pattern = expand("<cword>")
  else
    let l:pattern = a:args[0]
  endif
  return {
        \'short': 'rs',
        \'long': '',
        \ 'pattern' : l:pattern ,
        \ }
endfunction
" }}}

" source gtags/def {{{
let s:def = {
      \ 'name' : 'def',
      \ 'description' : 'global with -d option',
      \ 'result' : function('unite#libs#gtags#result2unite'),
      \}
function! s:def.option(args, context)
  if empty(a:args)
    let l:pattern = expand("<cword>")
  else
    let l:pattern = a:args[0]
  endif
  if empty(l:pattern)
    call unite#print_message("[unite-gtags] Warning: No word specified ")
    return []
  endif
  return {
        \'short': 'd',
        \'long': '',
        \'pattern' : l:pattern 
        \}
endfunction
" }}}

" source gtags/context {{{
let s:context = {
      \'name' : 'context',
      \ 'description' : 'global with --from-here option',
      \ 'result' : function('unite#libs#gtags#result2unite'),
      \}
function! s:context.option(args, context)
  let l:pattern = expand("<cword>")
  if empty(l:pattern)
    call unite#print_message("[unite-gtags] Warning: No word exists on cursor ")
    return []
  endif
  let l:long = "--from-here=\"" . line('.') . ":" . expand("%") . "\""
  return {
        \'short': '',
        \'long': l:long,
        \'pattern' : l:pattern,
        \}
endfunction
"}}}

" source gtags/completion {{{
let s:completion = { 'name' : 'completion'}

function! s:completion.result(name, result)
  if empty(a:result)
    return []
  endif
  let l:symbols = split(a:result, '\r\n\|\r\|\n')
  return map(l:symbols, '{
        \ "source" : "gtags/completion",
        \ 'description' : 'global with -c option',
        \ "kind" : "gtags_completion",
        \ "word" : v:val,
        \ }')
endfunction

function! s:completion.option(args, context)
  if empty(a:args)
    let l:prefix = ''
  else
    let l:prefix = a:args[0]
  endif
  return {
        \ 'short': 'c',
        \ 'long' : '',
        \ 'pattern' : l:prefix,
        \}
endfunction
" }}}

" source gtags/grep {{{
let s:grep = {
      \ 'name' : 'grep',
      \ 'description' : 'global with -g option',
      \ 'result' : function('unite#libs#gtags#result2unite'),
      \ 'hooks' : {},
      \}

function! s:grep.hooks.on_init(args, context)
  let a:context.source__input = get(a:args, 0, '')
  if a:context.source__input == ''
    let a:context.source__input = unite#util#input('Pattern: ')
  endif
endfunction

function! s:grep.option(args, context)
  return {
        \ 'short': 'g',
        \ 'long' : '',
        \ 'pattern' : a:context.source__input,
        \}
endfunction
" }}}

let s:gtags_commands  = [
      \ s:ref,
      \ s:def,
      \ s:context,
      \ s:completion,
      \ s:grep,
      \]

function! unite#sources#gtags#define()
  let l:sources   = []
  for gtags_command in s:gtags_commands
    let l:source  = {
          \ 'name' : 'gtags/' . gtags_command.name,
          \ 'gtags_option' : gtags_command.option,
          \ 'gtags_result' : gtags_command.result,
          \ 'hooks' : has_key(gtags_command, 'hooks') ? gtags_command.hooks : {},
          \ }
    function! l:source.gather_candidates(args, context)
      let l:options = self.gtags_option(a:args, a:context)
      if type(l:options) != type({})
        return []
      endif
      let l:result = unite#libs#gtags#exec_global(l:options.short, l:options.long, l:options.pattern)
      return self.gtags_result(self.name , l:result)
    endfunction
    call add(l:sources, l:source)
  endfor
  return l:sources
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

