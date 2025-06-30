import { ModalOutputModule } from './basicModule.js';

document.addEventListener('DOMContentLoaded', () => {
    ModalOutputModule.init();

    document.getElementById('createKeysBtn').onclick = () => {
        ModalOutputModule.fetchAndDisplay('/service/create_keys');
    };

    document.getElementById('getBalanceBtn').onclick = () => {
        const username = prompt('Enter username for balance:');
        if (username) {
            ModalOutputModule.fetchAndDisplay('/service/get_balance', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userName: username })
            });
        }
    };

    document.getElementById('getAccountBtn').onclick = () => {
        const username = prompt('Enter username for account info:');
        if (username) {
            ModalOutputModule.fetchAndDisplay('/service/get_account', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userName: username })
            });
        }
    };
});