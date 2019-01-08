#!/bin/bash

export JEKYLL_VERSION=3.8
# with Clean up (--rm)
#docker run --rm --volume="$PWD:/srv/jekyll" -p:4000:4000  -it jekyll/jekyll:$JEKYLL_VERSION jekyll serve

# No clean up
docker run --volume="$PWD:/srv/jekyll" -p:4000:4000  -it jekyll/jekyll:$JEKYLL_VERSION jekyll serve
