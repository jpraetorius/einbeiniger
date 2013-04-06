require 'json'

class Registration

	attr_accessor :id
	attr_accessor :name
	attr_accessor :email
	attr_accessor :skype
	attr_accessor :twitter
	attr_accessor :topics
	attr_accessor :registered_at
	attr_accessor :tags

	def initialize(mongo_hash_data)
		self.id = mongo_hash_data['_id']
		self.name = mongo_hash_data['name']
		self.email = mongo_hash_data['email']
		self.skype = mongo_hash_data['skype']
		self.twitter = mongo_hash_data['twitter']
		self.topics = mongo_hash_data['topics']
		self.registered_at = mongo_hash_data['registered_at']
		self.tags = mongo_hash_data['tags']
	end

	# Used for saving to mongodb
	def to_hash
		{
			:name => @name, 
			:email => @email,
			:skype => @skype,
			:twitter => @twitter,
			:topics => @topics,
			:registered_at => @registered_at,
			:tags => @tags
		}
	end

	def to_json
		JSON::fast_generate(self.to_hash)
	end

	def to_s
		"[Registration name: '#{@name}', email: '#{@email}',
			skype: '#{@skype}', twitter: '#{@twitter}',
			topics: '#{@topics}', registered_at: '#{@registered_at}',
			tags: '#{@tags}']"
	end
end