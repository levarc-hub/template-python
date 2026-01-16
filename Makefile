.PHONY: verify test hook lint check-build precommit release version-inject docker-build chlog

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

version-inject:
	@echo "🚀 Injecting version, commit sha and date into version.py"
	@echo "VERSION = '$(VERSION)'" > $(SRC_FOLDER)/version.py
	@echo "COMMIT = '$(COMMIT)'" >> $(SRC_FOLDER)/version.py
	@echo "BUILD_DATE = '$(BUILD_DATE)'" >> $(SRC_FOLDER)/version.py

docker-build:
	docker buildx build \
		--label version=$(VERSION) \
		--label commit=$(COMMIT) \
		--label build_date=$(BUILD_DATE) \
		--label repo=https://github.com/$(REPO) \
		--label registry=ghcr.io/$(REPO) \
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
