require "sinatra/base"
require "neography"

class App < Sinatra::Base
  get "/" do
    puts "HELLO WORLD"
  end
end
