begin
  require 'puppet_x/vault/helper'
rescue LoadError
  require 'pathname' # WORK_AROUND #14073 and #7788
  archive = Puppet::Module.find('archive', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find archive module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless archive
  require File.join archive.path, 'lib/puppet_x/vault/helper'
end

Puppet::Type.type(:vault_group).provide(:vault) do


  commands :vault => 'vault'

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    if resource[:policies] && resource[:policies].length > 0
      policies_cmd = "policies=#{resource[:policies].join(',')}"
    end
    begin
      result = PuppetX::Vault::Helper.execute_vault("write auth/#{resource[:auth_type]}/groups/#{resource[:name]} #{policies_cmd}")
    rescue Exception => e
      raise(Puppet::Error, "Unable to create group #{resource[:name]}\n#{e}")
    end
    if result =~ /Success/
      @property_hash[:ensure] = :present
    else
      raise(Puppet::Error, "Did not create group #{resource[:name]}")
    end
  end

  def destroy
    PuppetX::Vault::Helper.execute_vault("delete auth/#{resource[:auth_type]}/groups/#{resource[:name]}")
  end

  mk_resource_methods

  def self.get_policies(group, auth_type)
    policies = []
    begin
      policies_lines = PuppetX::Vault::Helper.execute_vault("read auth/#{auth_type}/groups/#{group}").split("\n")
      if policies_lines
        policies_line = policies_lines.select { |line| line =~ /^policies/ }[0]
        policies      = policies_line.split(' ')[1].split(',').sort
      end
    rescue Exception => e
      warning("Unable to determine policies for group #{group}\n#{e}")
    end

    policies
  end

  def self.instances
    items = []
    PuppetX::Vault::Helper.auth_types.each do |auth_type|
      begin
        groups = PuppetX::Vault::Helper.execute_vault("list auth/#{auth_type}/groups").split("\n")
      rescue Exception => e
        groups = []
      end
      if groups && groups.length > 1
        groups.shift(2) # Pop off the first two header elements
      end
      groups.each do |group|
        policies = get_policies(group, auth_type)
        items << new(
          :name      => group,
          :policies  => policies,
          :ensure    => :present,
          :auth_type => auth_type,
        )
      end
    end

    items
  end

  def self.prefetch(resources)
    groups = instances
    resources.keys.each do |name|
      if provider = groups.find { |group| group.name == name }
        resources[name].provider = provider
      end
    end
  end

  def policies=(values)
    create
    @property_hash[:policies] = values

    self.policies
  end
end