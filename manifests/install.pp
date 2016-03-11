# == Class vault::install
#
class vault::install {
  $vault_bin = "${::vault::bin_dir}/vault"
  $_version = $::vault::version

  $_download_url = $::vault::download_url ? {
    /http(s|):\/\// => $::vault::download_url,
    default => "https://releases.hashicorp.com/vault/${_version}/vault_${_version}_linux_${::vault::arch}.zip"
  }

  staging::deploy { 'vault.zip':
    source  => $_download_url,
    target  => $::vault::bin_dir,
    creates => $vault_bin,
  } ~>
  file { $vault_bin:
    owner => 'root',
    group => 'root',
    mode  => '0555',
  }

  if !$::vault::config_hash['disable_mlock'] {
    exec { "setcap cap_ipc_lock=+ep ${vault_bin}":
      path        => ['/sbin', '/usr/sbin'],
      subscribe   => File[$vault_bin],
      refreshonly => true,
    }
  }

  user { $::vault::user:
    ensure => present,
  }
  group { $::vault::group:
    ensure => present,
  }

}
