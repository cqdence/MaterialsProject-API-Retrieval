#!/bin/bash

# ── Colors ────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  Materials Project Exporter"
echo "========================================"
echo ""

# ── Check setup has been run ──────────────────────────────────
if [ ! -d "venv" ]; then
    echo -e "${RED}ERROR: Setup has not been run yet.${NC}"
    echo ""
    echo "Please run setup first:"
    echo "    bash setup.sh"
    echo ""
    exit 1
fi

source venv/bin/activate

# ── API Key ───────────────────────────────────────────────────
CONFIG_FILE=".api_key"

if [ -f "$CONFIG_FILE" ]; then
    SAVED_KEY=$(cat "$CONFIG_FILE")
    echo -e "${CYAN}Saved API key found.${NC}"
    read -p "Use saved API key? (Y/n): " USE_SAVED
    USE_SAVED=${USE_SAVED:-Y}
    if [[ "$USE_SAVED" =~ ^[Yy]$ ]]; then
        API_KEY="$SAVED_KEY"
    else
        read -p "Enter your Materials Project API key: " API_KEY
        echo "$API_KEY" > "$CONFIG_FILE"
        echo -e "${GREEN}API key saved for next time.${NC}"
    fi
else
    echo "Your API key can be found at: https://next-gen.materialsproject.org/api"
    echo ""
    read -p "Enter your Materials Project API key: " API_KEY
    if [ -z "$API_KEY" ]; then
        echo -e "${RED}ERROR: API key cannot be empty.${NC}"
        exit 1
    fi
    echo ""
    read -p "Save API key for next time? (Y/n): " SAVE_KEY
    SAVE_KEY=${SAVE_KEY:-Y}
    if [[ "$SAVE_KEY" =~ ^[Yy]$ ]]; then
        echo "$API_KEY" > "$CONFIG_FILE"
        echo -e "${GREEN}API key saved.${NC}"
    fi
fi

echo ""

# ── Material IDs ──────────────────────────────────────────────
echo "Enter the Material ID(s) you want to export."
echo -e "${CYAN}You can find the ID on the Materials Project website — it looks like: mp-149${NC}"
echo "To export multiple materials, separate them with spaces (e.g. mp-149 mp-1059103)"
echo ""
read -p "Material ID(s): " MP_IDS_INPUT

if [ -z "$MP_IDS_INPUT" ]; then
    echo -e "${RED}ERROR: At least one material ID is required.${NC}"
    exit 1
fi

# ── Path Type ─────────────────────────────────────────────────
echo ""
echo "K-path convention options:"
echo "  1) latimer_munro       (default, recommended)"
echo "  2) setyawan_curtarolo"
echo "  3) hinuma"
echo ""
read -p "Choose a path type [1/2/3] (press Enter for default): " PATH_CHOICE
PATH_CHOICE=${PATH_CHOICE:-1}

case "$PATH_CHOICE" in
    1|"") PATH_TYPE="latimer_munro" ;;
    2)    PATH_TYPE="setyawan_curtarolo" ;;
    3)    PATH_TYPE="hinuma" ;;
    *)    PATH_TYPE="latimer_munro" ;;
esac

echo -e "${GREEN}Using path type: $PATH_TYPE${NC}"
echo ""

# ── Run for each material ─────────────────────────────────────
echo "========================================"
echo ""

for MP_ID in $MP_IDS_INPUT; do
    echo -e "${CYAN}Processing $MP_ID...${NC}"
    echo ""
    python mp_electronic_structure.py \
        --api_key "$API_KEY" \
        --mp_id "$MP_ID" \
        --path_type "$PATH_TYPE"
done

# ── Done ──────────────────────────────────────────────────────
echo "========================================"
echo -e "${GREEN}  All done! Your files are in the Exports/ folder.${NC}"
echo "========================================"
echo ""
