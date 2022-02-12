%.md: %.Rmd
	Rscript -e "rmarkdown::render(\"$(basename $(@)).Rmd\", rmarkdown::md_document(preserve_yaml = TRUE, variant = 'markdown_github', pandoc_args = '--atx-headers'))"  ## atx headers ensures headers are all like #, ##, etc. Shouldn't be necessary as of pandoc >= 2.11.2
## markdown_github ensures that the 'r' tag is put on chunks, so code coloring/highlighting will be done when html is produced.

clean:
	rm -f index.md sql.md R-and-Python.md db-management.md 

