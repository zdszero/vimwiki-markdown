fun! s:get_path(key)
  return expand(g:wiki_config['home'] .. '/' .. g:wiki_config[a:key])
endfun

fun! s:get_home()
  return expand(g:wiki_config['home'])
endfun

fun! s:join_path(...)
  return join(a:000, '/')
endfun

let s:html_dir_path = s:get_path('html_dir')
let s:markdown_dir_path = s:get_path('markdown_dir')
let s:template_path = s:get_path('template_path')
let s:script_path = s:join_path(g:markdown_wiki_plug_dir, 'bin', 'wiki2html.sh')

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                 get html absolute path using relative path                 "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:html_path(html_rel)
  return s:html_dir_path..'/'..a:html_rel
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"               get markdown absolute path using relative path               "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:markdown_path(md_rel)
  return s:markdown_dir_path..'/'..a:md_rel
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                    get relateive path between two path                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:relative_path_to(parent, child)
  let from_dirs = split(expand(a:parent), '/')
  let to_dirs = split(expand(a:child), '/')
  let from_idx = 0
  let to_idx = 0
  while from_idx < len(from_dirs) && to_idx < len(to_dirs)
    if from_dirs[from_idx] != to_dirs[to_idx]
      break
    endif
    let from_idx += 1
    let to_idx += 1
  endwhile
  let relpath = repeat('../', len(from_dirs) - from_idx - 1)
  let relpath = relpath..join(to_dirs[to_idx:], '/')
  if from_idx == len(from_dirs) -1 && to_idx == len(to_dirs) - 1
    let relpath = './'..relpath
  endif
  return relpath
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"        get current directory's relateive path to markdown directory        "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:cur_dir_relative_path_to_root()
  let dir_abs = expand('%:p:h')
  return s:relative_path_to(s:markdown_dir_path, dir_abs)
endfun

fun! wiki#api#goto_parent_link()
  let filename = expand('%')
  if filename ==# 'index.md'
    let parent_link = expand('%:p:h:h') .. '/' .. 'index.md'
  else
    let parent_link = expand('%:p:h') .. '/' .. 'index.md'
  endif
  if filereadable(parent_link)
    exe 'e ' .. parent_link
  else
    echomsg 'no parent link for this file!'
  endif
endfun

fun! s:edit_link(line)
  let title = matchstr(a:line, '\[\zs.*\ze\]')
  let rel_filepath = matchstr(a:line, '(\zs.*\ze)')
  let abs_filepath = s:join_path(expand('%:p:h'), rel_filepath)
  let file_exist = 1
  if !filereadable(abs_filepath)
    let file_exist = 0
  endif
  let file_dir = fnamemodify(abs_filepath, ':h')
  if !isdirectory(file_dir)
    let choice = input(printf('Create directory %s ? (y/n): ', file_dir))
    if empty(choice) || choice == 'y'
      call mkdir(file_dir, 'p')
    else
      return
    endif
  endif
  exe 'edit ' .. abs_filepath
  if file_exist == 0
    call setline(1, '% ' .. title)
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                   follow or create link in current line                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! wiki#api#create_follow_link()
  let line = getline('.')
  if line =~# '\v\[.*\]\(.*\)'
    call s:edit_link(line)
  else
    if empty(line)
      let line = input('enter makrdown filename: ')
    endif
    let goto_file = substitute(line, ' ', '_',  'g')
    if goto_file !~# '\.md$'
      let goto_file = goto_file..'.md'
    endif
    let md_link = printf('[%s](./%s)', line, goto_file)
    call setline(line('.'), md_link)
    w
  endif
endfun

fun! wiki#api#create_follow_directory()
  let line = getline('.')
  if line =~# '\v\[.*\]\(.*\)'
    call s:edit_link(line)
  else
    if empty(line)
      let line = input('enter sub directory name: ')
    endif
    let dir = substitute(line, ' ', '_',  'g')
    let md_link = printf('[%s index](./%s/index.md)', line, dir)
    call setline(line('.'), md_link)
    w
  endif
endfun

fun! s:try_rename(from, to)
  let res = rename(a:from, a:to)
  if res != 0
    echoerr 'fail to rename '..a:from..' to '..a:to
  endif
endfun

fun! s:rename_directory(abspath, newname)
  let newabs = s:join_path(fnamemodify(a:abspath, ':h'), a:newname)
  call s:try_rename(a:abspath, newabs)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" rename markdown and html file of current link, if cuurent link is index    "
" file, rename the directory                                                 "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! wiki#api#rename_link()
  let line = getline('.')
  let md = matchstr(line, '\v\[.*\]\(\zs.*\ze\)')
  if !empty(md)
    let name = fnamemodify(md, ':t')
    if name =~# '\.md$'
      if name ==# 'index.md'
        let hint = input("Rename directory name to: ")
        if empty(hint)
          return
        endif
        let dir = fnamemodify(md, ':h')
        let dir_rel = s:join_path(s:cur_dir_relative_path_to_root(), dir)
        let dir_abs = s:markdown_path(dir_rel)
        let dir_html_abs = s:html_path(dir_rel)
        call s:rename_directory(dir_abs, hint)
        call s:rename_directory(dir_html_abs, hint)
        let new_link = s:join_path(fnamemodify(dir, ':h'), hint, 'index.md')
        let hint = hint .. ' index'
        let new_line = substitute(line, '\[.*\](.*)', '['..hint..']'..'('..new_link..')', '')
        call setline(line('.'), new_line)
      else
        let hint = input("Rename markdown filename to: ")
        if empty(hint)
          return
        endif
        let new_name = substitute(hint, " ", "_", "g")..'.md'
        let name = fnamemodify(md, ':t')
        let parent_dir = fnamemodify(md, ':h')
        let newmd = parent_dir.."/"..new_name
        let new_line = substitute(line, '\[.*\](.*)', '['..hint..']'..'('..newmd..')', '')
        call setline(line('.'), new_line)
        let parent_absdir = expand('%:p:h') .. '/' .. parent_dir
        let md_abs = s:join_path(parent_absdir, md)
        let newmd_abs = s:join_path(parent_absdir, newmd)
        " rename markdown and html files
        call s:try_rename(md_abs, newmd_abs)
        let reldir = s:relative_path_to(s:markdown_dir_path, parent_absdir)
        let htmlpath = s:html_path(reldir .. '/' .. substitute(name, '.md', '.html', ''))
        if !filereadable(htmlpath)
          return
        endif
        let new_htmlpath = s:html_path(reldir .. '/' .. substitute(new_name, '.md', '.html', ''))
        call s:try_rename(htmlpath, new_htmlpath)
      endif
    else
      echomsg 'current link is not a markdown link, which cannot be renamed!'
    endif
  endif
endfun

fun! s:change_all_image_links(dir, filepath)
  let cnt = count(a:dir, '/') + 1
  if a:dir =~# '^\.\.'
    let sub = repeat('\.\.\/', cnt) .. 'docs'
    let pat = 'docs'
  else
    let sub = 'docs'
    let pat = repeat('\.\.\/', cnt) .. 'docs'
  endif
  let cmd = printf("!sed -i 's/%s/%s/' %s", sub, pat, a:filepath)
  silent! exe cmd
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"     delete all images in markdown file according to its absolute path      "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:delete_images_in_markdown(md_path)
  for line in readfile(a:md_path)
    let relpath = matchstr(line, '\v\[.*\]\(\zs.*\ze\)')
    let abspath = s:join_path(fnamemodify(a:md_path, ':h'), relpath)
    if !empty(relpath)
      let name = fnamemodify(relpath, ':t')
      if name =~# '\v\.(png|jpg|jpeg|bmp|svg|gif|webp)$'
        echo abspath
        call delete(abspath)
        echomsg name..' has been deleted'
      endif
    endif
  endfor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"  delete markdown according to its relative path to markdown root directory  "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:delete_markdown(md_rel)
  let name = fnamemodify(a:md_rel, ':t')
  let html_name = substitute(name, '.md', '.html', '')
  let html_rel = substitute(a:md_rel, '.md', '.html', '')
  let html_path = s:html_path(html_rel)
  let md_path = s:markdown_path(a:md_rel)
  call s:delete_images_in_markdown(md_path)
  call delete(md_path)
  call delete(html_path)
  echomsg name..' and '..html_name..' have been deleted'
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"  delete direcotry according to relative path to current working directory  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:delete_directory(dir)
  for md in split(globpath(a:dir, '**/*.md'))
    let md_rel = s:join_path(s:cur_dir_relative_path_to_root(), md)
    call s:delete_markdown(md_rel)
  endfor
  " relative path to markdown root directory
  let dir_rel = s:join_path(s:cur_dir_relative_path_to_root(), a:dir)
  call system(['rm', '-rf', a:dir])
  call system(['rm', '-rf', s:html_path(dir_rel)])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" delete markdown and html file of current link, if currnet link is index    "
" file, delete the whole directory                                           "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! wiki#api#delete_link()
  let line = getline('.')
  let md = matchstr(line, '\v\[.*\]\(\zs.*\ze\)')
  if !empty(md)
    let name = fnamemodify(md, ':t')
    if name =~# '\.md$'
      if name ==# 'index.md'
        let opt = confirm('Are you sure you want to delete this whole directory?', "&Yes\n&No")
        if opt == 1
          let dir = fnamemodify(md, ':h')
          call s:delete_directory(dir)
        endif
      else
        let opt = confirm('Are you sure you want to delete this link?', "&Yes\n&No")
        if opt == 1
          let md_rel = s:join_path(s:cur_dir_relative_path_to_root(), md)
          call s:delete_markdown(md_rel)
        endif
      endif
    elseif name =~# '\v\.(png|jpg|jpeg|bmp|svg|gif|webp)$'
      let opt = confirm('Are you sure you want to delete this picture?', "&Yes\n&No")
      if opt == 1
        call delete(md)
      endif
      echomsg name..' has been deleted'
    endif
    normal! dd
  endif
endfun

fun! wiki#api#paste_image()
  let image_dir = s:html_dir_path .. '/images'
  let g:mdip_imgdir = s:relative_path_to(expand('%:p'), image_dir)
  call wiki#image#markdown_clipboard_image()
endfun

fun! wiki#api#open_index()
  let wiki_home = s:get_home()
  let init_index = 0
  if !isdirectory(wiki_home)
    let opt = confirm('Do you want to create a new vimwiki?', "&Yes\n&No")
    if opt == 2
      return
    endif
    let init_index = 1
    call mkdir(wiki_home, 'p')
    echomsg wiki_home .. ' has been created'
    let html_dir = g:wiki_config['html_dir']
    let md_dir = g:wiki_config['markdown_dir']
    let img_dir = html_dir..'/images'
    let dirs = [html_dir, md_dir, img_dir]
    for dir in dirs
      call mkdir(s:join_path(wiki_home, dir), 'p')
    endfor
    call system(['cp', '-r', g:markdown_wiki_plug_dir..'/templates', s:get_home()])
  endif
  let index_path = s:markdown_path('index.md')
  silent exe 'edit ' .. index_path
  if init_index == 1
    call setline(1, '% Wiki Home')
    call setline(2, '')
    call setline(3, '<!-- edit your content below -->')
    call setline(4, '')
    call cursor(4, 0)
  endif
endfun

fun! wiki#api#open_html()
  let l:curfile = expand('%')
  let bufpath = expand('%:p:h')
  if bufpath !~# '^' .. s:get_home()
    echoerr 'the current file is not in wiki home directory!'
    return
  endif
  if &ft != 'markdown'
    echoerr &ft .. ' is not markdown'
    return
  endif
  let md_rel = substitute(expand('%:p'), s:markdown_dir_path, '', '')
  let html_rel = substitute(md_rel, '\.md$', '.html', '')
  let html_path = join([s:get_home(), g:wiki_config['html_dir'], html_rel], '/')
  if !filereadable(html_path)
    echomsg 'html has not been coverted for this markdown file'
    return
  endif
  if exists('g:wiki_preview_browser')
    silent! exe '!'..g:wiki_preview_browser..' '..html_path
  else
    let browsers = ['firefox', 'google-chrome', 'chromium']
    for browser in browsers
      let v:errmsg = ''
      silent! exe '!'..browser..' '..html_path
      if v:errmsg == ''
        break
      endif
    endfor
  endif
  redraw
endfun

fun! s:md2html(stem)
  " let depth = count(a:stem, '/')
  let html = s:join_path(s:html_dir_path, a:stem..'.html')
  let html_dir = fnamemodify(html, ':h')
  if !isdirectory(html_dir)
    call mkdir(html_dir, 'p')
  endif
  let md = s:join_path(s:markdown_dir_path, a:stem..'.md')
  call system([s:script_path, md, html, s:template_path, g:wiki_generate_toc])
  if !v:shell_error
    echomsg md..' has been converted to html'
  endif
endfun

fun! s:changed_sources()
  let html_files =  split(globpath(s:html_dir_path, '**/*.html'), '\n')
  let stem_dict = {}
  let changed_stems = []
  for html in html_files
    let suffix = substitute(html, s:html_dir_path .. '/', '', '')
    let stem = substitute(suffix, '.html', '', '')
    let stem_dict[stem] = getftime(html)
  endfor
  let md_files =  split(globpath(s:markdown_dir_path, '**/*.md'), '\n')
  for md in md_files
    let suffix = substitute(md, s:markdown_dir_path .. '/', '', '')
    let stem = substitute(suffix, '.md', '', '')
    if !has_key(stem_dict, stem)
      let changed_stems = add(changed_stems, stem)
    elseif getftime(md) > stem_dict[stem]
      let changed_stems = add(changed_stems, stem)
    endif
  endfor
  return changed_stems
endfun

fun! s:convert_changed()
  for stem in s:changed_sources()
    call s:md2html(stem)
  endfor
endfun

fun! s:convert_all()
  let md_files =  split(globpath(s:markdown_dir_path, '**/*.md'), '\n')
  for md in md_files
    let suffix = substitute(md, s:markdown_dir_path .. '/', '', '')
    let stem = substitute(suffix, '.md', '', '')
    call s:md2html(stem)
  endfor
endfun

fun! s:convert_current()
  let md = expand('%:p')
  if md !~# '^'..s:markdown_dir_path
    echoerr 'the current file is not in wiki home directory and cannot be converted to html'
    return
  endif
  if &ft != 'markdown'
    echoerr &ft .. ' cannot be converted to html'
    return
  endif
  let suffix = substitute(md, s:markdown_dir_path .. '/', '', '')
  let stem = substitute(suffix, '.md', '', '')
  let html = s:join_path(s:html_dir_path, stem..'.html')
  if !filereadable(html) || getftime(md) > getftime(html)
    call s:md2html(stem)
  endif
endfun

fun! s:check_pandoc()
  if executable('pandoc')
    return 1
  else
    echoerr 'You need to install pandoc before converting markdown to html'
    return 0
  endif
endfun

fun! wiki#api#wiki2html(browse)
  if !s:check_pandoc()
    return
  endif
  call s:convert_current()
  if a:browse
    call wiki#api#open_html()
  endif
endfun

fun! wiki#api#wiki_all2html(convert_all)
  if !s:check_pandoc()
    return
  endif
  if a:convert_all
    call s:convert_all()
  else
    call s:convert_changed()
  endif
endfun

fun! wiki#api#clean()
  let md_files =  split(globpath(s:markdown_dir_path, '**/*.md'), '\n')
  let html_files =  split(globpath(s:html_dir_path, '**/*.html'), '\n')
  let stem_dict = {}
  let changed_stems = []
  let redundants = []
  for md in md_files
    let suffix = substitute(md, s:markdown_dir_path .. '/', '', '')
    let stem = substitute(suffix, '.md', '', '')
    let stem_dict[stem] = 1
  endfor
  for html in html_files
    let suffix = substitute(html, s:html_dir_path .. '/', '', '')
    let stem = substitute(suffix, '.html', '', '')
    if !has_key(stem_dict, stem)
      let redundants = add(redundants, html)
    endif
  endfor
  if empty(redundants)
    echo 'wiki is clean now!'
    return
  endif
  for html in redundants
    call delete(html)
    echo 'remove ' .. html
  endfor
endfun
