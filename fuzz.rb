#!/usr/bin/env ruby
require 'getoptlong'
require 'rexml/document'
include REXML

$have_opts = false
$endProg = false
$useColor = true
$k = []
$k[0] = "\033[0m" #nil color to end line
$k[1] = "\033[0;31m" #incoming msgs
$k[2] = "\033[0;34m" #outgoing msgs

class Fuzzle
	def Fuzzle.parse(xml, out)
		doc = Document.new(File.new(xml))
		doc.root.elements.each("sms") {|msg|
			Fuzzle.makenice(msg)
			case out
				when "screen" then puts @result
				when "group" then next
				else
					`touch #{out}`
					`/bin/echo "#{@result}" >> #{out}`
			end
		}
	end
	def Fuzzle.menu
		puts "help - this msg"
		puts "print - parse xml and output only"
		puts "save - parse xml and save to file"
		puts "search - search through xml for specific output"
		puts "group - xml to file(s) per contact name"
		puts "exit - close fuzzle"
	end
	def Fuzzle.help
		puts "http://github.com/deado/fuzzle/"
		puts "-p, --parse xml(,/path/to/save/file)	parse xml and save to file. screen if file not specified.\n"
		puts "-s, --search xml,text(,output)		text what what you are searching; output to screen or /path/to/save/file"
		puts "-g, --group xml,/save/dir/		xml to file(s) per contact name"
		puts "-h, --help				this help msg."
		puts "-a, --interactive			interactive mode\n"
	end
	def Fuzzle.cmd(cmd)
		case cmd
			when "help"
				Fuzzle.menu
			when "print"
				print "Path to XML: "
				Fuzzle.parse(gets.strip, "screen")
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
				print "Path to file: "
				txt = gets.strip
				Fuzzle.parse(xml, txt)
			when "group"
				print "Path to XML: "
				xml = gets.strip
				print "Path to save dir: "
				savedir = gets.strip
				Fuzzle.group(xml, savedir)
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
		@result = "#{$k[@type.to_i]}#{@result}#{$k[0]}" if ($useColor)
	end
	def Fuzzle.search(xml, what, out)
		if xml.empty? or what.empty?
			puts "missing search arguments"
			return 0
		end
		f = File.new(xml)
		if out == "screen" then
			f.each {|line| puts Fuzzle.makenice(line) if line.include?(what) }
		else
			if FileTest.exists?(out) then
				print "#{out}: exists... APPEND or overwrite? "
				`rm -rf #{out}` if gets.strip.downcase == "overwrite"
				`touch #{out}`
				f.each {|line| `/bin/echo "#{Fuzzle.makenice(line)}" >> #{out}` if line.include?(what)}
			end
		end
	end
	def Fuzzle.group(xml, savedir)
		#return if xml.empty? or savedir.empty?
		fr, nr = [], []
		doc = Document.new(File.new(xml))
		doc.root.elements.each("sms") {|msg|
			Fuzzle.makenice(msg)
			if !nr.include?(@contact) then
				nr.push(@contact)
				fr.push(savedir + @contact)
			end
			i = nr.index(@contact)
			`touch "#{fr[i]}"`
			`/bin/echo "#{@result}" >> "#{fr[i]}"`
		}
	end
end

opts = GetoptLong.new(
	[ "--parse",		"-p",	GetoptLong::REQUIRED_ARGUMENT ],
	[ "--group",		"-g",	GetoptLong::REQUIRED_ARGUMENT ],
	[ "--search",		"-s",	GetoptLong::REQUIRED_ARGUMENT ],
	[ "--help",		"-h",	GetoptLong::NO_ARGUMENT ],
	[ "--interactive",	"-a",	GetoptLong::NO_ARGUMENT ]
)

begin
	opts.each do |opt, arg|
		case opt
			when "--parse"
				$have_opts = true
				files = []
				files = arg.split(",")
				if files.nitems == 2 then
					Fuzzle.parse(files[0],files[1])
				else
					Fuzzle.parse(arg, "screen")
				end
			when "--group"
				$have_opts = true
				group = []
				group = arg.split(",")
				Fuzzle.group(group[0],group[1])
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
