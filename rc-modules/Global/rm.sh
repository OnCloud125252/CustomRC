# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Symbols
CHECKMARK='\xE2\x9C\x94'
ROCKET='\xF0\x9F\x9A\x80'
CROSSMARK='\xE2\x9C\x98'
HOURGLASS='\xE2\x8C\x9B'

function rm() {
  echo -e "\n${YELLOW}SAFETY ALERT: ${BLUE}rm${NC} command has been disabled to prevent accidental data loss.${NC}\n"
  echo -e "Alternative"
  echo -e "- ${BLUE}trash $* ${NC} (Use trash command, ${GREEN}restorable${NC})"
  echo -e "- ${BLUE}command rm $* ${NC} (Override protection, ${RED}permanent deletion${NC})"
}