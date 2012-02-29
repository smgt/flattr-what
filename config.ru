require "./app.rb"
require 'rack/timeout'
use Rack::Timeout
Rack::Timeout.timeout = 120

run App
