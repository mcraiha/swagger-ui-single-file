# swagger-ui-single-file

Single HTML file version of [Swagger UI](https://github.com/swagger-api/swagger-ui).

## Why ?

Because in some situations it is much easier to deploy/share a single .html file.

## Help

In most cases you want the files in [/templates](/templates) folder. Pick the latest one, open it in your favourite text editor and replace the following line
```js
url: "https://petstore.swagger.io/v2/swagger.json",
```
with your own `swagger.json` file.

You can also use tools to automate the process.

### Replace URL with sed

If your swagger.json would be in example.com then the command would look like:

```bash
sed 's+https://petstore.swagger.io/v2/swagger.json+https://www.example.com/swagger.json+g' index-5-29.html > my-swagger.html
```
Where `https://www.example.com/swagger.json` is your OpenAPI URL and `my-swagger.html` is the name of the output file.

### Replace URL with Deno cli tool

If your swagger.json would be in example.com then the command would look like:

```bash
deno run --allow-read --allow-write src/ts/cli/main.ts --fill-template templates/index-5-29.html https://example.com/swagger.json my.html
```

or

```cmd
deno run --allow-read --allow-write src\ts\cli\main.ts --fill-template templates\index-5-29.html https://example.org/swagger.json my.html
```

Where `https://www.example.com/swagger.json` is your OpenAPI URL and `my.html` is the name of the output file.

### Replace JSON spec with Deno cli tool

If you swagger.json is located in your local machine and you want to embed it into HTML then the command would look like:

```bash
deno run --allow-read --allow-write src/ts/cli/main.ts --fill-template templates/index-5-29.html swagger.json embedded.html
```

or

```cmd
deno run --allow-read --allow-write src\ts\cli\main.ts --fill-template templates\index-5-29.html swagger.json embedded.html
```

Where `swagger.json` is your OpenAPI file and `embedded.html` is the name of the output file.

### Create template file

If you want to create single HTML template file then the command would look like:

```bash
deno run --allow-read --allow-write src/ts/cli/main.ts --create-template swagger-ui-5.29.0/dist template.html
```

or

```cmd
deno run --allow-read --allow-write src\ts\cli\main.ts --create-template swagger-ui-5.29.0\dist template.html
```

Where `swagger-ui-5.29.0/dist` is folder of Swagger UI release that has the UI files and `template.html` is the name of the output template file.

## License

Source code is licensed under [Apache 2.0 license](https://github.com/mcraiha/swagger-ui-single-file/blob/main/LICENSE) because the Swagger UI uses the same license.  

CSS style is [MVP.css](https://andybrewer.github.io/mvp/) and it is [MIT licensed](https://en.wikipedia.org/wiki/MIT_License)  

Icon file is combination of 💾 and 🟢 emojis that are from [Twemoji](https://github.com/jdecked/twemoji) project. Their license is [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/)