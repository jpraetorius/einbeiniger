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
	set :search_name, nil
	set :search_tags, nil
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

	def find_registrations(current_page)
		skip = (current_page-1) * 10

		@search_name = settings.search_name
		tags = settings.search_tags
		@search_tags = tags.nil? ? tags : tags.join(',')
		query = Hash.new()
		if(!@search_name.nil? && !@search_name.empty?)
			query[:name]= Regexp.compile(@search_name)
		end
		if(!tags.nil? && tags.size > 0)
			query[:tags]= {'$in' => tags}
		end

		# set count and pages according to result
		if (query.empty?)
			@count = get_count
		else
			@count = settings.registrations.count({:query => query})
		end
		@max_pages = @count / 10
		if (@count % 10 > 0)
			@max_pages = @max_pages + 1
		end

		@results = settings.registrations.find(query).sort(:registered_at).skip(skip).limit(10)
		@registrations = Array.new
		@results.each do |result|
			@registrations << Registration.new(result)
		end
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

	def xhr_csrf_tag
		if (session[:xhr_csrf].nil?)
			token = random_string
			session[:xhr_csrf] = token
		else
			token = session[:xhr_csrf]
		end
		token
	end

	def clear_xhr_csrf_tag
		session[:xhr_csrf] = nil
	end

	def check_xhr_csrf_tag
		token = session[:xhr_csrf]
		val = params[:xhr_csrf]
		if !(token.eql?(val))
			clear_xhr_csrf_tag
			halt 401, 'go away!'
		end
	end

	# copied from Rack::Protection, as it is not exposed there
	def random_string(secure = defined? SecureRandom)
		secure ? SecureRandom.hex(32) : "%032x" % rand(2**128-1)
	end

	def mongodb_id val
		BSON::ObjectId.from_string(val)
	end

	def tags_to_array vals
		# split on comma or whitespace, replace comma followed by whitespace first
		# to avoid empty elements
		tags = vals.sub(/,\s+/,',')
		arr = tags.split(/\s|,/)
		arr
	end
end

# route handlers
get '/' do
	@registration_open = registration_open?
	erb :index
end

get '/register' do
	# we only accept calls for this, when the registration is really open
	if (!registration_open?)
		redirect "/"
	end

	erb :register
end

get '/thanks' do
	@count = get_count
	erb :thanks
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

get '/registrations/:page' do
	authenticated?
	@current_page = params[:page].to_i
	find_registrations(@current_page)
	erb :registrations, :layout => :admin_layout
end

get '/registrations' do
	authenticated?
	@current_page = 1
	find_registrations(@current_page)
	erb :registrations, :layout => :admin_layout
end

get '/user_img' do
	if session[:user].nil? || session[:user].avatar.nil?
		send_file 'public/img/default_avatar.png', :type => :png
	else
		content_type session[:user].avatar_type
		Base64.decode64(session[:user].avatar)
	end
end

post '/register' do
	clear_csrf_tag
	# we only accept calls for this, when the registration is really open
	if (!registration_open?)
		redirect "/"
	end

	r = Registration.new({})
	r.name = params[:name]
	r.skype = params[:skype]
	r.email = params[:mail]
	r.twitter = params[:twitter]
	r.topics = params[:topics]
	r.registered_at = Time.now

	settings.registrations.insert(r.to_hash)

	redirect '/thanks'
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
			# env.keys.each do |key|
			# 	logger.info "value for key '#{key}' is: '#{env[key]}'"
			# end
			type = params[:avatar][:type]
			tmpfile = params[:avatar]['tempfile']
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

post '/registrations' do
	authenticated?
	clear_csrf_tag
	if (params[:action].eql? 'delete')
		ids = params[:delete_ids].split(',')
		ids.each do |id|
			logger.info "About to remove id #{id}''"
			settings.registrations.remove({"_id" => mongodb_id(id)})
		end
		flash[:message] = "Anmeldungen gelöscht"
		redirect '/registrations'
	elsif (params[:action].eql? 'search')
		@name = params[:name].strip
		@tags = tags_to_array params[:tags]
		settings.search_name=@name
		settings.search_tags=@tags
		redirect '/registrations'
	elsif (params[:action].eql? 'clear')
		settings.search_name=nil
		settings.search_tags=nil
		redirect '/registrations'
	end
	redirect '/registrations'
end
			
post '/tags' do
	authenticated?
	check_xhr_csrf_tag
	puts params[:id]
	puts params[:tags]
	xhr_csrf_tag
end
