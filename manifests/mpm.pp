define apache::mpm (
  $lib_path       = $::apache::lib_path,
  $apache_version = $::apache::apache_version,
) {
  if ! defined(Class['apache']) {
    fail('You must include the apache base class before using any apache defined resources')
  }

  $mpm     = $name
  $mod_dir = $::apache::mod_dir

  $_lib  = "mod_mpm_${mpm}.so"
  $_path = "${lib_path}/${_lib}"
  $_id   = "mpm_${mpm}_module"

  if versioncmp($apache_version, '2.4') >= 0 {
    file { "${mod_dir}/${mpm}.load":
      ensure  => file,
      path    => "${mod_dir}/${mpm}.load",
      content => "LoadModule ${_id} ${_path}\n",
      require => [
        Package['httpd'],
        Exec["mkdir ${mod_dir}"],
      ],
      before  => File[$mod_dir],
      notify  => Class['apache::service'],
    }
  }

  case $::osfamily {
    'debian': {
      exec { "ln -fs ${::apache::mod_dir}/${mpm}.conf ${::apache::mod_enable_dir}/${mpm}.conf":
        creates => "${::apache::mod_enable_dir}/${mpm}.conf",
        require => Exec["mkdir ${::apache::mod_enable_dir}"],
        before  => File[$::apache::mod_enable_dir],
        notify  => Class['apache::service'],
        onlyif  => "test -f ${::apache::mod_dir}/${mpm}.conf -o ! -f ${::apache::mod_enable_dir}/${mpm}.conf -o ! -h ${::apache::mod_enable_dir}/${mpm}.conf",
      }

      exec { "ln -fs ${::apache::mod_dir}/mpm_${mpm}.conf ${::apache::mod_enable_dir}/${mpm}.conf":
        creates => "${::apache::mod_enable_dir}/${mpm}.conf",
        require => Exec["mkdir ${::apache::mod_enable_dir}"],
        before  => File[$::apache::mod_enable_dir],
        notify  => Class['apache::service'],
        onlyif  => "test ! -f ${::apache::mod_dir}/${mpm}.conf -a \( -f ${::apache::mod_dir}/mpm_${mpm}.conf -o ! -f ${::apache::mod_enable_dir}/${mpm}.conf -o ! -h ${::apache::mod_enable_dir}/${mpm}.conf \)",
      }

      file { "${::apache::mod_enable_dir}/${mpm}.conf":
        ensure => link,
        require => Exec[["ln -fs ${::apache::mod_dir}/${mpm}.conf ${::apache::mod_enable_dir}/${mpm}.conf",
                     "ln -fs ${::apache::mod_dir}/mpm_${mpm}.conf ${::apache::mod_enable_dir}/${mpm}.conf"]],
      }

      if versioncmp($apache_version, '2.4') >= 0 {
        file { "${::apache::mod_enable_dir}/${mpm}.load":
          ensure  => link,
          target  => "${::apache::mod_dir}/${mpm}.load",
          require => Exec["mkdir ${::apache::mod_enable_dir}"],
          before  => File[$::apache::mod_enable_dir],
          notify  => Class['apache::service'],
        }

        if $mpm == 'itk' {
            # Hack to get ITK module loading working properly on Ubuntu 14.04 LTS.
            # The ITK module package on Ubuntu fails to configure properly when the
            # default MPM (event) is configured.
            # TODO: remove when this is no longer necessary.
            if $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease == '14.04' {
              file { [ "${::apache::mod_enable_dir}/mpm_event.conf", "${::apache::mod_enable_dir}/mpm_event.load" ]:
                ensure => absent,
                before => Package["apache2-mpm-${mpm}"],
                notify => Class['apache::service'],
              }
            }

            # The ITK MPM requires the prefork MPM module to be loaded, as well.
            ::apache::mpm { 'prefork':
              lib_path       => $lib_path,
              apache_version => $apache_version,
            }

            file { "${lib_path}/mod_mpm_itk.so":
              ensure  => link,
              target  => "${lib_path}/mpm_itk.so",
              require => Package["apache2-mpm-${mpm}"],
              notify  => Class['apache::service'],
            }
        }
      }

      package { "apache2-mpm-${mpm}":
        ensure => present,
      }
    }
    'freebsd': {
      class { '::apache::package':
        mpm_module => $mpm
      }
    }
    'redhat': {
      # so we don't fail
    }
    'Suse': {
      file { "${::apache::mod_enable_dir}/${mpm}.conf":
        ensure  => link,
        target  => "${::apache::mod_dir}/${mpm}.conf",
        require => Exec["mkdir ${::apache::mod_enable_dir}"],
        before  => File[$::apache::mod_enable_dir],
        notify  => Class['apache::service'],
      }

      if versioncmp($apache_version, '2.4') >= 0 {
        file { "${::apache::mod_enable_dir}/${mpm}.load":
          ensure  => link,
          target  => "${::apache::mod_dir}/${mpm}.load",
          require => Exec["mkdir ${::apache::mod_enable_dir}"],
          before  => File[$::apache::mod_enable_dir],
          notify  => Class['apache::service'],
        }

        if $mpm == 'itk' {
            file { "${lib_path}/mod_mpm_itk.so":
              ensure => link,
              target => "${lib_path}/mpm_itk.so"
            }
        }
      }

      if versioncmp($apache_version, '2.4') < 0 {
        package { "apache2-${mpm}":
          ensure => present,
        }
      }
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }
}
