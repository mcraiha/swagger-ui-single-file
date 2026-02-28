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
	else if (args.len == 4 and std.mem.eql(u8, args[1], "--fill-template"))
	{

	}
	else if (args.len == 3 and std.mem.eql(u8, args[1], "--create-template"))
	{

	}

	_ = try stdout_writer.write("AAa");
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