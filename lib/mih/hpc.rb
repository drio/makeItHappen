# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
module Mih
  module Hpc
    TEMPLATE =<<EOF
echo "CMD" |\\
msub |\\
-N 'TITLE' |\\
-q QUEUE |\\
-d `pwd` |\\
-e TITLE.e |\\
-o TITLE.o |\\
-l nodes=1:ppn=THREADS,mem=MEM |\\
-W depend=afterok:DEPS |\\
-V
EOF
    def self.lthis(cmd, title, queue, cores, mem, deps)
      TEMPLATE.gsub(/CMD/, cmd)
              .gsub(/TITLE/, title)
              .gsub(/QUEUE/, queue)
              .gsub(/THREADS/, cores)
              .gsub(/MEM/, mem)
              .gsub(/DEPS/, deps.join(':'))
    end

    def self.pbs
      dg = Mih::load_graph("graph.dot")
      h_deps = Hash.new {|h, v| h[v] = []}
      script = [ "#!/bin/bash", "#" ]
      # Populate hash job -> deps
      dg.vertices.each do |v|
        h_deps[v] = dg.reverse.adjacent_vertices(v)
      end

      # Iterate over each jobs and its dependencies
      h_deps.each do |k, v|
        t = Mih::Target.load(k)
        d = v.inject([]) {|s, e| s << e}
        if t.cmd
          script << "# #{t.name} <- #{d.join(' : ')}\n#"
          script << lthis(t.cmd, t.name, "analysis", t.cores, t.mem, d)
        end
      end
      puts script.join("\n")
    end
  end
end


