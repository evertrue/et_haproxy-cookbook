## 2.9.0

* Add whitelisting of Pingdom API to globally-allowed IPs
    * Allows for tighter security for some internal-only APIs (e.g., Search), without preventing Pingdom from monitoring our systems

## 2.8.0

* Add stunnel

## 2.7.1

* Delete some extraneous parenthesis to make the recipe-based servers appear

## 2.7.0

* Add redirect capability to applications
* Move some ruby code in the template to the helper library (server and backend directives as well as some redirect code)
* Add chef-client 11.10.4 version constraint
* Fix RuboCop compliance

## 2.6.0

* Make test kitchen work
* Clean up library definitions for to make testing easier
* Clean up library references (using include)
* Pin logrotate at '>= 1.5.0'
* [platform-roadmap-15] - [Make backends optional in application definitions](https://trello.com/c/lwdLGnpU/15-app-token-lock-down "Trello")
* Add warning for missing allow list when access_control is enabled

## 2.5.5:

* Match endpoint prefix hostnames

## 2.5.4:

* Split long lines of trusted IPs into multiple lines
* Add true source IP check to trusted host ACL

## 2.5.3:

* Add "disable ssl redirect" functionality

## 2.5.2:

* Bump et_fog 1.0.2

## 2.5.1:

* [OpsDev-115] - [Add escaping to recipe search string.](https://trello.com/c/8ZyyIefd/115-recipe-search-in-et-haproxy-cookbook-doesn-t-work-if-cookbook-contains-a-colon "Trello")

## 2.5.0:

* [OpsDev-93] - [Add access control](https://trello.com/c/OdklBNsV/93-add-access-control-to-haproxy "Trello")

## 2.4.0:

* [OPS-252] - Provide a command to control haproxy from a shell command

## 2.3.3:

* [OPS-238] - Change local syslog routing position from 30 to 99

## 2.3.2:

* [OPS-233] - Switch to logrotate_app resource to handle log rotation
* [OPS-235] - Fix how redirect policies work for apps with multiple ACLs

## 2.3.1:

* Fix versioning in changelog
* Fix handling of target FQDN for SSL redirects
* Broke out redirect list builder to a library function
* Move syslog-config code to its own recipe
* Fix broken reference to syslog recipe
* Fix incorrect reference to "api_haproxy" in template

## 2.3.0

* Set up clusters using recipes with search
* Add "or" ACL clauses to use_backend code (oops!)
* Include `apt` recipe on Debian-family machines

## 2.2.0:

* Allow for "or" ACL clauses
* Fix a bug created by adding (!) to acl names

## 2.1.0:

* Fixed how redirect fqdn's are printed
* Made it possible to use negating (!) ACLs

## 2.0.1:

* Enhanced ACL parsing
* Removed some config attribute redundancy

## 1.0.3:

* Don't log haproxy messages to the regular syslog

## 1.0.2:

* Added changelog
* Fixed syslog integration
