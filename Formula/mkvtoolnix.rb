class Mkvtoolnix < Formula
  desc "Matroska media files manipulation tools"
  homepage "https://www.bunkus.org/videotools/mkvtoolnix/"
  url "https://mkvtoolnix.download/sources/mkvtoolnix-27.0.0.tar.xz"
  sha256 "2f45bb2d26a230b78d16c7c5fddbd0d62339f04a04b5738026d4783435e4e8c2"

  bottle do
    sha256 "4c54021ccf2b0d29efe8f042b1e7e50268922144c1f0b6eb18ee98775042de40" => :mojave
    sha256 "31d7f83326a93a88b3d2d671e481a70bba3e8bc6ef5750ade447e7fda85d12dd" => :high_sierra
    sha256 "2dc5720ec4305a953378008d3f84a674dc72ad1c75e92685efe519884e66323a" => :sierra
    sha256 "862b3e38229bd94becfc3c99fa252bfed64d6cb4efcb5775e5c4b91a2a6ab864" => :x86_64_linux
  end

  head do
    url "https://gitlab.com/mbunkus/mkvtoolnix.git"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  option "with-qt", "Build with Qt GUI"

  deprecated_option "with-qt5" => "with-qt"

  depends_on "docbook-xsl" => :build
  depends_on "pkg-config" => :build
  depends_on "pugixml" => :build
  depends_on "ruby" => :build if MacOS.version <= :mountain_lion || !OS.mac?
  depends_on "boost"
  depends_on "flac"
  depends_on "libebml"
  depends_on "libmagic"
  depends_on "libmatroska"
  depends_on "libogg"
  depends_on "libvorbis"
  depends_on "gettext" => OS.mac? ? :optional : :recommended
  depends_on "qt" => :optional
  depends_on "cmark" if build.with? "qt"
  depends_on "libxslt" => :build unless OS.mac? # for xsltproc

  needs :cxx11

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j4" if ENV["CIRCLECI"]

    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog" unless OS.mac?

    ENV.cxx11

    features = %w[flac libmagic libogg libvorbis libebml libmatroska]

    extra_includes = ""
    extra_libs = ""
    features.each do |feature|
      extra_includes << "#{Formula[feature].opt_include};"
      extra_libs << "#{Formula[feature].opt_lib};"
    end
    extra_includes.chop!
    extra_libs.chop!

    args = %W[
      --disable-debug
      --prefix=#{prefix}
      --with-boost=#{Formula["boost"].opt_prefix}
      --with-docbook-xsl-root=#{Formula["docbook-xsl"].opt_prefix}/docbook-xsl
      --with-extra-includes=#{extra_includes}
      --with-extra-libs=#{extra_libs}
    ]

    if build.with?("qt")
      qt = Formula["qt"]

      args << "--with-moc=#{qt.opt_bin}/moc"
      args << "--with-uic=#{qt.opt_bin}/uic"
      args << "--with-rcc=#{qt.opt_bin}/rcc"
      args << "--enable-qt"
    else
      args << "--disable-qt"
    end

    system "./autogen.sh" if build.head?

    system "./configure", *args

    system "rake", *("--trace" if ENV["CIRCLECI"]), "-j#{ENV.make_jobs}"
    system "rake", "install"
  end

  test do
    mkv_path = testpath/"Great.Movie.mkv"
    sub_path = testpath/"subtitles.srt"
    sub_path.write <<~EOS
      1
      00:00:10,500 --> 00:00:13,000
      Homebrew
    EOS

    system "#{bin}/mkvmerge", "-o", mkv_path, sub_path
    system "#{bin}/mkvinfo", mkv_path
    system "#{bin}/mkvextract", "tracks", mkv_path, "0:#{sub_path}"
  end
end
