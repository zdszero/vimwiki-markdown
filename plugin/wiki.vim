if exists('g:wiki_loaded')
  finish
endif
let g:wiki_loaded = 1
let g:markdown_wiki_plug_dir = expand('<sfile>:p:h:h')

if !exists('g:wiki_config')
  let g:wiki_config = {
    \ 'home': expand('~') .. '/Wiki',
    \ 'markdown_dir': 'sources',
    \ 'html_dir': 'docs',
    \ 'theme': 'bootstrap',
    \}
endif

if !exists('g:wiki_preview_port')
  let g:wiki_preview_port = 8022
endif

if !exists('g:wiki_preview_host')
  let g:wiki_preview_host = '127.0.0.1'
endif

" address the http server listens on, empty means all interfaces
if !exists('g:wiki_preview_bind')
  let g:wiki_preview_bind = ''
endif

if !exists('g:wiki_auto_convert')
  let g:wiki_auto_convert = 1
endif

fun! s:wiki_call(func_call)
  if wiki#api#is_under(expand('%:p'), wiki#api#get_path('markdown_dir'))
    exe 'call ' .. a:func_call
  endif
endfun

let s:pandoc_warned = 0

fun! s:auto_convert()
  if !wiki#api#is_under(expand('%:p'), wiki#api#get_path('markdown_dir'))
    return
  endif
  " the conversion below is silent, so warn once about missing pandoc
  if !executable('pandoc')
    if !s:pandoc_warned
      let s:pandoc_warned = 1
      echohl WarningMsg
      echomsg 'vimwiki-markdown: pandoc not found, html is not generated'
      echohl None
    endif
    return
  endif
  sil! call wiki#api#wiki2html(v:false)
endfun

if g:wiki_auto_convert == 1
  aug WikiMarkdown
    au!
    au BufWritePost *.md call <SID>auto_convert()
  aug END
endif

nnoremap <silent><script> <Plug>(WikiHome)
      \ :<c-u>call wiki#api#open_home()<CR>
nnoremap <silent><script> <Plug>(WikiOpenHTML)
      \ :<c-u>call <SID>wiki_call("wiki#api#open_html()")<CR>
nnoremap <silent><script> <Plug>(WikiCreateFollowLink)
      \ :<c-u>call <SID>wiki_call("wiki#api#create_follow_link()")<CR>
nnoremap <silent><script> <Plug>(WikiCreateFollowDirectory)
      \ :<c-u>call <SID>wiki_call("wiki#api#create_follow_directory()")<CR>
nnoremap <silent><script> <Plug>(WikiGotoParent)
      \ :<c-u>call <SID>wiki_call("wiki#api#goto_parent_link()")<CR>
nnoremap <silent><script> <Plug>(WikiDeleteLink)
      \ :<c-u>call <SID>wiki_call("wiki#api#delete_link()")<CR>
nnoremap <silent><script> <Plug>(WikiRenameLink)
      \ :<c-u>call <SID>wiki_call("wiki#api#rename_link()")<CR>
nnoremap <silent><script> <Plug>(Wiki2HTML)
      \ :<c-u>call <SID>wiki_call("wiki#api#wiki2html(v:false)")<CR>
nnoremap <silent><script> <Plug>(Wiki2HTMLBrowse)
      \ :<c-u>call <SID>wiki_call("wiki#api#wiki2html(v:true)")<CR>
nnoremap <silent><script> <Plug>(WikiPasteImage)
      \ :<c-u>call <SID>wiki_call("wiki#api#paste_image()")<CR>
nnoremap <silent><script> <Plug>(WikiAll2HTML)
      \ :<c-u>call <SID>wiki_call("wiki#api#wiki_all2html(v:false)")<CR>
nnoremap <silent><script> <Plug>(WikiClean)
      \ :<c-u>call <SID>wiki_call("wiki#api#wiki_all2html(v:false)")<CR>

command! WikiHome                  call wiki#api#open_home()
command! WikiDelete                call <SID>wiki_call("wiki#api#delete_link()")
command! WikiRename                call <SID>wiki_call("wiki#api#rename_link()")
command! WikiMove                  call <SID>wiki_call("wiki#api#move_link()")
command! WikiCreateFollowLink      call <SID>wiki_call("wiki#api#create_follow_link()")
command! WikiCreateFollowDirectory call <SID>wiki_call("wiki#api#create_follow_directory()")
command! WikiGotoParent            call <SID>wiki_call("wiki#api#goto_parent_link()")
command! WikiPasteImage            call <SID>wiki_call("wiki#api#paste_image()")
command! WikiOpenHTML              call <SID>wiki_call("wiki#api#open_html()")
command! Wiki2HTML                 call <SID>wiki_call("wiki#api#wiki2html(v:false)")
command! -bang WikiAll2HTML        call <SID>wiki_call("wiki#api#wiki_all2html(<bang>v:false)")
command! WikiClean                 call <SID>wiki_call("wiki#api#clean()")
command! WikiServer                call <SID>wiki_call("wiki#api#run_http_server()")
command! WikiReference             call <SID>wiki_call("wiki#api#add_reference()")
command! WikiSyncTheme             call wiki#api#sync_theme()
