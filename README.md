# 功夫跟练 iOS 原型

这是一个 SwiftUI iOS + Node API 原型，面向“跟着短视频练习中国功夫动作，并完成打卡分享”的核心体验。

## 已实现

- 功夫短视频课程列表：少林五步拳、咏春日字冲拳、太极云手
- 跟练播放页：短视频播放、动作倒计时、当前动作提示、动作拆解
- 完成打卡：本地保存打卡记录，统计连续打卡天数
- 分享打卡：使用 iOS 系统分享面板分享练习成果文案
- 后端 API：课程列表、打卡提交、打卡历史、公开动态
- 前端同步：iOS 端优先读取后端数据，后端不可用时展示本地示例数据

## 运行方式

### 启动后端

```bash
cd backend
npm run dev
```

后端默认运行在 `http://127.0.0.1:3000`，打卡数据会写入 `backend/.data/checkins.json`。

### 启动 iOS

1. 用 Xcode 打开 `KungFuFollow.xcodeproj`
2. 选择 iPhone 模拟器
3. 点击 Run

当前视频使用线上示例 MP4 地址，占位用于验证播放流程。后续可以替换为正式功夫教学短视频资源。

## API

- `GET /health`：健康检查
- `GET /api/routines`：获取功夫课程
- `GET /api/checkins?userId=demo-user`：获取用户打卡历史
- `POST /api/checkins`：提交打卡，参数为 `userId` 和 `routineId`
- `GET /api/feed`：获取公开打卡动态

## 测试

```bash
cd backend
npm test
```
