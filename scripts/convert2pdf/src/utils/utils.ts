
export function median(_numbers: number[]): number {
    if (_numbers.length === 0) {
        throw new RangeError('Cannot calculate the median of an empty array');
    }

    const numbers = [..._numbers].toSorted((left, right) => left - right);
    if (numbers.length % 2 === 0) {
        return (numbers[numbers.length / 2 - 1]! + numbers[numbers.length / 2]!) / 2;
    }

    return numbers[Math.floor(numbers.length / 2)]!;
}
