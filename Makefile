JL = julia --project

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'

update:
	$(JL) -e 'using Pkg; Pkg.update()'

notebook:
	$(JL) -e "using IJulia; notebook(dir=\"examples/$${case}\", detached=true)"

pluto:
	$(JL) -e "using Pluto; Pluto.run(notebook=\"examples/$${case}/main.jl\")"

.PHONY: init update notebook