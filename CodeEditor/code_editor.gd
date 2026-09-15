extends RichTextLabel

# Has order of priority
const PATTERNS = {
	COMMENT = r"//.*",
	STRING = r'"[^"\\]*(?:\\.[^"\\]*)*"',
	KEYWORD = r"\b(function|var|if|else|for|while|return)\b",
	FUNCTION = r"\b\w+(?=\()",
	NUMBER = r"\b\d+\b",
	PUNCTUATION = r"[\(\)\[\]\{\}\+\-\*/=<>!&\|~%\^\.,;:\?]"
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
var gutter: Gutter:
	set(new):
		gutter = new
		gutter.fold_closed.connect(_on_fold_closed)
		gutter.fold_opened.connect(_on_fold_opened)
var full_text: String
var folded_text: String
var collaped_regions: Array


func _ready() -> void:
	var combined_pattern = ""
	for key in PATTERNS:
		combined_pattern += "(?<%s>%s)|" % [key, PATTERNS[key]]
	combined_pattern = combined_pattern.trim_suffix('|')
	
	master_regex.compile(combined_pattern)
	
	full_text = text
	folded_text = full_text
	text = highlight_code(full_text)

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
	
	output += source.substr(last_pos).replace("[", "[lb]").replace("]", "[rb]")
	return output


func _on_fold_closed(foldline_start: int, foldline_end: int):
	var line_count = folded_text.count('\n')
	if foldline_start > line_count:
		return
	var code_foldline_start = StringUtil.find_nth_occurrence(folded_text, '\n', foldline_start)
	var code_foldline_end = StringUtil.find_nth_occurrence(folded_text, '\n', foldline_end)
	
	if code_foldline_end == -1:
		if foldline_end == line_count + 1:
			code_foldline_end = folded_text.length()
		else:
			return
	
	var code_foldline_length = code_foldline_end - code_foldline_start
	var collapsed_text = folded_text.substr(code_foldline_start, code_foldline_length)
	collaped_regions.append(foldline_start)
	collaped_regions.append(collapsed_text)
	
	folded_text = folded_text.erase(code_foldline_start, code_foldline_length)
	text = highlight_code(folded_text)
	print("collapsed regions: %s" % str(collaped_regions))

func _on_fold_opened(foldline_start: int, _foldline_end: int):
	var line_count = folded_text.count('\n')
	
	var code_foldline_start = StringUtil.find_nth_occurrence(folded_text, '\n', foldline_start)
	if code_foldline_start == -1:
		if foldline_start == line_count + 1:
			code_foldline_start = folded_text.length()
		else:
			return
	
	var relative_collapsed_index = collaped_regions.find(code_foldline_start)
	var collapsed_text: String = collaped_regions[relative_collapsed_index]
	folded_text = folded_text.insert(code_foldline_start, collapsed_text)
	text = highlight_code(folded_text)
	
	collaped_regions.remove_at(relative_collapsed_index) # Removes the starting line
	collaped_regions.remove_at(relative_collapsed_index) # Removes the collapsed code block
	print("collapsed regions: %s" % str(collaped_regions))
