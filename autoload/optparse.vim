let s:save_cpo = &cpo
set cpo&vim

function! s:get_SID()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeget_SID$')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

function! s:on(...) dict
    if ! (a:0 == 2 || a:0 == 3)
        echoerr 'Wrong number of arguments ('.a:0.' for 2 or 3)'
        return
    endif

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
        echoerr 'Option of key is invalid: '.a:1
        return
    endif

    let self.options[name] = {'definition' : a:1, 'description' : a:000[-1]}
    if exists('l:no')
        let self.options[name].no = 1
    endif
    if exists('l:has_value')
        let self.options[name].has_value = 1
    endif

    " if short option is specified
    if a:0 == 3
        if a:2 !~# '^-[^- =]$'
            echoerr 'Short option is invalid: '.a:2
            return
        endif

        let self.options[name].short_option_definition = a:2
    endif

    return self
endfunction

function! optparse#new()
    return { 'options' : {},
           \ 'on' : function(s:SID.'on'),
           \ 'parse' : function('optparse#lazy#parse'),
           \ 'help' : function('optparse#lazy#help_message'),
           \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
