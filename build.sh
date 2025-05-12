#!/bin/bash
latexmk -lualatex -synctex=1 -interaction=nonstopmode -file-line-error main.tex
