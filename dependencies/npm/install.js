#!/usr/bin/env node
"use strict"

const fs = require("fs")
const process = require("process")
const cp = require("child_process")
const path = require("path")

const fileContent = fs.readFileSync(path.join(__dirname, 'package.json'))
const fileJSON = JSON.parse(fileContent)

async function sh(cmd, errorHandler) {
    return new Promise((resolve, reject) => {
        cp.exec(cmd, (err, stdout, stderr) => {
            if (err) {
                resolve({ stdout, stderr })
                errorHandler(err)
            } else {
                resolve({ stdout, stderr })
            }
        })
    })
}

let installCommand = 'npm install '
if (process.argv.length < 3 || process.argv[2] !== 'local') {
    // installation is global by default
    // if 3rd argument is "local", then local install is executed instead
    installCommand += '--global '
}

const dependencyTypes = {
    'vanilla': 'dependencies',
    'dev': 'devDependencies',
    'peer': 'peerDependencies',
    'optional': 'optionalDependencies',
}

const requiredDependencyCallback = (err) => {
    console.error(`Could not install all ${key} dependencies`)
    console.error(err)
    process.exit(1)
}

const optionalDependencyCallback = (err) => {
    console.error('Some optional dependencies not installed')
    console.error(err)
}

for (let key in dependencyTypes) {
    const jsonKey = dependencyTypes[key]
    if (jsonKey in fileJSON) {
        const dependencies = Object.keys(fileJSON[jsonKey])
        if (dependencies.length > 0) {
            console.info(`Installing ${key} dependencies:`)
            console.info(dependencies.join(', '))
            console.info()

            const callback = key === 'optional' ? optionalDependencyCallback : requiredDependencyCallback
            sh(installCommand + dependencies.map(el => `"${el}"`).join(' '), callback)
        }
    }
}
