.PHONY: build notes clear

build:
	latexmk src/main.tex

notes:
	latexmk src/main-notes.tex

clear:
	latexmk -C
	rm -rf dist build