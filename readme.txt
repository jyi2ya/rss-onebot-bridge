=================
RSS-OneBot-Bridge
=================

将 RSS 订阅内容通过 OneBot 协议推送到 QQ 群的 Perl 工具

快速开始
========

1. 安装依赖：carton install
2. 复制配置文件：cp settings.example settings
3. 修改 settings 文件配置
4. 启动服务：carton exec perl main.pl

配置说明
========

* RSS_LINK_FILE : 订阅源列表文件
* ONEBOT_ENDPOINT : OneBot 服务地址
* ONEBOT_TOKEN : OneBot 身份验证的 token
* GROUP_IDS : 推送目标群号，以冒号分割
* ABSTRACT_MAX_LEN : 摘要最大长度

systemd
=======

    sudo cp rss-onebot-bridge.service /etc/systemd/system/
    sudo systemctl enable rss-onebot-bridge
    sudo systemctl start rss-onebot-bridge

需要修改的地方：

* 请将示例配置中的敏感信息替换为实际值
* 根据实际环境调整 WorkingDirectory 路径
