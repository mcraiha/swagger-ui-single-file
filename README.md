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

## License

swagger-ui-single-file is licensed under [Apache 2.0 license](https://github.com/mcraiha/swagger-ui-single-file/blob/main/LICENSE) because the Swagger UI uses the same license.