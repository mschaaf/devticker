#! /usr/bin/ruby
=begin
    This file is part of devticker.rb.

    gitticker is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    devticker is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with devticker.rb.  If not, see <http://www.gnu.org/licenses/>.
=end


require 'getoptlong'

PROG_VERSION = "0.0.1"

class DevTicker
public
  attr_accessor :interval

private
  @pipes

public
  def initialize(pipes)
    @pipes = pipes
    @interval = 5
  end

  def mainloop()
    while (true)
      puts( @pipes)
      sleep( @interval)
    end
  end

  def destruct()
    @pipes.clear()
  end
end

begin
  # set the name of the process
  $0 = "devticker.rb"

  # raise an exception on SIGINT and SIGTERM to exit cleanly
  trap( "SIGINT", proc { raise "SIGINT"})
  trap( "SIGTERM", proc { raise "SIGTERM"})
  # raise an exception on SIGHUP to reload the configuration
  trap( "SIGHUP", proc { raise "SIGHUP"})

  # all possible arguments
  options      = [ ["--foreground", "-f", GetoptLong::NO_ARGUMENT],
                   ["--help", "-h", GetoptLong::NO_ARGUMENT],
	           ["--version", GetoptLong::NO_ARGUMENT],
                   ["--pipe", "-p", GetoptLong::REQUIRED_ARGUMENT ] ]
  foreground   = false
  pipes = Array.new

  options_list = GetoptLong.new( *options)
  options_list.each { |opt, arg|
    case opt
    when "--pipe"
      pipes.push( arg); 
    when "--foreground"
      foreground = true
    when "--help"
      puts "usage: #{$0} [OPTION]\n"
      puts "       --version\tversion information and exit"
      puts "  -h,  --help\t\tthis help screen and exit"
      puts "  -f,  --foreground\trun in foreground"
      puts "  -p,  --pipe\t\tpipe to execute"
      exit
    when "--version"
      puts "#{$0} #{PROG_VERSION}"
      exit
    end
  }

  daemon = DevTicker.new( pipes)

  if foreground
    daemon.mainloop()
  else
    if nil == fork
      Process.setsid
      [$stdin, $stdout, $stderr].each { |stream|
	stream.reopen "/dev/null"
      }

      daemon.mainloop()
    end
  end

  # catch all exceptions
rescue
  case $!.message
  when "SIGINT" || "SIGTERM"
  when "SIGHUP"
    daemon.load_config( config_file)
    retry
  else
    $stderr.puts "#{$0}: #{$!.class} - #{$!}\n"
    $stderr.puts $@
  end
ensure
  daemon.destruct() unless daemon.nil?
end

