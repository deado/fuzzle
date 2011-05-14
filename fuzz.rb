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
		file = File.new(xml)
		doc = Document.new(file)

		root = doc.root
		root.elements.each("sms") {|msg|
			msg.attributes.each {|n, v| 
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
			@type = "0" if @type == "6"
			result = "[#{@tstamp}] #{@contact} (#{@addy}): #{@body}"
			result = $k[@type.to_i] + result if ($useColor)
			case out
				when "screen" then puts result
				when "search" then return
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
		puts "exit - close fuzzle"
	end
	def Fuzzle.help
		puts "http://github.com/deado/fuzzle/"
		puts "-i, --file-in xml		parse and print to screen only"
		puts "-o, --file-out xml,txt		parse xml and save to txt. no output.\n"
		puts "-s, --search xml,txt,category	txt what what you are searching, categories(all,name,number,text)"
		puts "-h, --help			this help msg."
		puts "-a, --interactive		interactive mode\n"
	end
	def Fuzzle.cmd(cmd)
		case cmd
			when "help"
				Fuzzle.menu
			when "print"
				print "Path to XML: "
				Fuzzle.xml(gets.strip, "screen")
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
	def Fuzzle.search(file, what, where)
		puts "Coming soon..."
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
				Fuzzle.search("this","that","there")
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
						$stderr.print "error: #{$_}"
					end
				end
		end
	end
	Fuzzle.help if !$have_opts
end
