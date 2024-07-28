# 这个项目创建了一个可证明公平的智能合约彩票系统

- 用户可以通过购买一张彩票参与
- 彩票的费用将在抽奖的时全部给赢家
- 经过一段时间，彩票将自动选出一名赢家（使用Chainlink VRF，Chainlink Automation完成）

forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
forge install transmissions11/solmate --no-commit
forge install Cyfrin/foundry-devops --no-commit