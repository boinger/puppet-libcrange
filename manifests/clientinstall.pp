class libcrange::clientinstall (
  $temp_dir            = '/tmp/range',
  $perl_range_name     = 'perl_seco_data_range',
  $perl_range_provider = 'git',
  $perl_range_giturl   = 'https://github.com/boinger/perl_seco_data_range.git',
  )
{

  Class['libcrange::install'] ->
  Class['libcrange::clientinstall']

  if $perl_range_provider == 'git' {
    exec {
      "git clone ${perl_range_name}":
        cwd     => $temp_dir,
        command => "git clone $perl_range_giturl",
        creates => "${temp_dir}/${perl_range_name}",
        timeout => 0,
        path    => ["/usr/bin"],
        require => [
          Package['git'],
          File["${temp_dir}"],
        ];

      "make ${perl_range_name}":
        cwd     => "${temp_dir}/${perl_range_name}/source",
        command => "perl Makefile.PL && make && make test && make install",
        creates => "/usr/local/share/perl5/Seco/Data/Range.pm",
        require => Exec["git clone ${perl_range_name}"];

      "install er":
        cwd     => "${temp_dir}/${perl_range_name}",
        command => "/usr/bin/install -m 0755 root/usr/bin/er /usr/bin",
        creates => "/usr/bin/er",
        require => Exec["git clone ${perl_range_name}"];

      "install er manpage":
        cwd     => "${temp_dir}/${perl_range_name}",
        command => "/usr/bin/install -m 0644 root/usr/share/man/man1/er.1 /usr/share/man/man1",
        creates => "/usr/share/man/man1/er.1",
        require => Exec["git clone ${perl_range_name}"];
    }

  }
  else {
    notify { "It's up to you to provde ${perl_range_name}": }
  }

}