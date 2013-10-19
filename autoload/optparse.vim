
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
endfunction

function! s:parse(...) dict
endfunction

function! optparse#new()
    return { 'options' : [],
           \ 'on' : function('s:on'),
           \ 'parse' : function('s:parse'),
           \ }
endfunction

