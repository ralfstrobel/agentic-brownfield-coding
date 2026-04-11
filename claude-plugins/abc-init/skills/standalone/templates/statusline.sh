#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
CONTEXT_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

LIMIT_5H_USED=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
LIMIT_5H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
LIMIT_7D_USED=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
LIMIT_7D_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

colorPercentage() {
    local val="$1" yellow="$2" red="$3"
    if [ "$val" -gt "$red" ] 2>/dev/null; then
        printf "\033[31m%s%%\033[0m\n" "$val"
    elif [ "$val" -gt "$yellow" ] 2>/dev/null; then
        printf "\033[33m%s%%\033[0m\n" "$val"
    else
        echo "${val}%"
    fi
}

LIMITS_OUTPUT=""
if [ -n "$LIMIT_5H_USED" ]; then
    LIMITS_OUTPUT="$(colorPercentage "$LIMIT_5H_USED" 70 90)"
    [ -n "$LIMIT_5H_RESET" ] && LIMITS_OUTPUT="${LIMITS_OUTPUT} limit until $(date -d @"$LIMIT_5H_RESET" +%H:%M 2>/dev/null || date -r "$LIMIT_5H_RESET" +%H:%M 2>/dev/null)"
fi
if [ -n "$LIMIT_7D_USED" ]; then
    PART="$(colorPercentage "$LIMIT_7D_USED" 70 90)"
    [ -n "$LIMIT_7D_RESET" ] && PART="${PART} limit until $(date -d @"$LIMIT_7D_RESET" +"%a %H:%M" 2>/dev/null || date -r "$LIMIT_7D_RESET" +"%a %H:%M" 2>/dev/null)"
    LIMITS_OUTPUT="${LIMITS_OUTPUT:+$LIMITS_OUTPUT | }$PART"
fi

CONTEXT_OUTPUT="$(colorPercentage "$CONTEXT_USED" 50 70)"

printf "[%s] %s context%s\n" "$MODEL" "$CONTEXT_OUTPUT" "${LIMITS_OUTPUT:+ | $LIMITS_OUTPUT}"
