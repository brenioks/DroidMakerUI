extends RichTextLabel

# Define patterns in order of priority (Strings and Comments MUST be first)
const PATTERNS = {
	COMMENT = r"//.*",
	STRING = r'"[^"\\]*(?:\\.[^"\\]*)*"',
	KEYWORD = r"\b(function|var|if|else|for|while|return)\b",
	FUNCTION = r"\b\w+(?=\()",
	NUMBER = r"\b\d+\b",
	PUNCTUATION = r"[\(\)\[\]\{\}\+\-\*/=<>!&\|~%\^\.,;:\?]" # Now safe!
}

const COLORS = {
	COMMENT = "forest_green",
	STRING = "yellow",
	KEYWORD = "orange",
	FUNCTION = "orange",
	NUMBER = "orange_red",
	PUNCTUATION = "gray"
}

var master_regex = RegEx.new()

func _ready() -> void:
	# Combine all patterns into one giant regular expression using | (OR)
	var combined_pattern = ""
	for key in PATTERNS:
		combined_pattern += "(?<%s>%s)|" % [key, PATTERNS[key]]
	combined_pattern = combined_pattern.trim_suffix('|') # Remove trailing |
	
	master_regex.compile(combined_pattern)
	
	var raw_code = text
	self.text = highlight_code(raw_code)

func highlight_code(source: String) -> String:
	var output = ""
	var last_pos = 0
	
	# search_all finds non-overlapping matches from left to right
	for m in master_regex.search_all(source):
		# 1. Append text that didn't match any rule (white space, plain identifiers)
		var plain_text = source.substr(last_pos, m.get_start() - last_pos)
		output += plain_text.replace("[", "[lb]").replace("]", "[rb]")
		
		# 2. Check which group matched and apply the color
		var matched_text = m.get_string()
		var escaped_match = matched_text.replace("[", "[lb]").replace("]", "[rb]")
		var matched_group = ""
		
		for key in PATTERNS.keys():
			if not m.get_string(key).is_empty():
				matched_group = key
				break
		
		if not matched_group.is_empty():
			var highlighted_word = "[color=%s]%s[/color]" % [COLORS[matched_group], escaped_match]
			match matched_group:
				"COMMENT":
					highlighted_word = "[i]%s[/i]" % highlighted_word
				"KEYWORD":
					highlighted_word = "[b]%s[/b]" % highlighted_word
			output += highlighted_word
		else:
			output += escaped_match
			
		last_pos = m.get_end()
		
	# Append remaining text
	output += source.substr(last_pos).replace("[", "[lb]").replace("]", "[rb]")
	return output
