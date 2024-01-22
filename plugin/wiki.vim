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

if !exists('g:wiki_generate_toc')
  let g:wiki_generate_toc = 1
endif

nnoremap <silent><script> <Plug>(WikiIndex)
      \ :<c-u>call wiki#api#open_index()<CR>
nnoremap <silent><script> <Plug>(WikiOpenHTML)
      \ :<c-u>call wiki#api#open_html()<CR>
nnoremap <silent><script> <Plug>(WikiCreateFollowLink)
      \ :<c-u>call wiki#api#create_follow_link()<CR>
nnoremap <silent><script> <Plug>(WikiCreateFollowDirectory)
      \ :<c-u>call wiki#api#create_follow_directory()<CR>
nnoremap <silent><script> <Plug>(WikiGotoParent)
      \ :<c-u>call wiki#api#goto_parent_link()<CR>
nnoremap <silent><script> <Plug>(WikiDeleteLink)
      \ :<c-u>call wiki#api#delete_link()<CR>
nnoremap <silent><script> <Plug>(WikiRenameLink)
      \ :<c-u>call wiki#api#rename_link()<CR>
nnoremap <silent><script> <Plug>(Wiki2HTML)
      \ :<c-u>call wiki#api#wiki2html(v:false)<CR>
nnoremap <silent><script> <Plug>(Wiki2HTMLBrowse)
      \ :<c-u>call wiki#api#wiki2html(v:true)<CR>
nnoremap <silent><script> <Plug>(WikiPasteImage)
      \ :<c-u>call wiki#api#paste_image()<CR>
nnoremap <silent><script> <Plug>(WikiAll2HTML)
      \ :<c-u>call wiki#api#wiki_all2html(v:false)<CR>
nnoremap <silent><script> <Plug>(WikiClean)
      \ :<c-u>call wiki#api#wiki_all2html(v:false)<CR>

command! WikiIndex                 call wiki#api#open_index()
command! WikiDelete                call wiki#api#delete_link()
command! WikiRename                call wiki#api#rename_link()
command! WikiCreateFollowLink      call wiki#api#create_follow_link()
command! WikiCreateFollowDirectory call wiki#api#create_follow_directory()
command! WikiGotoParent            call wiki#api#goto_parent_link()
command! WikiPasteImage            call wiki#api#paste_image()
command! WikiOpenHTML              call wiki#api#open_html()
command! Wiki2HTML                 call wiki#api#wiki2html(v:false)
command! -bang WikiAll2HTML        call wiki#api#wiki_all2html(<bang>v:false)
command! WikiClean                 call wiki#api#clean()
