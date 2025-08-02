JL = julia --project

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'
	for case in basic circuit_simulation qec; do \
		echo "Instantiating $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.instantiate()"; \
	done

update:
	$(JL) -e 'using Pkg; Pkg.update()'
	for case in basic circuit_simulation qec; do \
		echo "Updating $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.update()"; \
	done

notebook:
	$(JL) -e "using IJulia; notebook(dir=\"examples/$${case}\", detached=true)"

.PHONY: init update notebook