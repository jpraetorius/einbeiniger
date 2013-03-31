class Registration

	attr_accessor :name
	attr_accessor :email
	attr_accessor :skype
	attr_accessor :twitter
	attr_accessor :topics
	attr_accessor :registered_at
	attr_accessor :tags

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
end