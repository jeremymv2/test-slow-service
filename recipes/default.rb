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
