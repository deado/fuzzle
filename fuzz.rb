#!/usr/bin/env ruby
require 'getoptlong'
require 'rexml/document'
include REXML

$have_opts = false
$endProg = false
$useColor = true
$k = []
$k[0] = "\033[0m"
$k[1] = "\033[0;31m"
$k[2] = "\033[0;34m"

class Fuzzle
	def Fuzzle.xml(xml, out)
		doc = Document.new(File.new(xml))
		doc.root.elements.each("sms") {|msg|
			Fuzzle.makenice(msg)
			case out
				when "screen" then puts @result
				else
					`touch #{out}`
					`/bin/echo "#{result}" >> #{out}`
			end
		}
	end
	def Fuzzle.menu
		puts "help - this msg"
		puts "print - parse xml and output only"
		puts "save - parse xml and save to txt"
		puts "search - search through xml for specific output"
		puts "exit - close fuzzle"
	end
	def Fuzzle.help
		puts "http://github.com/deado/fuzzle/"
		puts "-i, --file-in xml			parse and print to screen only"
		puts "-o, --file-out xml,txt	 		parse xml and save to txt. no output.\n"
		puts "-s, --search xml,text(,output)		text what what you are searching; output to screen or /path/to/save/file"
		puts "-h, --help				this help msg."
		puts "-a, --interactive			interactive mode\n"
	end
	def Fuzzle.cmd(cmd)
		case cmd
			when "help"
				Fuzzle.menu
			when "print"
				print "Path to XML: "
				Fuzzle.xml(gets.strip, "screen")
			when "search"
				print "Path to XML: "
				xml = gets.strip
				print "What are we looking for? "
				what = gets.strip
				print "Path to save file ([Enter] for screen)"
				out = gets.strip
				if xml.empty? or what.empty?
					puts "error: missing one or more arguments"
					return
				end
				Fuzzle.search(xml, what,(!out.empty?) ? out : "screen")
			when "save"
				print "Path to XML: "
				xml = gets.strip
				print "Path to TXT: "
				txt = gets.strip
				Fuzzle.saveto(xml, txt)
			when "exit"
				$endProg = true
		end
	end
	def Fuzzle.makenice(msg)
		doc = Document.new "#{msg}"
		doc.root.attributes.each {|n, v|
			case n
				when "address" then @addy = v #phone number
				when "contact_name" then @contact = v #as listed in contact list
				when "body" then @body = v #actual msg
				when "type" then @type = v #recieve = 1; send = 2
				when "readable_date" then @tstamp = v #time stamp
				# other attributes in the sms element with possible values: 
				# sc_toa=n/a, protocol=0(sms), read=1,0, date=javatimestamp,
				# subject=nil, toa=n/a, service_center, status=-1,0,32,64(none,complete,pending,failed), locked
			end
		}
		@type = "2" if @type == "6" #only saw type '6' one time, was a sent msg.... tested used a 3rd color for awhile.
		@result = "[#{@tstamp}] #{@contact} (#{@addy}): #{@body}"
		@result = $k[@type.to_i] + @result if ($useColor)
	end
	def Fuzzle.search(xml, what, out)
		if xml.empty? or what.empty?
			puts "missing search arguments"
			return
		end
		f = File.new(xml)
		f.each {|line| puts Fuzzle.makenice(line) if line.include?(what) }
	end
end

opts = GetoptLong.new(
	[ "--file-in",		"-i",	GetoptLong::REQUIRED_ARGUMENT ],
	[ "--file-out",		"-o",	GetoptLong::REQUIRED_ARGUMENT ],
	[ "--search",		"-s",	GetoptLong::REQUIRED_ARGUMENT ],
	[ "--help",		"-h",	GetoptLong::NO_ARGUMENT ],
	[ "--interactive",	"-a",	GetoptLong::NO_ARGUMENT ]
)

begin
	opts.each do |opt, arg|
		case opt
			when "--file-in"
				$have_opts = true
				Fuzzle.xml(arg, "screen")
			when "--file-out"
				$have_opts = true
				files = []
				files = arg.split(",")
				Fuzzle.xml(files[0],files[1])
			when "--search"
				$have_opts = true
				search = []
				search = arg.split(",")
				Fuzzle.search(search[0], search[1], (search[2]) ? search[2] : "screen")
			when "--help"
				$have_opts = true
				Fuzzle.help
			when "--interactive"
				$have_opts = true
				while !($endProg)
					begin
						print "$ "
						Fuzzle.cmd(gets.strip.downcase)
					rescue
						$stderr.print "error: #{$_}\n"
					end
				end
		end
	end
	Fuzzle.help if !$have_opts
rescue
	$stderr.print "Fuzzle IO failed: " + $! + "\n"
end
