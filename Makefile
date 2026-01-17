TARGETS := $(shell grep -E '^[a-zA-Z_-]+:' Makefile | cut -d':' -f1)
.PHONY: $(TARGETS)

SRC_FOLDER := src
verify:
	@echo "🔍 Verifying Python environment..."
	@python3.14 --version
	@pip --version
	@pip check
	@echo "✅ Environment verification complete."

lint:
	@echo "🔍 Linting with ruff and mypy..."
	@ruff check $(SRC_FOLDER)/ --exit-zero
	@mypy $(SRC_FOLDER)/ --ignore-missing-imports
	@yamllint .github/workflows

test:
	@echo "🧪 Running tests..."
	@pytest tests/ --disable-warnings --maxfail=1 
	@echo "✅ Tests completed."

check-build:
	@echo "🧱 Checking Python build integrity..."
	@python -m compileall -q $(SRC_FOLDER)/
	@python -m pip check

precommit:
	bash ./scripts/hook.sh

BUMP_TYPE ?= patch

release:
	@echo "🚀 Releasing version bump..."
	bash scripts/bump.sh $(BUMP_TYPE)

REPO := levarc-hub/python-try
VERSION := $(shell git tag --sort=-v:refname | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$$' | head -n 1)
COMMIT := $(shell git rev-parse --short HEAD)
BUILD_DATE := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

live:
	python src/server.py

docker-build:
	docker buildx build \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg REPO=$(REPO) \
		-t ghcr.io/$(REPO):$(VERSION) .
	docker run -p 8080:8080 ghcr.io/$(REPO):$(VERSION)

CHLOG_LENGTH ?= 20
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
VERSION := $(shell git describe --tags --abbrev=0)

chlog:
	@printf "# Changelog for $(VERSION)\n" > CHANGELOG.md
	@printf "## Date: $(shell date '+%Y-%m-%d')\n\n" >> CHANGELOG.md
	@rm -f .chlog-seen

	@echo "\n### ✨ Features" >> CHANGELOG.md
	@git log -n $(CHLOG_LENGTH) --grep="^feat" --pretty=format:"- %h %d %s (%ad)" --date=relative \
	| tee -a CHANGELOG.md | cut -d' ' -f2 >> .chlog-seen
	@echo "" >> CHANGELOG.md

	@echo "\n### 🐛 Fixes" >> CHANGELOG.md
	@git log -n $(CHLOG_LENGTH) --grep="^fix" --pretty=format:"- %h %d %s (%ad)" --date=relative \
	| tee -a CHANGELOG.md | cut -d' ' -f2 >> .chlog-seen
	@echo "" >> CHANGELOG.md

	@echo "\n### 🧹 Chores & Refactors" >> CHANGELOG.md
	@git log -n $(CHLOG_LENGTH) --grep="^chore\|^refactor" --pretty=format:"- %h %d %s (%ad)" --date=relative \
	| tee -a CHANGELOG.md | cut -d' ' -f2 >> .chlog-seen
	@echo "" >> CHANGELOG.md

	@echo "\n### 📌 Other Commits" >> CHANGELOG.md
	@git log -n $(CHLOG_LENGTH) --pretty=format:"- %h %d %s (%ad)" --date=relative | while read line; do \
	  hash=$$(echo $$line | cut -d' ' -f2); \
	  grep -q $$hash .chlog-seen || echo "$$line" >> CHANGELOG.md; \
	done
	@echo "" >> CHANGELOG.md

	@sed -i -E \
		-e 's/HEAD -> [^,)]+,? ?//g' \
		-e 's/origin\/[^,)]+,? ?//g' \
		-e 's/HEAD,? ?//g' \
		-e 's/origin\/HEAD,? ?//g' \
		-e 's/ ,/,/g' \
		-e 's/, \)/)/g' \
		CHANGELOG.md

	@rm -f .chlog-seen
	@cat CHANGELOG.md
