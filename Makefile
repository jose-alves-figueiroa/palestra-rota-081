.PHONY: build notes clear

build:
	latexmk src/main.tex

notes:
	latexmk -aux-directory=build-notes src/main-notes.tex

clear:
	latexmk -C
	rm -rf dist build build-notes .gitversion.tex .build-datetime