#!/bin/bash

# GitHub Pages Publisher & Optimizer Script for Jri Radio
# This script processes .jlres3 files, extracts metadata, and sets up GitHub Pages

set -e  # Exit on any error

echo "🚀 Starting Jri Radio GitHub Pages Publisher & Optimizer"

# Configuration
SITE_DIR="site"
FILECOUNT_FILE="$SITE_DIR/filecount.txt"
FILEDATA_FILE="$SITE_DIR/filedata.txt"
DATE_FILE="$SITE_DIR/date.txt"
RADIO_FILE="$SITE_DIR/index.html"      # Radio interface (main page)
PLAYER_FILE="$SITE_DIR/player.html"    # Player interface

# Create site directory if it doesn't exist
mkdir -p "$SITE_DIR"

echo "📁 Created/verified site directory"

# Function to check if required tools are installed
check_dependencies() {
    echo "🔍 Checking dependencies..."
    
    if ! command -v ffprobe &> /dev/null; then
        echo "❌ ffprobe not found. Installing ffmpeg..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y ffmpeg
        elif command -v yum &> /dev/null; then
            sudo yum install -y ffmpeg
        else
            echo "❌ Cannot install ffmpeg automatically. Please install it manually."
            exit 1
        fi
    fi
    
    echo "✅ Dependencies checked"
}

# Function to count .jlres3 files
count_files() {
    echo "📊 Counting .jlres3 files..."
    
    local count=$(find . -name "*.jlres3" -type f | wc -l)
    echo "$count" > "$FILECOUNT_FILE"
    
    echo "✅ Found $count .jlres3 files, saved to $FILECOUNT_FILE"
}

# Function to extract base64 image from audio file
extract_image_base64() {
    local audio_file="$1"
    local temp_image="/tmp/cover_$$.jpg"
    
    # Try to extract cover art using ffmpeg
    if ffmpeg -i "$audio_file" -an -vcodec copy "$temp_image" 2>/dev/null; then
        # Convert to base64
        local base64_data=$(base64 -w 0 "$temp_image" 2>/dev/null || base64 "$temp_image" 2>/dev/null)
        rm -f "$temp_image"
        echo "data:image/jpeg;base64,$base64_data"
    else
        echo ""  # No image found
    fi
}

# Function to extract metadata from audio files
extract_metadata() {
    echo "🎵 Extracting metadata from .jlres3 files..."
    
    # Clear the filedata file
    > "$FILEDATA_FILE"
    
    local processed=0
    local total=$(cat "$FILECOUNT_FILE")
    
    # Find all .jlres3 files and process them
    while IFS= read -r -d '' jlres3_file; do
        processed=$((processed + 1))
        echo "Processing ($processed/$total): $(basename "$jlres3_file")"
        
        # Create temporary MP3 file by copying and renaming
        local temp_mp3="${jlres3_file}.mp3"
        cp "$jlres3_file" "$temp_mp3"
        
        # Extract metadata using ffprobe
        local title=""
        local artist=""
        local img_data=""
        
        # Get title
        title=$(ffprobe -v quiet -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$temp_mp3" 2>/dev/null | head -1 | tr -d '\n\r' | sed 's/=/_EQUAL_/g')
        if [ -z "$title" ]; then
            # Fallback to filename without extension
            title=$(basename "$jlres3_file" .jlres3)
        fi
        
        # Get artist
        artist=$(ffprobe -v quiet -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$temp_mp3" 2>/dev/null | head -1 | tr -d '\n\r' | sed 's/=/_EQUAL_/g')
        if [ -z "$artist" ]; then
            artist="Unknown Artist"
        fi
        
        # Extract cover image as base64
        img_data=$(extract_image_base64 "$temp_mp3")
        if [ -z "$img_data" ]; then
            img_data="none"
        fi
        
        # Clean up temp file
        rm -f "$temp_mp3"
        
        # Save to filedata.txt in format: (filename=title=artist=imgdata)
        echo "($(basename "$jlres3_file")=$title=$artist=$img_data)" >> "$FILEDATA_FILE"
        
    done < <(find . -name "*.jlres3" -type f -print0)
    
    echo "✅ Metadata extraction complete, saved to $FILEDATA_FILE"
}

# Function to get commit date
get_commit_date() {
    echo "📅 Getting commit date..."
    
    # Get the current commit date in ISO format
    local commit_date=$(git log -1 --format="%cI" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$commit_date" > "$DATE_FILE"
    
    echo "✅ Commit date saved to $DATE_FILE: $commit_date"
}

# Function to create optimized radio.html (now index.html) for GitHub Pages
create_radio_html() {
    echo "🌐 Creating/updating index.html (Radio) for GitHub Pages..."
    
    cat > "$RADIO_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jri Radio</title>
    <style>
        :root {
            --bg-color: #74b9ff;
            --container-bg: #fff;
            --text-color: #333;
            --secondary-text: #777;
            --light-text: #999;
            --play-button-bg: #4CAF50;
            --play-button-hover: #45a049;
            --next-button-bg: #2196F3;
            --next-button-hover: #0b7dda;
            --progress-bg: #ddd;
            --progress-fill: #4CAF50;
            --shadow-color: rgba(0, 0, 0, 0.1);
            --error-bg: #ffebee;
            --error-border: #f44336;
            --error-text: #c62828;
            --artist-controller-bg: #f8f9fa;
            --artist-controller-border: #e9ecef;
        }
        
        body.dark-mode {
            --bg-color: #003060;
            --container-bg: #1e1e1e;
            --text-color: #e0e0e0;
            --secondary-text: #b0b0b0;
            --light-text: #909090;
            --play-button-bg: #388e3c;
            --play-button-hover: #2e7d32;
            --next-button-bg: #1976d2;
            --next-button-hover: #1565c0;
            --progress-bg: #424242;
            --progress-fill: #4CAF50;
            --shadow-color: rgba(0, 0, 0, 0.3);
            --error-bg: #2d1b1b;
            --error-border: #d32f2f;
            --error-text: #ef5350;
            --artist-controller-bg: #2a2a2a;
            --artist-controller-border: #404040;
        }
        
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: var(--bg-color);
            color: var(--text-color);
            transition: background-color 0.3s, color 0.3s;
        }
        
        .player-container {
            background-color: var(--container-bg);
            border-radius: 8px;
            box-shadow: 0 2px 10px var(--shadow-color);
            padding: 20px;
            margin-bottom: 20px;
            transition: background-color 0.3s, box-shadow 0.3s;
        }
        
        .track-info {
            display: flex;
            margin-bottom: 20px;
        }
        
        .cover-art {
            width: 200px;
            height: 200px;
            background-color: #333;
            margin-right: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            border-radius: 8px;
        }
        
        .cover-art img {
            max-width: 100%;
            max-height: 100%;
            object-fit: cover;
        }
        
        .track-details {
            flex: 1;
        }
        
        .track-title {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        
        .track-artist {
            font-size: 18px;
            color: var(--secondary-text);
            margin-bottom: 15px;
        }
        
        .controls {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
            gap: 10px;
        }
        
        .play-button, .next-button, .artist-controller-toggle {
            color: white;
            border: none;
            padding: 10px 20px;
            text-align: center;
            font-size: 16px;
            cursor: pointer;
            border-radius: 4px;
            transition: background-color 0.2s;
        }
        
        .play-button {
            background-color: var(--play-button-bg);
            min-width: 100px;
        }
        
        .next-button, .artist-controller-toggle {
            background-color: var(--next-button-bg);
        }
        
        .play-button:hover {
            background-color: var(--play-button-hover);
        }
        
        .next-button:hover, .artist-controller-toggle:hover {
            background-color: var(--next-button-hover);
        }
        
        .progress-container {
            height: 8px;
            background-color: var(--progress-bg);
            border-radius: 4px;
            margin: 10px 0;
            width: 100%;
            cursor: pointer;
        }
        
        .progress-bar {
            height: 100%;
            background-color: var(--progress-fill);
            border-radius: 4px;
            width: 0;
            transition: width 0.1s linear;
        }
        
        .time-display {
            display: flex;
            justify-content: space-between;
            font-size: 14px;
            color: var(--secondary-text);
            margin-top: 5px;
        }
        
        .loading-indicator {
            text-align: center;
            padding: 20px;
            font-style: italic;
            color: var(--secondary-text);
        }
        
        .theme-toggle {
            background: none;
            border: none;
            color: var(--secondary-text);
            cursor: pointer;
            font-size: 14px;
            padding: 5px 10px;
            border-radius: 4px;
            margin-left: 10px;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header-controls {
            display: flex;
            align-items: center;
        }
        
        .volume-control {
            display: flex;
            align-items: center;
            margin-left: 15px;
        }
        
        .volume-control input[type="range"] {
            width: 100px;
            height: 6px;
            -webkit-appearance: none;
            background: var(--progress-bg);
            border-radius: 3px;
            outline: none;
            margin: 0 10px;
        }
        
        .error-message {
            background-color: var(--error-bg);
            border: 1px solid var(--error-border);
            color: var(--error-text);
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
        
        .player-link {
            display: block;
            text-align: center;
            margin-top: 20px;
            color: var(--primary-color);
            text-decoration: none;
            font-weight: bold;
        }
        
        .player-link:hover {
            text-decoration: underline;
        }
        
        .artist-controller {
            background-color: var(--artist-controller-bg);
            border: 1px solid var(--artist-controller-border);
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            display: none;
        }
        
        .artist-controller.show {
            display: block;
        }
        
        .artist-controller h3 {
            margin-top: 0;
            margin-bottom: 15px;
            font-size: 18px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .artist-controller-actions {
            display: flex;
            gap: 10px;
            margin-bottom: 15px;
        }
        
        .select-all-btn, .select-none-btn {
            background: var(--secondary-text);
            color: white;
            border: none;
            padding: 5px 10px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            transition: background-color 0.2s;
        }
        
        .select-all-btn:hover, .select-none-btn:hover {
            background: var(--text-color);
        }
        
        .artist-list {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 10px;
            max-height: 300px;
            overflow-y: auto;
            border: 1px solid var(--artist-controller-border);
            border-radius: 4px;
            padding: 10px;
        }
        
        .artist-item {
            display: flex;
            align-items: center;
            padding: 5px;
            border-radius: 4px;
            transition: background-color 0.2s;
        }
        
        .artist-item:hover {
            background-color: rgba(0, 0, 0, 0.05);
        }
        
        body.dark-mode .artist-item:hover {
            background-color: rgba(255, 255, 255, 0.05);
        }
        
        .artist-item input[type="checkbox"] {
            margin-right: 8px;
        }
        
        .artist-item label {
            cursor: pointer;
            flex: 1;
            font-size: 14px;
        }
        
        .artist-track-count {
            color: var(--secondary-text);
            font-size: 12px;
            margin-left: 5px;
        }
        
        #audio-player {
            display: none;
        }
        
        @media (max-width: 600px) {
            .track-info {
                flex-direction: column;
            }
            
            .cover-art {
                margin-right: 0;
                margin-bottom: 15px;
                align-self: center;
            }
            
            .artist-list {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Jri Radio</h1>
        <div class="header-controls">
            <button id="theme-toggle" class="theme-toggle">Dark Mode</button>
        </div>
    </div>
    
    <div class="artist-controller" id="artist-controller">
        <h3>
            Artist Controller
            <span class="artist-track-count" id="enabled-count">All artists enabled</span>
        </h3>
        <div class="artist-controller-actions">
            <button class="select-all-btn" id="select-all-btn">Select All</button>
            <button class="select-none-btn" id="select-none-btn">Select None</button>
        </div>
        <div class="artist-list" id="artist-list">
            <!-- Artists will be populated here -->
        </div>
    </div>
    
    <div class="player-container">
        <div id="loading" class="loading-indicator">Loading music library...</div>
        
        <div id="error-display" class="error-message" style="display: none;">
            Unable to load music files. This GitHub Pages version requires the files to be properly configured.
        </div>
        
        <div id="player-ui" style="display: none;">
            <div class="track-info">
                <div class="cover-art">
                    <img id="cover-image" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=" alt="Album Art">
                </div>
                <div class="track-details">
                    <div class="track-title" id="track-title">Loading...</div>
                    <div class="track-artist" id="track-artist">-</div>
                </div>
            </div>
            
            <audio id="audio-player" controls></audio>
            
            <div class="progress-container" id="progress-container">
                <div class="progress-bar" id="progress-bar"></div>
            </div>
            
            <div class="time-display">
                <span id="current-time">0:00</span>
                <span id="total-time">0:00</span>
            </div>
            
            <div class="controls">
                <button class="play-button" id="play-button">Play</button>
                <button class="next-button" id="next-button">Next Track</button>
                <button class="artist-controller-toggle" id="artist-controller-toggle">Artist Filter</button>
                <div class="volume-control">
                    <input type="range" id="volume-slider" min="0" max="1" step="0.05" value="1">
                </div>
            </div>
            
            <a href="player.html" class="player-link">Open Full Music Player →</a>
        </div>
    </div>

    <script>
        // GitHub Pages optimized version of Jri Radio with Artist Controller
        class JriRadioPlayer {
            constructor() {
                this.audioPlayer = document.getElementById('audio-player');
                this.playButton = document.getElementById('play-button');
                this.nextButton = document.getElementById('next-button');
                this.artistControllerToggle = document.getElementById('artist-controller-toggle');
                this.artistController = document.getElementById('artist-controller');
                this.artistList = document.getElementById('artist-list');
                this.selectAllBtn = document.getElementById('select-all-btn');
                this.selectNoneBtn = document.getElementById('select-none-btn');
                this.enabledCount = document.getElementById('enabled-count');
                this.coverImage = document.getElementById('cover-image');
                this.trackTitle = document.getElementById('track-title');
                this.trackArtist = document.getElementById('track-artist');
                this.progressBar = document.getElementById('progress-bar');
                this.progressContainer = document.getElementById('progress-container');
                this.currentTimeDisplay = document.getElementById('current-time');
                this.totalTimeDisplay = document.getElementById('total-time');
                this.loadingIndicator = document.getElementById('loading');
                this.playerUI = document.getElementById('player-ui');
                this.errorDisplay = document.getElementById('error-display');
                this.volumeSlider = document.getElementById('volume-slider');
                this.themeToggle = document.getElementById('theme-toggle');
                
                this.tracks = [];
                this.enabledTracks = []; // Shuffled list of enabled tracks only
                this.allArtists = new Map(); // Map of artist name -> track count
                this.enabledArtists = new Set();
                this.currentTrackIndex = 0;
                this.isPlaying = false;
                this.hasUserInteracted = false;
                this.artistControllerVisible = false;
                
                this.init();
                
                // Track user interaction for autoplay
                document.addEventListener('click', () => {
                    this.hasUserInteracted = true;
                }, { once: true });
                
                document.addEventListener('keydown', () => {
                    this.hasUserInteracted = true;
                }, { once: true });
            }
            
            async init() {
                this.setupEventListeners();
                await this.loadTrackData();
                this.setupArtistController();
                this.loadTrack(0);
                this.loadSavedSettings();
            }
            
            loadSavedSettings() {
                // Load saved volume
                const savedVolume = localStorage.getItem('jriRadioVolume');
                if (savedVolume) {
                    this.volumeSlider.value = savedVolume;
                    this.audioPlayer.volume = savedVolume;
                }
                
                // Load saved theme
                const isDarkMode = localStorage.getItem('jriRadioDarkMode') === 'true';
                if (isDarkMode) {
                    document.body.classList.add('dark-mode');
                    this.themeToggle.textContent = 'Light Mode';
                }
                
                // Load saved artist preferences
                const savedArtists = localStorage.getItem('jriRadioEnabledArtists');
                if (savedArtists) {
                    this.enabledArtists = new Set(JSON.parse(savedArtists));
                    // Re-shuffle with new artist selection
                    this.shuffleEnabledTracks();
                } else {
                    // Default: enable all artists
                    this.enabledArtists = new Set(this.allArtists.keys());
                }
                
                // Load artist controller visibility
                const controllerVisible = localStorage.getItem('jriRadioArtistControllerVisible') === 'true';
                if (controllerVisible) {
                    this.toggleArtistController();
                }
            }
            
            setupEventListeners() {
                this.playButton.addEventListener('click', () => this.togglePlay());
                this.nextButton.addEventListener('click', () => this.nextTrack());
                this.artistControllerToggle.addEventListener('click', () => this.toggleArtistController());
                this.selectAllBtn.addEventListener('click', () => this.selectAllArtists());
                this.selectNoneBtn.addEventListener('click', () => this.selectNoArtists());
                this.volumeSlider.addEventListener('input', (e) => this.setVolume(e.target.value));
                this.themeToggle.addEventListener('click', () => this.toggleTheme());
                
                this.audioPlayer.addEventListener('timeupdate', () => this.updateProgress());
                this.audioPlayer.addEventListener('ended', () => this.nextTrack());
                this.audioPlayer.addEventListener('loadedmetadata', () => this.updateTimeDisplay());
                this.audioPlayer.addEventListener('canplay', () => this.handleCanPlay());
                this.audioPlayer.addEventListener('error', (e) => this.handleAudioError(e));
                
                this.progressContainer.addEventListener('click', (e) => this.seek(e));
            }
            
            handleCanPlay() {
                // Auto-start playback if user has interacted and this is the first track
                if (this.hasUserInteracted && this.currentTrackIndex === 0 && !this.isPlaying) {
                    this.togglePlay();
                }
            }
            
            handleAudioError(e) {
                console.error('Audio error:', e);
                console.log('Error details:', this.audioPlayer.error);
                // Try next track on error
                setTimeout(() => this.nextTrack(), 1000);
            }
            
            async loadTrackData() {
                try {
                    // Load file count
                    const countResponse = await fetch('./filecount.txt');
                    if (!countResponse.ok) throw new Error('Could not load file count');
                    const fileCount = parseInt(await countResponse.text());
                    
                    if (fileCount === 0) {
                        this.showError('No music files found.');
                        return;
                    }
                    
                    // Load file data
                    const dataResponse = await fetch('./filedata.txt');
                    if (!dataResponse.ok) throw new Error('Could not load file data');
                    const fileData = await dataResponse.text();
                    
                    // Parse file data
                    this.parseTrackData(fileData);
                    
                    if (this.tracks.length === 0) {
                        this.showError('No valid music files found.');
                        return;
                    }
                    
                    // Extract all artists
                    this.extractArtists();
                    
                    // Initial shuffle and filter
                    this.shuffleEnabledTracks();
                    
                } catch (error) {
                    console.error('Error loading track data:', error);
                    this.showError('Error loading music library.');
                }
            }
            
            parseTrackData(data) {
                // Parse format: (filename=title=artist=imgdata)
                const lines = data.trim().split('\n');
                this.tracks = [];
                
                for (const line of lines) {
                    if (line.startsWith('(') && line.endsWith(')')) {
                        const content = line.slice(1, -1); // Remove parentheses
                        const parts = content.split('=');
                        
                        if (parts.length >= 3) {
                            this.tracks.push({
                                filename: parts[0],
                                title: parts[1].replace(/_EQUAL_/g, '='),
                                artist: parts[2].replace(/_EQUAL_/g, '='),
                                image: parts[3] && parts[3] !== 'none' ? parts[3] : null
                            });
                        }
                    }
                }
            }
            
            extractArtists() {
                this.allArtists.clear();
                
                // Count tracks per artist
                for (const track of this.tracks) {
                    const count = this.allArtists.get(track.artist) || 0;
                    this.allArtists.set(track.artist, count + 1);
                }
                
                // Sort artists alphabetically
                this.allArtists = new Map([...this.allArtists.entries()].sort());
            }
            
            setupArtistController() {
                this.artistList.innerHTML = '';
                
                for (const [artist, count] of this.allArtists) {
                    const artistItem = document.createElement('div');
                    artistItem.className = 'artist-item';
                    
                    const checkbox = document.createElement('input');
                    checkbox.type = 'checkbox';
                    checkbox.id = `artist-${artist.replace(/[^a-zA-Z0-9]/g, '_')}`;
                    checkbox.checked = this.enabledArtists.has(artist);
                    checkbox.addEventListener('change', () => this.toggleArtist(artist, checkbox.checked));
                    
                    const label = document.createElement('label');
                    label.htmlFor = checkbox.id;
                    label.textContent = artist;
                    
                    const trackCount = document.createElement('span');
                    trackCount.className = 'artist-track-count';
                    trackCount.textContent = `(${count})`;
                    
                    artistItem.appendChild(checkbox);
                    artistItem.appendChild(label);
                    artistItem.appendChild(trackCount);
                    this.artistList.appendChild(artistItem);
                }
                
                this.updateEnabledCount();
            }
            
            toggleArtist(artist, enabled) {
                if (enabled) {
                    this.enabledArtists.add(artist);
                } else {
                    this.enabledArtists.delete(artist);
                }
                
                // Ensure at least one artist remains enabled
                if (this.enabledArtists.size === 0) {
                    this.enabledArtists.add(artist);
                    // Re-check the checkbox
                    const checkbox = document.getElementById(`artist-${artist.replace(/[^a-zA-Z0-9]/g, '_')}`);
                    if (checkbox) checkbox.checked = true;
                }
                
                this.saveArtistPreferences();
                this.updateEnabledCount();
                this.shuffleEnabledTracks(); // Re-shuffle when artists change
            }
            
            selectAllArtists() {
                this.enabledArtists = new Set(this.allArtists.keys());
                this.updateArtistCheckboxes();
                this.saveArtistPreferences();
                this.updateEnabledCount();
                this.shuffleEnabledTracks(); // Re-shuffle when artists change
            }
            
            selectNoArtists() {
                // Keep only the first artist enabled to ensure at least one remains
                const firstArtist = this.allArtists.keys().next().value;
                this.enabledArtists = new Set([firstArtist]);
                this.updateArtistCheckboxes();
                this.saveArtistPreferences();
                this.updateEnabledCount();
                this.shuffleEnabledTracks(); // Re-shuffle when artists change
            }
            
            updateArtistCheckboxes() {
                for (const [artist] of this.allArtists) {
                    const checkbox = document.getElementById(`artist-${artist.replace(/[^a-zA-Z0-9]/g, '_')}`);
                    if (checkbox) {
                        checkbox.checked = this.enabledArtists.has(artist);
                    }
                }
            }
            
            updateEnabledCount() {
                const enabledCount = this.enabledArtists.size;
                const totalCount = this.allArtists.size;
                
                if (enabledCount === totalCount) {
                    this.enabledCount.textContent = 'All artists enabled';
                } else {
                    this.enabledCount.textContent = `${enabledCount}/${totalCount} artists enabled`;
                }
            }
            
            saveArtistPreferences() {
                localStorage.setItem('jriRadioEnabledArtists', JSON.stringify([...this.enabledArtists]));
            }
            
            toggleArtistController() {
                this.artistControllerVisible = !this.artistControllerVisible;
                
                if (this.artistControllerVisible) {
                    this.artistController.classList.add('show');
                    this.artistControllerToggle.textContent = 'Hide Filter';
                } else {
                    this.artistController.classList.remove('show');
                    this.artistControllerToggle.textContent = 'Artist Filter';
                }
                
                localStorage.setItem('jriRadioArtistControllerVisible', this.artistControllerVisible);
            }
            
            shuffleEnabledTracks() {
                // Filter tracks to only include enabled artists
                this.enabledTracks = this.tracks.filter(track => 
                    this.enabledArtists.has(track.artist)
                );
                
                // Shuffle the enabled tracks
                for (let i = this.enabledTracks.length - 1; i > 0; i--) {
                    const j = Math.floor(Math.random() * (i + 1));
                    [this.enabledTracks[i], this.enabledTracks[j]] = [this.enabledTracks[j], this.enabledTracks[i]];
                }
                
                // Reset current track index
                this.currentTrackIndex = 0;
                
                console.log(`Shuffled ${this.enabledTracks.length} enabled tracks`);
            }
            
            shuffleTracks() {
                // Legacy method - now just calls shuffleEnabledTracks
                this.shuffleEnabledTracks();
            }
            
            loadTrack(index) {
                // Ensure we have enabled tracks
                if (this.enabledTracks.length === 0) {
                    // Fallback: enable all artists and reshuffle
                    this.enabledArtists = new Set(this.allArtists.keys());
                    this.updateArtistCheckboxes();
                    this.saveArtistPreferences();
                    this.updateEnabledCount();
                    this.shuffleEnabledTracks();
                }
                
                // If we've reached the end of enabled tracks, reshuffle
                if (index >= this.enabledTracks.length) {
                    this.shuffleEnabledTracks();
                    index = 0;
                }
                
                this.currentTrackIndex = index;
                const track = this.enabledTracks[index];
                
                // Load audio file using GitHub raw URL
                this.loadAudioFile(track);
                
                this.trackTitle.textContent = track.title;
                this.trackArtist.textContent = track.artist;
                
                if (track.image) {
                    this.coverImage.src = track.image;
                } else {
                    this.coverImage.src = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
                }
                
                this.updateDocumentTitle();
                this.showPlayer();
            }
            
            async loadAudioFile(track) {
                try {
                    console.log(`Loading audio file: ${track.filename}`);
                    
                    // Only use GitHub raw URL method
                    const repoUrl = window.location.hostname.includes('github.io') ? 
                        window.location.hostname.replace('.github.io', '') : 'Jri-creator/jri_site';
                    
                    this.audioPlayer.src = `https://raw.githubusercontent.com/Jri-creator/jri_site/refs/heads/main/${track.filename}`;
                    this.audioPlayer.load();
                    
                    console.log(`Audio source set to: ${this.audioPlayer.src}`);
                    
                } catch (error) {
                    console.error('Error loading audio file:', error);
                    this.showError(`Cannot load audio file: ${track.filename}`);
                }
            }
            
            showPlayer() {
                this.loadingIndicator.style.display = 'none';
                this.errorDisplay.style.display = 'none';
                this.playerUI.style.display = 'block';
            }
            
            showError(message) {
                this.loadingIndicator.style.display = 'none';
                this.playerUI.style.display = 'none';
                this.errorDisplay.textContent = message;
                this.errorDisplay.style.display = 'block';
            }
            
            togglePlay() {
                if (this.isPlaying) {
                    this.audioPlayer.pause();
                    this.playButton.textContent = 'Play';
                    this.isPlaying = false;
                } else {
                    const playPromise = this.audioPlayer.play();
                    if (playPromise !== undefined) {
                        playPromise.then(() => {
                            this.playButton.textContent = 'Pause';
                            this.isPlaying = true;
                        }).catch(e => {
                            console.log('Playback failed:', e);
                            if (!this.hasUserInteracted) {
                                this.showError('Please click to start playback (browser autoplay policy)');
                            }
                        });
                    }
                }
                this.updateDocumentTitle();
            }
            
            nextTrack() {
                this.loadTrack(this.currentTrackIndex + 1);
                if (this.isPlaying && this.hasUserInteracted) {
                    // Delay to ensure new track is loaded
                    setTimeout(() => {
                        this.audioPlayer.play().catch(e => console.log('Auto-play failed:', e));
                    }, 100);
                }
            }
            
            setVolume(volume) {
                this.audioPlayer.volume = volume;
                localStorage.setItem('jriRadioVolume', volume);
            }
            
            updateProgress() {
                if (this.audioPlayer.duration) {
                    const progress = (this.audioPlayer.currentTime / this.audioPlayer.duration) * 100;
                    this.progressBar.style.width = `${progress}%`;
                    this.currentTimeDisplay.textContent = this.formatTime(this.audioPlayer.currentTime);
                }
            }
            
            updateTimeDisplay() {
                if (this.audioPlayer.duration) {
                    this.totalTimeDisplay.textContent = this.formatTime(this.audioPlayer.duration);
                }
            }
            
            formatTime(seconds) {
                if (isNaN(seconds)) return '0:00';
                seconds = Math.floor(seconds);
                const minutes = Math.floor(seconds / 60);
                seconds = seconds % 60;
                return `${minutes}:${seconds.toString().padStart(2, '0')}`;
            }
            
            seek(e) {
                if (this.audioPlayer.duration) {
                    const rect = this.progressContainer.getBoundingClientRect();
                    const percent = (e.clientX - rect.left) / rect.width;
                    this.audioPlayer.currentTime = percent * this.audioPlayer.duration;
                }
            }
            
            updateDocumentTitle() {
                if (this.enabledTracks.length > 0) {
                    const track = this.enabledTracks[this.currentTrackIndex];
                    const baseTitle = this.isPlaying ? 
                        ` ${track.title} - ${track.artist}` : 
                        ` ${track.title} - ${track.artist}`;
                    document.title = baseTitle;
                } else {
                    document.title = 'Jri Radio';
                }
            }
            
            toggleTheme() {
                document.body.classList.toggle('dark-mode');
                const isDark = document.body.classList.contains('dark-mode');
                this.themeToggle.textContent = isDark ? 'Light Mode' : 'Dark Mode';
                localStorage.setItem('jriRadioDarkMode', isDark);
            }
        }
        
        // Initialize player when DOM is loaded
        document.addEventListener('DOMContentLoaded', () => {
            new JriRadioPlayer();
        });
    </script>
</body>
</html>
EOF

    echo "✅ Created optimized index.html (Radio) for GitHub Pages"
}

# Function to create optimized player.html for GitHub Pages
create_player_html() {
    echo "🌐 Creating/updating player.html for GitHub Pages..."
    
    cat > "$PLAYER_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jri Music Player</title>
    <style>
        :root {
            --bg-color: #f0f2f5;
            --container-bg: #fff;
            --text-color: #333;
            --secondary-text: #777;
            --light-text: #999;
            --primary-color: #2196F3;
            --primary-hover: #0b7dda;
            --play-button-bg: #4CAF50;
            --play-button-hover: #45a049;
            --next-button-bg: #2196F3;
            --next-button-hover: #0b7dda;
            --progress-bg: #ddd;
            --progress-fill: #4CAF50;
            --shadow-color: rgba(0, 0, 0, 0.1);
            --error-bg: #ffebee;
            --error-border: #f44336;
            --error-text: #c62828;
            --library-bg: #f8f9fa;
            --track-hover: #e9ecef;
            --track-active: #e3f2fd;
        }
        
        body.dark-mode {
            --bg-color: #121212;
            --container-bg: #1e1e1e;
            --text-color: #e0e0e0;
            --secondary-text: #b0b0b0;
            --light-text: #909090;
            --primary-color: #64b5f6;
            --primary-hover: #90caf9;
            --play-button-bg: #388e3c;
            --play-button-hover: #2e7d32;
            --next-button-bg: #1976d2;
            --next-button-hover: #1565c0;
            --progress-bg: #424242;
            --progress-fill: #4CAF50;
            --shadow-color: rgba(0, 0, 0, 0.3);
            --error-bg: #2d1b1b;
            --error-border: #d32f2f;
            --error-text: #ef5350;
            --library-bg: #2d2d2d;
            --track-hover: #333;
            --track-active: #0d3a6b;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Arial, sans-serif;
        }
        
        body {
            background-color: var(--bg-color);
            color: var(--text-color);
            transition: background-color 0.3s, color 0.3s;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 1px solid var(--secondary-text);
        }
        
        .header h1 {
            font-size: 28px;
            color: var(--primary-color);
        }
        
        .header-controls {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .theme-toggle {
            background: none;
            border: 2px solid var(--primary-color);
            color: var(--primary-color);
            padding: 8px 15px;
            border-radius: 20px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.2s;
        }
        
        .theme-toggle:hover {
            background-color: var(--primary-color);
            color: white;
        }
        
        .container {
            display: flex;
            flex-direction: column;
            gap: 20px;
        }
        
        @media (min-width: 900px) {
            .container {
                flex-direction: row;
            }
            
            .library-container {
                flex: 0 0 300px;
            }
            
            .player-container {
                flex: 1;
            }
        }
        
        .panel {
            background-color: var(--container-bg);
            border-radius: 12px;
            box-shadow: 0 4px 12px var(--shadow-color);
            overflow: hidden;
            transition: background-color 0.3s, box-shadow 0.3s;
        }
        
        .panel-header {
            padding: 15px 20px;
            border-bottom: 1px solid var(--progress-bg);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .panel-title {
            font-size: 18px;
            font-weight: 600;
        }
        
        .search-container {
            position: relative;
        }
        
        .search-container input {
            padding: 8px 12px;
            padding-left: 35px;
            border: 1px solid var(--progress-bg);
            border-radius: 20px;
            background-color: var(--container-bg);
            color: var(--text-color);
            width: 100%;
            max-width: 250px;
        }
        
        .search-icon {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--secondary-text);
        }
        
        .panel-content {
            padding: 20px;
        }
        
        .library-list {
            max-height: 400px;
            overflow-y: auto;
        }
        
        .track-item {
            padding: 12px 15px;
            cursor: pointer;
            border-radius: 6px;
            margin-bottom: 5px;
            transition: background-color 0.2s;
            display: flex;
            align-items: center;
        }
        
        .track-item:hover {
            background-color: var(--track-hover);
        }
        
        .track-item.active {
            background-color: var(--track-active);
            font-weight: 600;
        }
        
        .track-number {
            margin-right: 12px;
            color: var(--secondary-text);
            font-variant-numeric: tabular-nums;
            min-width: 24px;
        }
        
        .track-info {
            flex: 1;
        }
        
        .track-title {
            font-size: 15px;
            margin-bottom: 3px;
        }
        
        .track-artist {
            font-size: 13px;
            color: var(--secondary-text);
        }
        
        .player-container {
            display: flex;
            flex-direction: column;
            gap: 20px;
        }
        
        .now-playing {
            padding: 25px;
            text-align: center;
        }
        
        .album-art {
            width: 250px;
            height: 250px;
            margin: 0 auto 20px;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 6px 15px rgba(0, 0, 0, 0.2);
        }
        
        .album-art img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        
        .track-details {
            margin-bottom: 20px;
        }
        
        .now-playing-title {
            font-size: 22px;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .now-playing-artist {
            font-size: 18px;
            color: var(--secondary-text);
            margin-bottom: 5px;
        }
        
        .now-playing-album {
            font-size: 16px;
            color: var(--light-text);
        }
        
        .player-controls {
            margin-top: 20px;
        }
        
        .progress-container {
            height: 6px;
            background-color: var(--progress-bg);
            border-radius: 3px;
            margin: 15px 0;
            width: 100%;
            cursor: pointer;
            position: relative;
        }
        
        .progress-bar {
            height: 100%;
            background-color: var(--progress-fill);
            border-radius: 3px;
            width: 0;
            transition: width 0.1s linear;
        }
        
        .time-display {
            display: flex;
            justify-content: space-between;
            font-size: 14px;
            color: var(--secondary-text);
            margin-top: 5px;
        }
        
        .control-buttons {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 15px;
            margin-top: 20px;
        }
        
        .control-button {
            background: none;
            border: none;
            cursor: pointer;
            color: var(--text-color);
            font-size: 14px;
            padding: 10px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: background-color 0.2s;
        }
        
        .control-button:hover {
            background-color: var(--track-hover);
        }
        
        .play-button {
            background-color: var(--play-button-bg);
            color: white;
            width: 60px;
            height: 60px;
            border-radius: 50%;
        }
        
        .play-button:hover {
            background-color: var(--play-button-hover);
        }
        
        .volume-control {
            display: flex;
            align-items: center;
            margin-top: 15px;
            gap: 10px;
        }
        
        .volume-control input[type="range"] {
            width: 100px;
            height: 5px;
            -webkit-appearance: none;
            background: var(--progress-bg);
            border-radius: 3px;
            outline: none;
        }
        
        .volume-control input[type="range"]::-webkit-slider-thumb {
            -webkit-appearance: none;
            width: 15px;
            height: 15px;
            border-radius: 50%;
            background: var(--primary-color);
            cursor: pointer;
        }
        
        .loading-indicator {
            text-align: center;
            padding: 20px;
            font-style: italic;
            color: var(--secondary-text);
        }
        
        .error-message {
            background-color: var(--error-bg);
            border: 1px solid var(--error-border);
            color: var(--error-text);
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
        
        .keyboard-hint {
            font-size: 12px;
            color: var(--secondary-text);
            margin-top: 20px;
            text-align: center;
        }
        
        .radio-link {
            display: block;
            text-align: center;
            margin-top: 20px;
            color: var(--primary-color);
            text-decoration: none;
            font-weight: bold;
        }
        
        .radio-link:hover {
            text-decoration: underline;
        }
        
        #audio-player {
            display: none;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Jri Music Player</h1>
        <div class="header-controls">
            <button id="theme-toggle" class="theme-toggle">Dark Mode</button>
        </div>
    </div>
    
    <div class="container">
        <div class="library-container">
            <div class="panel">
                <div class="panel-header">
                    <div class="panel-title">Your Library</div>
                    <div class="search-container">
                        <span class="search-icon">🔍</span>
                        <input type="text" id="search-input" placeholder="Search...">
                    </div>
                </div>
                <div class="panel-content">
                    <div id="library-content" class="library-list">
                        <div class="loading-indicator">Loading music library...</div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="player-container">
            <div class="panel">
                <div class="panel-content now-playing">
                    <div class="album-art">
                        <img id="cover-image" src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyMDAgMjAwIiBmaWxsPSJub25lIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iIzMzMyIvPjx0ZXh0IHg9IjEwMCIgeT0iMTAwIiBkb21pbmFudC1iYXNlbGluZT0ibWlkZGxlIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSIjNjY2IiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMjQiPk5vIEltYWdlPC90ZXh0Pjwvc3ZnPg==" alt="Album Art">
                    </div>
                    
                    <div class="track-details">
                        <div class="now-playing-title" id="track-title">No Track Selected</div>
                        <div class="now-playing-artist" id="track-artist">Select a song to begin</div>
                        <div class="now-playing-album" id="track-album"></div>
                    </div>
                    
                    <div class="player-controls">
                        <div class="progress-container" id="progress-container">
                            <div class="progress-bar" id="progress-bar"></div>
                        </div>
                        
                        <div class="time-display">
                            <span id="current-time">0:00</span>
                            <span id="total-time">0:00</span>
                        </div>
                        
                        <div class="control-buttons">
                            <button class="control-button" id="prev-button" title="Previous">
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <polygon points="19 20 9 12 19 4 19 20"></polygon>
                                    <line x1="5" y1="19" x2="5" y2="5"></line>
                                </svg>
                            </button>
                            
                            <button class="control-button play-button" id="play-button" title="Play">
                                <svg id="play-icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <polygon points="5 3 19 12 5 21 5 3"></polygon>
                                </svg>
                                <svg id="pause-icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display: none;">
                                    <line x1="6" y1="4" x2="6" y2="20"></line>
                                    <line x1="18" y1="4" x2="18" y2="20"></line>
                                </svg>
                            </button>
                            
                            <button class="control-button" id="next-button" title="Next">
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <polygon points="5 4 15 12 5 20 5 4"></polygon>
                                    <line x1="19" y1="5" x2="19" y2="19"></line>
                                </svg>
                            </button>
                        </div>
                        
                        <div class="volume-control">
                            <span>🔈</span>
                            <input type="range" id="volume-slider" min="0" max="1" step="0.05" value="1">
                            <span>🔊</span>
                        </div>
                    </div>
                    
                    <div class="keyboard-hint">
                        Keyboard shortcuts: Space = Play/Pause, ←/→ = Seek, P = Previous, N = Next
                    </div>
                    
                    <a href="index.html" class="radio-link">← Back to Radio</a>
                </div>
            </div>
        </div>
    </div>

    <audio id="audio-player"></audio>

    <script>
        class JriMusicPlayer {
            constructor() {
                // Audio elements
                this.audioPlayer = document.getElementById('audio-player');
                
                // UI elements
                this.playButton = document.getElementById('play-button');
                this.prevButton = document.getElementById('prev-button');
                this.nextButton = document.getElementById('next-button');
                this.playIcon = document.getElementById('play-icon');
                this.pauseIcon = document.getElementById('pause-icon');
                this.coverImage = document.getElementById('cover-image');
                this.trackTitle = document.getElementById('track-title');
                this.trackArtist = document.getElementById('track-artist');
                this.trackAlbum = document.getElementById('track-album');
                this.progressBar = document.getElementById('progress-bar');
                this.progressContainer = document.getElementById('progress-container');
                this.currentTimeDisplay = document.getElementById('current-time');
                this.totalTimeDisplay = document.getElementById('total-time');
                this.libraryContent = document.getElementById('library-content');
                this.searchInput = document.getElementById('search-input');
                this.volumeSlider = document.getElementById('volume-slider');
                this.themeToggle = document.getElementById('theme-toggle');
                
                // Player state
                this.tracks = [];
                this.filteredTracks = [];
                this.currentTrackIndex = -1;
                this.isPlaying = false;
                this.hasUserInteracted = false;
                
                // Initialize the player
                this.init();
                
                // Track user interaction for autoplay
                document.addEventListener('click', () => {
                    this.hasUserInteracted = true;
                }, { once: true });
            }
            
            async init() {
                this.setupEventListeners();
                await this.loadTrackData();
                this.renderLibrary();
                this.loadSavedSettings();
            }
            
            loadSavedSettings() {
                // Load saved volume
                const savedVolume = localStorage.getItem('jriPlayerVolume');
                if (savedVolume) {
                    this.volumeSlider.value = savedVolume;
                    this.audioPlayer.volume = savedVolume;
                }
                
                // Load saved theme
                const isDarkMode = localStorage.getItem('jriPlayerDarkMode') === 'true';
                if (isDarkMode) {
                    document.body.classList.add('dark-mode');
                    this.themeToggle.textContent = 'Light Mode';
                }
            }
            
            setupEventListeners() {
                // Player controls
                this.playButton.addEventListener('click', () => this.togglePlay());
                this.prevButton.addEventListener('click', () => this.previousTrack());
                this.nextButton.addEventListener('click', () => this.nextTrack());
                this.volumeSlider.addEventListener('input', (e) => this.setVolume(e.target.value));
                this.themeToggle.addEventListener('click', () => this.toggleTheme());
                
                // Progress bar
                this.progressContainer.addEventListener('click', (e) => this.seek(e));
                
                // Audio events
                this.audioPlayer.addEventListener('timeupdate', () => this.updateProgress());
                this.audioPlayer.addEventListener('ended', () => this.nextTrack());
                this.audioPlayer.addEventListener('loadedmetadata', () => this.updateTimeDisplay());
                this.audioPlayer.addEventListener('canplay', () => this.handleCanPlay());
                this.audioPlayer.addEventListener('error', (e) => this.handleAudioError(e));
                
                // Search
                this.searchInput.addEventListener('input', () => this.filterLibrary());
                
                // Keyboard shortcuts
                document.addEventListener('keydown', (e) => this.handleKeyboardShortcuts(e));
            }
            
            handleCanPlay() {
                // Auto-start playback if user has interacted and this is the first track
                if (this.hasUserInteracted && this.currentTrackIndex === 0 && !this.isPlaying) {
                    this.togglePlay();
                }
            }
            
            handleAudioError(e) {
                console.error('Audio error:', e);
                console.log('Error details:', this.audioPlayer.error);
                // Try next track on error
                setTimeout(() => this.nextTrack(), 1000);
            }
            
            async loadTrackData() {
                try {
                    // Load file count
                    const countResponse = await fetch('./filecount.txt');
                    if (!countResponse.ok) throw new Error('Could not load file count');
                    const fileCount = parseInt(await countResponse.text());
                    
                    if (fileCount === 0) {
                        this.showError('No music files found.');
                        return;
                    }
                    
                    // Load file data
                    const dataResponse = await fetch('./filedata.txt');
                    if (!dataResponse.ok) throw new Error('Could not load file data');
                    const fileData = await dataResponse.text();
                    
                    // Parse file data
                    this.parseTrackData(fileData);
                    
                    if (this.tracks.length === 0) {
                        this.showError('No valid music files found.');
                        return;
                    }
                    
                } catch (error) {
                    console.error('Error loading track data:', error);
                    this.showError('Error loading music library.');
                    // Fallback to sample tracks
                    this.tracks = [
                        {
                            title: "Sample Track 1",
                            artist: "Sample Artist",
                            album: "Sample Album",
                            filename: "https://filesamples.com/samples/audio/mp3/Sample_MP3_700KB.mp3",
                                                        image: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyMDAgMjAwIiBmaWxsPSJub25lIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iIzIxOTZGMyIvPjx0ZXh0IHg9IjEwMCIgeT0iMTAwIiBkb21pbmFudC1iYXNlbGluZT0ibWlkZGxlIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSJ3aGl0ZSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjE4Ij5TYW1wbGUgMTwvdGV4dD48L3N2Zz4="
                        },
                        {
                            title: "Sample Track 2",
                            artist: "Sample Artist",
                            album: "Sample Album",
                            filename: "https://filesamples.com/samples/audio/mp3/Sample_MP3_700KB.mp3",
                            image: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyMDAgMjAwIiBmaWxsPSJub25lIj48cmVjdCB3aWR0aD0iMjAwIi hoZWlnaHQ9IjIwMCIgZmlsbD0iIzRDQThGNCIvPjx0ZXh0IHg9IjEwMCIgeT0iMTAwIiBkb21pbmFudC1iYXNlbGluZT0ibWlkZGxlIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSJ3aGl0ZSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjE4Ij5TYW1wbGUgMjwvdGV4dD48L3N2Zz4="
                        },
                        {
                            title: "Sample Track 3",
                            artist: "Another Artist",
                            album: "Different Album",
                            filename: "https://filesamples.com/samples/audio/mp3/Sample_MP3_700KB.mp3",
                            image: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyMDAgMjAwIiBmaWxsPSJub25lIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iI0Y0NDMzNiIvPjx0ZXh0IHg9IjEwMCIgeT0iMTAwIiBkb21pbmFudC1iYXNlbGluZT0ibWlkZGxlIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSJ3aGl0ZSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU="
                        }
                    ];
                }
                
                this.filteredTracks = [...this.tracks];
            }
            
            parseTrackData(data) {
                // Parse format: (filename=title=artist=imgdata)
                const lines = data.trim().split('\n');
                this.tracks = [];
                
                for (const line of lines) {
                    if (line.startsWith('(') && line.endsWith(')')) {
                        const content = line.slice(1, -1); // Remove parentheses
                        const parts = content.split('=');
                        
                        if (parts.length >= 3) {
                            // Get the GitHub raw URL for the audio file
                            const repoUrl = window.location.hostname.includes('github.io') ? 
                                window.location.hostname.replace('.github.io', '') : 'Jri-creator/jri_site';
                            
                            const audioUrl = `https://raw.githubusercontent.com/Jri-creator/jri_site/refs/heads/main/${parts[0]}`;
                            
                            this.tracks.push({
                                filename: audioUrl,
                                title: parts[1].replace(/_EQUAL_/g, '='),
                                artist: parts[2].replace(/_EQUAL_/g, '='),
                                album: "", // Not provided in the data format
                                image: parts[3] && parts[3] !== 'none' ? parts[3] : null
                            });
                        }
                    }
                }
            }
            
            renderLibrary() {
                if (this.tracks.length === 0) {
                    this.libraryContent.innerHTML = '<div class="error-message">No tracks available</div>';
                    return;
                }
                
                this.libraryContent.innerHTML = this.filteredTracks.map((track, index) => `
                    <div class="track-item ${index === this.currentTrackIndex ? 'active' : ''}" data-index="${this.tracks.indexOf(track)}">
                        <div class="track-number">${this.tracks.indexOf(track) + 1}</div>
                        <div class="track-info">
                            <div class="track-title">${track.title}</div>
                            <div class="track-artist">${track.artist}</div>
                        </div>
                    </div>
                `).join('');
                
                // Add click handlers to track items
                this.libraryContent.querySelectorAll('.track-item').forEach(item => {
                    item.addEventListener('click', () => {
                        const index = parseInt(item.dataset.index);
                        this.playTrack(index);
                    });
                });
            }
            
            filterLibrary() {
                const query = this.searchInput.value.toLowerCase();
                if (query === '') {
                    this.filteredTracks = [...this.tracks];
                } else {
                    this.filteredTracks = this.tracks.filter(track => 
                        track.title.toLowerCase().includes(query) || 
                        track.artist.toLowerCase().includes(query) ||
                        track.album.toLowerCase().includes(query)
                    );
                }
                this.renderLibrary();
            }
            
            playTrack(index) {
                if (index < 0 || index >= this.tracks.length) return;
                
                this.currentTrackIndex = index;
                const track = this.tracks[index];
                
                // Update active track in library
                this.libraryContent.querySelectorAll('.track-item').forEach(item => {
                    item.classList.remove('active');
                });
                
                const activeItem = this.libraryContent.querySelector(`.track-item[data-index="${index}"]`);
                if (activeItem) {
                    activeItem.classList.add('active');
                }
                
                // Update player UI
                this.trackTitle.textContent = track.title;
                this.trackArtist.textContent = track.artist;
                this.trackAlbum.textContent = track.album;
                
                if (track.image) {
                    this.coverImage.src = track.image;
                } else {
                    this.coverImage.src = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyMDAgMjAwIiBmaWxsPSJub25lIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iIzMzMyIvPjx0ZXh0IHg9IjEwMCIgeT0iMTAwIiBkb21pbmFudC1iYXNlbGluZT0ibWlkZGxlIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxs="#666" font-family="Arial, sans-serif" font-size="24">No Image</text></svg>';
                }
                
                // Load and play audio
                this.audioPlayer.src = track.filename;
                this.audioPlayer.load();
                
                if (this.hasUserInteracted) {
                    this.audioPlayer.play().then(() => {
                        this.isPlaying = true;
                        this.updatePlayPauseUI();
                    }).catch(error => {
                        console.error('Playback error:', error);
                    });
                }
                
                this.updateDocumentTitle();
            }
            
            togglePlay() {
                if (this.currentTrackIndex === -1 && this.tracks.length > 0) {
                    this.playTrack(0);
                    return;
                }
                
                if (this.audioPlayer.paused) {
                    this.audioPlayer.play().then(() => {
                        this.isPlaying = true;
                        this.updatePlayPauseUI();
                    }).catch(error => {
                        console.error('Playback error:', error);
                    });
                } else {
                    this.audioPlayer.pause();
                    this.isPlaying = false;
                    this.updatePlayPauseUI();
                }
            }
            
            updatePlayPauseUI() {
                if (this.isPlaying) {
                    this.playIcon.style.display = 'none';
                    this.pauseIcon.style.display = 'block';
                } else {
                    this.playIcon.style.display = 'block';
                    this.pauseIcon.style.display = 'none';
                }
            }
            
            nextTrack() {
                if (this.tracks.length === 0) return;
                
                let nextIndex = this.currentTrackIndex + 1;
                if (nextIndex >= this.tracks.length) {
                    nextIndex = 0; // Loop back to the beginning
                }
                
                this.playTrack(nextIndex);
            }
            
            previousTrack() {
                if (this.tracks.length === 0) return;
                
                let prevIndex = this.currentTrackIndex - 1;
                if (prevIndex < 0) {
                    prevIndex = this.tracks.length - 1; // Loop to the end
                }
                
                this.playTrack(prevIndex);
            }
            
            setVolume(volume) {
                this.audioPlayer.volume = volume;
                localStorage.setItem('jriPlayerVolume', volume);
            }
            
            updateProgress() {
                if (this.audioPlayer.duration) {
                    const progress = (this.audioPlayer.currentTime / this.audioPlayer.duration) * 100;
                    this.progressBar.style.width = `${progress}%`;
                    this.currentTimeDisplay.textContent = this.formatTime(this.audioPlayer.currentTime);
                }
            }
            
            updateTimeDisplay() {
                if (this.audioPlayer.duration) {
                    this.totalTimeDisplay.textContent = this.formatTime(this.audioPlayer.duration);
                }
            }
            
            formatTime(seconds) {
                if (isNaN(seconds)) return '0:00';
                seconds = Math.floor(seconds);
                const minutes = Math.floor(seconds / 60);
                seconds = seconds % 60;
                return `${minutes}:${seconds.toString().padStart(2, '0')}`;
            }
            
            seek(e) {
                if (this.audioPlayer.duration) {
                    const rect = this.progressContainer.getBoundingClientRect();
                    const percent = (e.clientX - rect.left) / rect.width;
                    this.audioPlayer.currentTime = percent * this.audioPlayer.duration;
                }
            }
            
            updateDocumentTitle() {
                if (this.tracks.length > 0 && this.currentTrackIndex >= 0) {
                    const track = this.tracks[this.currentTrackIndex];
                    document.title = `${this.isPlaying ? '' : ''} ${track.title} - ${track.artist} | Jri Player`;
                } else {
                    document.title = 'Jri Music Player';
                }
            }
            
            toggleTheme() {
                document.body.classList.toggle('dark-mode');
                const isDark = document.body.classList.contains('dark-mode');
                this.themeToggle.textContent = isDark ? 'Light Mode' : 'Dark Mode';
                localStorage.setItem('jriPlayerDarkMode', isDark);
            }
            
            handleKeyboardShortcuts(e) {
                if (e.target.tagName === 'INPUT') return;
                
                switch(e.code) {
                    case 'Space':
                        e.preventDefault();
                        this.togglePlay();
                        break;
                    case 'ArrowLeft':
                        e.preventDefault();
                        this.audioPlayer.currentTime = Math.max(0, this.audioPlayer.currentTime - 5);
                        break;
                    case 'ArrowRight':
                        e.preventDefault();
                        this.audioPlayer.currentTime = Math.min(this.audioPlayer.duration, this.audioPlayer.currentTime + 5);
                        break;
                    case 'KeyN':
                        e.preventDefault();
                        this.nextTrack();
                        break;
                    case 'KeyP':
                        e.preventDefault();
                        this.previousTrack();
                        break;
                }
            }
            
            showError(message) {
                this.libraryContent.innerHTML = `<div class="error-message">${message}</div>`;
            }
        }
        
        // Initialize player when DOM is loaded
        document.addEventListener('DOMContentLoaded', () => {
            new JriMusicPlayer();
        });
    </script>
</body>
</html>
EOF

    echo "✅ Created optimized player.html for GitHub Pages"
}

# Function to setup GitHub Pages
setup_github_pages() {
    echo "📖 Setting up GitHub Pages..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not in a git repository. Please run this script in your git repository."
        exit 1
    fi
    
    # Add all files in site directory
    git add "$SITE_DIR/"
    
    # Check if there are changes to commit
    if git diff --staged --quiet; then
        echo "ℹ️ No changes to commit"
    else
        git commit -m "🚀 Update Jri Radio GitHub Pages site
        
- Updated file count: $(cat $FILECOUNT_FILE) files
- Refreshed metadata for all tracks
- Updated on: $(cat $DATE_FILE)"
        
        echo "✅ Committed changes to git"
    fi
    
    # Push to remote (assumes origin exists)
    if git remote get-url origin > /dev/null 2>&1; then
        git push origin main 2>/dev/null || git push origin master 2>/dev/null || echo "⚠️ Push failed - please push manually"
        echo "✅ Pushed to remote repository"
    else
        echo "⚠️ No remote 'origin' found. Please add a remote and push manually."
    fi
}

# Main execution
main() {
    echo "Starting Jri Radio GitHub Pages Publisher & Optimizer v1.0"
    echo "============================================================"
    
    check_dependencies
    count_files
    
    # Only proceed if files were found
    if [ "$(cat $FILECOUNT_FILE)" -gt 0 ]; then
        extract_metadata
        get_commit_date
        create_radio_html
        create_player_html
        setup_github_pages
        
        echo ""
        echo "🎉 SUCCESS! Jri Radio GitHub Pages site has been updated!"
        echo "============================================================"
        echo "📊 Total files processed: $(cat $FILECOUNT_FILE)"
        echo "📅 Last update: $(cat $DATE_FILE)"
        echo "📁 Site files created in: $SITE_DIR/"
        echo ""
        echo "Next steps:"
        echo "Only do this if you haven't done it already!"
        echo "1. Enable GitHub Pages in your repository settings"
        echo "2. Set source to 'Deploy from a branch' and select 'main' (or 'master') branch, /site folder"
        echo "3. Your Jri Radio site will be available at your GitHub Pages URL"
        echo ""
        echo "Note: .jlres3 files are loaded directly from the repository using GitHub's raw content URLs"
    else
        echo "❌ No .jlres3 files found. Please ensure your music files are in the repository."
        exit 1
    fi
}

# Run main function
main "$@"
