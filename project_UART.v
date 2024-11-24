
/////////////////////// parity /////////////////////////////

module parity ( output reg parity_out,
                input [7:0] data,
                input [1:0] parity_type,
                input rst);
integer num;
always @ (*)
begin
if (rst==0) parity_out =0;
else
begin
num = ^data; 
casex (parity_type)
2'b00 : parity_out = 1'bx;
2'b01 : parity_out = ~num;
2'b10 : parity_out = num;
2'b11 : parity_out = num;
endcase 
end
end 
endmodule 

////////////////////////// frame /////////////////////////////////

module frame_gen ( output reg [11:0] frame_out,
                   input rst,data_lengh,parity_out,stop_bits,
                   input [7:0] data,
                   input [1:0] parity_type);
//parity p (parity_out,data,parity_type,rst);
always@(*)
begin
if (rst==0) frame_out = 0;
else
begin 
frame_out [11] = 1'b0;
if (data_lengh==0) begin frame_out [10:4] = data ; end
else if (data_lengh==1) begin frame_out [10:3] = data ; end

case (parity_type)
2'b00,2'b11 : begin end
2'b01,2'b10 : begin 
              if (~data_lengh) frame_out[3] = parity_out;
              else if (data_lengh) frame_out[2] = parity_out;   
              end
endcase 

case (stop_bits)
1'b0 : if (parity_type==2'b00 || parity_type==2'b11)
         begin
         if (~data_lengh)
         frame_out [3] = 1'b1;
         else if (data_lengh)
         frame_out [2] = 1'b1;
         end 
       else if (parity_type==2'b01 || parity_type==2'b10)
         begin
         if (~data_lengh)
         frame_out [2] = 1'b1;
         else if (data_lengh)
         frame_out [1] = 1'b1;
         end 
1'b1 : if (parity_type==2'b00 || parity_type==2'b11)
         begin
         if (~data_lengh)
         frame_out [3:2] = 1'b1;
         else if (data_lengh)
         frame_out [2:1] = 1'b1;
         end 
       else if (parity_type==2'b01 || parity_type==2'b10)
         begin
         if (~data_lengh)
         frame_out [2:1] = 1'b1;
         else if (data_lengh)
         frame_out [1:0] = 1'b1;
         end
endcase
end
end
endmodule 

//////////////////////////////// baud_rate ////////////////////////////

module baud_gen( output reg baud_out,
                 input [1:0] baud_gen,
                 input clk,rst);
reg [15:0] div;
reg [15:0] count;
always@(posedge clk,negedge rst)
if (~rst) 
begin
count = 0; baud_out = 0;
end 
else 
begin
if (count>=div)
begin
count<=0;
baud_out <=~baud_out;
end
else 
count <= count + 1;
end
always@(*)
begin
case (baud_gen)
2'b00 : div<=1301;
2'b01 : div<=650;
2'b10 : div<=324;
2'b11 : div<=10;
default : div<=324;
endcase
end
endmodule 

/////////////////////////////// piso ///////////////////////////////

module piso_UART ( output reg data_out,parity_out,tx_active,tx_done,
                   input rst,send,baud_out,
                   input [11:0] frame_out,
                   input [1:0] parity_type);
reg [11:0] shift_register;
reg [3:0] bit_counter;

always@(posedge baud_out,negedge rst)
begin
if (~rst) 
begin
//data_out <= 1'b0;
parity_out <= 1'b0;
tx_active <= 1'b0;
tx_done <= 1'b0;
shift_register <= 12'b0;
bit_counter <= 4'b0;
end
else if (send)
begin
     if (~tx_active)
     begin
     shift_register <= frame_out;
     tx_active <= 1'b1; 
     tx_done <= 1'b0;
     bit_counter <= 4'b0;
     end
     else 
     begin
     data_out <= shift_register [0];
     shift_register <= shift_register >> 1;
     bit_counter <= bit_counter + 1;
     if (parity_type == 2'b11)
     parity_out <= 1'b1;
     else
     parity_out <= 1'b0;
     if (bit_counter==11)
     begin
     tx_active <= 1'b0;
     tx_done <= 1'b1;
     end
     end
end
else 
begin
     tx_active <= 1'b0;
     tx_done <= 1'b0;
     parity_out <= 1'b0;
end
end
endmodule

////////////////////////////// top_module ////////////////////////////////////////////

module top_UART ( output data_out,parity_out,tx_active,tx_done,
                  input rst,stop_bits,data_lengh,send,clock,
                  input [7:0] data_in,
                  input [1:0] parity_type,baud_gen);
wire parity_out1;
wire [11:0] frame_out;
wire baud_out;

parity w1 (parity_out1,data_in,parity_type,rst);
frame_gen w2 (frame_out,rst,data_lengh,parity_out1,stop_bits,data_in,parity_type);
baud_gen w3 (baud_out,baud_gen,clock,rst);
piso_UART w4 (data_out,parity_out,tx_active,tx_done,rst,send,baud_out,frame_out,parity_type);

endmodule

////////////////////////////// test_bench ///////////////////////////////////////////////

module  top_UART_ts ();
reg rst,stop_bits,data_length,send,clock;
reg [1:0] parity_type,baud_gen;
reg [7:0] data_in;
wire data_out,p_parity_out,tx_active,tx_done;
top_UART UA (data_out,p_parity_out,tx_active,tx_done,rst,stop_bits,data_length,send,clock,data_in,parity_type,baud_gen);
initial
begin
$monitor("Time = %0t, data_in = %b, data_out = %b", $time, data_in,data_out);
end
initial
begin
clock=0;
repeat (800)
#2 clock=~clock;
end
initial
begin
rst=0;
#15 rst=1;
end
initial
begin
send=0;
#20 send=1;
//#300 send=0;
end
initial
begin
stop_bits=1;
data_length=1;
parity_type=2'b00;
baud_gen=2'b11;
data_in=8'b00001111;
end
endmodule






