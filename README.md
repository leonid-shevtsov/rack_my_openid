# rack_my_openid - a one-user OpenID provider solution for rack

So you have a Rack/Sinatra/Rails-powered blog and you want to make it an OpenID?

Now you can do it in under 5 minutes.

## Operation details

Rack_my_openid is a simple, single-user OpenID provider inspired by (now deprecated) [phpMyId](http://siege.org/phpmyid.php). It uses 

* [ruby-openid](https://github.com/openid/ruby-openid) for the protocol implementation;
* simple Yaml files for storing configuration;
* in-memory storage for authentication data;
* HTTP Digest authentication for security;
* Sinatra and Rack as the server backend.

It's designed to be drop-in compatible with any Rails application, since implementing OpenID is a confusing exercise even with ruby-openid. I extracted it from my own site/blog and am continuing to use it there.

It's fully covered by RSpec tests.

See the [OpenID specs](http://openid.net/specs/openid-authentication-2_0.html) if you really want to understand how the whole thing works.

## Installation - Rails 3

* Add the `rack_my_openid` gem to your Gemfile
* Add this to your routes:

        match '/openid' => RackMyOpenid::Provider.new(YAML.load_file('config/rack_my_openid.yml'))

    The `/openid` path can't be changed, as of this release.

* Create a `config/rack_my_openid.yml` file (see below)
* Restart your Rails app and you're good to go.
* If you make any changes to the config you'll have to restart the app to pick them up.

## Installation - Standalone

This assumes that the OpenID is the root path.

* Install the `rack_my_openid` gem.
* Create a `config.ru` in your desired path with these contents:

        require 'rack_my_openid'
        run RackMyOpenid::Provider.new(YAML.load_file('rack_my_openid.yml'))

* Create a `rack_my_openid.yml` file (see below) in the same path
* Create empty `/public` and `/tmp` directories in the same path
* Deploy with [Passenger](http://www.modrails.com/documentation/Users%20guide%20Nginx.html#deploying_a_rack_app), [Rackup](https://github.com/rack/rack/wiki/(tutorial)-rackup-howto) or whatever Rack handler you fancy. 

## `rack_my_openid.yml`

This is a simple flat Yaml file. The keys are symbols (as of this release).

* `:credentials` - run `md5 -s 'yourusername:rack_my_openid:yourpassword'` (or replace rack_my_openid with your realm name if you changed it);
* `:openid` - the actual OpenID identifier that you want to provide;
* `:realm` - the realm for HTTP Digest auth. The default is `"rack_my_openid"`, why would you change it?
* `:endpoint_url` - the URL of the OpenID endpoint (the one that's '/openid'). You shouldn't explicitly declare it

## TODO

* Support stores other than memory store
* Support SReg data provision

~ ~ ~

(c) Leonid Shevtsov http://leonid.shevtsov.me
