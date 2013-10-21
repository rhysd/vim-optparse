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
end
