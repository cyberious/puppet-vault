begin
  require 'puppet/provider/vault'
rescue LoadError
  require 'pathname' # WORK_AROUND #14073 and #7788
  archive = Puppet::Module.find('archive', Puppet[:environment].to_s)
  raise(LoadError, "Unable to find archive module in modulepath #{Puppet[:basemodulepath] || Puppet[:modulepath]}") unless archive
  require File.join archive.path, 'lib/puppet/provider/vault'
end


class Puppet::Provider::VaultAuthType < Puppet::Provider::Vault


  def initialize(value={})
    super(value)
    @property_hash  = get_instance(resource[:name], value.original_parameters[:auth_type])
    @property_flush = {}
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    if resource[:ensure] == :present
      run_create
    elsif resource[:ensure] == :absent
      run_destroy
    end
  end

end
