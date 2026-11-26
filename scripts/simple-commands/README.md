# List of useful commands

Mirror an STL file:

```sh
admesh --yz-mirror --write-binary-stl='output.stl' 'input.stl'
```

Rotate an STL file:

```sh
admesh --x-rotate=90 --write-binary-stl='output.stl' 'input.stl'
```

Analyze codebase:

```sh
tokei '.' --hidden --output 'json' --exclude '.git' --exclude '*-lock.*' --exclude '*.lock' --exclude '*.lockb' --exclude 'npm-shrinkwrap.json' --exclude 'go.sum' | tokei-pie --output-html 'tokei.html'
```
