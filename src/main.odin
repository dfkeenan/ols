package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:strings"
import "core:slice"
import "core:strconv"
import "core:encoding/json"

import "shared:index"
import "shared:server"
import "shared:common"

running: bool;

os_read :: proc(handle: rawptr, data: [] byte) -> (int, int)
{
    return os.read(cast(os.Handle)handle, data);
}

os_write :: proc(handle: rawptr, data: [] byte) -> (int, int)
{
    return os.write(cast(os.Handle)handle, data);
}

//Note(Daniel, Should look into handling errors without crashing from parsing)

run :: proc(reader: ^server.Reader, writer: ^server.Writer) {

    config: common.Config;

    //temporary collections being set manually, need to get client configuration set up.
    config.collections = make(map [string] string);

    config.collections["core"] = "C:/Users/danie/OneDrive/Desktop/Computer_Science/Odin/core";

    log.info("Starting Odin Language Server");

    index.build_static_index(context.allocator, &config);


    config.running = true;

    for config.running {

        header, success := server.read_and_parse_header(reader);

        if(!success) {
            log.error("Failed to read and parse header");
            return;
        }


        value: json.Value;
        value, success = server.read_and_parse_body(reader, header);

        if(!success) {
            log.error("Failed to read and parse body");
            return;
        }

        success = server.handle_request(value, &config, writer);

        if(!success) {
            log.error("Unrecoverable handle request");
            return;
        }

        free_all(context.temp_allocator);

    }

}

end :: proc() {

}


main :: proc() {

    reader := server.make_reader(os_read, cast(rawptr)os.stdin);
    writer := server.make_writer(os_write, cast(rawptr)os.stdout);

    context.logger = server.create_lsp_logger(&writer);

    run(&reader, &writer);
}
