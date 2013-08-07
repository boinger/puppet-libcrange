class libcrange::install (
  $libcrange_name     = 'libcrange',
  $libcrange_home     = '/usr',
  $libcrange_temp     = '/tmp',
  $libcrange_provider = 'git',
  $libcrange_giturl   = 'https://github.com/boinger/libcrange.git',
  )
{
  if $libcrange_provider == 'package' {
    package {
      'libcrange':
        ensure => 'latest';
    }
  }
  elsif $libcrange_provider == 'git' {

    file {
      "${libcrange_temp}":
        ensure => directory;
    }

    exec {
      "git clone libcrange":
        cwd     => $libcrange_temp,
        command => "git clone $libcrange_url",
        creates => $libcrange_temp/libcrange,
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

      "make libcrange":
        cwd     => "${libcrange_temp}/libcrange/source",
        user    => root,
        command => "make install",
        creates => "${libcrange_home}/bin/crange",
        require => Exec['make libcrange'];
    }
 }
 elsif $libcrange_provider == 'external' {
    notify { "It's up to you to provde $libcrange_jar": }
  }
}