let s:root_dir = matchstr(system('git rev-parse --show-cdup'), '[^\n]\+')
execute 'set' 'rtp +=./'.s:root_dir

call vspec#matchers#load()

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
        let perms = []
        for c in cands
            let rest = filter(deepcopy(cands), 'type(v:val) != type(c) || v:val != c')
            call add(perms, [c, rest[0], rest[1]])
            call add(perms, [c, rest[1], rest[0]])
            unlet c
        endfor
        for p in perms
            Expect call(g:O.parse, [''] + p, g:O) == {'__unknown_args__' : [], '__count__' : 42, '__bang__' : '!', '__reg__' : 'g'}
        endfor

        " range command
        let cands = ['g', [1, 100], '!']
        let perms = []
        for c in cands
            let rest = filter(copy(cands), 'type(v:val) != type(c) || v:val != c')
            call add(perms, [c, rest[0], rest[1]])
            call add(perms, [c, rest[1], rest[0]])
            unlet c
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
        " TODO use recursive
        for c1 in args
            let r1 = filter(copy(args), 'v:val != c1')
            for c2 in r1
                let r2 = filter(copy(r1), 'v:val != c2')
                for c3 in r2
                    let r3 = filter(copy(r2), 'v:val != c3')
                    let c4 = r3[0]
                    let args_string = join([c1, c2, c3, c4], ' ')
                    Expect g:O.parse(args_string) == {'__unknown_args__' : ['unknown_arg'], 'hoge' : 1, 'huga' : 'foo', 'poyo' : 0}
                endfor
            endfor
        endfor
    end
end
