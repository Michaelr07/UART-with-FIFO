
module timer #(parameter int time0 = 2000) (
    input logic clk,
    input logic reset,
    input logic enable,
    output logic done 
);

localparam int NUM_BITS =  (time0 > 1)? $clog2(time0) : 1;  // gives number of bits needed for specified value
                                                            // prevents any bad outputs for when time is 1
logic [NUM_BITS - 1 : 0] out;                               // gives bit range 

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        out <= 0;
    else if(enable) begin
        if (out == time0 - 1)
            out <= 0;
        else
            out <= out + 1;
    end
    else 
        out <= 0;
end

assign done = (out == time0 - 1);                        // comb logic

endmodule