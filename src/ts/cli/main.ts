import * as path from "jsr:@std/path";
import { exists } from "jsr:@std/fs/exists";
import { encodeBase64 } from "jsr:@std/encoding/base64";

console.log(Deno.args);

if (Deno.args.length === 0)
{
    console.log("Print help");
}
else if (Deno.args.length === 4 && Deno.args[0] === "--fill-template")
{
    // Fill template
    await FillTemplate(Deno.args);
}
else if (Deno.args.length === 3 && Deno.args[0] === "--create-template")
{
    // Create template
    await CreateTemplate(Deno.args);
}

async function FillTemplate(args: string[])
{
    // Check that template file exists
    const templateFile: string = args[1];
    if (false === await exists(templateFile, { isFile: true }))
    {
        console.error("%cParameter: " + templateFile + " is not an existing HTML template file!", "color: red");
        Deno.exit(1);
    }

    console.log("Swagger UI index.html file: " + templateFile);
    let indexHtmlText = await Deno.readTextFile(templateFile);

    if (args[2].startsWith("http:") || args[2].startsWith("https:"))
    {
        // Assume Swagger URL
        const newSwaggerUrl: string = args[2];
        const urlToReplace: string = `https://petstore.swagger.io/v2/swagger.json`;

        indexHtmlText = indexHtmlText.replace(urlToReplace, newSwaggerUrl);

        const outputHtmlFilePath: string = args[3];
        await TryToWriteHtmlFile(outputHtmlFilePath, indexHtmlText);

        console.log("Output HTML succesfully written to: " + outputHtmlFilePath);
    }
    else
    {
        // Assume Swagger file in JSON
        const jsonFilename: string = args[2];
        try
        {
            const jsonText = await Deno.readTextFile(jsonFilename);
            JSON.parse(jsonText)
            const textToReplace: string = `url: "https://petstore.swagger.io/v2/swagger.json"`;
            const newText: string = `spec: ${jsonText}`;

            indexHtmlText = indexHtmlText.replace(textToReplace, newText);

            const outputHtmlFilePath: string = args[3];
            await TryToWriteHtmlFile(outputHtmlFilePath, indexHtmlText);

            console.log("Output HTML succesfully written to: " + outputHtmlFilePath);
        }
        catch (error)
        {
            if (error instanceof SyntaxError)
            {
                console.log("Currently only JSON spec files are supported. Invalid file: " + jsonFilename);
            }
            else
            {
                console.error(error);
                Deno.exit(1);
            }
        }
    }
}

async function CreateTemplate(args: string[])
{
    const basePath = args[1];
    if (false === await exists(basePath, { isDirectory: true }))
    {
        console.error("%cParameter: " + basePath + " is not an existing folder / directory!", "color: red");
        Deno.exit(1);
    }

    console.log("Base path for Swagger UI files: " + basePath);

    // HTML file(s)
    const indexHtmlPath = path.join(basePath, "index.html");
    console.log("Swagger UI index.html path: " + indexHtmlPath);
    let indexHtmlText = await Deno.readTextFile(indexHtmlPath);

    // CSS file(s)
    const swaggerUiCssPath = path.join(basePath, "swagger-ui.css");
    console.log("Swagger UI swagger-ui.css path: " + swaggerUiCssPath);
    const swaggerUiCssText = await Deno.readTextFile(swaggerUiCssPath);

    const indexCssPath = path.join(basePath, "index.css");
    console.log("Swagger UI index.css path: " + indexCssPath);
    const indexCssText = await Deno.readTextFile(indexCssPath);

    // Favicon file(s)
    const favIcon32Path = path.join(basePath, "favicon-32x32.png");
    console.log("Swagger UI favicon-32x32.png path: " + favIcon32Path);
    const favIcon32Bytes = await Deno.readFile(favIcon32Path);

    const favIcon16Path = path.join(basePath, "favicon-16x16.png");
    console.log("Swagger UI favicon-16x16.png path: " + favIcon16Path);
    const favIcon16Bytes = await Deno.readFile(favIcon16Path);

    // Javascript file(s)
    const bundleJsPath = path.join(basePath, "swagger-ui-bundle.js");
    console.log("Swagger UI swagger-ui-bundle.js path: " + bundleJsPath);
    const bundleJsText = await Deno.readTextFile(bundleJsPath);

    const standalonePresetJsPath = path.join(basePath, "swagger-ui-standalone-preset.js");
    console.log("Swagger UI swagger-ui-standalone-preset.js path: " + standalonePresetJsPath);
    const standalonePresetJsText = await Deno.readTextFile(standalonePresetJsPath);

    const initializerJsPath = path.join(basePath, "swagger-initializer.js");
    console.log("Swagger UI swagger-initializer.js path: " + initializerJsPath);
    const initializerJsText = await Deno.readTextFile(initializerJsPath);

    // Base64 needed
    const favIcon32Base64 = encodeBase64(favIcon32Bytes);
    const favIcon16Base64 = encodeBase64(favIcon16Bytes);

    const bundleJsBase64 = encodeBase64(bundleJsText);
    const standalonePresetJsBase64 = encodeBase64(standalonePresetJsText);

    // Replace operations
    indexHtmlText = indexHtmlText.replace(`<link rel="stylesheet" type="text/css" href="./swagger-ui.css" />`, "");
    
    const newCss = `
    <style>
    ${swaggerUiCssText}
    ${indexCssText}
    </style>`;
    indexHtmlText = indexHtmlText.replace(`<link rel="stylesheet" type="text/css" href="index.css" />`, newCss);

    const newIcon32 = `<link href="data:image/x-icon;base64,${favIcon32Base64}" rel="icon" type="image/x-icon" />`;
    indexHtmlText = indexHtmlText.replace(`<link rel="icon" type="image/png" href="./favicon-32x32.png" sizes="32x32" />`, newIcon32);

    const newIcon16 = `<link href="data:image/x-icon;base64,${favIcon16Base64}" rel="icon" type="image/x-icon" />`;
    indexHtmlText = indexHtmlText.replace(`<link rel="icon" type="image/png" href="./favicon-16x16.png" sizes="16x16" />`, newIcon16);

    const newBundleJs = `<script type="text/javascript" src="data:text/javascript;base64,${bundleJsBase64}"></script>`;
    indexHtmlText = indexHtmlText.replace(`<script src="./swagger-ui-bundle.js" charset="UTF-8"> </script>`, newBundleJs);

    const newStandalonePresetJs = `<script type="text/javascript" src="data:text/javascript;base64,${standalonePresetJsBase64}"></script>`;
    indexHtmlText = indexHtmlText.replace(`<script src="./swagger-ui-standalone-preset.js" charset="UTF-8"> </script>`, newStandalonePresetJs);

    const newInitializerJs = `
    <script>
    ${initializerJsText}
    </script>
    `;
    indexHtmlText = indexHtmlText.replace(`<script src="./swagger-initializer.js" charset="UTF-8"> </script>`, newInitializerJs);

    //console.log(indexHtmlText);
    const newIndexHtmlPath = args[2];
    await TryToWriteHtmlFile(newIndexHtmlPath, indexHtmlText);

    console.log("Output HTML succesfully written to: " + newIndexHtmlPath);
}

async function TryToWriteHtmlFile(filePath: string, htmlContent: string)
{
    try
    {
        await Deno.writeTextFile(filePath, htmlContent, { createNew: true });
    }
    catch (error)
    {
        if (error instanceof Deno.errors.AlreadyExists)
        {
            // Complain that this tool does not overwrite files
            console.error("File already exists: " + filePath);
            console.log("This tool does NOT overwrite any files!");
        }
        else
        {
            console.error(error);
        }
        Deno.exit(1);
    }
}