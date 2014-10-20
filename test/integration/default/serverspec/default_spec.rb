# Encoding: utf-8
require 'spec_helper'

describe 'Platform' do
  describe group('haproxy') do
    it { should exist }
  end

  describe user('haproxy') do
    it { should exist }
    it { should belong_to_group 'haproxy' }
  end
end

describe 'HAProxy Service' do
  describe package('haproxy') do
    it { should be_installed }
  end

  [
    8080,
    80,
    8443,
    8069
  ].each do |test_port|
    describe port(test_port) do
      it { should be_listening.with('tcp') }
    end
  end
end

describe 'Configuration' do
  describe file('/etc/haproxy/haproxy.cfg') do
    it { should be_file }
    it { should contain 'frontend main' }
    it { should contain 'frontend main_ssl' }

    context 'acls' do
      it 'has acl host-api' do
        contents = '  acl host-api hdr(host) -i api api.local'
        should contain(contents)
          .after(/^frontend main$/)
          .before(/^frontend main_ssl$/)
        should contain(contents)
          .after(/^frontend main_ssl$/)
      end
      it 'has acl uri_search' do
        contents = '  acl uri_search path_beg -i /search'
        should contain(contents)
          .after(/^frontend main$/)
          .before(/^frontend main_ssl$/)
        should contain(contents)
          .after(/^frontend main_ssl$/)
      end
      it 'has acl host-block' do
        contents = '  acl host-block hdr(host) -i block block.local'
        should contain(contents)
          .after(/^frontend main$/)
          .before(/^frontend main_ssl$/)
        should contain(contents)
          .after(/^frontend main_ssl$/)
      end
      it 'has acl exempt_from_access_control' do
        contents = '  acl exempt_from_access_control hdr(host) -i ' \
          'access-control-exempt access-control-exempt.local'
        should contain(contents)
          .after(/^frontend main$/)
          .before(/^frontend main_ssl$/)
        should contain(contents)
          .after(/^frontend main_ssl$/)
      end
      it 'has acl one_more_rule' do
        contents = '  acl one_more_rule path_beg -i /one_more_rule'
        should contain(contents)
          .after(/^frontend main$/)
          .before(/^frontend main_ssl$/)
        should contain(contents)
          .after(/^frontend main_ssl$/)
      end
    end

    context 'apps' do
      context 'host-endpoint-only' do
        app_name = 'host-endpoint-only'
        it 'has acl' do
          should contain("  acl host_endpoint_#{app_name} hdr_beg(host) -i " \
            'hostendpointonly hostendpointonly.local')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'has block rules in non-SSL section' do
          should contain("  block if host_endpoint_#{app_name} " \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips !exempt_from_access_control')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'has block rules in SSL section' do
          should contain("  block if host_endpoint_#{app_name} " \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips !exempt_from_access_control')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
        it 'has use_backend rule in non-SSL section' do
          should contain("  use_backend #{app_name} if host_endpoint_#{app_name}")
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'does not have use_backend rule in SSL section' do
          should_not contain("  use_backend #{app_name} if " \
            "host_endpoint_#{app_name}")
            .after(/^frontend main_ssl$/)
        end
      end

      context 'host-with-endpoint' do
        app_name = 'host-with-endpoint'
        it 'has acl' do
          should contain("  acl host_endpoint_#{app_name} hdr_beg(host) -i " \
            'host-with-endpoint host-with-endpoint.local')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'has block rules' do
          should contain('  block if host-api uri_search ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips !exempt_from_access_control')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
          should contain('  block if host-api one_more_rule ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips !exempt_from_access_control')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'has block rules in SSL section' do
          should contain('  block if host-api uri_search ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips !exempt_from_access_control')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
          should contain('  block if host-api one_more_rule ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips !exempt_from_access_control')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
        it 'has use_backend rule in non-SSL section' do
          should contain("  use_backend #{app_name} if host-api " \
            'uri_search or host-api one_more_rule or ' \
            'host_endpoint_host-with-endpoint')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'does not have use_backend rule in SSL section' do
          should_not contain("  use_backend #{app_name} if host-api " \
            'uri_search or host-api one_more_rule or ' \
            'host_endpoint_host-with-endpoint')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
      end

      context 'host-without-endpoint' do
        app_name = 'host-without-endpoint'
        it 'has block rules in non-SSL section' do
          should contain('  block if host-api uri_search one_more_rule ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'has block rules in SSL section' do
          should contain('  block if host-api uri_search one_more_rule ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
        it 'has use_backend rule in non-SSL section' do
          should contain("  use_backend #{app_name} if host-api uri_search " \
            'one_more_rule')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'does not have use_backend rule in SSL section' do
          should_not contain("  use_backend #{app_name} if host-api uri_search " \
            'one_more_rule')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
      end

      context 'ssl-host-with-endpoint' do
        app_name = 'ssl-host-with-endpoint'
        it 'has acl' do
          should contain("  acl host_endpoint_#{app_name} hdr_beg(host) -i " \
            'ssl-host-with-endpoint ssl-host-with-endpoint.local')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
        it 'has global block rules in non-SSL section' do
          should contain("  block if host-api uri_search\n")
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'has block rules in SSL section' do
          should contain('  block if host-api uri_search ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
        it 'does not have redirect rule in any section' do
          should_not contain("  redirect #{app_name} if host-api uri_search or " \
            'host_endpoint_ssl-host-with-endpoint')
        end
        it 'does not have use_backend rule in non-SSL section' do
          should_not contain("  use_backend #{app_name} if host-api uri_search")
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'has use_backend rule in SSL section' do
          should contain("  use_backend #{app_name} if host-api uri_search or " \
            'host_endpoint_ssl-host-with-endpoint')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
      end

      context 'ssl-redirect-host-with-endpoint' do
        app_name = 'ssl-redirect-host-with-endpoint'
        it 'has acl' do
          should contain("  acl host_endpoint_#{app_name} hdr_beg(host) -i " \
            "#{app_name} #{app_name}.local")
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
        it 'has block rules in non-SSL section' do
          should contain('  block if host-api uri_search ' \
            'uri_ssl-redirect-host-with-endpoint ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        its(:content) do
          should_not match(/^  block if host-api uri_search \
                            uri_ssl-redirect-host-with-endpoint or
                            host_endpoint_#{app_name}$/x)
        end
        it 'has block rules in SSL section' do
          should contain('  block if host-api uri_search ' \
            'uri_ssl-redirect-host-with-endpoint ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
        it 'has redirect rule in non-SSL section' do
          should contain("  redirect prefix https://#{app_name}.local code 301 " \
            'if host-api uri_search uri_ssl-redirect-host-with-endpoint ' \
            "or host_endpoint_#{app_name}")
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'does not have use_backend rule in non-SSL section' do
          should_not contain("  use_backend #{app_name} if host-api uri_search " \
            "uri_ssl-redirect-host-with-endpoint or host_endpoint_#{app_name}")
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'has use_backend rule in SSL section' do
          should contain("  use_backend #{app_name} if host-api uri_search " \
            "uri_ssl-redirect-host-with-endpoint or host_endpoint_#{app_name}")
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
      end

      context 'ssl-host-without-endpoint' do
        app_name = 'ssl-host-without-endpoint'
        its(:content) do
          should match(/^  block if host-api uri_search$/)
        end
        it 'has block rules in SSL section' do
          should contain('  block if host-api uri_search ' \
            'uri_host_without_endpoint !src_access_control_set_global ' \
            '!src_access_control_eips !src_access_control_instance_ext_ips')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
        it 'does not have redirect rule in non-SSL section' do
          should_not contain("  redirect prefix https://#{app_name}.local code " \
            '301 if host-api uri_search uri_host_without_endpoint')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'does not have use_backend rule in non-SSL section' do
          should_not contain("  use_backend #{app_name} if host-api uri_search " \
            'uri_host_without_endpoint')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'has use_backend rule in SSL section' do
          should contain("  use_backend #{app_name} if host-api uri_search " \
            'uri_host_without_endpoint')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
      end

      context 'just-block' do
        it 'has block rules in non-SSL section' do
          should contain('  block if uri_search host-block ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips')
            .after(/^frontend main$/)
            .before(/^frontend main_ssl$/)
        end
        it 'has block rules in SSL section' do
          should contain('  block if uri_search host-block ' \
            '!src_access_control_set_global !src_access_control_eips ' \
            '!src_access_control_instance_ext_ips')
            .after(/^frontend main_ssl$/)
            .before(/^  # backend rules/)
        end
      end
    end

    context 'backends' do
      its(:content) do
        should include("\nbackend host-endpoint-only\n" \
                       "  option httpchk OPTIONS /search/\n" \
                       "  server dev-generic-api-1d 10.0.103.254:8080 check\n")
      end
      its(:content) do
        should include("\nbackend host-with-endpoint\n" \
                       "  server stage-api-1 stage-api-1.local:8080 check\n" \
                       "  server stage-api-2 stage-api-2.local:8080 check\n")
      end
      its(:content) do
        should include("\nbackend host-without-endpoint\n" \
                       "  server dev-generic-api-1d 10.0.103.254:8080\n")
      end
      its(:content) do
        should include("\nbackend ssl-host-with-endpoint\n" \
                       "  server stage-api-1 stage-api-1.local:8080 check\n" \
                       "  server stage-api-2 stage-api-2.local:8080 check\n")
      end
      its(:content) do
        should include("\nbackend ssl-redirect-host-with-endpoint\n" \
                       "  option httpchk OPTIONS /search/\n" \
                       '  server dev-generic-api-cluster-1b 10.0.103.252:8080' \
                       " check\n" \
                       '  server dev-generic-api-cluster-1d 10.0.103.253:8080' \
                       " check\n")
      end
      its(:content) do
        should include("\nbackend ssl-host-without-endpoint\n" \
                       "  server stage-api-1 stage-api-1.local:8080 check\n")
      end
    end
  end

  describe file('/var/run/haproxy.socket') do
    it { should be_socket }
  end

  describe service('haproxy') do
    it { should be_running }
    it { should be_enabled }
  end
end

describe 'haproxyctl' do
  describe package 'ruby1.9.1' do
    it { should be_installed }
  end

  describe package 'haproxyctl' do
    it { should be_installed.by('gem') }
  end

  describe file '/etc/sudoers.d/control_haproxy' do
    it { should be_file }
    its(:content) { should include '/usr/local/bin/haproxyctl enable server *' }
    its(:content) { should include '/usr/local/bin/haproxyctl disable server *' }
  end
end

describe 'Syslog Service' do
  describe file('/etc/rsyslog.d/45-haproxy.conf') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode '644' }
    its(:content) { should match(/if \( \\\s+\(\$syslogfacility-text == 'local0'\) and \\/) }
    its(:content) { should match(/\s+\(\$programname == 'haproxy'\) \\\s+\) \\/) }
    its(:content) { should match(%r{then /var/log/haproxy.log\s+# Log no further\.\.\.\s+& ~}) }
  end

  describe service('rsyslog') do
    it { should be_enabled }
    it { should be_running }
  end
end

describe 'HAProxy log rotation' do
  describe file '/etc/logrotate.d/haproxy' do
    it { should be_file }
    [
      '/var/log/haproxy.log',
      '100M',
      'daily',
      'rotate 50',
      'sharedscripts',
      'compress',
      'notifempty',
      'missingok',
      'reload rsyslog > /dev/null 2>&1 || true'
    ].each { |contents| its(:content) { should include contents } }
  end
end

describe 'SSL certificate' do
  describe file('/etc/ssl/certs/STAR.evertrue.com.pem') do
    it { should be_file }
    its(:content) { should include "-----END CERTIFICATE-----\n\n-----BEGIN CERTIFICATE-----" }
  end

  describe file('/etc/ssl/private/evertrue.key') do
    it { should be_file }
    its(:content) { should include '-----BEGIN RSA PRIVATE KEY-----' }
  end
end

describe 'stunnel service' do
  describe port(443) do
    it { should be_listening }
  end

  describe file('/etc/stunnel/stunnel.conf') do
    it { should be_file }
    its(:content) { should include "[haproxy_ssl]\nconnect = 8443\naccept = 443" }
  end

  describe service('stunnel') do
    it { should be_running }
    it { should be_enabled }
  end
end
