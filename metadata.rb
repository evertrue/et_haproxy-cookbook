# Encoding: utf-8
name             'et_haproxy'
maintainer       'EverTrue, Inc.'
maintainer_email 'eric.herot@evertrue.com'
license          'All rights reserved'
description      'Installs/Configures et_haproxy'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.7.1'

depends 'apt'
depends 'openssl'
depends 'logrotate', '>= 1.5.0'
depends 'et_fog', '= 1.0.3'
