require 'puppet/util/execution'

class Puppet::Provider::Vault < Puppet::Provider

  initvars

  commands vault: 'vault'

  def get_token
    config_resc = resource.catalog.resources.detect { |resc|
      resc.name == "Vault::Globals"
    }
    if config_resc.nil?
      return ENV['VAULT_TOKEN'] #need to replace with lookup of catalog when used with creation
    end

    config_resc.original_parameters[:admin_token]
  end


  def execute_vault(query)
    Puppet::Util::Execution.execute("vault #{query}", :custom_environment => {'VAULT_TOKEN' => get_token})
  end

  def auth_types
    auth_types = execute_vault('auth --methods').split("\n")
    auth_types.shift
    auth_types.collect do |auth_type|
      auth_type.split(' ')[0].gsub(/\//, '')
    end
  end

end