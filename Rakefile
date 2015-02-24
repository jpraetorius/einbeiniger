$LOAD_PATH << './lib'

require 'user'
require 'yaml'
require 'mongo'
include Mongo

def random_string(secure = defined? SecureRandom)
  secure ? SecureRandom.hex(32) : "%032x" % rand(2**128-1)
end

desc "Sets up the initial DB Structure"
task :db_setup do
  # Create DB
  db = MongoClient.new("127.0.0.1", 27017).db('einbeiniger')

  # prepeare to write Users to config
  users = Hash.new

  #create the necessary Users
  # Site admin
  siteadmin = Hash.new
  siteadmin['name'] = 'siteadmin'
  siteadmin['pwd'] = random_string
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
  adminuser = Hash.new
  adminuser['name'] = 'adminuser'
  adminuser['pwd'] = random_string
  cmd = BSON::OrderedHash.new
  cmd[:createUser] = adminuser['name']
  cmd[:pwd] = adminuser['pwd']
  cmd[:roles] = [{:role => 'einbeinigerAdmin', :db => 'einbeiniger'}]
  db.command(cmd)
  users['adminuser'] = adminuser

  # Application User
  appuser = Hash.new
  appuser['name'] = 'appuser'
  appuser['pwd'] = random_string
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