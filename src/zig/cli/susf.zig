const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
	const arena: std.mem.Allocator = init.arena.allocator();

	const args = try init.minimal.args.toSlice(arena);
	for (args) |arg| {
		std.log.info("arg: {s}", .{arg});
	}

	const io = init.io;

	var stdout_buffer: [1024]u8 = undefined;
	var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
	const stdout_writer = &stdout_file_writer.interface;

	if (args.len == 1)
	{
		const buildinfo = @embedFile("buildinfo.txt");
		try printHelp(stdout_writer, buildinfo);
	}
	else if (args.len == 2 and std.mem.eql(u8, args[1], "--help"))
	{
		const buildinfo = @embedFile("buildinfo.txt");
		try printHelp(stdout_writer, buildinfo);
	}
	else if (args.len == 5 and std.mem.eql(u8, args[1], "--fill-template"))
	{
		try fillTemplate(init, stdout_writer, arena, args[2], args[3], args[4]);
	}
	else if (args.len == 4 and std.mem.eql(u8, args[1], "--create-template"))
	{
		try createTemplate(init, stdout_writer, arena, args[2], args[3]);
	}
	else
	{
		_ = try stdout_writer.print("Unknown parameter: {s}\n", .{args[1]});
	}

	try stdout_writer.flush(); // Don't forget to flush!
}

pub fn printHelp(writer: *Io.Writer, buildInfo: []const u8) Io.Writer.Error!void {
	_ = try writer.write(buildInfo);
	_ = try writer.write("susf is a CLI tool for creating and filling single HTML file Swagger UI\n");
	_ = try writer.write("Usage:\n");
	_ = try writer.write("\n");
	_ = try writer.write(" - To fill an existing template with Swagger JSON URL:\n");
	_ = try writer.write("susf --fill-template templates/index-5-29.html https://example.com/swagger.json my.html\n");
	_ = try writer.write("\n");
	_ = try writer.write(" - To fill an existing template with local Swagger JSON file:\n");
	_ = try writer.write("susf --fill-template templates/index-5-29.html swagger.json embedded.html\n");
	_ = try writer.write("\n");
	_ = try writer.write(" - To create a new template file from Swagger UI dist files:\n");
	_ = try writer.write("susf --create-template swagger-ui-5.29.0/dist template.html\n");
}

pub fn fillTemplate(init: std.process.Init, writer: *Io.Writer, allocator: std.mem.Allocator, inputTemplateFilename: []const u8, urlOrFilename: []const u8, outputHtmlFilename: []const u8) !void {
	// Check that template file exists
	const templateHtmlContent = Io.Dir.cwd().readFileAlloc(init.io, inputTemplateFilename, allocator, .unlimited) catch {
		std.log.err("Failed to open file: {s}", .{inputTemplateFilename});
		return;
	};

	_ = try writer.print("Swagger UI templated index.html file: {s} \n", .{inputTemplateFilename} );

	var writeWasSuccess = false;

	if (std.mem.startsWith(u8, urlOrFilename, "http:") or std.mem.startsWith(u8, urlOrFilename, "https:"))
	{
		// Assume Swagger URL
		const urlToReplace = "https://petstore.swagger.io/v2/swagger.json";
		const final_html_len = templateHtmlContent.len - urlToReplace.len + urlOrFilename.len;

		 // Allocate a buffer for the result
		const indexHtmlText = try allocator.alloc(u8, final_html_len);
		defer allocator.free(indexHtmlText);

		_ = std.mem.replace(u8, templateHtmlContent, urlToReplace, urlOrFilename, indexHtmlText);
		writeWasSuccess = tryToWriteHtmlFile(init, outputHtmlFilename, indexHtmlText);
	}
	else
	{
		// Assume Swagger file in JSON
		const openApiContent = Io.Dir.cwd().readFileAlloc(init.io, urlOrFilename, allocator, .unlimited) catch {
			std.log.err("Failed to open file: {s}\n", .{urlOrFilename});
			return;
		};

		const validJson = try std.json.Scanner.validate(allocator, openApiContent);

		if (!validJson)
		{
			std.log.err("Currently only JSON spec files are supported. Invalid file: {s}\n", .{urlOrFilename});
			return;
		}

		const textToReplace = "url: \"https://petstore.swagger.io/v2/swagger.json\"";
		const specText = "spec: ";
		const joinTogether = &[_][]const u8{ specText, openApiContent };
		const joined = try std.mem.concat(allocator, u8, joinTogether);

		const final_html_len = templateHtmlContent.len - textToReplace.len + joined.len;

		// Allocate a buffer for the result
		const indexHtmlText = try allocator.alloc(u8, final_html_len);
		defer allocator.free(indexHtmlText);

		_ = std.mem.replace(u8, templateHtmlContent, textToReplace, joined, indexHtmlText);
		writeWasSuccess = tryToWriteHtmlFile(init, outputHtmlFilename, indexHtmlText);
	}

	if (writeWasSuccess)
	{
		_ = try writer.print("Output HTML succesfully written to: {s}", .{outputHtmlFilename} );
	}
}

pub fn createTemplate(init: std.process.Init, writer: *Io.Writer, allocator: std.mem.Allocator, basePath: []const u8, outputHtmlFilename: []const u8) !void {
	// Check that basepath exists and we can access it
	_ = Io.Dir.cwd().openDir(init.io, basePath, .{ .follow_symlinks = true }) catch |err| {
		std.log.err("Error accessing folder {s}, error: {} \n", .{basePath, err});
		return;
	};

	_ = try writer.print("Base path for Swagger UI files: {s}\n", .{basePath} );

	// HTML file(s)
	const indexHtmlPath = try std.fs.path.join(allocator, &[_][]const u8{basePath, "index.html"});
	_ = try writer.print("Swagger UI index.html path: {s}\n", .{indexHtmlPath});
	const indexHtmlText = Io.Dir.cwd().readFileAlloc(init.io, indexHtmlPath, allocator, .unlimited) catch {
		std.log.err("Failed to open file: {s}\n", .{indexHtmlPath});
		return;
	};

	// CSS file(s)
	const swaggerUiCssPath = try std.fs.path.join(allocator, &[_][]const u8{basePath, "swagger-ui.css"});
	_ = try writer.print("Swagger UI swagger-ui.css path: {s}\n", .{swaggerUiCssPath});
	const swaggerUiCssText = Io.Dir.cwd().readFileAlloc(init.io, swaggerUiCssPath, allocator, .unlimited) catch {
		std.log.err("Failed to open file: {s}\n", .{swaggerUiCssPath});
		return;
	};

	const indexCssPath = try std.fs.path.join(allocator, &[_][]const u8{basePath, "index.css"});
	_ = try writer.print("Swagger UI index.css path: {s}\n", .{indexCssPath});
	const indexCssText = Io.Dir.cwd().readFileAlloc(init.io, indexCssPath, allocator, .unlimited) catch {
		std.log.err("Failed to open file: {s}\n", .{indexCssPath});
		return;
	};

	// Favicon file(s)
	const favIcon32Path = try std.fs.path.join(allocator, &[_][]const u8{basePath, "favicon-32x32.png"});
	_ = try writer.print("Swagger UI favicon-32x32.png path: {s}\n", .{favIcon32Path});
	const favIcon32Bytes = Io.Dir.cwd().readFileAlloc(init.io, favIcon32Path, allocator, .unlimited) catch {
		std.log.err("Failed to open file: {s}\n", .{favIcon32Path});
		return;
	};

	const favIcon16Path = try std.fs.path.join(allocator, &[_][]const u8{basePath, "favicon-16x16.png"});
	_ = try writer.print("Swagger UI favicon-16x16.png path: {s}\n", .{favIcon16Path});
	const favIcon16Bytes = Io.Dir.cwd().readFileAlloc(init.io, favIcon16Path, allocator, .unlimited) catch {
		std.log.err("Failed to open file: {s}\n", .{favIcon16Path});
		return;
	};

	// Javascript file(s)
	const bundleJsPath = try std.fs.path.join(allocator, &[_][]const u8{basePath, "swagger-ui-bundle.js"});
	_ = try writer.print("Swagger UI swagger-ui-bundle.js path: {s}\n", .{bundleJsPath});
	const bundleJsText = Io.Dir.cwd().readFileAlloc(init.io, bundleJsPath, allocator, .unlimited) catch {
		std.log.err("Failed to open file: {s}\n", .{bundleJsPath});
		return;
	};

	const standalonePresetJsPath = try std.fs.path.join(allocator, &[_][]const u8{basePath, "swagger-ui-standalone-preset.js"});
	_ = try writer.print("Swagger UI swagger-ui-standalone-preset.js path: {s}\n", .{standalonePresetJsPath});
	const standalonePresetJsText = Io.Dir.cwd().readFileAlloc(init.io, standalonePresetJsPath, allocator, .unlimited) catch {
		std.log.err("Failed to open file: {s}\n", .{standalonePresetJsPath});
		return;
	};

	const initializerJsPath = try std.fs.path.join(allocator, &[_][]const u8{basePath, "swagger-initializer.js"});
	_ = try writer.print("Swagger UI swagger-initializer.js path: {s}\n", .{initializerJsPath});
	const initializerJsText = Io.Dir.cwd().readFileAlloc(init.io, initializerJsPath, allocator, .unlimited) catch {
		std.log.err("Failed to open file: {s}\n", .{initializerJsPath});
		return;
	};

	// Base64 needed
	const encoder = std.base64.standard.Encoder;

	const favIcon32Base64 = try allocator.alloc(u8, encoder.calcSize(favIcon32Bytes.len));
	defer allocator.free(favIcon32Base64);
	_ = encoder.encode(favIcon32Base64, favIcon32Bytes);

	const favIcon16Base64 = try allocator.alloc(u8, encoder.calcSize(favIcon16Bytes.len));
	defer allocator.free(favIcon16Base64);
	_ = encoder.encode(favIcon16Base64, favIcon16Bytes);

	// Replace operations
	const removeSwaggerUiCssLink = "<link rel=\"stylesheet\" type=\"text/css\" href=\"./swagger-ui.css\" />";
	var temp_len = indexHtmlText.len - removeSwaggerUiCssLink.len;
	const tempBuffer1 = try allocator.alloc(u8, temp_len);
	defer allocator.free(tempBuffer1);
	_ = std.mem.replace(u8, indexHtmlText, removeSwaggerUiCssLink, "", tempBuffer1);

	const replaceIndexCssLink = "<link rel=\"stylesheet\" type=\"text/css\" href=\"index.css\" />";
	const newCssJoinTogether = &[_][]const u8{ "<style>\n", swaggerUiCssText, "\n", indexCssText, "\n", "</style>" };
	const newCss = try std.mem.concat(allocator, u8, newCssJoinTogether);
	temp_len = tempBuffer1.len - replaceIndexCssLink.len + newCss.len;
	const tempBuffer2 = try allocator.alloc(u8, temp_len);
	defer allocator.free(tempBuffer2);
	_ = std.mem.replace(u8, tempBuffer1, replaceIndexCssLink, newCss, tempBuffer2);

	const replaceFavicon32 = "<link rel=\"icon\" type=\"image/png\" href=\"./favicon-32x32.png\" sizes=\"32x32\" />";
	const newIcon32JoinTogether = &[_][]const u8{ "<link href=\"data:image/x-icon;base64,", favIcon32Base64, "\" rel=\"icon\" type=\"image/x-icon\" />" };
	const newIcon32 = try std.mem.concat(allocator, u8, newIcon32JoinTogether);
	temp_len = tempBuffer2.len - replaceFavicon32.len + newIcon32.len;
	const tempBuffer3 = try allocator.alloc(u8, temp_len);
	defer allocator.free(tempBuffer3);
	_ = std.mem.replace(u8, tempBuffer2, replaceFavicon32, newIcon32, tempBuffer3);

	const replaceFavicon16 = "<link rel=\"icon\" type=\"image/png\" href=\"./favicon-16x16.png\" sizes=\"16x16\" />";
	const newIcon16JoinTogether = &[_][]const u8{ "<link href=\"data:image/x-icon;base64,", favIcon16Base64, "\" rel=\"icon\" type=\"image/x-icon\" />" };
	const newIcon16 = try std.mem.concat(allocator, u8, newIcon16JoinTogether);
	temp_len = tempBuffer3.len - replaceFavicon16.len + newIcon16.len;
	const tempBuffer4 = try allocator.alloc(u8, temp_len);
	defer allocator.free(tempBuffer4);
	_ = std.mem.replace(u8, tempBuffer3, replaceFavicon16, newIcon16, tempBuffer4);

	const replaceBundleJs = "<script src=\"./swagger-ui-bundle.js\" charset=\"UTF-8\"> </script>";
	const newBundleJsJoinTogether = &[_][]const u8{ "<script type=\"text/javascript\" charset=\"UTF-8\">\n", bundleJsText, "\n", "</script>" };
	const newBundleJs = try std.mem.concat(allocator, u8, newBundleJsJoinTogether);
	temp_len = tempBuffer4.len - replaceBundleJs.len + newBundleJs.len;
	const tempBuffer5 = try allocator.alloc(u8, temp_len);
	defer allocator.free(tempBuffer5);
	_ = std.mem.replace(u8, tempBuffer4, replaceBundleJs, newBundleJs, tempBuffer5);

	const replaceStandalonePresetJs = "<script src=\"./swagger-ui-standalone-preset.js\" charset=\"UTF-8\"> </script>";
	const newStandalonePresetJsJoinTogether = &[_][]const u8{ "<script type=\"text/javascript\" charset=\"UTF-8\">\n", standalonePresetJsText, "\n", "</script>" };
	const newStandalonePresetJs = try std.mem.concat(allocator, u8, newStandalonePresetJsJoinTogether);
	temp_len = tempBuffer5.len - replaceStandalonePresetJs.len + newStandalonePresetJs.len;
	const tempBuffer6 = try allocator.alloc(u8, temp_len);
	defer allocator.free(tempBuffer6);
	_ = std.mem.replace(u8, tempBuffer5, replaceStandalonePresetJs, newStandalonePresetJs, tempBuffer6);

	const replaceInitializerJs = "<script src=\"./swagger-initializer.js\" charset=\"UTF-8\"> </script>";
	const newInitializerJsJoinTogether = &[_][]const u8{ "<script type=\"text/javascript\" charset=\"UTF-8\">\n", initializerJsText, "\n", "</script>" };
	const newInitializerJs = try std.mem.concat(allocator, u8, newInitializerJsJoinTogether);
	temp_len = tempBuffer6.len - replaceInitializerJs.len + newInitializerJs.len;
	const tempBuffer7 = try allocator.alloc(u8, temp_len);
	defer allocator.free(tempBuffer7);
	_ = std.mem.replace(u8, tempBuffer6, replaceInitializerJs, newInitializerJs, tempBuffer7);

	if (tryToWriteHtmlFile(init, outputHtmlFilename, tempBuffer7))
	{
		_ = try writer.print("Output HTML template succesfully written to: {s}", .{outputHtmlFilename} );
	}
}

pub fn tryToWriteHtmlFile(init: std.process.Init, outputHtmlFilename: []const u8, htmlContent: []const u8) bool {
	// Check that output file does not already exists, this tool does NOT overwrite any files!
	var fileExists = true;

	 Io.Dir.cwd().access(init.io, outputHtmlFilename, .{ .follow_symlinks = true }) catch |err| switch (err) {
		error.FileNotFound => {
			//std.log.err("Warning: File not found: {s}\n", .{outputHtmlFilename});
			fileExists = false;
		},
		else => {
			std.log.err("Error accessing file {s}\n", .{outputHtmlFilename});
			return false;
		},
	};

	if (fileExists)
	{
		std.log.err("Output file {s} already exists!\n", .{outputHtmlFilename});
		std.process.exit(1);
		return false;
	}

	const outputFile = Io.Dir.cwd().createFile(init.io, outputHtmlFilename, .{ .exclusive = true }) catch |err| {
		std.log.err("Error creating file {s}\n {}\n", .{outputHtmlFilename, err});
		return false;
	};
	defer outputFile.close(init.io);

	_ = outputFile.writePositionalAll(init.io, htmlContent, 0) catch |err| {
		std.log.err("Error writing to file {s}\n {}\n", .{outputHtmlFilename, err});
		return false;
	};

	return true;
}