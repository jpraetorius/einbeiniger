$LOAD_PATH << 'app/lib'

require 'user'
require 'mongo'
include Mongo


desc "Sets up the initial DB Structure"
task :db_setup do
  # Create DB
  db = MongoClient.new("127.0.0.1", 27017).db('einbeiniger')

  # Create Collections
  db.collection('users');
  db.collection('registrations')
  db.collection('configuration')

  # Preset Settings
  doc = {'name' => 'next_date', 'value' => '01.01.2000'}
  settings.config.insert(doc)
  doc = {'name' => 'registration_open', 'value' => false}
  settings.config.insert(doc)
end

desc "Creates a new User"
task :create_user do
  u = User.new({})
  STDOUT.puts('Please enter the Name for the new User: ');
  name = STDIN.gets
  STDOUT.puts('Please enter the Password for the new User: ');
  password = STDIN.gets
  u.name = name
  u.password = password
  db = MongoClient.new.db('einbeiniger')
  users = db.collection('users')
  users.insert(u.to_hash)
end