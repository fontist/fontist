#!/usr/bin/env ruby

require "net/http"

uri = URI('https://github.com/fontist/source-fonts/releases/download/v1.0/source-fonts-1.0.zip')

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.set_debug_output($stdout)

# http.ca_file = "/etc/ssl/cert.pem"
http.ca_file = "/etc/ssl/cert-nonexistent.pem"

http.start do |h|
  request = Net::HTTP::Head.new(uri)
  response = h.request(request)

  puts "RESPONSE:"
  puts response
end
