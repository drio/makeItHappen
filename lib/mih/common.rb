# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
#
module Mih
  def self.error(msg)
    $stderr.puts "ERROR: #{msg}"
    exit 1
  end
end
