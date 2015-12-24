require 'fileutils'
require 'haml'
require 'net/http'
require 'pp'
require 'pry'
require 'tilt/haml'
require 'tilt/sass'
require 'uri'
require 'yaml'

require_relative 'logger'
require_relative 'pacache'
require_relative 'server'
require_relative 'consolidator'

module Main
  include Logger
  include Server
  include Consolidator
end # module Main
