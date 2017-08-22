# test-slow-service

## Problem
When using [Inspec](https://www.inspec.io) to test the state of services or applications in your infrastructure,
some tests may yield incorrect results due to the slow service or app initialization and start up times.

This most likely will happen when the Inspec is run shortly after a Chef client converge, either via the
[audit](https://github.com/chef-cookbooks/audit) cookbook, or in the `verify` stage in [Test Kitchen](https://github.com/test-kitchen/test-kitchen).

This cookbook code demonstrates a pattern for testing a service that is slow to start.

## Solution
You may be tempted to add timeouts and loops in your Inspec tests, however, this is an anti-pattern since that makes Inspec
less deterministic and slower to execute and harder to maintain as you continue the pattern throughout your profiles or tests.

So with that in mind, all we need is something in the recipe that effectively gives the service or application some time to start up before we test with Inspec.
If the Service never actually starts, then by-golly, fail the converge! Ruby Blocks in Chef have often been misused, however this is one of few times that using
a `ruby_block` in your recipe is the perfect solution!

This specific example will be a Windows example, so we need to require the `Win32::Service` library to help facilitate accurately checking
the state of a service.

```ruby
# libraries/_z.rb
if RUBY_PLATFORM =~ /mswin|mingw32|windows/
  require "chef/win32/error"
  require "win32/service"
end
```

The recipe will have a service block that starts a service, then a `ruby_block` that blocks until the service is up or a timeout is reached.
```ruby
#
# Cookbook:: test-slow-service
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# some service that takes a while to initialize and start
# this one is just a random example
service_name = 'AppIDSvc'

service service_name do
  action :start
end

ruby_block 'Wait on Service Start' do
  block do
    state = 'unknown'
    i = 0
    until i == 5 || state == 'running'
      Chef::Log.warn("waiting for service state == running [#{state}]")
      sleep 2
      state = ::Win32::Service.status(service_name).current_state
      i += 1
    end
    fail "Service #{service_name} with status [#{state}] didn't start!" if state != 'running'
  end
end
```

Finally, the Inspec test is totally agnostic of the slow startup time and just runs a check as normal with sleeping or looping.
```ruby
# test/smoke/default/default_test.rb
# This would be the service that takes a long time to initialize and start
describe service('AppIDSvc') do
  it { should be_running }
end
```
