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
		try printHelp(stdout_writer);
	}
	else if (args.len == 2 and std.mem.eql(u8, args[1], "--help"))
	{
		try printHelp(stdout_writer);
	}
	else if (args.len == 5 and std.mem.eql(u8, args[1], "--fill-template"))
	{
		try fillTemplate(init, stdout_writer, arena, args[2], args[3], args[4]);
	}
	else if (args.len == 4 and std.mem.eql(u8, args[1], "--create-template"))
	{

	}
	else
	{
		_ = try stdout_writer.print("Unknown parameter: {s}\n", .{args[1]});
	}

	try stdout_writer.flush(); // Don't forget to flush!
}

pub fn printHelp(writer: *Io.Writer) Io.Writer.Error!void {
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

	if (std.mem.startsWith(u8, urlOrFilename, "http:") or std.mem.startsWith(u8, urlOrFilename, "https:"))
	{
		// Assume Swagger URL
		const urlToReplace = "https://petstore.swagger.io/v2/swagger.json";
		const new_len = templateHtmlContent.len - urlToReplace.len + urlOrFilename.len;

		 // Allocate a buffer for the result
		const indexHtmlText = try allocator.alloc(u8, new_len);
		defer allocator.free(indexHtmlText);

		_ = std.mem.replace(u8, templateHtmlContent, urlToReplace, urlOrFilename, indexHtmlText);
		//_ = try writer.write(indexHtmlText);
		try tryToWriteHtmlFile(init, outputHtmlFilename, indexHtmlText);
	}
	else
	{
		// Assume Swagger file in JSON
	}

	_ = try writer.print("Output HTML succesfully written to: {s}", .{outputHtmlFilename} );
}

pub fn tryToWriteHtmlFile(init: std.process.Init, outputHtmlFilename: []const u8, htmlContent: []const u8) !void {
	// Check that output file does not already exists, this tool does NOT overwrite any files!
	var fileExists = true;

	 Io.Dir.cwd().access(init.io, outputHtmlFilename, .{ .follow_symlinks = true }) catch |err| switch (err) {
		error.FileNotFound => {
			//std.log.err("Warning: File not found: {s}\n", .{outputHtmlFilename});
			fileExists = false;
		},
		else => {
			std.log.err("Error accessing file {s}\n", .{outputHtmlFilename});
			return;
		},
	};

	if (fileExists)
	{
		std.log.err("Output file {s} already exists!\n", .{outputHtmlFilename});
		std.process.exit(1);
		return;
	}

	const outputFile = try Io.Dir.cwd().createFile(init.io, outputHtmlFilename, .{ .exclusive = true });
	defer outputFile.close(init.io);

	_ = try outputFile.writePositionalAll(init.io, htmlContent, 0);
}