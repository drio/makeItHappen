# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
#
bin_dir  = File.dirname($0)
main_dir = File.dirname(bin_dir)
lib_dir  = File.join(main_dir, "lib")

# Load all mih libs
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)
Dir[File.join(lib_dir + "/mih/", "*.rb")].each {|file| require file }
