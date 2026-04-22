$LOAD_PATH.unshift File.join(__dir__, 'lib')
require 'webrick'
require 'chess'
require_relative 'app/api'

run Chess::API
