import { isValidVaultaName } from './vaultaUsernameChecks.js';

const AccountModule = {
    usernameInput: null,
    publicKeyInput: null,
    createBtn: null,
    openModalBtn: null,
    closeModalBtn: null,
    modal: null,

    init() {
        this.usernameInput = document.getElementById("usernameInput");
        this.publicKeyInput = document.getElementById("publicKeyInput");
        this.createBtn = document.getElementById("createBtn");
        this.openModalBtn = document.getElementById("openModalBtn");
        this.closeModalBtn = document.getElementById("closeModalBtn");
        this.modal = document.getElementById("createAccountModal");

        this.usernameInput.addEventListener('input', this.validateInputs.bind(this));
        this.publicKeyInput.addEventListener('input', this.validateInputs.bind(this));
        this.createBtn.addEventListener('click', this.handleCreateAccount.bind(this));

        this.openModalBtn.onclick = () => {
            this.modal.style.display = "block";
            this.usernameInput.value = "";
            this.publicKeyInput.value = "";
            this.createBtn.disabled = true;
        };

        this.closeModalBtn.onclick = () => {
            this.modal.style.display = "none";
        };

        window.onclick = (event) => {
            if (event.target === this.modal) {
                this.modal.style.display = "none";
            }
        };
    },

    validateInputs() {
        const usernameValid = isValidVaultaName(this.usernameInput.value.trim());
        const publicKeyPresent = this.publicKeyInput.value.trim().length > 0;
        this.createBtn.disabled = !(usernameValid && publicKeyPresent);
    },

    handleCreateAccount() {
        const username = this.usernameInput.value.trim();
        const publicKey = this.publicKeyInput.value.trim();

        if (!isValidVaultaName(username)) {
            alert("❌ Invalid username format.");
            return;
        }

        if (!publicKey) {
            alert("❌ Public key is required.");
            return;
        }

        fetch('/service/create_account', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                userName: username,
                publicKey: publicKey
            })
        })
        .then(async (res) => {
            const isJson = res.headers.get('content-type')?.includes('application/json');
            const data = isJson ? await res.json() : null;

            if (!res.ok) {
                const error = (data && data.error) || res.statusText;
                throw new Error(error);
            }

            return data;
        })
        .then(() => {
            alert(`✅ Success!\nAccount "${username}" has been created.`);
            this.modal.style.display = "none";
        })
        .catch((err) => {
            alert("❌ Error: " + err.message);
        });
    }
};

document.addEventListener('DOMContentLoaded', () => {
    AccountModule.init();
});
