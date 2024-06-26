import fs from 'fs/promises';
import os from 'os';
import path from 'path';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { execa } from 'execa';
import { glob } from 'glob';
import { compare } from 'alphanumeric-sort';
import pAll from 'p-all';

(async () => {
    let argumentParser = yargs(hideBin(process.argv))
        .version(false)
        .option('help', {
            alias: 'h', describe: 'Show help', type: 'boolean',
        })
        .option('output', {
            alias: 'o', describe: 'Output document path', type: 'string', demandOption: true,
        })
        .option('input', {
            describe: 'Input photo files to include', type: 'string', array: true,
        });
    const args = await argumentParser.parse();

    let input = args.input;
    if (!Array.isArray(input) || input.length === 0) {
        throw new Error('Empty input');
    }
    input = (await Promise.all(input.map(async (file) => {
        return (await glob(file)).sort(compare);
    }))).flat();

    const output = args.output;
    if (path.extname(output).slice(1) !== 'pdf') {
        throw new Error('Output must be PDF');
    }

    const concurrencyLimit = Math.max(os.cpus.length - 1, 1);

    const photos: { width: number, height: number, path: string }[] = await pAll(input.map((file) => async () => {
        const program = await execa('magick', ['identify', '-format', '%wx%h', file]);
        let resolution = program.stdout.split('x').map((el) => Number.parseInt(el)) as [number, number];
        return {
            path: file,
            width: resolution[0],
            height: resolution[1],
        };
    }), { concurrency: concurrencyLimit });

    const targetResolution = {
        width: Math.min(...photos.map((el) => el.width)),
        height: Math.min(...photos.map((el) => el.height)),
    };

    const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'tmp'));

    const tmpFiles = await pAll(input.map((file) => async () => {
        const tmpFile = path.join(tmpDir, path.basename(file, path.extname(file))) + '.jpg';
        await execa('magick', [file, '-quality', '90', '-resize', `${targetResolution.width}x${targetResolution.height}!`, tmpFile]);
        return tmpFile;
    }), { concurrency: concurrencyLimit });

    await execa('magick', [...tmpFiles, output]);
    await fs.rm(tmpDir, { force: true, recursive: true });
})();
