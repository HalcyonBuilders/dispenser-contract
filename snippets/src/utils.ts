export const wait = (ms: number): void => {
    const date = Date.now();
    let currentDate: number;
    do {
        currentDate = Date.now();
    } while (currentDate - date < ms);
};

export interface IObjectInfo {
    id: string
    type: string
}
