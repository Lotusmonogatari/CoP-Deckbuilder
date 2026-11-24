class_name ScrollStyle
extends RefCounted
## The Codex scroll's look in the active UI style (P18, 2026-11-24): paper, ink, rollers, caps, seal and cord, read from the UI Styles
## tab's scroll tokens (colours as "scroll_*" colour rows, the rest in the "scroll" group). A style changes the scroll by changing
## those rows; no screen has a per-style branch. The three styles' values are Claude's drafts from the P18 mock-ups.


## A scroll colour by its short name ("paper" for the scroll_paper row).
static func colour(short_name: String) -> Color:
	return UiStyle.colour("scroll_" + short_name, Color.MAGENTA)


## A scroll token's text ("" when the style leaves it blank).
static func text(token: String, fallback: String = "") -> String:
	return UiStyles.token(UiStyle.idx(), UiStyle.current(), "scroll", token, fallback)


static func yes(token: String) -> bool:
	return text(token) == "yes"


static func number(token: String, fallback: float = 0.0) -> float:
	return UiStyle.number("scroll", token, fallback)


## A length in base pixels from mockup pixels (the 390 px mock-up scaled to the 1080 px base).
static func len_px(mockup_px: float) -> float:
	return LevelBriefingStyles.len_px(mockup_px)
