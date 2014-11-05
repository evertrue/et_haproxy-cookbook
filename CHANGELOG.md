et_haproxy cookbook CHANGELOG
============================
This file is used to list changes made in each version of the et_haproxy cookbook.

v3.4.2 (2014-11-05)
-------------------

* Fix HAProxy stats path for New Relic reporting

v3.4.1 (2014-11-05)
-------------------

* Adjust attribute level for New Relic license to better test
* Add more assertions for `newrelic` recipe

v3.4.0 (2014-11-04)
-------------------

* Increase number of HAProxy logs kept on-disk
    - This is possible due to the fact that we take advantage of additional storage, typically mounted to `/mnt/dev0` by the `storage` cookbook
* Refactor to use the `newrelic_meetme_plugin` cookbook for tracking HAProxy stats

v3.3.3 (2014-10-21)
-------------------

* Include explicit block rules when ssl_disable_redirect is true for an app
* Bump newrelic-ng cookbook version to ~> 0.5

v3.3.2 (2014-10-17)
-------------------

* Switch to entirely pessimistic versioning of cookbooks

v3.3.1 (2014-10-17)
-------------------

* normalize recipe names so that ::default is appended to all recipes with no ::
* Fix logic for finding endpoint fqdn
* Fix double/redundant hostnames in acl lines
* Remove unnecessary apt recipe from kitchen run list
* Temporarily remove unit tests from travis/default test suites (because they are substantially broken now)

v3.3.0 (2014-10-17)
-------------------

* Move to a view-model approach to managing the master config
* Fix Travis-CI convergence issues
* Genericize test data
* Add Coveralls
* Update many underlying Gems and cookbooks

v3.2.1 (2014-08-11)
-------------------

* Add localhost test network to test access control data bag

v3.2.0 (2014-07-09)
-------------------

* Add et_security to install Snort, etc.
* Update ChefSpec tests

v3.1.5 (2014-06-30)
-------------------

* Attributize syslog output file


v3.1.4 (2014-06-29)
-------------------

* Change rotation retention to 50


v3.1.2 (2014-06-17)
-------------------

* Make syslog rate limit burst a configurable attribute


v3.1.1 (2014-06-16)
-------------------

* Add SystemLogRateLimitBurst 800 to rsyslog template


v3.1.0 (2014-06-04)
-------------------

* Add sudoer rules to allow control of HAProxy servers for zero downtime deployments
* Ensure ChefSpec converges the correct recipe
* Update RuboCop to v0.23.0
* Use data_bags supplied w/ cookbook to provide for cloud testing via Travis
* Match local TK config to cloud TK config


v3.0.1 (2014-05-13)
-------------------
* Fix local Test Kitchen config w/r/t nginx
* Use newer et_fog cookbook to fix issue w/ nokogiri dependency installation
* Add `apt::defaul` to the Test Kitchen run list
* Use HTTPS for talking to Berkshelf API server


v3.0.0 (2014-05-09)
-------------------
* Do not allow hdr_reg to be used in a host ACL
* Fix up test environment to support Travis-CI
* Reduced cyclomatic complexity in the helper library (by making more a lot more functions, heh)
* Added an ignore rule to rubocop for the ::Chef we're using in the default recipe

v2.12.2 (2014-05-08)
--------------------
* Fix URL to et_hostname cookbook in Berksfile


v2.12.1 (2014-05-08)
--------------------
* Install Ruby 1.9.x instead of Ruby 1.8.x


v2.12.0 (2014-05-08)
--------------------
* Fix things up to use Berkshelf 3 properly
* Relax some Rubocop rules
* Rubocop cleanup
* Add missing cookbook dependency
* Fix ChefSpec tests to work properly (so much Fog mocking madness)
* Add installation of community [haproxyctl](https://github.com/flores/haproxyctl), which require Ruby
    * Add ChefSpec & Serverspec tests for new `haproxyctl`


v2.11.1
-------
* s/operator/admin/ for socket control user

v2.11.0
-------
* Add New Relic monitoring of HAProxy via the MeetMe Plugin Agent

2.10.0
------

* Add acl key type to application allowed attribute

2.9.7
-----

* Fix NPE in hdr_reg(host) warning logger

2.9.6
-----

* Allow GTE version for et_fog

2.9.5
-----

* Handle host headers other than hdr_beg(host)
* Stop assuming one-to-one recipe/server relationship and in the process clean up nodes for recipes code a bit and move it into private method
* Add attribute validator
* Linting cleanup
* Move private methods to private methods section
* Clean up kitchen yml file
* local reference to et_hostname
* Update Berksfile for berkshelf 3
* Sanitize test data

2.9.4
-----

* Fixed a typo in the header of the 403.http file itself

2.9.3
-----

* Tiny typo fix or error files source name

2.9.2
-----

* Add headers to 403 error message files, change their location, and fix their line terminators.

2.9.1
-----

* Add custom 403 error page

2.9.0
-----

* Add whitelisting of Pingdom API to globally-allowed IPs
    * Allows for tighter security for some internal-only APIs (e.g., Search), without preventing Pingdom from monitoring our systems

2.8.0
-----

* Add stunnel

2.7.1
-----

* Delete some extraneous parenthesis to make the recipe-based servers appear

2.7.0
-----

* Add redirect capability to applications
* Move some ruby code in the template to the helper library (server and backend directives as well as some redirect code)
* Add chef-client 11.10.4 version constraint
* Fix RuboCop compliance

2.6.0
-----

* Make test kitchen work
* Clean up library definitions for to make testing easier
* Clean up library references (using include)
* Pin logrotate at '>= 1.5.0'
* [platform-roadmap-15] - [Make backends optional in application definitions](https://trello.com/c/lwdLGnpU/15-app-token-lock-down "Trello")
* Add warning for missing allow list when access_control is enabled

2.5.5:
------

* Match endpoint prefix hostnames

2.5.4:
------

* Split long lines of trusted IPs into multiple lines
* Add true source IP check to trusted host ACL

2.5.3:
------

* Add "disable ssl redirect" functionality

2.5.2:
------

* Bump et_fog 1.0.2

2.5.1:
------

* [OpsDev-115] - [Add escaping to recipe search string.](https://trello.com/c/8ZyyIefd/115-recipe-search-in-et-haproxy-cookbook-doesn-t-work-if-cookbook-contains-a-colon "Trello")

2.5.0:
------

* [OpsDev-93] - [Add access control](https://trello.com/c/OdklBNsV/93-add-access-control-to-haproxy "Trello")

2.4.0:
------

* [OPS-252] - Provide a command to control haproxy from a shell command

2.3.3:
------

* [OPS-238] - Change local syslog routing position from 30 to 99

2.3.2:
------

* [OPS-233] - Switch to logrotate_app resource to handle log rotation
* [OPS-235] - Fix how redirect policies work for apps with multiple ACLs

2.3.1:
------

* Fix versioning in changelog
* Fix handling of target FQDN for SSL redirects
* Broke out redirect list builder to a library function
* Move syslog-config code to its own recipe
* Fix broken reference to syslog recipe
* Fix incorrect reference to "api_haproxy" in template

2.3.0
-----

* Set up clusters using recipes with search
* Add "or" ACL clauses to use_backend code (oops!)
* Include `apt` recipe on Debian-family machines

2.2.0:
------

* Allow for "or" ACL clauses
* Fix a bug created by adding (!) to acl names

2.1.0:
------

* Fixed how redirect fqdn's are printed
* Made it possible to use negating (!) ACLs

2.0.1:
------

* Enhanced ACL parsing
* Removed some config attribute redundancy

1.0.3:
------

* Don't log haproxy messages to the regular syslog

1.0.2:
------

* Added changelog
* Fixed syslog integration
