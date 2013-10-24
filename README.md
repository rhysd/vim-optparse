Option parser for Vim script
============================

[![Build Status](https://travis-ci.org/rhysd/vim-optparse.png?branch=master)](https://travis-ci.org/rhysd/vim-optparse)

This is an option parser for Vim script. It can parse `--key=VALUE` arguments and command options such as `<count>`, `<bang>` and so on.
Note that now this library is under construction.

## Usage

At first, make new instnce of a parser with `optparse#new()`, then define options you want to parse with `on({definition}, {description})` funcref.  At last, define command with `parse({args}, [{count}, {bang}, {reg}, {range}])`.  Note that you must use `<a-args>` for `{args}`, `<count>` for `{count}`, `<q-bang>` for `{bang}` and `[<line1>, <line2>]` for `{range}`.  This library's interface is inspired by `OptionParser` in Ruby.

## TODO

- short options(wip)
- add tests
- refactorings

## Example

```vim
" make option parser instance
let s:opt = optparse#new()

" define options
call s:opt.on('--hoge=VALUE', 'description of hoge, option with value')
call s:opt.on('--foo', 'description of foo')
call s:opt.on('--[no-]bar', 'this is description of bar, contradictable')

" define command with the parser
command! -nargs=* -count -bang Hoge echo s:opt.parse(<q-args>, <count>, <q-bang>)

" execute!
Hoge! --hoge=huga --no-bar poyo
" => {
"      '__count__' : 0,
"      '__bang__' : '!',
"      'hoge' : 'huga',
"      'bar' : 0,
"      '__unknown_args__' : ['poyo'],
"    }

" show help
Hoge --help
" echo following message
"   --hoge=VALUE : description of hoge, option with value
"   --foo        : description of foo
"   --[no-]bar   : this is description of bar, contradictable
"
" => {
"      '__count__' : 0,
"      'help' : 1,
"    }
```

## License

Copyright (c) 2013 rhysd [MIT License](http://opensource.org/licenses/MIT).
