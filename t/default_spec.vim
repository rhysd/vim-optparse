let s:root_dir = matchstr(system('git rev-parse --show-cdup'), '[^\n]\+')
execute 'set' 'rtp +=./'.s:root_dir

call vspec#matchers#load()

describe 'Default settings'
    it 'define some autoload functions'
        Expect 'let g:Opt = optparse#new()' not to_throw_exception
        Expect 'call g:Opt.parse("hoge")' not to_throw_exception
        Expect '*optparse#lazy#parse' to_exist
        unlet g:Opt
    end
end

describe 'optparse#new()'
    it 'make dictionary to parse options'
        let g:Opt = optparse#new()
        Expect g:Opt to_have_key 'options'
        Expect g:Opt to_have_key 'on'
        Expect g:Opt to_have_key 'parse'
    end
end
