#!/bin/bash

export JEKYLL_VERSION=3.8.6
# with Clean up (--rm)
#docker run --rm --volume="$PWD:/srv/jekyll" -p:4000:4000  -it jekyll/jekyll:$JEKYLL_VERSION jekyll build -t --incremental

# No clean up
docker run --volume="$PWD:/srv/jekyll" -it jekyll/jekyll:$JEKYLL_VERSION jekyll build -t --incremental
#!/bin/bash

rm lgallard.github.io/ -rf
git clone https://github.com/lgallard/lgallard.github.io.git
cp -r _site/* lgallard.github.io/
cd lgallard.github.io/
git add --all
git commit -m "`date`"
git push https://$GITTOKEN@github.com/lgallard/lgallard.github.io.git
cd ..
