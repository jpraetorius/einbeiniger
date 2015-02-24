# encoding: utf-8
# add local classes
$LOAD_PATH << './lib'

# add bundler for gem handling
require 'bundler/setup'

# Ruby internals
require 'date'
require 'yaml'

# all other dependencies
require 'sinatra'
require 'sinatra/flash'
require 'sinatra/reloader'
require 'mongo'
require 'json'
require 'bcrypt'
require 'erubis'
require 'rack/throttle'

# internal classes
require 'registration'
require 'user'

set :erb, :escape_html => true
use Rack::Session::Pool
# allow one post request to login every three seconds
use Rack::Throttle::Interval, {:min => 3.0, :rules => {:url => [/login/], :method => [:post]}}
# enforce form tokens and referrer checking, exclude session control due to erratic behavior I've seen in testing
use Rack::Protection, {:use => [:form_token, :remote_referrer], :except => [:session_hijacking]}
# ?
use Rack::Protection::EscapedParams

include Mongo
include BCrypt

# setup
configure do
	# load auth information
	users = YAML.load_file('config/config.yaml')
	appuser = users['appuser']
	@db = MongoClient.new("127.0.0.1", 27017).db('einbeiniger')
	# Authenticate, load auth from File
	@db.authenticate(appuser['name'], appuser['pwd'])
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

		# see if we need to override it based on the next_date Value
		reg_date = settings.config.find_one('name' => 'next_date')
		if (!reg_setting.nil?)
			next_date = Date.parse(reg_date['value'])
			today = Date.today
			diff = (next_date - today).to_i
			if (!registration_open)
				# turn on automagically, when the next date is nigh
				if (diff > 0 && diff <= 3)
					registration_open = true
					doc = settings.config.find_one('name' => 'registration_open')
					id = doc['_id']
					doc['value'] = @registration_open
					settings.config.update({"_id" => id}, doc)
				end
			else
				# turn off automagically if the last date has passed
				if (diff < 0)
					registration_open = false
					doc = settings.config.find_one('name' => 'registration_open')
					id = doc['_id']
					doc['value'] = @registration_open
					settings.config.update({"_id" => id}, doc)
				end
			end
		end

		registration_open
	end

	def next_date
		reg_date = settings.config.find_one('name' => 'next_date')
		if (reg_date.nil?)
			next_date = nil
		else
			next_date = reg_date['value']
		end
		next_date
	end

	def next_date_text
		reg_date = next_date
		if (reg_date.nil?)
			next_date = 'derzeit nicht festgelegt'
		else
			d = Date.parse(reg_date)
			if ((d <=> Date.today) < 0)
				next_date = 'derzeit nicht festgelegt'
			else
				next_date = "am #{d.strftime('%d.%m.%Y')} geplant"
			end
		end
		next_date
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
	@next_date = next_date_text
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
	@next_date = next_date
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
		@request_next_date = params[:next_date]
		doc = settings.config.find_one('name' => 'next_date')
		if (doc.nil?)
			doc = {'name' => 'next_date', 'value' => @request_next_date}
			settings.config.insert(doc)
			flash[:message] = "Sendungsdatum gespeichert"
		else
			id = doc['_id']
			doc['value'] = @request_next_date
			settings.config.update({"_id" => id}, doc)
			flash[:message] = "Sendungsdatum gespeichert"
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
	id = params[:id]
	tags = params[:tags].split(',')

	registration = settings.registrations.find_one({'_id' => mongodb_id(id)});
	if !(registration.nil?)
		r = Registration.new(registration)
		r.tags = tags
		settings.registrations.update({'_id' => mongodb_id(id)}, r.to_hash);
	end

	xhr_csrf_tag
end
