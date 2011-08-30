# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
#
require 'rgl/adjacency'
require 'rgl/dot'

module Mih
  # Miserably stolen from the ruby graph library (rgl)
  #
  def self.graph_from_dotfile(file)
    g = RGL::AdjacencyGraph.new
    pattern = /\s*([^\"]+)[\"\s]*--[\"\s]*([^\"\[\;]+)/ # ugly but works
    IO.foreach(file) do |line|
      case line
      when /^digraph/
        g = RGL::DirectedAdjacencyGraph.new
        pattern = /\s*([^\"]+)[\"\s]*->[\"\s]*([^\"\[\;]+)/
      when pattern
        g.add_edge $1,$2
      else
        nil
      end
    end
    g
  end

  # Loads a graph from a file or retuns and empty graph if the
  # file does not exists
  #
  def self.load_graph(output_file)
    if File.exists?(output_file)
      begin
        graph_from_dotfile(File.open(output_file))
      rescue
        error("Problems opening file: #{output_file}")
        raise
      end
    else
      RGL::DirectedAdjacencyGraph[]
    end
  end
end
