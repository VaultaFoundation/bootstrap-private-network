export function fetchVersion(endpoint, elementId) {
    fetch(endpoint)
        .then(response => response.json())
        .then(data => {
            const output = data.output?.trim() || 'Error fetching';
            document.getElementById(elementId).innerText = output;
        })
        .catch(error => {
            document.getElementById(elementId).innerText = 'Error';
            console.error(`Error fetching from ${endpoint}:`, error);
        });
}

export function fetchChainInfo() {
    fetch('/chain/get_info')
        .then(response => response.json())
        .then(data => {
            document.getElementById('nodeosVersion').innerText = data.server_full_version_string || 'Unknown';
            document.getElementById('libNum').innerText = data.last_irreversible_block_num || 'Unknown';
            document.getElementById('headProducer').innerText = data.head_block_producer || 'Unknown';
            document.getElementById('chainId').innerText = data.chain_id || 'Unknown';
        })
        .catch(error => {
            document.getElementById('nodeosVersion').innerText = 'Error';
            document.getElementById('libNum').innerText = 'Error';
            document.getElementById('headProducer').innerText = 'Error';
            document.getElementById('chainId').innerText = 'Error';
            console.error('Error fetching chain info:', error);
        });
}

export function initVersionInfo() {
    fetchVersion('/service/cdt_version', 'cdtVersion');
    fetchChainInfo();
}