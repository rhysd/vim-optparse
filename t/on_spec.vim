let s:root_dir = matchstr(system('git rev-parse --show-cdup'), '[^\n]\+')
execute 'set' 'rtp +=./'.s:root_dir

call vspec#matchers#load()

describe 'g:Opt.on()'
    before
        let g:Opt = optparse#new()
    end

    after
        unlet g:Opt
    end

    it 'should have 2 or 3 arguments'
        Expect "call g:Opt.on('--a')" to_throw_exception
        Expect "call g:Opt.on('--a', 'b')" not to_throw_exception
        Expect "call g:Opt.on('--a', 'b', 'c', 'd')" to_throw_exception
        Expect "call g:Opt.on('--a', 'b', 'c', 'd', 'e')" to_throw_exception
        SKIP because 3 arguments are not implemented yet
        Expect "call g:Opt.on('--a', 'b', 'c')" not to_throw_exception
    end

    it 'defines --hoge option in g:Opt.options'
        call g:Opt.on('--hoge', 'huga')
        Expect g:Opt.options to_have_key 'hoge'
        Expect g:Opt.options.hoge == {'description': 'huga', 'definition': '--hoge'}
    end

    it 'defines --hoge=VALUE option in g:Opt.options'
        call g:Opt.on('--hoge=VALUE', 'huga')
        Expect g:Opt.options to_have_key 'hoge'
        Expect g:Opt.options.hoge == {'description': 'huga', 'definition': '--hoge=VALUE', 'has_value': 1}
    end

    it 'defines --[no-]hoge option in g:Opt.options'
        call g:Opt.on('--[no-]hoge', 'huga')
        Expect g:Opt.options to_have_key 'hoge'
        Expect g:Opt.options.hoge == {'description': 'huga', 'definition': '--[no-]hoge', 'no': 1}
    end

    it 'occurs an error when invalid option name is specified'
        Expect "call g:Opt.on('invalid_name', '')" to_throw_exception
        Expect "call g:Opt.on('--invalid name', '')" to_throw_exception
    end
end
