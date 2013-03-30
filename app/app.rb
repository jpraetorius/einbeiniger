# add local classes
$LOAD_PATH << './lib'

# add bundler for gem handling
require 'bundler/setup'

# all other dependencies
require 'sinatra'
require 'sinatra/reloader'

use Rack::Session::Pool
use Rack::Protection
use Rack::Protection::AuthenticityToken
use Rack::Protection::FormToken
use Rack::Protection::RemoteReferrer
use Rack::Protection::EscapedParams

get '/' do
	@registration_open = rand(2) > 0;
	erb :index, :locals => {:registration_open => @registration_open}
end
