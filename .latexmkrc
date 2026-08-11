#!/usr/bin/env perl
$pdf_mode = 5;               # 5 = build PDF via xelatex (required by fontspec/metropolis)
$xelatex = 'xelatex -interaction=nonstopmode %O %S';
$clean_ext = 'nav snm vrb synctex.gz';
$out_dir = 'dist';           # final PDF only
$aux_dir = 'build';          # aux/log/toc/etc — kept out of dist
@default_files = ('src/main.tex');