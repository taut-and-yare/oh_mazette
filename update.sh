#!/bin/bash

set -e  # Exit immediately if a command fails

# Get the current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Prevent running on master/main
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    echo "❌ Safety check failed: Do not run this script on '$CURRENT_BRANCH' branch."
    exit 1
fi

echo "🛠️  Updating dependencies..."

# Define paths for requirements files
REQ_DIR="requirements"
REQ_FILE="$REQ_DIR/requirements.txt"
REQ_IN_FILE="$REQ_DIR/requirements.in"

# Ensure the requirements directory exists
if [ ! -d "$REQ_DIR" ]; then
    echo "❌ Error: '$REQ_DIR' directory not found!"
    exit 1
fi

# Ensure the requirements.in file exists
if [ ! -f "$REQ_IN_FILE" ]; then
    echo "❌ Error: '$REQ_IN_FILE' not found!"
    exit 1
fi

# Save a copy of the old requirements.txt for comparison
cp "$REQ_FILE" "$REQ_DIR/requirements.old.txt" || touch "$REQ_DIR/requirements.old.txt"

# Compile new dependencies with upgrade
pip-compile --upgrade --output-file="$REQ_FILE" "$REQ_IN_FILE"

# Check if requirements.txt changed
if diff -q "$REQ_DIR/requirements.old.txt" "$REQ_FILE" > /dev/null; then
    echo "✅ No changes in dependencies. Skipping commit."
    rm "$REQ_DIR/requirements.old.txt"
    exit 0  # Exit script without continuing to build/tests
fi

# Extract changed dependencies
CHANGES=$(diff -u "$REQ_DIR/requirements.old.txt" "$REQ_FILE" | grep -E '^\+' | tail -n +2 | cut -c 2-)
rm "$REQ_DIR/requirements.old.txt"

echo "📦 Changes detected in dependencies:"
echo "$CHANGES"

echo "📦 Building the Docker stack..."
docker compose -f docker-compose.local.yml build

echo "🧪 Running tests..."
if docker compose -f docker-compose.local.yml run --rm django pytest -s; then
    echo "✅ Tests passed! Committing changes..."

    git add "$REQ_FILE"
    COMMIT_MSG="Update dependencies: $(echo "$CHANGES" | tr '\n' ' ') ✅"

    git commit -m "$COMMIT_MSG"
    git push

    echo "🚀 Changes pushed successfully!"
else
    echo "❌ Tests failed! Fix errors before committing."
    exit 1  # Stop execution if tests fail
fi
