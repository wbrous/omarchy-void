nohup bash .local-build/build-iso-only.sh > .local-build/build-iso-only.log 2>&1 &
tail -f .local-build/build-iso.log

something like this.
