require 'bcrypt'

class User

	attr_accessor :id
	attr_accessor :password_hash
	attr_accessor :name
	attr_accessor :avatar
	attr_accessor :avatar_type

	include BCrypt

	def initialize(mongo_hash_data)
		self.id = mongo_hash_data['_id']
		self.password_hash = mongo_hash_data['password_hash']
		self.name = mongo_hash_data['name']
		self.avatar = mongo_hash_data['avatar']
		self.avatar_type = mongo_hash_data['avatar_type']
	end

	def password
		@password ||= Password.new(password_hash)
	end

	def password=(new_password)
		@password = Password.create(new_password)
		self.password_hash = @password
	end

	# Used for saving to mongodb
	def to_hash
		{
			:name => @name, 
			:password_hash => @password_hash,
			:avatar => @avatar,
			:avatar_type => @avatar_type
		}
	end
end