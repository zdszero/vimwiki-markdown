fun! s:is_wsl()
  let lines = readfile("/proc/version")
  if lines[0] =~ "Microsoft"
    return 1
  endif
  return 0
endfun

fun! s:safe_mkdir()
  if !exists('g:mdip_imgdir_absolute')
    if s:os == "Windows"
      let outdir = expand('%:p:h') . '\' . g:mdip_imgdir
    else
      let outdir = expand('%:p:h') . '/' . g:mdip_imgdir
    endif
  else
    let outdir = g:mdip_imgdir
  endif
  if !isdirectory(outdir)
    call mkdir(outdir)
  endif
  if s:os == "Darwin"
    return outdir
  else
    return fnameescape(outdir)
  endif
endfun

fun! s:save_file_tmp_wsl(imgdir, tmpname) abort
  let tmpfile = a:imgdir . '/' . a:tmpname . '.png'

  let clip_command = "Add-Type -AssemblyName System.Windows.Forms;"
  let clip_command .= "if ([Windows.Forms.Clipboard]::ContainsImage()) {"
  let clip_command .= "[Windows.Forms.Clipboard]::GetImage().Save(\\\""
  let clip_command .= tmpfile ."\\\", [System.Drawing.Imaging.ImageFormat]::Png) }"
  let clip_command = "powershell.exe -sta \"".clip_command. "\""

  call system(clip_command)
  if v:shell_error == 1
    return 1
  else
    return tmpfile
  endif
endfun

fun! s:save_file_tmp_linux(imgdir, tmpname) abort
  if $XDG_SESSION_TYPE == 'wayland'
    let target_cmd = 'wl-paste --list-types'
    let paste_cmd = 'wl-paste --type=%s > %s'
  else
    let target_cmd = 'xclip -selection clipboard -t TARGETS -o'
    let paste_cmd = 'xclip -selection clipboard -t %s -o > %s'
  endif
  let targets = filter(
        \ systemlist(target_cmd),
        \ 'v:val =~# ''image/''')
  if empty(targets) | return 1 | endif

  if index(targets, "image/png") >= 0
    " Use PNG if available
    let mimetype = "image/png"
    let extension = "png"
  else
    " Fallback
    let mimetype = targets[0]
    let extension = split(mimetype, '/')[-1]
  endif

  let tmpfile = a:imgdir . '/' . a:tmpname . '.' . extension
  call system(printf(paste_cmd, mimetype, tmpfile))
  return tmpfile
endfun

fun! s:save_file_tmp_win32(imgdir, tmpname) abort
  let tmpfile = a:imgdir . '\' . a:tmpname . '.png'
  let tmpfile = substitute(tmpfile, '\\ ', ' ', 'g')

  let clip_command = "Add-Type -AssemblyName System.Windows.Forms;"
  let clip_command .= "if ($([System.Windows.Forms.Clipboard]::ContainsImage())) {"
  let clip_command .= "[System.Drawing.Bitmap][System.Windows.Forms.Clipboard]::GetDataObject().getimage().Save('"
  let clip_command .= tmpfile ."', [System.Drawing.Imaging.ImageFormat]::Png) }"
  let clip_command = "powershell -sta \"".clip_command. "\""

  silent call system(clip_command)
  if v:shell_error == 1
    return 1
  else
    return tmpfile
  endif
endfun

fun! s:save_file_tmp_osx(imgdir, tmpname) abort
  let tmpfile = a:imgdir . '/' . a:tmpname . '.png'
  let clip_command = 'osascript'
  let clip_command .= ' -e "set png_data to the clipboard as «class PNGf»"'
  let clip_command .= ' -e "set referenceNumber to open for access POSIX path of'
  let clip_command .= ' (POSIX file \"' . tmpfile . '\") with write permission"'
  let clip_command .= ' -e "write png_data to referenceNumber"'

  silent call system(clip_command)
  if v:shell_error == 1
    return 1
  else
    return tmpfile
  endif
endfun

fun! s:save_file_tmp(imgdir, tmpname)
  if s:os == "Linux"
    " Linux could also mean Windowns Subsystem for Linux
    if s:is_wsl()
      return s:save_file_tmp_wsl(a:imgdir, a:tmpname)
    endif
    return s:save_file_tmp_linux(a:imgdir, a:tmpname)
  elseif s:os == "Darwin"
    return s:save_file_tmp_osx(a:imgdir, a:tmpname)
  elseif s:os == "Windows"
    return s:save_file_tmp_win32(a:imgdir, a:tmpname)
  endif
endfun

fun! s:save_new_file(imgdir, tmpfile)
  let extension = split(a:tmpfile, '\.')[-1]
  let reldir = g:mdip_imgdir
  let cnt = 0
  let filename = a:imgdir . '/' . g:mdip_imgname . cnt . '.' . extension
  let relpath = reldir . '/' . g:mdip_imgname . cnt . '.' . extension
  while filereadable(filename)
    call system('diff ' . a:tmpfile . ' ' . filename)
    if !v:shell_error
      call delete(a:tmpfile)
      return relpath
    endif
    let cnt += 1
    let filename = a:imgdir . '/' . g:mdip_imgname . cnt . '.' . extension
    let relpath = reldir . '/' . g:mdip_imgname . cnt . '.' . extension
  endwhile
  if filereadable(a:tmpfile)
    call rename(a:tmpfile, filename)
  endif
  return relpath
endfun

fun! s:random_name()
  " help feature-list
  if has('win16') || has('win32') || has('win64') || has('win95')
    let l:new_random = strftime("%Y-%m-%d-%H-%M-%S")
    " creates a file like this: `2019-11-12-10-27-10.png`
    " the filesystem on Windows does not allow : character.
  else
    let l:new_random = strftime("%Y-%m-%d-%H-%M-%S")
  endif
  return l:new_random
endfun

fun! s:input_name()
  call inputsave()
  let name = input('Image name: ')
  call inputrestore()
  return substitute(name, ' ', '_', 'g')
endfun

fun! wiki#image#markdown_clipboard_image()
  let s:os = "Windows"
  if !(has("win64") || has("win32") || has("win16"))
    let s:os = substitute(system('uname'), '\n', '', '')
  endif

  let workdir = s:safe_mkdir()
  " change temp-file-name and image-name
  let g:mdip_tmpname = s:input_name()
  if empty(g:mdip_tmpname)
    let g:mdip_tmpname = g:mdip_imgname . '_' . s:random_name()
  endif

  let tmpfile = s:save_file_tmp(workdir, g:mdip_tmpname)
  if tmpfile == 1
    echomsg 'current content in clipboard cannot be pasted as image'
    return
  else
    " let relpath = s:SaveNewFile(g:mdip_imgdir, tmpfile)
    let extension = split(tmpfile, '\.')[-1]
    if extension == 'bmp'
      let imgdir = fnamemodify(tmpfile, ":h")
      call system(printf('cd %s; mogrify -format png %s; rm %s', imgdir, tmpfile, tmpfile))
      let extension = 'png'
    endif
    let relpath = g:mdip_imgdir_intext . '/' . g:mdip_tmpname . '.' . extension
    echomsg "setline ...."
    call setline('.', printf("![%s](%s)", g:mdip_tmpname, relpath))
  endif
endfun

fun! wiki#image#tex_clipboard_image()
  " detect os: https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
  let s:os = "Windows"
  if !(has("win64") || has("win32") || has("win16"))
    let s:os = substitute(system('uname'), '\n', '', '')
  endif

  let workdir = s:safe_mkdir()
  " change temp-file-name and image-name
  let g:mdip_tmpname = s:input_name()
  if empty(g:mdip_tmpname)
    let g:mdip_tmpname = g:mdip_imgname . '_' . s:random_name()
  endif

  let tmpfile = s:save_file_tmp(workdir, g:mdip_tmpname)
  if tmpfile == 1
    return
  else
    " let relpath = s:SaveNewFile(g:mdip_imgdir, tmpfile)
    let extension = split(tmpfile, '\.')[-1]
    if extension == 'bmp'
      call system('cd img; mogrify -format png *.bmp; rm *.bmp')
      let extension = 'png'
    endif
    let relpath = g:mdip_imgdir_intext . '/' . g:mdip_tmpname . '.' . extension
    call setline('.', '\includegraphics{' . relpath . '}')
  endif
endfun

if !exists('g:mdip_imgdir') && !exists('g:mdip_imgdir_absolute')
  let g:mdip_imgdir = 'img'
endif
"allow absolute paths. E.g., on linux: /home/path/to/imgdir/
if exists('g:mdip_imgdir_absolute')
  let g:mdip_imgdir = g:mdip_imgdir_absolute
endif
"allow a different intext reference for relative links
if !exists('g:mdip_imgdir_intext')
  let g:mdip_imgdir_intext = g:mdip_imgdir
endif
if !exists('g:mdip_tmpname')
  let g:mdip_tmpname = 'tmp'
endif
if !exists('g:mdip_imgname')
  let g:mdip_imgname = 'image'
endif
