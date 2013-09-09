puppet-libcrange
================

installs & (eventually) configures [libcrange](https://github.com/boinger/libcrange.git)

##Usage##
Below shows the defaults.

```puppet
  class {
    'libcrange::install':
      libcrange_name      => 'libcrange',
      libcrange_home      => '/usr',
      temp_dir            => '/tmp/range',
      libcrange_provider  => 'git',
      libcrange_giturl    => 'https://github.com/boinger/libcrange.git',
      mod_ranged_name     => 'mod_ranged',
      mod_ranged_provider => 'git',
      mod_ranged_giturl   => 'https://github.com/boinger/mod_ranged.git',
      perl_range_name     => 'perl_seco_data_range',
      perl_range_provider => 'git',
      perl_range_giturl   => 'https://github.com/boinger/perl_seco_data_range.git',
  }
```