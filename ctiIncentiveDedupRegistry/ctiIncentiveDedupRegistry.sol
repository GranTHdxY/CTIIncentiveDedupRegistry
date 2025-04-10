// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title RegistCTI
 * @dev 威胁情报注册合约，支持链下相似度检测融合判断
 */
contract RegistCTI {
    struct CTI {
        string tid;                  // 威胁情报 ID
        string tip;                  // 情报类型（如：DDoS、SQL注入等）
        uint register_time;          // 注册时间
        address producer_address;    // 发布者地址
        string cti_hash;             // 情报的哈希值，用于验证数据
        string[] tags;               // 标签（如：漏洞、恶意软件等）
        int price;                   // 情报的价格
        string ip;                   // 关联的IP地址
        uint threat_score;           // 威胁评分（来自不同源的威胁分析评分）
        string[] iocs;               // 受影响的IP、域名等IOCs
        int confidence;              // 情报质量评分
        int consumption_count;       // 被消费的次数（生产者激励）
        int transaction_value;       // 总交易金额（生产者激励）
        int validation_count;        // 被委托者验证的次数（委托者激励）
        uint feedback_score;         // 消费者对情报的反馈评分
    }

    mapping(string => CTI) public CTIByTidList;           // 通过 tid 索引的情报信息
    mapping(string => CTI[]) public CTIByTipListGroup;    // 通过 tip 类型分组的情报集合
    mapping(string => bool) public existingCTIHashes;     // 存储已存在的 cti 哈希值
    mapping(string => uint) public duplicateCTICount;     // 存储重复次数
    mapping(string => address[]) public reportedDuplicates; // 被举报为重复的情报

    uint similarityThreshold = 85;  // 判定为重复的融合相似度阈值

    // 信任评分机制相关变量（用于计算可信度平均分）
    mapping(string => uint[]) public feedbackScores;       // 每个 tid 的所有评分
    mapping(string => mapping(address => bool)) public hasScored; // 用户是否评分过某 CTI

    // 首先检查情报的哈希值是否完全重复上传（也就是完全匹配的情况）
    function checkDuplicate(string memory cti_hash) public view returns (bool) {
        return existingCTIHashes[cti_hash];
    }

    // 基于 cti_hash 的海明距离计算基础相似度
    function detectSimilarity(string memory new_cti_hash, string memory existing_cti_hash) public pure returns (uint similarityScore) {
        bytes memory a = bytes(new_cti_hash);
        bytes memory b = bytes(existing_cti_hash);
        if (a.length != b.length || a.length == 0) {
            return 0;
        }
        uint diff = 0;
        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                diff++;
            }
        }
        uint sim = ((a.length - diff) * 100) / a.length;
        return sim;
    }

    // 组合字段生成特征哈希（用于增强比较）
    function generateCompositeHash(
        string memory ip,
        string[] memory tags,
        string[] memory iocs
    ) public pure returns (bytes32) {
        bytes memory combined = abi.encodePacked(ip);
        for (uint i = 0; i < tags.length; i++) {
            combined = abi.encodePacked(combined, tags[i]);
        }
        for (uint i = 0; i < iocs.length; i++) {
            combined = abi.encodePacked(combined, iocs[i]);
        }
        return keccak256(combined);
    }

    // 比较两个特征哈希之间的“海明相似度”
    function detectCompositeSimilarity(bytes32 hash1, bytes32 hash2) public pure returns (uint) {
        bytes memory a = abi.encodePacked(hash1);
        bytes memory b = abi.encodePacked(hash2);
        uint diff = 0;
        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                diff++;
            }
        }
        return ((a.length - diff) * 100) / a.length;
    }

    // 外部接口：用于手动查看单个 hash 自比较（用于测试）
    function checkSimilarity(string calldata cti_hash) external view returns (bool) {
        uint similarity = detectSimilarity(cti_hash, cti_hash);
        return similarity >= similarityThreshold;
    }

    // 注册新的情报
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
        require(!checkDuplicate(cti_hash), "CTI already uploaded");

        bytes32 newComposite = generateCompositeHash(ip, tags, iocs);

        for (uint i = 0; i < CTIByTipListGroup[tip].length; i++) {
            CTI memory existing = CTIByTipListGroup[tip][i];
            bytes32 existingComposite = generateCompositeHash(existing.ip, existing.tags, existing.iocs);
            uint sim = detectCompositeSimilarity(newComposite, existingComposite);
            if (sim >= similarityThreshold) {
                revert("CTI is too similar to an existing one");
            }
        }

        existingCTIHashes[cti_hash] = true;

        CTI memory cti = CTI(
            tid,
            tip,
            block.timestamp,
            msg.sender,
            cti_hash,
            tags,
            price,
            ip,
            threat_score,
            iocs,
            confidence,
            0,
            0,
            0,
            0
        );

        CTIByTidList[tid] = cti;
        CTIByTipListGroup[tip].push(cti);
    }

    // 查询单个情报
    function GetCTIByTid(string calldata tid) external view returns (CTI memory) {
        return CTIByTidList[tid];
    }

    // 查询某类情报集合
    function GetCTIByTip(string memory tip) external view returns (CTI[] memory) {
        return CTIByTipListGroup[tip];
    }

    // 更新消费次数和交易金额（激励用途）
    function UpdateConsumption(string calldata tid, int transactionAmount) external {
        require(CTIByTidList[tid].producer_address != address(0), "CTI does not exist");
        CTIByTidList[tid].consumption_count += 1;
        CTIByTidList[tid].transaction_value += transactionAmount;
    }

    // 更新验证次数（激励用途）
    function UpdateValidation(string calldata tid) external {
        require(CTIByTidList[tid].producer_address != address(0), "CTI does not exist");
        CTIByTidList[tid].validation_count += 1;
    }

    /// 消费者提交对情报的反馈评分（用于判断情报质量）
    function UpdateFeedbackScore(string calldata tid, uint feedback) external {
        require(CTIByTidList[tid].producer_address != address(0), "CTI does not exist");
        require(!hasScored[tid][msg.sender], "You already scored this CTI");
        require(feedback <= 100, "Feedback must be 0~100");

        feedbackScores[tid].push(feedback);
        hasScored[tid][msg.sender] = true;

        uint sum = 0;
        uint len = feedbackScores[tid].length;
        for (uint i = 0; i < len; i++) {
            sum += feedbackScores[tid][i];
        }

        CTIByTidList[tid].feedback_score = sum / len;
    }

    /// 获取某 CTI 的平均反馈分数和总评分次数
    function GetFeedbackStats(string calldata tid) external view returns (uint average, uint count) {
        uint[] memory scores = feedbackScores[tid];
        uint len = scores.length;
        if (len == 0) return (0, 0);

        uint sum = 0;
        for (uint i = 0; i < len; i++) {
            sum += scores[i];
        }

        return (sum / len, len);
    }
}


contract AssignmentContract {
    DelegatorContract delegator_contract;
    constructor(address payable addr){
        delegator_contract=DelegatorContract(addr);
    }

    struct Assignment {
        string tid; // 威胁情报 ID
        address producer; // 生产者地址
        address[] delegators_address; // 委托者的地址数组
                                      // 委托者 中介 验证情报
        uint price; // 总价格
        uint producer_price; // 生产者的价格
        uint delegator_price; // 委托者的价格
        string ipfsHash; // IPFS 哈希值
    }


    struct transaction {
        string tid; // 威胁情报 ID
        string txid; // 交易 ID
        address producer; // 生产者地址
        address delegator; // 委托者地址
        address consumer; // 消费者地址
        uint price; // 总价
        uint producer_price; // 生产者价格
        uint delegator_price; // 委托者价格
        int status; // 交易状态，0 - 未处理，1 - 已处理
    }

    mapping(address => uint256) public points;//用户积分映射

    mapping(string => address[]) private record;
    mapping(string => Assignment) private assignment_list;
    mapping(string => transaction) public tx_list;//所有交易记录

    uint public maxDiscountPercent = 20;           // 最多可抵扣 20%
    uint public pointValueInWei = 2e15;             // 每积分价值 0.002 ETH

    event ProducerAssignmentComing(address[] addresses,address producer,string tid,string ipfshash);
    event ConsumerAssignmentComing(address delegator_address,string txid,uint pay, string pubkey);
    event IPFSHashComing(address consumer,string ipfshash,string txid);

    event CTIChecked(
        string txid,
        address consumer,
        address producer,
        address delegator,
        uint256 consumerReward,
        uint256 producerReward,
        uint256 delegatorReward
    );

    // 查询某个地址积分
    function getPoints(address user) public view returns (uint256) {
        return points[user];
    }

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

    // 配置函数：部署者可后续设置
    function setMaxDiscountPercent(uint val) public {
        require(val <= 100, "Too high");
        maxDiscountPercent = val;
    }

    function setPointValueInWei(uint val) public {
        require(val > 0, "Invalid");
        pointValueInWei = val;
    }

    //消费者选择委托者
    //消费者 购买和使用威胁情报
    function ConsumerSelectDelegator(
        string memory tid,
        string memory txid,
        address addr,
        string calldata pubkey
    ) external payable {
        Assignment memory curAssignment = assignment_list[tid];
        address[] memory delegatorList = record[tid];

        bool valid = false;
        for (uint i = 0; i < delegatorList.length; i++) {
            if (delegatorList[i] == addr) {
                valid = true;
                break;
            }
        }
        if (!valid) return;

        uint price = curAssignment.price;

        // 可调节的抵扣逻辑
        uint maxDiscount = (price * maxDiscountPercent) / 100;
        uint pointValue = points[msg.sender] * pointValueInWei;
        uint discount = pointValue > maxDiscount ? maxDiscount : pointValue;

        uint finalPrice = price - discount;
        require(msg.value >= finalPrice, "Insufficient payment");

        uint usedPoints = discount / pointValueInWei;
        if (usedPoints > 0) {
            points[msg.sender] -= usedPoints;
        }

        tx_list[txid] = transaction(
            curAssignment.tid,
            txid,
            curAssignment.producer,
            addr,
            msg.sender,
            curAssignment.price,
            curAssignment.producer_price,
            curAssignment.delegator_price,
            0
        );

        emit ConsumerAssignmentComing(addr, txid, msg.value, pubkey);
    }

    //委托者上传 cti 给消费者
    function UploadCTI(string calldata ipfshash,address consumer,string calldata txid) external {
        emit IPFSHashComing(consumer,ipfshash,txid);
    }

    //消费者确认收到 cti    
    function CheckCTI(string calldata txid) external payable  {
        transaction memory trc = tx_list[txid];
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

        ///  简单的积分奖励逻辑
        points[trc.producer] += 10;      // 生产者得 10 分
        points[trc.delegator] += 5;      // 验证者得 5 分
        points[msg.sender] += 2;         // 消费者得 2 分
        emit CTIChecked(txid, msg.sender, trc.producer, trc.delegator, 2, 10, 5);
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
        //require(msg.value == 10000000000000000000);
        require(msg.value == 0);
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