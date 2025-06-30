export const accountNameRegex = /^[a-z1-5.]{1,12}$/;

export function isValidVaultaName(name) {
    return accountNameRegex.test(name.trim());
}