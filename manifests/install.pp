class libcrange::install (
  $libcrange_name      = 'libcrange',
  $libcrange_home      = '/usr',
  $temp_dir            = '/tmp/range',
  $libcrange_provider  = 'git',
  $libcrange_giturl    = 'https://github.com/boinger/libcrange.git',
  $mod_ranged_name     = 'mod_ranged',
  $mod_ranged_provider = 'git',
  $mod_ranged_giturl   = 'https://github.com/boinger/mod_ranged.git',
  )
{
  if $architecture == "x86_64" {
    $lib = "lib64"
  } else {
    $lib = "lib"
  }

  define pkg_install { ## Local define to make the dependent package installs go smoothly without conflicts
    if (!defined(Package[$name])){
      package {
        $name:
          ensure => installed;
      }
    }
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

    pkg_install { $build_tools: }
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

  if $libcrange_provider == 'package' {
    package {
      $libcrange_name:
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

    exec {
      "git clone ${libcrange_name}":
        cwd     => $temp_dir,
        command => "git clone $libcrange_giturl",
        creates => "${temp_dir}/${libcrange_name}",
        timeout => 0,
        path    => ["/usr/bin"],
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
    }

    if $lib != 'lib' {
      file {
        "/usr/$lib/libcrange.so.0":
          ensure => '/usr/lib/libcrange.so.0',
          require => Exec["install ${libcrange_name}"];
      }
    }

  }
  elsif $libcrange_provider == 'external' {
    notify { "It's up to you to provde libcrange": }
  }

  if $mod_ranged_provider == 'package' {
    package {
      $mod_ranged_name:
        ensure => 'present';
    }
  }
  elsif $mod_ranged_provider == 'git' {

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

    file {
      [ "/etc/range", "/etc/range/conf", ]:
        mode   => 0755,
        ensure => directory;

      "/etc/range.conf":
        content => "loadmodule nodescf\n";

      "/etc/httpd/htdocs":
        ensure => "/var/www/html";

      "/etc/httpd/conf.d/${mod_ranged_name}.conf":
        mode    => 644,
        source  => "puppet:///modules/${module_name}/etc/httpd/conf.d/mod_ranged.conf",
        notify  => Service['httpd'],
        require => Package['httpd'];
    }

    exec {
      "git clone ${mod_ranged_name}":
        cwd     => $temp_dir,
        command => "git clone $mod_ranged_giturl",
        creates => "${temp_dir}/${mod_ranged_name}",
        timeout => 0,
        path    => ["/usr/bin"],
        require => [
          Package['git'],
          File["${temp_dir}"],
        ];

      "apxs ${mod_ranged_name}":
        cwd     => "${temp_dir}/${mod_ranged_name}/source",
        command => "/usr/sbin/apxs -c mod_ranged.c -lcrange",
        creates => "${temp_dir}/$mod_ranged_name/source/.libs/${mod_ranged_name}.so",
        require => [
          Exec["git clone ${mod_ranged_name}"],
          Package["httpd"],
          ];

      "install ${mod_ranged_name}.so":
        cwd     => "${temp_dir}/${mod_ranged_name}/source",
        command => "/usr/bin/install -m 0755 .libs/${mod_ranged_name}.so /usr/${lib}/httpd/modules",
        creates => "/usr/${lib}/httpd/modules/${mod_ranged_name}.so",
        notify  => Service['httpd'],
        require => Exec["apxs ${mod_ranged_name}"];
    }

  }
  elsif $mod_ranged_provider == 'external' {
    notify { "It's up to you to provde mod_ranged": }
  }

}