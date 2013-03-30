class Entry
	include Comparable

	attr_accessor :timecode_absolute
	attr_accessor :timecode_relative
	attr_accessor :text

	def to_s
		"[Entry: timecode_relative: '#{@timecode_relative}', timecode_absolute: '#{@timecode_absolute}', text: '#{@text}']"
	end

	def <=>(anOther)
    	@timecode_absolute <=> anOther.timecode_absolute
  	end
end