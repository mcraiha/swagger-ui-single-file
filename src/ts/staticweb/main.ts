const urllink = document.getElementById("urllink")!;
const filelink = document.getElementById("filelink")!;

const urleditSection = document.getElementById("urledit")!;
const fileeditSection = document.getElementById("fileedit")!;

const urlgenerateButton = document.getElementById("urlgenerate")!;
const filegenerateButton = document.getElementById("filegenerate")!;

const htmlOutputFrame = document.getElementById("htmlOutputFrame")! as HTMLIFrameElement;

urllink.addEventListener("click", function() {
    selectUrlEdit();
});

filelink.addEventListener("click", function() {
    selectFileEdit();
});

urlgenerateButton.addEventListener("click", async function() {
    let templateText = await checkDownloadStore();
    htmlOutputFrame.srcdoc = templateText;
    htmlOutputFrame.hidden = false;
});

const templateFilePrefix: string = "index-5-29";

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

const localStorageTemplateKey: string = "template";

async function checkDownloadStore(): Promise<string> {
    let returnString: string = "";
    if (localStorage.getItem(localStorageTemplateKey) === null) {
        // Fetch the template
        try
        {
            const response = await fetch(`${templateFilePrefix}.html`);
            const text = await response.text();
            if (text.startsWith("<!--")) {
                localStorage.setItem(localStorageTemplateKey, text);
                returnString = text;
            }
        }
        catch (error) {
            console.error(error);
        }
    }
    else {
        returnString = localStorage.getItem(localStorageTemplateKey)!;
    }

    return returnString;
}