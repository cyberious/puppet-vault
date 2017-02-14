require 'puppet/util/execution'

module PuppetX
  module Vault
    module Helper

      def self.get_token
        ENV['VAULT_TOKEN'] #need to replace with lookup of catalog when used with creation
      end

      def self.execute_vault(query)
        Puppet::Util::Execution.execute("vault #{query}", :custom_environment => {'VAULT_TOKEN' => get_token})
      end

      def self.auth_types
        auth_types = PuppetX::Vault::Helper.execute_vault('auth --methods').split("\n")
        auth_types.shift
        auth_types.collect do |auth_type|
          auth_type.split(' ')[0].gsub(/\//, '')
        end
      end

    end
  end
end