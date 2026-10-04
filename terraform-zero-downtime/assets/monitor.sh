#!/usr/bin/env bash
# Live view (optional, for a second terminal tab): one line per streak.
#
# Requests are grouped per second. Seconds that look the same (every request
# answered, by the same versions) are folded into one line, which is updated
# in place for as long as the streak lasts. A second with failed requests is
# never folded: it gets its own line, inside a block that closes with the
# length of the outage (measured like `score` does: first to last failure).
LOG="${LOG:-/root/lab/traffic.log}"

tty=0; [ -t 1 ] && tty=1                 # only a terminal can redraw a line in place
red='' off=''
if [ "$tty" = 1 ] && [ -z "${NO_COLOR:-}" ]; then red=$'\e[31m' off=$'\e[0m'; fi

sec='' ok=0 fail=0 codes=''              # the second being collected ...
declare -A vers=()                       # ... and the versions that answered in it
s_from='' s_to='' s_ok=0 s_vers=''       # the open streak of clean seconds
line=''                                  # its line, as currently shown
failing=0 f_count=0 f_first='' f_last='' # the current run of failed requests

duration() {  # seconds -> 45s, 3m20s, 1h05m (result in $dur)
  if   [ "$1" -lt 60 ];   then printf -v dur '%ds' "$1"
  elif [ "$1" -lt 3600 ]; then printf -v dur '%dm%02ds' $(($1 / 60)) $(($1 % 60))
  else                         printf -v dur '%dh%02dm' $(($1 / 3600)) $(($1 % 3600 / 60)); fi
}

show() {      # draw the open streak; on a terminal the line overwrites itself
  local t; printf -v t '%(%T)T' "$s_from"
  duration $((s_to - s_from + 1))
  printf -v line '%-8s %7s %6d %7d  %s' "$t" "$dur" "$s_ok" 0 "$s_vers"
  [ "$tty" = 0 ] || printf '\r> %s\e[K' "$line"
}

freeze() {    # the open streak is over: its line stays on screen as it is
  [ -n "$s_from" ] || return 0
  if [ "$tty" = 1 ]; then printf '\r  %s\e[K\n' "$line"; else printf '  %s\n' "$line"; fi
  s_from=''
}

close_second() {
  local v=- t ms n=requests
  [ "${#vers[@]}" -eq 0 ] || v=$(printf 'v%s\n' "${!vers[@]}" | sort -V | paste -sd, -)

  if [ "$fail" -eq 0 ]; then
    if [ "$failing" = 1 ]; then          # first clean second after an outage
      ms=$((f_last - f_first + 150))     # +100 ms like score, +50 to round
      [ "$f_count" -ne 1 ] || n=request
      printf '%s└ recovered: %d failed %s over %d.%d s%s\n' \
        "$red" "$f_count" "$n" $((ms / 1000)) $((ms % 1000 / 100)) "$off"
      failing=0 f_count=0 f_first=''
    fi
    if [ -n "$s_from" ] && [ "$v" = "$s_vers" ]; then
      s_to=$sec s_ok=$((s_ok + ok))      # nothing changed: fold into the open line
    else
      freeze                             # other versions are answering: new line
      s_from=$sec s_to=$sec s_ok=$ok s_vers=$v
    fi
    show
  else
    freeze
    [ "$failing" = 1 ] || printf '%s┌ requests are failing%s\n' "$red" "$off"
    failing=1
    printf -v t '%(%T)T' "$sec"
    printf '%s│ %-8s %7s %6d %7d  %-10s %s%s\n' "$red" "$t" 1s "$ok" "$fail" "$v" "$codes" "$off"
  fi
  ok=0 fail=0 codes='' vers=()
}

trap 'freeze; exit 0' INT TERM
[ -e "$LOG" ] || echo "Waiting for $LOG (is the traffic generator running?)"
printf '  %-8s %7s %6s %7s  %s\n' SINCE FOR OK FAILED VERSIONS

while read -r ts code ver; do
  s=${ts%%.*}
  case $s in '' | *[!0-9]*) continue ;; esac  # not a log line
  [ -n "$code" ] || continue
  [ -z "$sec" ] || [ "$s" = "$sec" ] || close_second
  sec=$s
  if [ "$code" = 200 ]; then
    ok=$((ok + 1))
    [ "$ver" = - ] || vers[$ver]=1
  else
    fail=$((fail + 1)) f_count=$((f_count + 1))
    frac=${ts#"$s"}; frac=${frac#.}000   # milliseconds, for the length of the outage
    f_last=$((s * 1000 + 10#${frac:0:3}))
    [ -n "$f_first" ] || f_first=$f_last
    case $code in 000) code='no answer' ;; *) code="HTTP $code" ;; esac
    case ", $codes," in *", $code,"*) ;; *) codes=${codes:+$codes, }$code ;; esac
  fi
done < <(tail -n 0 -F "$LOG" 2>/dev/null)
freeze
