//
// pcileech_bar_impl_i210_null — NULL ENDPOINT, Intel I210 identity
//
// Same architecture as pcileech_bar_impl_CMI8738_null: answers only the
// register reads/writes an igb driver performs during igb_probe()/
// igb_sw_init() with plausible values, so enumeration and driver bind
// succeed. Does NOT implement a real TX/RX descriptor engine, real EEPROM
// contents, or real MSI-X vector delivery — per upstream guidance (see
// 16SalomonArs/Pcileech-DMA-Firmware-Guide and JPShag/PCILeech-DMA-Firmware,
// both explicit that static config/BAR replication cannot produce a
// functional NIC clone, and PCILeech's own DMA function does not need one).
// Generates zero autonomous PCIe TLPs, matching the CMI8738 module's
// "null endpoint" contract.
//
// Register offsets below come from a live config-space dump (see
// ip/pcileech_cfgspace_i210.coe) cross-checked against igb driver register
// definitions from training data. The low RX/TX ring-register base
// (0x0C000/0x0E000, "expanded" 82576/i350/i210-family layout) is the one
// item NOT independently re-verified against this specific silicon this
// session -- confirm with an ILA capture of the real driver's first BAR
// writes before trusting it on hardware (see guide section 14.1).
//
module pcileech_bar_impl_i210_null(
    input                rst,
    input                clk,
    input  [31:0]        wr_addr,
    input  [3:0]         wr_be,
    input  [31:0]        wr_data,
    input                wr_valid,
    input  [87:0]        rd_req_ctx,
    input  [31:0]        rd_req_addr,
    input                rd_req_valid,
    output reg [87:0]    rd_rsp_ctx,
    output reg [31:0]    rd_rsp_data,
    output reg           rd_rsp_valid
);

    // =====================================================================
    // REGISTER OFFSETS (byte offsets within BAR0)
    // =====================================================================
    localparam [15:0] REG_CTRL      = 16'h0000;
    localparam [15:0] REG_STATUS    = 16'h0008;
    localparam [15:0] REG_EECD      = 16'h0010;
    localparam [15:0] REG_EERD      = 16'h0014;
    localparam [15:0] REG_CTRL_EXT  = 16'h0018;
    localparam [15:0] REG_MDIC      = 16'h0020;
    localparam [15:0] REG_VET       = 16'h0038;
    localparam [15:0] REG_ICR       = 16'h00C0;
    localparam [15:0] REG_ICS       = 16'h00C8;
    localparam [15:0] REG_IMS       = 16'h00D0;
    localparam [15:0] REG_IMC       = 16'h00D8;
    localparam [15:0] REG_RCTL      = 16'h0100;
    localparam [15:0] REG_TCTL      = 16'h0400;
    localparam [15:0] REG_RAL0      = 16'h5400;
    localparam [15:0] REG_RAH0      = 16'h5404;
    // RX/TX ring regs, queue 0 only (REG_*_BASE + per-queue 0x40 stride not
    // implemented -- single queue is enough to pass driver init checks).
    localparam [15:0] REG_RDBAL0    = 16'hC000;
    localparam [15:0] REG_RDBAH0    = 16'hC004;
    localparam [15:0] REG_RDLEN0    = 16'hC008;
    localparam [15:0] REG_SRRCTL0   = 16'hC00C;
    localparam [15:0] REG_RDH0      = 16'hC010;
    localparam [15:0] REG_RDT0      = 16'hC018;
    localparam [15:0] REG_RXDCTL0   = 16'hC028;
    localparam [15:0] REG_TDBAL0    = 16'hE000;
    localparam [15:0] REG_TDBAH0    = 16'hE004;
    localparam [15:0] REG_TDLEN0    = 16'hE008;
    localparam [15:0] REG_TDH0      = 16'hE010;
    localparam [15:0] REG_TDT0      = 16'hE018;
    localparam [15:0] REG_TXDCTL0   = 16'hE028;

    // =====================================================================
    // REGISTER FILE
    // =====================================================================
    reg [31:0] reg_ctrl;
    reg [31:0] reg_ctrl_ext;
    reg [31:0] reg_eecd;
    reg [31:0] reg_eerd;
    reg [31:0] reg_mdic;
    reg [31:0] reg_vet;
    reg [31:0] reg_icr;
    reg [31:0] reg_ims;
    reg [31:0] reg_rctl;
    reg [31:0] reg_tctl;
    reg [31:0] reg_ral0;
    reg [31:0] reg_rah0;
    reg [31:0] reg_rdbal0, reg_rdbah0, reg_rdlen0, reg_srrctl0, reg_rdh0, reg_rdt0, reg_rxdctl0;
    reg [31:0] reg_tdbal0, reg_tdbah0, reg_tdlen0, reg_tdh0, reg_tdt0, reg_txdctl0;

    wire [15:0] wr_offs = wr_addr[15:0];

    function automatic [31:0] apply_be(input [31:0] old_v, input [31:0] new_v, input [3:0] be);
        integer lane;
        begin
            apply_be = old_v;
            for (lane = 0; lane < 4; lane = lane + 1)
                if (be[lane]) apply_be[lane*8 +: 8] = new_v[lane*8 +: 8];
        end
    endfunction

    // =====================================================================
    // WRITE PATH
    // =====================================================================
    always @ ( posedge clk ) begin
        if ( rst ) begin
            reg_ctrl     <= 32'h00080201;  // SLU default-asserted-looking value
            reg_ctrl_ext <= 32'h00000000;
            reg_eecd     <= 32'h00000100;  // bit8 EE_PRES = 1
            reg_eerd     <= 32'h00000000;
            reg_mdic     <= 32'h00000000;
            reg_vet      <= 32'h00008100;
            reg_icr      <= 32'h00000000;
            reg_ims      <= 32'h00000000;
            reg_rctl     <= 32'h00000000;
            reg_tctl     <= 32'h00000000;
            reg_ral0     <= 32'h00000000;
            reg_rah0     <= 32'h00000000;
            reg_rdbal0   <= 32'h00000000;
            reg_rdbah0   <= 32'h00000000;
            reg_rdlen0   <= 32'h00000000;
            reg_srrctl0  <= 32'h00000000;
            reg_rdh0     <= 32'h00000000;
            reg_rdt0     <= 32'h00000000;
            reg_rxdctl0  <= 32'h00000000;
            reg_tdbal0   <= 32'h00000000;
            reg_tdbah0   <= 32'h00000000;
            reg_tdlen0   <= 32'h00000000;
            reg_tdh0     <= 32'h00000000;
            reg_tdt0     <= 32'h00000000;
            reg_txdctl0  <= 32'h00000000;
        end else begin
            // CTRL.RST (bit26) self-clears same cycle it's observed, like
            // real hardware -- never let software read RST=1 back.
            reg_ctrl[26] <= 1'b0;

            // MDIC: driver sets bit28(R)/bit30 pending; auto-complete with
            // READY(bit28 in MDIC is actually "R", bit30 is READY) next
            // cycle so the driver's poll loop doesn't spin forever.
            if ( reg_mdic[27] )  // bit27 = pending-access marker we set below
                reg_mdic[30] <= 1'b1;  // READY

            // EERD: driver writes START(bit0)+ADDR(bits15:2); respond with
            // DONE(bit4)=1 and DATA(bits31:16)=0 (blank-but-valid EEPROM
            // word) one cycle later so checksum validation doesn't hang.
            if ( reg_eerd[0] ) begin
                reg_eerd[0] <= 1'b0;     // START self-clears
                reg_eerd[4] <= 1'b1;     // DONE
            end

            if ( wr_valid ) begin
                case ( wr_offs )
                    REG_CTRL:     begin reg_ctrl     <= apply_be(reg_ctrl,     wr_data, wr_be); end
                    REG_CTRL_EXT: reg_ctrl_ext <= apply_be(reg_ctrl_ext, wr_data, wr_be);
                    REG_EECD:     reg_eecd     <= apply_be(reg_eecd,     wr_data, wr_be);
                    REG_EERD:     begin
                                      reg_eerd <= apply_be(reg_eerd, wr_data, wr_be);
                                  end
                    REG_MDIC:     begin
                                      reg_mdic <= apply_be(reg_mdic, wr_data, wr_be);
                                      reg_mdic[30] <= 1'b0;  // clear READY, re-set above next cycle
                                      reg_mdic[27] <= 1'b1;  // internal "access pending" marker
                                  end
                    REG_VET:      reg_vet      <= apply_be(reg_vet,      wr_data, wr_be);
                    REG_ICS:      reg_icr      <= reg_icr | apply_be(32'h0, wr_data, wr_be);
                    REG_IMS:      reg_ims      <= reg_ims | apply_be(32'h0, wr_data, wr_be);
                    REG_IMC:      reg_ims      <= reg_ims & ~apply_be(32'h0, wr_data, wr_be);
                    REG_RCTL:     reg_rctl     <= apply_be(reg_rctl,     wr_data, wr_be);
                    REG_TCTL:     reg_tctl     <= apply_be(reg_tctl,     wr_data, wr_be);
                    REG_RAL0:     reg_ral0     <= apply_be(reg_ral0,     wr_data, wr_be);
                    REG_RAH0:     reg_rah0     <= apply_be(reg_rah0,     wr_data, wr_be);
                    REG_RDBAL0:   reg_rdbal0   <= apply_be(reg_rdbal0,   wr_data, wr_be);
                    REG_RDBAH0:   reg_rdbah0   <= apply_be(reg_rdbah0,   wr_data, wr_be);
                    REG_RDLEN0:   reg_rdlen0   <= apply_be(reg_rdlen0,   wr_data, wr_be);
                    REG_SRRCTL0:  reg_srrctl0  <= apply_be(reg_srrctl0,  wr_data, wr_be);
                    REG_RDH0:     reg_rdh0     <= apply_be(reg_rdh0,     wr_data, wr_be);
                    REG_RDT0:     reg_rdt0     <= apply_be(reg_rdt0,     wr_data, wr_be);
                    REG_RXDCTL0:  reg_rxdctl0  <= apply_be(reg_rxdctl0,  wr_data, wr_be);
                    REG_TDBAL0:   reg_tdbal0   <= apply_be(reg_tdbal0,   wr_data, wr_be);
                    REG_TDBAH0:   reg_tdbah0   <= apply_be(reg_tdbah0,   wr_data, wr_be);
                    REG_TDLEN0:   reg_tdlen0   <= apply_be(reg_tdlen0,   wr_data, wr_be);
                    REG_TDH0:     reg_tdh0     <= apply_be(reg_tdh0,     wr_data, wr_be);
                    REG_TDT0:     reg_tdt0     <= apply_be(reg_tdt0,     wr_data, wr_be);
                    REG_TXDCTL0:  reg_txdctl0  <= apply_be(reg_txdctl0,  wr_data, wr_be);
                    default: ;
                endcase
            end

            // RXDCTL/TXDCTL ENABLE (bit25) self-reflects immediately once
            // set -- real hardware acks queue-enable without extra delay
            // for a null/no-traffic queue.
        end
    end

    // STATUS.LU (bit1) and FD (bit0) always report "link up, full duplex"
    // once CTRL.SLU (bit6) has been set by the driver -- a null endpoint
    // never has a real link, but igb_probe()/watchdog expect this. STATUS
    // is otherwise read-only and not stored as explicit state.
    wire [31:0] reg_status = { 6'b0, 2'b01 /*speed=1000*/, 22'b0, 1'b1 /*LU*/, reg_ctrl[6] /*FD mirrors SLU-ish*/ };

    // =====================================================================
    // READ PATH -- 2-cycle registered pipeline, matching
    // pcileech_bar_impl_CMI8738_null's drd_req_* -> rd_rsp_* convention.
    // =====================================================================
    reg [87:0] drd_req_ctx;
    reg [31:0] drd_req_addr;
    reg        drd_req_valid;

    always @ ( posedge clk ) begin
        if ( rst ) begin
            drd_req_ctx   <= 0;
            drd_req_addr  <= 0;
            drd_req_valid <= 0;
            rd_rsp_ctx    <= 0;
            rd_rsp_data   <= 0;
            rd_rsp_valid  <= 0;
        end else begin
            drd_req_ctx   <= rd_req_ctx;
            drd_req_addr  <= rd_req_addr;
            drd_req_valid <= rd_req_valid;

            rd_rsp_ctx   <= drd_req_ctx;
            rd_rsp_valid <= drd_req_valid;

            case ( drd_req_addr[15:0] )
                REG_CTRL:     rd_rsp_data <= reg_ctrl;
                REG_STATUS:   rd_rsp_data <= reg_status;
                REG_EECD:     rd_rsp_data <= reg_eecd;
                REG_EERD:     rd_rsp_data <= reg_eerd;
                REG_CTRL_EXT: rd_rsp_data <= reg_ctrl_ext;
                REG_MDIC:     rd_rsp_data <= reg_mdic;
                REG_VET:      rd_rsp_data <= reg_vet;
                REG_ICR:      rd_rsp_data <= reg_icr;        // note: real HW clears-on-read, not modeled (null traffic -> always 0 anyway)
                REG_IMS:      rd_rsp_data <= reg_ims;
                REG_RCTL:     rd_rsp_data <= reg_rctl;
                REG_TCTL:     rd_rsp_data <= reg_tctl;
                REG_RAL0:     rd_rsp_data <= reg_ral0;
                REG_RAH0:     rd_rsp_data <= reg_rah0;
                REG_RDBAL0:   rd_rsp_data <= reg_rdbal0;
                REG_RDBAH0:   rd_rsp_data <= reg_rdbah0;
                REG_RDLEN0:   rd_rsp_data <= reg_rdlen0;
                REG_SRRCTL0:  rd_rsp_data <= reg_srrctl0;
                REG_RDH0:     rd_rsp_data <= reg_rdh0;
                REG_RDT0:     rd_rsp_data <= reg_rdt0;
                REG_RXDCTL0:  rd_rsp_data <= reg_rxdctl0;
                REG_TDBAL0:   rd_rsp_data <= reg_tdbal0;
                REG_TDBAH0:   rd_rsp_data <= reg_tdbah0;
                REG_TDLEN0:   rd_rsp_data <= reg_tdlen0;
                REG_TDH0:     rd_rsp_data <= reg_tdh0;
                REG_TDT0:     rd_rsp_data <= reg_tdt0;
                REG_TXDCTL0:  rd_rsp_data <= reg_txdctl0;
                default:      rd_rsp_data <= 32'h00000000;
            endcase
        end
    end

endmodule
