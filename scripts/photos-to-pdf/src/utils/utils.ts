
export function median(_numbers: number[]): number {
    const numbers = _numbers.map((el) => el).sort();
    if (numbers.length % 2 === 0) {
        return (numbers[numbers.length / 2 - 1] + numbers[numbers.length / 2]) / 2
    } else {
        return numbers[numbers.length / 2];
    }
}
