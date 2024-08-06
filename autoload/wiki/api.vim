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
let s:template_path = g:markdown_wiki_plug_dir .. '/templates/template.html'
let s:script_path = s:join_path(g:markdown_wiki_plug_dir, 'bin', 'wiki2html.sh')
let s:http_server_opened = 0

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
"                      change path suffix from md to html                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:suffix_md2html(md)
  return substitute(a:md, '.md$', '.html', '')
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

fun! s:simplify_path(path)
  " Split the path by '/'
  let parts = split(a:path, '/')
  let stack = []

  for part in parts
    if part == '..'
      if !empty(stack)
        call remove(stack, -1)
      endif
    elseif part != '.' && part != ''
      call add(stack, part)
    endif
  endfor

  " Join the stack to form the simplified path
  return join(stack, '/')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"     convert a markdown or directory absolute path from sources to docs     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:abs_sources2docs(md_abspath)
  return substitute(s:html_path(s:relative_path_to(s:markdown_dir_path, a:md_abspath)), '.md$', '.html', '')
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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"         get absolute filepath using link in current markdown link          "
"         Two types of link:                                                 "
"           1. [hint](/Dir1/Dir2/Filename)                                   "
"           2. [hint](./Dir/Filename)                                        "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:get_abs_path(filepath)
  if a:filepath =~# '^/'
    let abs_filepath = s:markdown_path(a:filepath)
  else
    let abs_filepath = s:join_path(expand('%:p:h'), a:filepath)
  endif
  return abs_filepath
endfun

fun! s:edit_link(line)
  let title = matchstr(a:line, '\[\zs.*\ze\]')
  let filepath = matchstr(a:line, '(\zs.*\ze)')
  let fragment = matchstr(filepath, '#\zs.*\ze$')
  if !empty(fragment)
    let filepath = substitute(filepath, '#'..fragment, '', '')
  endif
  let abs_filepath = s:get_abs_path(filepath)
  let file_exist = 1
  if !filereadable(abs_filepath)
    let file_exist = 0
  endif
  let file_dir = fnamemodify(abs_filepath, ':h')
  if !isdirectory(file_dir)
    let choice = input(printf('Create directory: %s ? (y/n): ', s:simplify_path(file_dir)))
    if empty(choice) || tolower(choice) == 'y'
      call mkdir(file_dir, 'p')
    else
      return
    endif
  endif
  exe 'edit ' .. abs_filepath
  if !empty(fragment)
    exe '/'..fragment
    nohlsearch
    normal! zt
  endif
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
  if executable('git')
    let git_mv_cmd = printf("git mv -k %s %s", a:from, a:to)
    call system(git_mv_cmd)
    if v:shell_error
      echomsg 'Failed to rename ' . a:from
    else
      echomsg git_mv_cmd
      return
    endif
  endif
  let res = rename(a:from, a:to)
  if res != 0
    echoerr 'Fail to rename '..a:from..' to '..dst
  else
    echomsg 'mv '..a:from..' to '..dst
  endif
endfun

fun! s:try_delete(path)
  if executable('git')
    call system('git rm '..a:path)
    if !v:shell_error
      return
    endif
  endif
  call delete(a:path)
  echomsg a:path.' has been deleted'
endfun

fun! s:rename_directory(abspath, newname)
  let newabs = s:join_path(fnamemodify(a:abspath, ':h'), a:newname)
  call s:try_rename(a:abspath, newabs)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" rename markdown and html file of current link, if cuurent link is index    "
" file, rename the directory                                                 "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! wiki#api#rename_link() abort
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
        let new_dirname = substitute(hint, " ", "_", "g")
        let dirpath = fnamemodify(md, ':h')
        let dir_abspath = s:get_abs_path(dirpath)
        let html_dir_abspath = s:abs_sources2docs(dir_abspath)
        call s:rename_directory(dir_abspath, hint)
        call s:rename_directory(html_dir_abspath, hint)
        let new_link = s:join_path(fnamemodify(dirpath, ':h'), new_dirname, 'index.md')
        let new_line = substitute(line, '\[.*\](.*)', '['..hint..']'..'('..new_link..')', '')
        call setline(line('.'), new_line)
      else
        let hint = input("Rename markdown filename to: ")
        if empty(hint)
          return
        endif
        let new_name = substitute(hint, " ", "_", "g")..'.md'
        let name = fnamemodify(md, ':t')
        let new_md = fnamemodify(md, ':h').."/"..new_name
        let md_abs = s:get_abs_path(md)
        let new_md_abs = s:get_abs_path(new_md)
        call s:try_rename(s:abs_sources2docs(md_abs), s:abs_sources2docs(new_md_abs))
        call s:try_rename(md_abs, new_md_abs)
        let new_line = substitute(line, '\[.*\](.*)', '['..hint..']'..'('..new_md..')', '')
        call setline(line('.'), new_line)
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
  let sed_command = "sed"
  let os_name = system("uname -s")
  if os_name == 'Darwin'
    let sed_command = "gsed"
  elseif os_name == "Linux"
    let sed_command = "sed"
  else
    echomsg "Unsupported platform: " .. os_name
  endif
  let cmd = printf("!%s -i 's/%s/%s/' %s", sed_command, sub, pat, a:filepath)
  silent! exe cmd
endfun

let s:before_abspath = ''

fun! s:choose_move_dir()
  if s:before_abspath == ''
    return
  endif
  let before_root_path = s:relative_path_to(s:markdown_dir_path, s:before_abspath)
  let filename = fnamemodify(s:before_abspath, ':t')
  let after_root_path = getline('.')..'/'..filename
  call s:try_rename(s:markdown_path(before_root_path), s:markdown_path(after_root_path))
  call s:try_rename(s:html_path(s:suffix_md2html(before_root_path)), s:html_path(s:suffix_md2html(after_root_path)))
  bd!
endfun

fun! wiki#api#move_link()
  let line = getline('.')
  let dirs = extend(['/'], map(filter(split(globpath('~/Wiki/sources', '**'), '\n'), "isdirectory(v:val) == v:true"), "substitute(v:val, s:markdown_dir_path, '', '')"))
  let path = matchstr(line, '\v\[.*\]\(\zs.*\ze\)')
  if !empty(path)
    let s:before_abspath = s:get_abs_path(path)
    normal! dd
    botright new wiki_move
    call setline(1, dirs)
    setlocal readonly
    nmap <silent> <buffer> <cr> :<C-u>call <SID>choose_move_dir()<CR>
    echo "choose a directory to move to (using Enter key)"
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"     delete all images in markdown file according to its absolute path      "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:delete_images_in_markdown(md_abspath)
  for line in readfile(a:md_abspath)
    let relpath = matchstr(line, '\v\[.*\]\(\zs.*\ze\)')
    let abspath = s:join_path(fnamemodify(a:md_abspath, ':h'), relpath)
    if filereadable(abspath)
      let name = fnamemodify(relpath, ':t')
      if name =~# '\v\.(png|jpg|jpeg|bmp|svg|gif|webp)$'
        call s:try_delete(abspath)
      endif
    endif
  endfor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"              delete markdown according to its absolute path                 "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:delete_markdown(md_abspath)
  let name = fnamemodify(a:md_abspath, ':t')
  let html_name = s:suffix_md2html(name)
  let html_abspath = s:abs_sources2docs(a:md_abspath)
  call s:delete_images_in_markdown(a:md_abspath)
  call s:try_delete(a:md_abspath)
  call s:try_delete(html_abspath)
  echomsg name..' and '..html_name..' have been deleted'
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                    delete directory using absolute path                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:delete_directory(abs_dirpath)
  for abs_mdpath in split(globpath(a:abs_dirpath, '**/*.md'))
    call s:delete_markdown(abs_mdpath)
  endfor
  call system(['rm', '-rf', a:abs_dirpath])
  call system(['rm', '-rf', s:abs_sources2docs(a:abs_dirpath)])
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
          let dirpath = fnamemodify(md, ':h')
          call s:delete_directory(s:get_abs_path(dirpath))
        endif
      else
        let opt = confirm('Are you sure you want to delete this link?', "&Yes\n&No")
        if opt == 1
          call s:delete_markdown(s:get_abs_path(md))
        endif
      endif
    elseif name =~# '\v\.(png|jpg|jpeg|bmp|svg|gif|webp)$'
      let opt = confirm('Are you sure you want to delete this picture?', "&Yes\n&No")
      if opt == 1
        call s:try_delete(md)
      endif
    endif
    normal! dd
  endif
endfun

fun! wiki#api#paste_image()
  let image_dir = s:html_dir_path .. '/WikiImage'
  let g:mdip_imgdir = s:relative_path_to(expand('%:p'), image_dir)
  call wiki#image#markdown_clipboard_image()
endfun

fun! wiki#api#open_home()
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
    let img_dir = html_dir..'/WikiImage'
    let dirs = [html_dir, md_dir, img_dir]
    for dir in dirs
      call mkdir(s:join_path(wiki_home, dir), 'p')
    endfor
    call system(['cp', '-r', g:markdown_wiki_plug_dir..'/WikiTheme', s:html_dir_path])
  endif
  let index_path = s:markdown_path('index.md')
  silent exe 'edit ' .. index_path
  if init_index == 1
    call setline(1, '% Wiki Home')
    call setline(2, '')
    call setline(3, '')
    call cursor(3, 0)
  endif
endfun

function! s:JobHandler(channel, msg)
  if a:msg !=# ''
    echomsg 'http.server output: ' . a:msg
  endif
endfunction

fun! wiki#api#run_http_server()
  if s:http_server_opened == 0
    if has("nvim")
      call jobstart(['python3', '-m', 'http.server', '-d', s:html_dir_path, g:wiki_preview_port])
    else
      call job_start(['python3', '-m', 'http.server', '-d', s:html_dir_path, g:wiki_preview_port],  {'callback': 's:JobHandler'})
    endif
    echomsg "http server is running on port " .. g:wiki_preview_port
    let s:http_server_opened = 1
  endif
endfun

fun! s:open_html_in_browser(html_path)
  if exists('g:wiki_preview_browser')
    echomsg '!'..g:wiki_preview_browser..' '..a:html_path
    exe '!'..g:wiki_preview_browser..' '..a:html_path
  else
    let browsers = ['firefox', 'google-chrome', 'chromium', 'brave', 'safari']
    for browser in browsers
      if executable(browser)
        exe '!'..browser..' '..a:html_path
        break
      endif
    endfor
  endif
  redraw
endfun

fun! wiki#api#open_html()
  let l:curfile = expand('%')
  let bufpath = expand('%:p:h')
  if bufpath !~# '^' .. s:get_home()
    echoerr 'the current file is not in wiki home directory!'
    return
  endif
  if expand('%') !~# '.md$'
    echoerr &ft .. ' is not markdown'
    return
  endif
  let md_rel = substitute(expand('%:p'), s:markdown_dir_path, '', '')
  let html_rel = s:suffix_md2html(md_rel)
  let html_path = join([s:get_home(), g:wiki_config['html_dir'], html_rel], '/')
  let open_path = 'http://127.0.0.1:' .. g:wiki_preview_port .. html_rel
  if !filereadable(html_path)
    echomsg 'html has not been coverted for this markdown file'
    return
  endif
  call wiki#api#run_http_server()
  call s:open_html_in_browser(open_path)
endfun

fun! s:parse_metadata(mdpath)
  let opts = {}
  let lines = readfile(a:mdpath)
  if len(lines) == 0
    return
  endif
  if lines[0] == '---'
    let lineno = 1
    while lineno < len(lines)
      let line = lines[lineno]
      if line == '---' || line == '...'
        break
      endif
      let parts = split(line, '\v[: ]+')
      if len(parts) == 2
        let opts[parts[0]] = parts[1]
      endif
      let lineno = lineno + 1
    endwhile
  endif
  return opts
endfun

fun! s:md2html(stem)
  let depth = count(a:stem, '/')
  let html = s:join_path(s:html_dir_path, a:stem..'.html')
  let html_dir = fnamemodify(html, ':h')
  if !isdirectory(html_dir)
    call mkdir(html_dir, 'p')
  endif
  let md = s:join_path(s:markdown_dir_path, a:stem..'.md')
  let opts = s:parse_metadata(md)
  let enable_highlight = 1
  if has_key(opts, 'enable_highlight')
    if opts['enable_highlight'] =~ 'false' || opts['enable_highlight'] == '0'
      let enable_highlight = 0
    endif
  endif
  let enable_toc = 1
  if has_key(opts, 'enable_toc')
    if opts['enable_toc'] =~ 'false' || opts['enable_toc'] == '0'
      let enable_toc = 0
    endif
  endif
  let theme = g:wiki_config['theme']
  if has_key(opts, 'theme')
    let theme = opts['theme']
  endif
  if theme !~# '\.css$'
    let theme = theme .. '.css'
  endif
  let target_theme = s:join_path(s:html_dir_path, 'WikiTheme/theme', theme)
  let src_theme = s:join_path(g:markdown_wiki_plug_dir, 'WikiTheme/theme', theme)
  if !filereadable(target_theme) && !filereadable(src_theme)
    echoerr "Error: theme " .. theme " doesn't exist!"
    return
  endif
  if filereadable(src_theme) && getftime(src_theme) > getftime(target_theme)
    call system(printf("cp %s %s", src_theme, target_theme))
    echomsg "Theme " .. theme .. " has been updated"
  endif
  call system(join([s:script_path, md, html, s:template_path, theme, enable_toc, enable_highlight, depth], ' '))
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
  if expand('%') !~# '.md$'
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
  let html_files =  filter(split(globpath(s:html_dir_path, '**/*.html'), '\n'), "v:val !~# 'WikiTheme'")
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
    call s:try_delete(html)
  endfor
endfun

fun! s:insert_text_at_cursor(content)
  let line = getline('.')
  call setline('.', strpart(line, 0, col('.') - 1) . a:content . strpart(line, col('.') - 1))
endfun

let s:wiki_ref_link = ''

fun! s:choose_ref_fragment()
  let line = getline('.')
  bd!
  if line =~# '^#'
    let fragment = matchstr(line, '\v#+ \zs.*\ze')
  else
    let fragment = matchstr(line, '<span id="\zs.*\ze">.*</span>')
  endif
  call s:insert_text_at_cursor(printf('[%s](%s#%s)', fragment, s:wiki_ref_link, fragment))
endfun

fun! s:choose_ref_file()
  let link = getline('.')
  bd!
  let md_abspath = s:markdown_path(link)
  if !filereadable(md_abspath)
    return
  endif
  let fragments = system('grep -E -o "(#+ .*|<span id=\".*\">.*</span>)" '  .. md_abspath) 
  let hint = substitute(substitute(fnamemodify(link, ':t'), '.md$', '', ''), '_', ' ', 'g')
  if !empty(fragments)
    let choice = input(printf('Do you want to refer to a fragment in %s ? (y/n): ', hint))
    if tolower(choice) == 'y'
      echon "\r\r"
      echon ""
      botright new wiki_reference
      call setline(1, split(fragments, '\n'))
      setlocal readonly
      let s:wiki_ref_link = link
      nmap <silent> <buffer> <cr> :<C-u>call <SID>choose_ref_fragment()<CR>
      echo "choose a fragment to refer to (using Enter key)"
      return
    endif
  endif
  call s:insert_text_at_cursor(printf('[%s](%s)', hint, link))
endfun

fun! wiki#api#add_reference()
  let mds = map(split(globpath(s:markdown_dir_path, '**/*.md'), '\n'), "substitute(v:val, s:markdown_dir_path, '', '')")
  botright new wiki_reference
  call setline(1, mds)
  setlocal readonly
  nmap <silent> <buffer> <cr> :<C-u>call <SID>choose_ref_file()<CR>
  echo "choose a markdown file to refer to (using Enter key)"
endfun
