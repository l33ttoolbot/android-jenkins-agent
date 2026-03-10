#!/bin/bash
# Build Script für Android Jenkins Agent
# Taggt das Image automatisch mit Version und Datum

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/VERSION"

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Version lesen
if [ -f "$VERSION_FILE" ]; then
    VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
    echo -e "${RED}❌ VERSION file not found!${NC}"
    exit 1
fi

# Datum
DATE=$(date +%Y%m%d)
DATE_FULL=$(date +%Y-%m-%d)

# Git Commit SHA (kurz)
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "local")

# Image Name
IMAGE_NAME="${IMAGE_NAME:-android-jenkins-agent}"

# Tags generieren
TAGS=(
    "$VERSION-$DATE"          # z.B. 1.0.0-20260310
    "$VERSION"                # z.B. 1.0.0
    "latest"                  # immer latest
)

# Argumente parsen
INCREMENT=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        patch|minor|major)
            INCREMENT="$1"
            shift
            ;;
        --push|-p)
            PUSH=true
            shift
            ;;
        --registry|-r)
            REGISTRY="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [patch|minor|major] [--push] [--registry REGISTRY]"
            echo ""
            echo "Options:"
            echo "  patch       Increment patch version (1.0.0 → 1.0.1)"
            echo "  minor       Increment minor version (1.0.0 → 1.1.0)"
            echo "  major       Increment major version (1.0.0 → 2.0.0)"
            echo "  --push      Push to registry after build"
            echo "  --registry  Docker registry (default: ghcr.io/l33ttoolbot)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Version increment
if [ -n "$INCREMENT" ]; then
    IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
    case "$INCREMENT" in
        patch) VERSION="$MAJOR.$MINOR.$((PATCH + 1))" ;;
        minor) VERSION="$MAJOR.$((MINOR + 1)).0" ;;
        major) VERSION="$((MAJOR + 1)).0.0" ;;
    esac
    echo "$VERSION" > "$VERSION_FILE"
    echo -e "${BLUE}📦 Version bumped to: $VERSION${NC}"
fi

# Build Info
echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  Android Jenkins Agent Build${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""
echo -e "  Version:    ${GREEN}$VERSION${NC}"
echo -e "  Date:       ${GREEN}$DATE_FULL${NC}"
echo -e "  Git SHA:    ${GREEN}$GIT_SHA${NC}"
echo -e "  Image:      ${GREEN}$IMAGE_NAME${NC}"
echo ""
echo -e "  Tags:"
for TAG in "${TAGS[@]}"; do
    echo -e "    - ${YELLOW}$IMAGE_NAME:$TAG${NC}"
done
echo ""

# Docker Build
echo -e "${BLUE}🔨 Building Docker image...${NC}"
docker build -t "$IMAGE_NAME:$VERSION-$DATE" \
             -t "$IMAGE_NAME:$VERSION" \
             -t "$IMAGE_NAME:latest" \
             --build-arg BUILD_DATE="$DATE_FULL" \
             --build-arg VCS_REF="$GIT_SHA" \
             --build-arg VERSION="$VERSION" \
             "$SCRIPT_DIR"

# Build Check
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo -e "  Test with:"
    echo -e "    ${YELLOW}docker run --rm $IMAGE_NAME:latest java -version${NC}"
    echo -e "    ${YELLOW}docker run --rm $IMAGE_NAME:latest gradle --version${NC}"
    echo ""
    
    # Images auflisten
    echo -e "${BLUE}📦 Built images:${NC}"
    docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

# Push to Registry
if [ "$PUSH" = "true" ]; then
    REGISTRY="${REGISTRY:-ghcr.io/l33ttoolbot}"
    echo ""
    echo -e "${BLUE}📤 Pushing to registry: $REGISTRY${NC}"
    
    for TAG in "${TAGS[@]}"; do
        docker tag "$IMAGE_NAME:$TAG" "$REGISTRY/$IMAGE_NAME:$TAG"
        docker push "$REGISTRY/$IMAGE_NAME:$TAG"
    done
    
    echo -e "${GREEN}✅ Pushed to $REGISTRY${NC}"
fi

# Commit Version file if changed
if [ -n "$INCREMENT" ]; then
    echo ""
    echo -e "${YELLOW}📝 Don't forget to commit VERSION file:${NC}"
    echo -e "    git add VERSION && git commit -m 'chore: bump version to $VERSION'"
fi