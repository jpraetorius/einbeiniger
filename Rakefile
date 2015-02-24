# Don't echo sh commands
verbose(false) unless ENV['VERBOSE'].eql?('true')

# Build Variables
DIST_DIR = "./dist"
PUBLIC_DIR = "#{DIST_DIR}/public"
DIST_VIEWS_DIR = "#{DIST_DIR}/views"
DIST_LIB_DIR = "#{DIST_DIR}/lib"
DIST_CONFIG_DIR = "#{DIST_DIR}/config"
DIST_CSS_DIR = "#{PUBLIC_DIR}/css"
DIST_IMG_DIR = "#{PUBLIC_DIR}/img"
DIST_JS_DIR = "#{PUBLIC_DIR}/js"
DIST_FONT_DIR = "#{PUBLIC_DIR}/font"

JS_SRC_DIR = "./js"
LESS_SRC_DIR = "./less"
IMG_SRC_DIR = "./img"
FONT_SRC_DIR = "./font"
APP_SRC_DIR = "./app"
CONFIG_SRC_DIR = "./config"

CHECK="\033[32m✔\033[39m"
HR="##################################################"


def random_string(secure = defined? SecureRandom)
  secure ? SecureRandom.hex(32) : "%032x" % rand(2**128-1)
end

namespace :einbeiniger do

  namespace :build do

    task :default => 'einbeiniger:build:build_all'
    task :build_all => [:build_js, :build_less, :build_img, :build_font, :build_app, :build_config]

    desc "remove all artifacts of the last build"
    task :clean do
      rm_r DIST_DIR
    end

    desc "concatenate and minify all Javascript Files"
    task :build_js do
      puts "#{HR}"
      print "Building Javascript..."
      mkdir_p DIST_JS_DIR
      jsfiles = FileList[JS_SRC_DIR+'/*.js']
      #@cat $(JS_SRC_DIR)/jquery-1.9.1.js $(JS_SRC_DIR)/bootstrap-dropdown.js $(JS_SRC_DIR)/bootstrap-tooltip.js $(JS_SRC_DIR)/bootstrap-popover.js $(JS_SRC_DIR)/bootstrap-modal.js $(JS_SRC_DIR)/jquery.tagsinput.min.js $(JS_SRC_DIR)/bootstrapSwitch.js $(JS_SRC_DIR)/application.js > $(DIST_JS_DIR)/app.js
      sh("uglifyjs #{jsfiles} -c warnings=false > #{DIST_JS_DIR}/app.min.js")
      print "\t #{CHECK}\n"
    end

    desc "Compile the LESS Files into CSS"
    task :build_less do
      print "Building CSS..."
      mkdir_p DIST_CSS_DIR
      sh("recess --compress #{LESS_SRC_DIR}/bootstrap.less > #{DIST_CSS_DIR}/app.css")
      print "\t\t #{CHECK}\n"
    end

    desc "copy and compress all images"
    task :build_img do
      print "Building Images..."
      mkdir_p DIST_IMG_DIR
      FileList["#{IMG_SRC_DIR}/*"].each do |file|
        sh("imagemin #{file} #{DIST_IMG_DIR}")
      end
      print "\t #{CHECK}\n"
    end

    desc "copy all Font Files"
    task :build_font do
      print "Building Fonts..."
      mkdir_p DIST_FONT_DIR
      fontfiles = FileList[FONT_SRC_DIR+'/**/*']
      cp fontfiles, DIST_FONT_DIR
      print "\t #{CHECK}\n"
    end

    desc "Copy all application Files"
    task :build_app do
      print "Building App..."
      mkdir_p DIST_VIEWS_DIR
      mkdir_p DIST_LIB_DIR
      viewfiles = FileList[APP_SRC_DIR+'/views/*.erb']
      libfiles = FileList[APP_SRC_DIR+'/lib/*.rb']
      appfiles = FileList[APP_SRC_DIR+'/*.rb']
      cp viewfiles, DIST_VIEWS_DIR
      cp libfiles, DIST_LIB_DIR
      cp appfiles, DIST_DIR
      print "\t\t #{CHECK}\n"
    end

    desc "Prepare the application configuration"
    task :build_config do
      print "Building Config..."
      mkdir_p DIST_CONFIG_DIR
      cp(CONFIG_SRC_DIR+'/config.yaml', DIST_CONFIG_DIR) unless ENV['DEVENV'].nil?
      cp('Rakefile', DIST_DIR)
      print "\t #{CHECK}\n"
    end
  end


  namespace :db do
    # Load einbeiniger classes
    $LOAD_PATH << './lib'
    $LOAD_PATH << './app/lib'
    require 'user'
    require 'yaml'
    require 'mongo'
    include Mongo

    desc "Sets up the initial DB Structure"
    task :db_setup do
      # Create DB
      db = MongoClient.new("127.0.0.1", 27017).db('einbeiniger')

      # Read existing User config, if it exists
      if File.exists?('config/config.yaml')
        users = YAML.load_file('config/config.yaml')
      else
        users = Hash.new
      end

      # create the necessary Users, recognize existing settings
      # Site admin
      siteadmin = users['siteadmin'] || Hash.new
      siteadmin['name'] = 'siteadmin'
      siteadmin['pwd'] = siteadmin['pwd'] || random_string
      # as add_user is seriously b0rken (no access to any roles or dbs possible)  , let's do this manually
      cmd = BSON::OrderedHash.new
      cmd[:createUser] = siteadmin['name']
      cmd[:pwd] = siteadmin['pwd']
      cmd[:roles] = [{:role => 'userAdminAnyDatabase', :db => 'admin'}, {:role => 'dbOwner', :db => 'einbeiniger'}]
      db.command(cmd)
      users['siteadmin'] = siteadmin

      # Reonnect as Site-Admin for the other operations
      db.logout
      db = MongoClient.new("127.0.0.1", 27017).db('einbeiniger')
      db.authenticate(siteadmin['name'], siteadmin['pwd'])

      # Create Collections
      db.create_collection('users');
      db.create_collection('registrations')
      db.create_collection('configuration')

      # Roles
      cmd = BSON::OrderedHash.new
      cmd[:createRole] = "einbeinigerApplication"
      cmd[:privileges] = [
        { :resource => { :db => 'einbeiniger', :collection => 'configuration' }, :actions => [ 'find', 'update' ] },
        { :resource => { :db => 'einbeiniger', :collection => 'users' }, :actions => [ 'find', 'update' ] },
        { :resource => { :db => 'einbeiniger', :collection => 'registrations' }, :actions => [ 'find', 'insert', 'update', 'remove' ] }
      ]
      cmd[:roles] = []
      db.command(cmd)

      cmd = BSON::OrderedHash.new
      cmd[:createRole] = "einbeinigerAdmin"
      cmd[:privileges] = [
        { :resource => { :db => 'einbeiniger', :collection => 'configuration' }, :actions => [ 'find', 'insert', 'update', 'remove' ] },
        { :resource => { :db => 'einbeiniger', :collection => 'users' }, :actions => [ 'find', 'insert', 'update', 'remove' ] },
        { :resource => { :db => 'einbeiniger', :collection => 'registrations' }, :actions => [ 'find', 'insert', 'update', 'remove' ] }
      ]
      cmd[:roles] = []
      db.command(cmd)

      # Application Administrator
      adminuser = users['adminuser'] || Hash.new
      adminuser['name'] = 'adminuser'
      adminuser['pwd'] = adminuser['pwd'] || random_string
      cmd = BSON::OrderedHash.new
      cmd[:createUser] = adminuser['name']
      cmd[:pwd] = adminuser['pwd']
      cmd[:roles] = [{:role => 'einbeinigerAdmin', :db => 'einbeiniger'}]
      db.command(cmd)
      users['adminuser'] = adminuser

      # Application User
      appuser = users['appuser'] || Hash.new
      appuser['name'] = 'appuser'
      appuser['pwd'] = appuser['pwd'] || random_string
      cmd = BSON::OrderedHash.new
      cmd[:createUser] = appuser['name']
      cmd[:pwd] = appuser['pwd']
      cmd[:roles] = [{:role => 'einbeinigerApplication', :db => 'einbeiniger'}]
      db.command(cmd)
      users['appuser'] = appuser

      # write down created users
      File.open('config/config.yaml', 'w') do |file|
        file.write(YAML.dump(users))
      end
      # and secure them
      File.chmod(0400, 'config/config.yaml')

      # Reconnect as Application-Admin for the other operations
      db.logout
      db = MongoClient.new("127.0.0.1", 27017).db('einbeiniger')
      db.authenticate(adminuser['name'], adminuser['pwd'])
      # Preset Settings
      doc = {'name' => 'next_date', 'value' => '01.01.2000'}
      db.collection('configuration').insert(doc)
      doc = {'name' => 'registration_open', 'value' => false}
      db.collection('configuration').insert(doc)
    end

    desc "Creates a new User"
    task :create_user do
      u = User.new({})
      STDOUT.puts('Please enter the Name for the new User: ');
      name = STDIN.gets.chomp!
      STDOUT.puts('Please enter the Password for the new User: ');
      password = STDIN.gets.chomp
      u.name = name
      u.password = password

      users = YAML.load_file('config/config.yaml')
      adminuser = users['adminuser']
      db = MongoClient.new.db('einbeiniger')
      db.authenticate(adminuser['name'], adminuser['pwd'])
      users = db.collection('users')
      users.insert(u.to_hash)
    end
  end #namespace :db
end #namespace einbeiniger