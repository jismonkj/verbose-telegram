.PHONY: prep-coverage

prep-coverage:
	@mkdir -p ./unit-tests
	@mkdir -p ./unit-tests/profiles
code-coverage:
	@go test -v -coverpkg=./... -covermode=set -coverprofile=./unit-tests/unit.cov ./...
	@cat ./unit-tests/unit.cov
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
			go list -f '{{.ImportPath}}' $$(dirname $$file); \
		done | sort | uniq > ./unit-tests/affected_packages.txt; \
	fi

# Find dependent packages
dependent-packages: affected-packages
	@if [ -s ./unit-tests/affected_packages.txt ]; then \
		for pkg in $$(cat ./unit-tests/affected_packages.txt); do \
			go list -f '{{.ImportPath}}:{{.Deps}}' ./... | grep $$pkg | awk -F ':' '{print $$1}'; \
		done | sort | uniq > ./unit-tests/dependent_packages.txt; \
	fi

# Target to find unique packages
unique-packages: dependent-packages
	@awk -F"/" '{OFS="/"; $$(NF)=""; print}' ./unit-tests/dependent_packages.txt | sort | uniq > ./unit-tests/packages.txt

# Target to run tests for the unique packages
code-coverage-on-changes: unique-packages
	@while read -r pkg; do \
		echo "Running tests for package: $$pkg"; \
		pkg_profile=$$(echo $${pkg} | sed 's/[\/\\]/_/g'); \
		go test -v -coverpkg=./... -covermode=set -coverprofile=./unit-tests/profiles/$$pkg_profile.cov ./$$pkg; \
	done < ./unit-tests/packages.txt

# Target to merge coverage profiles
merge-coverage:
	@if ls ./unit-tests/profiles/*.cov 1> /dev/null 2>&1; then \
		echo 'mode: set' > ./unit-tests/unit.cov; \
		tail -q -n +2 ./unit-tests/profiles/*.cov >> ./unit-tests/unit.cov; \
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
