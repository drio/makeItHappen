# vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 tw=80
#
require 'optparse'
require 'ostruct'

class Arguments
  def initialize(arguments)
    @command     = arguments.shift
    @arguments   = arguments
    @o           = OpenStruct.new
  end

  def process
    parsed_options
    run
  end

  private

  def run
    case @command
      when "builder"; Mih::builder(@o)
      when "hpc"; Mih::Hpc.pbs
      else
        $sdterr.puts "Unsupported command"
        exit 1
    end
  end

  def parsed_options
    case @command
      when "builder"; parse_builder
      when "hpc"    ; parse_hpc
      else
        usage
    end
  end

  def parse_builder
    opts = OptionParser.new
    opts.on("-c", "--cmd c")   {|c| @o.cmd   = c }
    opts.on("-m", "--mem m")   {|m| @o.mem   = m }
    opts.on("-r", "--cores r") {|r| @o.cores = r }
    opts.on("-n", "--name n")  {|n| @o.name  = n }
    opts.on("-d", "--deps d")  {|d| @o.deps  = d }
    opts.parse!(@arguments) rescue return false
    usage unless @o.cmd && @o.mem && @o.cores && @o.name && @o.deps
    true
  end

  def parse_hpc
    if @arguments.size != 1
      usage
    else
      case @arguments.shift
        when "pbs"; @o.hpc_type = "pbs"; true
        else; usage
      end
    end
  end

  def usage
    case @command
      when "builder"
        $stderr.puts builder_help
      when "hpc"
        $stderr.puts hpc_help
      else
        $stderr.puts main_help
    end
    exit 1
  end

  def common_help
    common =<<COMMON_HELP
Program    : #{Mih::PRG_NAME}
Description: #{Mih::DESCRIPTION}
Version    : #{Mih::VERSION}

Usage      : mih <command> [options]
COMMON_HELP
  end

  def main_help
    str =<<END_MAIN_HELP
#{common_help}
Command    : builder    Generate a Graph adding the new command
             hpc        Create a script for the targeted HPC scheduler

END_MAIN_HELP
  end

  def hpc_help
    str =<<END_HPC_HELP
Usage: mih hpc <scheduler_type>

Supported schedulers: pbs     Generate code for a pbs cluster

END_HPC_HELP
  end

  def builder_help
    str =<<END_BUILDER_HELP
Usage: mih builder [options]

Options: -c, -cmd      New command to incorporate in the graph
         -m, -mem      Memory requiriments
         -r, -cores    Number of cores required
         -n, -name     Name of the job
         -d, -deps     List of dependencies for the job

END_BUILDER_HELP
  end
end
