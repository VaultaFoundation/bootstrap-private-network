const KeysModule = {
    outputText: null,
    outputTextModal: null,
    overlayTextBox: null,
    

    init() {
        this.outputText = document.getElementById('outputText')
        this.outputTextModal = document.getElementById('outputTextModal')
        this.overlayTextBox = document.getElementById('overlayTextBox')
    
        document.getElementById('createKeysBtn').onclick = () => this.createKeys;
        document.getElementById('closeOutputBtn').onclick = () => this.closeModal;
        document.getElementById('copyOutputBtn').onclick = () => this.copyOutput;
    }

    createKeys() {
        fetch('/service/create_keys', { method: 'POST' })
            .then(response => response.json())
            .then(data => {
                if (data.output) {
                    this.showModal(data.output);
                } else {
                    this.showModal("Error:\n" + (data.error || "Unknown error"));
                }
            })
            .catch(error => {
                this.showModal("Error calling server: " + error);
            });
    }

    // PLAIN TEXT BOX MODAL HANDLERS
    showModal(text) {
        this.outputText.value = text;
        this.outputTextModal.style.display = 'block';
        this.overlayTextBox = 'block';
    }

    closeModal() {
        this.outputTextModal.style.display = 'none';
        this.overlayTextBox = 'none';
    }

    copyOutput() {
        const textarea = this.outputText;
        textarea.select();
        textarea.setSelectionRange(0, 99999); // For mobile compatibility
        document.execCommand('copy');
        alert('Copied to clipboard!');
    }
}

document.addEventListener('DOMContentLoaded', () => {
    KeysModule.init();
});
