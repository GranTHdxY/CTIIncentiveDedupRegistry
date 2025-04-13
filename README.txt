# ThreatIntelChain

**ThreatIntelChain** 是一个基于区块链的威胁情报共享与激励平台，整合了情报上传、委托者验证、消费者购买评分和积分激励机制。该平台在本地测试网络上运行，旨在为安全社区提供去中心化、可信的情报交易环境。

---

## 📦 合约模块概览

### 1. `RegistCTI`

用于情报（CTI）的上传、重复检测、评分与综合排序展示。

- ✍ 支持上传情报，包含去重机制（SimHash + Hamming 距离）
- ⭐ 支持消费者打分反馈，按评分+积分加权排序推荐情报
- 🔗 与 `AssignmentContract` 和 `RewardPointsContract` 关联，实现评分权限校验和积分奖励

### 2. `AssignmentContract`

实现交易流程的核心合约，包含三方交互逻辑。

- 🛒 消费者选择委托者，发起交易
- 🔐 委托者验证情报后上传
- ✅ 消费者确认收到情报后触发资金转账和积分奖励
- 💰 支持消费者积分折扣购买情报
- 🧾 提供 `hasConsumerBought()` 接口供评分权限验证使用

### 3. `DelegatorContract`

用于委托者注册与查询。

- 🧑‍💼 委托者注册需质押 10 ETH
- 📊 提供积分排序展示所有委托者，方便消费者选择
- 🔎 查询是否为注册委托者

### 4. `RewardPointsContract`

积分激励管理合约，支持三类用户的积分记录与操作。

- 🎯 上传情报、完成交易可获得积分（生产者、委托者、消费者）
- 🧾 消费者可用积分抵扣情报费用
- 📊 可查询用户的各类积分信息

---

## ⚙️ 核心功能亮点

| 功能                  | 描述                                        |
| --------------------- | ------------------------------------------- |
| 🔁 去重机制            | 使用 SimHash + Hamming 距离防止重复情报上传 |
| 🔄 积分系统            | 基于用户行为自动奖励积分                    |
| ⭐ 评分机制            | 消费者购买后可对情报打分，仅限一次          |
| 💰 折扣机制            | 消费者积分可用于抵扣最多 20% 交易金额       |
| 📊 委托者/情报推荐排序 | 按积分和反馈进行降序排序展示                |
| 🔒 权限控制            | 情报评分需完成购买交易后才可执行            |

---

## 🧪 部署说明

合约版本：Solidity ^0.8.2  
建议部署网络：Ganache 本地链 / Goerli 测试网

### 🧱 部署顺序建议：

```text
1. RewardPointsContract
2. DelegatorContract (传入 Reward 合约地址)
3. AssignmentContract (传入 Reward 与 Delegator 地址)
4. RegistCTI (传入 Reward 与 Assignment 地址)
```

---

## 🚀 样例调用流程

```solidity
// 上传情报（生产者）
Register(tid, tip, cti_hash, tags, price);

// 发起任务，选择委托者
ProducerSelectDelegator(...);

// 验证任务（委托者）
VerifyAssignment(...);

// 购买情报（消费者）
ConsumerSelectDelegator(...);

// 确认接收情报
CheckCTI(txid);

// 评分（仅限消费后）
rateCTI(tid, score);

// 消费者升级为委托者
consumerUpgrade(txid, name, pubkey);
```

---

## 📄 License

本项目采用 [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html) 协议开源发布。

