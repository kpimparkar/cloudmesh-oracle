package=oracle
UNAME=$(shell uname)
export ROOT_DIR=${PWD}/cloudmesh/rest/server
MONGOD=mongod --dbpath ~/.cloudmesh/data/db --bind_ip 127.0.0.1
VERSION=`head -1 VERSION`

define banner
	@echo
	@echo "###################################"
	@echo $(1)
	@echo "###################################"
endef

ifeq ($(UNAME),Darwin)
define terminal
	osascript -e 'tell application "Terminal" to do script "$(1)"'
endef
endif
ifeq ($(UNAME),Linux)
define terminal
	echo "Linux not yet supported, fix me"
endef
endif
ifeq ($(UNAME),Windows)
define terminal
	echo "Windows not yet supported, fix me"
endef
endif

list:
	$(call banner, "TARGETS")
	@grep '^[^#[:space:]].*:' Makefile


requirements:
	echo "cloudmesh-cmd5" > tmp.txt
	echo "cloudmesh-sys" >> tmp.txt
	echo "cloudmesh-inventory" >> tmp.txt
	echo "cloudmesh-configuration" >> tmp.txt
	echo "cloudmesh-cloud" >> tmp.txt
	pip-compile setup.py
	fgrep -v "# via" requirements.txt | fgrep -v "cloudmesh" >> tmp.txt
	mv tmp.txt requirements.txt
	git commit -m "update requirements" requirements.txt
	git push

setup:
	# brew update
	# brew install mongodb
	# brew install jq
	rm -rf ~/.cloudmesh/data/db
	mkdir -p ~/.cloudmesh/data/db

kill:
	killall mongod




mongo:
	$(call terminal, $(MONGOD))

source:
	pip install -e .
	cms help

test:
	$(call banner, "LIST SERVICE")
	curl -s -i http://127.0.0.1:5000 
	$(call banner, "LIST PROFILE")
	@curl -s http://127.0.0.1:5000/profile  | jq
	$(call banner, "LIST CLUSTER")
	@curl -s http://127.0.0.1:5000/cluster  | jq
	$(call banner, "LIST COMPUTER")
	@curl -s http://127.0.0.1:5000/computer  | jq
	$(call banner, "INSERT COMPUTER")
	curl -d '{"name": "myCLuster",	"label": "c0","ip": "127.0.0.1","memoryGB": 16}' -H 'Content-Type: application/json'  http://127.0.0.1:5000/computer  
	$(call banner, "LIST COMPUTER")
	@curl -s http://127.0.0.1:5000/computer  | jq


clean:
	rm -rf *.zip
	rm -rf *.egg-info
	rm -rf *.eggs
	rm -rf docs/build
	rm -rf build
	rm -rf dist
	find . -type d -name __pycache__ -delete
	find . -name '*.pyc' -delete
	find . -name '*.pye' -delete
	rm -rf .tox
	rm -f *.whl

install:
	cd ../common; pip install .
	cd ../cmd5; pip install .
	pip install .

######################################################################
# PYPI
######################################################################


twine:
	pip install -U twine

dist:
	python setup.py sdist bdist_wheel
	twine check dist/*

patch: clean
	$(call banner, "bbuild")
	bump2version --allow-dirty patch
	python setup.py sdist bdist_wheel
	# git push origin master --tags
	twine check dist/*
	twine upload --repository testpypi  dist/*
	$(call banner, "install")
	#sleep 10
	#pip install --index-url https://test.pypi.org/simple/ cloudmesh-$(package) -U

minor: clean
	$(call banner, "minor")
	bump2version minor --allow-dirty
	@cat VERSION
	@echo

release: clean
	$(call banner, "release")
	git tag "v$(VERSION)"
	git push origin master --tags
	python setup.py sdist bdist_wheel
	twine check dist/*
	twine upload --repository pypi dist/*
	$(call banner, "install")
	@cat VERSION
	@echo


dev:
	bump2version --new-version "$(VERSION)-dev0" part --allow-dirty
	bump2version patch --allow-dirty
	@cat VERSION
	@echo

reset:
	bump2version --new-version "4.0.0-dev0" part --allow-dirty

upload:
	twine check dist/*
	twine upload dist/*

pip:
	pip install --index-url https://test.pypi.org/simple/ cloudmesh-$(package) -U

#	    --extra-index-url https://test.pypi.org/simple

log:
	$(call banner, log)
	gitchangelog | fgrep -v ":dev:" | fgrep -v ":new:" > ChangeLog
	git commit -m "chg: dev: Update ChangeLog" ChangeLog
	git push