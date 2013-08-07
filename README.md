puppet-libcrange
================

installs & (eventually) configures libcrange

##Usage##
Below shows the defaults.

<pre>
  class {
    'libcrange::install':
      $libcrange_name     => 'libcrange',
      $libcrange_temp     => '/tmp/libcrange',
      $libcrange_provider => 'git',
      $libcrange_giturl   => 'https://github.com/boinger/libcrange.git';
  }
</pre>