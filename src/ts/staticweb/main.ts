const urllink = document.getElementById("urllink")!;
const filelink = document.getElementById("filelink")!;

const urleditSection = document.getElementById("urledit")!;
const fileeditSection = document.getElementById("fileedit")!;

urllink.addEventListener("click", function() {
    selectUrlEdit();
});

filelink.addEventListener("click", function() {
    selectFileEdit();
});

function selectUrlEdit() {
    showUrlEditSection();
    hideFileEditSection();
}

function selectFileEdit() {
    showFileEditSection();
    hideUrlEditSection();
}

function showUrlEditSection() {
    urleditSection.hidden = false;
}

function hideUrlEditSection() {
    urleditSection.hidden = true;
}

function showFileEditSection() {
    fileeditSection.hidden = false;
}

function hideFileEditSection() {
    fileeditSection.hidden = true;
}