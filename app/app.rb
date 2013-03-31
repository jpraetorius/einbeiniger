# encoding: utf-8
# add local classes
$LOAD_PATH << './lib'

# add bundler for gem handling
require 'bundler/setup'

# all other dependencies
require 'sinatra'
require 'sinatra/flash'
require 'sinatra/reloader'
require 'mongo'
require 'json'
require 'bcrypt'
require 'erubis'

# internal classes
require 'registration'
require 'user'

set :erb, :escape_html => true
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

	def authenticated?
		if (!logged_in?)
			flash[:message] = "Bitte melde Dich an um diese Funktion zu benutzen."
			redirect '/'
		end
	end

	def logged_in?
		!session[:user].nil?
	end

	def get_count
		settings.registrations.count
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

get '/admin' do
	authenticated?
	erb :admin, :layout => :admin_layout
end

get '/settings' do
	authenticated?
	erb :settings, :layout => :admin_layout
end

get '/logout' do
	clear_csrf_tag
	session[:user] = nil
	session.clear
	flash[:message] = "Du hast Dich erfolgreich ausgeloggt"
	redirect '/'
end

get '/registrations' do
	authenticated?
	erb :registrations, :layout => :admin_layout
end

get '/user_img' do
	if session[:user].nil? || session[:user].avatar.nil?
		send_file 'public/img/default_avatar.gif', :type => :gif
	else
		content_type session[:user].avatar_type
		Base64.decode(session[:user].avatar)
	end
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
	r.registered_at = Time.now

	settings.registrations.insert(r.to_hash)

	@count = get_count

	erb :thanks, :locals => {:count => @count}
end

post '/login' do
	clear_csrf_tag
	@result = settings.users.find_one('name' => params[:username])
	if (@result.nil?)
		redirect '/'
	else
		@user = User.new(@result)
		if @user.password == params[:password]
			session[:user] = @user
			redirect '/admin'
		else
			redirect '/'
		end
	end
end

post '/settings' do
	authenticated?
	clear_csrf_tag
	if (params[:action].eql? 'application')
		# update application settings
		if (params[:register]) 
			@request_register = true
			flash[:message] = "Anmeldungen sind jetzt zugelassen"
		else
			@request_register = false
			flash[:message] = "Anmeldungen sind jetzt nicht möglich"
		end
		doc = settings.config.find_one('name' => 'registration_open')
		if (doc.nil?)
			doc = {'name' => 'registration_open', 'value' => @request_register}
			settings.config.insert(doc)
		else
			id = doc['_id']
			doc['value'] = @request_register
			settings.config.update({"_id" => id}, doc)
		end

		if (params[:delete_all].eql? 'delete_all_really') 
			settings.registrations.remove
			flash[:message] = "Alle Anmeldungen gelöscht"
		end
		redirect '/settings'
	elsif (params[:action].eql? 'user')
		@user = session[:user]	
		
		id = @user.id
		@user.name = params[:username]

		pwd = params[:password].strip
		if(!pwd.nil? && !pwd.empty?)
			pwd_confirm = params[:passwordconfirm].strip
			if (pwd.eql?(pwd_confirm))
				@user.password=pwd
			else
				flash[:error] = "Passwort nicht geändert – Angaben stimmten nicht überein" 
			end
		end

		if params[:avatar] #&& (tmpfile = params[:avatar][:tempfile]) && (name = params[:avatar][:filename])
			env.keys.each do |key|
				logger.info "value for key '#{key}' is: '#{file_hash[key]}'"
			end
			type = file_hash[:type]
			tmpfile = file_hash['tempfile']
			size = tmpfile.size
			if ((size <= 30720) && (%w(image/png image/jpg image/jpeg).contains type))
				contents = tmpfile.read
				@user.avatar = Base64.encode(contents)
				@user.avatar_type = type
			else
				flash[:error] = "Bild nicht gespeichert: zu gross oder falscher Typ" 
			end
		end

		settings.users.update({"_id" => id}, @user.to_hash)
		flash[:message] = "Accountänderungen gespeichert"
		redirect '/settings'
	else
		redirect '/'
	end
end