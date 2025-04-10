async function main() {
  console.log("✅ 脚本启动成功");

  const contractAddress = "0xfd1994A02F856B159B62516e843B78D8227DEe4E";

  const abi = [
    "function Register(string tid, string tip, string cti_hash, string[] tags, int256 price, string ip, uint256 threat_score, string[] iocs, int256 confidence) external"
  ];

  const [signer] = await ethers.getSigners();
  console.log("🔐 当前调用账户地址: ", signer.address);

  const contract = new ethers.Contract(contractAddress, abi, signer);
  console.log("📡 合约连接成功: ", contractAddress);

  const unifiedCTI = [
    {
      tid: "cti_test_1",
      tip: "Threat",
      cti_hash: "hash_test_1",
      tags: ["MALWARE", "DDOS"],
      price: 100,
      ip: "8.8.8.8",
      threat_score: 80,
      iocs: ["malicious.com"],
      confidence: 85
    }
  ];

  for (const cti of unifiedCTI) {
    console.log("🚀 正在准备上传:", cti);

    try {
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
      console.log("✅ 上传成功: ", tx.hash);
      await tx.wait();
    } catch (err) {
      console.error("❌ 上传失败: ", cti.tid);
      console.error("错误详情: ", err);
    }
  }
}

main();
