Puppet::Type.newtype(:vault_user) do

  ensurable

  newparam(:name, :namevar => true) do
    isnamevar
  end

  newproperty(:groups, :array_matching => :all) do
    desc "Groups that the user should belong to"

  end

  newproperty(:auth_type) do
    newvalues('ldap', 'app-id', 'app-role', 'aws-ec2', 'github')
    validate do |value|
      if value.nil?
        raise(ArgumentError, "Auth type required for user #{self[:name]}")
      end
    end
  end

  autorequire(:vault_group) do
    self[:groups]
  end

end