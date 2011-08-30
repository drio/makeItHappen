# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
module Mih
  def self.builder(o) # o = cmd options
    #cmd, mem, cores, name, list_deps = o
    c_deps = o.deps.split

    # Load current graph
    dg = Mih::load_graph("graph.dot")

    # Add new vertex
    new_vertex = Mih::Target.new({
      :cmd => o.cmd, :mem => o.mem, :cores => o.cores, :name => o.name, :deps => o.deps
    })
    dg.add_vertex new_vertex.to_s
    new_vertex.save

    # Find all the vertex the current vertex is depending on
    c_vertices = dg.vertices.map! do |v|
      name = v.gsub(/\s+$/, '')
      Mih::Target.load name
    end
    vd = c_vertices.inject([]) {|vs, v| c_deps.include?(v.name) ? vs << v : vs}
    #puts "CMD: #{o.cmd} TARGET: #{o.name} DEPS: #{o.deps} G_SIZE: #{c_vertices.size}"

    # If we couldn't find the deps in the graph, create them
    # Those should be the first targets on the makefile.
    if vd.size == 0
      c_deps.each do |d|
        n_vert = Mih::Target.new( { :name => d }).save
        dg.add_vertex n_vert.to_s
        vd << n_vert.to_s
      end
    end

    # Create all the necessary to represent the depencies
    vd.each do |v|
      dg.add_edge v, new_vertex.to_s
      #puts "#{v.to_s} -> #{new_vertex.to_s}"
    end
    #puts ""

    # Dump the new graph
    dg.write_to_graphic_file
  end
end
