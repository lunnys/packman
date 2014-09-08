class Proj < PACKMAN::Package
  url 'http://download.osgeo.org/proj/proj-4.8.0.tar.gz'
  sha1 '5c8d6769a791c390c873fef92134bf20bb20e82a'
  version '4.8.0'

  def install
    args = %W[
      --prefix=#{PACKMAN::Package.prefix(self)}
      --enable-static=yes
      --enable-shared=no
    ]
    PACKMAN.run './configure', *args
    PACKMAN.run 'make all'
    PACKMAN.run 'make install'
  end
end