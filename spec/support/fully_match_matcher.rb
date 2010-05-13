
Spec::Matchers.define :fully_match do |*inputs|
  match do |grammar|
		raise if inputs.empty?
		success = true
		@errors = {}

    inputs.each do |input|
			result = grammar.parse(input)
			if result.match != :full
				success = false
				@errors.merge!(input => result.match)
			end
		end

		success
  end

  failure_message_for_should do |actual|
    "#{actual} did not fully match: #{@errors.inspect}"
  end

  #failure_message_for_should_not do |actual|
  #  "expected that #{actual} would not have #{expected}"
  #end
end
