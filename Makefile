local:
	mkdir -p tmp
	npx antora --version
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-local.yml \
		2>&1 | tee tmp/local-build.log 2>&1

remote:
	mkdir -p tmp
	npm ci
	npx antora --version
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-remote.yml \
		2>&1 | tee tmp/remote-build.log 2>&1

mcm-local:
	mkdir -p tmp
	ln -sf antora-yml/antora-mcm.yml ./versions/latest/antora.yml
	ln -sf antora-yml/antora-mcm.yml ./versions/v2.12/antora.yml
	npx antora --version
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-mcm-local.yml \
		2>&1 | tee tmp/mcm-local-build.log 2>&1
	rm -rf build/site/rancher-mcm/latest/zh/
	ln -sf antora-yml/antora-product.yml ./versions/latest/antora.yml
	rm -rf build/site/rancher-mcm/v2.12/zh/
	ln -sf antora-yml/antora-product.yml ./versions/v2.12/antora.yml

mcm-remote:
	mkdir -p tmp
	npm ci
	npx antora --version
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-mcm-remote.yml \
		2>&1 | tee tmp/mcm-remote-build.log 2>&1

clean:
	rm -rf build

environment:
	npm ci

preview:
	npx http-server build/site -c-1
