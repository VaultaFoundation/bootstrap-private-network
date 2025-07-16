export const ModalOutputModule = {
    outputText: null,
    outputTextModal: null,
    overlayTextBox: null,
    htmlContentBox: null,
    
    init() {
        this.outputText = document.getElementById('outputText');
        this.outputTextModal = document.getElementById('outputTextModal');
        this.overlayTextBox = document.getElementById('overlayTextBox');
        this.htmlContentBox = document.getElementById('htmlContentBox');

        document.getElementById('closeOutputBtn').onclick = () => this.closeModal();
        document.getElementById('copyOutputBtn').onclick = () => this.copyOutput();
    },

    showModal(text, height = '5em') {
        this.outputText.value = text;
        this.outputText.style.height = height;
        this.outputText.style.display = 'block';
        this.htmlContentBox.style.display = 'none';
        this.outputTextModal.style.display = 'block';
        this.overlayTextBox.style.display = 'block';
    },
    
    showHTMLModal(html) {
        this.htmlContentBox.innerHTML = html;
        this.outputText.style.display = 'none';
        this.htmlContentBox.style.display = 'block';
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
    
    fetchAndDisplay(url, modalHeight = '5em', options = { method: 'GET' }, parser = null) {
        fetch(url, options)
            .then(async response => {
                if (response.status === 429) {
                    this.showModal("Too Many Requests, please wait 24 hours before making a new request", modalHeight);
                    return;
                }
    
                const data = await response.json();
    
                if (parser) {
                    try {
                        const html = parser(data);
                        this.showHTMLModal(html);
                    } catch (e) {
                        this.showModal("Error parsing response:\n" + e.message, modalHeight);
                    }
                } else if (data.output) {
                    this.showModal(data.output, modalHeight);
                } else {
                    const text = JSON.stringify(data, null, 2) || 'Unknown error';
                    this.showModal("Error:\n" + text, modalHeight);
                }
            })
            .catch(error => {
                this.showModal("Error calling server: " + error, modalHeight);
            });
    }
};