
Spec::Matchers.define :have_properties do |expected_properties|
  match do |actual|
		raise if expected_properties.empty?
		success = true
		@errors = {}

    expected_properties.each do |name,expected_value|
			actual_value = actual.send(name)
			if actual_value != expected_value
				success = false
				@errors.merge!(name => [actual_value,expected_value])
			end
		end

		success
  end

  failure_message_for_should do |actual|
    "#{actual} did not have the expected properties: #{@errors.inspect}"
  end

  #failure_message_for_should_not do |actual|
  #  "expected that #{actual} would not have #{expected}"
  #end
end
