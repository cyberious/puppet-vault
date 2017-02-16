begin
  require 'puppet_x/vault/helper'
  require 'puppet/provider/vault'
rescue LoadError
  require 'pathname' # WORK_AROUND #14073 and #7788
  archive = Puppet::Module.find('archive', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find archive module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless archive
  require File.join archive.path, 'lib/puppet_x/vault/helper'
  require File.join archive.path, 'lib/puppet/provider/vault'
end
Puppet::Type.type(:vault_policy).provide(:vault, :parent => Puppet::Provider::Vault) do


  mk_resource_methods

  commands :vault => 'vault'

  def create
    result = ""
    Tempfile.open(@resource[:name]) do |file|
      begin
        file.write(@resource[:rules])
        file.flush
        result = PuppetX::Vault::Helper.execute_vault("policy-write #{@resource[:name]} #{file.path}")
      rescue => e

      end
    end
    if result !~ /^Policy '#{@resource[:name]}' written/
      fail("Failed to create policy #{@resource[:name]}")
    end
  end

  def destroy
    begin
      PuppetX::Vault::Helper.execute_vault("policy-delete #{@resource[:name]}")
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def self.get_policy_definition(policy)
    policy_def = PuppetX::Vault::Helper.execute_vault("policies #{policy}").chop

    policy_def
  end

  def self.instances
    items = []
    begin
      policies = PuppetX::Vault::Helper.execute_vault("policies").split("\n")
    rescue Exception => e
      policies= []
    end
    policies.each { |policy|
      items << new(
        :name   => policy,
        :ensure => :present,
        :rules  => get_policy_definition(policy),
      )
    }

    items
  end

  def self.prefetch(resources)
    policies = instances
    resources.keys.each do |name|
      if provider = policies.find { |p| p.name == name }
        resources[name].provider = provider
      end
    end
  end


end