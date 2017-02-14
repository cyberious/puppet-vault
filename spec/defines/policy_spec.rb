require 'spec_helper'

RSpec.describe 'vault::policy' do
  let(:title) { 'teamA' }
  let(:params) {
    {
      :rules => {
        'sys/*'               => {
          'policy' => 'deny',
        },
        'secret/sj/baat'      => {
          'policy'       => 'write',
          'capabilities' => ['create'],
        },
        'secret/super-secret' => {
          'capabilities' => ['deny'],
        }
      },
    }
  }
  it {
    is_expected.to contain_vault_policy('teamA').with_rules(<<-RULE
path "sys/*" {
  policy = "deny"
}
path "secret/sj/baat" {
  policy = "write"
  capabilities = ["create"]
}
path "secret/super-secret" {
  capabilities = ["deny"]
}
    RULE
    )
  }


end