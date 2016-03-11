# == Class vault::params
#
# This class is meant to be called from vault.
# It sets variables according to platform.
#
class vault::params {
  $user             = 'vault'
  $group            = 'vault'
  $bin_dir          = '/usr/local/bin'
  $config_dir       = '/etc/vault'
  $source_url       = 'https://releases.hashicorp.com/vault/'
  $service_name     = 'vault'
  $arch             = $::architecture ? {
    /(x86_64|amd64)/  => 'amd64',
    default => $::architecture,
  }
  $service_provider = $osfamily ? {
    'Debian'  => 'upstart',
    'RedHat'  => 'init',
    default   => 'upstart',
  }
}
