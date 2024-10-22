.PHONY: prep-coverage

prep-coverage:
	@mkdir -p ./coverage
	@mkdir -p ./coverage/profiles
# code-coverage:
# 	@go test -v -coverpkg=./... -covermode=set -coverprofile=./coverage/unit.cov ./...
# 	@cat ./coverage/unit.cov
# pkg-coverage: prep-coverage
# 	@pkg_profile=$$(echo $${pkg} | sed 's/[\/\\]/_/g'); \
# 	go test -v -coverpkg=./... -covermode=set -coverprofile=./coverage/profiles/$${pkg_profile}.cov ./${pkg}

# Target to get changed Go files
changed-files: prep-coverage
	@git diff --name-only $(git merge-base origin/main HEAD) HEAD | grep '.go$$' > ./coverage/changed_files.txt
	@echo "<--- changed files -->"
	@cat ./coverage/changed_files.txt
	@echo "<-------------------->\n"

# Target to find unique packages
unique-packages: changed-files
	@awk -F"/" '{OFS="/"; $$(NF)=""; print}' ./coverage/changed_files.txt | sort | uniq > ./coverage/packages.txt

# Target to run tests for the unique packages
code-coverage: unique-packages
	@while read -r pkg; do \
        echo "Running tests for package: $$pkg"; \
		pkg_profile=$$(echo $${pkg} | sed 's/[\/\\]/_/g'); \
        go test -v -coverpkg=./... -covermode=set -coverprofile=./coverage/profiles/$$pkg_profile.cov ./$$pkg; \
    done < ./coverage/packages.txt

# Target to merge coverage profiles
merge-coverage:
	@echo 'mode: set' > ./coverage/merged.cov
	@tail -q -n +2 ./coverage/profiles/*.cov >> ./coverage/merged.cov

# Target to summarize and print total coverage
summarize-coverage: merge-coverage
	@echo "\nTotal code coverage: "
	@go tool cover -func ./coverage/merged.cov | grep total | grep -Eo '[0-9]+\.[0-9]+'

# Phony target to run everything
sanity: code-coverage summarize-coverage

.PHONY: sanity changed-files unique-packages code-coverage summarize-coverage
