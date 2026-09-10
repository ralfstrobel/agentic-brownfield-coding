#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
THINKING=$(echo "$input" | jq -r '.thinking.enabled // empty')
[ "$THINKING" = "true" ] && [ -n "$EFFORT" ] && MODEL="$MODEL $EFFORT"
CONTEXT_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

CACHE_OBSERVED=$(echo "$input" | jq -r '.prompt_cache.caching_observed // empty')
CACHE_WARM=$(echo "$input" | jq -r '.prompt_cache.warm // empty')
CACHE_EXPIRES=$(echo "$input" | jq -r '.prompt_cache.expires_at // empty')
CACHE_RECACHE=$(echo "$input" | jq -r '.prompt_cache | if (.cache_write_tokens // 0) > 0 then (.miss_recache_tokens // 0) * 100 / .cache_write_tokens else empty end' | cut -d. -f1)

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

CACHE_OUTPUT=""
if [ "$CACHE_OBSERVED" = "true" ] && [ -n "$CACHE_RECACHE" ]; then
    CACHE_OUTPUT="$(colorPercentage "$CACHE_RECACHE" 30 60) recache"
    if [ "$CACHE_WARM" = "true" ]; then
        [ -n "$CACHE_EXPIRES" ] && CACHE_OUTPUT="${CACHE_OUTPUT}, warm until $(date -d @"$CACHE_EXPIRES" +%H:%M 2>/dev/null || date -r "$CACHE_EXPIRES" +%H:%M 2>/dev/null)"
    else
        CACHE_OUTPUT="${CACHE_OUTPUT}$(printf ", \033[31mcold\033[0m")"
    fi
fi

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

if [ "$CONTEXT_SIZE" -ge 500000 ] 2>/dev/null; then
    CONTEXT_OUTPUT="$(colorPercentage "$CONTEXT_USED" 30 50)"
else
    CONTEXT_OUTPUT="$(colorPercentage "$CONTEXT_USED" 50 70)"
fi

printf "[%s] %s context%s%s\n" "$MODEL" "$CONTEXT_OUTPUT" "${CACHE_OUTPUT:+ | $CACHE_OUTPUT}" "${LIMITS_OUTPUT:+ | $LIMITS_OUTPUT}"
