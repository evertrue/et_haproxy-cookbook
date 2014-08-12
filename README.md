# et_haproxy cookbook

[![Build Status](https://travis-ci.org/evertrue/et_haproxy-cookbook.svg?branch=master)](https://travis-ci.org/evertrue/et_haproxy-cookbook)
[![Coverage Status](https://img.shields.io/coveralls/evertrue/et_haproxy-cookbook.svg)](https://coveralls.io/r/evertrue/et_haproxy-cookbook)

This cookbook installs and configures the haproxy load balancer according to rules defined in node defintions.

# Requirements

- `openssl` - Requires the "openssl" cookbook for generating random passwords.

# Usage

It is recommended that you wrap this cookbook with a "wrapper" application-specific cookbook by creating said cookbook, then using include_recipe in recipes/default.rb to reference this recipe.  Specific rules should then be added to the attributes in that cookbook.  See: http://devopsanywhere.blogspot.com/2012/11/how-to-write-reusable-chef-cookbooks.html

You should not need to write any recipe code (other than the aforementioned `include_recipe` line) in order to make this cookbook work.

# Rules Attributes

At the heart of how to configure a rule in this cookbook are the rules attributes.  These attributes take the form of {key1 => {subkey => value, key2 => {subkey=>value}} hashes and consist of frontend rules, backend rules, and application rules to tie them together (See: http://code.google.com/p/haproxy-docs/wiki/Proxies): 

### Frontend Rules
```
set['haproxy']['frontends'] = {
  "main" => {
    "port" => "8080",
    "ssl" => false,
    "x_forwarded_for" => true,
    "applications" => [
      "contactsapi-prod",
      "authapi-prod"
    ]
  },
  "main_ssl" => {
    "port" => "8443",
    "ssl" => true,
    "x_forwarded_for" => true,
    "applications" => [
      "contactsapi-prod",
      "authapi-prod"
    ]
  }
}
```
These define haproxy "listeniners."  Each must have a unique port/ip pair.  In the current revision of this cookbook, only ports can be specified.  Haproxy will always listen on all available IPs.  

- `port` - Sets the port that this listener listens on.
- `ssl` - This does not actually enable SSL, but instead identifies the listener as one where it is known that the connection is encrypted (i.e. because it is behind an SSL-enabled Elastic Load Balancer).  This is used in concert with "SSL-Required" rules (see below) to make sure that apps requiring SSL are always routed through the SSL channel.  The "X-Forwarded-Proto: https" is also appended.
- `x_forwarded_for` - Appends the X-Forwarded-For header to incoming requests.  This allows properly configured internal hosts to log the "real" source IP of the connection.
- `applications` - An array consisting of the names of the applications for which this frontend should contain routing rules.  Note that for an application to be redirected from a non-SSL frontend to an SSL frontend, its name must still appear on this list in order for the redirect rules to be generated.

### Application Rules
```
set["haproxy"]["applications"] = {
  "contactsapi-prod" => {
    "endpoint" => "contactsapi.evertrue.com",
    "ssl_enabled" => true,
    "ssl_required" => true,
    "backend" => "contactsapi-prod"
  },
  "authapi-prod" => {
    "endpoint" => "auth.evertrue.com",
    "ssl_enabled" => true,
    "ssl_required" => true,
    "backend" => "authapi-prod"
  }
}
```
Unlike the frontend and backend rules, these rules do not affect a specific part of the haproxy configuration file.  Instead, they provide useful information about each application to be used in any place where the application is referenced.  The sub-properties are:

- `endpoint` - The hostname that the loadbalancer will use to identify requests for this application.  Routing is done based on the combination of where the connection came in (which frontend) and this hostname.
- `ssl_enabled` - Should people be able to connect to this app using HTTPS.
- `ssl_required` - Non-SSL requests for this app should be directed to the HTTPS URL.
- `backend` - Which backend to use to serve requests for this app.

### Backend Rules
```
set['haproxy']['backends'] = {
  "contactsapi-prod" => {
    "balance_algorithm" => "roundrobin",
    "check_req" => {
      "method" => "OPTIONS",
      "url" => "/contacts/"
    },
    "servers" => [
      "name" => "prod-et-api-contacts",
      "fqdn" => "10.0.113.143",
      "port" => "8080",
      "options" => []
    ]
  },
  "authapi-prod" => {
    "balance_algorithm" => "roundrobin",
    "check_req" => {
      "method" => "OPTIONS",
      "url" => "/"
    },
    "servers" => [
      {
        "name" => "prod-et-api-auth",
        "fqdn" => "10.0.113.87",
        "port" => "8080",
        "options" => []
      }
    ]
  }
}
```
These define the haproxy "backends" (obviously).  These are generally server clusters that can host one or many applications based on the routing defined in the "application" attributes.  Each backend consists of some options, a check method, and a server list:

- `balance_algorithm` - How to achieve the loadbalancing.  (See: http://code.google.com/p/haproxy-docs/wiki/balance)
- `check_req` - This is optional, but if undefined, servers will not be checked for availability (instead, availability will just be assumed--potentially with negative ramifications for end-users in production).  Sub-options for this include:
	- `method` - The HTTP method to use for the check (Defaults to OPTIONS, because it is a very lightweight query method requiring no content to be transferred).
	- `url` - Really a URI (e.g. /status).  Should be self-explanatory.
- `servers` - An array consisting of server definitions containing the following attributes:
	- `name` - An identifier for the individual server.  Used on the HAProxy stats page and also by the haproxy socket remote control system to identify specific servers to be enabled/disabled. (See: http://code.google.com/p/haproxy-docs/wiki/UnixSocketCommands)
	- `fqdn` - FQDN or IP that HAProxy should use to connect to the server.
	- `port` - port used to connect to the server.
	- `options` - Any additional server options to append to the server line (See: http://code.google.com/p/haproxy-docs/wiki/ServerOptions).

# Config Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['haproxy']['syslog']['host']</tt></td>
    <td>String (IP or FQDN)</td>
    <td>The Syslog host.</td>
    <td><tt>127.0.0.1</tt></td>
  </tr>
  <tr>
    <td><tt>['haproxy']['syslog']['facility']</tt></td>
    <td>String</td>
    <td>The Syslog facility.</td>
    <td><tt>local0</tt></td>
  </tr>
  <tr>
    <td><tt>['haproxy']['global']['maxconn']</tt></td>
    <td>String (well, a number in quotes, really)</td>
    <td>The GLOBAL maximum number of concurrent connections the frontend will accept to serve. Excess connections will be queued by the system in the socket's listen queue and will be served once a connection closes.  (See: http://code.google.com/p/haproxy-docs/wiki/maxconn)</td>
    <td><tt>100000 (seconds)</tt></td>
  </tr>
  <tr>
    <td><tt>['haproxy']['defaults']['timeout']</tt></td>
    <td>Hash</td>
    <td>This is actually broken into three sub-attributes: connect (See: http://code.google.com/p/haproxy-docs/wiki/timeout_connect), client (See: http://code.google.com/p/haproxy-docs/wiki/timeout_client), and server (See: http://code.google.com/p/haproxy-docs/wiki/timeout_server).</td>
    <td><tt>{ "connect" => "10000", "client" => "300000", "server" => "300000" }</tt></td>
  </tr>
  <tr>
    <td><tt>['haproxy']['defaults']['maxconn']</tt></td>
    <td>String (well, a number in quotes, really)</td>
    <td>The DEFAULT maximum number of concurrent connections the frontend will accept to serve. Excess connections will be queued by the system in the socket's listen queue and will be served once a connection closes.  (See: http://code.google.com/p/haproxy-docs/wiki/maxconn)</td>
    <td><tt>60000</tt></td>
  </tr>
  <tr>
    <td><tt>['haproxy']['stats']</tt></td>
    <td>Hash</td>
    <td>A set of parameters consisting of `uri` (see: http://code.google.com/p/haproxy-docs/wiki/stats_uri), `port` (just the port number), `admin_user` (see: http://code.google.com/p/haproxy-docs/wiki/stats_auth).  The stats password is auto-generated by  OpenSSL upon install.</td>
    <td><tt>{ 'uri' => "/stats", 'port' => '8069', 'admin_user' => 'admin' }</tt></td>
  </tr>
  <tr>
    <td><tt>['haproxy']['monitor_uri']</tt></td>
    <td>String</td>
    <td>A URI that will simply return a 200 OK whenever the haproxy server is up.  A good thing to point ELB at when deployed in EC2. (See: http://code.google.com/p/haproxy-docs/wiki/monitor_uri)</td>
    <td><tt>/status</tt></td>
  </tr>
</table>

# Additional gotchas

Be *VERY* careful editing the http error files.  They have a *mix* of LF and CRLF line terminators and it has to stay that way or some proxies and servers may experience hanging issues.

# Author

Author:: Eric Herot @ EverTrue, Inc. (<eric.herot@evertrue.com>)
