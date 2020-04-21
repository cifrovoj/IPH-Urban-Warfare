#if !defined(using_map_DATUM)

	#include "../shared/exodus_torch/_include.dm"

	#include "hospital_announcements.dm"
	#include "hospital_areas.dm"


	//CONTENT
	#include "../shared/job/jobs.dm"
	#include "../shared/datums/uniforms.dm"
	#include "../shared/items/cards_ids.dm"
	#include "../shared/items/clothing.dm"
	#include "hospital_gamemodes.dm"
	#include "hospital_presets.dm"
	#include "hospital_shuttles.dm"
	#include "hospital_elevator.dm"

	#include "hospital-1.dmm"


	#include "../shared/exodus_torch/_include.dm"

	#include "../../code/modules/lobby_music/generic_songs.dm"

	#define using_map_DATUM /datum/map/hospital

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring hospital
#endif
