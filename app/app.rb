# add local classes
$LOAD_PATH << './lib'

# add bundler for gem handling
require 'bundler/setup'

# all other dependencies
require 'sinatra'
require 'sinatra/reloader'
require 'mongo'
#require 'rack/csrf'

use Rack::Session::Pool
use Rack::Protection, {:use => [:form_token, :remote_referrer]}
use Rack::Protection::EscapedParams

# setup
configure do
	include Mongo
	@db = MongoClient.new("127.0.0.1", 27017).db('einbeiniger')
	set :users, @db.collection('users');
	set :registrations, @db.collection('registrations')
	set :config, @db.collection('configuration')
end

helpers do
	def registration_open?
		reg_setting = settings.config.find_one('name' => 'registration_open')
		if (reg_setting.nil?)
			registration_open = false
		else
			registration_open = reg_setting['value']
		end
		registration_open
	end

	def csrf_tag
		token = random_string
		session[:csrf] = token
		"<input type='hidden' name='authenticity_token' value='#{token}' />"
	end

	def random_string(secure = defined? SecureRandom)
		secure ? SecureRandom.hex(32) : "%032x" % rand(2**128-1)
	end
end

get '/' do
	@registration_open = registration_open?
	erb :index, :locals => {:registration_open => @registration_open}
end

get '/register' do
	# we only accept calls for this, when the registration is really open
	if (!registration_open?)
		redirect "/"
	end

	erb :register
end

post '/register' do
	# we only accept calls for this, when the registration is really open
	if (!registration_open?)
		redirect "/"
	end

	erb :register
end