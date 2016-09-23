#!/usr/bin/ruby

# getFlickrGeoTags.rb
# Script to read geotags from all photos in the given Flickr account, and
# output them to stdout
#
# Created by Jayanth Chennamangalam


require "getoptlong"
require "flickraw"


def printUsage(progName)
  puts <<-EOF
Usage: #{progName} [options]
    -h  --help                           Display this usage information
    -k  --api-key                        API key
    -s  --shared-secret                  Shared secret
    -t  --auth-token                     Authentication token
    -e  --auth-secret                    Authentication secret
  EOF
end


opts = GetoptLong.new(
  [ "--help",           "-h", GetoptLong::NO_ARGUMENT ],
  [ "--api-key",        "-k", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--shared-secret",  "-s", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--auth-token",     "-t", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--auth-secret",    "-e", GetoptLong::REQUIRED_ARGUMENT ]
)


FlickRaw.api_key = nil
FlickRaw.shared_secret = nil

begin
opts.each do |opt, arg|
  case opt
    when "--help"
      printUsage($PROGRAM_NAME)
      exit(0)
    when "--api-key"
      # set the API key
      FlickRaw.api_key = arg
    when "--shared-secret"
      # set the shared secret
      FlickRaw.shared_secret = arg
    when "--auth-token"
      # set the authentication token
      flickr.access_token = arg
    when "--auth-secret"
      # set the authentication secret
      flickr.access_secret = arg
  end
end
rescue StandardError
  printUsage($PROGRAM_NAME)
  exit
end

# check if necessary options have been given
if nil == FlickRaw.api_key
    puts "ERROR: API key not given."
    exit
end
if nil == FlickRaw.shared_secret
    puts "ERROR: Shared secret not given."
    exit
end

# if authentication credentials have not been given, make request for them
if nil == flickr.access_token or nil == flickr.access_secret
  token = flickr.get_request_token
  authURL = flickr.get_authorize_url(token["oauth_token"], :perms => "read")
  print "Open this URL to complete the authentication process: #{authURL}\n"
  print "Enter authorization code: "
  verify = gets.strip

  begin
    flickr.get_access_token(token["oauth_token"],
                            token["oauth_token_secret"],
                            verify)
    login = flickr.test.login
    print "You are now authenticated as #{login.username}.\n"
    print "Token: #{flickr.access_token}\n"
    print "Secret: #{flickr.access_secret}\n"
  rescue FlickRaw::FailedResponse => e
    print "Authentication failed: #{e.msg}\n"
  end
end

# page numbering starts at 1
photos = flickr.photos.getWithGeoData(:"per_page" => 500, :"page" => 1)
for pageNum in 1..photos.pages
  photos.each { |photo|
    loc = flickr.photos.geo.getLocation(:"photo_id" => photo.id)
    latitude = loc["location"]["latitude"]
    longitude = loc["location"]["longitude"]
    print latitude, ", ", longitude, "\n"                                         
  }
  photos = flickr.photos.getWithGeoData(:"per_page" => 500,
                                        :"page" => pageNum + 1)
end

