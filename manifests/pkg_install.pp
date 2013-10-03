define libcrange::pkg_install {
  if (!defined(Package[$name])){
    package {
      $name:
        ensure => installed;
    }
  }
}