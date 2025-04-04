package main

import "core:fmt"
import "core:thread"
import "core:net"
import "core:sync"
import "core:strings"
import "core:slice"

Client_Packet :: struct {
	// type: CLIENT_PACKET_TYPE,
	// socket: net.TCP_Socket,
	data: Decoded_Packet,
}

Client_Packet_Queue :: struct {
	queue: [dynamic]Client_Packet,
	mutex: sync.Mutex,
}

make_client_packet_queue :: proc() -> Client_Packet_Queue{
	return {
		queue = make([dynamic]Client_Packet),
	};
}

client_packet_queue_push :: proc(q: ^Client_Packet_Queue, packet: Client_Packet){
    sync.lock(&q.mutex);
    defer sync.unlock(&q.mutex);
    
    append(&q.queue, packet);
}

client_packet_queue_has :: proc(q: ^Client_Packet_Queue) -> bool{
    sync.lock(&q.mutex);
    defer sync.unlock(&q.mutex);

    return len(q.queue) > 0;
}

client_packet_queue_pop :: proc(q: ^Client_Packet_Queue) -> Client_Packet{
    sync.lock(&q.mutex);
    defer sync.unlock(&q.mutex);

	return pop_front(&q.queue);
}

Server_Client_Data :: struct{
    socket: net.TCP_Socket,
	player_id: i64,
	// state: ^App_State,
	// queue: Client_Packet_Queue,
};

// aka from server -> to client packets
SERVER_PACKET_TYPE :: enum {
	EMPTY_PACKET, // this is here to handle empty data, should never happen
	SOLAR_SYSTEM_DATA,
	TRAVEL_DATA,
}

// aka from client -> to server packets
CLIENT_PACKET_TYPE :: enum {
	EMPTY_PACKET, // this is here to handle empty data, should never happen
	EXIT,
	REQUEST_ALL_DATA,
	REQUEST_TRAVEL,
}

Empty_Packet_Data :: struct {}
Exit_Data :: struct {}
Request_All_Data :: struct {
	socket: net.TCP_Socket,
}
Request_Travel_Data :: struct {
	socket: net.TCP_Socket,

	planet1: string,
	planet2: string,
	start_day: i32,
}

Decoded_Packet :: union #no_nil {
	Empty_Packet_Data,
	Exit_Data,
	Request_All_Data,
	Request_Travel_Data,
}



accept_connections :: proc() {
	listener, err := net.listen_tcp(ENDPOINT);
	if err != nil{
		fmt.println("[communication] Error at lisetner start", err);
		panic("");
	}

	for i in 0..<1 {
		client_socket, endpoint, err := net.accept_tcp(listener);
		if err != nil{
			fmt.println("[main] Error at accepting clients", err);
			panic("");
		}
		fmt.println("[main] Got connection: ", endpoint);
		
		scd := new(Server_Client_Data);
		scd.socket = client_socket;
		// scd.queue = make_client_packet_queue();
		// scd.state = &state;
		thread.create_and_start_with_data(scd, handle_incoming_packets);
	}
}

handle_incoming_packets :: proc(client_data: rawptr){
	scd := (cast(^Server_Client_Data) client_data)^;
	free(client_data);
	
	// This loops till our client wants to disconnect
	for {
		// get header
		packet_header: [3]byte;
		_ ,err := net.recv_tcp(scd.socket, packet_header[:]);
		if err != nil {
			fmt.panicf("error while recieving data %s", err);
		}

		
		// get data
		packet_type: CLIENT_PACKET_TYPE = cast(CLIENT_PACKET_TYPE) packet_header[0];
		packet_data_len: u16 = slice.to_type(packet_header[1:3], u16);
		packet_data: []byte = make([]byte, packet_data_len);
		fmt.println("[communication] Received packet: ", packet_type, "(len: ", packet_data_len, ")");
		if packet_type == .EXIT {
			fmt.println("[communication] connection ended");
			break; // TODO: handle setting player state to disconnected
		}
		_ ,err = net.recv_tcp(scd.socket, packet_data[:])
		
		client_packet_queue_push(&packet_queue, {
			data = decode_packet(packet_type, packet_data, scd.socket),
		});
	}
}

send_packet :: proc(socket: net.TCP_Socket, data: []byte) {
	sent, err := net.send_tcp(socket, data[:]);

	fmt.println("[communication] Sent", sent, "bytes of", cast(SERVER_PACKET_TYPE) data[0], "packet"); // (total bytes: ", len(data) - 2)
		
	if err != nil {
		// fmt.panicf("error while recieving data %s", err);
		fmt.println("[communication] Error sending ", cast(SERVER_PACKET_TYPE) data[0], " packet: ", err);
	}
}

decode_packet :: proc(type: CLIENT_PACKET_TYPE, data: []byte, socket: net.TCP_Socket) -> Decoded_Packet {
	data := data;
	switch (type) {
		case .EMPTY_PACKET:
			// TODO: handle wrong packets

		case .EXIT:
			panic("[communication] Exit packet should be handled earlier");
		case .REQUEST_ALL_DATA:
			// nothing
			return Request_All_Data{
				socket = socket,
			};
		case .REQUEST_TRAVEL:
			return decode_request_travel(data, socket);

	}
	return {};
}

decode_request_travel :: proc(data: []byte, socket: net.TCP_Socket) -> Request_Travel_Data {
	data := data;

	// player_id := slice.to_type(data[:8], i64);
	// piece_id := cast(u8) data[8];
	p1_len := cast(u8) data[0];
	p1_name := strings.clone_from_bytes(data[1:][:p1_len], context.allocator);
	
	p2_len := cast(u8) data[p1_len + 1];
	p2_name := strings.clone_from_bytes(data[p1_len + 2:][:p2_len], context.allocator);
	
	start_day := slice.to_type(data[p1_len + p2_len + 2:][:4], i32);


	return Request_Travel_Data{
		planet1 = p1_name,
		planet2 = p2_name,

		start_day = start_day,

		socket = socket,
	}
}

encode_all_data :: proc(planets: [dynamic]Planet, rocket: Rocket) -> []byte {
	rocket := rocket;

	packet_data := make([dynamic]byte, 3);
	packet_data[0] = cast(byte) SERVER_PACKET_TYPE.SOLAR_SYSTEM_DATA;

	append_elems(&packet_data, ..bytes_of(&earth_mass));
	append_elems(&packet_data, ..bytes_of(&GRAVITATIONAL_CONSTANT));
	append_elems(&packet_data, ..bytes_of(&ASTRONOMICAL_UNIT));
	
	append_elems(&packet_data, ..bytes_of(&rocket.acceleration));
	append_elems(&packet_data, ..bytes_of(&rocket.nr_engines));
	
	append(&packet_data, cast(u8) len(planets));

	for &planet in planets {
		append(&packet_data, cast(u8) len(planet.name));
		append_elem_string(&packet_data, planet.name);
		append_elems(&packet_data, ..bytes_of(&planet.diameter));
		append_elems(&packet_data, ..bytes_of(&planet.relative_mass));

		append_elems(&packet_data, ..bytes_of(&planet.period));
		append_elems(&packet_data, ..bytes_of(&planet.orbital_radius));
	}

	// packet_data[1] = cast(byte) len(packet_data) - 2;
	packet_len := cast(i16) (len(packet_data) - 3);
	copy(packet_data[1:3], bytes_of(&packet_len)[:])

	// fmt.println(slice.to_type(packet_data[1:3], i16));

	return slice.reinterpret([]byte, packet_data[:]);
}

encode_travel_data :: proc(travel_data: Complex_Travel_Data) -> []byte {
	travel_data := travel_data

	packet_data := make([dynamic]byte, 3);
	packet_data[0] = cast(byte) SERVER_PACKET_TYPE.TRAVEL_DATA;

	append(&packet_data, cast(u8) len(travel_data.p1.name));
	append_elem_string(&packet_data, travel_data.p1.name);
	append(&packet_data, cast(u8) len(travel_data.p2.name));
	append_elem_string(&packet_data, travel_data.p2.name);
	
	append_elems(&packet_data, ..bytes_of(&travel_data.start_coord.x));
	append_elems(&packet_data, ..bytes_of(&travel_data.start_coord.y));
	append_elems(&packet_data, ..bytes_of(&travel_data.end_coord.x));
	append_elems(&packet_data, ..bytes_of(&travel_data.end_coord.y));
	
	append_elems(&packet_data, ..bytes_of(&travel_data.start_day));
	append_elems(&packet_data, ..bytes_of(&travel_data.travel_days));

	append_elems(&packet_data, ..bytes_of(&travel_data.accel_time));
	append_elems(&packet_data, ..bytes_of(&travel_data.cruising_velocity));
	append_elems(&packet_data, ..bytes_of(&travel_data.dist_from_surface));

	packet_len := cast(i16) (len(packet_data) - 3);
	copy(packet_data[1:3], bytes_of(&packet_len)[:])

	// fmt.println(slice.to_type(packet_data[1:3], i16));

	return slice.reinterpret([]byte, packet_data[:]);
}



// Credit: Ferenc a fonok
bytes_of :: proc(data: ^$T) -> []byte{
    return slice.bytes_from_ptr(data, size_of(T));
}