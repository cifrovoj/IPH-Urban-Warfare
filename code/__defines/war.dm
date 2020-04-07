// used for factions and sometimes languages
#define SEPARATIST "SEPARATIST"
#define CIVILIAN "CIVILIAN"
#define PARTISAN "PARTISAN" // ukrainian but not with ruskies
#define FEDERAL "SOVIET"
#define ITALIAN "FEDERAL"
#define PILLARMEN "PILLARMEN"
#define JAPAN "JAPAN"
#define USA "USA"

// there are things with 'SS' in their type path, thats why the const isn't SS
// this is only used for a few circumstances right now, like faction bans
#define SCHUTZSTAFFEL "SS"
#define SS_TV "SS_TV"
#define CROATION "CROATION"
#define TEREK "TEREK"
#define UKRAINE "UKRAINE"
#define SOVIET_PRISONER "SOVIET_PRISONER"
#define GERMAN_REICHSTAG "GERMAN_REICHSTAG"
#define SOVIET_PARTISAN "SOVIET_PARTISAN"
#define DIRLEWANGER "DIRLEWANGER"
#define ESCORT "ESCORT"
#define POLISH_INSURGENTS "POLISH_INSURGENTS"

// used for languages only
#define RUSSIAN "RUSSIAN"
#define POLISH "POLISH"
#define UKRAINIAN "UKRAINIAN"
#define ENGLISH "ENGLISH"
#define JAPANESE "JAPANESE"

/proc/faction_const2name(constant)
	if (constant == POLISH_INSURGENTS)
		return "Polish Insurgents"

	if (constant == FEDERAL)
		return "Federal Forces"

	if (constant == USA)
		return "Allies"

	if (constant == JAPAN)
		return "Axis"

	if (constant == SEPARATIST)
		return "Separatist Insurgents"