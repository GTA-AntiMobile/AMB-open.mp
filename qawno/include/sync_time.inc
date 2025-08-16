#if defined _sync_time_included
    #endinput
#endif
#define _sync_time_included

forward RealTimeSync();
public RealTimeSync()
{
    new hours, minutes, seconds;
    gettime(hours, minutes, seconds);
    SetWorldTime(hours);
}

public OnGameModeInit()
{
    SetTimer(#RealTimeSync, 15000, true); // sync after 15 seconds

    #if defined synctime_OnGameModeInit
        return synctime_OnGameModeInit();
    #else
        return 1;
    #endif
}

#if defined _ALS_OnGameModeInit
	#undef OnGameModeInit
#else
	#define _ALS_OnGameModeInit
#endif
#define OnGameModeInit synctime_OnGameModeInit
#if defined synctime_OnGameModeInit
	forward synctime_OnGameModeInit();
#endif