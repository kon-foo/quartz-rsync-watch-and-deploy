#!/bin/bash

# Path to the directory to monitor
DIRECTORY="content"

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
    echo "Error: RSYNC_TARGET is not set in the .env file."
    exit 1
  fi
}

# Function to build the site
function buildWithQuartz {
  echo "Building the site with Quartz..."
  cd /quartz
  npx quartz build
  # Return to the original directory
  cd -
}

# Function to run when a change is detected
function onChange {
  # Comparing the public folder size as an extremely basic check to see if the public folder has changed
  preBuildPublicSize=$(du -s "public" | cut -f1)
  buildWithQuartz
  postBuildPublicSize=$(du -s "public" | cut -f1)
  if [ "$preBuildPublicSize" != "$postBuildPublicSize" ]; then
    rsync -rv -e "ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no" public/ $RSYNC_TARGET
  else 
    echo "No changes detected in public folder. Skipping rsync."
  fi
}

# Load environment variables and set defaults
loadEnv

# Monitor the directory for changes and handle debouncing
while true; do
  if inotifywait -r -e modify,create,delete,move --timefmt '%d/%m/%Y %H:%M' --format '%T' $DIRECTORY --timeout $((DEBOUNCE_TIME * 1000)); then
    echo "Change detected in $DIRECTORY. Waiting for $DEBOUNCE_TIME seconds to collect more changes..."
    # Change order if you want to build immediately and then debounce. However, removing it entirely may cause issues.
    sleep $DEBOUNCE_TIME
    onChange
  fi
done