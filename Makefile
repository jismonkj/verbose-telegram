.PHONY: prep-coverage

prep-coverage:
	@mkdir -p ./coverage
	@mkdir -p ./coverage/profiles
code-coverage:
	@go test -v -coverpkg=./... -covermode=set -coverprofile=./coverage/unit.cov ./...
	@cat ./coverage/unit.cov
# pkg-coverage: prep-coverage
# 	@pkg_profile=$$(echo $${pkg} | sed 's/[\/\\]/_/g'); \
# 	go test -v -coverpkg=./... -covermode=set -coverprofile=./coverage/profiles/$${pkg_profile}.cov ./${pkg}

# Target to get changed Go files
changed-files: prep-coverage
    echo "Current branch: $$CURRENT_BRANCH"; \
	git diff --name-only | grep '.go$$' > ./coverage/changed_files.txt
	@echo "<--- changed files -->"
	@cat ./coverage/changed_files.txt
	@echo "<-------------------->\n"

# Target to find unique packages
unique-packages:
	@awk -F"/" '{OFS="/"; $$(NF)=""; print}' ./coverage/changed_files.txt | sort | uniq > ./coverage/packages.txt

# Target to run tests for the unique packages
code-coverage-on-changes: unique-packages
	@while read -r pkg; do \
        echo "Running tests for package: $$pkg"; \
		pkg_profile=$$(echo $${pkg} | sed 's/[\/\\]/_/g'); \
        go test -v -coverpkg=./... -covermode=set -coverprofile=./coverage/profiles/$$pkg_profile.cov ./$$pkg; \
    done < ./coverage/packages.txt

# Target to merge coverage profiles
merge-coverage:
	@if ls ./coverage/profiles/*.cov 1> /dev/null 2>&1; then \
        echo 'mode: set' > ./coverage/unit.cov; \
        tail -q -n +2 ./coverage/profiles/*.cov >> ./coverage/unit.cov; \
    else \
        echo "No coverage files found"; \
        exit 0; \
    fi

# Target to summarize and print total coverage
summarize-coverage: merge-coverage
	@if [ -s ./coverage/unit.cov ]; then \
        echo "\nTotal code coverage: "; \
        go tool cover -func ./coverage/unit.cov | grep total | grep -Eo '[0-9]+\.[0-9]+'; \
    else \
        echo "No coverage to summarize"; \
    fi

# Phony target to run everything
.PHONY: sanity changed-files unique-packages code-coverage code-coverage-on-changes summarize-coverage
