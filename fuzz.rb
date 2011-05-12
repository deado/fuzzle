#!/usr/bin/env ruby
require 'rexml/document'
include REXML
$useColor = true
$k = []
$k[0] = "\033[0m"
$k[1] = "\033[0;31m"
$k[2] = "\033[0;34m"

file = File.new("sms.xml")
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
	puts result
}
