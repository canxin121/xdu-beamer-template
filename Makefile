ROOT ?= main.tex
OUTDIR ?= build
LATEXMK := latexmk -cd -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error -xelatex -outdir=$(OUTDIR) -auxdir=$(OUTDIR)

pdf:
	$(LATEXMK) $(ROOT)

clean:
	$(LATEXMK) -c $(ROOT)
	rm -rf $(OUTDIR)
	rm -f *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.nav *.out *.pdf *.run.xml *.snm *.synctex.gz *.toc *.xdv missfont.log

.PHONY: pdf clean
