#!/bin/bash

# Path to the directory to monitor
DIRECTORY="content"

# Function to run a command and prepend date and time to its output
run_with_date() {
    "$@" | while IFS= read -r line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $line"
    done
}

# Load environment variables from a .env file
function loadEnv {
  if [ -f .env ]; then
    export $(cat .env | sed 's/#.*//g' | xargs)
  fi

  # Set default values for some variables if they are not set
  if [ -z "${DEBOUNCE_TIME}" ]; then
    DEBOUNCE_TIME=2 # Default debounce time in seconds
  fi

  # Check for critical variables and throw an error if not set
  if [ -z "${RSYNC_TARGET}" ]; then
    run_with_date echo "Error: RSYNC_TARGET is not set in the .env file."
    exit 1
  fi
}

# Function to build the site
function buildWithQuartz {
  run_with_date echo "Building the site with Quartz..."
  cd /quartz
  run_with_date npx quartz build
  # Return to the original directory
  cd -
}

# Function to run when a change is detected
function onChange {
  # Comparing the public folder size as an extremely basic check to see if the public folder has changed
  preBuildPublicSize=$(du -s -b "public" | cut -f1)
  buildWithQuartz
  postBuildPublicSize=$(du -s -b "public" | cut -f1)
  if [ "$preBuildPublicSize" != "$postBuildPublicSize" ]; then
    # run_with_date rsync -rv -e "ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no" public/ $RSYNC_TARGET
    mkdir test
    run_with_date rsync -rv public/ $RSYNC_TARGET
  else 
    run_with_date echo "No changes detected in public folder. Skipping rsync."
  fi
}

# Load environment variables and set defaults
loadEnv
# Monitor the directory for changes and handle debouncing

while true; do
  if inotifywait -r -e modify,create,delete,move --timefmt '%Y-%m-%d %H:%M:%S' --format '%T' $DIRECTORY --timeout $((DEBOUNCE_TIME * 1000)); then
    run_with_date echo "Change detected in $DIRECTORY. Waiting for $DEBOUNCE_TIME seconds to collect more changes..."
    # Change order if you want to build immediately and then debounce. However, removing it entirely may cause issues.
    sleep $DEBOUNCE_TIME
    onChange
  fi
done