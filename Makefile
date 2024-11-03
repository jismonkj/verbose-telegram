# Define variables
BASE_PATH=github.com/jismonkj/verbose-telegram
PACKAGES_FILE=./unit-tests/dependent_packages.txt
COVERAGE_FILE=./unit-tests/unit.cov
TEMP_FILE=./unit-tests/temp.cov

.PHONY: prep-coverage

prep-coverage:
	@mkdir -p ./unit-tests
	@mkdir -p ./unit-tests/profiles
code-coverage:
	@go test -v -coverpkg=./... -covermode=set -coverprofile=./unit-tests/unit.cov ./...
	@go tool cover -func ./unit-tests/unit.cov | grep total
# pkg-coverage: prep-coverage
# 	@pkg_profile=$$(echo $${pkg} | sed 's/[\/\\]/_/g'); \
# 	go test -v -coverpkg=./... -covermode=set -coverprofile=./unit-tests/profiles/$${pkg_profile}.cov ./${pkg}

# Target to get changed Go files
changed-files: prep-coverage
	git diff --name-only main release | grep '.go$$' > ./unit-tests/changed_files.txt
	@echo "<--- changed files -->"
	@cat ./unit-tests/changed_files.txt
	@echo "<-------------------->\n"

# Find affected packages
affected-packages:
	@if [ -s ./unit-tests/changed_files.txt ]; then \
		for file in $$(cat ./unit-tests/changed_files.txt); do \
			go list -f '{{.ImportPath}}' ./$$(dirname $$file); \
		done | sort | uniq > ./unit-tests/affected_packages.txt; \
	fi

# Find dependent packages
dependent-packages: affected-packages
@MODULE_PATH=$$(cat go.mod | grep '^module' | awk '{print $$2}'); \
    PREV_DEPENDENT_PACKAGES="" && \
    CURRENT_DEPENDENT_PACKAGES=$$(cat ./unit-tests/affected_packages.txt) && \
    while [ "$$PREV_DEPENDENT_PACKAGES" != "$$CURRENT_DEPENDENT_PACKAGES" ]; do \
      PREV_DEPENDENT_PACKAGES=$$CURRENT_DEPENDENT_PACKAGES; \
      for pkg in $$CURRENT_DEPENDENT_PACKAGES; do \
        go list -f '{{.ImportPath}}:{{.Deps}}' ./... | grep $$pkg | awk -F ':' '{print $$1}' | sed "s|$$MODULE_PATH||"; \
      done | sort | uniq > ./unit-tests/new_dependent_packages.txt && \
      CURRENT_DEPENDENT_PACKAGES=$$(cat ./unit-tests/affected_packages.txt ./unit-tests/new_dependent_packages.txt | sort | uniq); \
    done && \
    echo $$CURRENT_DEPENDENT_PACKAGES > ./unit-tests/dependent_packages.txt

# Target to run tests for the unique packages
code-coverage-on-changes:
	@while read -r pkg; do \
		echo "Running tests for package: $$pkg"; \
		pkg_profile=$$(echo $${pkg} | sed 's/[\/\\]/_/g'); \
		go test -v -coverpkg=./... -covermode=set -coverprofile=./unit-tests/profiles/$$pkg_profile.cov ./$$pkg; \
	done < ./unit-tests/dependent_packages.txt

# Target to filter coverage file
filter-coverage:
    # Read the package path and construct the pattern
	@PATTERN=$$(awk '{print "^$(BASE_PATH)/" $$1 "/[^/]+\\.go"}' $(PACKAGES_FILE) | paste -s -d '|' -); \
    echo "Pattern: $$PATTERN"; \
    grep -v -E "$$PATTERN" $(COVERAGE_FILE) >> $(TEMP_FILE); \
    mv $(TEMP_FILE) $(COVERAGE_FILE)

# Target to merge coverage profiles
# While appending coverages, there may be duplicates
# awk command is used for deduplicating the list 
merge-coverage: filter-coverage
	@if ls ./unit-tests/profiles/*.cov 1> /dev/null 2>&1; then \
		# echo 'mode: set' > ./unit-tests/unit.cov; \
		tail -q -n +2 ./unit-tests/profiles/*.cov >> ./unit-tests/unit.cov; \
		awk '!seen[$$0]++' ./unit-tests/unit.cov > ./unit-tests/unit.cov.tmp && mv ./unit-tests/unit.cov.tmp ./unit-tests/unit.cov; \
	else \
		echo "No coverage files found"; \
		exit 0; \
	fi

# Target to summarize and print total coverage
summarize-coverage: merge-coverage
	@if [ -s ./unit-tests/unit.cov ]; then \
		echo "\nTotal code coverage: "; \
		go tool cover -func ./unit-tests/unit.cov | grep total | grep -Eo '[0-9]+\.[0-9]+'; \
	else \
		echo "No coverage to summarize"; \
	fi

.PHONY: changed-files affected-packages dependent-packages

# Phony target to run everything
.PHONY: sanity changed-files unique-packages code-coverage code-coverage-on-changes summarize-coverage
.PHONY: affected-packages dependent-packages
