# == Class vault::service
class vault::service {

  assert_private()

  service { $::vault::service_name:
    ensure   => running,
    enable   => true,
    provider => $::vault::service_provider,
  }

}
