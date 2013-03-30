$LOAD_PATH << './lib'

require 'sinatra'

get '/' do
	erb :index
end
