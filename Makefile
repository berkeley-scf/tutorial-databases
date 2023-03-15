bigquery.md: bigquery.Rmd
	Rscript -e "rmarkdown::render(\"$(basename $(@)).Rmd\", rmarkdown::md_document(preserve_yaml = TRUE, variant = 'gfm', pandoc_args = '--markdown-headings=atx'))"
	sed -i "s/^myproject <- \".*\"/myproject <- \"some_project\"/" bigquery.*md
	sed -i "s/^user <- \".*\"/user <- \"user@berkeley.edu\"/" bigquery.*md

%.md: %.Rmd
	Rscript -e "rmarkdown::render(\"$(basename $(@)).Rmd\", rmarkdown::md_document(preserve_yaml = TRUE, variant = 'gfm', pandoc_args = '--markdown-headings=atx'))"  ## atx headers ensures headers are all like #, ##, etc. Shouldn't be necessary as of pandoc >= 2.11.2
## markdown_github ensures that the 'r' tag is put on chunks, so code coloring/highlighting will be done when html is produced.

clean:
	rm -f index.md sql.md R-and-Python.md db-management.md 

## NOTE: if want to protect my email/GCP account name, replace them in bigquery.{Rmd,md} before committing to repo.
