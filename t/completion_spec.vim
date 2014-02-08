let s:root_dir = matchstr(system('git rev-parse --show-cdup'), '[^\n]\+')
execute 'set' 'rtp +=./'.s:root_dir

call vspec#matchers#load()

function! CompleteTest(optlead, cmdline, pos)
    return filter(['sushi', 'yakiniku', 'yakitori'], 'a:optlead == "" ? 1 : (v:val =~# "^" . a:optlead)')
endfunction

function! CompleteTest2(optlead, cmdline, pos)
    return filter(['inu', 'manbou', 'momonga'], 'a:optlead == "" ? 1 : (v:val =~# "^" . a:optlead)')
endfunction

function! CompleteUnknownOptionTest(optlead, cmdline, pos)
    return filter(['vim', 'vimmer', 'kowai'], 'a:optlead == "" ? 1 : (v:val =~# "^" . a:optlead)')
endfunction

describe 'g:Opt.complete()'

    before
        let g:O = optparse#new()
        call g:O.on('--[no-]huga=VALUE', '', {'short' : '-h', 'completion' : function('CompleteTest')})
               \.on('--hoge', '')
               \.on('--piyo', '', {'short' : '-p'})
               \.on('--tsura=VALUE', '', {'completion' : function('CompleteTest2')})
               \.on('--[no-]poyo', '')
        let g:O.unknown_options_completion = function('CompleteUnknownOptionTest')
    end

    after
        unlet g:O
    end

    it 'completes long options'
        echo g:O
        Expect g:O.complete('--', 'Hoge --', 7) == ['--tsura=', '--hoge', '--huga=', '--no-huga=', '--piyo', '--poyo', '--no-poyo']
        Expect g:O.complete('--h', 'Hoge --h', 8) == ['--hoge', '--huga=']
        Expect g:O.complete('--hu', 'Hoge --hu', 9) == ['--huga=']
        Expect g:O.complete('--ho', 'Hoge --ho', 9) == ['--hoge']
        Expect g:O.complete('--p', 'Hoge --p', 8) == ['--piyo', '--poyo']
        Expect g:O.complete('--po', 'Hoge --po', 9) == ['--poyo']
        Expect g:O.complete('--pi', 'Hoge --pi', 9) == ['--piyo']
        Expect g:O.complete('--f', 'Hoge --f', 8) == []
        Expect g:O.complete('--no', 'Hoge --no', 9) == ['--no-huga=', '--no-poyo']
    end

    it 'completes short options'
        Expect g:O.complete('-', 'Hoge -', 6) == ['-h=', '-no-h=', '-p']
        Expect g:O.complete('-h', 'Hoge -h', 7) == ['-h=']
        Expect g:O.complete('-p', 'Hoge -p', 7) == ['-p']
        Expect g:O.complete('-f', 'Hoge -f', 7) == []
    end

    it 'completes values of options with specified complete function'
        Expect g:O.complete('--huga=', 'Hoge --huga=', 12) == ['--huga=sushi', '--huga=yakiniku', '--huga=yakitori']
        Expect g:O.complete('--huga=yaki', 'Hoge --hoge=yaki', 16) == ['--huga=yakiniku', '--huga=yakitori']
        Expect g:O.complete('--tsura=', 'Hoge --tsura=', 13) == ['--tsura=inu', '--tsura=manbou', '--tsura=momonga']
        Expect g:O.complete('--hoge=', 'Hoge --hoge=', 12) == []
    end

    it 'completes unknown argument if "unknown_options_completion" is specified'
        Expect g:O.complete('', 'Hoge ', 5) == ['vim', 'vimmer', 'kowai']
        Expect g:O.complete('vim', 'Hoge vim', 8) == ['vim', 'vimmer']
    end
end
