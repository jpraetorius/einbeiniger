class Registration

	attr_accessor :name
	attr_accessor :email
	attr_accessor :skype
	attr_accessor :twitter
	attr_accessor :topics
	attr_accessor :tags

	def to_hash
		{
			:name => @name, 
			:email => @email,
			:skype => @skype,
			:twitter => @twitter,
			:topics => @topics,
			:tags => @tags
		}
	end

	def to_json
		JSON.generate(self.to_hash)
	end
end