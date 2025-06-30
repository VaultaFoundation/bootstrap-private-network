import { ModalOutputModule } from './basicModule.js';

document.addEventListener('DOMContentLoaded', () => {
    ModalOutputModule.init();

    document.getElementById('createKeysBtn').onclick = () => {
        ModalOutputModule.fetchAndDisplay('/service/create_keys', '5em');
    };

    document.getElementById('getBalanceBtn').onclick = () => {
        const username = prompt('Enter username for balance:');
        if (username) {
            ModalOutputModule.fetchAndDisplay('/service/get_balance', '5em', {
                method: 'GET',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userName: username })
            });
        }
    };

    document.getElementById('getAccountBtn').onclick = () => {
        const username = prompt('Enter username for account info:');
        if (username) {
            ModalOutputModule.fetchAndDisplay('/service/get_account', '75em', {
                method: 'GET',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userName: username })
            });
        }
    };
    
    document.getElementById('getPowerUpBtn').onclick = () => {
        const username = prompt('Enter username for power up:');
        if (username) {
            ModalOutputModule.fetchAndDisplay('/service/powerup', '5em', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userName: username })
            });
        }
    };
    
    document.getElementById('getFaucetBtn').onclick = () => {
        const username = prompt('Enter username to send tokens:');
        if (username) {
            ModalOutputModule.fetchAndDisplay('/service/faucet', '5em', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userName: username })
            });
        }
    };
    
    document.getElementById('getHelloBtn').onclick = () => {
        ModalOutputModule.fetchAndDisplay('/service/hello', '10em');
    };
});