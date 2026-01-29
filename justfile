# Documentation commands

# Build the documentation
doc-build:
    cd doc && mdbook build

# Watch and serve the documentation with live reload
doc-dev:
    cd doc && mdbook watch --open

# Clean the documentation build
doc-clean:
    rm -rf doc/book
