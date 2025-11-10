#!/bin/bash

# Log Rotation Script for DNS Monitor
# Rotates log files daily, keeps 7 days of history

LOG_DIR="$HOME/Library/Logs"
DATE=$(date +%Y%m%d)
MAX_DAYS=7

# Function to rotate a log file
rotate_log() {
    local logfile="$1"
    
    if [[ ! -f "$logfile" ]]; then
        return
    fi
    
    # Only rotate if file has content
    if [[ -s "$logfile" ]]; then
        # Copy current log with date suffix
        cp "$logfile" "${logfile}.${DATE}"
        
        # Compress the rotated log
        gzip "${logfile}.${DATE}"
        
        # Truncate the original log
        > "$logfile"
        
        echo "$(date): Rotated $logfile"
    fi
}

# Rotate DNS monitor logs
rotate_log "$LOG_DIR/dns-monitor.log"
rotate_log "$LOG_DIR/dns-monitor-stdout.log"
rotate_log "$LOG_DIR/dns-monitor-stderr.log"

# Clean up old logs (older than MAX_DAYS)
find "$LOG_DIR" -name "dns-monitor*.log.*.gz" -mtime +$MAX_DAYS -delete
find "$LOG_DIR" -name "dns-logrotate*.log" -mtime +$MAX_DAYS -delete

echo "$(date): Log rotation complete"
