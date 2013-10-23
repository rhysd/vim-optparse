let s:root_dir = matchstr(system('git rev-parse --show-cdup'), '[^\n]\+')
execute 'set' 'rtp +=./'.s:root_dir

call vspec#matchers#load()

function! s:permutation(args)
    if len(a:args) <= 1
        return [[a:args[0]]]
    endif
    let ret = []
    for a in a:args
        let r = filter(copy(a:args), 'type(v:val) != type(a) || v:val != a')
        let p = s:permutation(r)
        for i in p
            call add(ret, [a] + i)
        endfor
        unlet a
    endfor
    return ret
endfunction

describe 'g:Opt.parse()'
    before
        let g:O = optparse#new()
    end

    after
        unlet g:O
    end

    it 'parses empty argument'
        Expect g:O.parse('') == {'__unknown_args__' : []}
    end

    it 'deals with <bang>'
        Expect g:O.parse('', '!') == {'__unknown_args__' : [], '__bang__' : '!'}
    end

    it 'deals with <count>'
        Expect g:O.parse('', 3) == {'__unknown_args__' : [], '__count__' : 3}
    end

    it 'deals with <reg>'
        Expect g:O.parse('', 'g') == {'__unknown_args__' : [], '__reg__' : 'g'}
    end

    it 'deals with <range>'
        Expect g:O.parse('', [1, 100]) == {'__unknown_args__' : [], '__range__' : [1, 100]}
    end

    " TODO random test; generate combination of special cases randomly
    it 'deals with command special options regardless of the order of and number of arguments'
        " count command
        let cands = ['g', 42, '!']
        let perms = s:permutation(cands)
        for p in perms
            Expect call(g:O.parse, [''] + p, g:O) == {'__unknown_args__' : [], '__count__' : 42, '__bang__' : '!', '__reg__' : 'g'}
        endfor

        " range command
        let cands = ['g', [1, 100], '!']
        let perms = s:permutation(cands)
        for p in perms
            Expect call(g:O.parse, [''] + p, g:O) == {'__unknown_args__' : [], '__range__' : [1, 100], '__bang__' : '!', '__reg__' : 'g'}
        endfor
    end

    it 'parses --hoge as ''hoge'' : 1'
        call g:O.on('--hoge', 'huga')
        Expect g:O.parse('--hoge') == {'__unknown_args__' : [], 'hoge' : 1}
    end

    it 'parses --hoge=VALUE as ''hoge'' : ''VALUE'' and echos an error when VALUE is omitted'
        call g:O.on('--hoge=VALUE', 'huga')
        Expect g:O.parse('--hoge=huga') == {'__unknown_args__' : [], 'hoge' : 'huga'}
        Expect "call g:O.parse('--hoge')" to_throw_exception
    end

    it 'parses --[no-]hoge as ''hoge'' : 0 or 1'
        call g:O.on('--[no-]hoge', 'huga')
        Expect g:O.parse('--no-hoge') == {'__unknown_args__' : [], 'hoge' : 0}
        Expect g:O.parse('--hoge') == {'__unknown_args__' : [], 'hoge' : 1}
    end

    it 'doesn''t parse arguments not defined with on()'
        call g:O.on('--foo', 'huga')
        call g:O.on('--bar=VALUE', 'huga')
        call g:O.on('--[no-]baz', 'huga')
        Expect g:O.parse('--hoge') == {'__unknown_args__' : ['--hoge']}
        Expect g:O.parse('--huga=poyo') == {'__unknown_args__' : ['--huga=poyo']}
        Expect g:O.parse('--no-poyo') == {'__unknown_args__' : ['--no-poyo']}
        Expect g:O.parse('--hoge --huga=poyo --no-poyo') == {'__unknown_args__' : ['--hoge', '--huga=poyo', '--no-poyo']}
    end

    it 'parses all argument types at one time regardless of the order of arguments'
        call g:O.on('--hoge', '')
        call g:O.on('--huga=VALUE', '')
        call g:O.on('--[no-]poyo', '')
        let args = ['--hoge', '--huga=foo', '--no-poyo', 'unknown_arg']
        let perms = s:permutation(args)
        for p in perms
            Expect g:O.parse(join(p, ' ')) ==
                        \ {'__unknown_args__' : ['unknown_arg'], 'hoge' : 1, 'huga' : 'foo', 'poyo' : 0}
        endfor
    end

    it 'parses all options defined with on() and command options at one time refardless of the order of arguments'
        call g:O.on('--hoge', '')
        call g:O.on('--huga=VALUE', '')
        call g:O.on('--[no-]poyo', '')
        let args = map(s:permutation(['--hoge', '--huga=foo', '--no-poyo', 'unknown_arg']), 'join(v:val, " ")')
        let opts_count = s:permutation(['g', 42, '!'])
        let opts_range = s:permutation(['g', [1, 100], '!'])

        " command with <count>
        for a in args
            for oc in opts_count
                Expect call(g:O.parse, [a] + oc, g:O) ==
                            \ {
                            \   '__unknown_args__' : ['unknown_arg'],
                            \   '__count__' : 42,
                            \   '__bang__' : '!',
                            \   '__reg__' : 'g',
                            \   'hoge' : 1,
                            \   'huga' : 'foo',
                            \   'poyo' : 0
                            \ }
            endfor
        endfor

        " command with <range>
        for a in args
            for or in opts_range
                Expect call(g:O.parse, [a] + or, g:O) ==
                            \ {
                            \   '__unknown_args__' : ['unknown_arg'],
                            \   '__range__' : [1, 100],
                            \   '__bang__' : '!',
                            \   '__reg__' : 'g',
                            \   'hoge' : 1,
                            \   'huga' : 'foo',
                            \   'poyo' : 0
                            \ }
            endfor
        endfor
    end
end
