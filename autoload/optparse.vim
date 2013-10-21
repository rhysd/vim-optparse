let s:save_cpo = &cpo
set cpo&vim

function! s:get_SID()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeget_SID$')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

function! s:on(...) dict
    if a:0 == 2

        " get hoge and huga from --hoge=huga
        let [name, value] = matchlist(a:1, '^--\([^= ]\+\)\(=\S\+\)\=$')[1:2]
        if value != ''
            let has_value = 1
        endif

        if name =~# '^\[no-]'
            let no = 1
            let name = matchstr(name, '^\[no-]\zs.\+')
        endif

        if name == ''
            echoerr 'Option of key is invalid: '.name
        else
            let self.options[name] = {'definition' : a:1, 'description' : a:2}
            if exists('l:no')
                let self.options[name].no = 1
            endif
            if exists('l:has_value')
                let self.options[name].has_value = 1
            endif
        endif

    elseif a:0 == 3
        " short options like -h for --hoge
        throw "Not implemented"
    else
        echoerr 'Wrong number of arguments ('.a:0.' for 2 or 3)'
    endif
endfunction

" separate parse function to other file to load functions lazily
function! s:parse(...) dict
    return call('optparse#lazy#parse', a:000, self)
endfunction

function! optparse#new()
    return { 'options' : {},
           \ 'on' : function(s:SID.'on'),
           \ 'parse' : function(s:SID.'parse'),
           \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
