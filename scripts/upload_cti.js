async function main() {
  // 确保 MetaMask 已安装并注入
  if (typeof window.ethereum === "undefined") {
    console.error("MetaMask is not installed. Please install MetaMask and try again.");
    return;
  }

  // 请求 MetaMask 授权访问账户
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send("eth_requestAccounts", []);  // 请求用户账户授权
  const signer = provider.getSigner();  // 获取签名者（用户的地址）

  console.log("🔐 当前账户地址:", await signer.getAddress());

  // 从 GitHub 获取统一的威胁情报数据
  const response = await fetch("https://granthdxy.github.io/cti-data/unified_cti_all_sources.json");
  const unifiedCTI = await response.json();

  // 合约地址和ABI配置
  const contractAddress = "0x80366Ac8aA4ce67b36Cb219613c6f76474D8Ae91";  // 替换为你的合约地址
  const abi = [
    {
      "inputs": [
        { "internalType": "string", "name": "tid", "type": "string" },
        { "internalType": "string", "name": "tip", "type": "string" },
        { "internalType": "string", "name": "cti_hash", "type": "string" },
        { "internalType": "string[]", "name": "tags", "type": "string[]" },
        { "internalType": "int256", "name": "price", "type": "int256" },
        { "internalType": "string", "name": "ip", "type": "string" },
        { "internalType": "uint256", "name": "threat_score", "type": "uint256" },
        { "internalType": "string[]", "name": "iocs", "type": "string[]" },
        { "internalType": "int256", "name": "confidence", "type": "int256" }
      ],
      "name": "Register",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ];

  // 创建合约实例
  const contract = new ethers.Contract(contractAddress, abi, signer);

  // 循环上传每条威胁情报数据
  for (const cti of unifiedCTI) {
    try {
      console.log(`🚀 正在上传: ${cti.tid}`);
      
      // 调用合约的 Register 函数
      const tx = await contract.Register(
        cti.tid, 
        cti.tip, 
        cti.cti_hash, 
        cti.tags, 
        cti.price, 
        cti.ip, 
        cti.threat_score, 
        cti.iocs, 
        cti.confidence
      );
      
      // 等待交易完成
      console.log(`✅ 上传成功: ${cti.tid}`);
      await tx.wait();
    } catch (e) {
      console.error(`❌ 上传失败: ${cti.tid}`, e.message);  // 输出错误消息
      if (e.code === "INSUFFICIENT_FUNDS") {
        console.error("❌ 错误：账户余额不足，无法支付Gas费用");
      } else if (e.code === "TRANSACTION_REPLACEMENT_FAILED") {
        console.error("❌ 错误：交易失败，可能由于Gas价格过低");
      } else {
        console.error("❌ 其他错误: ", e);
      }
    }
}
}
// 执行 main 函数
main();
