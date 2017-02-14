Puppet::Type.newtype(:vault_policy) do

  ensurable

  newparam(:name, :namevar => true) do
    isnamevar
    munge do |value|
      value.downcase
    end
  end

  newproperty(:rules) do
    desc "String representing the entire Rules to be inforced"
    munge do |value|
      value.chop
    end
  end
end