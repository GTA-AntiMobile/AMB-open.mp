const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8081;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.text()); // For raw text body

// Serve static MP3 files
app.use('/mp3', express.static(path.join(__dirname, 'mp3_files')));

// Logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// Create mp3_files directory if it doesn't exist
const mp3Dir = path.join(__dirname, 'mp3_files');
if (!fs.existsSync(mp3Dir)) {
    fs.mkdirSync(mp3Dir);
    console.log('Created mp3_files directory');
}

// Cache để track conversion status
const conversionCache = new Map();
const CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours

// Helper function để extract video ID từ URL
function extractVideoId(url) {
    const patterns = [
        /(?:https?:\/\/)?(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/,
        /(?:https?:\/\/)?(?:www\.)?youtu\.be\/([a-zA-Z0-9_-]{11})/,
        /^([a-zA-Z0-9_-]{11})$/ // Chỉ video ID
    ];
    
    for (const pattern of patterns) {
        const match = url.match(pattern);
        if (match) return match[1];
    }
    return null;
}

// Helper function để sanitize filename
function sanitizeFilename(filename) {
    return filename.replace(/[^a-zA-Z0-9_-]/g, '_').substring(0, 100);
}

// Helper function để run yt-dlp command
function downloadAndConvert(videoId, outputPath) {
    return new Promise((resolve, reject) => {
        const url = `https://www.youtube.com/watch?v=${videoId}`;
        
        // FFmpeg path
        const ffmpegPath = 'C:\\Users\\Dylan\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Gyan.FFmpeg.Essentials_Microsoft.Winget.Source_8wekyb3d8bbwe\\ffmpeg-7.1.1-essentials_build\\bin';
        
        // yt-dlp command với FFmpeg path
        const command = `yt-dlp -x --audio-format mp3 --audio-quality 192K --ffmpeg-location "${ffmpegPath}" --output "${outputPath}" "${url}"`;
        
        console.log(`Running: ${command}`);
        
        exec(command, { timeout: 300000 }, (error, stdout, stderr) => { // 5 minute timeout
            if (error) {
                console.error(`Error: ${error.message}`);
                reject(error);
                return;
            }
            if (stderr) {
                console.error(`Stderr: ${stderr}`);
            }
            console.log(`Success: ${stdout}`);
            resolve(stdout);
        });
    });
}

// Helper function để get video info
function getVideoInfo(videoId) {
    return new Promise((resolve, reject) => {
        const url = `https://www.youtube.com/watch?v=${videoId}`;
        const command = `yt-dlp --dump-json --no-download "${url}"`;
        
        exec(command, { timeout: 30000 }, (error, stdout, stderr) => {
            if (error) {
                reject(error);
                return;
            }
            try {
                const info = JSON.parse(stdout);
                resolve({
                    title: info.title || 'Unknown Title',
                    duration: info.duration || 0,
                    uploader: info.uploader || 'Unknown'
                });
            } catch (e) {
                reject(e);
            }
        });
    });
}

// Route: Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'YouTube to MP3 API is running',
        timestamp: new Date().toISOString(),
        mp3_count: fs.readdirSync(mp3Dir).filter(f => f.endsWith('.mp3')).length
    });
});

// Route: Convert YouTube to MP3
app.post('/convert', async (req, res) => {
    try {
        // Debug logging
        console.log('=== REQUEST DEBUG ===');
        console.log('Content-Type:', req.headers['content-type']);
        console.log('Raw body:', req.body);
        console.log('Body type:', typeof req.body);
        console.log('Body length:', req.body ? req.body.length : 0);
        
        // Handle SA-MP specific format
        let url;
        let videoId;
        
        if (req.headers['content-type'] && req.headers['content-type'].includes('application/x-www-form-urlencoded')) {
            // SA-MP sends JSON as URL-encoded, need to reconstruct
            const keys = Object.keys(req.body);
            const values = Object.values(req.body);
            
            if (keys.length > 0) {
                // Reconstruct JSON string from broken parts
                const jsonString = keys[0] + values[0];
                console.log('Reconstructed JSON:', jsonString);
                
                try {
                    const jsonData = JSON.parse(jsonString);
                    url = jsonData.url;
                    videoId = jsonData.video_id;
                    console.log('Parsed JSON URL:', url);
                    console.log('Parsed JSON Video ID:', videoId);
                } catch (e) {
                    console.log('JSON parse error:', e.message);
                    // Try direct key as URL
                    url = keys[0];
                    console.log('Using key as URL:', url);
                }
            }
        } else if (req.headers['content-type'] && req.headers['content-type'].includes('application/json')) {
            url = req.body.url;
            videoId = req.body.video_id;
        } else {
            // Fallback
            url = req.body.url || req.body;
            videoId = req.body.video_id;
        }
        
        // If we have video_id, construct URL from it
        if (videoId && !url) {
            url = `https://www.youtube.com/watch?v=${videoId}`;
            console.log('Constructed URL from video_id:', url);
        }
        
        console.log('Final URL:', url);
        console.log('=====================');
        
        if (!url) {
            return res.status(400).json({
                success: false,
                error: 'URL is required'
            });
        }
        
        // Check if URL is incomplete (missing video ID)
        if (url === 'https://youtube.com/watch?v' || url === 'https://youtube.com/watch?v=') {
            return res.status(400).json({
                success: false,
                error: 'Video ID is missing from URL'
            });
        }

        const extractedVideoId = extractVideoId(url);
        if (!extractedVideoId) {
            return res.status(400).json({
                success: false,
                error: 'Invalid YouTube URL'
            });
        }

        // Check if already converted and cached
        const cacheKey = `convert_${extractedVideoId}`;
        const cached = conversionCache.get(cacheKey);
        if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
            console.log(`Cache hit for: ${extractedVideoId}`);
            
            // Check if file still exists
            if (fs.existsSync(cached.data.file_path)) {
                return res.json(cached.data);
            } else {
                // File deleted, remove from cache
                conversionCache.delete(cacheKey);
            }
        }

        // Get video info first
        const videoInfo = await getVideoInfo(extractedVideoId);
        const safeTitle = sanitizeFilename(videoInfo.title);
        const filename = `${extractedVideoId}_${safeTitle}.mp3`;
        const outputPath = path.join(mp3Dir, filename);
        
        // Check if file already exists
        if (fs.existsSync(outputPath)) {
            const stats = fs.statSync(outputPath);
            const result = {
                success: true,
                video_id: extractedVideoId,
                title: videoInfo.title,
                duration: videoInfo.duration,
                uploader: videoInfo.uploader,
                mp3_url: `http://26.142.249.17:${PORT}/mp3/${filename}`,
                file_path: outputPath,
                file_size: stats.size,
                created_at: stats.birthtime,
                from_cache: true
            };
            
            // Cache result
            conversionCache.set(cacheKey, {
                data: result,
                timestamp: Date.now()
            });
            
            return res.json(result);
        }

        // Start conversion
        console.log(`Starting conversion for: ${extractedVideoId} - ${videoInfo.title}`);
        
        await downloadAndConvert(extractedVideoId, outputPath.replace('.mp3', '.%(ext)s'));
        
        // Check if file was created
        if (!fs.existsSync(outputPath)) {
            throw new Error('MP3 file was not created');
        }

        const stats = fs.statSync(outputPath);
        const result = {
            success: true,
            video_id: extractedVideoId,
            title: videoInfo.title,
            duration: videoInfo.duration,
            uploader: videoInfo.uploader,
            mp3_url: `http://26.142.249.17:${PORT}/mp3/${filename}`,
            file_path: outputPath,
            file_size: stats.size,
            created_at: new Date(),
            from_cache: false
        };

        // Cache result
        conversionCache.set(cacheKey, {
            data: result,
            timestamp: Date.now()
        });

        res.json(result);

    } catch (error) {
        console.error(`Error converting video: ${error.message}`);
        res.status(500).json({
            success: false,
            error: 'Failed to convert video',
            details: error.message
        });
    }
});

// Route: Get conversion status
app.get('/status/:videoId', (req, res) => {
    const { videoId } = req.params;
    
    const cached = conversionCache.get(`convert_${videoId}`);
    if (cached) {
        res.json({
            status: 'completed',
            data: cached.data
        });
    } else {
        res.json({
            status: 'not_found',
            message: 'Video not converted yet'
        });
    }
});

// Route: List all MP3 files
app.get('/list', (req, res) => {
    try {
        const files = fs.readdirSync(mp3Dir)
            .filter(file => file.endsWith('.mp3'))
            .map(file => {
                const filePath = path.join(mp3Dir, file);
                const stats = fs.statSync(filePath);
                const videoId = file.split('_')[0];
                
                return {
                    filename: file,
                    video_id: videoId,
                    mp3_url: `http://26.142.249.17:${PORT}/mp3/${file}`,
                    file_size: stats.size,
                    created_at: stats.birthtime
                };
            })
            .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

        res.json({
            total: files.length,
            files: files
        });
    } catch (error) {
        res.status(500).json({
            error: 'Failed to list files',
            details: error.message
        });
    }
});

// Route: Delete MP3 file
app.delete('/delete/:videoId', (req, res) => {
    try {
        const { videoId } = req.params;
        
        // Find file with this video ID
        const files = fs.readdirSync(mp3Dir).filter(file => file.startsWith(videoId));
        
        if (files.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'File not found'
            });
        }

        files.forEach(file => {
            const filePath = path.join(mp3Dir, file);
            fs.unlinkSync(filePath);
            console.log(`Deleted: ${file}`);
        });

        // Remove from cache
        conversionCache.delete(`convert_${videoId}`);

        res.json({
            success: true,
            message: `Deleted ${files.length} file(s) for video ${videoId}`
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to delete file',
            details: error.message
        });
    }
});

// Route: Clear cache
app.delete('/cache', (req, res) => {
    const cacheSize = conversionCache.size;
    conversionCache.clear();
    res.json({
        message: `Cache cleared successfully. Removed ${cacheSize} entries.`
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(`Unhandled error: ${err.message}`);
    res.status(500).json({
        error: 'Internal server error',
        details: err.message
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Endpoint not found',
        available_endpoints: [
            'GET /health',
            'POST /convert',
            'GET /status/:videoId',
            'GET /list',
            'DELETE /delete/:videoId',
            'DELETE /cache',
            'GET /mp3/:filename'
        ]
    });
});

// Cleanup expired cache entries every hour
setInterval(() => {
    const now = Date.now();
    let cleaned = 0;
    
    for (const [key, value] of conversionCache.entries()) {
        if (now - value.timestamp >= CACHE_DURATION) {
            conversionCache.delete(key);
            cleaned++;
        }
    }
    
    if (cleaned > 0) {
        console.log(`Cache cleanup: removed ${cleaned} expired entries`);
    }
}, 60 * 60 * 1000); // Every hour

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🎵 YouTube to MP3 API Server started on port ${PORT}`);
    console.log(`📍 Health check: http://26.142.249.17:${PORT}/health`);
    console.log(`📖 API Endpoints:`);
    console.log(`   POST /convert - Convert YouTube to MP3`);
    console.log(`   GET  /status/:videoId - Check conversion status`);
    console.log(`   GET  /list - List all MP3 files`);
    console.log(`   GET  /mp3/:filename - Stream MP3 file`);
    console.log(`📁 MP3 files directory: ${mp3Dir}`);
    console.log(`⚡ Cache enabled with ${CACHE_DURATION / 1000 / 60 / 60} hour duration`);
});
