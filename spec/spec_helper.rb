require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts

add_custom_fact :staging_http_get, '/usr/sbin/wget'