Puppet::Type.newtype(:vault_user) do

  ensurable

  newparam(:username, :namevar => true) do
    isnamevar
  end

  newproperty(:groups, :array_matching => :all) do
    desc "Groups that the user should belong to"
    munge do |value|
      value.downcase
    end
  end

  newproperty(:auth_type) do
    validate do |value|
      if value.nil?
        raise(ArgumentError, "Auth type required for user #{self[:username]}")
      end
    end
  end

  autorequire(:vault_group) do
    self[:groups]
  end

end