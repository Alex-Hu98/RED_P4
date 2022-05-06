/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<8>  TCP_PROTOCOL = 0x06;
const bit<16> TYPE_IPV4 = 0x800;

const bit<19> WEIGHT = 25;                          // weight for calcuating avg queue length
const bit<19> MAX_WEIGHT = 256;                     // range for the weight

const bit<19> P_MAX = 128;                          // maximun drop prob
const bit<19> P_MAX_RANGE = 256;                    // range for maximun drop prob
const bit<19> P_MAX_RANGE_SHIFT = 8;                // bits to shift when need to divide by P_MAX_RANGE
const bit<19> DIFF_MAX_MIN_THRESHOLD = 32;          // difference between min_thres and max_thres
const bit<19> DIFF_MAX_MIN_THESHOLD_SHIFT = 5;      // need to be changed if the upper value is changed
const bit<19> MIN_THRESHOLD = 10;                   // min_thres
const bit<19> MAX_THRESHOLD = MIN_THRESHOLD + DIFF_MAX_MIN_THRESHOLD;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

typedef bit<9> QueueId_t;
typedef bit<14> QueueDepth_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    diffserv;
    bit<2>    ecn;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}



/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {


    action drop() {
        mark_to_drop(standard_metadata);
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply {
        // packet forwarding 
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
        }
    }
}



register<bit<19>>(1) Qavg;
register<bit<19>>(1) this_enq_qdepth;
register<bit<19>>(1) this_drop_prob;
//register<bit<19>>(128) this_rand_num;
register<bit<32>>(1) if_dropped;


/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { 
        // read current queue length and record it in a register
        bit<32> write_location = 0;
        this_enq_qdepth.write(write_location, standard_metadata.enq_qdepth);
        bit<19> Q_this = standard_metadata.enq_qdepth;

        // read previously calculated queue_legnth_avg
        // then calculate the new average queue length and store it in a register
        bit<19> Qavg_prev = 0;
        bit<19> Qavg_new = 0;
        Qavg.read(Qavg_prev, (bit<32>)0);
        Qavg_new = WEIGHT * Q_this + (MAX_WEIGHT - WEIGHT) * Qavg_prev;
        Qavg_new = Qavg_new>>8;
        Qavg.write(write_location, Qavg_new);

        // calcuate current drop probability and store it in a reg
        bit<19> drop_prob = 0;
        if (Qavg_new > MIN_THRESHOLD) {
            drop_prob = P_MAX * (Qavg_new - MIN_THRESHOLD);
            drop_prob = drop_prob>>5; //shifted DIFF_MAX_MIN_THESHOLD_SHIFT; now we have drop_prob in range 0 to 256
        }
        this_drop_prob.write(write_location, drop_prob);

        // generate a random number and drop packets based on the number generated
        if ((Qavg_new <= MAX_THRESHOLD) && (Qavg_new >= MIN_THRESHOLD)) {
            bit<19> rand_val;
            random<bit<19>>(rand_val, 1, 256);
            if (rand_val < drop_prob) {
                mark_to_drop(standard_metadata);
                if_dropped.write(write_location, 1);
            } else {
                if_dropped.write(write_location, 0);
            }

        }
        if (Qavg_new > MAX_THRESHOLD) {
            mark_to_drop(standard_metadata);
            if_dropped.write(write_location, 1);
        }
        if (Qavg_new < MIN_THRESHOLD) {
            if_dropped.write(write_location, 0);
        }
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
	      hdr.ipv4.diffserv,
	      hdr.ipv4.ecn,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
