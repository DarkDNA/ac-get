#!/bin/zsh

echo "Making HTML"

for i in index download license; do
	echo "  Compiling $i.md"
	multimarkdown $i.md >$i.html
done

cd docs/
for i in custom-locations index repo-format plugins install-manifests; do
	echo "  Compiling docs/$i.md"
	multimarkdown $i.md >$i.html
done

cd ../

zip example-repo.zip -r example-repo/