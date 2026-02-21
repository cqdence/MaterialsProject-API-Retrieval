#!/bin/bash

# ── Colors ────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  Materials Project Exporter — Setup"
echo "========================================"
echo ""

# ── Step 1: Xcode Command Line Tools ─────────────────────────
# Required on macOS for git, compilers, and Homebrew
echo "[1/5] Checking Xcode Command Line Tools..."

if xcode-select -p &>/dev/null; then
    echo -e "${GREEN}Already installed.${NC}"
else
    echo -e "${YELLOW}Not found. Installing Xcode Command Line Tools...${NC}"
    echo "    A pop-up window will appear — click Install and wait for it to finish."
    echo "    Then press Enter here to continue."
    echo ""
    xcode-select --install 2>/dev/null
    read -p "    Press Enter once the Xcode install is complete: "
    if ! xcode-select -p &>/dev/null; then
        echo -e "${RED}ERROR: Xcode Command Line Tools still not detected.${NC}"
        echo "Please install them manually, then re-run this script."
        exit 1
    fi
    echo -e "${GREEN}Xcode Command Line Tools installed.${NC}"
fi
echo ""

# ── Step 2: Homebrew ─────────────────────────────────────────
echo "[2/5] Checking Homebrew..."

if command -v brew &>/dev/null; then
    echo -e "${GREEN}Already installed: $(brew --version | head -1)${NC}"
else
    echo -e "${YELLOW}Not found. Installing Homebrew...${NC}"
    echo "    (You may be asked for your Mac login password — this is normal)"
    echo ""
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Homebrew installation failed.${NC}"
        exit 1
    fi

    # Add Homebrew to PATH for this session (Apple Silicon uses /opt/homebrew,
    # Intel Macs use /usr/local)
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        # Also add to shell profile so it persists after reboot
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    echo -e "${GREEN}Homebrew installed.${NC}"
fi
echo ""

# ── Step 3: Python 3 ─────────────────────────────────────────
echo "[3/5] Checking Python 3..."

# Prefer the Homebrew python3 if present, otherwise fall back to system
if command -v python3 &>/dev/null; then
    PYTHON=python3
elif command -v python &>/dev/null && python --version 2>&1 | grep -q "Python 3"; then
    PYTHON=python
else
    PYTHON=""
fi

# Check version is 3.9+
if [ -n "$PYTHON" ]; then
    PYVER=$($PYTHON -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    MAJOR=$(echo "$PYVER" | cut -d. -f1)
    MINOR=$(echo "$PYVER" | cut -d. -f2)
    if [ "$MAJOR" -lt 3 ] || { [ "$MAJOR" -eq 3 ] && [ "$MINOR" -lt 9 ]; }; then
        echo -e "${YELLOW}Found Python $PYVER, but 3.9+ is required. Installing newer version...${NC}"
        PYTHON=""
    fi
fi

if [ -z "$PYTHON" ]; then
    echo -e "${YELLOW}Installing Python 3 via Homebrew...${NC}"
    brew install python3
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Python 3 installation failed.${NC}"
        exit 1
    fi
    PYTHON=python3
fi

PYTHON_VERSION=$($PYTHON --version 2>&1)
echo -e "${GREEN}Using: $PYTHON_VERSION${NC}"
echo ""

# ── Step 4: Virtual environment ───────────────────────────────
echo "[4/5] Setting up virtual environment..."

if [ -d "venv" ]; then
    echo -e "${YELLOW}Already exists, skipping.${NC}"
else
    $PYTHON -m venv venv
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Failed to create virtual environment.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Virtual environment created.${NC}"
fi
echo ""

# ── Step 5: Python packages ───────────────────────────────────
echo "[5/5] Installing Python packages..."
echo -e "    ${CYAN}mp-api, pymatgen, pandas, emmet-core${NC}"
echo "    (This can take 1-2 minutes the first time)"
echo ""

source venv/bin/activate

pip install --upgrade pip --quiet

pip install -r requirements.txt

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Package installation failed.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}All packages installed.${NC}"
echo ""

# ── Make run script executable ────────────────────────────────
chmod +x run.sh

# ── Done ──────────────────────────────────────────────────────
echo "========================================"
echo -e "${GREEN}  Setup complete!${NC}"
echo "========================================"
echo ""
echo "To export electronic structure data, run:"
echo ""
echo -e "    ${YELLOW}bash run.sh${NC}"
echo ""
echo "It will ask you for your API key and material ID."
echo ""
