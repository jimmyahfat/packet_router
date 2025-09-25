/*
package tb_pkg;

    localparam DATA_WIDTH = 32;
    class packet;
        logic [DATA_WIDTH-1:0] transfers [];

        function void gen_even(int length);
            foreach (transfers[i]) transfers[i] = $urandom;
            transfers[0] |= 'h0000_0001;
        endfunction

        function void gen_odd(int length);
            foreach (transfers[i]) transfers[i] = $urandom;
            transfers[0] &= 'hFFFF_FFFE;
        endfunction
    endclass
endpackage*/
