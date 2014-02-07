function! optparse#completion#file(arglead, cmdline, cursorpos)
    let candidates = glob(a:arglead . '*', 0, 1)
    if a:arglead =~# '^\~'
        let home_matcher = '^' . expand('~') . '/'
        call map(candidates, "substitute(v:val, home_matcher, '~/', '')")
    endif
    call map(candidates, "escape(isdirectory(v:val) ? v:val.'/' : v:val, ' \\')")
    return candidates
endfunction
