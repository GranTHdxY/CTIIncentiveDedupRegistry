// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

contract RegistCTI {
    struct CTI {
        string tid;
        string tip;
        uint register_time;
        address producer_address;
        string cti_hash;
        string[] tags;
        int price;
        int feedback_score;         // 消费者对情报的反馈评分
    }

    mapping(string => CTI) public CTIByTidList;
    mapping(string => CTI[]) public CTIByTipListGroup;

    CTI[] public allCtiHashes;                                   // 用于存储已上传cti的哈希值

    uint public similarityThreshold = 10; // 设置阈值，Hamming距离大于此值表示相似度过高

    // 计算两个CTI的SimHash值之间的Hamming距离
    function hammingDistance(string memory hash1, string memory hash2) public pure returns (uint) {
        uint distance = 0;
        for (uint i = 0; i < bytes(hash1).length; i++) {
            if (bytes(hash1)[i] != bytes(hash2)[i]) {
                distance++;
            }
        }
        return distance;
    }

    //生产者注册展示的CTI
    function Register(
        string calldata tid,
        string calldata tip,
        string calldata cti_hash,
        string[] calldata tags,
        int price
    ) external {

        // 检查相似度，防止重复上传
        for (uint i = 0; i < CTIByTipListGroup[tip].length; i++) {
            CTI memory existingCTI = CTIByTipListGroup[tip][i];
            uint distance = hammingDistance(existingCTI.cti_hash, cti_hash);
            if (distance < similarityThreshold) {
                revert("CTI is too similar to an existing one");
            }
        }
        
        //如果两个情报不相似，继续处理上传
        CTI memory cti  =CTI(
            tid,
            tip,
            block.timestamp,
            msg.sender,
            cti_hash,
            tags,
            price,
            0
        );
        CTIByTidList[tid] = cti;
        CTIByTipListGroup[tip].push(cti);
        allCtiHashes.push(cti);
    }
    //根据 id 来查询 cti
    function GetCTIByTid(string calldata tid) external view returns (CTI memory) {
        return CTIByTidList[tid];
    }
    //根据 ip 来查询 cti
    function GetCTIByTip(string memory tip) external view returns (CTI[] memory) {
        return CTIByTipListGroup[tip];
    }

    //列出当前所有上传过的情报的cti_hash
    function GetAllCTIHashes() external view returns (string[] memory) {
        string[] memory hashes = new string[](allCtiHashes.length);
        for (uint i = 0; i < allCtiHashes.length; i++) {
            hashes[i] = allCtiHashes[i].cti_hash;
        }
        return hashes;
    }
}

contract AssignmentContract {
    DelegatorContract delegator_contract;
    constructor(address payable addr){
        delegator_contract=DelegatorContract(addr);
    }
    struct Assignment {
        string tid;
        address producer;
        address[] delegators_address;
        uint price;
        uint producer_price;
        uint delegator_price;
        string ipfsHash;
    }

    struct transaction {
        string tid;
        string txid;
        address producer;
        address delegator;
        address consumer;
        uint price;
        uint producer_price;
        uint delegator_price;
        int status;
    }

    mapping(string => address[]) private record;
    mapping(string => Assignment) private assignment_list;
    mapping(string => transaction) public tx_list;
    event ProducerAssignmentComing(address[] addresses,address producer,string tid,string ipfshash);
    event ConsumerAssignmentComing(address delegator_address,string txid,uint pay, string pubkey);
    event IPFSHashComing(address consumer,string ipfshash,string txid);

    //生产者选择委托者
    function ProducerSelectDelegator(
        string calldata tid,
        address[] calldata delegators_address,
        uint price,
        uint producer_price,
        uint delegator_price,
        string calldata ipfsHash
    ) external returns(bool){
        if (price!=producer_price+delegator_price){
            return false;
        }
        assignment_list[tid]=Assignment(tid,msg.sender, delegators_address, price,producer_price,delegator_price, ipfsHash);
        emit ProducerAssignmentComing(delegators_address,msg.sender,tid,ipfsHash);
        return true;
    }

    //消费者选择委托者
    function ConsumerSelectDelegator(
        string memory tid,
        string memory txid,
        address addr,
        string calldata pubkey
    ) external payable {
        bool f;
        f=false;
        Assignment memory curAssignment;
        // for (uint i = 0;i < list.length;i++){
        //     string memory ttid = list[i].tid;
        //     if (isStringEqual(tid, ttid)){
        //         f=true;
        //         curAssignment = list[i];
        //         break;
        //     }
        // }
        curAssignment = assignment_list[tid];
        address[] memory delegatorList = record[tid];
        for (uint i = 0;i<delegatorList.length;i++){
            if (delegatorList[i]==addr){
                f=true;
            }
        }
        if (f==false){
            return;
        }

        if (f==true){
            require(msg.value>=curAssignment.price);
        }

        tx_list[txid] = transaction(curAssignment.tid,txid,curAssignment.producer,addr,msg.sender,curAssignment.price,curAssignment.producer_price,curAssignment.delegator_price,0);
        emit ConsumerAssignmentComing(addr,txid,msg.value, pubkey);
    }

    //委托者上传 cti 给消费者
    function UploadCTI(string calldata ipfshash,address consumer,string calldata txid) external {
        emit IPFSHashComing(consumer,ipfshash,txid);
    }

    //消费者确认收到 cti    
    function CheckCTI(string calldata txid) external payable  {
        transaction memory trc;
        trc = tx_list[txid];
        if (trc.status == 1){
            return;
        }
        require(msg.sender==trc.consumer);
        trc.status=1;
        address payable producer = payable(trc.producer);
        address payable delegator = payable(trc.delegator);
        producer.transfer(trc.producer_price);
        delegator.transfer(trc.delegator_price);
    }

    //消费者选择升级成为委托者
    function consumerUpgrade(string calldata txid,string calldata name, string calldata pubkey) external payable    {
        transaction memory trc;
        trc=tx_list[txid];
        if (get(trc.tid)==false){
            return;
        }

        address consumer;
        consumer = trc.consumer;
        if (delegator_contract.isDelegator(consumer)==false) {
            delegator_contract.Register{value:msg.value}(name, pubkey);
        }

        Assignment storage assignment;
        assignment=assignment_list[trc.tid];
        assignment.delegators_address.push(consumer);
    }

    //委托者验证 cti ，选择是否接受委托
    function VerifyAssignment(
        string calldata tid,
        bool opt
    ) external returns (bool) {
        if (opt == true) {
            record[tid].push(msg.sender);
            return true;
        }
        return false;
    }
    
    //消费者根据 id 来查询接受委托的委托者有哪些
    function GetAssignmentVerified(string calldata tid) external view returns(address[] memory){
        return record[tid];
    }

    function isStringEqual(string memory  a, string memory b) internal pure returns(bool) {
        bytes memory aa = bytes(a);
        bytes memory bb = bytes(b);
        if (aa.length != bb.length){
            return false;
        }
        for (uint i = 0 ;i<aa.length;i++){
            if (aa[i]!=bb[i]){
                return false;
            }
        }
        return true;
    }

    function get(string memory str) internal pure returns(bool){
        if (bytes(str).length==0){
            return false;
        }
        return true;
    }
}

contract DelegatorContract {
    struct Delegator {
        string name;
        address addr;
        int reputation;
        string pubkey;
        uint time;
    }

    Delegator[] public list;
    mapping(address => bool) public DelegatorInserted;
    function ListDelegator() external view returns (Delegator[] memory) {
        return list;
    }

    //注册成为委托者
    function Register(string calldata name,string calldata pubkey) payable external {
        require(msg.value == 10000000000000000000);
        payable(address(this)).transfer(msg.value);
        list.push(Delegator(name,msg.sender,10,pubkey,block.timestamp));
        DelegatorInserted[msg.sender]=true;
    }

    //判断是否是委托者
    function isDelegator(address addr )external view returns (bool){
        return DelegatorInserted[addr];
    }
    function GetContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    receive()external payable{}
    fallback()external payable{}
}