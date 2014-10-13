class libcrange::install (
  $libcrange_name      = 'libcrange',
  $libcrange_home      = '/usr',
  $temp_dir            = '/tmp/range',
  $libcrange_provider  = 'git',
  $libcrange_giturl    = 'https://github.com/boinger/libcrange.git',
  )
{
  if $architecture == "x86_64" {
    $lib = "lib64"
  } else {
    $lib = "lib"
  }

  file {
    $temp_dir:
      ensure => directory;

    '/etc/ld.so.conf.d/libperl.conf':
      content => "/usr/${lib}/perl5/CORE";
  }

  if $libcrange_provider == 'git' or $mod_ranged_provider == 'git' {
    $build_tools = [
      'autoconf',
      'automake',
      'bison',
      'byacc',
      'gcc',
      'git',
      'libtool',
      'make',
      ]

    libcrange::pkg_install { $build_tools: }
  }

  if $operatingsystemmajrelease > 5 {
    $range_deps = [
      "apr",
      "flex",
      "libyaml",
      "pcre",
      "perl",
      "perl-YAML-Syck",
      "perl-core",
      "perl-libs",
      "sqlite",
      ]
  } else {
    $range_deps = [
      "apr",
      "flex",
      "libyaml",
      "pcre",
      "perl",
      "perl-YAML-Syck",
      "sqlite",
      ]
  }

  libcrange::pkg_install { $range_deps: }

  if $libcrange_provider == 'git' {

    if $operatingsystemmajrelease > 5 {
      $range_build_deps = [
        'apr-devel',
        'libyaml-devel',
        'pcre-devel',
        'perl-devel',
        'sqlite-devel',
        ]
    } else {
      $range_build_deps = [
        'apr-devel',
        'libyaml-devel',
        'pcre-devel',
        'sqlite-devel',
        ]
    }

    libcrange::pkg_install { $range_build_deps: }

    exec {
      "git clone ${libcrange_name}":
        cwd     => $temp_dir,
        command => "test -f ${libcrange_name}/.git/HEAD || rm -rf ${libcrange_name} && git clone $libcrange_giturl",
        creates => "${temp_dir}/${libcrange_name}/.git/HEAD",
        timeout => 0,
        path    => ["/usr/bin", "/bin"],
        require => [
          Package['git'],
          File["${temp_dir}"],
        ];

      "make ${libcrange_name}":
        cwd     => "${temp_dir}/${libcrange_name}/source",
        command => "aclocal && libtoolize --force && autoheader && automake -a && autoconf && ./configure --prefix=/usr && make",
        creates => "${temp_dir}/${libcrange_name}/source/src/libcrange.la",
        require => Exec["git clone ${libcrange_name}"];

      "install ${libcrange_name}":
        cwd     => "${temp_dir}/${libcrange_name}/source",
        user    => root,
        command => "make install && ldconfig",
        creates => "${libcrange_home}/bin/crange",
        require => Exec["make ${libcrange_name}"];

      "install ${libcrange_name} perl libs":
        cwd     => "${temp_dir}/${libcrange_name}/source/perl",
        user    => root,
        command => "perl Makefile.PL && make && make install",
        creates => "/usr/local/lib64/perl5/Libcrange.pm",
        require => Exec["install ${libcrange_name}"];

      "install supplemental ${libcrange_name} perl libs":
        cwd     => "${temp_dir}/${libcrange_name}/root",
        user    => root,
        command => "install ./var/libcrange/perl/* /var/libcrange/perl/",
        creates => "/var/libcrange/perl/LibrangeUtils.pm",
        require => [
          File["/var/libcrange/perl"],
          Exec["git clone ${libcrange_name}"],
          ];
    }

    file {
      [
      "/var/libcrange",
      "/var/libcrange/perl"
      ]:
        ensure => directory,
        mode   => 0755;

      "/etc/range.conf":
        source  => "puppet:///modules/${module_name}/etc/range.conf";
    }

    if $lib != 'lib' {
      file {
        "/usr/$lib/libcrange.so.0":
          ensure => '/usr/lib/libcrange.so.0',
          require => Exec["install ${libcrange_name}"];
      }
    }

  }
  else {
    notify { "It's up to you to provde libcrange": }
  }

}