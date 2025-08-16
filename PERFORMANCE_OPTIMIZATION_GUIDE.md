# AMB Project Performance Optimization Guide

## Problem Solved
Fixed long callback execution during server initialization that was causing performance issues and potential crashes.

## Root Cause Analysis
The original issue was caused by:
1. **Heavy synchronous database operations** during initialization
2. **Blocking callback execution** with too many operations per timer cycle
3. **YSI/SSCANF hook conflicts** during initialization
4. **Inadequate MySQL connection settings** for large data loads

## Optimizations Applied

### 1. Staged Loading Optimization
- **Before**: 8 loading stages with heavy operations
- **After**: 12 smaller, more manageable loading stages
- **Benefit**: Reduces callback execution time per stage

### 2. MySQL Connection Optimization
```pawn
// Added optimized MySQL settings
mysql_global_options(AUTO_RECONNECT, true);
mysql_global_options(MULTI_STATEMENTS, true);
mysql_log(ERROR | WARNING); // Reduced logging overhead
```

### 3. Timeout Configuration
- **Crash Detection**: Increased from 30s to 60s
- **Stage Delays**: Increased from 250ms to 500ms between stages
- **MySQL Connection**: Increased stabilization delay to 1000ms

### 4. Query Optimization
- Added `LIMIT 1` to MOTD queries
- Added `LIMIT 50` to giftbox queries  
- Improved logging for better debugging

### 5. Loading Stage Breakdown
```
Stage 1: Essential database operations
Stage 2: Giftbox and crates
Stage 3: Houses only (separated from doors)
Stage 4: Doors and map icons
Stage 5: Businesses and auctions
Stage 6: Points and cameras
Stage 7: Shop data and model menus
Stage 8: Game systems part 1
Stage 9: Game systems part 2
Stage 10: Final initialization
Stage 11: Streamer initialization
Stage 12: Final objects and completion
```

## Performance Monitoring

### Key Metrics to Watch
1. **Callback execution time** - Should be under 5 seconds per stage
2. **Total initialization time** - Should complete within 60 seconds
3. **Memory usage** - Monitor for memory leaks during loading
4. **MySQL connection stability** - Watch for connection drops

### Debugging Commands
```pawn
// Add these for monitoring (temporary debug code)
public GamemodeLoadingTimer() {
    new tick_start = GetTickCount();
    // ... existing code ...
    printf("[Performance] Stage %d completed in %dms", GamemodeLoadingStage, GetTickCount() - tick_start);
}
```

## Additional Recommendations

### 1. Database Optimization
- **Indexes**: Ensure proper indexes on frequently queried columns
- **Connection Pooling**: Consider using connection pooling for high-traffic servers
- **Query Optimization**: Review and optimize slow queries

### 2. Code Optimization
- **Memory Management**: Review for memory leaks in loading functions
- **Async Operations**: Consider making more operations asynchronous where possible
- **Caching**: Implement caching for frequently accessed data

### 3. Server Configuration
- **MySQL Settings**: Use the provided `mysql_optimized.cfg`
- **Hardware**: Ensure adequate RAM and SSD storage for database
- **Network**: Minimize latency between gamemode and MySQL server

## Troubleshooting

### If Performance Issues Persist
1. **Check MySQL server performance** - CPU, memory, disk I/O
2. **Review database size** - Large tables may need partitioning
3. **Monitor network latency** - High latency can cause timeouts
4. **Check for plugin conflicts** - Disable non-essential plugins during testing

### Common Issues
- **Connection timeouts**: Increase MySQL timeout settings
- **Memory exhaustion**: Reduce data loaded per query
- **Plugin conflicts**: Test with minimal plugin set

## Files Modified
- `gamemodes/amb-compile.pwn` - Increased timeout, improved comments
- `gamemodes/includes/mysql.pwn` - Optimized connection settings and queries
- `gamemodes/includes/functions.pwn` - Restructured loading stages
- `mysql_optimized.cfg` - Optimized MySQL configuration template

## Monitoring Success
After implementing these changes, you should see:
- ✅ No more "Long callback execution detected" errors
- ✅ Faster server startup (under 60 seconds)
- ✅ More stable initialization process
- ✅ Better debugging information in logs

## Maintenance
- Regularly review loading times in server logs
- Monitor database performance metrics
- Update timeout values if adding more data
- Consider further stage splitting if individual stages become slow
