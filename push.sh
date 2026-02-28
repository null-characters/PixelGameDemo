#!/bin/bash

echo "📦 开始打包代码..."
git add .

# 提示输入提交信息
read -p "📝 请输入本次提交的说明 (直接回车将使用当前时间): " commit_msg

# 如果用户没有输入任何内容，就使用当前时间作为默认信息
if [ -z "$commit_msg" ]; then
    commit_msg="自动提交: $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo "🚀 正在提交并推送到 GitHub..."
git commit -m "$commit_msg"
git push

echo "✅ 大功告成！代码已安全上传！"
