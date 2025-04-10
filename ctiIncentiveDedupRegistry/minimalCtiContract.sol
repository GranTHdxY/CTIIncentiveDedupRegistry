// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleCTIRegistry {
    struct CTI {
        string tid;
        string tip;
        string cti_hash;
        string[] tags;
        int price;
        string ip;
        uint threat_score;
        string[] iocs;
        int confidence;
    }

    mapping(string => CTI) public CTIByTid;

    event CTIRegistered(string tid, string cti_hash);

    function Register(
        string calldata tid,
        string calldata tip,
        string calldata cti_hash,
        string[] calldata tags,
        int price,
        string calldata ip,
        uint threat_score,
        string[] calldata iocs,
        int confidence
    ) external {
        CTI memory cti = CTI(
            tid,
            tip,
            cti_hash,
            tags,
            price,
            ip,
            threat_score,
            iocs,
            confidence
        );

        CTIByTid[tid] = cti;
        emit CTIRegistered(tid, cti_hash);
    }

    function GetCTI(string calldata tid) external view returns (CTI memory) {
        return CTIByTid[tid];
    }
}