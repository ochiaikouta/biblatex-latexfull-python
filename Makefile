TEXFILE=main
LATEX=latexmk
LATEXFLAGS=-lualatex -shell-escape

all:
	$(LATEX) $(LATEXFLAGS) $(TEXFILE).tex

bib:
	biber $(TEXFILE)

clean:
	$(LATEX) -c

fullclean:
	$(LATEX) -C
	rm -f $(TEXFILE).bbl $(TEXFILE).bcf $(TEXFILE).run.xml

watch:
	$(LATEX) -pvc $(LATEXFLAGS) $(TEXFILE).tex

view:
	xdg-open $(TEXFILE).pdf

# help message
help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  all        - build PDF using latexmk + LuaLaTeX"
	@echo "  bib        - run biber only"
	@echo "  clean      - clean temporary files"
	@echo "  fullclean  - clean all generated files"
	@echo "  watch      - auto build on file change (preview continuously)"
	@echo "  view       - open resulting PDF"
