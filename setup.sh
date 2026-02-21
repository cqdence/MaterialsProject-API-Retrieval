#!/bin/bash

# ── Colors ────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "========================================"
echo "  Materials Project Exporter — Setup"
echo "========================================"
echo ""

# ── Check for Python 3 ────────────────────────────────────────
echo "Checking for Python 3..."

if command -v python3 &>/dev/null; then
    PYTHON=python3
elif command -v python &>/dev/null && python --version 2>&1 | grep -q "Python 3"; then
    PYTHON=python
else
    echo -e "${RED}ERROR: Python 3 was not found.${NC}"
    echo ""
    echo "Please install Python 3 from https://www.python.org/downloads/"
    echo "Then re-run this script."
    exit 1
fi

PYTHON_VERSION=$($PYTHON --version 2>&1)
echo -e "${GREEN}Found: $PYTHON_VERSION${NC}"
echo ""

# ── Create virtual environment ────────────────────────────────
echo "Creating virtual environment..."

if [ -d "venv" ]; then
    echo -e "${YELLOW}Virtual environment already exists, skipping creation.${NC}"
else
    $PYTHON -m venv venv
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Failed to create virtual environment.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Virtual environment created.${NC}"
fi
echo ""

# ── Activate and install dependencies ─────────────────────────
echo "Installing dependencies (this may take a minute)..."
echo ""

source venv/bin/activate

pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to install dependencies.${NC}"
    exit 1
fi

echo -e "${GREEN}All dependencies installed.${NC}"
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
