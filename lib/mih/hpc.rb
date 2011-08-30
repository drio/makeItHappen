# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
module Mih
  module Hpc
    def self.pbs
      dg = Mih::load_graph("graph.dot")
      h_deps = Hash.new {|h, v| h[v] = []}
      dg.vertices.each do |v|
        h_deps[v] = dg.reverse.adjacent_vertices(v)
        #dg.reverse.adjacent_vertices(v).size == 0 ? s << v : s
      end

      h_deps.each do |k, v|
        t = Mih::Target.load(k)
        puts t.name
        puts "CMD: #{t.cmd}"
        v.each {|e| printf "+ \t%s\n", e}
        puts ""
      end
    end
  end
end
