require 'fileutils'
require 'haml'
require 'net/http'
require 'pp'
require 'pry'
require 'tilt/haml'
require 'tilt/sass'
require 'uri'
require 'yaml'

require_relative '../lib/logger'
require_relative 'pacache'
require_relative 'server'

module Main
  include Loggerer
  include Server
end # module Main
