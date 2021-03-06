let s:save_cpo = &cpo
set cpo&vim

let s:STRING_TYPE = type('')
let s:LIST_TYPE = type([])

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

function! s:make_option_description_for_help(opt)
    let desc = a:opt.description
    if has_key(a:opt, 'default_value')
        let desc .= ' (DEFAULT: ' . string(a:opt.default_value) . ')'
    endif
    return desc
endfunction

function! optparse#lazy#help_message() dict
    let definitions = map(values(self.options), "[s:make_option_definition_for_help(v:val), s:make_option_description_for_help(v:val)]")
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
    if a:argc <= 0
        return ret
    endif

    let ret.q_args = a:argv[0]
    for arg in a:argv[1:]
        let arg_type = type(arg)
        if arg_type == s:LIST_TYPE
            let ret.specials.__range__ = arg
        elseif arg_type == type(0)
            let ret.specials.__count__ = arg
        elseif arg_type == s:STRING_TYPE
            if arg ==# '!'
                let ret.specials.__bang__ = arg
            elseif arg != ''
                let ret.specials.__reg__ = arg
            endif
        endif
        unlet arg
    endfor
    return ret
endfunction

function! s:make_args(cmd_args)
    let type = type(a:cmd_args)
    if type == s:STRING_TYPE
        return split(a:cmd_args)
    elseif type == s:LIST_TYPE
        return map(copy(a:cmd_args), 'type(v:val) == s:STRING_TYPE ? v:val : string(v:val)')
    else
        echoerr 'Invalid type: first argument of parse() should be string or list of string'
        return []
    endif
endfunction

function! s:expand_short_option(arg, options)
    let short_opt = matchstr(a:arg, '^-[^- =]\>')
    for [name, value] in items(a:options)
        if get(value, 'short_option_definition', '') ==# short_opt
            return substitute(a:arg, short_opt, '--'.name, '')
        endif
    endfor
    return a:arg
endfunction

function! s:parse_arg(arg, options)
    " if --no-hoge pattern
    if a:arg =~# '^--no-[^= ]\+'
        " get hoge from --no-hoge
        let key = matchstr(a:arg, '^--no-\zs[^= ]\+')
        if has_key(a:options, key) && has_key(a:options[key], 'no')
            return [key, 0]
        endif

    " if --hoge pattern
    elseif a:arg =~# '^--[^= ]\+$'
        " get hoge from --hoge
        let key = matchstr(a:arg, '^--\zs[^= ]\+')
        if has_key(a:options, key)
            if has_key(a:options[key], 'has_value')
                echoerr 'Must specify value for option: '.key
            endif
            return [key, 1]
        endif

    " if --hoge=poyo pattern
    else
        " get hoge from --hoge=poyo
        let key = matchstr(a:arg, '^--\zs[^= ]\+')
        if has_key(a:options, key)
            " get poyo from --hoge=poyo
            return [key, matchstr(a:arg, '^--[^= ]\+=\zs\S\+$')]
        endif
    endif

    return a:arg
endfunction

function! s:parse_args(cmd_args, options)
    let parsed_args = {}
    let unknown_args = []
    let args = s:make_args(a:cmd_args)

    for arg in args

        " replace short option with long option if short option is available
        if arg =~# '^-[^- =]\>'
            let arg = s:expand_short_option(arg, a:options)
        endif

        " check if arg is --[no-]hoge[=VALUE]
        if arg !~# '^--\%(no-\)\=[^= ]\+\%(=\S\+\)\=$'
            call add(unknown_args, arg)
            continue
        endif

        let parsed_arg = s:parse_arg(arg, a:options)
        if type(parsed_arg) == s:LIST_TYPE
            let parsed_args[parsed_arg[0]] = parsed_arg[1]
        else
            call add(unknown_args, parsed_arg)
        endif
        unlet parsed_arg
    endfor

    return [parsed_args, unknown_args]
endfunction

function! s:set_default_values(parsed_args, options)
    for [name, default_value] in map(items(filter(copy(a:options), 'has_key(v:val, "default_value")')), '[v:val[0], v:val[1].default_value]')
        if ! has_key(a:parsed_args, name)
            let a:parsed_args[name] = default_value
        endif
        unlet default_value
    endfor
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
    call s:set_default_values(ret, self.options)
    call extend(ret, opts.specials)
    let ret.__unknown_args__ = parsed_args[1]
    return ret
endfunction

function! s:long_option_completion(arglead, options)
    let candidates = []
    for [name, option] in items(a:options)
        let has_value = get(option, 'has_value', 0)
        call add(candidates, '--' . name . (has_value ? '=' : ''))
        if get(option, 'no', 0)
            call add(candidates, '--no-' . name . (has_value ? '=' : ''))
        endif
    endfor
    let lead_pattern = '^' . a:arglead
    return filter(candidates, 'v:val =~# lead_pattern')
endfunction

function! s:short_option_completion(arglead, options)
    let candidates = []
    for option in values(a:options)
        let has_value = get(option, 'has_value', 0)
        if has_key(option, 'short_option_definition')
            call add(candidates, option.short_option_definition . (has_value ? '=' : ''))
            if get(option, 'no', 0)
                call add(candidates, '-no' . option.short_option_definition . (has_value ? '=' : ''))
            endif
        endif
    endfor
    let lead_pattern = '^' . a:arglead
    return filter(candidates, 'v:val =~# lead_pattern')
endfunction

function! s:user_defined_completion(lead, name, options, cmdline, cursorpos)
    if ! has_key(a:options, a:name) || ! has_key(a:options[a:name], 'completion')
        return []
    endif
    return a:options[a:name].completion(a:lead, a:cmdline, a:cursorpos)
endfunction

function! s:user_defined_short_option_completion(lead, def, options, cmdline, cursorpos)
    for option in values(a:options)
        if has_key(option, 'short_option_definition')
            \ && option.short_option_definition ==# a:def
            \ && has_key(option, 'completion')
            return option.completion(a:lead, a:cmdline, a:cursorpos)
        endif
    endfor
    return []
endfunction

function! optparse#lazy#complete(arglead, cmdline, cursorpos) dict
    if a:arglead =~# '^--[^=]*$'
        " when long option
        return s:long_option_completion(a:arglead, self.options)

    elseif a:arglead =~# '^-[^-=]\?$'
        " when short option
        return s:short_option_completion(a:arglead, self.options)

    elseif a:arglead =~# '^--.\+=.*$'
        let lead = matchstr(a:arglead, '=\zs.*$')
        let name = matchstr(a:arglead, '^--\zs[^=]\+')
        let prefix = matchstr(a:arglead, '^.\+=')
        return map(
            \  s:user_defined_completion(lead, name, self.options, a:cmdline, a:cursorpos),
            \ 'prefix . v:val'
            \ )

    elseif a:arglead =~# '^-[^-=]=.*$'
        let lead = matchstr(a:arglead, '=\zs.*$')
        let def = matchstr(a:arglead, '^-[^-=]')
        let prefix = def . '='
        return map(
             \ s:user_defined_short_option_completion(lead, def, self.options, a:cmdline, a:cursorpos),
             \ 'prefix . v:val'
             \ )

    elseif has_key(self, 'unknown_options_completion')
        if type(self.unknown_options_completion) == type('')
            return call('optparse#completion#' . self.unknown_options_completion, [a:arglead, a:cmdline, a:cursorpos])
        else
            return self.unknown_options_completion(a:arglead, a:cmdline, a:cursorpos)
        endif
    endif

    return []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
