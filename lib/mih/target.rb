# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
#
require 'digest/md5'

module Mih
  class Target
    attr_reader :cmd, :mem, :cores, :name, :deps
    def initialize(ps) # ps : params
      @cmd   = ps[:cmd] || nil
      @mem   = ps[:mem] || nil
      @cores = ps[:cores] || nil
      @name  = ps[:name]
      @deps  = ps[:deps] ? ps[:deps].split : nil
    end

    def self.load(n)
      ns = n.gsub(/\s+$/, '')
      #puts "loading: -#{n}- -- #{Digest::MD5.hexdigest(n) + ".dump"} "
      File.open(Digest::MD5.hexdigest(ns) + ".dump", "r") {|f| Marshal.load(f) }
    end

    def to_s
      @name
    end

    def save
      File.open(Digest::MD5.hexdigest(@name) + ".dump", "w") {|f| f.puts Marshal.dump(self)}
      self
    end
  end
end
