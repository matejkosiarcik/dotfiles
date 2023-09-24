import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { execa } from 'execa';
import { median } from './utils/utils.js';

function printPhotos(photos: { file: string, width: number, height: number }[]) {
    const heading = {
        file: 'File',
        width: 'Width',
        height: 'Height',
    };

    let lines = [heading, ...photos.map((el) => ({
        file: el.file,
        width: el.width.toFixed(0),
        height: el.height.toFixed(0),
    }))];

    const maxFileLength = Math.max(...lines.map((el) => el.file.length));
    const maxWidthLength = Math.max(...lines.map((el) => el.width.length));
    const maxHeightLength = Math.max(...lines.map((el) => el.height.length));

    lines = lines.map((line) => ({
        file: line.file.padEnd(maxFileLength, ' '),
        width: line.width.padStart(maxWidthLength, ' '),
        height: line.height.padStart(maxHeightLength, ' '),
    }))

    console.log(`| ${lines[0].file} | ${lines[0].width} | ${lines[0].height} |`);
    console.log(`| ${lines[0].file.replace(/./g, '-')} | ${lines[0].width.replace(/./g, '-')} | ${lines[0].height.replace(/./g, '-')} |`);
    for (const line of lines.slice(1)) {
        console.log(`| ${line.file} | ${line.width} | ${line.height} |`);
    }
}

function printStatistics(photos: { file: string, width: number, height: number }[]) {
    // const stats = {
    //     width: {
    //         max: Math.max(...photos.map((el) => el.width)),
    //         min: Math.min(...photos.map((el) => el.width)),
    //         average: photos.map((el) => el.width).reduce((sum, el) => sum + el, 0) / photos.length,
    //         median: median(photos.map((el) => el.width)),
    //     },
    //     height: {
    //         max: Math.max(...photos.map((el) => el.height)),
    //         min: Math.min(...photos.map((el) => el.height)),
    //         average: photos.map((el) => el.height).reduce((sum, el) => sum + el, 0) / photos.length,
    //         median: median(photos.map((el) => el.height)),
    //     },
    // };

    let lines = [
        {
            type: 'Type',
            width: 'Width',
            height: 'Height',
        },
        {
            type: 'Min',
            width: Math.min(...photos.map((el) => el.width)),
            height: Math.min(...photos.map((el) => el.height)),
        },
        {
            type: 'Max',
            width: Math.max(...photos.map((el) => el.width)),
            height: Math.max(...photos.map((el) => el.height)),
        },
        {
            type: 'Average',
            width: photos.map((el) => el.width).reduce((sum, el) => sum + el, 0) / photos.length,
            height: photos.map((el) => el.height).reduce((sum, el) => sum + el, 0) / photos.length,
        },
        {
            type: 'Median',
            width: median(photos.map((el) => el.width)),
            height: median(photos.map((el) => el.height)),
        },
    ].map((line) => ({
        type: line.type,
        width: typeof line.width === 'string' ? line.width : line.width.toFixed(2),
        height: typeof line.height === 'string' ? line.height : line.height.toFixed(2),
    }))

    const maxTypeLength = Math.max(...lines.map((el) => el.type.length));
    const maxWidthLength = Math.max(...lines.map((el) => el.width.length));
    const maxHeightLength = Math.max(...lines.map((el) => el.height.length));

    lines = lines.map((line) => ({
        type: line.type.padEnd(maxTypeLength, ' '),
        width: line.width.padStart(maxWidthLength, ' ').replace(/\.00$/, '   '),
        height: line.height.padStart(maxHeightLength, ' ').replace(/\.00$/, '   '),
    }))

    console.log(`| ${lines[0].type} | ${lines[0].width} | ${lines[0].height} |`);
    console.log(`| ${lines[0].type.replace(/./g, '-')} | ${lines[0].width.replace(/./g, '-')} | ${lines[0].height.replace(/./g, '-')} |`);
    for (const line of lines.slice(1)) {
        console.log(`| ${line.type} | ${line.width} | ${line.height} |`);
    }
}

(async () => {
    let argumentParser = yargs(hideBin(process.argv))
        .version(false)
        .option('help', {
            alias: 'h', describe: 'Show help', type: 'boolean',
        })
        .option('input', {
            describe: 'Input photo files to include', type: 'string', array: true,
        });
    const args = await argumentParser.parse();

    const input = args.input;
    if (!Array.isArray(input) || input.length === 0) {
        throw new Error('Empty input');
    }

    const photos: { file: string, width: number, height: number }[] = await Promise.all(input.map(async (file) => {
        const program = await execa('magick', ['identify', '-format', '%wx%h', file]);
        let resolution = program.stdout.split('x').map((el) => Number.parseInt(el)) as [number, number];
        return {
            file: file,
            width: resolution[0],
            height: resolution[1],
        };
    }));

    printPhotos(photos);
    console.log();
    printStatistics(photos);
})();
