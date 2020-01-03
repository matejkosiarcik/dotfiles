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
    installCommand += '--global '
}

if ('dependencies' in fileJSON) {
    const dependencies = Object.keys(fileJSON['dependencies'])
    if (dependencies.length > 0) {
        console.info("Installing vanilla dependencies:")
        console.info(dependencies.join(', '))
        console.info()

        sh(installCommand + dependencies.map(el => `"${el}"`).join(' '), (err) => { console.error('Could not install all vanilla dependencies'); console.error(err); process.exit(1) })
    }
}

if ('devDependencies' in fileJSON) {
    const dependencies = Object.keys(fileJSON['devDependencies'])
    if (dependencies.length > 0) {
        console.info("Installing dev dependencies:")
        console.info(dependencies.join(', '))
        console.info()

        sh(installCommand + dependencies.map(el => `"${el}"`).join(' '), (err) => { console.error('Could not install all dev dependencies'); console.error(err); process.exit(1) })
    }
}

if ('peerDependencies' in fileJSON) {
    const dependencies = Object.keys(fileJSON['peerDependencies'])
    if (dependencies.length > 0) {
        console.info("Installingpeer dependencies:")
        console.info(dependencies.join(', '))
        console.info()

        sh(installCommand + dependencies.map(el => `"${el}"`).join(' '), (err) => { console.error('Could not install all peer dependencies'); console.error(err); process.exit(1) })
    }
}

if ('optionalDependencies' in fileJSON) {
    const dependencies = Object.keys(fileJSON['optionalDependencies'])
    if (dependencies.length > 0) {
        console.info("Installingoptional dependencies:")
        console.info(dependencies.join(', '))
        console.info()

        // optional dependencies can fail without the script failing as well, as they are "optional"
        sh(installCommand + dependencies.map(el => `"${el}"`).join(' '), (err) => { console.error('Some optional dependencies not installed'); console.error(err) })
    }
}
