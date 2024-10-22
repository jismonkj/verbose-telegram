.PHONY: code-coverage, print-total-coverage

code-coverage:
	@mkdir -p ./coverage
	@go test -v -coverpkg=./... -covermode=set -coverprofile=./coverage/unit.cov ./...
	@cat ./coverage/unit.cov
print-total-coverage:
	@go tool cover -func ./coverage/unit.cov | grep total | grep -Eo '[0-9]+\.[0-9]+'