
" on('--[no-]hoge={poyo}')
"   --hoge=true returns 1 and --hoge=false returns 0
"   otherwise, --hoge=huga returns 'huga'
"   if [no-] is added, --no-hoge returns 0 and --hoge returns 1
" __bang__ is special keys. it contains 1 if <bang> is setted
"   __count__ has 
" options must not contain any white spaces
function! s:on(...) dict

endfunction

function! s:parse_args(argc, argv)
    let ret = {}
    if a:argc > 0
        let ret.args = a:argv[0]
        let ret.options = {}
        for arg in a:argv[1:]
            let arg_type = type(arg)
            if arg_type == type([])
                let ret.options.__range__ = arg
            elseif arg_type == type(0)
                let ret.options.__count__ = arg
            elseif arg_type == type('')
                if arg ==# '!'
                    let ret.options.__bang__ = arg
                elseif arg != ''
                    let ret.options.__reg__ = arg
                endif
            endif
            unlet arg
        endfor
    endif
    return ret
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

