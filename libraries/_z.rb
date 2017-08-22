if RUBY_PLATFORM =~ /mswin|mingw32|windows/
  require "chef/win32/error"
  require "win32/service"
end
