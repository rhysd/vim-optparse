let s:save_cpo = &cpo
set cpo&vim

function! s:get_SID()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeget_SID$')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

function! s:on(def, desc, ...) dict
    if a:0 > 1
        echoerr 'Wrong number of arguments: ' . a:0+2 . ' for 2..3'
        return
    endif

    " get hoge and huga from --hoge=huga
    let [name, value] = matchlist(a:def, '^--\([^= ]\+\)\(=\S\+\)\=$')[1:2]
    if value != ''
        let has_value = 1
    endif

    if name =~# '^\[no-]'
        let no = 1
        let name = matchstr(name, '^\[no-]\zs.\+')
    endif

    if name == ''
        echoerr 'Option of key is invalid: '.a:def
        return
    endif

    let self.options[name] = {'definition' : a:def, 'description' : a:desc}
    if exists('l:no')
        let self.options[name].no = 1
    endif
    if exists('l:has_value')
        let self.options[name].has_value = 1
    endif

    " if extra option is specified
    if a:0 == 1
        if type(a:1) == type({})
            if has_key(a:1, 'short')
                let self.options[name].short_option_definition = a:1.short
            endif
            if has_key(a:1, 'default')
                let self.options[name].default_value = a:1.default
            endif
            if has_key(a:1, 'completion')
                if type(a:1.completion) == type('')
                    let self.options[name].completion = function('optparse#completion#' . a:1.completion)
                else
                    let self.options[name].completion = a:1.completion
                endif
            endif
        else
            let self.options[name].default_value = a:1
        endif
    endif

    return self
endfunction

function! optparse#new()
    return { 'options' : {},
           \ 'on' : function(s:SID.'on'),
           \ 'parse' : function('optparse#lazy#parse'),
           \ 'help' : function('optparse#lazy#help_message'),
           \ 'complete' : function('optparse#lazy#complete'),
           \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
