
" on('--[no-]hoge={poyo}')
"   --hoge=true returns 1 and --hoge=false returns 0
"   otherwise, --hoge=huga returns 'huga'
"   if [no-] is added, --no-hoge returns 0 and --hoge returns 1
" __bang__ is special keys. it contains 1 if <bang> is setted
"   __count__ has 
" options must not contain any white spaces
function! s:on(...) dict

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

function! s:is_valid(args)
    for arg in a:args
        if arg !~# '^--\%(no-\)\=[^= ]\+\%(=[^= ]\+\)\=$'
            echoerr 'Unexpected argument: '.arg
            return 0
        endif
    endfor
endfunction

function! s:parse(...) dict
    let args = s:parse_args(a:0, a:000)
    echo args
endfunction

function! optparse#new()
    return { 'options' : [],
           \ 'on' : function('s:on'),
           \ 'parse' : function('s:parse'),
           \ }
endfunction

