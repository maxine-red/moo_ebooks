require 'moo_ebooks'
require_relative 'memprof'

def path(relpath)
  File.join(File.dirname(__FILE__), relpath)
end
