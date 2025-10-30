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
	ln -sf antora-yml/antora-mcm.yml ./versions/v2.12/antora.yml
	npx antora --version
	trap 'echo "Cleaning up .adoc files..."; git restore ./versions/v2.12/modules/en/pages' EXIT; \
	\
	echo "Preprocessing .adoc files to remove :page-languages:..." ; \
	find ./versions/v2.12/modules/en/pages -name "*.adoc" -exec sed -i '/^:page-languages: \[en, zh\]/d' {} + ; \
	\
	echo "Running Antora build..." ; \
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-mcm-local.yml \
		2>&1 | tee tmp/mcm-local-build.log 2>&1
	rm -rf build/site-mcm/rancher-mcm/v2.12/zh/
	ln -sf antora-yml/antora-product.yml ./versions/v2.12/antora.yml

mcm-remote:
	mkdir -p tmp
	ln -sf antora-yml/antora-mcm.yml ./versions/v2.12/antora.yml
	npm ci
	npx antora --version
	trap 'echo "Cleaning up .adoc files..."; git restore ./versions/v2.12/modules/en/pages' EXIT; \
	\
	echo "Preprocessing .adoc files to remove :page-languages:..." ; \
	find ./versions/v2.12/modules/en/pages -name "*.adoc" -exec sed -i '/^:page-languages: \[en, zh\]/d' {} + ; \
	\
	echo "Running Antora build..." ; \
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-mcm-remote.yml \
		2>&1 | tee tmp/mcm-remote-build.log 2>&1
	rm -rf build/site-mcm/rancher-mcm/v2.12/zh/
	ln -sf antora-yml/antora-product.yml ./versions/v2.12/antora.yml

clean:
	rm -rf build

environment:
	npm ci

preview:
	npx http-server build/site -c-1

preview-mcm:
	npx http-server build/site-mcm -c-1
