# Encoding: utf-8
require 'spec_helper'

describe 'et_haproxy::newrelic' do
  let(:chef_run) { ChefSpec::Runner.new .converge(described_recipe) }

  before do
    stub_haproxy_items
  end

  %w(
    newrelic-ng
    newrelic-ng::plugin-agent-default
  ).each do |recipe|
    it "should include the #{recipe} recipe" do
      expect(chef_run).to include_recipe recipe
    end
  end
end
