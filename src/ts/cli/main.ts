import * as path from "jsr:@std/path";
import { encodeBase64 } from "jsr:@std/encoding/base64";

console.log(Deno.args);

if (Deno.args.length === 0)
{
    console.log("Print help");
}
else if (Deno.args.length === 1)
{
    // Fill template, default mode
}
else if (Deno.args.length === 2 && Deno.args[0] === "--create-template")
{
    const basePath = Deno.args[1];
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
    const newIndexHtmlPath = path.join(basePath, "index2.html");
    try
    {
        await Deno.writeTextFile(newIndexHtmlPath, indexHtmlText, { createNew: true });
    }
    catch (error)
    {
        if (error instanceof Deno.errors.AlreadyExists)
        {
            // Complain that this tool does not overwrite files
            console.error("File already exists: " + newIndexHtmlPath);
            console.log("This tool does NOT overwrite any files!");
        }
        else
        {
            console.error(error);
        }
    }
}