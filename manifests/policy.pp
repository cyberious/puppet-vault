define vault::policy (
  String $policy                    = $name,
  Enum['absent', 'present'] $ensure = 'present',
  Hash[
    String,
    Struct[{
      policy       => Optional[String],
      capabilities => Optional[Array[Vault::Capability]]
    }]] $rules,
) {

  vault_policy { $name:
    ensure => $ensure,
    rules  => template('vault/policy.hcl.erb')
  }


}