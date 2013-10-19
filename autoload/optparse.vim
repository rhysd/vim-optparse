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

function! s:max_len(arr)
    let max_len = 1
    for i in a:arr
        let len = len(i)
        if len > max_len
            let max_len = len
        endif
    endfor
    return max_len
endfunction

function! s:show_help(options)
    let key_width = s:max_len(map(values(a:options), "v:val.definition"))
    echo join(map(values(a:options), '
                \ v:val.definition .
                \ repeat(" ", key_width - len(v:val.definition)) . " : " .
                \ v:val.description
                \ '), "\n")
endfunction

function! s:extract_special_opts(argc, argv)
    let ret = {'specials' : {}}
    if a:argc > 0
        let ret.q_args = a:argv[0]
        for arg in a:argv[1:]
            let arg_type = type(arg)
            if arg_type == type([])
                let ret.specials.__range__ = arg
            elseif arg_type == type(0)
                let ret.specials.__count__ = arg
            elseif arg_type == type('')
                if arg ==# '!'
                    let ret.specials.__bang__ = arg
                elseif arg != ''
                    let ret.specials.__reg__ = arg
                endif
            endif
            unlet arg
        endfor
    endif
    return ret
endfunction

function! s:is_key_value(arg)
    return a:arg =~# '^--\%(no-\)\=[^= ]\+\%(=\S\+\)\=$'
endfunction

function! s:parse_args(q_args, options)
    let args = split(a:q_args)
    let parsed_args = {}
    let unknown_args = []

    for arg in args
        if s:is_key_value(arg)
            if arg =~# '^--no-[^= ]\+'
                " if --no-hoge pattern
                let key = matchstr(arg, '^--no-\zs[^= ]\+')
                if has_key(a:options, key) && has_key(a:options[key], 'no')
                    let parsed_args[key] = 0
                else
                    call add(unknown_args, arg)
                endif
            elseif arg =~# '^--[^= ]\+$'
                " if --hoge pattern
                let key = matchstr(arg, '^--\zs[^= ]\+')
                if has_key(a:options, key)
                    let parsed_args[key] = 1
                else
                    call add(unknown_args, arg)
                endif
            else
                " if --hoge=poyo pattern
                let key = matchstr(arg, '^--\zs[^= ]\+')
                if has_key(a:options, key)
                    let parsed_args[key] = matchstr(arg, '^--[^= ]\+=\zs\S\+$')
                else
                    call add(unknown_args, arg)
                endif
            endif
        else
            call add(unknown_args, arg)
        endif
    endfor

    return [parsed_args, unknown_args]
endfunction

function! s:parse(...) dict
    let opts = s:extract_special_opts(a:0, a:000)
    if ! has_key(opts, 'q_args')
        return opts.specials
    endif

    if opts.q_args ==# '--help' && ! has_key(self.options, 'help')
        call s:show_help(self.options)
        return opts.specials
    endif

    let parsed_args = s:parse_args(opts.q_args, self.options)

    let ret = parsed_args[0]
    call extend(ret, opts.specials)
    let ret.__unknown_args__ = parsed_args[1]
    return ret
endfunction

function! optparse#new()
    return { 'options' : {},
           \ 'on' : function('s:on'),
           \ 'parse' : function('s:parse'),
           \ }
endfunction
