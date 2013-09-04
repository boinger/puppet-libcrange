class libcrange::install (
  $libcrange_name     = 'libcrange',
  $libcrange_home     = '/usr',
  $libcrange_temp     = '/tmp/libcrange',
  $libcrange_provider = 'git',
  $libcrange_giturl   = 'https://github.com/boinger/libcrange.git',
  )
{

  define pkg_install { ## Local define to make the dependent package installs go smoothly without conflicts
    if (!defined(Package[$name])){
      package {
        $name:
          ensure => installed;
      }
    }
  }

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

  pkg_install { $range_deps: }

  $build_tools = [
    'autoconf',
    'automake',
    'bison',
    'byacc',
    'gcc',
    'libtool',
    'make',
  ]

  pkg_install { $build_tools: }

  $mod_ranged_deps = [
    ## apache mod deps
    #'flex',
    #'libyaml',
    'perl-ExtUtils-MakeMaker',
    'perl-ExtUtils-Embed',
    'perl-Test-Simple',
    'perl-libwww-perl',
    #'pcre',
    'zlib',
    ## apache mod build deps
    'apr-util-devel',
    'httpd-devel',
    #'pcre-devel',
    #'sqlite-devel',
    'zlib-devel',
    ]

  pkg_install { $mod_ranged_deps: }

  if $libcrange_provider == 'package' {
    package {
      'libcrange':
        ensure => 'present';
    }
  }
  elsif $libcrange_provider == 'git' {

    $range_build_deps = [
      'apr-devel',
      'libyaml-devel',
      'pcre-devel',
      'perl-devel',
      'sqlite-devel',
    ]

    pkg_install { $range_build_deps: }

    file {
      "${libcrange_temp}":
        ensure => directory;
    }

    exec {
      "git clone libcrange":
        cwd     => $libcrange_temp,
        command => "git clone $libcrange_giturl",
        creates => "${libcrange_temp}/libcrange",
        timeout => 0,
        path    => ["/usr/bin"],
        require => [
          Package['git'],
          File["${libcrange_temp}"],
        ];

      "make libcrange":
        cwd     => "${libcrange_temp}/libcrange/source",
        command => "aclocal && libtoolize --force && autoheader && automake -a && autoconf && ./configure --prefix=/usr && make",
        creates => "${libcrange_temp}/libcrange/source/src/libcrange.la",
        require => Exec['git clone libcrange'];

      "install libcrange":
        cwd     => "${libcrange_temp}/libcrange/source",
        user    => root,
        command => "make install && ldconfig",
        creates => "${libcrange_home}/bin/crange",
        require => Exec['make libcrange'];
    }
 }
 elsif $libcrange_provider == 'external' {
    notify { "It's up to you to provde libcrange": }
  }
}