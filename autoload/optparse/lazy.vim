let s:save_cpo = &cpo
set cpo&vim

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

function! optparse#lazy#parse(...) dict
    let opts = s:extract_special_opts(a:0, a:000)
    if ! has_key(opts, 'q_args')
        return opts.specials
    endif

    if opts.q_args ==# '--help' && ! has_key(self.options, 'help')
        call s:show_help(self.options)
        return extend(opts.specials, {'help' : 1})
    endif

    let parsed_args = s:parse_args(opts.q_args, self.options)

    let ret = parsed_args[0]
    call extend(ret, opts.specials)
    let ret.__unknown_args__ = parsed_args[1]
    return ret
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
