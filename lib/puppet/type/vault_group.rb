Puppet::Type.newtype(:vault_group) do

  ensurable

  newparam(:name, :namevar => true) do

  end


  newproperty(:policies, :array_matching => :all) do
    munge do |value|
      value.downcase # Vault always forces policies to be lowercase
    end
  end

  newproperty(:auth_type) do
    newvalues('ldap', 'app-id', 'app-role', 'aws-ec2', 'github')
  end

  autorequire(:vault_policy) do
    self[:policies]
  end

  def validate
    if !self[:policies].nil? && !self[:policies].empty?
      if self[:policies].include?('root')
        if self[:policies].length > 1
          fail("When providng root as policy it will never contain any additional policies")
        end
      else
        if !self[:policies].include?('default')
          self[:policies] = self[:policies] << 'default'
          info("Group policies will always include default, adding to #{self[:name]}")
        end
        self[:policies] = self[:policies].sort
      end
    end
  end
end