class_name StringUtil

static func find_nth_occurrence(text: String, target: String, n: int) -> int:
	var pos = -1
	for i in range(n):
		pos = text.find(target, pos + 1)
		if pos == -1:
			break
	return pos
