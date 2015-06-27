class Vim < PACKMAN::Package
  url 'ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2'
  sha1 '601abf7cc2b5ab186f40d8790e542f86afca86b7'
  version '7.4'

  label :compiler_insensitive

  option 'use_vundle' => false
  option 'without_perl' => false
  option 'without_ruby' => false
  option 'without_python' => false
  option 'without_lua' => false

  patch :embed

  depends_on 'ncurses'
  depends_on 'lua' if not without_lua?

  def install
    PACKMAN.append_env 'LUA_PREFIX', Lua.prefix
    args = %W[
      --prefix=#{prefix}
      --enable-multibyte
      --enable-gui=no
      --enable-cscope
      --without-x
      --with-tlib=ncurses
      --with-features=huge
      --with-compiledby=PACKMAN
    ]
    %w[perl ruby python lua].each do |language|
      if eval "without_#{language}?"
        args << "--disable-#{language}interp"
      else
        args << "--enable-#{language}interp"
      end
    end
    PACKMAN.set_cppflags_and_ldflags [Ncurses]
    PACKMAN.run './configure', *args
    PACKMAN.run 'make -j2'
    PACKMAN.run "make install prefix=#{prefix} STRIP=true"
    if use_vundle?
      bundle_root = "#{ENV['HOME']}/.vim/bundle"
      vundle_root = "#{bundle_root}/Vundle.vim"
      vimrc = "#{ENV['HOME']}/.vimrc"
      PACKMAN.mkdir bundle_root, :skip_if_exist
      if not Dir.exist? vundle_root
        PACKMAN.git_clone bundle_root, 'https://github.com/gmarik/Vundle.vim'
      end
      FileUtils.touch(vimrc) if not File.exist? vimrc
      if not File.open(vimrc, 'r').read.match(/Added by PACKMAN/)
        PACKMAN.append vimrc, <<-EOT.keep_indent
          " ###################################################
          " Added by PACKMAN.
          set nocompatible
          filetype off
          set rtp+=~/.vim/bundle/Vundle.vim
          call vundle#begin()
          Plugin 'gmarik/Vundle.vim'
          " ---> Add you favorate vundle plugins here.
          "Plugin 'Shougo/neocomplete.vim'
          call vundle#end()
          filetype plugin on
          let g:neocomplete#enable_at_startup = 1
          let g:neocomplete#enable_smart_case = 1
          " ###################################################
        EOT
      end
    end
  end
end

__END__
diff --git a/src/os_unix.h b/src/os_unix.h
index 02eeafc..57c45c9 100644
--- a/src/os_unix.h
+++ b/src/os_unix.h
@@ -37,6 +37,10 @@
 # define HAVE_TOTAL_MEM
 #endif
 
+#if defined(__APPLE__)
+#include <AvailabilityMacros.h>
+#endif
+
 #if defined(__CYGWIN__) || defined(__CYGWIN32__)
 # define WIN32UNIX /* Compiling for Win32 using Unix files. */
 # define BINARY_FILE_IO
