let s:root_dir = matchstr(system('git rev-parse --show-cdup'), '[^\n]\+')
execute 'set' 'rtp +=./'.s:root_dir

call vspec#matchers#load()

describe 'g:Opt.help()'
    before
        let g:O = optparse#new()
    end

    after
        unlet g:O
    end

    it 'returns help message'
        call g:O.on('--hoge=VALUE', 'description of hoge, must have value')
        call g:O.on('--foo', 'description of foo')
        call g:O.on('--[no-]bar', 'description of bar, contradictable')
        call g:O.on('--baz', 'description of baz, has short option', {'short' : '-b'})
        call g:O.on('--qux', 'description of qux, has default value', {'default' : 3.14})

        Expect g:O.help() ==# join([
                    \   "Options:",
                    \   "  --foo        : description of foo",
                    \   "  --baz, -b    : description of baz, has short option",
                    \   "  --hoge=VALUE : description of hoge, must have value",
                    \   "  --[no-]bar   : description of bar, contradictable",
                    \   "  --qux        : description of qux, has default value (DEFAULT: 3.14)",
                    \ ], "\n")
    end

    it 'returns title-only help if no option is defined'
        Expect g:O.help() ==# "Options:\n"
    end
end
