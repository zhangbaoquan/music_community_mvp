# INFRA — DNS 架构精简与 SSL 证书自动化

- **日期**：2026-05-19
- **状态**：✅ 已完成

## 1. 变更文件列表
- `[基建变更]` 本次为纯云端基础设施配置修改，无源码级变更。涉及腾讯云控制台的 DNS 与 SSL 模块。

## 2. 变更内容详情
- **废弃 Cloudflare**：彻底移除了原架构中历史遗留的 Cloudflare DNS 解析层，将 `qinqinmusic.com` 域名的 Nameserver 指向腾讯云 DNSPod（`red.dnspod.net` / `display.dnspod.net`）。
- **SSL 证书自动续期闭环**：在腾讯云 SSL 控制台为 `qinqinmusic.com` 及 `www.qinqinmusic.com` 申请新的免费 DV 证书，开启自动续费与 CDN 节点自动托管部署，并利用 DNSPod 实现了 TXT 记录的自动化验证。

## 3. 设计决策 (Trade-offs)
- **为什么彻底剥离 Cloudflare？** 
  早期引入 Cloudflare 是为了尝试其免费 CDN，后因 GFW 阻断改用其 CNAME Flattening 特性作纯 DNS 调度。但在本次 SSL 证书续期中发现，保留国外的 Cloudflare 作 DNS 拦截了腾讯云的自动检测，导致需跨平台手动干预且排错困难。
- **为什么迁回 DNSPod？**
  将域名控制权统一交回腾讯云（DNSPod）后，实现了域名、DNS 解析、CDN 加速、SSL 证书一键自动部署的**全链路腾讯云闭环**。这极大地降低了运维的心智负担，根除了"域名/证书/解析分家"造成的验证障碍。
