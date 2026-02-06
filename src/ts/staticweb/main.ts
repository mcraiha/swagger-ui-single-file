const urllink = document.getElementById("urllink")!;
const filelink = document.getElementById("filelink")!;

const urleditSection = document.getElementById("urledit")!;
const fileeditSection = document.getElementById("fileedit")!;

const urlinput = document.getElementById("urlinput")! as HTMLInputElement;

const urlgenerateButton = document.getElementById("urlgenerate")!;
const inputFile = document.getElementById("inputfile")! as HTMLInputElement;

const downloadButton = document.getElementById("downloadbutton")!;

const htmlOutputHeader = document.getElementById("htmlOutputHeader")!;
const htmlOutputFrame = document.getElementById("htmlOutputFrame")! as HTMLIFrameElement;

urllink.addEventListener("click", function() {
    selectUrlEdit();
});

filelink.addEventListener("click", function() {
    selectFileEdit();
});

downloadButton.addEventListener("click", function() {
    handleDownload();
});

urlgenerateButton.addEventListener("click", async function() {
    let templateText = await checkDownloadStore();
    templateText = templateText.replace(`https://petstore.swagger.io/v2/swagger.json`, urlinput.value);

    htmlOutputFrame.srcdoc = templateText;
    htmlOutputFrame.hidden = false;
    htmlOutputHeader.hidden = false;
    downloadButton.hidden = false;
});

inputFile.addEventListener("change", async function() {
    // Check input file first
    const file: File = this.files?.item(0)!;

    try
    {
        const possibleJsonInput: string = await file.text();
        JSON.parse(possibleJsonInput);

        let templateText = await checkDownloadStore();
        templateText = templateText.replace(`url: "https://petstore.swagger.io/v2/swagger.json"`, `spec: ${possibleJsonInput}`);

        htmlOutputFrame.srcdoc = templateText;
        htmlOutputFrame.hidden = false;
        htmlOutputHeader.hidden = false;
        downloadButton.hidden = false;
    }
    catch (error) 
    {
        console.error(error);
    }
});

const templateFilePrefix: string = "index-5-31";

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

enum SupportedCompression {
  None = 0,
  Brotli,
  GZip
}

async function checkDownloadStore(): Promise<string> {
    let returnString: string = "";
    if (localStorage.getItem(templateFilePrefix) === null) {
        // Check supported decompression format
        const chosenFormat: SupportedCompression = detectSupportedDecompression();

        // Fetch the template based on supported compression formats
        if (chosenFormat === SupportedCompression.Brotli) {
            try
            {
                const response = await fetch(`${templateFilePrefix}.br`);
                const blob = await response.blob();
                const decoded = blob.stream().pipeThrough(new DecompressionStream("brotli"));
                const text = await new Response(decoded).text();
                if (text.startsWith("<!--")) {
                    localStorage.setItem(templateFilePrefix, text);
                    returnString = text;
                }
            }
            catch (error) {
                console.error(error);
            }
        }
        else if (chosenFormat === SupportedCompression.GZip) {
            try
            {
                const response = await fetch(`${templateFilePrefix}.gz`);
                const blob = await response.blob();
                const decoded = blob.stream().pipeThrough(new DecompressionStream("gzip"));
                const text = await new Response(decoded).text();
                if (text.startsWith("<!--")) {
                    localStorage.setItem(templateFilePrefix, text);
                    returnString = text;
                }
            }
            catch (error) {
                console.error(error);
            }
        }
        else {
            // No compression
            try
            {
                const response = await fetch(`${templateFilePrefix}.html`);
                const text = await response.text();
                if (text.startsWith("<!--")) {
                    localStorage.setItem(templateFilePrefix, text);
                    returnString = text;
                }
            }
            catch (error) {
                console.error(error);
            }
        }
    }
    else {
        returnString = localStorage.getItem(templateFilePrefix)!;
    }

    return returnString;
}

function detectSupportedDecompression(): SupportedCompression {
    try
    {
        new DecompressionStream("brotli");
        return SupportedCompression.Brotli;
    }
    catch (error)
    {
        console.log(error);
    }

    try
    {
        new DecompressionStream("gzip");
        return SupportedCompression.GZip;
    }
    catch (error)
    {
        console.log(error);
    }

    return SupportedCompression.None;
}

function handleDownload(): void {
    const htmlText: string = htmlOutputFrame.srcdoc;
    const element: HTMLAnchorElement = document.createElement('a');
    const file = new Blob([htmlText], {type: 'text/html'});
    element.href = URL.createObjectURL(file);
    element.download = "swagger_ui.html";
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  };