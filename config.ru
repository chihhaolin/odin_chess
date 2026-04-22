$LOAD_PATH.unshift File.join(__dir__, 'lib')
require 'chess'
require_relative 'app/api'

run Chess::API
