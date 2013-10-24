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

function! s:make_option_definition_for_help(opt)
    let key = a:opt.definition
    if has_key(a:opt, 'short_option_definition')
        let key .= ', '.a:opt.short_option_definition
    endif
    return key
endfunction

function! optparse#lazy#help_message() dict
    let definitions = map(values(self.options), "[s:make_option_definition_for_help(v:val), v:val.description]")
    let key_width = s:max_len(map(copy(definitions), 'v:val[0]'))
    return "Options:\n" .
        \ join(map(definitions, '
                \ "  " . v:val[0] .
                \ repeat(" ", key_width - len(v:val[0])) . " : " .
                \ v:val[1]
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
    " check if arg is --[no-]hoge[=VALUE]
    return a:arg =~# '^--\%(no-\)\=[^= ]\+\%(=\S\+\)\=$'
endfunction

function! s:parse_args(q_args, options)
    let args = split(a:q_args)
    let parsed_args = {}
    let unknown_args = []

    for arg in args

        " replace short option with long option if short option is available
        if arg =~# '^-[^- =]\>'
            let short_opt = matchstr(arg, '^-[^- =]\>')
            for [name, value] in items(a:options)
                if has_key(value, 'short_option_definition') && value.short_option_definition ==# short_opt
                    let arg = substitute(arg, short_opt, '--'.name, '')
                endif
            endfor
        endif

        if s:is_key_value(arg)

            " if --no-hoge pattern
            if arg =~# '^--no-[^= ]\+'
                " get hoge from --no-hoge
                let key = matchstr(arg, '^--no-\zs[^= ]\+')
                if has_key(a:options, key) && has_key(a:options[key], 'no')
                    let parsed_args[key] = 0
                else
                    call add(unknown_args, arg)
                endif

            " if --hoge pattern
            elseif arg =~# '^--[^= ]\+$'
                " get hoge from --hoge
                let key = matchstr(arg, '^--\zs[^= ]\+')
                if has_key(a:options, key)
                    if has_key(a:options[key], 'has_value')
                        echoerr 'Must specify value for option: '.key
                    endif
                    let parsed_args[key] = 1
                else
                    call add(unknown_args, arg)
                endif

            " if --hoge=poyo pattern
            else
                " get hoge from --hoge=poyo
                let key = matchstr(arg, '^--\zs[^= ]\+')
                if has_key(a:options, key)
                    " get poyo from --hoge=poyo
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

    if ! get(self, 'disable_auto_help', 0)
      \  && opts.q_args ==# '--help'
      \  && ! has_key(self.options, 'help')
        echo call('optparse#lazy#help_message', [], self)
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
