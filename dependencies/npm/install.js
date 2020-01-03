#!/usr/bin/env node
"use strict"

const fs = require("fs")
const process = require("process")
const cp = require("child_process")

const fileContent = fs.readFileSync("package.json")
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

if ('dependencies' in fileJSON) {
    const dependencies = Object.keys(fileJSON['dependencies'])
    if (dependencies.length > 0) {
        console.err("Installing vanilla dependencies:")
        console.err(dependencies.join(', '))
        console.err()

        sh("npm install --global " + dependencies.map(el => `"${el}"`).join(' '), (err) => { console.err('Could not install all vanilla dependencies'); console.err(err); process.exit(1) })
    }
}

if ('devDependencies' in fileJSON) {
    const dependencies = Object.keys(fileJSON['devDependencies'])
    if (dependencies.length > 0) {
        console.err("Installingdev dependencies:")
        console.err(dependencies.join(', '))
        console.err()

        sh("npm install --global " + dependencies.map(el => `"${el}"`).join(' '), (err) => { console.err('Could not install all dev dependencies'); console.err(err); process.exit(1) })
    }
}

if ('peerDependencies' in fileJSON) {
    const dependencies = Object.keys(fileJSON['peerDependencies'])
    if (dependencies.length > 0) {
        console.err("Installingpeer dependencies:")
        console.err(dependencies.join(', '))
        console.err()

        sh("npm install --global " + dependencies.map(el => `"${el}"`).join(' '), (err) => { console.err('Could not install all peer dependencies'); console.err(err); process.exit(1) })
    }
}

if ('optionalDependencies' in fileJSON) {
    const dependencies = Object.keys(fileJSON['optionalDependencies'])
    if (dependencies.length > 0) {
        console.err("Installingoptional dependencies:")
        console.err(dependencies.join(', '))
        console.err()

        // optional dependencies can fail without the script failing as well, as they are "optional"
        sh("npm install --global " + dependencies.map(el => `"${el}"`).join(' '), (err) => { console.err('Some optional dependencies not installed'); console.err(err) })
    }
}
