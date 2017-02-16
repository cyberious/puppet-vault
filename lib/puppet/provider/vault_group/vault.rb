begin
  require 'puppet/provider/vault_auth_type'
rescue LoadError
  require 'pathname' # WORK_AROUND #14073 and #7788
  archive = Puppet::Module.find('archive', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find archive module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless archive
  require File.join archive.path, 'lib/puppet/provider/vault_auth_type'
end

Puppet::Type.type(:vault_group).provide(:vault, :parent => Puppet::Provider::VaultAuthType) do

  mk_resource_methods

  def policies=(values)
    @property_flush[:policies] = values
  end

  def run_destroy
    execute_vault("delete auth/#{resource[:auth_type]}/groups/#{resource[:name]}")
  end

  def run_create
    if resource[:policies] && resource[:policies].length > 0
      policies_cmd = "policies=#{resource[:policies].join(',')}"
    end
    begin
      result = execute_vault("write auth/#{resource[:auth_type]}/groups/#{resource[:name]} #{policies_cmd}")
    rescue Exception => e
      raise(Puppet::Error, "Unable to create group #{resource[:name]}\n#{e}")
    end

    if result =~ /Success/
      @property_hash[:ensure] = :present
    else
      raise(Puppet::Error, "Did not create group #{resource[:name]}")
    end
  end

  # @api private
  def get_policies(group, auth_type)
    policies = []
    begin
      policies_lines = execute_vault("read auth/#{auth_type}/groups/#{group}").split("\n")
      if policies_lines
        policies_line = policies_lines.select { |line| line =~ /^policies/ }[0]
        policies      = policies_line.split(' ')[1].split(',').sort
      end
    rescue Exception => e
      warning("Unable to determine policies for group #{group}\n#{e}")
    end

    policies
  end

  # @api private
  def get_instance(name, auth_type)
    result = {}
    groups = execute_vault("list auth/#{auth_type}/groups").split("\n")
    if groups.include?(name)
      result = {:name      => name,
                :ensure    => :present,
                :policies  => get_policies(name, auth_type),
                :auth_type => auth_type}
    end

    result
  end

end