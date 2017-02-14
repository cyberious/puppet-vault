begin
  require 'puppet_x/vault/helper'
rescue LoadError
  require 'pathname' # WORK_AROUND #14073 and #7788
  archive = Puppet::Module.find('archive', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find archive module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless archive
  require File.join archive.path, 'lib/puppet_x/vault/helper'
end

Puppet::Type.type(:vault_user).provide(:vault) do

  mk_resource_methods

  commands :vault => 'vault'

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    if resource[:auth_type].nil?
      raise(Puppet::Error, "Auth type required for vault_user #{resource[:username]}")
    end
    if resource[:groups] && resource[:groups].length > 0
      groups_cmd = "groups=#{resource[:groups].join(',')}"
    end
    begin
      PuppetX::Vault::Helper.execute_vault("write auth/#{resource[:auth_type]}/users/#{resource[:username]} #{groups_cmd}")
    rescue Exception => e
      raise(Puppet::Error, "Unable to create user #{resource[:username]}\n#{e}")
    end

    @property_hash[:ensure] = :present
  end

  def destroy
    if resource[:auth_type].nil?
      raise(Puppet::Error, "Auth type required for vault_user #{resource[:username]}")
    end
    PuppetX::Vault::Helper.execute_vault("delete auth/#{resource[:auth_type]}/users/#{resource[:username]}")
  end


  def self.get_groups(user, auth_type)
    groups = []
    begin
      group_lines = PuppetX::Vault::Helper.execute_vault("read auth/#{auth_type}/users/#{user}").split("\n")
      if group_lines
        group_line = group_lines.select { |line| line =~ /^groups/ }[0]
        groups     = group_line.split(' ')[1].split(',')
      end
    rescue Exception => e
      warning("Unable to determin groups for user #{user}")
    end

    groups
  end

  def self.instances
    items = []
    PuppetX::Vault::Helper.auth_types.each do |auth_type|
      begin
        users = PuppetX::Vault::Helper.execute_vault("list auth/#{auth_type}/users").split("\n")
      rescue Exception => e
        users = []
      end
      if users && users.length > 1
        users.shift(2) # Pop off the first two header elements
      end
      users.each do |user|
        groups = get_groups(user, auth_type)
        items << new(
          :name      => user,
          :ensure    => :present,
          :groups    => groups,
          :auth_type => auth_type,
        )
      end
    end
    items
  end

  def self.prefetch(resources)
    users = instances
    resources.keys.each do |name|
      if provider = users.find { |user| user.name == name }
        resources[name].provider = provider
      end
    end
  end

  def groups=(values)
    create
    @property_hash[:groups] = values

    self.groups
  end

end