function! optparse#completion#file(optlead, cmdline, cursorpos)
    let candidates = glob(a:optlead . '*', 0, 1)
    if a:optlead =~# '^\~'
        let home_matcher = '^' . expand('~') . '/'
        call map(candidates, "substitute(v:val, home_matcher, '~/', '')")
    endif
    call map(candidates, "escape(isdirectory(v:val) ? v:val.'/' : v:val, ' \\')")
    return candidates
endfunction
