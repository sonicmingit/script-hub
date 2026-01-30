#!/bin/bash
# 企业微信消息推送工具
# 功能描述：通过企业微信 API 发送卡片消息到指定部门
# 使用方法：./wechat_push.sh "标题" "内容"
# 注意事项：需要配置正确的 CorpID、Secret、AgentID 和 ToParty，需要安装 jq 命令
# 版本信息：v1.0.0

# ========= 企业微信配置（请修改为自己的配置）=========
CORP_ID="ww65388672764f572"
CORP_SECRET="hHucgPBP-uRE_TOh3hNl_dcpqboAQBfc2-D780debN"
AGENT_ID="100000"
TO_PARTY="6"

# 获取Access Token
function get_access_token() {
  local resp=$(curl -s "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=${CORP_ID}&corpsecret=${CORP_SECRET}")
  local token=$(echo $resp | jq -r '.access_token')
  echo $token
}

# 发送消息
function send_message() {
  local title="$1"
  local content="$2"
  local access_token=$(get_access_token)
  local data=$(cat <<EOF
{
  "touser" : "",
  "toparty" : "${TO_PARTY}",
  "totag" : "",
  "msgtype" : "textcard",
  "agentid" : ${AGENT_ID},
  "textcard" : {
           "title" : "${title}",
           "description" : "${content}",
           "url" : "URL",
           "btntxt":"更多"
  }
}
EOF
)

  local resp=$(curl -s -X POST -d "$data" "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=${access_token}")
  echo "Response: $resp"
}

# 使用方法: ./send_wechat_message.sh "标题" "内容"
send_message "$1" "$2"