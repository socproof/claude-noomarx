#!/bin/bash

set -e

ENV_FILE=".env"

echo "=== Loading Telegram MCP Session Initializer ==="

# 1. Check for Go installation first
if ! command -v go &> /dev/null; then
    echo "❌ Error: Go (Golang) is not installed."
    echo "Please install it using 'brew install go' (Mac) or from golang.org"
    exit 1
fi

# 2. Install or update telegram-mcp CLI tool
if ! command -v telegram-mcp &> /dev/null; then
    echo "📥 telegram-mcp tool not found. Installing via 'go install'..."

    go install github.com/chaindead/telegram-mcp@latest

    GOPATH_BIN="$(go env GOPATH)/bin"
    export PATH="$PATH:$GOPATH_BIN"
fi

# 3. Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: $ENV_FILE file not found in the current directory."
    echo "Please create a .env file with the following variables:"
    echo "telegram_API_ID=\"your_api_id\""
    echo "telegram_API_HASH=\"your_api_hash\""
    echo "phone_number=\"your_phone_number\""
    echo "telegram_2FA_PASSWORD=\"your_password_if_enabled\""
    exit 1
fi

# 4. Source the .env file safely
set -a
source "$ENV_FILE"
set +a

# 5. Validate mandatory variables
missing_vars=()
[ -z "$telegram_API_ID" ] && missing_vars+=("telegram_API_ID")
[ -z "$telegram_API_HASH" ] && missing_vars+=("telegram_API_HASH")
[ -z "$phone_number" ] && missing_vars+=("phone_number")

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "❌ Error: Missing mandatory variables in $ENV_FILE:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

# 6. Execute authentication command based on 2FA presence
if [ -n "$telegram_2FA_PASSWORD" ]; then
    echo "🚀 Launching authentication with 2FA password..."
    telegram-mcp auth \
        --app-id "$telegram_API_ID" \
        --api-hash "$telegram_API_HASH" \
        --phone "$phone_number" \
        --password "$telegram_2FA_PASSWORD"
else
    echo "🚀 Launching standard authentication..."
    telegram-mcp auth \
        --app-id "$telegram_API_ID" \
        --api-hash "$telegram_API_HASH" \
        --phone "$phone_number"
fi

echo "✅ Session initialized successfully!"