#!/bin/zsh

echo "Making HTML"

for i in index download license beta-tester; do
	echo "  Compiling $i.md"
	multimarkdown $i.md >$i.html
done

cd docs/
for i in custom-locations index repo-format plugins install-manifests; do
	echo "  Compiling docs/$i.md"
	multimarkdown $i.md >$i.html
done

cd ../

cd ../stable/

zip -r example-repo.zip example-repo

cd ../beta

zip -r example-repo.zip example-repo