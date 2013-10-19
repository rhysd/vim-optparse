let s:save_cpo = &cpo
set cpo&vim

" on('--[no-]hoge={poyo}')
"   --hoge=true returns 1 and --hoge=false returns 0
"   otherwise, --hoge=huga returns 'huga'
"   if [no-] is added, --no-hoge returns 0 and --hoge returns 1
" __bang__ is special keys. it contains 1 if <bang> is setted
"   __count__ has 
" options must not contain any white spaces
" TODO parse --[no-]
" TODO parse VALUE of --hoge=VALUE
function! s:on(...) dict
    if a:0 == 2
        let name = matchstr(a:1, '^--\zs[^= ]\+')
        if name == ''
            echoerr 'Option of key is invalid: '.name
        else
            " NOTE: a:1 is description
            let self.options[name] = {'definition' : a:1, 'description' : a:2}
        endif
    elseif a:0 == 3
        throw "Not implemented"
    else
        echoerr 'Wrong number of arguments ('.a:0.' for 3 or 2)'
    endif
endfunction

" separate parse function to other file to load functions lazily
function! s:parse(...) dict
    return call('optparse#lazy#parse', a:000, self)
endfunction

function! optparse#new()
    return { 'options' : {},
           \ 'on' : function('s:on'),
           \ 'parse' : function('s:parse'),
           \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
