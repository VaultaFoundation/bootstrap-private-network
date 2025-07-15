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
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userName: username })
            });
        }
    };

    document.getElementById('getBalanceBtn').onclick = () => {
        const username = prompt('Enter username for balance:');
        if (username) {
            ModalOutputModule.fetchAndDisplay('/service/get_balance', 'auto', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ userName: username })
            }, (data) => {
                const rows = data.output.rows || [];
                if (rows.length === 0) return '<p>No balances found.</p>';
    
                let html = `<table style="width:100%; border-collapse:collapse; text-align:left;">
                    <thead>
                        <tr>
                            <th style="border-bottom: 1px solid #ccc; padding: 8px;">Balance</th>
                            <th style="border-bottom: 1px solid #ccc; padding: 8px;">Released</th>
                        </tr>
                    </thead>
                    <tbody>`;
    
                rows.forEach(row => {
                    html += `<tr>
                        <td style="padding: 8px;">${row.balance || '-'}</td>
                        <td style="padding: 8px;">${'released' in row ? row.released : '-'}</td>
                    </tr>`;
                });
    
                html += `</tbody></table>`;
                return html;
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