# System Dependencies

> In this folder, I have group of packages that I use in my computes

## APT

```sh #apt
sudo apt-get install -y $(sed -E 's~(\s*)#(.*)~~' <'apt.txt' | grep -vE '^(\s*)$' | tr '\n' ' ')
```

## NPM

```sh #npm
npm install -g $(sed -E 's~(\s*)#(.*)~~' <'npm.txt' | grep -vE '^(\s*)$' | tr '\n' ' ')
```

## Pip

```sh #pip
pip install -r 'requirements.txt' # or pip3
```
