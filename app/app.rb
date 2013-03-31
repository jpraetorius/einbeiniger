# add local classes
$LOAD_PATH << './lib'

# add bundler for gem handling
require 'bundler/setup'

# all other dependencies
require 'sinatra'
require 'sinatra/reloader'
require 'mongo'
require 'json'
require 'bcrypt'

# internal classes
require 'registration'
require 'user'

use Rack::Session::Pool
use Rack::Protection, {:use => [:form_token, :remote_referrer]}
use Rack::Protection::EscapedParams

include Mongo
include BCrypt

# setup
configure do
	@db = MongoClient.new("127.0.0.1", 27017).db('einbeiniger')
	set :users, @db.collection('users');
	set :registrations, @db.collection('registrations')
	set :config, @db.collection('configuration')
end

# helpers
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

	def logged_in?
		!session[:user].nil?
	end

	def h(text)
		ERB::Util.html_escape(text)
	end

	def csrf_tag
		if (session[:csrf].nil?)
			token = random_string
			session[:csrf] = token
		else
			token = session[:csrf]
		end
		"<input type='hidden' name='authenticity_token' value='#{token}' />"
	end

	def clear_csrf_tag
		session[:csrf] = nil
	end

	# copied form Rack::Protection, as it is not exposed there
	def random_string(secure = defined? SecureRandom)
		secure ? SecureRandom.hex(32) : "%032x" % rand(2**128-1)
	end
end

# route handlers
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
	clear_csrf_tag
	# we only accept calls for this, when the registration is really open
	if (!registration_open?)
		redirect "/"
	end

	r = Registration.new
	r.name = params[:name]
	r.skype = params[:skype]
	r.email = params[:mail]
	r.twitter = params[:twitter]
	r.topics = params[:topics]

	settings.registrations.insert(r.to_hash)

	@count = settings.registrations.count

	erb :thanks, :locals => {:count => @count}
end

post '/login' do
	clear_csrf_tag
	@result = settings.users.find_one('name' => params[:username])
	logger.info @result
	@user = User.new(@result)
	logger.info @user
	if @user.password == params[:password]
		session[:user] = @user
		redirect '/'
	else
		redirect '/'
	end
end