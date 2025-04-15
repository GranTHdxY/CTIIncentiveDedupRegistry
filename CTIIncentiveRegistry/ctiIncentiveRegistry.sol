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
    mapping(string => mapping(address => bool)) public hasScored; // tid => user => 用于判断情报是否已评分


    CTI[] public allCtiHashes;                                   // 用于存储已上传cti的哈希值
    AssignmentContract public assignment;
    RewardPointsContract public reward;

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
        reward.rewardUser(msg.sender, 5);//上传情报并通过了去重验证 就为生产者加5积分
    }
    //根据 id 来查询 cti
    function GetCTIByTid(string calldata tid) external view returns (CTI memory) {
        return CTIByTidList[tid];
    }
    //根据 ip 来查询 cti
    function GetCTIByTip(string memory tip) external view returns (CTI[] memory) {
        return CTIByTipListGroup[tip];
    }
    
    function rateCTI(string calldata tid, int score) external {
        require(score >= 1 && score <= 10, "Invalid score (1-10)");
        require(!hasScored[tid][msg.sender], "Already rated");

        // ✅是否完成交易
        require(assignment.hasConsumerBought(tid, msg.sender), "Only consumers who completed the deal can rate");

        CTI storage cti = CTIByTidList[tid];
        require(cti.producer_address != address(0), "CTI not found");

        cti.feedback_score += score;
        hasScored[tid][msg.sender] = true;
    }


    //排序后返回情报列表
    struct CTIWithWeight {
        string tid;
        string tip;
        address producer;
        uint weight;
        string cti_hash;
        int price;
        int feedback_score;
    }

    constructor(address rewardAddr,address assignmentAddr) {
        reward = RewardPointsContract(rewardAddr);
        assignment = AssignmentContract(assignmentAddr);
    }
    
    //按照权重给现有上传的CTI进行排序 方便消费者选择更有价值的情报
    function listCTIByWeight() external view returns (CTIWithWeight[] memory) {
        uint len = allCtiHashes.length;
        CTIWithWeight[] memory temp = new CTIWithWeight[](len);

        for (uint i = 0; i < len; i++) {
            CTI memory cti = allCtiHashes[i];
            uint pScore = reward.getPoints(cti.producer_address);
            uint weight = pScore + uint(int(cti.feedback_score)) * 2; // ✳ 权重值：反馈 ×2 更重要
            temp[i] = CTIWithWeight(
                cti.tid,
                cti.tip,
                cti.producer_address,
                weight,
                cti.cti_hash,
                cti.price,
                cti.feedback_score
            );
        }

        // 插入排序：按 weight 降序
        for (uint i = 0; i < len; i++) {
            for (uint j = i + 1; j < len; j++) {
                if (temp[j].weight > temp[i].weight) {
                    CTIWithWeight memory tmp = temp[i];
                    temp[i] = temp[j];
                    temp[j] = tmp;
                }
            }
        }

        return temp;
    }
}

contract AssignmentContract {
    DelegatorContract delegator_contract;
    RewardPointsContract public reward;

    constructor(address rewardAddr, address delegatorAddr) {
        reward = RewardPointsContract(rewardAddr);
        delegator_contract = DelegatorContract(payable(delegatorAddr));
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
    string[] public txids; //保存所有发生过的交易的id


    //生产者选择委托者
    function ProducerSelectDelegator(
        string calldata tid,//这里的tid应该是情报的
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
        address delegator_addr,//委托者的地址
        string calldata pubkey
    ) external payable {
        bool f = false;
        Assignment memory curAssignment = assignment_list[tid];
        address[] memory delegatorList = record[tid];
        
        for (uint i = 0; i < delegatorList.length; i++) {
            if (delegatorList[i] == delegator_addr) {
                f = true;
            }
        }
        if (!f) {
            return;
        }
    
        // 折扣逻辑开始
        uint maxDiscount = curAssignment.price / 5; // 最多折扣 20%
        uint consumerPoint= reward.getPoints(msg.sender); // 查询当前用户积分
        uint discountUsed = consumerPoint > maxDiscount ? maxDiscount : consumerPoint;
        uint actualPay = curAssignment.price - discountUsed;

        //确保支付的金额足够
        require(msg.value >= actualPay, "Insufficient ETH after discount");
        
        uint refundAmount = msg.value - actualPay; // 计算多余的支付金额
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount); // 退还多余的 ETH
        }

        // 更新积分（使用积分）
        if (discountUsed > 0) {
            reward.useConsumerPoints(msg.sender, discountUsed);
        }

        // 创建交易记录
        tx_list[txid] = transaction(
            curAssignment.tid,
            txid,
            curAssignment.producer,
            delegator_addr,
            msg.sender,
            curAssignment.price,
            curAssignment.producer_price,
            curAssignment.delegator_price,
            0);

        txids.push(txid);
        emit ConsumerAssignmentComing(delegator_addr,txid,actualPay, pubkey);
    }

    //委托者上传 cti 给消费者
    function UploadCTI(string calldata ipfshash,address consumer,string calldata txid) external {
        emit IPFSHashComing(consumer,ipfshash,txid);
    }

    //消费者确认收到 cti    
    function CheckCTI(string calldata txid) external payable  {
        //transaction memory trc;
        transaction storage trc = tx_list[txid];
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
        reward.reward(trc.producer, trc.consumer, trc.delegator);
    }

    function hasConsumerBought(string calldata tid, address consumer) external view returns (bool) {
    // 遍历交易记录查找已完成交易
        for (uint i = 0; i < txids.length; i++) {
            transaction memory txr = tx_list[txids[i]];
            if (
                keccak256(bytes(txr.tid)) == keccak256(bytes(tid)) &&
                txr.consumer == consumer &&
                txr.status == 1
            ) {
                return true;
            }
        }
        return false;
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


    //注册成为委托者
    function Register(string calldata name,string calldata pubkey) payable external {
        //require(msg.value == 10000000000000000000);// 注册成为委托者需要10eth
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

    //根据积分排序delegator 当消费者调用ListDelegator时 可以看到委托者的积分 从而自行选择委托者
    RewardPointsContract public reward;
    constructor(address rewardAddress) {
        reward = RewardPointsContract(rewardAddress);
    }

    //定义一个扩展结构体 专门用来存储委托者的积分
    struct DelegatorWithPoints {
        string name;
        address addr;
        uint points;
        string pubkey;
        uint time;
    }

    function ListDelegator() external view returns (DelegatorWithPoints[] memory) {
        uint len = list.length;
        DelegatorWithPoints[] memory temp = new DelegatorWithPoints[](len);

        for (uint i = 0; i < len; i++) {
            uint p = reward.getPoints(list[i].addr);
            temp[i] = DelegatorWithPoints(
                list[i].name,
                list[i].addr,
                p,
                list[i].pubkey,
                list[i].time
            );
        }

        for (uint i = 0; i < len; i++) {
            for (uint j = i + 1; j < len; j++) {
                if (temp[j].points > temp[i].points) {
                    DelegatorWithPoints memory tmp = temp[i];
                    temp[i] = temp[j];
                    temp[j] = tmp;
                }
            }
        }

        return temp;
    }

    receive()external payable{}
    fallback()external payable{}
}

contract RewardPointsContract {
    // 统一的积分映射，存储每个用户的积分
    mapping(address => uint) public userPoints;

    // 完成交易之后为所有的用户加积分
    function reward(address producer, address consumer, address delegator) external {
        userPoints[producer] += 10; // 生产者加积分
        userPoints[delegator] += 7;  // 委托者加积分
        userPoints[consumer] += 5;   // 消费者加积分
    }

    // 为用户增加积分
    function rewardUser(address user, uint points) external {
        userPoints[user] += points;
    }

    // 使用积分：打折购买商品
    function useConsumerPoints(address user, uint points) external {
        require(userPoints[user] >= points, "Not enough points");
        userPoints[user] -= points;
    }

    // 获取用户的积分并返回用户地址与积分的对应关系
    function getPoints(address user) external view returns (uint) {
        return userPoints[user];
    }

}
