begin
  require 'puppet/provider/vault_auth_type'
rescue LoadError
  require 'pathname' # WORK_AROUND #14073 and #7788
  archive = Puppet::Module.find('archive', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find archive module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless archive
  require File.join archive.path, 'lib/puppet/provider/vault_auth_type'
end

Puppet::Type.type(:vault_user).provide(:vault, :parent => Puppet::Provider::VaultAuthType) do

  mk_resource_methods

  def groups=(values)
    @property_flush[:groups] = values
  end

  def run_create
    if resource[:groups] && resource[:groups].length > 0
      groups_cmd = "groups=#{resource[:groups].join(',')}"
    end
    begin
      result = execute_vault("write auth/#{resource[:auth_type]}/users/#{resource[:name]} #{groups_cmd}")
    rescue Exception => e
      raise(Puppet::Error, "Unable to create user #{resource[:name]}\n#{e}")
    end

    if result =~ /Success/
      @property_hash[:ensure] = :present
    else
      raise(Puppet::Error, "Did not create group #{resource[:name]}")
    end
  end

  def run_destroy
    result = execute_vault("delete auth/#{resource[:auth_type]}/users/#{resource[:name]}")
    if result !~ /^Success!/
      raise(Puppet::Error, "Unable to delete user #{resource[:name]}")
    end
  end

  def get_groups(user, auth_type)
    groups = []
    begin
      group_lines = execute_vault("read auth/#{auth_type}/users/#{user}").split("\n")
      if group_lines
        group_line = group_lines.select { |line| line =~ /^groups/ }[0]
        groups     = group_line.split(' ')[1].split(',')
      end
    rescue Exception => e
      warning("Unable to determin groups for user #{user}")
    end

    groups
  end

  def get_instance(name, auth_type)
    result = {}
    users  = execute_vault("list auth/#{auth_type}/users").split("\n")
    if users.include?(name)
      result = {:name      => name,
                :ensure    => :present,
                :groups    => get_groups(name, auth_type),
                :auth_type => auth_type, }
    end

    result
  end


end