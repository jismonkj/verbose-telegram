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
    echo "Current branch: $$CURRENT_BRANCH"; \
	git diff --name-only | grep '.go$$' > ./unit-tests/changed_files.txt
	@echo "<--- changed files -->"
	@cat ./unit-tests/changed_files.txt
	@echo "<-------------------->\n"

# Target to find unique packages
unique-packages:
	@awk -F"/" '{OFS="/"; $$(NF)=""; print}' ./unit-tests/changed_files.txt | sort | uniq > ./unit-tests/packages.txt

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

# Phony target to run everything
.PHONY: sanity changed-files unique-packages code-coverage code-coverage-on-changes summarize-coverage
