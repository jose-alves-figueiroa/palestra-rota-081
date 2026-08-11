.PHONY: build clear

build:
	latexmk

clear:
	latexmk -C
	rm -rf dist build