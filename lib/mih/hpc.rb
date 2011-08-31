# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
module Mih
  module Hpc
    TEMPLATE =<<EOF
echo "CMD" |\\
qsub \\
-N 'TITLE' \\
-q QUEUE \\
-d `pwd` \\
-e TITLE.e \\
-o TITLE.o \\
-l nodes=1:ppn=THREADS,mem=MEM \\
-V \\
-W depend:afterok:DEPS
EOF

    def self.lthis(cmd, title, queue, cores, mem, deps, random_n)
      t = TEMPLATE.gsub(/CMD/, cmd)
                  .gsub(/TITLE/, Digest::MD5.hexdigest(title + random_n))
                  .gsub(/QUEUE/, queue)
                  .gsub(/THREADS/, cores)
                  .gsub(/MEM/, mem)
                  .gsub(/DEPS/, deps.map{|e| Digest::MD5.hexdigest(e + random_n)}.join(':'))
      if t =~ /\sdepend:afterok:\s/
        t = t.split('\\')[0..8].join("\\")
      end
      t
    end

    def self.pbs
      ran_num = rand(100000000).to_s
      dg = Mih::load_graph("graph.dot")
      h_deps = Hash.new {|h, v| h[v] = []}
      script = [ "#!/bin/bash", "#" ]
      # Populate hash job -> deps
      dg.vertices.each do |v|
        h_deps[v] = dg.reverse.adjacent_vertices(v)
      end
      h_deps['root '] = [] # FIXME: I add root but rgl creates root_

      # Iterate over each jobs and its dependencies
      h_deps.each do |k, v|
        t = Mih::Target.load(k)
        next if t.name == 'root'
        # FIXME: when I create the root vertex, dgl adds an extran space
        d = v.inject([]) {|s, e| e == 'root ' ? s : s << e}
        #puts "------> -#{k}- : #{d}"
        if t.cmd
          script << "# #{t.name} <- #{d.join(' : ')}\n#"
          script << lthis(t.cmd, t.name, "analysis", t.cores, t.mem, d, ran_num)
        else
          raise "Warning: nil when trying to load loading: #{k}"
        end
      end
      puts script.join("\n")
    end
  end
end


