export const ModalOutputModule = {
    outputText: null,
    outputTextModal: null,
    overlayTextBox: null,

    init() {
        this.outputText = document.getElementById('outputText');
        this.outputTextModal = document.getElementById('outputTextModal');
        this.overlayTextBox = document.getElementById('overlayTextBox');

        document.getElementById('closeOutputBtn').onclick = () => this.closeModal();
        document.getElementById('copyOutputBtn').onclick = () => this.copyOutput();
    },

    showModal(text, height = '5em') {
        this.outputText.value = text;
        this.outputText.style.height = height;
        this.outputTextModal.style.display = 'block';
        this.overlayTextBox.style.display = 'block';
    },

    closeModal() {
        this.outputTextModal.style.display = 'none';
        this.overlayTextBox.style.display = 'none';
    },

    copyOutput() {
        const textarea = this.outputText;
        textarea.select();
        textarea.setSelectionRange(0, 99999);
        document.execCommand('copy');
        alert('Copied to clipboard!');
    },

    fetchAndDisplay(url, modalHeight, options = { method: 'POST' }) {
        fetch(url, options)
            .then(response => response.json())
            .then(data => {
                if (data.output) {
                    this.showModal(data.output, modalHeight);
                } else {
                    const text = JSON.stringify(data, null, 2) || 'Unknown error';
                    this.showModal("Error:\n" + text);
                }
            })
            .catch(error => {
                this.showModal("Error calling server: " + error);
            });
    }
};