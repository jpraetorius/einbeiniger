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

# setup
configure do
	@db = MongoClient.new("127.0.0.1", 27017).db('einbeiniger')
	@users = @db.collection('users');
	@registrations = @db.collection('registrations')
	@config = @db.collection('configuration')
end


get '/' do
	@registration_open = @config.find_one('name' => 'registration_open')
	erb :index, :locals => {:registration_open => @registration_open}
end
