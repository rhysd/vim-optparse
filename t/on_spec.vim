let s:root_dir = matchstr(system('git rev-parse --show-cdup'), '[^\n]\+')
execute 'set' 'rtp +=./'.s:root_dir

function! CompletionTest(optlead, cmdline, col)
    return ['aaa', 'bbb', 'ccc']
endfunction

call vspec#matchers#load()

describe 'g:Opt.on()'
    before
        let g:Opt = optparse#new()
    end

    after
        unlet g:Opt
    end

    it 'should have 2..3 arguments'
        Expect "call g:Opt.on('--a')" to_throw_exception
        Expect "call g:Opt.on('--a', 'b')" not to_throw_exception
        Expect "call g:Opt.on('--a', '-b', 'c')" not to_throw_exception
        Expect "call g:Opt.on('--a', '-b', 'c', 'd')" to_throw_exception
        Expect "call g:Opt.on('--a', 'b', 'c', 'd', 'e')" to_throw_exception
    end

    it 'defines --hoge option in g:Opt.options'
        call g:Opt.on('--hoge', 'huga')
        Expect g:Opt.options to_have_key 'hoge'
        Expect g:Opt.options.hoge == {'description': 'huga', 'definition': '--hoge'}
        call g:Opt.on('--!"#$?', 'huga')
        Expect g:Opt.options to_have_key '!"#$?'
        Expect g:Opt.options['!"#$?'] == {'description': 'huga', 'definition': '--!"#$?'}
    end

    it 'defines short option in g:Opt.options'
        call g:Opt.on('--hoge', 'huga', {'short' : '-h'})
        Expect g:Opt.options.hoge to_have_key 'short_option_definition'
        Expect g:Opt.options.hoge.short_option_definition ==# '-h'

        " non alphabetical characters
        for na in ['!', '"', '#', '$', '%', '&', '''', '(', ')', '~', '\', '[', ']', ';', ':', '+', '*', ',', '.', '/', '1', '2', '_']
            call g:Opt.on('--'.na, 'huga', {'short' : '-'.na})
            Expect g:Opt.options[na] to_have_key 'short_option_definition'
            Expect g:Opt.options[na].short_option_definition ==# '-'.na
        endfor
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

    it 'can chain definitions of options'
        call g:Opt.on('--hoge', '')
                 \.on('--huga', '')
                 \.on('--piyo', '')
                 \.on('--poyo', '')
        Expect g:Opt.options to_have_key 'hoge'
        Expect g:Opt.options to_have_key 'huga'
        Expect g:Opt.options to_have_key 'piyo'
        Expect g:Opt.options to_have_key 'poyo'
    end

    " TODO more invalid names
    it 'occurs an error when invalid option name is specified'
        Expect "call g:Opt.on('invalid_name', '')" to_throw_exception
        Expect "call g:Opt.on('--invalid name', '')" to_throw_exception
    end

    it 'sets default value if the default value is specified'
        call g:Opt.on('--hoge', '')
                 \.on('--huga', '', {'default' : 3})
                 \.on('--tsura', '', 'aaa')
                 \.on('--poyo', 'a', 3)
        Expect g:Opt.options.hoge not to_have_key 'default_value'
        Expect g:Opt.options.huga to_have_key 'default_value'
        Expect g:Opt.options.huga.default_value == 3
        Expect g:Opt.options.tsura to_have_key 'default_value'
        Expect g:Opt.options.tsura.default_value == 'aaa'
        Expect g:Opt.options.poyo to_have_key 'default_value'
        Expect g:Opt.options.poyo.default_value == 3
    end

    it 'sets function for completion with "completion" key'
        call g:Opt.on('--hoge', '', {'completion' : 'file'})
                 \.on('--huga', '', {'completion' : function('CompletionTest')})
                 \.on('--piyo', '')
        Expect g:Opt.options.hoge to_have_key 'completion'
        Expect g:Opt.options.huga to_have_key 'completion'
        Expect g:Opt.options.piyo not to_have_key 'completion'
        Expect g:Opt.options.hoge.completion to_be_funcref
        Expect g:Opt.options.huga.completion to_be_funcref
    end
end
