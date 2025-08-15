#!/bin/bash

export JEKYLL_VERSION=3.8.6
# with Clean up (--rm) and future posts
#docker run --rm --volume="$PWD:/srv/jekyll" -p:4000:4000  -it jekyll/jekyll:$JEKYLL_VERSION jekyll serve --future

# No clean up, with future posts
docker run --volume="$PWD:/srv/jekyll" -p:4000:4000  -it jekyll/jekyll:$JEKYLL_VERSION jekyll serve --future
