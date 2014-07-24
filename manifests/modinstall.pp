class libcrange::modinstall (
  $libcrange_name      = 'libcrange',
  $temp_dir            = '/tmp/range',
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

  Class['libcrange::install'] ->
  Class['libcrange::modinstall']

  if $mod_ranged_provider == 'git' {

    $mod_ranged_deps = [
      ## apache mod deps
      #'flex',
      #'libyaml',
      'perl-ExtUtils-MakeMaker',
      'perl-ExtUtils-Embed',
      'perl-Test-Simple',
      #'perl-libwww-perl', ## installed by client
      #'pcre',
      'zlib',
      ## apache mod build deps
      'apr-util-devel',
      'httpd-devel',
      #'pcre-devel',
      #'sqlite-devel',
      'zlib-devel',
      ]

    libcrange::pkg_install { $mod_ranged_deps: }

    file {
      "/etc/range":
        mode   => 0755,
        ensure => directory;

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
          Exec["install ${libcrange_name}"],
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
  else {
    notify { "It's up to you to provde mod_ranged": }
  }

}