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
	git diff --name-only main workflow-1st-run | grep '.go$$' > ./unit-tests/changed_files.txt
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
# find the repo name from go.mod
	@MODULE_PATH=$$(cat go.mod | grep '^module' | awk '{print $$2}'); \
	for pkg in $$(cat ./unit-tests/affected_packages.txt); do \
	  go list -f '{{.ImportPath}}:{{.Deps}}' ./... | grep $$pkg | awk -F ':' '{print $$1}'; \
	done | sort | uniq | sed "s|$$MODULE_PATH||" > ./unit-tests/dependent_packages.txt

# Target to run tests for the unique packages
code-coverage-on-changes: dependent-packages
	@while read -r pkg; do \
		echo "Running tests for package: $$pkg"; \
		pkg_profile=$$(echo $${pkg} | sed 's/[\/\\]/_/g'); \
		go test -v -coverpkg=./... -covermode=set -coverprofile=./unit-tests/profiles/$$pkg_profile.cov ./$$pkg; \
	done < ./unit-tests/dependent_packages.txt

# Target to merge coverage profiles
merge-coverage:
# While appending coverages, there may be duplicates
# awk command is used for deduplicating the list 
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
