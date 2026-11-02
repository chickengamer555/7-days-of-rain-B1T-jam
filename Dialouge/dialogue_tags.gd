class_name DialogueTags
extends RefCounted

const YORN_TOKEN: String = "{YorN}"

## The universal "type forever" token (a looping typewriter). Detected before stripping.
const LOOP_TOKEN: String = "{loop}"

## Tag contents (lower case) with a fixed meaning, so they can never be link targets.
const CONTROL_TAGS: Array[String] = ["loop", "yorn", "y", "n"]


## `s` with every `{...}` tag removed and leftover double spaces collapsed.
static func strip(s: String) -> String:
	var result: String = ""
	var i: int = 0
	for tok: Dictionary in _tokens(s):
		result += s.substr(i, int(tok["open"]) - i)
		i = int(tok["close"]) + 1
	result += s.substr(i)
	while result.contains("  "):
		result = result.replace("  ", " ")
	return result.strip_edges()


## True if `s` carries the {YorN} prompt token (tag content matched case-insensitively, so
static func has_yorn(s: String) -> bool:
	for tok: Dictionary in _tokens(s):
		if String(tok["content"]).to_lower() == "yorn":
			return true
	return false


## True if `s` carries the {loop} token.
static func has_loop(s: String) -> bool:
	for tok: Dictionary in _tokens(s):
		if String(tok["content"]).to_lower() == "loop":
			return true
	return false



static func branch_of(s: String) -> String:
	for tok: Dictionary in _tokens(s):
		var c: String = String(tok["content"]).to_lower()
		if c == "y":
			return "y"
		if c == "n":
			return "n"
	return ""


## The per-line typing speed (characters/second) 
static func char_speed(s: String) -> float:
	for tok: Dictionary in _tokens(s):
		var c: String = String(tok["content"]).to_lower()
		if _is_speed_tag(c):
			return c.substr(0, c.length() - 3).strip_edges().to_float()
	return 0.0


## The first tag that is a link target, or "" if none. 
static func link_target(s: String) -> String:
	for tok: Dictionary in _tokens(s):
		var content: String = tok["content"]
		if _is_link_content(content):
			return content
	return ""


## Every `{...}` occurrence as {content, open, close} index spans, in order.
static func _tokens(s: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var i: int = 0
	while true:
		var open: int = s.find("{", i)
		if open == -1:
			break
		var close: int = s.find("}", open + 1)
		if close == -1:
			break
		out.append({
			"content": s.substr(open + 1, close - open - 1).strip_edges(),
			"open": open, "close": close})
		i = close + 1
	return out


static func _is_link_content(content: String) -> bool:
	var c: String = content.to_lower()
	return not (c.is_empty() or c.is_valid_int() or CONTROL_TAGS.has(c) or _is_speed_tag(c))


## `c` is lower case. A node called `facts` ends in "cts" too, so the rest must be a number.
static func _is_speed_tag(c: String) -> bool:
	return c.ends_with("cts") and c.substr(0, c.length() - 3).strip_edges().is_valid_float()
